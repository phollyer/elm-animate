module Anim.Internal.CSS.KeyframeAnimation exposing
    ( KeyframeAnimation
    , generate
    , toAttributeString
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position as Position
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Timing.Easing as Easing
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
                    { globalTiming = Nothing, globalEasing = Nothing, globalDelay = Nothing, currentElementId = Nothing, elements = Dict.empty, scrollTargets = [], scrollContainer = "document" }
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

                                Builder.ProcessedOpacityConfig cfg ->
                                    cfg.delay

                                Builder.ProcessedSizeConfig cfg ->
                                    cfg.delay
                        )
                    |> List.maximum
                    |> Maybe.withDefault 0

            keyframeCount =
                30

            keyframeSteps =
                List.range 0 keyframeCount
                    |> List.map
                        (\i ->
                            let
                                globalProgress =
                                    toFloat i / toFloat keyframeCount

                                time =
                                    globalProgress * toFloat maxDuration

                                -- Collect transform components using canonical ordering pattern
                                transformParts =
                                    processedProps
                                        |> List.foldl
                                            (\p acc ->
                                                case p of
                                                    Builder.ProcessedPositionConfig cfg ->
                                                        let
                                                            dur =
                                                                cfg.duration

                                                            linearProgress =
                                                                if time == 0 || dur == 0 then
                                                                    0

                                                                else if time <= toFloat dur then
                                                                    time / toFloat dur

                                                                else
                                                                    1.0

                                                            -- Apply easing to the linear progress
                                                            easingFunction =
                                                                Easing.toFunction cfg.easing

                                                            propProgress =
                                                                easingFunction linearProgress

                                                            startPos =
                                                                case cfg.startAt of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Position.fromTuple ( 0.0, 0.0 )

                                                            endPos =
                                                                cfg.endAt

                                                            interpolatedPos =
                                                                Position.interpolate propProgress startPos endPos
                                                        in
                                                        { acc | position = "translate(" ++ Position.toCssString interpolatedPos ++ ")" }

                                                    Builder.ProcessedRotateConfig cfg ->
                                                        let
                                                            dur =
                                                                cfg.duration

                                                            linearProgress =
                                                                if time == 0 || dur == 0 then
                                                                    0

                                                                else if time <= toFloat dur then
                                                                    time / toFloat dur

                                                                else
                                                                    1.0

                                                            -- Apply easing to the linear progress
                                                            easingFunction =
                                                                Easing.toFunction cfg.easing

                                                            propProgress =
                                                                easingFunction linearProgress

                                                            startRot =
                                                                case cfg.startAt of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Rotate.fromFloat 0.0

                                                            endRot =
                                                                cfg.endAt

                                                            startAngle =
                                                                Rotate.toFloat startRot

                                                            endAngle =
                                                                Rotate.toFloat endRot

                                                            interpolatedAngle =
                                                                startAngle + (endAngle - startAngle) * propProgress

                                                            interpolatedRot =
                                                                Rotate.fromFloat interpolatedAngle
                                                        in
                                                        { acc | rotate = "rotate(" ++ Rotate.toCssString interpolatedRot ++ ")" }

                                                    Builder.ProcessedScaleConfig cfg ->
                                                        let
                                                            dur =
                                                                cfg.duration

                                                            linearProgress =
                                                                if dur > 0 then
                                                                    clamp 0 1 (time / toFloat dur)

                                                                else
                                                                    1.0

                                                            -- Apply easing to the linear progress
                                                            easingFunction =
                                                                Easing.toFunction cfg.easing

                                                            propProgress =
                                                                easingFunction linearProgress

                                                            startScale =
                                                                case cfg.startAt of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Scale.fromTuple ( 1.0, 1.0 )

                                                            endScale =
                                                                cfg.endAt

                                                            ( startX, startY ) =
                                                                Scale.toTuple startScale

                                                            ( endX, endY ) =
                                                                Scale.toTuple endScale

                                                            interpolatedX =
                                                                startX + (endX - startX) * propProgress

                                                            interpolatedY =
                                                                startY + (endY - startY) * propProgress

                                                            interpolatedScale =
                                                                Scale.fromTuple ( interpolatedX, interpolatedY )
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
                                                            dur =
                                                                cfg.duration

                                                            linearProgress =
                                                                if dur > 0 then
                                                                    clamp 0 1 (time / toFloat dur)

                                                                else
                                                                    1.0

                                                            -- Apply easing to the linear progress
                                                            easingFunction =
                                                                Easing.toFunction cfg.easing

                                                            propProgress =
                                                                easingFunction linearProgress

                                                            startColor =
                                                                case cfg.startAt of
                                                                    Just c ->
                                                                        c

                                                                    Nothing ->
                                                                        BackgroundColor.rgb255 59 130 246

                                                            endColor =
                                                                cfg.endAt

                                                            interpolatedColor =
                                                                BackgroundColor.interpolate startColor endColor propProgress
                                                        in
                                                        Just
                                                            [ ( "background-color", BackgroundColor.toString interpolatedColor ) ]

                                                    Builder.ProcessedOpacityConfig cfg ->
                                                        let
                                                            dur =
                                                                cfg.duration

                                                            linearProgress =
                                                                if time <= toFloat dur then
                                                                    time / toFloat dur

                                                                else
                                                                    1.0

                                                            -- Apply easing to the linear progress
                                                            easingFunction =
                                                                Easing.toFunction cfg.easing

                                                            propProgress =
                                                                easingFunction linearProgress

                                                            startOpacity =
                                                                case cfg.startAt of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Opacity.fromFloat 1.0

                                                            endOpacity =
                                                                cfg.endAt

                                                            startValue =
                                                                Opacity.toFloat startOpacity

                                                            endValue =
                                                                Opacity.toFloat endOpacity

                                                            interpolatedValue =
                                                                startValue + (endValue - startValue) * propProgress

                                                            interpolatedOpacity =
                                                                Opacity.fromFloat interpolatedValue
                                                        in
                                                        Just
                                                            [ ( "opacity", Opacity.toString interpolatedOpacity ) ]

                                                    Builder.ProcessedSizeConfig cfg ->
                                                        let
                                                            dur =
                                                                cfg.duration

                                                            linearProgress =
                                                                if dur > 0 then
                                                                    clamp 0 1 (time / toFloat dur)

                                                                else
                                                                    1.0

                                                            -- Apply easing to the linear progress
                                                            easingFunction =
                                                                Easing.toFunction cfg.easing

                                                            propProgress =
                                                                easingFunction linearProgress

                                                            startSize =
                                                                case cfg.startAt of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Size.fromTuple ( 100.0, 100.0 )

                                                            endSize =
                                                                cfg.endAt

                                                            ( startW, startH ) =
                                                                Size.toTuple startSize

                                                            ( endW, endH ) =
                                                                Size.toTuple endSize

                                                            interpolatedW =
                                                                startW + (endW - startW) * propProgress

                                                            interpolatedH =
                                                                startH + (endH - startH) * propProgress
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
                    ++ (processedProps
                            |> List.map
                                (\p ->
                                    case p of
                                        Builder.ProcessedPositionConfig cfg ->
                                            "pos" ++ String.fromInt cfg.duration ++ Position.toCssString cfg.endAt

                                        Builder.ProcessedScaleConfig cfg ->
                                            "scale" ++ String.fromInt cfg.duration ++ Scale.toCssString cfg.endAt

                                        Builder.ProcessedRotateConfig cfg ->
                                            "rot" ++ String.fromInt cfg.duration ++ Rotate.toCssString cfg.endAt

                                        Builder.ProcessedBackgroundColorConfig cfg ->
                                            "background-color" ++ String.fromInt cfg.duration ++ BackgroundColor.toString cfg.endAt

                                        Builder.ProcessedOpacityConfig cfg ->
                                            "opacity" ++ String.fromInt cfg.duration ++ Opacity.toString cfg.endAt

                                        Builder.ProcessedSizeConfig cfg ->
                                            "size" ++ String.fromInt cfg.duration ++ Size.toString cfg.endAt
                                )
                            |> String.join ""
                       )

            simpleHash =
                contentForHash
                    |> String.toList
                    |> List.map Char.toCode
                    |> List.sum
                    |> modBy 999999

            animationName =
                elementId ++ "-anim-" ++ String.fromInt simpleHash

            keyframesString =
                buildKeyframesString animationName keyframeSteps

            animatedProperties =
                [ "transform", "background-color", "opacity", "width", "height" ]
        in
        [ { animationName = animationName
          , keyframes = keyframesString
          , duration = maxDuration
          , easing = "linear"
          , delay = maxDelay
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
