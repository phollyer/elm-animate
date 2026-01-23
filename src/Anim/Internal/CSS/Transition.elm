module Anim.Internal.CSS.Transition exposing
    ( calculatePropertyDistance
    , generate
    , generateFromProcessed
    )

import Anim.Easing as Easing
import Anim.Internal.Builder as Builder
import Anim.Internal.CSS.Transform as TH
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
        transformProperties =
            List.filter TH.isTransformProperty properties

        nonTransformTransitions =
            List.filterMap transitionFromNonTransformProperty properties

        -- Generate single consolidated transform transition
        transformTransition =
            case TH.consolidateTiming transformProperties of
                Just transition ->
                    [ transition ]

                Nothing ->
                    []

        allTransitions =
            transformTransition ++ nonTransformTransitions
    in
    String.join ", " allTransitions


transitionFromNonTransformProperty : Builder.PropertyConfig -> Maybe String
transitionFromNonTransformProperty property =
    case property of
        Builder.BackgroundColorConfig config ->
            if config.isDirty then
                Nothing

            else
                let
                    distance =
                        calculatePropertyDistance (Builder.BackgroundColorConfig config)
                in
                Just ("background-color " ++ TimeSpec.toCssString distance config.timing ++ " " ++ InternalEasing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        Builder.OpacityConfig config ->
            if config.isDirty then
                Nothing

            else
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
            -- Separate transform and non-transform properties
            ( transformProps, nonTransformProps ) =
                List.partition isProcessedTransformProperty properties

            -- Generate non-transform transitions
            nonTransformTransitions =
                List.filterMap transitionFromProcessedNonTransform nonTransformProps

            -- Generate single consolidated transform transition
            transformTransition =
                case consolidateProcessedTiming transformProps of
                    Just transition ->
                        [ transition ]

                    Nothing ->
                        []

            allTransitions =
                transformTransition ++ nonTransformTransitions
        in
        String.join ", " allTransitions


isProcessedTransformProperty : Builder.ProcessedPropertyConfig -> Bool
isProcessedTransformProperty property =
    case property of
        Builder.ProcessedTranslateConfig _ ->
            True

        Builder.ProcessedRotateConfig _ ->
            True

        Builder.ProcessedScaleConfig _ ->
            True

        _ ->
            False


transitionFromProcessedNonTransform : Builder.ProcessedPropertyConfig -> Maybe String
transitionFromProcessedNonTransform property =
    case property of
        Builder.ProcessedBackgroundColorConfig config ->
            Just ("background-color " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedOpacityConfig config ->
            Just ("opacity " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        _ ->
            Nothing


consolidateProcessedTiming : List Builder.ProcessedPropertyConfig -> Maybe String
consolidateProcessedTiming transformProps =
    case transformProps of
        [] ->
            Nothing

        _ ->
            let
                longestDuration =
                    transformProps
                        |> List.map extractProcessedDuration
                        |> List.maximum
                        |> Maybe.withDefault 0

                latestEasing =
                    transformProps
                        |> List.map extractProcessedEasing
                        |> List.head
                        |> Maybe.withDefault Easing.EaseInOut

                earliestDelay =
                    transformProps
                        |> List.map extractProcessedDelay
                        |> List.minimum
                        |> Maybe.withDefault 0
            in
            Just ("transform " ++ String.fromInt longestDuration ++ "ms " ++ InternalEasing.toCSS (Just latestEasing) ++ " " ++ String.fromInt earliestDelay ++ "ms")


extractProcessedDuration : Builder.ProcessedPropertyConfig -> Int
extractProcessedDuration property =
    case property of
        Builder.ProcessedTranslateConfig config ->
            config.duration

        Builder.ProcessedRotateConfig config ->
            config.duration

        Builder.ProcessedScaleConfig config ->
            config.duration

        _ ->
            0


extractProcessedEasing : Builder.ProcessedPropertyConfig -> Easing.Easing
extractProcessedEasing property =
    case property of
        Builder.ProcessedTranslateConfig config ->
            config.easing

        Builder.ProcessedRotateConfig config ->
            config.easing

        Builder.ProcessedScaleConfig config ->
            config.easing

        _ ->
            Easing.EaseInOut


extractProcessedDelay : Builder.ProcessedPropertyConfig -> Int
extractProcessedDelay property =
    case property of
        Builder.ProcessedTranslateConfig config ->
            config.delay

        Builder.ProcessedRotateConfig config ->
            config.delay

        Builder.ProcessedScaleConfig config ->
            config.delay

        _ ->
            0
