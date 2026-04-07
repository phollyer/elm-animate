module Anim.Internal.Engine.Animation.CSS.Transition.Generator exposing (..)

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Animation.CSS.Transition.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Animation.CSS.Transition.Styles as TransitionStyles
import Anim.Internal.Extra.Easing as InternalEasing


type alias AnimGroupName =
    String


init : Bool -> List Builder.PropertyConfig -> AnimGroup
init discreteTransitions properties =
    let
        processedProps =
            Builder.processProperties Builder.initDefaults properties
    in
    AnimGroup.init
        |> AnimGroup.setStyles
            (TransitionStyles.fromProcessedProperties
                (baseStyles discreteTransitions processedProps)
                processedProps
            )


generateAnimation : Bool -> List Builder.ProcessedPropertyConfig -> AnimGroup
generateAnimation discreteTransitions processedProps =
    AnimGroup.init
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


generate : List Builder.ProcessedPropertyConfig -> String
generate properties =
    let
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

                            Builder.ProcessedSizeConfig config ->
                                config.duration == 0

                            Builder.ProcessedFontColorConfig config ->
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

        Builder.ProcessedSizeConfig config ->
            Just ("width " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms, height " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")

        Builder.ProcessedFontColorConfig config ->
            Just ("color " ++ String.fromInt config.duration ++ "ms " ++ InternalEasing.toCSS (Just config.easing) ++ " " ++ String.fromInt config.delay ++ "ms")
