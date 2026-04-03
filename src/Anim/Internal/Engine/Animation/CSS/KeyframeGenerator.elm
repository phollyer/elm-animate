module Anim.Internal.Engine.Animation.CSS.KeyframeGenerator exposing
    ( generateAnimation
    , generateInitialState
    , generateRestart
    , generateTransformString
    , generateWithOrder
    )

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Builder.FontColor as FontColor
import Anim.Internal.Engine.Animation.CSS.CSS as CSS exposing (AnimPlayState(..), AnimState(..))
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Extra.Easing as Easing
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Translate as Translate
import Char


type alias AnimGroupName =
    String


type alias AnimGroup =
    { styles : List ( String, String )
    , animationLayers : Maybe Animation
    , restartCounter : Int
    }


type alias Animation =
    { animationName : String
    , keyframes : String
    , duration : Int
    , easing : String
    , delay : Int
    , iterationCount : Builder.IterationCount
    , direction : Builder.AnimationDirection
    }


generateInitialState : Maybe (List Builder.TransformOrder) -> Builder.IterationCount -> Builder.AnimationDirection -> AnimGroupName -> Builder.AnimGroupConfig -> AnimGroup
generateInitialState maybeOrder iterationCount direction animGroupName animGroupConfig =
    let
        processedProps =
            animGroupConfig
                |> Builder.processAnimGroupConfig Builder.initDefaults
                |> .properties

        transforms =
            case maybeOrder of
                Nothing ->
                    generateTransformString processedProps

                Just order ->
                    let
                        orderStrings =
                            List.map Builder.transformOrderToString order
                    in
                    generateWithOrder orderStrings processedProps

        allStyles =
            ( "transform", transforms )
                :: CSS.getStyles processedProps
                |> List.filter (\( _, value ) -> not (String.isEmpty value))
    in
    { styles = allStyles
    , animationLayers = generateAnimationLayers maybeOrder iterationCount direction Nothing animGroupName processedProps
    , restartCounter = 0
    }


generateAnimation : Maybe (List Builder.TransformOrder) -> Builder.IterationCount -> Builder.AnimationDirection -> Maybe Builder.ElementEndStates -> AnimGroupName -> Builder.ProcessedAnimGroupConfig -> AnimGroup
generateAnimation maybeOrder iterationCount direction maybeTargetValues animGroupName processed =
    let
        processedProps =
            processed.properties

        baseline =
            baselineTransformParts maybeTargetValues processedProps

        transforms =
            processedProps
                |> Builder.extractTransformsFromProcessed
                |> mergeTransformParts baseline
                |> transformPartsToString maybeOrder

        allStyles =
            ( "transform", transforms )
                :: CSS.getStyles processedProps
                |> List.filter (\( _, value ) -> not (String.isEmpty value))
    in
    { styles = allStyles
    , animationLayers = generateAnimationLayers maybeOrder iterationCount direction maybeTargetValues animGroupName processedProps
    , restartCounter = 0
    }


generateRestart : Maybe (List Builder.TransformOrder) -> Builder.IterationCount -> Builder.AnimationDirection -> Maybe Builder.ElementEndStates -> String -> AnimGroupName -> Builder.ProcessedAnimGroupConfig -> AnimGroup
generateRestart maybeOrder iterationCount direction maybeTargetValues suffix animGroupName processed =
    let
        processedProps =
            processed.properties

        baseline =
            baselineTransformParts maybeTargetValues processedProps

        transforms =
            processedProps
                |> Builder.extractTransformsFromProcessed
                |> mergeTransformParts baseline
                |> transformPartsToString maybeOrder

        allStyles =
            ( "transform", transforms )
                :: CSS.getStyles processedProps
                |> List.filter (\( _, value ) -> not (String.isEmpty value))
    in
    { styles = allStyles
    , animationLayers = generateRestartLayers maybeOrder iterationCount direction maybeTargetValues suffix animGroupName processedProps
    , restartCounter = 0
    }


generateAnimationLayers :
    Maybe (List Builder.TransformOrder)
    -> Builder.IterationCount
    -> Builder.AnimationDirection
    -> Maybe Builder.ElementEndStates
    -> AnimGroupName
    -> List Builder.ProcessedPropertyConfig
    -> Maybe Animation
generateAnimationLayers maybeOrder iterationCount direction maybeTargetValues animGroupName =
    generateAnimationData maybeOrder maybeTargetValues animGroupName
        >> setIterationCount iterationCount
        >> setDirection direction


