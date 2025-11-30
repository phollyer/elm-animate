module Anim.Internal.CSS.Transition exposing
    ( calculatePropertyDistance
    , generate
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.CSS.Transform as TH
import Anim.Internal.Properties.Color as Color
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position as Position
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Timing.Delay as Delay
import Anim.Internal.Timing.Easing as Easing
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
                Just ("background-color " ++ TimeSpec.toCssString distance config.timing ++ " " ++ Easing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        Builder.OpacityConfig config ->
            if config.isDirty then
                Nothing

            else
                let
                    distance =
                        calculatePropertyDistance (Builder.OpacityConfig config)
                in
                Just ("opacity " ++ TimeSpec.toCssString distance config.timing ++ " " ++ Easing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        _ ->
            Nothing


calculatePropertyDistance : Builder.PropertyConfig -> Float
calculatePropertyDistance property =
    case property of
        Builder.PositionConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Position.fromTuple ( 0, 0 )
            in
            Position.distance startAt config.endAt

        Builder.RotateConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Rotate.fromFloat 0
            in
            Rotate.distance startAt config.endAt

        Builder.ScaleConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Scale.fromTuple ( 1, 1 )
            in
            Scale.distance startAt config.endAt

        Builder.BackgroundColorConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Color.rgb255 0 0 0
            in
            Color.distance startAt config.endAt

        Builder.OpacityConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Opacity.fromFloat 1.0
            in
            Opacity.distance startAt config.endAt

        Builder.SizeConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Size.fromTuple ( 0, 0 )
            in
            Size.distance startAt config.endAt
