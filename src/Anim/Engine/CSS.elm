module Anim.Engine.CSS exposing
    ( AnimState, init, AnimBuilder, builder
    , animate, TransformOrder(..), animateOrder
    , keyframesStyleNode, keyframesStyleNodeFor, getElementKeyframes
    , animationStyleAttribute, animationStyleAttributeWithEvents
    , htmlAttributes, htmlAttributesWithEvents
    , Event(..), handleEvent
    , onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel
    , onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel
    , duration, speed
    , easing
    , delay
    , anyRunning, isRunning, allComplete, isComplete
    , getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor
    , getStartOpacity, getEndOpacity, getCurrentOpacity
    , getStartPosition, getEndPosition, getCurrentPosition
    , getStartRotate, getEndRotate, getCurrentRotate
    , getStartScale, getEndScale, getCurrentScale
    , getStartSize, getEndSize, getCurrentSize
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

@docs animate, TransformOrder, animateOrder


# View


## Design Decisions

**Choosing Between Keyframes and Transforms**

The choice between keyframes and transforms should be based on your animation requirements:

**Use Keyframes when you need:**

  - Complex animations
  - Advanced easing curves (bounce, elastic, back, etc.)
  - Fine-grained control over animation timing
  - Better debugging visibility in DevTools

**Use Transforms for:**

  - Basic A→B animations
  - Simple easing (ease, ease-in-out, cubic-bezier)
  - Minimal setup (no style node required)


## Keyframes

For Keyframe animations, you would create your Keyframes string, add it to a `<style>` node in your DOM,
then apply the animation style attribute directly to the element you want to animate.

The following functions help with this process:

@docs keyframesStyleNode, keyframesStyleNodeFor, getElementKeyframes

@docs animationStyleAttribute, animationStyleAttributeWithEvents


## CSS Transform Attributes

For CSS transform animations, just apply the generated HTML attributes to your elements.

@docs htmlAttributes, htmlAttributesWithEvents


# Event Handling

CSS animations and transitions can trigger events when they start, end, or are cancelled. You have two options for handling
these events in your application:

1.  **Automatic Event Handling:** Use the [htmlAttributesWithEvents](#htmlAttributesWithEvents) or [animationStyleAttributeWithEvents](#animationStyleAttributeWithEvents) functions to automatically add event handlers
    to your elements. These handlers will generate [Event](#Event) messages that you can process in your update function.

2.  **Manual Event Handling:** Manually add event handlers to your elements using the provided event handler functions:

    [onAnimationStart](#onAnimationStart), [onAnimationEnd](#onAnimationEnd), [onAnimationIteration](#onAnimationIteration), [onAnimationCancel](#onAnimationCancel)

    [onTransitionStart](#onTransitionStart), [onTransitionEnd](#onTransitionEnd), [onTransitionRun](#onTransitionRun), [onTransitionCancel](#onTransitionCancel)

You should only use one of these approaches at a time. Mixing both can lead to unexpected behavior as they don't play well together.


## Automatic Event Handling

@docs Event, handleEvent


## Manual Event Handling

Animation events are different from transition events, so both types of events can be handled using the following functions:

For CSS keyframe animations.

@docs onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel


## Transition Events

For CSS transitions (used in CSS transform animations).

@docs onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel


# Global Settings

These settings will be used for all property animations unless overridden on a per-property basis.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay


# Querying Animation State

@docs anyRunning, isRunning, allComplete, isComplete


# Querying Animated Properties


## Background Color

@docs getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor


## Opacity

@docs getStartOpacity, getEndOpacity, getCurrentOpacity


## Position

@docs getStartPosition, getEndPosition, getCurrentPosition


## Rotate

@docs getStartRotate, getEndRotate, getCurrentRotate


## Scale

@docs getStartScale, getEndScale, getCurrentScale


## Size

@docs getStartSize, getEndSize, getCurrentSize

-}

import Anim.Internal.CSS as InternalCSS exposing (ElementState(..), Event(..))
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Timing.Easing as Easing exposing (Easing)
import Browser exposing (UrlRequest(..))
import Html
import Html.Attributes


{-| Transform property ordering.

The default (recommended) transform order is: Position → Rotate → Scale.

[animate](#animate) uses this transform order which should
be suitable for most use cases:

  - Position sets the base location
  - Rotation happens around that position
  - Scale happens last to avoid affecting rotation radius

Be aware that changing the transform order can lead to unexpected visual results,
as the order of transforms affects how they are applied.

-}
type TransformOrder
    = Position
    | Rotate
    | Scale


{-| Animation lifecycle events.
-}
type Event
    = AnimationStarted String
    | AnimationEnded String
    | AnimationCancelled String
    | AnimationIteration String
    | TransitionStarted String
    | TransitionEnded String
    | TransitionRun String
    | TransitionCancelled String


{-| Optional State for managing animations.

    import Anim.Engine.CSS as CSS

    { model | animations : CSS.AnimState }

This state keeps track of animations and their configurations.

If you only need to create fire-and-forget animations you don't need to add this type to your model.

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

This is an alternative to [animate](#animate) that allows you to specify the order
in which properties should be animated.

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


{-| This is an alternative to [animationStyleAttribute](#animationStyleAttribute) that also adds
event handlers for animation lifecycle events.


### HTML Example

    import Anim.Engine.CSS as CSS
    import Html exposing (div, text)
    import Html.Attributes exposing (id)

    div
        ([ id "my-element"
        , ...
        ]
            ++ CSS.animationStyleAttributeWithEvents "my-element" AnimationEvent animationState
        )
        [ text "Animating element" ]

For Elm UI, just wrap each attribute with [htmlAttribute](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/Element#htmlAttribute).


### Elm UI Example

    import Anim.Engine.CSS as CSS
    import Element exposing (el, htmlAttribute, map, text)
    import Html.Attributes exposing (id)

    el
        ([ htmlAttribute (id "my-element")
         , ...
         ]
            ++ (List.map htmlAttribute <|
                    CSS.animationStyleAttributeWithEvents "my-element" AnimationEvent animationState
               )
        )
        (text "Animating element")

-}
animationStyleAttributeWithEvents : String -> (Event -> msg) -> AnimState -> List (Html.Attribute msg)
animationStyleAttributeWithEvents elementId toMsg animationState =
    let
        eventHandlers =
            [ onAnimationStart (AnimationStarted elementId)
                |> Html.Attributes.map toMsg
            , onAnimationEnd (AnimationEnded elementId)
                |> Html.Attributes.map toMsg
            , onAnimationCancel (AnimationCancelled elementId)
                |> Html.Attributes.map toMsg
            , onAnimationIteration (AnimationIteration elementId)
                |> Html.Attributes.map toMsg
            ]
    in
    InternalCSS.animationStyleAttribute elementId animationState :: eventHandlers


{-| Generate the animation `<style>` attribute and apply it directly to the element you want to animate.

This creates the `animation` CSS property value that tells the browser which keyframe animation to run on this element.


### HTML Example

    import Anim.Engine.CSS as CSS
    import Html exposing (div, text)
    import Html.Attributes exposing (id)

    div
        [ Html.Attributes.id "my-element"
        , CSS.animationStyleAttribute "my-element" animationState
        ]
        [ text "Animating element" ]


### Elm UI Example

    import Anim.Engine.CSS as CSS
    import Element exposing (el, htmlAttribute, map, text)
    import Html.Attributes exposing (id)

    el
        [ htmlAttribute (id "my-element")
        , htmlAttribute (CSS.animationStyleAttribute "my-element" animationState)
        ]
        (text "Animating element")

Using this function is equivalent to manually writing something like:

    Html.Attributes.style "animation" "animation-name 2000ms linear 0ms"

**Note:**

1.  You still need to include the keyframes in your DOM separately with
    [ keyframesStyleNode ](#keyframesStyleNode) or [ keyframesStyleNodeFor ](#keyframesStyleNodeFor).

2.  The Easing function will always be "linear" for the CSS animation property. This is because the easing
    is baked into the keyframes themselves, so we need to transition between keyframe values linearly.
    This is the only way to achieve:
      - Accurate curves for advanced easing functions (like bounce, elastic, etc.)
      - Independent easing per property within the same animation

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
anyRunning : AnimState -> Bool
anyRunning =
    InternalCSS.anyRunning


{-| Check if a specific element has any animations currently running.
-}
isRunning : String -> AnimState -> Bool
isRunning elementId animState =
    InternalCSS.isElementRunning elementId animState


{-| Check if a specific element's animations have completed.

Returns `Nothing` if there are no animations for the element.

-}
isComplete : String -> AnimState -> Maybe Bool
isComplete elementId animState =
    InternalCSS.isElementComplete elementId animState


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete animState =
    InternalCSS.allComplete animState


{-| Handle animation lifecycle events.

Call this function from your update function when you receive CSS animation events:

    type Msg
        = CSSEvent CSS.Event
        | ...

    update msg model =
        case msg of
            CSSEvent event ->
                { model | animState = CSS.handleEvent event model.animState }

    div
        [ CSS.animationStyleAttributeWithEvents "element-id" CSSEvent model.animState
        , ...
        ]
        [ ... ]

-}
handleEvent : Event -> AnimState -> AnimState
handleEvent event animState =
    case event of
        AnimationStarted elementId ->
            InternalCSS.handleEvent (InternalCSS.AnimationStarted elementId) animState

        AnimationEnded elementId ->
            InternalCSS.handleEvent (InternalCSS.AnimationEnded elementId) animState

        AnimationCancelled elementId ->
            InternalCSS.handleEvent (InternalCSS.AnimationCancelled elementId) animState

        AnimationIteration elementId ->
            InternalCSS.handleEvent (InternalCSS.AnimationIteration elementId) animState

        TransitionStarted elementId ->
            InternalCSS.handleEvent (InternalCSS.TransitionStarted elementId) animState

        TransitionEnded elementId ->
            InternalCSS.handleEvent (InternalCSS.TransitionEnded elementId) animState

        TransitionRun elementId ->
            InternalCSS.handleEvent (InternalCSS.TransitionRun elementId) animState

        TransitionCancelled elementId ->
            InternalCSS.handleEvent (InternalCSS.TransitionCancelled elementId) animState


getCurrent : String -> Maybe a -> a -> a -> AnimState -> Maybe a
getCurrent elementId maybeStart end default animState =
    case InternalCSS.getState elementId animState of
        Just Running ->
            -- Animation is running, element is moving toward end value
            Just end

        Just Complete ->
            -- Animation has completed, element is at end value
            Just end

        _ ->
            -- Animation not started, use start value or default
            case maybeStart of
                Nothing ->
                    Just default

                Just startValue ->
                    Just startValue


{-| Get the start position of an element being animated.

Returns `Nothing` if the element has no position animation.
If no explicit start position was set, returns (0, 0) as the default.

-}
getStartPosition : String -> AnimState -> Maybe Position
getStartPosition elementId animState =
    InternalCSS.getPositionRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        Position.fromTuple ( 0, 0 )

                    Just startPos ->
                        startPos
            )


{-| Get the end position of an element being animated.

Returns `Nothing` if the element has no position animation.

-}
getEndPosition : String -> AnimState -> Maybe Position
getEndPosition elementId animState =
    InternalCSS.getPositionRange elementId animState
        |> Maybe.map .end


{-| Get the current position of an element based on its animation state.

Returns the start position if the animation has not started yet, or the end position
if the animation is running or has completed.

This is useful for determining where an element is positioned at any point in time,
regardless of animation state.

-}
getCurrentPosition : String -> AnimState -> Maybe Position
getCurrentPosition elementId animState =
    InternalCSS.getPositionRange elementId animState
        |> Maybe.andThen
            (\{ start, end } ->
                getCurrent elementId start end (Position.fromTuple ( 0, 0 )) animState
            )


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.
If no explicit start scale was set, returns uniform scale of 1.0 as the default.

-}
getStartScale : String -> AnimState -> Maybe Scale.Scale
getStartScale elementId animState =
    InternalCSS.getScaleRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        Scale.fromUniform 1.0

                    Just startScale ->
                        startScale
            )


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getEndScale : String -> AnimState -> Maybe Scale.Scale
getEndScale elementId animState =
    InternalCSS.getScaleRange elementId animState
        |> Maybe.map .end


{-| Get the current scale of an element based on its animation state.

Returns the start scale if the animation has not started yet, or the end scale
if the animation is running or has completed.

-}
getCurrentScale : String -> AnimState -> Maybe Scale.Scale
getCurrentScale elementId animState =
    InternalCSS.getScaleRange elementId animState
        |> Maybe.andThen
            (\{ start, end } ->
                getCurrent elementId start end (Scale.fromUniform 1.0) animState
            )


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.
If no explicit start rotation was set, returns 0.0 degrees as the default.

-}
getStartRotate : String -> AnimState -> Maybe Rotate.Rotate
getStartRotate elementId animState =
    InternalCSS.getRotateRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        Rotate.fromFloat 0.0

                    Just startRotate ->
                        startRotate
            )


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getEndRotate : String -> AnimState -> Maybe Rotate.Rotate
getEndRotate elementId animState =
    InternalCSS.getRotateRange elementId animState
        |> Maybe.map .end


{-| Get the current rotation of an element based on its animation state.

Returns the start rotation if the animation has not started yet, or the end rotation
if the animation is running or has completed.

-}
getCurrentRotate : String -> AnimState -> Maybe Rotate.Rotate
getCurrentRotate elementId animState =
    InternalCSS.getRotateRange elementId animState
        |> Maybe.andThen
            (\{ start, end } ->
                getCurrent elementId start end (Rotate.fromFloat 0.0) animState
            )


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.
If no explicit start color was set, returns black (rgb 0 0 0) as the default.

-}
getStartBackgroundColor : String -> AnimState -> Maybe BackgroundColor.Color
getStartBackgroundColor elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        BackgroundColor.rgb255 0 0 0

                    Just startColor ->
                        startColor
            )


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getEndBackgroundColor : String -> AnimState -> Maybe BackgroundColor.Color
getEndBackgroundColor elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.map .end


{-| Get the current background color of an element based on its animation state.

Returns the start color if the animation has not started yet, or the end color
if the animation is running or has completed.

-}
getCurrentBackgroundColor : String -> AnimState -> Maybe BackgroundColor.Color
getCurrentBackgroundColor elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.andThen
            (\{ start, end } ->
                getCurrent elementId start end (BackgroundColor.rgb255 0 0 0) animState
            )


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.
If no explicit start opacity was set, returns 1.0 (fully opaque) as the default.

-}
getStartOpacity : String -> AnimState -> Maybe Opacity.Opacity
getStartOpacity elementId animState =
    InternalCSS.getOpacityRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        Opacity.fromFloat 1.0

                    Just startOpacity ->
                        startOpacity
            )


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getEndOpacity : String -> AnimState -> Maybe Opacity.Opacity
getEndOpacity elementId animState =
    InternalCSS.getOpacityRange elementId animState
        |> Maybe.map .end


{-| Get the current opacity of an element based on its animation state.

Returns the start opacity if the animation has not started yet, or the end opacity
if the animation is running or has completed.

-}
getCurrentOpacity : String -> AnimState -> Maybe Opacity.Opacity
getCurrentOpacity elementId animState =
    InternalCSS.getOpacityRange elementId animState
        |> Maybe.andThen
            (\{ start, end } ->
                getCurrent elementId start end (Opacity.fromFloat 1.0) animState
            )


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.
If no explicit start size was set, returns (0, 0) as the default.

-}
getStartSize : String -> AnimState -> Maybe Size.Size
getStartSize elementId animState =
    InternalCSS.getSizeRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        Size.fromTuple ( 0, 0 )

                    Just startSize ->
                        startSize
            )


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getEndSize : String -> AnimState -> Maybe Size.Size
getEndSize elementId animState =
    InternalCSS.getSizeRange elementId animState
        |> Maybe.map .end


