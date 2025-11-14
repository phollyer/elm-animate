module Anim.CSS exposing
    ( animate, AnimationState, init
    , getCurrentRotation, setCurrentRotation
    , getCurrentScale, setCurrentScale
    , getCurrentPosition, setCurrentPosition
    , getCurrentOpacity, setCurrentOpacity
    , getElementStyles
    , htmlAttributes
    , onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel
    )

{-| CSS-based animation system for Anim with property state tracking.

This module converts AnimBuilder configurations to CSS transition and transform styles
for native browser performance and hardware acceleration. It also tracks current property
values to enable exact distance calculations for speed-based animations.


# Animation Execution

@docs animate, AnimationState, init


# State Tracking

@docs getCurrentRotation, setCurrentRotation
@docs getCurrentScale, setCurrentScale
@docs getCurrentPosition, setCurrentPosition
@docs getCurrentOpacity, setCurrentOpacity


# Utility Functions

@docs getElementStyles


# Element Integration

@docs htmlAttributes


# Event Handling

@docs onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel

-}

import Anim exposing (AnimBuilder)
import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.Color as Color
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position as Position
import Anim.Internal.Properties.Rotation as Rotation
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Timing.Delay as Delay
import Anim.Internal.Timing.Easing as Easing
import Anim.Internal.Timing.TimeSpec as TimeSpec
import Dict exposing (Dict)
import Html
import Html.Attributes
import Html.Events
import Json.Decode


{-| Result of CSS animation generation with property state tracking.
-}
type AnimationState
    = AnimationState
        { elementAnimations : Dict ElementId ElementAnimation
        , currentValues : Dict ElementId (Dict String PropertyValue)
        }


type alias ElementId =
    String


{-| Flexible property value storage for state tracking.
-}
type PropertyValue
    = FloatValue Float -- rotation: 45, opacity: 0.8
    | PositionValue { x : Float, y : Float } -- translate: {x: 100, y: 50}
    | ScaleValue { x : Float, y : Float } -- scale: {x: 1.2, y: 0.8}
    | ColorValue String -- color: "#ff0000"


{-| CSS animation data for a single element.
-}
type alias ElementAnimation =
    { elementId : ElementId
    , styles : List ( String, String )
    , keyframes : Maybe String
    }


{-| Generate CSS animations from AnimBuilder.

    Anim.init "my-element"
        |> Anim.Properties.Position.to { x = 100, y = 200 }
        |> Anim.Properties.Scale.to { x = 1.5, y = 1.5 }
        |> Anim.CSS.animate

Returns CSS styles that can be applied via Html.Attributes.style or similar.

-}
animate : AnimBuilder -> AnimationState
animate builder =
    let
        elementAnimations =
            builder
                |> Builder.elements
                |> Debug.log "Element Configs"
                |> Dict.map generateElementAnimation
    in
    AnimationState
        { elementAnimations = elementAnimations
        , currentValues = Dict.empty
        }


{-| Initialize empty animation state.
-}
init : AnimationState
init =
    AnimationState
        { elementAnimations = Dict.empty
        , currentValues = Dict.empty
        }


{-| Get current rotation value with default fallback.
-}
getCurrentRotation : ElementId -> AnimationState -> Float
getCurrentRotation elementId (AnimationState state) =
    Dict.get elementId state.currentValues
        |> Maybe.andThen (Dict.get "rotation")
        |> Maybe.andThen
            (\value ->
                case value of
                    FloatValue f ->
                        Just f

                    _ ->
                        Nothing
            )
        |> Maybe.withDefault 0.0


{-| Set current rotation value after animation completes.
-}
setCurrentRotation : ElementId -> Float -> AnimationState -> AnimationState
setCurrentRotation elementId rotation (AnimationState state) =
    let
        updateElement elementValues =
            elementValues
                |> Maybe.withDefault Dict.empty
                |> Dict.insert "rotation" (FloatValue rotation)
                |> Just
    in
    AnimationState
        { state
            | currentValues = Dict.update elementId updateElement state.currentValues
        }


