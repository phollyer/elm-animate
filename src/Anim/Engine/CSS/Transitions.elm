module Anim.Engine.CSS.Transitions exposing
    ( AnimState, init
    , attributes
    , AnimMsg(..), update, events
    , onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel
    , AnimBuilder, animate, fireAndForget, TransformOrder(..), animateOrder, fireAndForgetOrder
    , duration, speed
    , easing
    , delay
    , allowDiscrete
    , startingStyleNode, startingStyleNodeFor
    , stop, reset
    , anyRunning, isRunning, allComplete, isComplete
    , getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor
    , getStartOpacity, getEndOpacity, getCurrentOpacity
    , getStartRotate, getEndRotate, getCurrentRotate
    , getStartScale, getEndScale, getCurrentScale
    , getStartSize, getEndSize, getCurrentSize
    , getStartTranslate, getEndTranslate, getCurrentTranslate
    )

{-| CSS Transitions engine for smooth A→B animations.

CSS Transitions are the simplest way to animate elements. They work by smoothly
interpolating between two states when a property value changes.

**Use CSS Transitions for:**

  - Basic A→B animations (opacity, position, scale, etc.)
  - Simple easing (ease, ease-in-out, cubic-bezier)
  - Minimal setup (no style node required)

**Limitations:**

  - Complex easing curves (bounce, elastic) are approximated
  - No pause/resume support (use [Keyframes](Anim.Engine.CSS.Keyframes) instead)
  - No iteration/looping (use [Keyframes](Anim.Engine.CSS.Keyframes) instead)


# State

@docs AnimState, init


# Apply Transitions

Apply transition styles to your elements

@docs attributes


# Transition Events

CSS transitions trigger events at various stages of their lifecycle.
Use these events to keep your [AnimState](#AnimState) in sync.

@docs AnimMsg, update, events

For more granular control over which events to handle:

@docs onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel


# Execute

@docs AnimBuilder, animate, fireAndForget, TransformOrder, animateOrder, fireAndForgetOrder


# Default Settings


## Timing

@docs duration, speed


## Easing

@docs easing

**Note:** Complex easing curves like bounce and elastic are approximated by `cubic-bezier`.
For accurate complex curves, use [Keyframes](Anim.Engine.CSS.Keyframes) instead.


## Delay

@docs delay


## Discrete Property Transitions

CSS transitions only work by default with properties that have intermediate values.
Discrete properties like `display`, `visibility`, and `content-visibility` normally snap instantly.

@docs allowDiscrete

For **entry animations** (elements appearing), you also need `@starting-style` CSS rules
to define the initial state:

@docs startingStyleNode, startingStyleNodeFor


# Animation Control

@docs stop, reset

**Note:** `restart`, `pause`, and `resume` are not available for CSS transitions.
This is a limitation of the CSS API, not the engine. For these features,
consider using [Transitions](Anim.Engine.CSS.Transitions), [Sub](Anim.Engine.Sub) or [WAAPI](Anim.Engine.WAAPI) engines instead.


# Querying Animation State

@docs anyRunning, isRunning, allComplete, isComplete


# Querying Animated Properties

CSS transitions do not provide direct access to mid-flight values.
However, this engine tracks start and end values, allowing you to query them.

For accurate mid-flight values, consider [Sub](Anim.Engine.Sub) or [WAAPI](Anim.Engine.WAAPI) engines.


## Background Color

@docs getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor


## Opacity

@docs getStartOpacity, getEndOpacity, getCurrentOpacity


## Rotate

@docs getStartRotate, getEndRotate, getCurrentRotate


## Scale

@docs getStartScale, getEndScale, getCurrentScale


## Size

@docs getStartSize, getEndSize, getCurrentSize


## Translate

@docs getStartTranslate, getEndTranslate, getCurrentTranslate

-}

import Anim.Extra.Color exposing (Color)
import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.CSS as InternalCSS exposing (ElementState(..))
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate as Translate
import Html
import Html.Attributes



-- TYPES


{-| The animation state type used to store animation configurations and transitions.

Both state-tracked and fire-and-forget animations produce an `AnimState`, but only
state-tracked animations require storing it in your model:

    type alias Model =
        { animState : Transitions.AnimState }

-}
type alias AnimState =
    InternalCSS.AnimState


{-| Animation builder type for configuring animations.
-}
type alias AnimBuilder =
    InternalCSS.AnimBuilder


{-| Transform property ordering.

The **default** (recommended) transform order is: Translate → Rotate → Scale.

  - Translate sets the base location
  - Rotation happens around that position
  - Scale happens last to avoid affecting rotation radius

-}
type TransformOrder
    = Translate
    | Rotate
    | Scale


{-| CSS transition lifecycle messages.
-}
type AnimMsg
    = Started String
    | Ended String
    | Cancelled String
    | Run String



-- INIT


{-| Initialize animation state with optional property initializers.

    -- Empty state
    Transitions.init []

    -- With initial properties
    Transitions.init
        [ Translate.initXY "animGroupName" 100 50
        , Opacity.init "animGroupName" 0.5
        ]

-}
init : List (AnimBuilder -> AnimBuilder) -> AnimState
init =
    InternalCSS.init



-- EXECUTE


{-| Create a state-tracked animation.

    { model
        | animState =
            Transitions.animate model.animState <|
                (fadeIn >> slideIn)
    }

-}
animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate =
    InternalCSS.animate


{-| Apply the animation configuration with custom transform ordering.

    -- Custom transform order: Scale → Rotate → Translate
    Transitions.animateOrder [ Scale, Rotate, Translate ] model.animState <|
        rotateLeft
            >> scaleUp
            >> moveRight

-}
animateOrder : List TransformOrder -> AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animateOrder order =
    let
        mapOrder xform =
            case xform of
                Translate ->
                    InternalCSS.Translate

                Rotate ->
                    InternalCSS.Rotate

                Scale ->
                    InternalCSS.Scale
    in
    InternalCSS.animateWithOrder (List.map mapOrder order)


{-| Create a fire-and-forget animation without state tracking.

    entranceAnimation : Transitions.AnimState
    entranceAnimation =
        Transitions.fireAndForget <|
            (fadeIn >> slideIn)

-}
fireAndForget : (AnimBuilder -> AnimBuilder) -> AnimState
fireAndForget =
    animate (init [])


{-| Create a fire-and-forget animation with custom transform ordering.
-}
fireAndForgetOrder : List TransformOrder -> (AnimBuilder -> AnimBuilder) -> AnimState
fireAndForgetOrder order =
    animateOrder order (init [])



-- GLOBAL SETTINGS


{-| Set the global duration in milliseconds.

    model.animState
        |> Transitions.builder
        |> Transitions.duration 500
        |> ...

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalCSS.duration


{-| Set the global speed in pixels per second.

    model.animState
        |> Transitions.builder
        |> Transitions.speed 100
        |> ...

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalCSS.speed


{-| Set the global easing function.

    model.animState
        |> Transitions.builder
        |> Transitions.easing EaseInOutQuad
        |> ...

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalCSS.easing


{-| Set the global delay in milliseconds.

    model.animState
        |> Transitions.builder
        |> Transitions.delay 500
        |> ...

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalCSS.delay


{-| Enable transitions for discrete CSS properties using `transition-behavior: allow-discrete`.

    Transitions.animate model.animState <|
        (Transitions.allowDiscrete >> fadeIn >> slideIn)

-}
allowDiscrete : AnimBuilder -> AnimBuilder
allowDiscrete =
    Builder.allowDiscreteTransitions


{-| Generate a `<style>` node containing `@starting-style` rules for all animated elements.

When an element enters the DOM (or changes from `display: none`), the browser needs
to know what values to animate FROM. Without `@starting-style`, the browser skips
the transition.

    view model =
        div []
            [ Transitions.startingStyleNode model.animState
            , div (Transitions.attributes "fadeIn" model.animState)
                [ text "I fade in!" ]
            ]

-}
startingStyleNode : AnimState -> Html.Html msg
startingStyleNode =
    InternalCSS.startingStyleNode


{-| Generate `@starting-style` rules for a specific element.

    view model =
        div []
            [ Transitions.startingStyleNodeFor "fadeIn" model.animState
            , div (Transitions.attributes "fadeIn" model.animState)
                [ text "I fade in!" ]
            ]

-}
startingStyleNodeFor : String -> AnimState -> Html.Html msg
startingStyleNodeFor =
    InternalCSS.startingStyleNodeFor



-- TRANSITION ATTRIBUTES


{-| Get the transition and transform attributes to apply to the target element.

    div
        (Transitions.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : String -> AnimState -> List (Html.Attribute msg)
attributes =
    InternalCSS.transitionAttributes



-- TRANSITION EVENTS


{-| The simplest way to receive transition messages.

    type Msg
        = TransitionMsg Transitions.AnimMsg

    div
        (Transitions.attributes "animGroupName" animState
            ++ Transitions.events "animGroupName" TransitionMsg
        )
        [ text "Animating element" ]

-}
events : String -> (AnimMsg -> msg) -> List (Html.Attribute msg)
events elementId toMsg =
    List.map (Html.Attributes.map toMsg) <|
        [ onTransitionStart (Started elementId)
        , onTransitionEnd (Ended elementId)
        , onTransitionRun (Run elementId)
        , onTransitionCancel (Cancelled elementId)
        ]


{-| Handle CSS transition lifecycle messages.

    updateModel msg model =
        case msg of
            TransitionMsg animMsg ->
                { model | animState = Transitions.update animMsg model.animState }

-}
update : AnimMsg -> AnimState -> AnimState
update animMsg animState =
    case animMsg of
        Started elementId ->
            InternalCSS.handleEvent (InternalCSS.TransitionStarted elementId) animState

        Ended elementId ->
            InternalCSS.handleEvent (InternalCSS.TransitionEnded elementId) animState

        Run elementId ->
            InternalCSS.handleEvent (InternalCSS.TransitionRun elementId) animState

        Cancelled elementId ->
            InternalCSS.handleEvent (InternalCSS.TransitionCancelled elementId) animState


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


{-| Event handler for when a CSS transition runs.
-}
onTransitionRun : msg -> Html.Attribute msg
onTransitionRun =
    InternalCSS.onTransitionRun


{-| Event handler for when a CSS transition is cancelled.
-}
onTransitionCancel : msg -> Html.Attribute msg
onTransitionCancel =
    InternalCSS.onTransitionCancel



-- ANIMATION CONTROL


{-| Stop a running animation by instantly jumping to its end state.

    Transitions.stop "elementId" model.animState

-}
stop : String -> AnimState -> AnimState
stop =
    InternalCSS.stopAnimation


{-| Reset an animation by instantly jumping back to its start state.

    Transitions.reset "elementId" model.animState

-}
reset : String -> AnimState -> AnimState
reset =
    InternalCSS.reset



-- STATE QUERIES


{-| Check if any animations are currently running.
-}
anyRunning : AnimState -> Bool
anyRunning =
    InternalCSS.anyRunning


{-| Check if a specific element has any animations currently running.
-}
isRunning : String -> AnimState -> Bool
isRunning =
    InternalCSS.isRunning


{-| Check if a specific element's animations have completed.

Returns `Nothing` if there are no animations for the element.

-}
isComplete : String -> AnimState -> Maybe Bool
isComplete =
    InternalCSS.isComplete


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    InternalCSS.allComplete



-- PROPERTY GETTERS (HELPER)


getCurrent : String -> a -> AnimState -> { start : Maybe a, end : a } -> Maybe a
getCurrent elementId default animState range =
    InternalCSS.getState elementId animState
        |> Maybe.map
            (\state ->
                case state of
                    NotStarted ->
                        case range.start of
                            Nothing ->
                                default

                            Just startValue ->
                                startValue

                    Running ->
                        range.end

                    Complete ->
                        range.end
            )



-- TRANSLATE GETTERS


{-| Get the start translate value of an element being animated.

Returns `Nothing` if the element has no translate animation.

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


{-| Get the end translate value of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getEndTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndTranslate elementId animState =
    InternalCSS.getTranslateRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Translate.toRecord


{-| Get the current translate value based on animation state.

Returns `Nothing` if the element has no translate animation.

-}
getCurrentTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentTranslate elementId animState =
    InternalCSS.getTranslateRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId Translate.default animState)
        |> Maybe.map Translate.toRecord



-- SCALE GETTERS


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

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


{-| Get the current scale based on animation state.

Returns `Nothing` if the element has no scale animation.

-}
getCurrentScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentScale elementId animState =
    InternalCSS.getScaleRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId (Scale.fromUniform 1.0) animState)
        |> Maybe.map Scale.toRecord



-- ROTATE GETTERS


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

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


{-| Get the current rotation based on animation state.

Returns `Nothing` if the element has no rotate animation.

-}
getCurrentRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentRotate elementId animState =
    InternalCSS.getRotateRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId Rotate.default animState)
        |> Maybe.map Rotate.toRecord



-- OPACITY GETTERS


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

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


{-| Get the current opacity based on animation state.

Returns `Nothing` if the element has no opacity animation.

-}
getCurrentOpacity : String -> AnimState -> Maybe Float
getCurrentOpacity elementId animState =
    InternalCSS.getOpacityRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId Opacity.default animState)
        |> Maybe.map Opacity.toFloat



-- SIZE GETTERS


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

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


{-| Get the current size based on animation state.

Returns `Nothing` if the element has no size animation.

-}
getCurrentSize : String -> AnimState -> Maybe { width : Float, height : Float }
getCurrentSize elementId animState =
    InternalCSS.getSizeRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId Size.default animState)
        |> Maybe.map Size.toRecord



-- BACKGROUND COLOR GETTERS


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

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


{-| Get the current background color based on animation state.

Returns `Nothing` if the element has no background color animation.

-}
getCurrentBackgroundColor : String -> AnimState -> Maybe Color
getCurrentBackgroundColor elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId BackgroundColor.default animState)
