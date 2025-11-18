module Anim.CSS exposing
    ( AnimationState, init, builder, animate
    , htmlAttributes, getElementKeyframes, animationStyleAttribute, keyframesStyleNode, keyframesStyleNodeFor
    , onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel
    , onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel
    )

{-| CSS-based animation system with optional state tracking.

This module provides the ability to create simple CSS animations that
can be easily added to your elements as style tags or css [transform](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Transforms) attributes.


# Build

@docs AnimationState, init, builder, animate


# View

@docs htmlAttributes, getElementKeyframes, animationStyleAttribute, keyframesStyleNode, keyframesStyleNodeFor


# Event Handling

CSS animations and transitions can trigger events when they start, end, or are cancelled.

Animation events are different from transition events, so both types of events can be handled using the following functions:


## Animation Events

@docs onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel


## Transition Events

@docs onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel

-}

import Anim exposing (AnimBuilder)
import Anim.Internal.CSS as InternalCSS
import Html


{-| Optional state tracker.

Add this to your model to enable state tracking for CSS animations.

    type alias Model =
        { animations : CSS.AnimationState
        , ...
        }

For simple CSS animations, such as one-off transitions, you probably do not need to track state.

If you want more complex animations that depend on current positions or colors etc, include this in your model
so that new animations will be started based on the current state.

-}
type alias AnimationState =
    InternalCSS.AnimationState


{-| Generate CSS animations from the builder, and return the
updated AnimationState.

    animationState =
        model.animations -- Or `CSS.init`
            |> CSS.builder
            |> ... -- continue building the animation
            |> CSS.animate

The AnimationState can then be used by the view.

-}
animate : AnimBuilder -> AnimationState
animate =
    InternalCSS.animate


{-| Initialize empty animation state.
-}
init : AnimationState
init =
    InternalCSS.init


{-| Turn the AnimationState into an AnimBuilder.

Use this to start new animations.

    -- Start a new animation based on current state
    newBuilder =
        model.animations
            |> CSS.builder
            |> ... -- continue building the animation


    -- Start a new animation with no state tracking
    newBuilder =
        CSS.init
            |> CSS.builder
            |> ... -- continue building the animation

-}
builder : AnimationState -> AnimBuilder
builder =
    InternalCSS.builder


{-| Generate the CSS animation property for an element.

This creates the `animation` CSS property value that should be applied to the element.

    div
        [ Html.Attributes.id "my-element"
        , CSS.animationStyleAttribute "my-element" animationState
        ]
        [ text "Animating element" ]

This is equivalent to manually writing:

    Html.Attributes.style "animation" "my-element-animation 2000ms ease-out 100ms"

-}
animationStyleAttribute : String -> AnimationState -> Html.Attribute msg
animationStyleAttribute =
    InternalCSS.animationStyleAttribute


{-| Generate a `<style>` node containing keyframes for all animated elements.

This creates a style node that can be added to your view to include all the keyframe definitions.

    view model =
        div []
            [ CSS.keyframesStyleNode model.animationState
            , div
                [ Html.Attributes.id "my-element"
                , CSS.animationStyleAttribute "my-element" model.animationState
                ]
                [ text "Animating element" ]
            ]

-}
keyframesStyleNode : AnimationState -> Html.Html msg
keyframesStyleNode =
    InternalCSS.keyframesStyleNode


{-| Generate a `<style>` node containing keyframes for a specific element.

This creates a style node for just one element, giving you fine-grained control over which
keyframes are included in your DOM.

    view model =
        div []
            [ CSS.keyframesStyleNodeFor "my-element" model.animationState
            , div
                [ Html.Attributes.id "my-element"
                , CSS.animationStyleAttribute "my-element" model.animationState
                ]
                [ text "Animating element" ]
            ]

If the element has no animations, this returns an empty text node.

-}
keyframesStyleNodeFor : String -> AnimationState -> Html.Html msg
keyframesStyleNodeFor =
    InternalCSS.keyframesStyleNodeFor


{-| Get the keyframes CSS string for a specific element from the animation state.

This function returns the generated CSS keyframes that can be inserted into a `<style>` tag.

    case CSS.getElementKeyframes "my-element" animationState of
        Just keyframes ->
            Html.node "style" [] [ Html.text keyframes ]

        Nothing ->
            Html.text ""

The generated keyframes will have a name based on the element ID (e.g., "my-element-animation").

-}
getElementKeyframes : String -> AnimationState -> Maybe String
getElementKeyframes =
    InternalCSS.getElementKeyframes


{-| Get all the HTML attributes needed for the CSS animations on the target element.


### HTML Example

    div
        ([ Html.Attributes.id "my-element"
         , ...
         ]
            ++ CSS.htmlAttributes "my-element" animationState
        )
        [ text "Animating element" ]


### Elm UI Example

For Elm UI, just wrap each attribute with [htmlAttribute](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/Element#htmlAttribute):

    el
        ([ htmlAttribute (Html.Attributes.id "my-element")
         , ...
         ]
            ++ List.map htmlAttribute <|
                CSS.htmlAttributes "my-element" animationState
        )
        (text "Animating element")

-}
htmlAttributes : String -> AnimationState -> List (Html.Attribute msg)
htmlAttributes =
    InternalCSS.htmlAttributes



-- CSS TRANSITION EVENT HANDLERS


{-| Event handler for when a CSS transition starts.
-}
onTransitionStart : msg -> Html.Attribute msg
onTransitionStart =
    InternalCSS.onTransitionStart


{-| Event handler for when a CSS transition ends.
-}
onTransitionEnd : msg -> Html.Attribute msg
onTransitionEnd =
    InternalCSS.onTransitionEnd


{-| Event handler for when a CSS transition run begins (even if delayed).
-}
onTransitionRun : msg -> Html.Attribute msg
onTransitionRun =
    InternalCSS.onTransitionRun


{-| Event handler for when a CSS transition is cancelled.
-}
onTransitionCancel : msg -> Html.Attribute msg
onTransitionCancel =
    InternalCSS.onTransitionCancel



-- CSS ANIMATION EVENT HANDLERS


{-| Event handler for when a CSS animation starts.
-}
onAnimationStart : msg -> Html.Attribute msg
onAnimationStart =
    InternalCSS.onAnimationStart


{-| Event handler for when a CSS animation ends.
-}
onAnimationEnd : msg -> Html.Attribute msg
onAnimationEnd =
    InternalCSS.onAnimationEnd


{-| Event handler for when a CSS animation iteration completes.
-}
onAnimationIteration : msg -> Html.Attribute msg
onAnimationIteration =
    InternalCSS.onAnimationIteration


{-| Event handler for when a CSS animation is cancelled.
-}
onAnimationCancel : msg -> Html.Attribute msg
onAnimationCancel =
    InternalCSS.onAnimationCancel
