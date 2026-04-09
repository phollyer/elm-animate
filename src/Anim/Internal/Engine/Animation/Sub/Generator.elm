module Anim.Internal.Engine.Animation.Sub.Generator exposing (init)

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


init : List Builder.PropertyConfig -> AnimGroup
init properties =
    let
        processedProps =
            Builder.processProperties Builder.initDefaults properties

        animations =
            List.filterMap toCompletedAnimation processedProps
                |> Animations.fromList
    in
    AnimGroup.init
        |> AnimGroup.setIsComplete True
        |> AnimGroup.setAnimations animations


toCompletedAnimation : Builder.ProcessedPropertyConfig -> Maybe ( String, Animation )
toCompletedAnimation property =
    let
        complete start end duration_ delay_ easing_ =
            { startValue = start
            , endValue = end
            , easingFunction = Easing.toFunction (toFloat duration_) easing_
            , delayMs = toFloat delay_
            , isComplete = True
            , totalDurationMs = toFloat duration_
            , elapsedMs = 0.0
            }
    in
    case property of
        Builder.ProcessedTranslateConfig config ->
            Just
                ( "translate"
                , Translate
                    (complete (Maybe.withDefault Translate.default config.start) config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedRotateConfig config ->
            Just
                ( "rotate"
                , Rotate
                    (complete (Maybe.withDefault Rotate.default config.start) config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedScaleConfig config ->
            Just
                ( "scale"
                , Scale
                    (complete (Maybe.withDefault Scale.default config.start) config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedBackgroundColorConfig config ->
            Just
                ( "backgroundColor"
                , BackgroundColor
                    (complete (Maybe.withDefault BackgroundColor.default config.start) config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedFontColorConfig config ->
            Just
                ( "fontColor"
                , FontColor
                    (complete (Maybe.withDefault FontColor.default config.start) config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedOpacityConfig config ->
            Just
                ( "opacity"
                , Opacity
                    (complete (Maybe.withDefault Opacity.default config.start) config.end config.duration config.delay config.easing)
                )

        Builder.ProcessedSizeConfig config ->
            Just
                ( "size"
                , Size
                    (complete (Maybe.withDefault Size.default config.start) config.end config.duration config.delay config.easing)
                )
