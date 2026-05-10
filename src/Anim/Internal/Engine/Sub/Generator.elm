module Anim.Internal.Engine.Sub.Generator exposing (generateAnimation, init)

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.PlayState as PlayState
import Anim.Internal.Engine.Sub.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Sub.Animation exposing (Animation(..), PropertyAnimation)
import Anim.Internal.Engine.Sub.Animations as Animations
import Anim.Internal.Extra.Color as Color
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Dict exposing (Dict)
import Motion.Internal.Spring as SpringInt
import Motion.Spring exposing (Spring)
import Shared.Easing as Easing
import Shared.Spring as SpringSolver



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
            let
                durationMs =
                    toFloat config.duration

                easingFn =
                    case config.spring of
                        Just s ->
                            springEasingFunction s durationMs

                        Nothing ->
                            Easing.toFunction durationMs config.easing
            in
            { start = Maybe.withDefault default config.start
            , end = config.end
            , easingFunction = easingFn
            , delayMs = toFloat config.delay
            , isComplete = isComplete
            , totalDurationMs = durationMs
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

        Builder.ProcessedPerspectiveOriginConfig config ->
            Just
                ( "perspectiveOrigin"
                , PerspectiveOrigin <|
                    build PerspectiveOrigin.default config
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



-- ============================================================
-- SPRING
-- ============================================================


{-| Build a `Float -> Float` interpolator that maps `t` (in `[0, 1]`)
to the spring's normalised position at time `t * durationMs`.

Used by `Sub`'s per-frame loop so that spring-driven motion plugs
into the same `easingFunction` slot as a regular easing curve. The
spring is parametrised on `from = 0` to `to = 1`; the engine then
linearly interpolates between the property's actual start and end
values using that fraction.

-}
springEasingFunction : Spring -> Float -> (Float -> Float)
springEasingFunction s durationMs =
    let
        motion =
            { spring = SpringInt.unwrap s
            , from = 0
            , to = 1
            }

        safeDuration =
            if durationMs <= 0 then
                1

            else
                durationMs
    in
    \t ->
        SpringSolver.valueAt motion (t * safeDuration)
