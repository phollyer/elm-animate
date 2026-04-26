module Anim.Internal.Engine.Sub.Generator exposing (generateAnimation, init)

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.PlayState as PlayState
import Anim.Internal.Engine.Sub.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Sub.Animation exposing (Animation(..), PropertyAnimation)
import Anim.Internal.Engine.Sub.Animations as Animations
import Anim.Internal.Extra.Color as Color
import Anim.Internal.PropertyBuilder.Opacity as Opacity
import Anim.Internal.PropertyBuilder.Rotate as Rotate
import Anim.Internal.PropertyBuilder.Scale as Scale
import Anim.Internal.PropertyBuilder.Size as Size
import Anim.Internal.PropertyBuilder.Skew as Skew
import Anim.Internal.PropertyBuilder.Translate as Translate
import Dict exposing (Dict)
import Shared.Easing as Easing



-- ============================================================
-- INITIALIZE
-- ============================================================


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



-- ============================================================
-- GENERATORS
-- ============================================================


generateAnimation :
    Builder.Iterations
    -> Builder.AnimationDirection
    -> Maybe (List TransformProperty)
    -> Dict String Builder.DiscreteEntryProperty
    -> Dict String Builder.DiscreteExitProperty
    -> Maybe AnimGroup
    -> List Builder.ProcessedPropertyConfig
    -> AnimGroup
generateAnimation iterationCount directionConfig maybeOrder discreteEntryProps discreteExitProps existingAnimation properties =
    let
        animations =
            List.filterMap (toAnimation False) properties
                |> Animations.fromList

        transformOrder =
            case maybeOrder of
                Just order ->
                    order

                Nothing ->
                    existingAnimation
                        |> Maybe.map AnimGroup.getTransformOrder
                        |> Maybe.withDefault TransformProperty.default
    in
    AnimGroup.init
        |> AnimGroup.setAnimations animations
        |> AnimGroup.setPlayState PlayState.Running
        |> AnimGroup.setIterationCount iterationCount
        |> AnimGroup.setAnimationDirection directionConfig
        |> AnimGroup.setCurrentIteration 1
        |> AnimGroup.setTransformOrder transformOrder
        |> AnimGroup.setDiscreteEntry discreteEntryProps
        |> AnimGroup.setDiscreteExit discreteExitProps



-- ============================================================
-- HELPERS
-- ============================================================


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
        Builder.ProcessedCustomPropertyConfig cssName unit config ->
            Just
                ( "custom:" ++ cssName
                , CustomProperty cssName unit <|
                    build 0 config
                )

        Builder.ProcessedCustomColorPropertyConfig cssName config ->
            Just
                ( "customColor:" ++ cssName
                , CustomColorProperty cssName <|
                    build (Color.fromRGB { r = 0, g = 0, b = 0 }) config
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

        Builder.ProcessedSkewConfig config ->
            Just
                ( "skew"
                , Skew <|
                    build Skew.default config
                )

        Builder.ProcessedTranslateConfig config ->
            Just
                ( "translate"
                , Translate <|
                    build Translate.default config
                )
