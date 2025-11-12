module Anim.CSS exposing
    ( animate, AnimationState
    , getElementStyles
    , htmlAttributes
    , onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel
    )

{-| CSS-based animation system for Anim.

This module converts AnimBuilder configurations to CSS transition and transform styles
for native browser performance and hardware acceleration.


# Animation Execution

@docs animate, AnimationState


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


{-| Result of CSS animation generation.
-}
type AnimationState
    = AnimationState (Dict ElementId ElementAnimation)


type alias ElementId =
    String


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
                |> Dict.map generateElementAnimation
    in
    AnimationState elementAnimations



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
            Just ("translate(" ++ Position.toCssString config ++ ")")

        Builder.RotateConfig config ->
            Just ("rotate(" ++ Rotation.toCssString config.target ++ ")")

        Builder.ScaleConfig config ->
            Just ("scale(" ++ Scale.toCssString config.target ++ ")")

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
            Just ( "background-color", Color.toString config.target )

        Builder.OpacityConfig config ->
            Just ( "opacity", Opacity.toString config.target )

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
getElementStyles : String -> AnimationState -> List ( String, String )
getElementStyles elementId (AnimationState animations) =
    animations
        |> List.filter (\anim -> anim.elementId == elementId)
        |> List.head
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
