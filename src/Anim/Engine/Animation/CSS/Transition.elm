module Anim.Engine.Animation.CSS.Transition exposing
    ( AnimState, AnimBuilder, AnimGroupName
    , init
    , attributes
    , animate
    , AnimMsg, update
    , CurrentTargetId, TargetId, AnimEvent(..)
    , events, eventsStopPropagation
    , stop, reset
    , delay
    , duration, speed
    , easing
    , discreteEntry, startingStyleNode, startingStyleNodeFor, discreteExit
    , anyRunning, isRunning, allComplete, isComplete, isCancelled
    , getBackgroundColorEnd
    , getOpacityEnd
    , getRotateEnd
    , getScaleEnd
    , getSizeEnd
    , getTranslateEnd
    )

{-| Run native CSS Transition animations.

For specific Engine guides and examples, see the
[Transition Engine Documentation](https://phollyer.github.io/elm-animate/engines/animation/transitions/).

For Engine comparisons, shared features, examples and code, see the
[Engine Overview](https://phollyer.github.io/elm-animate/engines/animation/overview/) section in the docs.


# Types

@docs AnimState, AnimBuilder, AnimGroupName


# Initialize

@docs init

📖 See [Initialize](https://phollyer.github.io/elm-animate/animation-workflow/init/) in the docs.


# Render

To render a CSS transition animation, you need to apply the animation attributes to your element.

@docs attributes

📖 See [Render](https://phollyer.github.io/elm-animate/animation-workflow/render/) in the docs.


# Trigger

@docs animate

📖 See [Triggering Animations](https://phollyer.github.io/elm-animate/animation-workflow/trigger/) in the docs.


# Update

@docs AnimMsg, update

📖 See [React](https://phollyer.github.io/elm-animate/animation-workflow/react/) in the docs.


# Events

@docs CurrentTargetId, TargetId, AnimEvent

📖 See [Event Reference](https://phollyer.github.io/elm-animate/animation-workflow/react/#event-reference) in the docs.


## Event Handlers

@docs events, eventsStopPropagation

📖 See [Event Reference](https://phollyer.github.io/elm-animate/animation-workflow/react/#event-reference) in the docs.


# Animation Control

@docs stop, reset

📖 See [Controlling Animations](https://phollyer.github.io/elm-animate/concepts/controlling-animations/) in the docs.


# Playback Settings

@docs delay

@docs duration, speed

@docs easing

See [Timing](https://phollyer.github.io/elm-animate/getting-started/timing/) and
[Easing](https://phollyer.github.io/elm-animate/getting-started/easing/) in the docs.

# Discrete Properties

@docs discreteEntry, startingStyleNode, startingStyleNodeFor, discreteExit

📖 See [Discrete Properties](https://phollyer.github.io/elm-animate/concepts/discrete-properties/) in the docs.


# State Queries

@docs anyRunning, isRunning, allComplete, isComplete, isCancelled

📖 See [State Queries](https://phollyer.github.io/elm-animate/engines/animation/transitions/#state-queries) in the docs.


# Property Queries

See [Property Queries](https://phollyer.github.io/elm-animate/engines/animation/transitions/#property-queries) and
[Properties](https://phollyer.github.io/elm-animate/getting-started/properties/) in the docs.


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
import Anim.Internal.Engine.Animation.CSS.Transition.AnimGroup as AnimGroup
import Html



{- **** MODEL **** -}


{-| The animation state type used to store animation configurations and transitions.

Store it in your model.

    type alias Model =
        { animState : Transition.AnimState }

-}
type alias AnimState =
    Transition.AnimState


{-| Animation builder type for configuring animations.
-}
type alias AnimBuilder =
    Builder.AnimBuilder


{-| A type alias for animation group names.

Used to identify which animation group to target in functions like
[attributes](#attributes), [isRunning](#isRunning), [stop](#stop), etc.

-}
type alias AnimGroupName =
    String



{- **** INITIALIZE **** -}


{-| Initialize animation state with optional property initializers.

    -- Empty state
    Transition.init []

    -- With initial properties
    Transition.init
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
            Transition.animate model.animState <|
                fadeIn
                    >> slideIn
    }

-}
animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate =
    Transition.animate



{- **** EVENTS **** -}


{-| The ID of the element where the handler is attached.

Returns `Nothing` if the element has no ID attribute.

-}
type alias CurrentTargetId =
    Maybe String


{-| The ID of the element that triggered the event.

Returns `Nothing` if the element has no ID attribute.

This may be different from `CurrentTargetId` if the event bubbled up from a child element.

-}
type alias TargetId =
    Maybe String


{-| CSS transition lifecycle events.
-}
type AnimEvent
    = Started CurrentTargetId TargetId AnimGroupName
    | Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Run CurrentTargetId TargetId AnimGroupName



{- **** UPDATE **** -}


{-| Internal message type.

    type Msg
        = TransitionMsg Transition.AnimMsg
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
                        Transition.update animMsg model.animState
                in
                handleAnimationEvent event { model | animState = newAnimState }

    handleAnimationEvent : Transition.AnimEvent -> Model -> ( Model, Cmd Msg )
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

    Transition.animate model.animState <|
        Transition.duration 500
            >> slideIn

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Builder.duration


{-| Set the global speed in property units per second.

Consult each property's documentation for details on how speed is interpreted.

    Transition.animate model.animState <|
        Transition.speed 100
            >> slideIn

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    Builder.speed


{-| Set the global easing function.

    import Anim.Extra.Easing exposing (Easing(..))

    Transition.animate model.animState <|
        Transition.easing BounceOut
            >> slideIn

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Builder.easing


{-| Set the global delay in milliseconds.

    Transition.animate model.animState <|
        Transition.delay 500
            >> slideIn

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Builder.delay


{-| Add a discrete CSS property for entry animations.

The value is applied as an inline style from the first frame and held throughout
the animation. Use this when an element is appearing (e.g., going from
`display: none` to `display: block`).

For entry animations, pair this with `startingStyleNode` so the browser knows
what values to transition from.

    Transition.animate model.animState <|
        Transition.discreteEntry "display" "block"
            >> Transition.discreteEntry "visibility" "visible"
            >> fadeIn

-}
discreteEntry : String -> String -> AnimBuilder -> AnimBuilder
discreteEntry =
    Builder.discreteEntry


{-| Add a discrete CSS property for exit animations.

Exit animations need to hold their initial state
until the very end of the animation, at which point they flip to the final state.

Therefore you need to set both the `from` and `to` values for the property.

Use when an element is disappearing (e.g., going from
`display: block` to `display: none`).

    Transition.animate model.animState <|
        Transition.discreteExit "display" "block" "none"
            >> fadeOut

-}
discreteExit : String -> String -> String -> AnimBuilder -> AnimBuilder
discreteExit =
    Builder.discreteExit



{- **** CONTROLS **** -}


{-| Stop a running animation by instantly jumping to its end state.

    Transition.stop "animGroup" model.animState

-}
stop : AnimGroupName -> AnimState -> AnimState
stop =
    Transition.stop


{-| Reset an animation by instantly jumping back to its start state.

    Transition.reset "animGroup" model.animState

-}
reset : AnimGroupName -> AnimState -> AnimState
reset =
    Transition.reset



{- **** VIEW **** -}


{-| Apply the animation attributes to your element.

    div
        (Transition.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes =
    Transition.attributes


{-| Generate a `<style>` node containing `@starting-style` rules for all animated elements.

When an element enters the DOM (or changes from `display: none`), the browser needs
to know what values to animate FROM. Without `@starting-style`, the browser skips
the transition.

    view model =
        div []
            [ Transition.startingStyleNode model.animState
            , div (Transition.attributes "fadeIn" model.animState)
                [ text "I fade in!" ]
            ]

-}
startingStyleNode : AnimState -> Html.Html msg
startingStyleNode =
    Transition.startingStyleNode


{-| Generate `@starting-style` rules for a specific animation group.

    view model =
        div []
            [ Transition.startingStyleNodeFor "fadeIn" model.animState
            , div (Transition.attributes "fadeIn" model.animState)
                [ text "I fade in!" ]
            ]

-}
startingStyleNodeFor : AnimGroupName -> AnimState -> Html.Html msg
startingStyleNodeFor =
    Transition.startingStyleNodeFor



{- **** EVENT LISTENERS **** -}


{-| Receive transition lifecycle events.

Add `events` to your element with a message constructor that wraps `AnimMsg`.

    type Msg
        = TransitionMsg Transition.AnimMsg

    div
        (Transition.attributes "animGroupName" animState
            ++ Transition.events "animGroupName" TransitionMsg
        )
        [ text "Animating element" ]

-}
events : (AnimMsg -> msg) -> List (Html.Attribute msg)
events =
    Transition.events


{-| The same as [events](#events) but with propagation stopped.

    div
        (Transition.attributes "animGroupName" model.animState
            ++ Transition.eventsStopPropagation "animGroupName" TransitionMsg
        )
        [ text "Animated element" ]

-}
eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation =
    Transition.eventsStopPropagation



{- **** STATE QUERIES **** -}


{-| Check if any animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : AnimState -> Maybe Bool
anyRunning =
    CSS.anyRunning AnimGroup.isRunning


{-| Check if a specific animation group is currently running.

Returns `Nothing` if there are no animations for the group.

-}
isRunning : AnimGroupName -> AnimState -> Maybe Bool
isRunning =
    CSS.isRunning AnimGroup.isRunning


{-| Check if a specific animation group has completed.

Returns `Nothing` if there are no animations for the group.

-}
isComplete : AnimGroupName -> AnimState -> Maybe Bool
isComplete =
    CSS.isComplete AnimGroup.isComplete


{-| Check if a specific animation group was cancelled.

Returns `Nothing` if there are no animations for the group.

-}
isCancelled : AnimGroupName -> AnimState -> Maybe Bool
isCancelled =
    CSS.isCancelled AnimGroup.isCancelled


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    CSS.allComplete AnimGroup.isComplete



{- **** PROPERTY QUERIES **** -}
--
--
-- BACKGROUND COLOR QUERIES


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorEnd : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorEnd =
    CSS.getBackgroundColorEnd



-- OPACITY QUERIES


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd =
    CSS.getOpacityEnd



-- ROTATE QUERIES


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    CSS.getRotateEnd



-- SCALE QUERIES


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    CSS.getScaleEnd



-- SIZE QUERIES


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd =
    CSS.getSizeEnd



-- TRANSLATE QUERIES


{-| Get the end translate value of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    CSS.getTranslateEnd
