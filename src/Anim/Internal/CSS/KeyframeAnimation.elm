module Anim.Internal.CSS.KeyframeAnimation exposing
    ( KeyframeAnimation
    , generate
    , toAttributeString
    )

import Anim.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.Easing as Easing
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Color as Color exposing (Color(..))
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position as Position
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Char
import Dict


type alias KeyframeAnimation =
    { animationName : String
    , keyframes : String
    , duration : Int
    , easing : String
    , delay : Int
    , properties : List String -- Properties this layer animates
    }


{-| Generate animation layers for an element's properties, supporting multiple simultaneous animations.
-}
generate : String -> List Builder.PropertyConfig -> List KeyframeAnimation
generate elementId properties =
    if List.isEmpty properties then
        []

    else
        let
            processed =
                Builder.processElement
                    { globalTiming = Nothing, globalEasing = Nothing, globalDelay = Nothing, globalPerspective = Nothing, currentElementId = Nothing, elements = Dict.empty, scrollTargets = [], scrollContainer = "document", perspectiveStylesCache = Nothing, animationHistories = Dict.empty, nextAnimationId = 0, elementBaselines = Dict.empty }
                    { properties = properties }

            processedProps =
                processed.properties

            maxDuration =
                processedProps
                    |> List.map
                        (\p ->
                            case p of
                                Builder.ProcessedPositionConfig cfg ->
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
                                Builder.ProcessedPositionConfig cfg ->
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
                                    in
                                    Easing.toFunction easing linearProgress

                                -- Collect transform components (order will be enforced during assembly)
                                transformParts =
                                    processedProps
                                        |> List.foldl
                                            (\p acc ->
                                                case p of
                                                    Builder.ProcessedPositionConfig cfg ->
                                                        let
                                                            progress =
                                                                calculateProgress cfg.delay cfg.duration cfg.easing

                                                            startPos =
                                                                case cfg.start of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Position.default

                                                            interpolatedPos =
                                                                Position.interpolate progress startPos cfg.end
                                                        in
                                                        { acc | position = "translate3d(" ++ Position.toCssString interpolatedPos ++ ")" }

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
                                                        { acc | rotate = Rotate.to3DCssString interpolatedRot }

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
                                            { position = "", rotate = "", scale = "" }

                                -- Build transform string with canonical ordering: translate rotate scale
                                transformComponents =
                                    [ transformParts.position, transformParts.rotate, transformParts.scale ]
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
                                        Builder.ProcessedPositionConfig cfg ->
                                            "pos-" ++ String.fromInt cfg.duration ++ "-" ++ String.fromInt cfg.delay ++ "-" ++ Position.toCssString cfg.end ++ "-" ++ (cfg.start |> Maybe.map Position.toCssString |> Maybe.withDefault "none")

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
                elementId ++ "-anim-" ++ String.fromInt betterHash

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
          }
        ]


toAttributeString : List KeyframeAnimation -> String
toAttributeString animationLayers =
    if not (List.isEmpty animationLayers) then
        animationLayers
            |> List.map
                (\layer ->
                    layer.animationName
                        ++ " "
                        ++ String.fromInt layer.duration
                        ++ "ms "
                        ++ layer.easing
                        ++ " "
                        ++ String.fromInt layer.delay
                        ++ "ms forwards"
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
