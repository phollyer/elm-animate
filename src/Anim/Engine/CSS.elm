module Anim.Engine.CSS exposing
    ( transitionAttributes
    , keyframeAnimationAttribute
    , keyframesStyleNode, keyframesStyleNodeFor, getElementKeyframes
    , AnimState, init, AnimBuilder, builder
    , animate, TransformOrder(..), animateOrder
    , onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel
    , onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel
    , Event(..), handleEvent
    , transitionEvents, keyframeAnimationEvents
    , stop, reset, restart, pause, resume
    , perspective
    , perspectiveStyles, perspectiveWith
    , duration, speed
    , easing
    , delay
    , anyRunning, isRunning, allComplete, isComplete
    , getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor
    , getStartOpacity, getEndOpacity, getCurrentOpacity
    , getStartTranslate, getEndTranslate, getCurrentTranslate
    , getStartRotate, getEndRotate, getCurrentRotate
    , getStartScale, getEndScale, getCurrentScale
    , getStartSize, getEndSize, getCurrentSize
    )

{-| CSS-based animation system with optional state tracking.

This Engine converts [AnimBuilder](#AnimBuilder) configurations to CSS animations which you can apply as either:

1.  **CSS transitions**, or,
2.  **Keyframe animations**

You decide how to apply the generated CSS to your elements in your view - giving you full control
over how the CSS is integrated into your application.


## Design Decisions

**Choosing Between Transitions and Keyframes**

The choice between transitions and keyframes is the main decision you need to make when using this Engine,
creating animations with either approach is exactly the same using the [AnimBuilder](#AnimBuilder) API.

**Use Transitions for:**

  - Basic A→B animations
  - Simple easing (ease, ease-in-out, cubic-bezier)
  - Minimal setup (no style node required)

**Use Keyframes when you need:**

  - Complex animations
  - Advanced easing curves (bounce, elastic, back, etc.)
  - Fine-grained control over animation timing
  - Better debugging visibility in DevTools


## CSS Transitions

For CSS transitions, you just need to apply the generated [transition](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Transitions/Using)
and [transform](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Transforms/Using)
attributes to your elements.

@docs transitionAttributes


## Keyframe Animations

For Keyframe animations, you need to apply the generated CSS [animation](https://developer.mozilla.org/en-US/docs/Web/CSS/animation) property to your elements
and also add the generated keyframes to a node in your DOM.

@docs keyframeAnimationAttribute

@docs keyframesStyleNode, keyframesStyleNodeFor, getElementKeyframes


# Build

@docs AnimState, init, AnimBuilder, builder


# Execute

@docs animate, TransformOrder, animateOrder


# Event Handling

CSS transitions and keyframe animations can trigger events at various stages of their lifecycle.
You have two options for handling these events in your application:

1.  **Manual Event Handling:** Manually add event handlers to your elements using the provided event handler functions.

2.  **Automatic Event Handling**: Generate [Event](#Event) messages that you can process in your update function.


## Manual Event Handling

For fire-and-forget animations where you don't track state in your model.


### Transition Animation Events

@docs onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel


### Keyframe Animation Events

@docs onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel


## Automatic Event Handling

For when you are tracking animation state in your model.

@docs Event, handleEvent


### Wiring Up Events

In order for your application to respond to animation events, you need to add the appropriate event handlers to your animated elements.

@docs transitionEvents, keyframeAnimationEvents


# Animation Control

Control running animations with stop, reset, restart, pause, and resume functionality.

**CSS Animation Behavior:**

  - **stop**: Instantly jumps to the animation's end state.
    Triggers `transitionend`/`animationend` events.
  - **reset**: Instantly jumps back to the animation's start state.
    Triggers `transitionend`/`animationend` events.
  - **restart**: Restarts the animation from the beginning.
    Triggers `transitionrun`/`animationstart` events.
  - **pause**: Pauses animations mid-flight.
    Note: Only works with keyframe animations, not CSS transitions.
  - **resume**: Resumes paused keyframe animations.
    Note: Only works with keyframe animations, not CSS transitions.

@docs stop, reset, restart, pause, resume


# 3D Animations

For 3D animations you need to set a perspective
to give a sense of depth. Without perspective, 3D animations will have no visual effect, and will appear flat.


## Perspective

@docs perspective


## HTML

@docs perspectiveStyles, perspectiveWith


# Global Settings

These settings will be used for all animations unless overridden on a per-property basis.


## Timing

@docs duration, speed


## Easing

@docs easing

**Reminder:**

  - **Keyframe Animations:** the easing is baked into the keyframes themselves, enabling complex easing
    curves like bounce and elastic to be accurately represented,
  - **Transform Animations:** complex easing curves like bounce and elastic have to be approximated by a `cubic-bezier` curve, meaning that
    they **can not** be perfectly represented. _This is a limitation of CSS transitions, not the animation engine itself._


## Delay

@docs delay


# Querying Animation State

@docs anyRunning, isRunning, allComplete, isComplete


# Querying Animated Properties

**When tracking state in your model**: CSS animations, whether using transforms or keyframes, do not provide direct mid-flight access to the current values of properties.
_This is a limitation of CSS itself._
However, this engine tracks the start and end values of animated properties, allowing you to query these values as needed.

If you need accurate mid-flight values, consider using the [Sub](Anim.EngineSub) or [WAAPI](Anim.Engine.WAAPI) Engines instead,
which provide real-time access to animated property values.


## Background Color

@docs getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor


## Opacity

@docs getStartOpacity, getEndOpacity, getCurrentOpacity


## Translate

@docs getStartTranslate, getEndTranslate, getCurrentTranslate


## Rotate

@docs getStartRotate, getEndRotate, getCurrentRotate


## Scale

@docs getStartScale, getEndScale, getCurrentScale


## Size

@docs getStartSize, getEndSize, getCurrentSize

-}

import Anim.Color exposing (Color)
import Anim.Easing exposing (Easing)
import Anim.Internal.CSS as InternalCSS exposing (ElementState(..), Event(..))
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate as Translate
import Browser exposing (UrlRequest(..))
import Html
import Html.Attributes


{-| Transform property ordering.

The default (recommended) transform order is: Translate → Rotate → Scale.

[animate](#animate) uses this transform order which should
be suitable for most use cases:

  - Translate sets the base location
  - Rotation happens around that position
  - Scale happens last to avoid affecting rotation radius

Be aware that changing the transform order can lead to unexpected visual results,
as the order of transforms affects how they are applied.

-}
type TransformOrder
    = Translate
    | Rotate
    | Scale


{-| Animation lifecycle events.
-}
type Event
    = KeyframeAnimationStarted String
    | KeyframeAnimationEnded String
    | KeyframeAnimationCancelled String
    | KeyframeAnimationIteration String
    | TransitionStarted String
    | TransitionEnded String
    | TransitionCancelled String
    | TransitionRun String


{-| Optional State for managing animations.

    import Anim.Engine.CSS as CSS

    { model | animations : CSS.AnimState }

This state keeps track of animations and their configurations.

**Note**: You do not need this for fire-and-forget animations.

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
    model.animations -- Or `CSS.init`
        |> CSS.builder
        |> -- ... property configurations ...
        |> CSS.animateOrder [ Scale, Rotate, Position ]

-}
animateOrder : List TransformOrder -> AnimBuilder -> AnimState
animateOrder order =
    let
        mapOrder transform =
            case transform of
                Translate ->
                    InternalCSS.Translate

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
        |> ... -- continue building the animation

-}
init : AnimState
init =
    InternalCSS.init


{-| Turn the [AnimState](#AnimState) into an [AnimBuilder](#AnimBuilder).

Use this to start building new animations.

    -- Create a new animation based on current state
    model.animations
        |> CSS.builder
        |> ... -- continue building the animation


    -- Create a new fire-and-forget animation
    CSS.init
        |> CSS.builder
        |> ... -- continue building the animation

-}
builder : AnimState -> AnimBuilder
builder =
    InternalCSS.builder


{-| Opt-in to receive keyframe animation event messages for the target element.

    import Anim.Engine.CSS as CSS
    import Html exposing (div, text)

    type Msg
        = KeyframeEvent CSS.Event

    div
        ( CSS.keyframeAnimationAttributes "my-element" animationState
            ++ CSS.keyframeAnimationEvents "my-element" KeyframeEvent
        )
        [ text "Animating element" ]

-}
keyframeAnimationEvents : String -> (Event -> msg) -> List (Html.Attribute msg)
keyframeAnimationEvents elementId toMsg =
    List.map (Html.Attributes.map toMsg) <|
        [ onAnimationStart (KeyframeAnimationStarted elementId)
        , onAnimationEnd (KeyframeAnimationEnded elementId)
        , onAnimationCancel (KeyframeAnimationCancelled elementId)
        , onAnimationIteration (KeyframeAnimationIteration elementId)
        ]


{-| Generate the animation `style` attribute and apply it directly to the element you want to animate.

This creates the `animation` CSS property value that tells the browser which keyframe animation to run on this element.

    import Anim.Engine.CSS as CSS
    import Html exposing (div, text)

    div
        [ CSS.keyframeAnimationAttribute "my-element" animationState ]
        [ text "Animating element" ]

-}
keyframeAnimationAttribute : String -> AnimState -> Html.Attribute msg
keyframeAnimationAttribute =
    InternalCSS.animationStyleAttribute


{-| Generate a `<style>` node containing keyframes for all animated elements. You
can add this node anywhere in your DOM, typically near the top.

    view model =
        div []
            [ CSS.keyframesStyleNode model.animationState ]

If there are no animations, this returns an empty text node.

-}
keyframesStyleNode : AnimState -> Html.Html msg
keyframesStyleNode =
    InternalCSS.keyframesStyleNode


{-| Generate a `<style>` node containing keyframes for a specific element, giving you fine-grained control over which
keyframes are included in your DOM. You can add this node anywhere in your DOM, typically near the top.

    view model =
        div []
            [ CSS.keyframesStyleNodeFor "my-element" model.animationState ]

If the element has no animations, this returns an empty text node.

-}
keyframesStyleNodeFor : String -> AnimState -> Html.Html msg
keyframesStyleNodeFor =
    InternalCSS.keyframesStyleNodeFor


{-| Get the raw generated CSS keyframes string that can be inserted into a `<style>` node.

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

Call this function from your update function.

    type Msg
        = CSSEvent CSS.Event
        | ...

    update msg model =
        case msg of
            CSSEvent event ->
                let
                    newModel =
                        { model | animations = CSS.handleEvent event model.animations }
                in
                case event of
                    CSS.KeyframeAnimationEnded elementId ->
                        -- Do something when animation ends
                        ( newModel, Cmd.none )

                    _ ->
                        ( newModel, Cmd.none )

-}
handleEvent : Event -> AnimState -> AnimState
handleEvent event animState =
    case event of
        KeyframeAnimationStarted elementId ->
            InternalCSS.handleEvent (InternalCSS.AnimationStarted elementId) animState

        KeyframeAnimationEnded elementId ->
            InternalCSS.handleEvent (InternalCSS.AnimationEnded elementId) animState

        KeyframeAnimationCancelled elementId ->
            InternalCSS.handleEvent (InternalCSS.AnimationCancelled elementId) animState

        KeyframeAnimationIteration elementId ->
            InternalCSS.handleEvent (InternalCSS.AnimationIteration elementId) animState

        TransitionStarted elementId ->
            InternalCSS.handleEvent (InternalCSS.TransitionStarted elementId) animState

        TransitionEnded elementId ->
            InternalCSS.handleEvent (InternalCSS.TransitionEnded elementId) animState

        TransitionRun elementId ->
            InternalCSS.handleEvent (InternalCSS.TransitionRun elementId) animState

        TransitionCancelled elementId ->
            InternalCSS.handleEvent (InternalCSS.TransitionCancelled elementId) animState


getCurrent : String -> a -> AnimState -> { start : Maybe a, end : a } -> Maybe a
getCurrent elementId default animState range =
    InternalCSS.getState elementId animState
        |> Maybe.map
            (\state ->
                case state of
                    NotStarted ->
                        -- Animation not started, use start value or default
                        case range.start of
                            Nothing ->
                                default

                            Just startValue ->
                                startValue

                    Running ->
                        -- Animation is running, element is moving toward end value
                        range.end

                    Complete ->
                        -- Animation has completed, element is at end value
                        range.end
            )


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartTranslate elementId animState =
    InternalCSS.getTranslateRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 0, y = 0, z = 0 }

                    Just startPos ->
                        Translate.toRecord startPos
            )


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getEndTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndTranslate elementId animState =
    InternalCSS.getTranslateRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Translate.toRecord


{-| Get the current translate of an element based on its animation state.

Returns `Nothing` if the element has no translate animation.

Returns the start translate if the animation has not started yet.

Returns the end translate if the animation is running or has completed.

-}
getCurrentTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentTranslate elementId animState =
    InternalCSS.getTranslateRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId Translate.default animState)
        |> Maybe.map Translate.toRecord


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartScale elementId animState =
    InternalCSS.getScaleRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 1, y = 1, z = 1 }

                    Just startScale ->
                        Scale.toRecord startScale
            )


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getEndScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndScale elementId animState =
    InternalCSS.getScaleRange elementId animState
        |> Maybe.map (.end >> Scale.toRecord)


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the end scale if the animation is running or has completed.

