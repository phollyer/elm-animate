module Anim.Internal.Engine.Animation.CSS.Keyframe.Generator exposing
    ( generateAnimation
    , generateInitialState
    , generateRestart
    , generateTransforms
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Builder.FontColor as FontColor
import Anim.Internal.Engine.Animation.CSS.CSS exposing (AnimPlayState(..), AnimState(..))
import Anim.Internal.Engine.Animation.CSS.Keyframe.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Animation.CSS.Keyframe.Animation as Animation
import Anim.Internal.Engine.Animation.CSS.Styles as Styles
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


generateInitialState :
    Maybe (List Builder.TransformOrder)
    -> Builder.Iterations
    -> Builder.AnimationDirection
    -> AnimGroupName
    -> List Builder.PropertyConfig
    -> AnimGroup
generateInitialState maybeOrder iterationCount direction animGroupName properties =
    let
        processedProps =
            Builder.processProperties Builder.initDefaults properties

        transforms =
            generateTransforms maybeOrder Nothing processedProps

        name =
            generateName Nothing maybeOrder animGroupName processedProps
    in
    generate name 0 maybeOrder iterationCount direction Nothing transforms processedProps


generateAnimation : Maybe (List Builder.TransformOrder) -> Builder.Iterations -> Builder.AnimationDirection -> Maybe Builder.PropertyEndStates -> AnimGroupName -> List Builder.ProcessedPropertyConfig -> AnimGroup
generateAnimation maybeOrder iterationCount direction maybeTargetValues animGroupName properties =
    let
        transforms =
            generateTransforms maybeOrder maybeTargetValues properties

        name =
            generateName Nothing maybeOrder animGroupName properties
    in
    generate name 0 maybeOrder iterationCount direction maybeTargetValues transforms properties


generateRestart : Int -> Maybe (List Builder.TransformOrder) -> Builder.Iterations -> Builder.AnimationDirection -> Maybe Builder.PropertyEndStates -> AnimGroupName -> List Builder.ProcessedPropertyConfig -> AnimGroup
generateRestart counter maybeOrder iterationCount direction maybeTargetValues animGroupName properties =
    let
        transforms =
            generateTransforms maybeOrder maybeTargetValues properties

        suffix =
            "-r" ++ String.fromInt counter

        name =
            generateName (Just suffix) maybeOrder animGroupName properties
    in
    generate name counter maybeOrder iterationCount direction maybeTargetValues transforms properties


generateTransforms : Maybe (List Builder.TransformOrder) -> Maybe Builder.PropertyEndStates -> List Builder.ProcessedPropertyConfig -> String
generateTransforms maybeOrder maybeTargetValues processedProps =
    let
        baselines =
            baselineTransformParts maybeTargetValues processedProps

        mergeTransformParts : Builder.TransformParts -> Builder.TransformParts -> Builder.TransformParts
        mergeTransformParts baseline animated =
            let
                selectOrBaseline accessor =
                    if accessor animated /= "" then
                        accessor animated

                    else
                        accessor baseline
            in
            { translate = selectOrBaseline .translate
            , rotate = selectOrBaseline .rotate
            , scale = selectOrBaseline .scale
            }
    in
    processedProps
        |> Builder.extractTransformsFromProcessed
        |> mergeTransformParts baselines
        |> generateTransformComponents maybeOrder
        |> String.join " "



{- ***** Internal Helpers ***** -}


generate : String -> Int -> Maybe (List Builder.TransformOrder) -> Builder.Iterations -> Builder.AnimationDirection -> Maybe Builder.PropertyEndStates -> String -> List Builder.ProcessedPropertyConfig -> AnimGroup
generate name counter maybeOrder iterationCount direction maybeTargetValues transforms properties =
    AnimGroup.init
        |> AnimGroup.setStyles (Styles.fromProcessedProperties [ ( "transform", transforms ) ] properties)
        |> AnimGroup.setRestartCounter counter
        |> AnimGroup.setIterationCount 0
        |> (\animGroup ->
                if List.isEmpty properties then
                    animGroup

                else
                    let
                        ( maxDuration, maxDelay ) =
                            getMaxTimings properties

                        keyframesString =
                            properties
                                |> generateSteps maybeOrder maybeTargetValues maxDuration maxDelay
                                |> buildKeyframesString name
                    in
                    AnimGroup.setAnimation
                        (Animation.init
                            |> Animation.setAnimationName name
                            |> Animation.setKeyframes keyframesString
                            |> Animation.setDuration (maxDuration + maxDelay)
                            |> Animation.setIterations iterationCount
                            |> Animation.setDirection direction
                        )
                        animGroup
           )


generateSteps : Maybe (List Builder.TransformOrder) -> Maybe Builder.PropertyEndStates -> Int -> Int -> List Builder.ProcessedPropertyConfig -> List ( Float, List ( String, String ) )
generateSteps maybeOrder maybeTargetValues maxDuration maxDelay processedProps =
    let
        totalAnimationTime =
            maxDuration + maxDelay

        totalSteps =
            30

        generateTransformStyle : List String -> Maybe ( String, String )
        generateTransformStyle transformComponents =
            if List.isEmpty transformComponents then
                Nothing

            else
                Just ( "transform", String.join " " transformComponents )
    in
    totalSteps
        |> List.range 0
        |> List.map
            (\i ->
                let
                    globalProgress =
                        toFloat i / toFloat totalSteps

                    totalTime =
                        globalProgress * toFloat totalAnimationTime

                    transformStyle =
                        generateTransformParts maybeTargetValues totalTime processedProps
                            |> generateTransformComponents maybeOrder
                            |> generateTransformStyle

                    otherStyles =
                        generateNonTransformStyles totalTime processedProps

                    styles =
                        case transformStyle of
                            Just t ->
                                t :: otherStyles

                            Nothing ->
                                otherStyles
                in
                ( globalProgress, styles )
            )


generateTransformParts : Maybe Builder.PropertyEndStates -> Float -> List Builder.ProcessedPropertyConfig -> Builder.TransformParts
generateTransformParts maybeTargetValues totalTime properties =
    let
        baselineParts =
            baselineTransformParts maybeTargetValues properties
    in
    List.foldl
        (\p acc ->
            case p of
                Builder.ProcessedTranslateConfig cfg ->
                    { acc | translate = generateTransformPart totalTime Translate.default Translate.interpolate Translate.toCssString cfg }

                Builder.ProcessedRotateConfig cfg ->
                    { acc | rotate = generateTransformPart totalTime Rotate.default Rotate.interpolate Rotate.toCssString cfg }

                Builder.ProcessedScaleConfig cfg ->
                    { acc | scale = generateTransformPart totalTime Scale.default Scale.interpolate Scale.toCssString cfg }

                _ ->
                    acc
        )
        baselineParts
        properties


generateTransformPart : Float -> a -> (Float -> a -> a -> a) -> (a -> String) -> Builder.ProcessedAnimationConfig a -> String
generateTransformPart totalTime default interpolate toCssString cfg =
    let
        linearProgress =
            if totalTime < toFloat cfg.delay then
                0

            else if cfg.duration == 0 then
                1.0

            else
                let
                    animationTime =
                        totalTime - toFloat cfg.delay
                in
                clamp 0 1 (animationTime / toFloat cfg.duration)

        progress =
            Easing.toFunction (toFloat cfg.duration) cfg.easing linearProgress

        start =
            case cfg.start of
                Just s ->
                    s

                Nothing ->
                    default
    in
    cfg.end
        |> interpolate progress start
        |> toCssString


generateTransformComponents : Maybe (List Builder.TransformOrder) -> Builder.TransformParts -> List String
generateTransformComponents maybeOrder transformParts =
    List.filter (String.isEmpty >> not) <|
        case maybeOrder of
            Nothing ->
                [ transformParts.translate, transformParts.rotate, transformParts.scale ]

            Just order ->
                let
                    toMaybe part =
                        if part /= "" then
                            Just part

                        else
                            Nothing
                in
                List.filterMap
                    (\o ->
                        case o of
                            Builder.Translate ->
                                toMaybe transformParts.translate

                            Builder.Rotate ->
                                toMaybe transformParts.rotate

                            Builder.Scale ->
                                toMaybe transformParts.scale
                    )
                    order


generateNonTransformStyles : Float -> List Builder.ProcessedPropertyConfig -> List ( String, String )
generateNonTransformStyles totalTime =
    List.concat
        << List.filterMap
            (\p ->
                case p of
                    Builder.ProcessedTranslateConfig _ ->
                        Nothing

                    Builder.ProcessedRotateConfig _ ->
                        Nothing

                    Builder.ProcessedScaleConfig _ ->
                        Nothing

                    Builder.ProcessedBackgroundColorConfig cfg ->
                        Just
                            [ ( "background-color", generateTransformPart totalTime BackgroundColor.default Color.interpolate Color.toCssString cfg ) ]

                    Builder.ProcessedFontColorConfig cfg ->
                        Just
                            [ ( "color", generateTransformPart totalTime FontColor.default Color.interpolate Color.toCssString cfg ) ]

                    Builder.ProcessedOpacityConfig cfg ->
                        Just
                            [ ( "opacity", generateTransformPart totalTime Opacity.default Opacity.interpolate Opacity.toCssString cfg ) ]

                    Builder.ProcessedSizeConfig cfg ->
                        Just
                            [ ( "width", generateTransformPart totalTime Size.default Size.interpolate Size.widthToCssString cfg )
                            , ( "height", generateTransformPart totalTime Size.default Size.interpolate Size.heightToCssString cfg )
                            ]
            )


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
            steps
                |> List.map stepToString
                |> String.join "\n\n"

        animationPropertiesComment =
            "\n\n/* Animation properties for "
                ++ name
                ++ " */\n"
    in
    "@keyframes " ++ name ++ " {\n" ++ stepsString ++ "\n}" ++ animationPropertiesComment


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


generateName : Maybe String -> Maybe (List Builder.TransformOrder) -> AnimGroupName -> List Builder.ProcessedPropertyConfig -> String
generateName maybeSuffix maybeOrder animGroupName properties =
    let
        ( maxDuration, maxDelay ) =
            getMaxTimings properties

        hash =
            generateHash maybeOrder animGroupName maxDuration maxDelay properties

        suffix =
            case maybeSuffix of
                Nothing ->
                    ""

                Just s ->
                    "-" ++ s
    in
    animGroupName ++ "-anim-" ++ hash ++ suffix


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


{-| Build baseline transform parts from element targets, only for properties
not being animated in the current processedProps.
-}
baselineTransformParts : Maybe Builder.PropertyEndStates -> List Builder.ProcessedPropertyConfig -> Builder.TransformParts
baselineTransformParts maybeTargetValues processedProps =
    case maybeTargetValues of
        Nothing ->
            { translate = "", rotate = "", scale = "" }

        Just targets ->
            let
                baseline isAnimated maybeValue toCssString =
                    if List.any isAnimated processedProps then
                        ""

                    else
                        maybeValue
                            |> Maybe.map toCssString
                            |> Maybe.withDefault ""

                isTranslate p =
                    case p of
                        Builder.ProcessedTranslateConfig _ ->
                            True

                        _ ->
                            False

                isRotate p =
                    case p of
                        Builder.ProcessedRotateConfig _ ->
                            True

                        _ ->
                            False

                isScale p =
                    case p of
                        Builder.ProcessedScaleConfig _ ->
                            True

                        _ ->
                            False
            in
            { translate = baseline isTranslate targets.translate Translate.toCssString
            , rotate = baseline isRotate targets.rotate Rotate.toCssString
            , scale = baseline isScale targets.scale Scale.toCssString
            }
