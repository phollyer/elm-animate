module Anim.Internal.Engine.CSS.Transition.Generator exposing (..)

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.Transition.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.CSS.Transition.Styles as TransitionStyles
import Dict exposing (Dict)
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
            allTransitions =
                List.filterMap transitionFromProcessed properties
        in
        String.join ", " allTransitions



-- ============================================================
-- HELPERS
-- ============================================================


transitionFromProcessed : Builder.ProcessedPropertyConfig -> Maybe String
transitionFromProcessed property =
    case property of
        Builder.ProcessedCustomPropertyConfig cssName _ config ->
            Just (cssName ++ " " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedCustomColorPropertyConfig cssName config ->
            Just (cssName ++ " " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedOpacityConfig config ->
            Just ("opacity " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedRotateConfig config ->
            Just ("transform " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedScaleConfig config ->
            Just ("scale " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedSizeConfig config ->
            Just ("width " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms, height " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedSkewConfig config ->
            Just ("transform " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedTranslateConfig config ->
            Just ("translate " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")