-}
getCurrentScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentScale elementId animState =
    InternalCSS.getScaleRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId (Scale.fromUniform 1.0) animState)
        |> Maybe.map Scale.toRecord


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartRotate elementId animState =
    InternalCSS.getRotateRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 0, y = 0, z = 0 }

                    Just startRotate ->
                        Rotate.toRecord startRotate
            )


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getEndRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndRotate elementId animState =
    InternalCSS.getRotateRange elementId animState
        |> Maybe.map (.end >> Rotate.toRecord)


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the end rotation if the animation is running or has completed.

-}
getCurrentRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentRotate elementId animState =
    InternalCSS.getRotateRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId Rotate.default animState)
        |> Maybe.map Rotate.toRecord


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getStartBackgroundColor : String -> AnimState -> Maybe Color
getStartBackgroundColor elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Just startColor ->
                        startColor

                    Nothing ->
                        BackgroundColor.default
            )


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getEndBackgroundColor : String -> AnimState -> Maybe Color
getEndBackgroundColor elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.map .end


{-| Get the current background color of an element based on its animation state.

Returns `Nothing` if the element has no background color animation.

Returns the start color if the animation has not started yet.

Returns the end color if the animation is running or has completed.

-}
getCurrentBackgroundColor : String -> AnimState -> Maybe Color
getCurrentBackgroundColor elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId BackgroundColor.default animState)


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getStartOpacity : String -> AnimState -> Maybe Float
getStartOpacity elementId animState =
    InternalCSS.getOpacityRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        1.0

                    Just startOpacity ->
                        Opacity.toFloat startOpacity
            )


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getEndOpacity : String -> AnimState -> Maybe Float
getEndOpacity elementId animState =
    InternalCSS.getOpacityRange elementId animState
        |> Maybe.map (.end >> Opacity.toFloat)


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the end opacity if the animation is running or has completed.

