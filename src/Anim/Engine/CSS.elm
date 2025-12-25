module Anim.Engine.CSS exposing
    ( AnimState, init, AnimBuilder, builder
    , animate, animateOrder
    , TransformOrder(..), defaultTransformOrder
    , htmlAttributes
    , keyframesStyleNode, keyframesStyleNodeFor, getElementKeyframes
    , animationStyleAttribute
    , duration, speed
    , easing
    , delay
    , onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel
    , onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel
    , isRunning
    )

{-| CSS-based animation system with optional state tracking.

This Engine converts [AnimBuilder](#AnimBuilder) configurations to CSS animations which you can apply as either:

1.  **Keyframe animations**, or,
2.  **CSS [transform](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Transforms) attributes**.

You decide how to apply the generated CSS to your elements in your view - giving you full control
over how the CSS is integrated into your application.


# Build

@docs AnimState, init, AnimBuilder, builder


# Execute

@docs animate, animateOrder


# Transform Ordering

@docs TransformOrder, defaultTransformOrder


# View


## Design Decisions (Keyframes vs Transforms)

**Choosing Between Keyframes and Transforms**

The choice between keyframes and transforms should be based on your animation requirements:

**Use Keyframes when you need:**

  - Complex easing curves (bounce, elastic, back, etc.)
  - Individual delays per property
  - Fine-grained control over animation timing
  - Better debugging visibility in DevTools

**Use Transforms for:**

  - Simple easing (ease, ease-in-out, cubic-bezier)
  - Basic A→B animations
  - Minimal setup (no style node required)


## CSS Transform Attributes

For CSS transform animations, just apply the generated HTML attributes to your elements.

@docs htmlAttributes


## Keyframes and Animation Styles

For Keyframe animations, add the Keyframes `<style>` node to your DOM. Then apply the
animation style attribute directly to the element you want to animate.

@docs keyframesStyleNode, keyframesStyleNodeFor, getElementKeyframes

@docs animationStyleAttribute


# Global Settings

These settings will be used for all property animations unless overridden on a per-property basis.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay


# Event Handling

CSS animations and transitions can trigger events when they start, end, or are cancelled.

Animation events are different from transition events, so both types of events can be handled using the following functions:


## Animation Events

For CSS keyframe animations.

@docs onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel


## Transition Events

For CSS transitions (used in CSS transform animations).

@docs onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel


# Querying Animation State

@docs isRunning

-}

import Anim.Internal.CSS as InternalCSS
import Anim.Properties.Position exposing (Position)
import Anim.Timing.Easing as Easing exposing (Easing)
import Html


{-| Transform property ordering for CSS generation.

Defines the order in which transform properties (position, rotate, scale)
should appear in the final CSS transform string.

-}
type TransformOrder
    = Position
    | Rotate
    | Scale


{-| Default transform order: Position → Rotate → Scale.

This is the recommended order for most use cases:

  - Position sets the base location
  - Rotation happens around that position
  - Scale happens last to avoid affecting rotation radius

-}
defaultTransformOrder : List TransformOrder
defaultTransformOrder =
    [ Position, Rotate, Scale ]


{-| Optional State for managing animations.

    import Anim.Engine.CSS as CSS

    { model | animations : CSS.AnimState }

This state keeps track of animations and their configurations.

If you want animations that need to start from their previous end state, i.e. you only
set the start state once and then keep updating the end state over time, or after user interactions,
you should include this type in your model.

If you only need to create fire-and-forget animations where you control both the start and end states,
you don't need to add this type to your model.

-}
type alias AnimState =
    InternalCSS.AnimState


{-| Animation builder type.

This is used internally to configure animations.

-}
type alias AnimBuilder =
    InternalCSS.AnimBuilder


{-| Generate CSS animations from the builder, and return the
updated [AnimState](#AnimState).

    animationState =
        model.animations -- Or `CSS.init`
            |> CSS.builder
            |> ... -- continue building the animation
            |> CSS.animate

-}
animate : AnimBuilder -> AnimState
animate =
    InternalCSS.animate


{-| Apply animation configuration with custom transform ordering.

This is an alternative to `animate` that allows you to specify the order
in which transform properties should appear in the CSS.

[animate](#animate) uses the transform order (Position → Rotate → Scale) which should
be suitable for most use cases. Use `animateOrder` if you need a different order.

Beware that changing the transform order can lead to unexpected visual results,
as the order of transforms affects how they are applied by the browser.

    -- Custom transform order: Scale → Rotate → Position
    newState =
        state
            |> CSS.builder
            |> -- ... property configurations ...
            |> CSS.animateOrder [ Scale, Rotate, Position ]

-}
animateOrder : List TransformOrder -> AnimBuilder -> AnimState
animateOrder order =
    let
        mapOrder transform =
            case transform of
                Position ->
                    InternalCSS.Position

                Rotate ->
                    InternalCSS.Rotate

                Scale ->
                    InternalCSS.Scale
    in
    order
        |> List.map mapOrder
        |> InternalCSS.animateWithOrder


{-| Initialize empty animation state.

    import Anim.Engine.CSS as CSS

    { model | animations = CSS.init }

Or, when you want fire-and-forget animations.

    import Anim.Engine.CSS as CSS

    CSS.init
        |> CSS.builder
        |> ... -- continue building the animation
        |> CSS.animate

-}
init : AnimState
init =
    InternalCSS.init


{-| Turn the [AnimState](#AnimState) into an [AnimBuilder](#AnimBuilder).

Use this to start building new animations.

    -- Create a new animation based on current state
    newBuilder =
        model.animations
            |> CSS.builder
            |> ... -- continue building the animation


    -- Create a new animation with no state tracking
    newBuilder =
        CSS.init
            |> CSS.builder
            |> ... -- continue building the animation

-}
builder : AnimState -> AnimBuilder
builder =
    InternalCSS.builder


{-| Generate the animation `<style>` attribute and apply it directly to the element you want to animate.

This creates the `animation` CSS property value that tells the browser which keyframe animation to run on this element.

    div
        [ Html.Attributes.id "my-element"
        , CSS.animationStyleAttribute "my-element" animationState
        ]
        [ text "Animating element" ]

This is equivalent to manually writing something like:

    Html.Attributes.style "animation" "animation-name 2000ms linear 0ms"

**Note:**

1.  You still need to include the keyframes in your DOM separately with
    [ keyframesStyleNode ](#keyframesStyleNode) or [ keyframesStyleNodeFor ](#keyframesStyleNodeFor).
2.  The Easing function will always be "linear" for CSS keyframe animations, as the easing
    is baked into the keyframes themselves, so we need to transition between keyframe values linearly.
3.  The Delay is also baked into the keyframes, so it will always be 0 in the CSS animation property.

-}
animationStyleAttribute : String -> AnimState -> Html.Attribute msg
animationStyleAttribute =
    InternalCSS.animationStyleAttribute


{-| Generate a `<style>` node containing keyframes for all animated elements.

This creates a style node that can be added to your view to include all the keyframe definitions.

    view model =
        div []
            [ CSS.keyframesStyleNode model.animationState ]

If there are no animations, this returns an empty text node.

-}
keyframesStyleNode : AnimState -> Html.Html msg
keyframesStyleNode =
    InternalCSS.keyframesStyleNode


{-| Generate a `<style>` node containing keyframes for a specific element.

This creates a style node for just one element, giving you fine-grained control over which
keyframes are included in your DOM.

    view model =
        div []
            [ CSS.keyframesStyleNodeFor "my-element" model.animationState ]

If the element has no animations, this returns an empty text node.

-}
keyframesStyleNodeFor : String -> AnimState -> Html.Html msg
keyframesStyleNodeFor =
    InternalCSS.keyframesStyleNodeFor


{-| Get the raw generated CSS keyframes string that can be inserted into a `<style>` tag.

However, you probably want to use [ keyframesStyleNodeFor ](#keyframesStyleNodeFor) instead, which
handles creating the full `<style>` node for you.

This function is mainly provided for advanced use cases where you need direct access to the keyframes string prior to inserting it into the DOM.

-}
getElementKeyframes : String -> AnimState -> Maybe String
getElementKeyframes =
    InternalCSS.getElementKeyframes


{-| Check if any animations are currently running.
-}
isRunning : AnimState -> Bool
isRunning =
    InternalCSS.isRunning


{-| Set the global duration in milliseconds (overrides any previous speed setting).

    Css.init
        |> CSS.builder
        |> Css.duration 1000
        |> ... -- Property animations
        |> Css.animate

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalCSS.duration


{-| Set the global speed in units per second (overrides any previous duration setting).

Exactly what "units" means depends on the properties being animated. For position properties, this is pixels per second.
Refer to the relevant property documentation for specific details for each property.

    Css.init
        |> CSS.builder
        |> Css.speed 100
        |> ... -- Property animations
        |> Css.animate

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalCSS.speed


{-| Set global easing function.

    Css.init
        |> CSS.builder
        |> Css.easing EaseInOutQuad
        |> ... -- Property animations
        |> Css.animate

**Note:** For CSS keyframe animations, the easing is baked into the keyframes themselves,
for CSS transform animations, the easing function will be applied to the `transition-timing-function` property.

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Easing.mapInternal InternalCSS.easing


{-| Set global delay in milliseconds.

    Css.init
        |> CSS.builder
        |> Css.delay 500
        |> ... -- Property animations
        |> Css.animate

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalCSS.delay


{-| Get all the HTML attributes needed for the CSS animations on the target element.


### HTML Example

    import Anim.Engine.CSS as CSS
    import Html exposing (div, text)
    import Html.Attributes exposing (id)

    div
        ([ id "my-element"
         , ...
         ]
            ++ CSS.htmlAttributes "my-element" animationState
        )
        [ text "Animating element" ]

For Elm UI, just wrap each attribute with [htmlAttribute](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/Element#htmlAttribute).


### Elm UI Example

    import Anim.Engine.CSS as CSS
    import Element exposing (el, htmlAttribute, text)

    el
        ([ htmlAttribute (Html.Attributes.id "my-element")
         , ...
         ]
            ++ List.map htmlAttribute (CSS.htmlAttributes "my-element" animationState)
        )
        (text "Animating element")

-}
htmlAttributes : String -> AnimState -> List (Html.Attribute msg)
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
