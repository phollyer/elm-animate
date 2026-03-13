module Anim.Internal.CSS.Transition exposing
    ( calculatePropertyDistance
    , generate
    , generateFromProcessed
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.Easing as InternalEasing
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Color as Color exposing (Color(..))
import Anim.Internal.Properties.FontColor as FontColor
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate as Translate
import Anim.Internal.Timing.Delay as Delay
import Anim.Internal.Timing.TimeSpec as TimeSpec


generate : List Builder.PropertyConfig -> String
generate properties =
    let
        allTransitions =
            List.filterMap transitionFromProperty properties
    in
    String.join ", " allTransitions


transitionFromProperty : Builder.PropertyConfig -> Maybe String
transitionFromProperty property =
    case property of
        Builder.TranslateConfig config ->
            let
                distance =
                    calculatePropertyDistance (Builder.TranslateConfig config)
            in
            Just ("translate " ++ TimeSpec.toCssString distance config.timing ++ " " ++ InternalEasing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        Builder.RotateConfig config ->
            let
                distance =
                    calculatePropertyDistance (Builder.RotateConfig config)
            in
            Just ("transform " ++ TimeSpec.toCssString distance config.timing ++ " " ++ InternalEasing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        Builder.ScaleConfig config ->
            let
                distance =
                    calculatePropertyDistance (Builder.ScaleConfig config)
            in
            Just ("scale " ++ TimeSpec.toCssString distance config.timing ++ " " ++ InternalEasing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        Builder.BackgroundColorConfig config ->
            let
                distance =
                    calculatePropertyDistance (Builder.BackgroundColorConfig config)
            in
            Just ("background-color " ++ TimeSpec.toCssString distance config.timing ++ " " ++ InternalEasing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        Builder.OpacityConfig config ->
            let
                distance =
                    calculatePropertyDistance (Builder.OpacityConfig config)
            in
            Just ("opacity " ++ TimeSpec.toCssString distance config.timing ++ " " ++ InternalEasing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        _ ->
            Nothing


calculatePropertyDistance : Builder.PropertyConfig -> Float
calculatePropertyDistance property =
    case property of
        Builder.TranslateConfig config ->
            let
                start =
                    case config.start of
                        Just s ->
                            s

                        Nothing ->
                            Translate.fromTuple ( 0, 0 )
            in
            Translate.distance start config.end

        Builder.RotateConfig config ->
            let
                start =
                    case config.start of
                        Just s ->
                            s

                        Nothing ->
                            Rotate.fromFloat 0
            in
            Rotate.distance start config.end

        Builder.ScaleConfig config ->
            let
                start =
                    case config.start of
                        Just s ->
                            s

                        Nothing ->
                            Scale.fromTuple ( 1, 1 )
            in
            Scale.distance start config.end

        Builder.BackgroundColorConfig config ->
            let
                start =
                    case config.start of
                        Just s ->
                            s

                        Nothing ->
                            BackgroundColor.default
            in
            Color.distance start config.end

        Builder.FontColorConfig config ->
            let
                start =
                    case config.start of
                        Just s ->
                            s

                        Nothing ->
                            FontColor.default
            in
            Color.distance start config.end

        Builder.OpacityConfig config ->
            let
                start =
                    case config.start of
                        Just s ->
                            s

                        Nothing ->
                            Opacity.fromFloat 1.0
            in
            Opacity.distance start config.end

        Builder.SizeConfig config ->
            let
                start =
                    case config.start of
                        Just s ->
                            s

                        Nothing ->
                            Size.fromTuple ( 0, 0 )
            in
            Size.distance start config.end


{-| Generate transitions from processed properties. This is the new unified approach
that treats all properties consistently, whether dirty or clean.
-}
generateFromProcessed : List Builder.ProcessedPropertyConfig -> String
generateFromProcessed properties =
    let
        -- Check if all durations are 0ms (stop/reset case)
        allDurationsZero =
            properties
                |> List.all
                    (\prop ->
                        case prop of
                            Builder.ProcessedTranslateConfig config ->
                                config.duration == 0

                            Builder.ProcessedRotateConfig config ->
                                config.duration == 0

                            Builder.ProcessedScaleConfig config ->
                                config.duration == 0

                            Builder.ProcessedBackgroundColorConfig config ->
                                config.duration == 0

                            Builder.ProcessedOpacityConfig config ->
                                config.duration == 0

                            _ ->
                                True
                    )
    in
    if allDurationsZero then
        -- Use "none" to cancel running transitions when stopping
        "none"

    else
        let
            allTransitions =
                List.filterMap transitionFromProcessed properties
        in
        String.join ", " allTransitions


transitionFromProcessed : Builder.ProcessedPropertyConfig -> Maybe String
transitionFromProcessed property =
    case property of
        Builder.ProcessedTranslateConfig config ->
            Just ("translate " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedRotateConfig config ->
            Just ("transform " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedScaleConfig config ->
            Just ("scale " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedBackgroundColorConfig config ->
            Just ("background-color " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedOpacityConfig config ->
            Just ("opacity " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        _ ->
            Nothing
