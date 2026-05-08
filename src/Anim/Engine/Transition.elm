module Anim.Engine.Transition exposing
    ( AnimState, AnimGroupName
    , AnimBuilder
    , TimelineBuilder
    , EngineBuilder
    , init
    , animate
    , CurrentTargetId, TargetId, AnimEvent(..)
    , AnimMsg, update
    , attributes
    , events, eventsStopPropagation
    , delay, duration, speed
    , easing
    , stop, reset
    , discreteEntry, startingStyleNode, startingStyleNodeFor, discreteExit
    , anyRunning, isRunning, allComplete, isComplete, isCancelled
    , getPropertyEnd
    , getColorPropertyEnd
    , getOpacityEnd
    , getRotateEnd
    , getScaleEnd
    , getSizeEnd
    , getSkewEnd
    , getTranslateEnd
    )

{-| Run native CSS Transition animations.

For specific Engine guides and examples, see the
[Transition Engine Documentation](https://phollyer.github.io/elm-animate/engines/animation/transitions/).

For Engine comparisons, shared features, examples and code, see the
[Engine Overview](https://phollyer.github.io/elm-animate/engines/animation/overview/) section in the docs.


# Types

@docs AnimState, AnimGroupName


## Builders

@docs AnimBuilder


### Timeline Builder

This Engine uses the browser's Document timeline, along with the Keyframe, Sub, and WAAPI Engines.

Use the `TimelineBuilder` to configure animations that run on the Document timeline only. If any Engines
are used that don't run on the Document timeline (e.g., Scroll or View), you'll get a type error.

@docs TimelineBuilder


### Engine Builder

The `EngineBuilder` is a builder type restricted to the Transition Engine.

Use the `EngineBuilder` when you want to restrict helpers to the Transition Engine.

@docs EngineBuilder


# Initialize

@docs init

📖 See [Initialize](https://phollyer.github.io/elm-animate/animation-workflow/init/) in the docs.


# Trigger

@docs animate

📖 See [Triggering Animations](https://phollyer.github.io/elm-animate/animation-workflow/trigger/) in the docs.


# Events

@docs CurrentTargetId, TargetId, AnimEvent

📖 See [Event Reference](https://phollyer.github.io/elm-animate/animation-workflow/react/#event-reference) in the docs.


# Update

@docs AnimMsg, update

📖 See [React](https://phollyer.github.io/elm-animate/animation-workflow/react/) in the docs.


# View

To render a CSS transition animation, you need to apply the animation `attributes` to your element.

@docs attributes

📖 See [Render](https://phollyer.github.io/elm-animate/animation-workflow/render/) in the docs.


# Event Listeners

@docs events, eventsStopPropagation

📖 See [Event Reference](https://phollyer.github.io/elm-animate/animation-workflow/react/#event-reference) in the docs.


# Timing

@docs delay, duration, speed

📖 See [Timing](https://phollyer.github.io/elm-animate/getting-started/timing/) in the docs.


# Easing

@docs easing

📖 See [Easing](https://phollyer.github.io/elm-animate/getting-started/easing/) in the docs.


# Animation Control

@docs stop, reset

📖 See [Controlling Animations](https://phollyer.github.io/elm-animate/concepts/controlling-animations/) in the docs.

# Discrete Properties

@docs discreteEntry, startingStyleNode, startingStyleNodeFor, discreteExit

📖 See [Discrete Properties](https://phollyer.github.io/elm-animate/concepts/discrete-properties/) in the docs.


# State Queries

@docs anyRunning, isRunning, allComplete, isComplete, isCancelled

📖 See [State Queries](https://phollyer.github.io/elm-animate/engines/animation/transitions/#state-queries) in the docs.


# Property Queries

📖 See [Property Queries](https://phollyer.github.io/elm-animate/engines/animation/transitions/#property-queries) and
[Properties](https://phollyer.github.io/elm-animate/getting-started/properties/) in the docs.


## Custom Properties

@docs getPropertyEnd


## Custom Color Properties

@docs getColorPropertyEnd


## Opacity

@docs getOpacityEnd


## Rotate

@docs getRotateEnd


## Scale

@docs getScaleEnd


## Size

@docs getSizeEnd


## Skew

@docs getSkewEnd


## Translate

@docs getTranslateEnd

-}

import Anim.Extra.Color exposing (Color)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.CSS as CSS
import Anim.Internal.Engine.Transition as Internal
import Anim.Internal.Engine.Transition.AnimGroup as AnimGroup
import Easing exposing (Easing)
import Html



-- ============================================================
-- TYPES
-- ============================================================


{-| The animation state type used to store animation configurations and transitions.

Store it in your model.

    type alias Model =
        { animState : Transition.AnimState }

-}
type alias AnimState =
    Internal.AnimState


{-| Type alias for the base [AnimBuilder](Anim.Builder#AnimBuilder) type.
-}
type alias AnimBuilder mode =
    Internal.AnimBuilder mode


{-| A type alias for animation group names.

Used to identify which animation group to target.

-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `TimelineBuilder` type.

This generic timeline builder works with any engine that uses the same timeline,
but will result in a type error if used with an Engine that does not.

    f : Transition.TimelineBuilder engine -> Transition.TimelineBuilder engine

Here's an engine-specific timeline builder for the Transition Engine. It will result in a type error if used with any other engine.

    f : Transition.TimelineBuilder ForTransitionEngine -> Transition.TimelineBuilder ForTransitionEngine

For mode restrictions and examples, see
[Build: Builder Modes](https://phollyer.github.io/elm-animate/animation/workflow/build/#builder-modes).

-}
type alias TimelineBuilder engine =
    Internal.TimelineBuilder engine


{-| Type alias for the internal `EngineBuilder` type.

This engine-specific builder will result in a type error if used with any other engine.

    f : Transition.EngineBuilder -> Transition.EngineBuilder

For mode restrictions and examples, see
[Build: Builder Modes](https://phollyer.github.io/elm-animate/animation/workflow/build/#builder-modes).

-}
type alias EngineBuilder =
    Internal.EngineBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Initialize animation state with optional property initializers.

    import Anim.Engine.Transition as Transition
    import Anim.Property.Opacity as Opacity
    import Anim.Property.Translate as Translate

    -- Empty state
    Transition.init []

    -- With initial properties
    Transition.init
        [ Translate.initXY "animGroupName" 100 50
        , Opacity.init "animGroupName" 0.5
        ]

-}
init : List (EngineBuilder -> EngineBuilder) -> AnimState
init =
    Internal.init



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Trigger animations.

    import Anim.Engine.Transition as Transition
    import Anim.Property.Opacity as Opacity
    import Anim.Property.Translate as Translate

    { model
        | animState =
            Transition.animate model.animState <|
                Opacity.for "box"
                    >> Opacity.to 1
                    >> Opacity.build
                    >> Translate.for "box"
                    >> Translate.toX 0
                    >> Translate.build
    }

-}
animate : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
animate =
    Internal.animate



-- ============================================================
-- EVENTS
-- ============================================================


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



-- ============================================================
-- UPDATE
-- ============================================================


{-| Internal message type.

    import Anim.Engine.Transition as Transition

    type Msg
        = TransitionMsg Transition.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Handle animation lifecycle messages.

Returns the updated state and an [AnimEvent](#AnimEvent) for you to pattern match on.

    import Anim.Engine.Transition as Transition

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            TransitionMsg animMsg ->
                let
                    ( animState, event ) =
                        Transition.update animMsg model.animState
                in
                handleAnimationEvent event { model | animState = animState }

    handleAnimationEvent : Transition.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            ...

-}
update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update msg =
    Internal.update msg
        >> Tuple.mapSecond toAnimEvent


toAnimEvent : Internal.AnimEvent -> AnimEvent
toAnimEvent event =
    case event of
        Internal.Started currentTargetId targetId animGroup ->
            Started currentTargetId targetId animGroup

        Internal.Ended currentTargetId targetId animGroup ->
            Ended currentTargetId targetId animGroup

        Internal.Cancelled currentTargetId targetId animGroup ->
            Cancelled currentTargetId targetId animGroup

        Internal.Run currentTargetId targetId animGroup ->
            Run currentTargetId targetId animGroup



-- ============================================================
-- VIEW
-- ============================================================


{-| Apply the animation `attributes` to your element.

    import Anim.Engine.Transition as Transition
    import Html exposing (div, text)

    div
        (Transition.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes =
    Internal.attributes


{-| Generate a `<style>` node containing `@starting-style` rules for all animated elements.

When an element enters the DOM (or changes from `display: none`), the browser needs
to know what values to animate FROM. Without `@starting-style`, the browser skips
the transition.

    import Anim.Engine.Transition as Transition
    import Html exposing (div, text)

    view model =
        div []
            [ Transition.startingStyleNode model.animState
            , div (Transition.attributes "fadeIn" model.animState)
                [ text "I fade in!" ]
            ]

-}
startingStyleNode : AnimState -> Html.Html msg
startingStyleNode =
    Internal.startingStyleNode


{-| Generate `@starting-style` rules for a specific animation group.

    import Anim.Engine.Transition as Transition
    import Html exposing (div, text)

    view model =
        div []
            [ Transition.startingStyleNodeFor "fadeIn" model.animState
            , div (Transition.attributes "fadeIn" model.animState)
                [ text "I fade in!" ]
            ]

-}
startingStyleNodeFor : AnimGroupName -> AnimState -> Html.Html msg
startingStyleNodeFor =
    Internal.startingStyleNodeFor



-- ============================================================
-- EVENT LISTENERS
-- ============================================================


{-| Receive transition lifecycle events.

Add `events` to your element with a message constructor that wraps `AnimMsg`.

    import Anim.Engine.Transition as Transition
    import Html exposing (div, text)

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
    Internal.events


{-| The same as [events](#events) but with propagation stopped.

    import Anim.Engine.Transition as Transition
    import Html exposing (div, text)

    div
        (Transition.attributes "animGroupName" model.animState
            ++ Transition.eventsStopPropagation "animGroupName" TransitionMsg
        )
        [ text "Animated element" ]

-}
eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation =
    Internal.eventsStopPropagation



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay for all animations.

This will be inherited by all animations that
don't define their own delay.

    import Anim.Engine.Transition as Transition
    import Anim.Property.Custom as Custom

    Transition.animate model.animState <|
        Transition.delay 500
            >> Custom.for "box" (Custom.BorderRadius "px")
            >> Custom.to 24
            >> Custom.build

-}
delay : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
delay =
    CSS.delay


{-| Set the duration of all animations.

This will be inherited by all animations that
don't define their own duration.

    import Anim.Engine.Transition as Transition
    import Anim.Property.Custom as Custom

    Transition.animate model.animState <|
        Transition.duration 500
            >> Custom.for "box" (Custom.BorderRadius "px")
            >> Custom.to 24
            >> Custom.build

-}
duration : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
duration =
    CSS.duration


{-| Set the speed that animations should run at.

This will be inherited by all animations that
don't define their own speed.

Consult each property's documentation for details on how speed is interpreted.

    import Anim.Engine.Transition as Transition
    import Anim.Property.Custom as Custom

    Transition.animate model.animState <|
        Transition.speed 100
            >> Custom.for "box" (Custom.BorderRadius "px")
            >> Custom.to 24
            >> Custom.build

-}
speed : Float -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
speed =
    CSS.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function to be used by all animations.

This will be inherited by all animations that
don't define their own easing.

    import Easing exposing (Easing(..))
    import Anim.Engine.Transition as Transition
    import Anim.Property.Custom as Custom

    Transition.animate model.animState <|
        Transition.easing BounceOut
            >> Custom.for "box" (Custom.BorderRadius "px")
            >> Custom.to 24
            >> Custom.build

-}
easing : Easing -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
easing =
    CSS.easing



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


{-| Stop a running animation by instantly jumping to its end state.

    import Anim.Engine.Transition as Transition

    Transition.stop "animGroup" model.animState

-}
stop : AnimGroupName -> AnimState -> AnimState
stop =
    Internal.stop


{-| Reset an animation by instantly jumping back to its start state.

    import Anim.Engine.Transition as Transition

    Transition.reset "animGroup" model.animState

-}
reset : AnimGroupName -> AnimState -> AnimState
reset =
    Internal.reset



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


{-| Add a discrete CSS property for entry animations.

The value is applied as an inline style from the first frame and held throughout
the animation. Use this when an element is appearing (e.g., going from
`display: none` to `display: block`).

For entry animations, pair this with `startingStyleNode` so the browser knows
what values to transition from.

    import Anim.Engine.Transition as Transition
    import Anim.Property.Opacity as Opacity

    Transition.animate model.animState <|
        Transition.discreteEntry "display" "block"
            >> Opacity.for "box"
            >> Opacity.to 1
            >> Opacity.build

-}
discreteEntry : String -> String -> EngineBuilder -> EngineBuilder
discreteEntry =
    CSS.discreteEntry


{-| Add a discrete CSS property for exit animations.

Exit animations need to hold their initial state
until the very end of the animation, at which point they flip to the final state.

Therefore you need to set both the `from` and `to` values for the property.

Use when an element is disappearing (e.g., going from
`display: block` to `display: none`).

    import Anim.Engine.Transition as Transition
    import Anim.Property.Opacity as Opacity

    Transition.animate model.animState <|
        Transition.discreteExit "display" "block" "none"
            >> Opacity.for "box"
            >> Opacity.to 0
            >> Opacity.build

-}
discreteExit : String -> String -> String -> EngineBuilder -> EngineBuilder
discreteExit =
    CSS.discreteExit



-- ============================================================
-- STATE QUERIES
-- ============================================================


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



-- ============================================================
-- PROPERTY QUERIES
-- ============================================================
--
--
-- ============================
-- CUSTOM PROPERTY
-- ============================


{-| Get the end value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyEnd =
    CSS.getPropertyEnd



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


{-| Get the end value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyEnd =
    CSS.getColorPropertyEnd



-- ============================
-- OPACITY
-- ============================


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd =
    CSS.getOpacityEnd



-- ============================
-- ROTATE
-- ============================


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    CSS.getRotateEnd



-- ============================
-- SCALE
-- ============================


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    CSS.getScaleEnd



-- ============================
-- SIZE
-- ============================


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd =
    CSS.getSizeEnd



-- ============================
-- SKEW
-- ============================


{-| Get the end skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewEnd =
    CSS.getSkewEnd



-- ============================
-- TRANSLATE
-- ============================


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    CSS.getTranslateEnd
