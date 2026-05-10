module Anim.Internal.Engine.Transition.Generator exposing (..)

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Transition.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Transition.Styles as TransitionStyles
import Dict exposing (Dict)
import Motion.Easing as Easing exposing (Easing)
import Motion.Spring exposing (Spring)
import Shared.Easing as InternalEasing



-- ============================================================
-- TYPES
-- ============================================================


type alias AnimGroupName =
    String



-- ============================================================
-- INITIALIZE
-- ============================================================


init : Bool -> Dict String String -> Dict String Builder.DiscreteExitProperty -> List Builder.PropertyConfig -> AnimGroup
init discreteTransitions discreteEntry discreteExit properties =
    let
        processedProps =
            Builder.processProperties Builder.initDefaults properties
    in
    AnimGroup.init
        |> AnimGroup.setDiscreteEntry discreteEntry
        |> AnimGroup.setDiscreteExit discreteExit
        |> AnimGroup.setStyles
            (TransitionStyles.fromProcessedProperties
                (baseStyles discreteTransitions processedProps)
                processedProps
            )



-- ============================================================
-- GENERATORS
-- ============================================================


generateAnimation : Bool -> Dict String String -> Dict String Builder.DiscreteExitProperty -> List Builder.ProcessedPropertyConfig -> AnimGroup
generateAnimation discreteTransitions discreteEntry discreteExit processedProps =
    AnimGroup.init
        |> AnimGroup.setDiscreteEntry discreteEntry
        |> AnimGroup.setDiscreteExit discreteExit
        |> AnimGroup.setStyles
            (TransitionStyles.fromProcessedProperties
                (baseStyles discreteTransitions processedProps)
                processedProps
            )


baseStyles : Bool -> List Builder.ProcessedPropertyConfig -> List ( String, String )
baseStyles discreteTransitions processedProps =
    let
        transitionBehavior =
            if discreteTransitions then
                [ ( "transition-behavior", "allow-discrete" ) ]

            else
                []
    in
    ( "transition", generate processedProps ) :: transitionBehavior



-- ============================================================
-- CSS TRANSITION STRING
-- ============================================================


generate : List Builder.ProcessedPropertyConfig -> String
generate properties =
    let
        allDurationsZero =
            properties
                |> List.all
                    (\prop ->
                        case prop of
                            Builder.ProcessedCustomPropertyConfig _ _ config ->
                                config.duration == 0

                            Builder.ProcessedCustomColorPropertyConfig _ config ->
                                config.duration == 0

                            Builder.ProcessedOpacityConfig config ->
                                config.duration == 0

                            Builder.ProcessedPerspectiveOriginConfig config ->
                                config.duration == 0

                            Builder.ProcessedRotateConfig config ->
                                config.duration == 0

                            Builder.ProcessedScaleConfig config ->
                                config.duration == 0

                            Builder.ProcessedSizeConfig config ->
                                config.duration == 0

                            Builder.ProcessedSkewConfig config ->
                                config.duration == 0

                            Builder.ProcessedTranslateConfig config ->
                                config.duration == 0
                    )
    in
    if allDurationsZero then
        "none"

    else
        let
            transformTransition =
                transformTransitionFromProcessed properties

            nonTransformTransitions =
                List.filterMap nonTransformTransitionFromProcessed properties

            allTransitions =
                case transformTransition of
                    Just t ->
                        t :: nonTransformTransitions

                    Nothing ->
                        nonTransformTransitions
        in
        String.join ", " allTransitions



-- ============================================================
-- HELPERS
-- ============================================================


{-| Emits a single `transform` transition rule. When both rotate and skew are
present, rotate's settings take priority. If only skew is present, skew's
settings are used.
-}
transformTransitionFromProcessed : List Builder.ProcessedPropertyConfig -> Maybe String
transformTransitionFromProcessed properties =
    let
        rotateConfig =
            properties
                |> List.filterMap
                    (\p ->
                        case p of
                            Builder.ProcessedRotateConfig config ->
                                Just config

                            _ ->
                                Nothing
                    )
                |> List.head

        skewConfig =
            properties
                |> List.filterMap
                    (\p ->
                        case p of
                            Builder.ProcessedSkewConfig config ->
                                Just config

                            _ ->
                                Nothing
                    )
                |> List.head
    in
    case ( rotateConfig, skewConfig ) of
        ( Just config, _ ) ->
            Just ("transform " ++ String.fromInt config.duration ++ "ms " ++ timingFunction config.spring config.easing ++ " " ++ String.fromInt config.delay ++ "ms")

        ( Nothing, Just config ) ->
            Just ("transform " ++ String.fromInt config.duration ++ "ms " ++ timingFunction config.spring config.easing ++ " " ++ String.fromInt config.delay ++ "ms")

        ( Nothing, Nothing ) ->
            Nothing


nonTransformTransitionFromProcessed : Builder.ProcessedPropertyConfig -> Maybe String
nonTransformTransitionFromProcessed property =
    case property of
        Builder.ProcessedCustomPropertyConfig cssName _ config ->
            Just (cssName ++ " " ++ String.fromInt config.duration ++ "ms " ++ timingFunction config.spring config.easing ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedCustomColorPropertyConfig cssName config ->
            Just (cssName ++ " " ++ String.fromInt config.duration ++ "ms " ++ timingFunction config.spring config.easing ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedOpacityConfig config ->
            Just ("opacity " ++ String.fromInt config.duration ++ "ms " ++ timingFunction config.spring config.easing ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedPerspectiveOriginConfig config ->
            Just ("perspective-origin " ++ String.fromInt config.duration ++ "ms " ++ timingFunction config.spring config.easing ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedRotateConfig _ ->
            Nothing

        Builder.ProcessedScaleConfig config ->
            Just ("scale " ++ String.fromInt config.duration ++ "ms " ++ timingFunction config.spring config.easing ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedSizeConfig config ->
            Just ("width " ++ String.fromInt config.duration ++ "ms " ++ timingFunction config.spring config.easing ++ " " ++ String.fromInt config.delay ++ "ms, height " ++ String.fromInt config.duration ++ "ms " ++ timingFunction config.spring config.easing ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedSkewConfig _ ->
            Nothing

        Builder.ProcessedTranslateConfig config ->
            Just ("translate " ++ String.fromInt config.duration ++ "ms " ++ timingFunction config.spring config.easing ++ " " ++ String.fromInt config.delay ++ "ms")


{-| Resolve the CSS `transition-timing-function` for a property.

CSS `transition` only supports a single timing function per property,
so spring physics cannot be expressed faithfully on this engine. When
a `Spring` is set, we fall back to a single overshoot cubic-bezier
(`cubic-bezier(0.34, 1.56, 0.64, 1)`) that conveys a spring-like
"snap" feel, with the duration already overridden to the spring's
settle time by `processStandardAnimation`. The full bouncing
character of an under-damped spring is only available on engines
that emit per-step keyframes (Keyframe, WAAPI, Sub).

-}
timingFunction : Maybe Spring -> Easing -> String
timingFunction maybeSpring easing =
    case maybeSpring of
        Just _ ->
            "cubic-bezier(0.34, 1.56, 0.64, 1)"

        Nothing ->
            InternalEasing.toCSS (Just easing)
