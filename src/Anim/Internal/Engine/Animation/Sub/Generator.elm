module Anim.Internal.Engine.Animation.Sub.Generator exposing (generateAnimation, init)

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Builder.FontColor as FontColor
import Anim.Internal.Engine.Animation.PlayState as PlayState
import Anim.Internal.Engine.Animation.Sub.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Animation.Sub.Animation exposing (Animation(..), PropertyAnimation)
import Anim.Internal.Engine.Animation.Sub.Animations as Animations
import Anim.Internal.Extra.Easing as Easing
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Translate as Translate
import Dict exposing (Dict)


init : Dict String Builder.DiscreteEntryProperty -> Dict String Builder.DiscreteExitProperty -> List Builder.PropertyConfig -> AnimGroup
init discreteEntryProps discreteExitProps properties =
    let
        processedProps =
            Builder.processProperties Builder.initDefaults properties

        animations =
            List.filterMap (toAnimation True) processedProps
                |> Animations.fromList
    in
    AnimGroup.init
        |> AnimGroup.setPlayState PlayState.Complete
        |> AnimGroup.setAnimations animations
        |> AnimGroup.setDiscreteEntry discreteEntryProps
        |> AnimGroup.setDiscreteExit discreteExitProps


generateAnimation :
    Builder.Iterations
    -> List TransformProperty
    -> Dict String Builder.DiscreteEntryProperty
    -> Dict String Builder.DiscreteExitProperty
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
        |> AnimGroup.setPlayState PlayState.Running
        |> AnimGroup.setIterationCount iterationCount
        |> AnimGroup.setCurrentIteration 1
        |> AnimGroup.setTransformOrder order
        |> AnimGroup.setDiscreteEntry discreteEntryProps
        |> AnimGroup.setDiscreteExit discreteExitProps


toAnimation : Bool -> Builder.ProcessedPropertyConfig -> Maybe ( String, Animation )
toAnimation isComplete propertyConfig =
    let
        build : property -> Builder.ProcessedAnimationConfig property -> PropertyAnimation property
        build default config =
            { start = Maybe.withDefault default config.start
            , end = config.end
            , easingFunction = Easing.toFunction (toFloat config.duration) config.easing
            , delayMs = toFloat config.delay
            , isComplete = isComplete
            , totalDurationMs = toFloat config.duration
            , elapsedMs = 0.0
            }
    in
    case propertyConfig of
        Builder.ProcessedBackgroundColorConfig config ->
            Just
                ( "backgroundColor"
                , BackgroundColor <|
                    build BackgroundColor.default config
                )

        Builder.ProcessedFontColorConfig config ->
            Just
                ( "fontColor"
                , FontColor <|
                    build FontColor.default config
                )

        Builder.ProcessedOpacityConfig config ->
            Just
                ( "opacity"
                , Opacity <|
                    build Opacity.default config
                )

        Builder.ProcessedRotateConfig config ->
            Just
                ( "rotate"
                , Rotate <|
                    build Rotate.default config
                )

        Builder.ProcessedScaleConfig config ->
            Just
                ( "scale"
                , Scale <|
                    build Scale.default config
                )

        Builder.ProcessedSizeConfig config ->
            Just
                ( "size"
                , Size <|
                    build Size.default config
                )

        Builder.ProcessedTranslateConfig config ->
            Just
                ( "translate"
                , Translate <|
                    build Translate.default config
                )
