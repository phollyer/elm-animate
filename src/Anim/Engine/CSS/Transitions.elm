module Anim.Engine.CSS.Transitions exposing
    ( AnimState, init
    , attributes
    , AnimMsg, AnimEvent(..), update, events, eventsStopPropagation
    , onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel
    , onTransitionStartStopPropagation, onTransitionEndStopPropagation, onTransitionRunStopPropagation, onTransitionCancelStopPropagation
    , AnimBuilder, animate, fireAndForget, TransformOrder(..), animateOrder, fireAndForgetOrder
    , duration, speed
    , easing
    , delay
    , allowDiscrete
    , startingStyleNode, startingStyleNodeFor
    , stop, reset
    , anyRunning, isRunning, allComplete, isComplete
    , getBackgroundColorStart, getBackgroundColorEnd
    , getOpacityStart, getOpacityEnd
    , getRotateStart, getRotateEnd
    , getScaleStart, getScaleEnd
    , getSizeStart, getSizeEnd
    , getTranslateStart, getTranslateEnd
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

@docs AnimMsg, AnimEvent, update, events, eventsStopPropagation

For more granular control over which events to handle:

@docs onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel

To stop event propagation (for nested animated elements):

@docs onTransitionStartStopPropagation, onTransitionEndStopPropagation, onTransitionRunStopPropagation, onTransitionCancelStopPropagation


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

@docs getBackgroundColorStart, getBackgroundColorEnd


## Opacity

@docs getOpacityStart, getOpacityEnd


## Rotate

@docs getRotateStart, getRotateEnd


## Scale

@docs getScaleStart, getScaleEnd


## Size

@docs getSizeStart, getSizeEnd


## Translate

@docs getTranslateStart, getTranslateEnd

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


{-| Opaque message type for CSS transition DOM events.

Pass this to your parent Msg type and forward it to [update](#update).

    type Msg
        = TransitionMsg Transitions.AnimMsg
        | ...

-}
type AnimMsg
    = AnimMsg InternalAnimMsg


{-| Internal message variants.
-}
type InternalAnimMsg
    = InternalStarted InternalCSS.SourceEventData
    | InternalEnded InternalCSS.SourceEventData
    | InternalCancelled InternalCSS.SourceEventData
    | InternalRun InternalCSS.SourceEventData


{-| CSS transition lifecycle events.

Returned by [update](#update) for you to pattern match and react to.

Each event contains three `String` values: `currentTargetId`, `targetId`, and `animGroup`.

  - `currentTargetId`: The HTML `id` attribute of the element where the handler is attached.
    This is an empty string `""` if the element has no `id` attribute set.
  - `targetId`: The HTML `id` attribute of the element that triggered the event (event.target).
    This is an empty string `""` if the element has no `id` attribute set.
  - `animGroup`: The animation group name passed to `Transitions.attributes`.

You can pattern match on any combination of values:

    handleAnimationEvent : Transitions.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            -- Match specific handler, any source element, specific animation
            Transitions.Ended "container" _ "fadeIn" ->
                ( { model | phase = Complete }, Cmd.none )

            -- Match any handler and any source with a specific animation group
            Transitions.Ended _ _ "box" ->
                ( model, startNextAnimation )

            -- Match specific source element with any handler and animation
            Transitions.Ended _ "header" _ ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

-}
type AnimEvent
    = Started String String String
    | Ended String String String
    | Cancelled String String String
    | Run String String String



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
events animGroup toMsg =
    List.map (Html.Attributes.map toMsg) <|
        [ InternalCSS.onTransitionStartWithSource animGroup (AnimMsg << InternalStarted)
        , InternalCSS.onTransitionEndWithSource animGroup (AnimMsg << InternalEnded)
        , InternalCSS.onTransitionRunWithSource animGroup (AnimMsg << InternalRun)
        , InternalCSS.onTransitionCancelWithSource animGroup (AnimMsg << InternalCancelled)
        ]


{-| Handle CSS transition lifecycle messages.

Returns the updated state and an event for you to pattern match on.

    updateModel msg model =
        case msg of
            TransitionMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Transitions.update animMsg model.animState
                in
                handleAnimationEvent event { model | animState = newAnimState }

    handleAnimationEvent : Transitions.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            Transitions.Ended _ _ animGroup ->
                -- Animation ended
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

-}
update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update (AnimMsg animMsg) animState =
    let
        idOrEmpty maybeId =
            Maybe.withDefault "" maybeId
    in
    case animMsg of
        InternalStarted data ->
            ( InternalCSS.handleEvent (InternalCSS.TransitionStarted data.animGroup) animState
            , Started (idOrEmpty data.currentTargetId) (idOrEmpty data.domElementId) data.animGroup
            )

        InternalEnded data ->
            ( InternalCSS.handleEvent (InternalCSS.TransitionEnded data.animGroup) animState
            , Ended (idOrEmpty data.currentTargetId) (idOrEmpty data.domElementId) data.animGroup
            )

        InternalRun data ->
            ( InternalCSS.handleEvent (InternalCSS.TransitionRun data.animGroup) animState
            , Run (idOrEmpty data.currentTargetId) (idOrEmpty data.domElementId) data.animGroup
            )

        InternalCancelled data ->
            ( InternalCSS.handleEvent (InternalCSS.TransitionCancelled data.animGroup) animState
            , Cancelled (idOrEmpty data.currentTargetId) (idOrEmpty data.domElementId) data.animGroup
            )


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


{-| Like [onTransitionStart](#onTransitionStart) but stops event propagation.
Use this to prevent events from bubbling up to parent elements with listeners.
-}
onTransitionStartStopPropagation : msg -> Html.Attribute msg
onTransitionStartStopPropagation =
    InternalCSS.onTransitionStartStopPropagation


{-| Like [onTransitionEnd](#onTransitionEnd) but stops event propagation.
Use this to prevent events from bubbling up to parent elements with listeners.
-}
onTransitionEndStopPropagation : msg -> Html.Attribute msg
onTransitionEndStopPropagation =
    InternalCSS.onTransitionEndStopPropagation


{-| Like [onTransitionRun](#onTransitionRun) but stops event propagation.
Use this to prevent events from bubbling up to parent elements with listeners.
-}
onTransitionRunStopPropagation : msg -> Html.Attribute msg
onTransitionRunStopPropagation =
    InternalCSS.onTransitionRunStopPropagation


{-| Like [onTransitionCancel](#onTransitionCancel) but stops event propagation.
Use this to prevent events from bubbling up to parent elements with listeners.
-}
onTransitionCancelStopPropagation : msg -> Html.Attribute msg
onTransitionCancelStopPropagation =
    InternalCSS.onTransitionCancelStopPropagation


{-| All transition event handlers with propagation stopped.
Use this to prevent events from bubbling up to parent elements with listeners.

    div
        (Transitions.attributes "myElement" model.animState
            ++ Transitions.eventsStopPropagation "myElement" TransitionMsg
        )
        [ text "Animated element" ]

-}
eventsStopPropagation : String -> (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation animGroup toMsg =
    List.map (Html.Attributes.map toMsg) <|
        [ InternalCSS.onTransitionStartWithSourceStopPropagation animGroup (AnimMsg << InternalStarted)
        , InternalCSS.onTransitionEndWithSourceStopPropagation animGroup (AnimMsg << InternalEnded)
        , InternalCSS.onTransitionRunWithSourceStopPropagation animGroup (AnimMsg << InternalRun)
        , InternalCSS.onTransitionCancelWithSourceStopPropagation animGroup (AnimMsg << InternalCancelled)
        ]



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



-- TRANSLATE GETTERS


{-| Get the start translate value of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateStart : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart elementId animState =
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
getTranslateEnd : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd elementId animState =
    InternalCSS.getTranslateRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Translate.toRecord



-- SCALE GETTERS


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleStart : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart elementId animState =
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
getScaleEnd : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd elementId animState =
    InternalCSS.getScaleRange elementId animState
        |> Maybe.map (.end >> Scale.toRecord)



-- ROTATE GETTERS


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateStart : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart elementId animState =
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
getRotateEnd : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd elementId animState =
    InternalCSS.getRotateRange elementId animState
        |> Maybe.map (.end >> Rotate.toRecord)



-- OPACITY GETTERS


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityStart : String -> AnimState -> Maybe Float
getOpacityStart elementId animState =
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
getOpacityEnd : String -> AnimState -> Maybe Float
getOpacityEnd elementId animState =
    InternalCSS.getOpacityRange elementId animState
        |> Maybe.map (.end >> Opacity.toFloat)



-- SIZE GETTERS


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeStart : String -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart elementId animState =
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
getSizeEnd : String -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd elementId animState =
    InternalCSS.getSizeRange elementId animState
        |> Maybe.map (.end >> Size.toRecord)



-- BACKGROUND COLOR GETTERS


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorStart : String -> AnimState -> Maybe Color
getBackgroundColorStart elementId animState =
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
getBackgroundColorEnd : String -> AnimState -> Maybe Color
getBackgroundColorEnd elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.map .end