{-| Get the current size of an element based on its animation state.

Returns the start size if the animation has not started yet, or the end size
if the animation is running or has completed.

-}
getCurrentSize : String -> AnimState -> Maybe Size.Size
getCurrentSize elementId animState =
    InternalCSS.getSizeRange elementId animState
        |> Maybe.andThen
            (\{ start, end } ->
                getCurrent elementId start end (Size.fromTuple ( 0, 0 )) animState
            )


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
    import Element exposing (el, htmlAttribute, map, text)

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


{-| This is an alternative to [htmlAttributes](#htmlAttributes) that also adds
event handlers for animation lifecycle events.


### HTML Example

    import Anim.Engine.CSS as CSS
    import Html exposing (div, text)
    import Html.Attributes exposing (id)

    div
        ([ id "my-element"
         , ...
         ]
            ++ CSS.htmlAttributesWithEvents "my-element" AnimationEvent animationState
        )
        [ text "Animating element" ]

For Elm UI, just wrap each attribute with [htmlAttribute](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/Element#htmlAttribute).


### Elm UI Example

    import Anim.Engine.CSS as CSS
    import Element exposing (el, htmlAttribute, map, text)
    import Html.Attributes exposing (id)

    el
        ([ htmlAttribute (id "my-element")
         , ...
         ]
            ++ (List.map htmlAttribute <|
                    CSS.htmlAttributesWithEvents "my-element" AnimationEvent animationState
               )
        )
        (text "Animating element")

-}
htmlAttributesWithEvents : String -> (Event -> msg) -> AnimState -> List (Html.Attribute msg)
htmlAttributesWithEvents elementId msg animationState =
    let
        eventHandlers =
            [ onTransitionStart (TransitionStarted elementId)
                |> Html.Attributes.map msg
            , onTransitionEnd (TransitionEnded elementId)
                |> Html.Attributes.map msg
            , onTransitionCancel (TransitionCancelled elementId)
                |> Html.Attributes.map msg
            , onTransitionRun (TransitionRun elementId)
                |> Html.Attributes.map msg
            ]
    in
    InternalCSS.htmlAttributes elementId animationState ++ eventHandlers



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
