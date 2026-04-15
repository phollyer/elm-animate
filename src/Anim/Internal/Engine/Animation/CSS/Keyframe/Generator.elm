module Anim.Internal.Engine.Animation.CSS.Keyframe.Generator exposing
    ( DiscreteConfig
    , emptyDiscreteConfig
    , generateAnimation
    , generateRestart
    , init
    )

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Builder.FontColor as FontColor
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.Animation.CSS.CSS exposing (AnimState(..))
import Anim.Internal.Engine.Animation.CSS.Keyframe.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Animation.CSS.Keyframe.Animation as Animation
import Anim.Internal.Engine.Animation.CSS.Keyframe.Styles as KeyframeStyles
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Extra.Easing as Easing
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Translate as Translate
import Char
import Dict exposing (Dict)


type alias DiscreteConfig =
    { entry : Dict String String
    , exit : Dict String Builder.DiscreteExitProperty
    }


emptyDiscreteConfig : DiscreteConfig
emptyDiscreteConfig =
    { entry = Dict.empty
    , exit = Dict.empty
    }


type alias AnimGroupName =
    String


init :
    Maybe (List TransformProperty)
    -> Builder.Iterations
    -> Builder.AnimationDirection
    -> DiscreteConfig
    -> AnimGroupName
    -> List Builder.PropertyConfig
    -> AnimGroup
init maybeOrder iterationCount direction discrete animGroupName properties =
    let
        processedProps =
            Builder.processProperties Builder.initDefaults properties

        name =
            generateName Nothing maybeOrder discrete animGroupName processedProps
    in
    generate name 0 maybeOrder iterationCount direction Nothing discrete processedProps


generateAnimation : Maybe (List TransformProperty) -> Builder.Iterations -> Builder.AnimationDirection -> Maybe PropertyBaselines -> DiscreteConfig -> AnimGroupName -> List Builder.ProcessedPropertyConfig -> AnimGroup
generateAnimation maybeOrder iterationCount direction maybeTargetValues discrete animGroupName properties =
    let
        name =
            generateName Nothing maybeOrder discrete animGroupName properties
    in
    generate name 0 maybeOrder iterationCount direction maybeTargetValues discrete properties


generateRestart : Int -> Maybe (List TransformProperty) -> Builder.Iterations -> Builder.AnimationDirection -> Maybe PropertyBaselines -> DiscreteConfig -> AnimGroupName -> List Builder.ProcessedPropertyConfig -> AnimGroup
generateRestart counter maybeOrder iterationCount direction maybeTargetValues discrete animGroupName properties =
    let
        newCounter =
            counter + 1

        suffix =
            "-r" ++ String.fromInt newCounter

        name =
            generateName (Just suffix) maybeOrder discrete animGroupName properties
    in
    generate name newCounter maybeOrder iterationCount direction maybeTargetValues discrete properties



{- ***** Internal Helpers ***** -}


generate : String -> Int -> Maybe (List TransformProperty) -> Builder.Iterations -> Builder.AnimationDirection -> Maybe PropertyBaselines -> DiscreteConfig -> List Builder.ProcessedPropertyConfig -> AnimGroup
generate name counter maybeOrder iterationCount direction maybeTargetValues discrete properties =
    AnimGroup.init
        |> AnimGroup.setStyles (KeyframeStyles.fromProcessedProperties maybeOrder maybeTargetValues [] properties)
        |> AnimGroup.setRestartCounter counter
        |> AnimGroup.setIterationCount 0
        |> (\animGroup ->
                if List.isEmpty properties && Dict.isEmpty discrete.entry && Dict.isEmpty discrete.exit then
                    animGroup

                else
                    let
                        ( maxDuration, maxDelay ) =
                            getMaxTimings properties

                        keyframesString =
                            properties
                                |> generateSteps maybeOrder maybeTargetValues maxDuration maxDelay discrete
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


generateSteps : Maybe (List TransformProperty) -> Maybe PropertyBaselines -> Int -> Int -> DiscreteConfig -> List Builder.ProcessedPropertyConfig -> List ( Float, List ( String, String ) )
generateSteps maybeOrder maybeTargetValues maxDuration maxDelay discrete processedProps =
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

        discreteStylesForStep : Int -> List ( String, String )
        discreteStylesForStep stepIndex =
            let
                entryStyles =
                    discrete.entry
                        |> Dict.toList
                        |> List.map (\( prop, value ) -> ( prop, value ))

                exitStyles =
                    discrete.exit
                        |> Dict.toList
                        |> List.map
                            (\( prop, { from, to } ) ->
                                if stepIndex == totalSteps then
                                    ( prop, to )

                                else
                                    ( prop, from )
                            )
            in
            entryStyles ++ exitStyles
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
                            |> KeyframeStyles.generateTransformComponents maybeOrder
                            |> generateTransformStyle

                    otherStyles =
                        generateNonTransformStyles totalTime processedProps

                    discreteStyles =
                        discreteStylesForStep i

                    styles =
                        case transformStyle of
                            Just t ->
                                t :: otherStyles ++ discreteStyles

                            Nothing ->
                                otherStyles ++ discreteStyles
                in
                ( globalProgress, styles )
            )


generateTransformParts : Maybe PropertyBaselines -> Float -> List Builder.ProcessedPropertyConfig -> Builder.TransformParts
generateTransformParts maybeTargetValues totalTime properties =
    let
        baselineParts =
            KeyframeStyles.baselineTransformParts maybeTargetValues properties
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


generateHash : Maybe (List TransformProperty) -> DiscreteConfig -> AnimGroupName -> Int -> Int -> List Builder.ProcessedPropertyConfig -> String
generateHash maybeOrder discrete animGroupName maxDuration maxDelay processedProps =
    let
        orderHash =
            case maybeOrder of
                Nothing ->
                    ""

                Just order ->
                    "-order-" ++ (List.map TransformProperty.toString order |> String.join "-")

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

        discreteHash =
            let
                stringifyEntryDict dict =
                    dict
                        |> Dict.toList
                        |> List.map (\( prop, value ) -> "entry-" ++ prop ++ ":" ++ value)
                        |> String.join "-"

                stringifyExitDict dict =
                    dict
                        |> Dict.toList
                        |> List.map (\( prop, { from, to } ) -> "exit-" ++ prop ++ ":" ++ from ++ "->" ++ to)
                        |> String.join "-"
            in
            stringifyEntryDict discrete.entry
                ++ stringifyExitDict discrete.exit

        contentForHash =
            animGroupName
                ++ orderHash
                ++ String.fromInt maxDuration
                ++ String.fromInt maxDelay
                ++ hashConfig
                ++ discreteHash

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


generateName : Maybe String -> Maybe (List TransformProperty) -> DiscreteConfig -> AnimGroupName -> List Builder.ProcessedPropertyConfig -> String
generateName maybeSuffix maybeOrder discrete animGroupName properties =
    let
        ( maxDuration, maxDelay ) =
            getMaxTimings properties

        hash =
            generateHash maybeOrder discrete animGroupName maxDuration maxDelay properties

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