{-| Get current scale value with default fallback.
-}
getCurrentScale : ElementId -> AnimationState -> { x : Float, y : Float }
getCurrentScale elementId (AnimationState state) =
    Dict.get elementId state.currentValues
        |> Maybe.andThen (Dict.get "scale")
        |> Maybe.andThen
            (\value ->
                case value of
                    ScaleValue scale ->
                        Just scale

                    _ ->
                        Nothing
            )
        |> Maybe.withDefault { x = 1.0, y = 1.0 }


{-| Set current scale value after animation completes.
-}
setCurrentScale : ElementId -> { x : Float, y : Float } -> AnimationState -> AnimationState
setCurrentScale elementId scale (AnimationState state) =
    let
        updateElement elementValues =
            elementValues
                |> Maybe.withDefault Dict.empty
                |> Dict.insert "scale" (ScaleValue scale)
                |> Just
    in
    AnimationState
        { state
            | currentValues = Dict.update elementId updateElement state.currentValues
        }


{-| Get current position value with default fallback.
-}
getCurrentPosition : ElementId -> AnimationState -> { x : Float, y : Float }
getCurrentPosition elementId (AnimationState state) =
    Dict.get elementId state.currentValues
        |> Maybe.andThen (Dict.get "position")
        |> Maybe.andThen
            (\value ->
                case value of
                    PositionValue pos ->
                        Just pos

                    _ ->
                        Nothing
            )
        |> Maybe.withDefault { x = 0.0, y = 0.0 }


{-| Set current position value after animation completes.
-}
setCurrentPosition : ElementId -> { x : Float, y : Float } -> AnimationState -> AnimationState
setCurrentPosition elementId position (AnimationState state) =
    let
        updateElement elementValues =
            elementValues
                |> Maybe.withDefault Dict.empty
                |> Dict.insert "position" (PositionValue position)
                |> Just
    in
    AnimationState
        { state
            | currentValues = Dict.update elementId updateElement state.currentValues
        }


{-| Get current opacity value with default fallback.
-}
getCurrentOpacity : ElementId -> AnimationState -> Float
getCurrentOpacity elementId (AnimationState state) =
    Dict.get elementId state.currentValues
        |> Maybe.andThen (Dict.get "opacity")
        |> Maybe.andThen
            (\value ->
                case value of
                    FloatValue f ->
                        Just f

                    _ ->
                        Nothing
            )
        |> Maybe.withDefault 1.0


{-| Set current opacity value after animation completes.
-}
setCurrentOpacity : ElementId -> Float -> AnimationState -> AnimationState
setCurrentOpacity elementId opacity (AnimationState state) =
    let
        updateElement elementValues =
            elementValues
                |> Maybe.withDefault Dict.empty
                |> Dict.insert "opacity" (FloatValue opacity)
                |> Just
    in
    AnimationState
        { state
            | currentValues = Dict.update elementId updateElement state.currentValues
        }



-- CSS GENERATION


generateElementAnimation : String -> Builder.ElementConfig -> ElementAnimation
generateElementAnimation elementId elementConfig =
    let
        transforms =
            generateTransforms elementConfig.properties

        transitions =
            generateTransitions elementConfig.properties

        colors =
            generateColorStyles elementConfig.properties

        allStyles =
            [ ( "transform", transforms )
            , ( "transition", transitions )
            ]
                ++ colors
                |> List.filter (\( _, value ) -> not (String.isEmpty value))
    in
    { elementId = elementId
    , styles = allStyles
    , keyframes = Nothing -- For future complex animations
    }


generateTransforms : List Builder.PropertyConfig -> String
generateTransforms properties =
    let
        transformParts =
            List.filterMap transformFromProperty properties
    in
    String.join " " transformParts


transformFromProperty : Builder.PropertyConfig -> Maybe String
transformFromProperty property =
    case property of
        Builder.PositionConfig config ->
            Just ("translate(" ++ Position.toCssString config.endAt ++ ")")

        Builder.RotateConfig config ->
            Just ("rotate(" ++ Rotation.toCssString config.endAt ++ ")")

        Builder.ScaleConfig config ->
            Just ("scale(" ++ Scale.toCssString config.endAt ++ ")")

        Builder.ColorConfig _ ->
            -- Color doesn't use transform
            Nothing

        Builder.OpacityConfig _ ->
            -- Opacity doesn't use transform
            Nothing