generateRestartLayers :
    Maybe (List Builder.TransformOrder)
    -> Builder.IterationCount
    -> Builder.AnimationDirection
    -> Maybe Builder.ElementEndStates
    -> String
    -> AnimGroupName
    -> List Builder.ProcessedPropertyConfig
    -> Maybe Animation
generateRestartLayers maybeOrder iterationCount direction maybeTargetValues suffix animGroupName =
    generateRestartData maybeOrder maybeTargetValues suffix animGroupName
        >> setIterationCount iterationCount
        >> setDirection direction


{-| Generate the CSS transform string from processed properties.
-}
generateTransformString : List Builder.ProcessedPropertyConfig -> String
generateTransformString properties =
    let
        transformParts =
            extractTransformsFromProcessed properties
    in
    String.trim (transformParts.translate ++ " " ++ transformParts.rotate ++ " " ++ transformParts.scale)


{-| Generate transform from processed properties with custom ordering.
-}
generateWithOrder : List String -> List Builder.ProcessedPropertyConfig -> String
generateWithOrder order properties =
    let
        transformParts =
            extractTransformsFromProcessed properties
    in
    order
        |> List.filterMap (getTransformByName transformParts)
        |> String.join " "
        |> String.trim



{- ***** Internal Helpers ***** -}


generateAnimationData : Maybe (List Builder.TransformOrder) -> Maybe Builder.ElementEndStates -> AnimGroupName -> List Builder.ProcessedPropertyConfig -> Maybe Animation
generateAnimationData maybeOrder maybeTargetValues animGroupName processedProps =
    if List.isEmpty processedProps then
        Nothing

    else
        let
            ( maxDuration, maxDelay ) =
                getMaxTimings processedProps

            totalAnimationTime =
                maxDuration + maxDelay

            hash =
                generateHash maybeOrder animGroupName maxDuration maxDelay processedProps

            animationName =
                animGroupName
                    ++ "-anim-"
                    ++ hash

            keyframesString =
                processedProps
                    |> generateSteps maybeOrder maybeTargetValues maxDuration maxDelay
                    |> buildKeyframesString animationName
        in
        Just
            { animationName = animationName
            , keyframes = keyframesString
            , duration = totalAnimationTime
            , easing = "linear"
            , delay = 0
            , iterationCount = Builder.Once
            , direction = Builder.Normal
            }


{-| Generate animation data with a restart suffix
-}
generateRestartData : Maybe (List Builder.TransformOrder) -> Maybe Builder.ElementEndStates -> AnimGroupName -> String -> List Builder.ProcessedPropertyConfig -> Maybe Animation
generateRestartData maybeOrder maybeTargetValues animGroupName suffix processedProps =
    if List.isEmpty processedProps then
        Nothing

    else
        let
            ( maxDuration, maxDelay ) =
                getMaxTimings processedProps

            totalAnimationTime =
                maxDuration + maxDelay

            hash =
                generateHash maybeOrder animGroupName maxDuration maxDelay processedProps

            animationName =
                animGroupName
                    ++ "-anim-"
                    ++ hash
                    ++ suffix

            keyframesString =
                processedProps
                    |> generateSteps maybeOrder maybeTargetValues maxDuration maxDelay
                    |> buildKeyframesString animationName
        in
        Just
            { animationName = animationName
            , keyframes = keyframesString
            , duration = totalAnimationTime
            , easing = "linear"
            , delay = 0
            , iterationCount = Builder.Once
            , direction = Builder.Normal
            }


generateHash : Maybe (List Builder.TransformOrder) -> AnimGroupName -> Int -> Int -> List Builder.ProcessedPropertyConfig -> String
generateHash maybeOrder animGroupName maxDuration maxDelay processedProps =
    let
        orderHash =
            case maybeOrder of
                Nothing ->
                    ""

                Just order ->
                    "-order-" ++ (List.map Builder.transformOrderToString order |> String.join "-")

        stringifyConfig p =
            let
                s prefix toCssString cfg =
                    prefix
                        ++ String.fromInt cfg.duration
                        ++ "-"
                        ++ String.fromInt cfg.delay
                        ++ "-"
                        ++ toCssString cfg.end
                        ++ "-"
                        ++ (cfg.start |> Maybe.map toCssString |> Maybe.withDefault "none")
            in
            case p of
                Builder.ProcessedTranslateConfig cfg ->
                    s "pos-" Translate.toCssString cfg

                Builder.ProcessedScaleConfig cfg ->
                    s "scale-" Scale.toCssString cfg

                Builder.ProcessedRotateConfig cfg ->
                    s "rot-" Rotate.toCssString cfg

                Builder.ProcessedBackgroundColorConfig cfg ->
                    s "bg-" Color.toCssString cfg

                Builder.ProcessedFontColorConfig cfg ->
                    s "color-" Color.toCssString cfg

                Builder.ProcessedOpacityConfig cfg ->
                    s "opacity-" Opacity.toCssString cfg

                Builder.ProcessedSizeConfig cfg ->
                    s "size-" Size.toCssString cfg

        hashConfig =
            processedProps
                |> List.map stringifyConfig
                |> String.join "-"

        contentForHash =
            animGroupName
                ++ orderHash
                ++ String.fromInt maxDuration
                ++ String.fromInt maxDelay
                ++ hashConfig

        hashString char acc =
            let
                code =
                    Char.toCode char
            in
            (acc * 31 + code) |> modBy 1000000007
    in
    contentForHash
        |> String.toList
        |> List.foldl hashString 0
        |> String.fromInt


