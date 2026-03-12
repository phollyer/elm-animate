module Anim.Internal.CSS.KeyframeAnimation exposing
    ( KeyframeAnimation
    , generate
    , generateFromProcessed
    , generateWithSuffix
    , generateWithSuffixFromProcessed
    , setDirection
    , setIterationCount
    , toAttributeString
    )

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.Easing as Easing
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Color as Color exposing (Color(..))
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate as Translate
import Char
import Dict


type alias KeyframeAnimation =
    { animationName : String
    , keyframes : String
    , duration : Int
    , easing : String
    , delay : Int
    , properties : List String -- Properties this layer animates
    , iterationCount : Builder.IterationCount
    , direction : Builder.AnimationDirection
    }


{-| Generate animation layers for an element's properties, supporting multiple simultaneous animations.
-}
generate : String -> List Builder.PropertyConfig -> List KeyframeAnimation
generate elementId properties =
    generateWithSuffix elementId "" properties


{-| Generate animation layers from already-processed properties.
-}
generateFromProcessed : String -> List Builder.ProcessedPropertyConfig -> List KeyframeAnimation
generateFromProcessed elementId processedProps =
    generateWithSuffixFromProcessed elementId "" processedProps


{-| Generate animation layers with an optional suffix for the animation name.
Used for restarting animations - passing a unique suffix forces the browser to treat it as a new animation.
-}
generateWithSuffix : String -> String -> List Builder.PropertyConfig -> List KeyframeAnimation
generateWithSuffix elementId suffix properties =
    if List.isEmpty properties then
        []

    else
        let
            processed =
                Builder.processElement
                    { globalTiming = Nothing, globalEasing = Nothing, globalDelay = Nothing, globalTransformOrder = Nothing, currentElementId = Nothing, elements = Dict.empty, scrollTargets = [], scrollContainer = "document", animationHistories = Dict.empty, nextAnimationId = 0, elementBaselines = Dict.empty, discreteTransitions = False, iterationCount = Builder.Once, animationDirection = Builder.Normal, targetElement = Nothing }
                    { properties = properties, targetElement = Nothing }
        in
        generateWithSuffixFromProcessed elementId suffix processed.properties


