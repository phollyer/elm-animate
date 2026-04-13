module Anim.Internal.Engine.Animation.Sub.Generator exposing (generateAnimation, init)

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Builder.FontColor as FontColor
import Anim.Internal.Engine.Animation.Sub.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Animation.Sub.Animation exposing (Animation(..))
import Anim.Internal.Engine.Animation.Sub.Animations as Animations
import Anim.Internal.Extra.Easing as Easing
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Translate as Translate
import Dict exposing (Dict)


init : Dict String String -> Dict String Builder.DiscreteKeyframeProperty -> List Builder.PropertyConfig -> AnimGroup
init discreteEntryProps discreteExitProps properties =
    let
        processedProps =
            Builder.processProperties Builder.initDefaults properties

        animations =
            List.filterMap (toAnimation True) processedProps
                |> Animations.fromList
    in
    AnimGroup.init
        |> AnimGroup.setIsComplete True
        |> AnimGroup.setAnimations animations
        |> AnimGroup.setDiscreteEntry discreteEntryProps
        |> AnimGroup.setDiscreteExit discreteExitProps


generateAnimation :
    Builder.Iterations
    -> List TransformProperty
    -> Dict String String
    -> Dict String Builder.DiscreteKeyframeProperty
    -> List Builder.ProcessedPropertyConfig
    -> AnimGroup
generateAnimation iterationCount order discreteEntryProps discreteExitProps properties =
    let
        animations =
            List.filterMap (toAnimation False) properties
                |> Animations.fromList
    in
    AnimGroup.init
        |> AnimGroup.setAnimations animations
        |> AnimGroup.setIterationCount iterationCount
        |> AnimGroup.setCurrentIteration 1
        |> AnimGroup.setTransformOrder order
        |> AnimGroup.setDiscreteEntry discreteEntryProps
        |> AnimGroup.setDiscreteExit discreteExitProps


toAnimation : Bool -> Builder.ProcessedPropertyConfig -> Maybe ( String, Animation )
toAnimation isComplete property =
    let
        build start end duration_ delay_ easing_ =
            { startValue = start
            , endValue = end
            , easingFunction = Easing.toFunction (toFloat duration_) easing_
            , delayMs = toFloat delay_
            , isComplete = isComplete
            , totalDurationMs = toFloat duration_
            , elapsedMs = 0.0
            }
    in
    case property of
        Builder.ProcessedTranslateConfig config ->
            Just
                ( "translate"
                , Translate
                    (build (Maybe.withDefault Translate.default config.start) config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedRotateConfig config ->
            Just
                ( "rotate"
                , Rotate
                    (build (Maybe.withDefault Rotate.default config.start) config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedScaleConfig config ->
            Just
                ( "scale"
                , Scale
                    (build (Maybe.withDefault Scale.default config.start) config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedBackgroundColorConfig config ->
            Just
                ( "backgroundColor"
                , BackgroundColor
                    (build (Maybe.withDefault BackgroundColor.default config.start) config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedFontColorConfig config ->
            Just
                ( "fontColor"
                , FontColor
                    (build (Maybe.withDefault FontColor.default config.start) config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedOpacityConfig config ->
            Just
                ( "opacity"
                , Opacity
                    (build (Maybe.withDefault Opacity.default config.start) config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedSizeConfig config ->
            Just
                ( "size"
                , Size
                    (build (Maybe.withDefault Size.default config.start) config.end config.duration config.delay config.easing)
                )