generateSteps : Maybe (List Builder.TransformOrder) -> Maybe Builder.ElementEndStates -> Int -> Int -> List Builder.ProcessedPropertyConfig -> List ( Float, List ( String, String ) )
generateSteps maybeOrder maybeTargetValues maxDuration maxDelay processedProps =
    let
        totalAnimationTime =
            maxDuration + maxDelay

        totalSteps =
            30
    in
    List.range 0 totalSteps
        |> List.map
            (\i ->
                let
                    globalProgress =
                        toFloat i / toFloat totalSteps

                    totalTime =
                        globalProgress * toFloat totalAnimationTime

                    calculateProgress : Int -> Int -> Easing -> Float
                    calculateProgress propDelay propDuration propEasing =
                        let
                            linearProgress =
                                if totalTime < toFloat propDelay then
                                    0

                                else if propDuration == 0 then
                                    1.0

                                else
                                    let
                                        animationTime =
                                            totalTime - toFloat propDelay
                                    in
                                    clamp 0 1 (animationTime / toFloat propDuration)

                            easingFunction =
                                Easing.toFunction (toFloat propDuration) propEasing
                        in
                        easingFunction linearProgress

                    baselineParts =
                        baselineTransformParts maybeTargetValues processedProps

                    transformParts =
                        processedProps
                            |> List.foldl
                                (\p acc ->
                                    case p of
                                        Builder.ProcessedTranslateConfig cfg ->
                                            let
                                                progress =
                                                    calculateProgress cfg.delay cfg.duration cfg.easing

                                                startPos =
                                                    case cfg.start of
                                                        Just s ->
                                                            s

                                                        Nothing ->
                                                            Translate.default

                                                interpolatedPos =
                                                    Translate.interpolate progress startPos cfg.end
                                            in
                                            { acc | translate = Translate.toCssString interpolatedPos }

                                        Builder.ProcessedRotateConfig cfg ->
                                            let
                                                progress =
                                                    calculateProgress cfg.delay cfg.duration cfg.easing

                                                startRot =
                                                    case cfg.start of
                                                        Just s ->
                                                            s

                                                        Nothing ->
                                                            Rotate.default

                                                interpolatedRot =
                                                    Rotate.interpolate progress startRot cfg.end
                                            in
                                            { acc | rotate = Rotate.toCssString interpolatedRot }

                                        Builder.ProcessedScaleConfig cfg ->
                                            let
                                                progress =
                                                    calculateProgress cfg.delay cfg.duration cfg.easing

                                                startScale =
                                                    case cfg.start of
                                                        Just s ->
                                                            s

                                                        Nothing ->
                                                            Scale.default

                                                interpolatedScale =
                                                    Scale.interpolate progress startScale cfg.end
                                            in
                                            { acc | scale = Scale.toCssString interpolatedScale }

                                        _ ->
                                            acc
                                )
                                baselineParts

                    transformComponents =
                        (case maybeOrder of
                            Nothing ->
                                [ transformParts.translate, transformParts.rotate, transformParts.scale ]

                            Just order ->
                                List.filterMap
                                    (\o ->
                                        case o of
                                            Builder.Translate ->
                                                if transformParts.translate /= "" then
                                                    Just transformParts.translate

                                                else
                                                    Nothing

                                            Builder.Rotate ->
                                                if transformParts.rotate /= "" then
                                                    Just transformParts.rotate

                                                else
                                                    Nothing

                                            Builder.Scale ->
                                                if transformParts.scale /= "" then
                                                    Just transformParts.scale

                                                else
                                                    Nothing
                                    )
                                    order
                        )
                            |> List.filter (\s -> s /= "")

                    transformStyle =
                        if List.isEmpty transformComponents then
                            Nothing

                        else
                            Just ( "transform", String.join " " transformComponents )

                    otherStyles =
                        processedProps
                            |> List.filterMap
                                (\p ->
                                    case p of
                                        Builder.ProcessedBackgroundColorConfig cfg ->
                                            let
                                                progress =
                                                    calculateProgress cfg.delay cfg.duration cfg.easing

                                                startColor =
                                                    case cfg.start of
                                                        Just c ->
                                                            c

                                                        Nothing ->
                                                            BackgroundColor.default

                                                interpolatedColor =
                                                    Color.interpolate startColor cfg.end progress
                                            in
                                            Just
                                                [ ( "background-color", Color.toCssString interpolatedColor ) ]

                                        Builder.ProcessedFontColorConfig cfg ->
                                            let
                                                progress =
                                                    calculateProgress cfg.delay cfg.duration cfg.easing

                                                startColor =
                                                    case cfg.start of
                                                        Just c ->
                                                            c

                                                        Nothing ->
                                                            FontColor.default

                                                interpolatedColor =
                                                    Color.interpolate startColor cfg.end progress
                                            in
                                            Just
                                                [ ( "color", Color.toCssString interpolatedColor ) ]

                                        Builder.ProcessedOpacityConfig cfg ->
                                            let
                                                progress =
                                                    calculateProgress cfg.delay cfg.duration cfg.easing

                                                startOpacity =
                                                    case cfg.start of
                                                        Just s ->
                                                            s

                                                        Nothing ->
                                                            Opacity.default

                                                interpolatedOpacity =
                                                    Opacity.interpolate progress startOpacity cfg.end
                                            in
                                            Just
                                                [ ( "opacity", Opacity.toString interpolatedOpacity ) ]

                                        Builder.ProcessedSizeConfig cfg ->
                                            let
                                                progress =
                                                    calculateProgress cfg.delay cfg.duration cfg.easing

                                                startSize =
                                                    case cfg.start of
                                                        Just s ->
                                                            s

                                                        Nothing ->
                                                            Size.default

                                                interpolated =
                                                    Size.interpolate progress startSize cfg.end

                                                ( interpolatedW, interpolatedH ) =
                                                    Size.toTuple interpolated
                                            in
                                            Just
                                                [ ( "width", String.fromFloat interpolatedW ++ "px" )
                                                , ( "height", String.fromFloat interpolatedH ++ "px" )
                                                ]

                                        _ ->
                                            Nothing
                                )

                    styles =
                        case transformStyle of
                            Just t ->
                                t :: List.concat otherStyles

                            Nothing ->
                                List.concat otherStyles
                in
                ( globalProgress, styles )
            )