-}
getCurrentOpacity : String -> AnimState -> Maybe Float
getCurrentOpacity elementId animState =
    InternalCSS.getOpacityRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId Opacity.default animState)
        |> Maybe.map Opacity.toFloat


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartSize : String -> AnimState -> Maybe { width : Float, height : Float }
getStartSize elementId animState =
    InternalCSS.getSizeRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { width = 0, height = 0 }

                    Just startSize ->
                        Size.toRecord startSize
            )


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getEndSize : String -> AnimState -> Maybe { width : Float, height : Float }
getEndSize elementId animState =
    InternalCSS.getSizeRange elementId animState
        |> Maybe.map (.end >> Size.toRecord)


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the end size if the animation is running or has completed.

-}
getCurrentSize : String -> AnimState -> Maybe { width : Float, height : Float }
getCurrentSize elementId animState =
    InternalCSS.getSizeRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId Size.default animState)
        |> Maybe.map Size.toRecord


{-| Set the global duration in milliseconds (overrides any previous speed setting).

    model.animations
        |> CSS.builder
        |> Css.duration 1000
        |> ... -- continue building the animation

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalCSS.duration


{-| Set the global speed in units per second (overrides any previous duration setting).

Exactly what "units" means depends on the properties being animated. For position properties, this is pixels per second.
Refer to the relevant property documentation for specific details for each property.

    model.animations
        |> CSS.builder
        |> Css.speed 100
        |> ... -- continue building the animation

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalCSS.speed


{-| Set the global easing function.

    model.animations
        |> CSS.builder
        |> Css.easing EaseInOutQuad
        |> ... -- continue building the animation

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalCSS.easing


{-| Set the global delay in milliseconds.

    model.animations
        |> CSS.builder
        |> Css.delay 500
        |> ... -- continue building the animation

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalCSS.delay


{-| Set the global perspective value.

The perspective value determines the distance between the viewer and the `z = 0` plane.
Smaller values create more dramatic 3D effects, while larger values create subtler effects.

    model.animations
        |> CSS.builder
        |> Css.perspective "container-id" 1000
        |> ... -- continue building the animation

You can override this global setting for specific properties using property-specific `perspective` functions.

-}
perspective : String -> Float -> AnimBuilder -> AnimBuilder
perspective =
    InternalCSS.perspective


{-| Generate HTML attributes for container elements that need perspective.

This function generates the necessary CSS perspective attributes for container elements
to properly display 3D animations. Apply these attributes to the parent containers
of animated elements.

    model.animations
        |> CSS.builder
        |> CSS.perspective "main-container" 1000
        |> ...

    div
        (CSS.perspectiveStyles "main-container" model.animations)
        [ div
            (CSS.htmlAttributes "animated-element" model.animations)
            [ text "3D animated content" ]
        ]

This looks up perspective settings for the specified container from both global settings
and property-level overrides, with property-level taking precedence.

-}
perspectiveStyles : String -> AnimState -> List (Html.Attribute msg)
perspectiveStyles =
    InternalCSS.perspectiveStyles


{-| Manually generate HTML attributes with a given perspective value.

Perspective controls the viewer's distance from the 3D scene (not zoom/magnification).
Lower values create more dramatic 3D effects, higher values create more subtle effects.

Can be applied to any ancestor element of 3D-transformed children, not just direct parents.
Set this on the root node for global effect, and override on specific containers as needed.

Common values: 500-2000px.

    -- Adjust 3D depth effect dynamically

    update msg model =
        case msg of
            IncreaseDepth ->
                { model | viewerDistance = model.viewerDistance - 100 }

            DecreaseDepth ->
                { model | viewerDistance = model.viewerDistance + 100 }


    div
        (CSS.perspectiveWith model.viewerDistance)
        [ -- Animated content with 3D transforms
        ]

**Elm-side styles take precedence**: When you use this function, the JavaScript will detect
the existing inline style and skip auto-applying perspective, giving you full control.

-}
perspectiveWith : Float -> List (Html.Attribute msg)
perspectiveWith perspectiveValue =
    [ Html.Attributes.style "perspective" (String.fromFloat perspectiveValue ++ "px")
    , Html.Attributes.style "transform-style" "preserve-3d"
    ]


{-| Get all the attributes needed for the CSS transition on the target element.

    import Anim.Engine.CSS as CSS
    import Html exposing (div, text)

    div
        (CSS.transitionAttributes "my-element" model.animations)
        [ text "Animating element" ]

-}
transitionAttributes : String -> AnimState -> List (Html.Attribute msg)
transitionAttributes =
    InternalCSS.transitionAttributes


{-| Opt-in to receive transition event messages for the target element.

    import Anim.Engine.CSS as CSS
    import Html exposing (div, text)

    type Msg
        = TransitionEvent CSS.Event
        | ...

    div
        (CSS.transitionAttributes "my-element" animationState
            ++ CSS.transitionEvents "my-element" TransitionEvent
        )
        [ text "Animating element" ]

-}
transitionEvents : String -> (Event -> msg) -> List (Html.Attribute msg)
transitionEvents elementId msg =
    List.map (Html.Attributes.map msg) <|
        [ onTransitionStart (TransitionStarted elementId)
        , onTransitionEnd (TransitionEnded elementId)
        , onTransitionCancel (TransitionCancelled elementId)
        , onTransitionRun (TransitionRun elementId)
        ]



-- CSS TRANSITION EVENT HANDLERS


{-| Event handler for when a CSS transition starts animating (after any delay).
-}
onTransitionStart : msg -> Html.Attribute msg
onTransitionStart =
    InternalCSS.onTransitionStart


{-| Event handler for when a CSS transition ends.
-}
onTransitionEnd : msg -> Html.Attribute msg
onTransitionEnd =
    InternalCSS.onTransitionEnd


{-| Event handler for when a CSS transition is triggered (before any delay).
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



-- ANIMATION CONTROL


{-| Stop a running animation by instantly jumping to its end state.

This creates a 1ms CSS transition to the end position, effectively completing
the animation immediately.

    CSS.stop "my-element" model.animations

-}
stop : String -> AnimState -> AnimState
stop elementId animState =
    InternalCSS.stopAnimation elementId animState


{-| Reset an animation by instantly jumping back to its start state.

This creates a 1ms CSS transition to the start position.

    CSS.reset "my-element" model.animations

-}
reset : String -> AnimState -> AnimState
reset elementId animState =
    InternalCSS.resetAnimation elementId animState


{-| Restart an animation from the beginning.

This re-runs the full animation from start to end.

    CSS.restart "my-element" model.animations

-}
restart : String -> AnimState -> AnimState
restart elementId animState =
    InternalCSS.restartAnimation elementId animState


{-| Pause a running keyframe animation using CSS `animation-play-state`.

**Note**: This only works with keyframe animations, not CSS transitions.
CSS transitions cannot be paused once started.

    pausedAnimations =
        CSS.pause "my-element" model.animations

-}
pause : String -> AnimState -> AnimState
pause elementId animState =
    InternalCSS.pauseAnimation elementId animState


{-| Resume a paused keyframe animation using CSS `animation-play-state`.

**Note**: This only works with keyframe animations, not CSS transitions.

    resumedAnimations =
        CSS.resume "my-element" model.animations

-}
resume : String -> AnimState -> AnimState
resume elementId animState =
    InternalCSS.resumeAnimation elementId animState
