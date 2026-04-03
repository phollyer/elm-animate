module Anim.Engine.CSS.Transition exposing
    ( AnimState, AnimBuilder, AnimGroup
    , init
    , attributes
    , allowDiscrete
    , startingStyleNode, startingStyleNodeFor
    , animate
    , AnimMsg, update
    , CurrentTargetId, TargetId, AnimEvent(..)
    , events, eventsStopPropagation
    , stop, reset
    , delay
    , duration, speed
    , easing
    , anyRunning, isRunning, allComplete, isComplete
    , getBackgroundColorEnd
    , getOpacityEnd
    , getRotateEnd
    , getScaleEnd
    , getSizeEnd
    , getTranslateEnd
    )

{-| CSS Transitions engine for smooth A→B animations.

For detailed guides, examples, and engine comparisons, see the
[full documentation](https://phollyer.github.io/elm-animate/engines/transitions/).


# Types

@docs AnimState, AnimBuilder, AnimGroup


# Initialize

@docs init


# Render

@docs attributes

## Discrete Properties

CSS transitions behave differently for discrete properties like `display` or `visibility`.
In order for the transitions to behave as expected, you need to enable discrete transitions,
and provide starting styles for elements entering the DOM or changing from `display: none`.

@docs allowDiscrete

@docs startingStyleNode, startingStyleNodeFor


# Trigger

@docs animate


# Update

@docs AnimMsg, update


# Anim Events

@docs CurrentTargetId, TargetId, AnimEvent


## Event Handlers

@docs events, eventsStopPropagation


# Animation Control

@docs stop, reset


# Playback Settings

@docs delay

@docs duration, speed

@docs easing


# Querying Animation State

@docs anyRunning, isRunning, allComplete, isComplete


# Querying Animated Properties


## Background Color

@docs getBackgroundColorEnd


## Opacity

@docs getOpacityEnd


## Rotate

@docs getRotateEnd


## Scale

@docs getScaleEnd


## Size

@docs getSizeEnd


## Translate

@docs getTranslateEnd

-}

import Anim.Extra.Color exposing (Color)
import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Animation.CSS.CSS as CSS
import Anim.Internal.Engine.Animation.CSS.Transition as Transition
import Html



{- **** MODEL **** -}


{-| The animation state type used to store animation configurations and transitions.

Store it in your model.

    type alias Model =
        { animState : Transitions.AnimState }

-}
type alias AnimState =
    Transition.AnimState


{-| Animation builder type for configuring animations.
-}
type alias AnimBuilder =
    CSS.AnimBuilder


{-| A type alias for animation group names.

Used to identify which animation group to target in functions like
[attributes](#attributes), [isRunning](#isRunning), [stop](#stop), etc.

-}
type alias AnimGroup =
    String



{- **** INITIALIZE **** -}


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
    Transition.init



{- **** TRIGGER **** -}


{-| Trigger animations.

    { model
        | animState =
            Transitions.animate model.animState <|
                fadeIn
                    >> slideIn
    }

-}
animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate =
    Transition.animate



{- **** EVENTS **** -}


{-| The ID of the element where the handler is attached.

If the element has no ID attribute, this will be an empty string.

-}
type alias CurrentTargetId =
    String


{-| The ID of the element that triggered the event.

If the element has no ID attribute, this will be an empty string.

This may be different from `CurrentTargetId` if the event bubbled up from a child element.

-}
type alias TargetId =
    String


{-| CSS transition lifecycle events.
-}
type AnimEvent
    = Started CurrentTargetId TargetId AnimGroup
    | Ended CurrentTargetId TargetId AnimGroup
    | Cancelled CurrentTargetId TargetId AnimGroup
    | Run CurrentTargetId TargetId AnimGroup



{- **** UPDATE **** -}


{-| Opaque message type.

    type Msg
        = TransitionMsg Transitions.AnimMsg
        | ...

-}
type alias AnimMsg =
    Transition.AnimMsg


{-| Handle animation lifecycle messages.

Returns the updated state and an [AnimEvent](#AnimEvent) for you to pattern match on.

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
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
            ...

-}
update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update msg =
    Transition.update msg
        >> Tuple.mapSecond mapEvent


mapEvent : Transition.AnimEvent -> AnimEvent
mapEvent event =
    case event of
        Transition.Started currentTargetId targetId animGroup ->
            Started currentTargetId targetId animGroup

        Transition.Ended currentTargetId targetId animGroup ->
            Ended currentTargetId targetId animGroup

        Transition.Cancelled currentTargetId targetId animGroup ->
            Cancelled currentTargetId targetId animGroup

        Transition.Run currentTargetId targetId animGroup ->
            Run currentTargetId targetId animGroup



{- **** PLAYBACK SETTINGS **** -}


{-| Set the global duration in milliseconds.

    Transitions.animate model.animState <|
        Transitions.duration 500
            >> slideIn

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    CSS.duration


{-| Set the global speed in property units per second.

Consult each property's documentation for details on how speed is interpreted.

    Transitions.animate model.animState <|
        Transitions.speed 100
            >> slideIn

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    CSS.speed


{-| Set the global easing function.

    import Anim.Extra.Easing exposing (Easing(..))

    Transitions.animate model.animState <|
        Transitions.easing BounceOut
            >> slideIn

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    CSS.easing


{-| Set the global delay in milliseconds.

    Transitions.animate model.animState <|
        Transitions.delay 500
            >> slideIn

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    CSS.delay


{-| Enable transitions for discrete CSS properties like `visibility` or `display`.

This is required for all transitions that involve changes to discrete properties.

    Transitions.animate model.animState <|
        Transitions.allowDiscrete
            >> fadeIn
            >> slideIn

-}
allowDiscrete : AnimBuilder -> AnimBuilder
allowDiscrete =
    Builder.allowDiscreteTransitions



{- **** CONTROLS **** -}


{-| Stop a running animation by instantly jumping to its end state.

    Transitions.stop "animGroup" model.animState

-}
stop : AnimGroup -> AnimState -> AnimState
stop =
    Transition.stop


{-| Reset an animation by instantly jumping back to its start state.

    Transitions.reset "animGroup" model.animState

-}
reset : AnimGroup -> AnimState -> AnimState
reset =
    Transition.reset



{- **** VIEW **** -}


{-| Apply the transition attributes to your element.

    div
        (Transitions.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroup -> AnimState -> List (Html.Attribute msg)
attributes =
    Transition.attributes


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
    Transition.startingStyleNode


{-| Generate `@starting-style` rules for a specific animation group.

    view model =
        div []
            [ Transitions.startingStyleNodeFor "fadeIn" model.animState
            , div (Transitions.attributes "fadeIn" model.animState)
                [ text "I fade in!" ]
            ]

-}
startingStyleNodeFor : AnimGroup -> AnimState -> Html.Html msg
startingStyleNodeFor =
    Transition.startingStyleNodeFor



{- **** EVENT LISTENERS **** -}


{-| Receive transition lifecycle events.

Add `events` to your element with the animation group name and a message constructor
that wraps `AnimMsg`.

    type Msg
        = TransitionMsg Transitions.AnimMsg

    div
        (Transitions.attributes "animGroupName" animState
            ++ Transitions.events "animGroupName" TransitionMsg
        )
        [ text "Animating element" ]

-}
events : AnimGroup -> (AnimMsg -> msg) -> List (Html.Attribute msg)
events =
    Transition.events


{-| The same as [events](#events) but with propagation stopped.

    div
        (Transitions.attributes "animGroupName" model.animState
            ++ Transitions.eventsStopPropagation "animGroupName" TransitionMsg
        )
        [ text "Animated element" ]

-}
eventsStopPropagation : AnimGroup -> (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation =
    Transition.eventsStopPropagation



{- **** STATE QUERIES **** -}


{-| Check if any animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : AnimState -> Maybe Bool
anyRunning =
    CSS.anyRunning


{-| Check if a specific animation group is currently running.

Returns `Nothing` if there are no animations for the group.

-}
isRunning : AnimGroup -> AnimState -> Maybe Bool
isRunning =
    CSS.isRunning


{-| Check if a specific animation group has completed.

Returns `Nothing` if there are no animations for the group.

-}
isComplete : AnimGroup -> AnimState -> Maybe Bool
isComplete =
    CSS.isComplete


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    CSS.allComplete



{- **** PROPERTY QUERIES **** -}
--
--
-- BACKGROUND COLOR QUERIES


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorEnd : AnimGroup -> AnimState -> Maybe Color
getBackgroundColorEnd =
    CSS.getBackgroundColorEnd



-- OPACITY QUERIES


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroup -> AnimState -> Maybe Float
getOpacityEnd =
    CSS.getOpacityEnd



-- ROTATE QUERIES


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroup -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    CSS.getRotateEnd



-- SCALE QUERIES


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroup -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    CSS.getScaleEnd



-- SIZE QUERIES


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroup -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd =
    CSS.getSizeEnd



-- TRANSLATE QUERIES


{-| Get the end translate value of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroup -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    CSS.getTranslateEnd