generateTransitions : List Builder.PropertyConfig -> String
generateTransitions properties =
    let
        transitionParts =
            List.filterMap transitionFromProperty properties
    in
    String.join ", " transitionParts


transitionFromProperty : Builder.PropertyConfig -> Maybe String
transitionFromProperty property =
    case property of
        Builder.PositionConfig config ->
            Just ("transform " ++ TimeSpec.toCssString config.timing ++ " " ++ Easing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        Builder.RotateConfig config ->
            Just ("transform " ++ TimeSpec.toCssString config.timing ++ " " ++ Easing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        Builder.ScaleConfig config ->
            Just ("transform " ++ TimeSpec.toCssString config.timing ++ " " ++ Easing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        Builder.ColorConfig config ->
            Just ("background-color " ++ TimeSpec.toCssString config.timing ++ " " ++ Easing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        Builder.OpacityConfig config ->
            Just ("opacity " ++ TimeSpec.toCssString config.timing ++ " " ++ Easing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)


generateColorStyles : List Builder.PropertyConfig -> List ( String, String )
generateColorStyles properties =
    List.filterMap colorStyleFromProperty properties


colorStyleFromProperty : Builder.PropertyConfig -> Maybe ( String, String )
colorStyleFromProperty property =
    case property of
        Builder.ColorConfig config ->
            Just ( "background-color", Color.toString config.endAt )

        Builder.OpacityConfig config ->
            Just ( "opacity", Opacity.toString config.endAt )

        _ ->
            Nothing



-- UTILITY FUNCTIONS FOR CONSUMERS


{-| Extract styles for a specific element from AnimationResult.

    case Anim.CSS.animate builder of
        AnimationResult animations ->
            animations
                |> List.filter (\anim -> anim.elementId == "my-element")
                |> List.head
                |> Maybe.map .styles
                |> Maybe.withDefault []

-}
getElementStyles : ElementId -> AnimationState -> List ( String, String )
getElementStyles elementId (AnimationState state) =
    Dict.get elementId state.elementAnimations
        |> Debug.log "getElementStyles"
        |> Maybe.map .styles
        |> Maybe.withDefault []


{-| Get all HTML attributes needed for CSS animations on an element.

This is a convenience function that combines CSS styles, transition properties,
and event handling into a single list of Html.Attribute values.

Example:

    div
        ([ Html.Attributes.id "my-element"
         , Html.Attributes.class "box"
         ]
            ++ CSS.htmlAttributes "my-element" animationResult AnimationComplete
        )
        [ text "Animating element" ]

For Elm UI, wrap each attribute with htmlAttribute:

    el
        ([ htmlAttribute (Html.Attributes.id "my-element") ]
            ++ List.map htmlAttribute (CSS.htmlAttributes "my-element" animationResult AnimationComplete)
        )
        (text "Animating element")

-}
htmlAttributes : String -> Maybe AnimationState -> List (Html.Attribute msg)
htmlAttributes elementId maybeAnimationResult =
    case maybeAnimationResult of
        Just animationResult ->
            getElementStyles elementId animationResult
                |> List.map (\( prop, value ) -> Html.Attributes.style prop value)

        Nothing ->
            [ Html.Attributes.style "transition" "none" ]



-- CSS TRANSITION EVENT HANDLERS


{-| Event handler for when a CSS transition starts.
-}
onTransitionStart : msg -> Html.Attribute msg
onTransitionStart msg =
    Html.Events.on "transitionstart" (Json.Decode.succeed msg)


{-| Event handler for when a CSS transition ends.
-}
onTransitionEnd : msg -> Html.Attribute msg
onTransitionEnd msg =
    Html.Events.on "transitionend" (Json.Decode.succeed msg)


{-| Event handler for when a CSS transition run begins (even if delayed).
-}
onTransitionRun : msg -> Html.Attribute msg
onTransitionRun msg =
    Html.Events.on "transitionrun" (Json.Decode.succeed msg)


{-| Event handler for when a CSS transition is cancelled.
-}
onTransitionCancel : msg -> Html.Attribute msg
onTransitionCancel msg =
    Html.Events.on "transitioncancel" (Json.Decode.succeed msg)