{-| Generate animation layers with a suffix, from already-processed properties.
Used for restarting animations from history where properties are already processed.
-}
generateWithSuffixFromProcessed : String -> String -> List Builder.ProcessedPropertyConfig -> List KeyframeAnimation
generateWithSuffixFromProcessed elementId suffix processedProps =
    if List.isEmpty processedProps then
        []

    else
        let
            maxDuration =
                processedProps
                    |> List.map
                        (\p ->
                            case p of
                                Builder.ProcessedTranslateConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedScaleConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedRotateConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedBackgroundColorConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedFontColorConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedOpacityConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedSizeConfig cfg ->
                                    cfg.duration
                        )
                    |> List.maximum
                    |> Maybe.withDefault 0

            -- Extract the maximum delay from all properties
            maxDelay =
                processedProps
                    |> List.map
                        (\p ->
                            case p of
                                Builder.ProcessedTranslateConfig cfg ->
                                    cfg.delay

                                Builder.ProcessedScaleConfig cfg ->
                                    cfg.delay

                                Builder.ProcessedRotateConfig cfg ->
                                    cfg.delay

                                Builder.ProcessedBackgroundColorConfig cfg ->
                                    cfg.delay

                                Builder.ProcessedFontColorConfig cfg ->
                                    cfg.delay

                                Builder.ProcessedOpacityConfig cfg ->
                                    cfg.delay

                                Builder.ProcessedSizeConfig cfg ->
                                    cfg.delay
                        )
                    |> List.maximum
                    |> Maybe.withDefault 0

            -- Calculate total animation time (max duration + max delay)
            totalAnimationTime =
                maxDuration + maxDelay

            keyframeCount =
                30

            keyframeSteps =
                List.range 0 keyframeCount
                    |> List.map
                        (\i ->
                            let
                                globalProgress =
                                    toFloat i / toFloat keyframeCount

                                -- Total time from start including delays
                                totalTime =
                                    globalProgress * toFloat totalAnimationTime

                                -- Helper function to calculate progress for any property
                                calculateProgress : Int -> Int -> Easing -> Float
                                calculateProgress delay duration easing =
                                    let
                                        linearProgress =
                                            if totalTime < toFloat delay then
                                                -- Still in delay phase, no progress
                                                0

                                            else if duration == 0 then
                                                -- Instant animation after delay
                                                1.0

                                            else
                                                -- Animation phase: (totalTime - delay) / duration
                                                let
                                                    animationTime =
                                                        totalTime - toFloat delay
                                                in
                                                clamp 0 1 (animationTime / toFloat duration)

                                        easingFunction =
                                            Easing.toFunction (toFloat duration) easing
                                    in
                                    easingFunction linearProgress

                                -- Collect transform components (order will be enforced during assembly)
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
                                                        { acc | scale = "scale(" ++ Scale.toCssString interpolatedScale ++ ")" }

                                                    _ ->
                                                        acc
                                            )
                                            { translate = "", rotate = "", scale = "" }

                                -- Build transform string with canonical ordering: translate rotate scale
                                transformComponents =
                                    [ transformParts.translate, transformParts.rotate, transformParts.scale ]
                                        |> List.filter (\s -> s /= "")

                                transformStyle =
                                    if List.isEmpty transformComponents then
                                        Nothing

                                    else
                                        Just ( "transform", String.join " " transformComponents )

                                -- Collect non-transform styles
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

            -- Generate a unique animation name based on content hash
            contentForHash =
                elementId
                    ++ String.fromInt maxDuration
                    ++ String.fromInt maxDelay
                    ++ (processedProps
                            |> List.map
                                (\p ->
                                    case p of
                                        Builder.ProcessedTranslateConfig cfg ->
                                            "pos-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Translate.toCssString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Translate.toCssString |> Maybe.withDefault "none")

                                        Builder.ProcessedScaleConfig cfg ->
                                            "scale-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Scale.toCssString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Scale.toCssString |> Maybe.withDefault "none")

                                        Builder.ProcessedRotateConfig cfg ->
                                            "rot-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Rotate.toCssString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Rotate.toCssString |> Maybe.withDefault "none")

                                        Builder.ProcessedBackgroundColorConfig cfg ->
                                            "bg-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Color.toCssString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Color.toCssString |> Maybe.withDefault "none")

                                        Builder.ProcessedFontColorConfig cfg ->
                                            "color-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Color.toCssString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Color.toCssString |> Maybe.withDefault "none")

                                        Builder.ProcessedOpacityConfig cfg ->
                                            "opacity-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Opacity.toString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Opacity.toString |> Maybe.withDefault "none")

                                        Builder.ProcessedSizeConfig cfg ->
                                            "size-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Size.toString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Size.toString |> Maybe.withDefault "none")
                                )
                            |> String.join "-"
                       )

            -- Better hash function to reduce collisions
            betterHash =
                contentForHash
                    |> String.toList
                    |> List.foldl
                        (\char acc ->
                            let
                                code =
                                    Char.toCode char
                            in
                            -- Polynomial rolling hash with prime multiplier
                            (acc * 31 + code) |> modBy 1000000007
                        )
                        0

            animationName =
                elementId
                    ++ "-anim-"
                    ++ String.fromInt betterHash
                    ++ (if String.isEmpty suffix then
                            ""

                        else
                            "-" ++ suffix
                       )

            keyframesString =
                buildKeyframesString animationName keyframeSteps

            animatedProperties =
                [ "transform", "background-color", "opacity", "width", "height" ]
        in
        [ { animationName = animationName
          , keyframes = keyframesString
          , duration = totalAnimationTime
          , easing = "linear"
          , delay = 0
          , properties = animatedProperties
          , iterationCount = Builder.Once -- Default, can be overridden via setIterationCount
          , direction = Builder.Normal -- Default, can be overridden via setDirection
          }
        ]


{-| Set the iteration count on all animation layers.
-}
setIterationCount : Builder.IterationCount -> List KeyframeAnimation -> List KeyframeAnimation
setIterationCount count layers =
    List.map (\layer -> { layer | iterationCount = count }) layers


setDirection : Builder.AnimationDirection -> List KeyframeAnimation -> List KeyframeAnimation
setDirection dir layers =
    List.map (\layer -> { layer | direction = dir }) layers


toAttributeString : List KeyframeAnimation -> String
toAttributeString animationLayers =
    if not (List.isEmpty animationLayers) then
        animationLayers
            |> List.map
                (\layer ->
                    let
                        iterationString =
                            case layer.iterationCount of
                                Builder.Once ->
                                    "1"

                                Builder.Times n ->
                                    String.fromInt n

                                Builder.Infinite ->
                                    "infinite"

                        directionString =
                            case layer.direction of
                                Builder.Normal ->
                                    "normal"

                                Builder.Alternate ->
                                    "alternate"
                    in
                    layer.animationName
                        ++ " "
                        ++ String.fromInt layer.duration
                        ++ "ms "
                        ++ layer.easing
                        ++ " "
                        ++ String.fromInt layer.delay
                        ++ "ms "
                        ++ iterationString
                        ++ " "
                        ++ directionString
                        ++ " forwards"
                )
            |> String.join ", "

    else
        ""


buildKeyframesString : String -> List ( Float, List ( String, String ) ) -> String
buildKeyframesString elementId steps =
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
                ++ elementId
                ++ " */\n"
    in
    "@keyframes " ++ elementId ++ " {\n" ++ stepsString ++ "\n}" ++ animationPropertiesComment