getMaxTimings : List Builder.ProcessedPropertyConfig -> ( Int, Int )
getMaxTimings processedProps =
    processedProps
        |> List.map
            (\p ->
                case p of
                    Builder.ProcessedTranslateConfig cfg ->
                        ( cfg.duration, cfg.delay )

                    Builder.ProcessedScaleConfig cfg ->
                        ( cfg.duration, cfg.delay )

                    Builder.ProcessedRotateConfig cfg ->
                        ( cfg.duration, cfg.delay )

                    Builder.ProcessedBackgroundColorConfig cfg ->
                        ( cfg.duration, cfg.delay )

                    Builder.ProcessedFontColorConfig cfg ->
                        ( cfg.duration, cfg.delay )

                    Builder.ProcessedOpacityConfig cfg ->
                        ( cfg.duration, cfg.delay )

                    Builder.ProcessedSizeConfig cfg ->
                        ( cfg.duration, cfg.delay )
            )
        |> List.maximum
        |> Maybe.withDefault ( 0, 0 )


setIterationCount : Builder.IterationCount -> Maybe Animation -> Maybe Animation
setIterationCount count =
    Maybe.map (\anim -> { anim | iterationCount = count })


setDirection : Builder.AnimationDirection -> Maybe Animation -> Maybe Animation
setDirection dir =
    Maybe.map (\anim -> { anim | direction = dir })


{-| Build baseline transform parts from element targets, only for properties
not being animated in the current processedProps.
-}
baselineTransformParts : Maybe Builder.ElementEndStates -> List Builder.ProcessedPropertyConfig -> Builder.TransformParts
baselineTransformParts maybeTargetValues processedProps =
    case maybeTargetValues of
        Nothing ->
            { translate = "", rotate = "", scale = "" }

        Just targets ->
            let
                hasType checker =
                    List.any checker processedProps
            in
            { translate =
                if
                    hasType
                        (\p ->
                            case p of
                                Builder.ProcessedTranslateConfig _ ->
                                    True

                                _ ->
                                    False
                        )
                then
                    ""

                else
                    targets.translate |> Maybe.map Translate.toCssString |> Maybe.withDefault ""
            , rotate =
                if
                    hasType
                        (\p ->
                            case p of
                                Builder.ProcessedRotateConfig _ ->
                                    True

                                _ ->
                                    False
                        )
                then
                    ""

                else
                    targets.rotate |> Maybe.map Rotate.toCssString |> Maybe.withDefault ""
            , scale =
                if
                    hasType
                        (\p ->
                            case p of
                                Builder.ProcessedScaleConfig _ ->
                                    True

                                _ ->
                                    False
                        )
                then
                    ""

                else
                    targets.scale |> Maybe.map Scale.toCssString |> Maybe.withDefault ""
            }


mergeTransformParts : Builder.TransformParts -> Builder.TransformParts -> Builder.TransformParts
mergeTransformParts baseline animated =
    { translate =
        if animated.translate /= "" then
            animated.translate

        else
            baseline.translate
    , rotate =
        if animated.rotate /= "" then
            animated.rotate

        else
            baseline.rotate
    , scale =
        if animated.scale /= "" then
            animated.scale

        else
            baseline.scale
    }


transformPartsToString : Maybe (List Builder.TransformOrder) -> Builder.TransformParts -> String
transformPartsToString maybeOrder parts =
    let
        orderedParts =
            case maybeOrder of
                Nothing ->
                    [ parts.translate, parts.rotate, parts.scale ]

                Just order ->
                    List.filterMap
                        (\o ->
                            case o of
                                Builder.Translate ->
                                    if parts.translate /= "" then
                                        Just parts.translate

                                    else
                                        Nothing

                                Builder.Rotate ->
                                    if parts.rotate /= "" then
                                        Just parts.rotate

                                    else
                                        Nothing

                                Builder.Scale ->
                                    if parts.scale /= "" then
                                        Just parts.scale

                                    else
                                        Nothing
                        )
                        order
    in
    orderedParts
        |> List.filter (\s -> s /= "")
        |> String.join " "


{-| Extract transform parts from processed properties.
-}
extractTransformsFromProcessed : List Builder.ProcessedPropertyConfig -> Builder.TransformParts
extractTransformsFromProcessed =
    List.foldl
        (\property acc ->
            case property of
                Builder.ProcessedTranslateConfig config ->
                    { acc | translate = Translate.toCssString config.end }

                Builder.ProcessedRotateConfig config ->
                    { acc | rotate = Rotate.toCssString config.end }

                Builder.ProcessedScaleConfig config ->
                    let
                        ( x, y ) =
                            Scale.toTuple config.end
                    in
                    { acc | scale = "scale(" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")" }

                _ ->
                    acc
        )
        { translate = ""
        , rotate = ""
        , scale = ""
        }


{-| Get the transform string for a given property name.
-}
getTransformByName : Builder.TransformParts -> String -> Maybe String
getTransformByName parts name =
    let
        somethingOrNothing str =
            case str of
                "" ->
                    Nothing

                _ ->
                    Just str
    in
    case name of
        "translate" ->
            somethingOrNothing parts.translate

        "rotate" ->
            somethingOrNothing parts.rotate

        "scale" ->
            somethingOrNothing parts.scale

        _ ->
            Nothing


buildKeyframesString : String -> List ( Float, List ( String, String ) ) -> String
buildKeyframesString name steps =
    let
        stepToString : ( Float, List ( String, String ) ) -> String
        stepToString ( progress, styles ) =
            let
                percentage =
                    String.fromFloat (progress * 100) ++ "%"

                styleStrings =
                    List.map (\( prop, value ) -> "  " ++ prop ++ ": " ++ value ++ ";") styles
            in
            percentage ++ " {\n" ++ String.join "\n" styleStrings ++ "\n}"

        stepsString =
            List.map stepToString steps |> String.join "\n\n"

        animationPropertiesComment =
            "\n\n/* Animation properties for "
                ++ name
                ++ " */\n"
    in
    "@keyframes " ++ name ++ " {\n" ++ stepsString ++ "\n}" ++ animationPropertiesComment
