module Scroll.Engine.Sub exposing
    ( AnimState, ScrollBuilder
    , init
    , animate
    , AnimMsg, update
    , subscriptions
    , AnimEvent(..)
    , stop
    , pause
    , resume
    , reset
    , restart
    , delay, duration, speed
    , easing
    , anyRunning, isRunning
    , getPosition, getPositionX, getPositionY
    )

{-| Stateful subscription-based scroll animations.

Use this module when you need to track ongoing scrolls, query their state,
react to their progress, or control them mid-flight (pause, resume, stop, etc.).

For specific Engine guides and examples, see the
[Scroll Sub Engine Documentation](https://phollyer.github.io/elm-animate/engines/scroll/sub/).

For Engine comparisons, shared features, examples and code, see the
[Scroll Overview](https://phollyer.github.io/elm-animate/engines/scroll/overview/) section in the docs.

Use the [Builder](Anim-Engine-Scroll-Builder) module to configure scroll targets.


# Types

@docs AnimState, ScrollBuilder


# Initialize

@docs init


# Trigger

@docs animate


# Update

@docs AnimMsg, update

📖 See [React](https://phollyer.github.io/elm-animate/animation-workflow/react/) in the docs.


# Subscriptions

@docs subscriptions


# Events

@docs AnimEvent


# Animation Control


## Stop

@docs stop


## Pause

@docs pause


## Resume

@docs resume


## Reset

@docs reset


## Restart

@docs restart

📖 See [Controlling Scroll](https://phollyer.github.io/elm-animate/concepts/controlling-scroll/) in the docs.


# Playback Settings


## Timing

@docs delay, duration, speed

📖 See [Timing](https://phollyer.github.io/elm-animate/getting-started/timing/) in the docs.


## Easing

@docs easing

📖 See [Easing](https://phollyer.github.io/elm-animate/getting-started/easing/) in the docs.


# State Queries

@docs anyRunning, isRunning


# Querying Scroll Position

@docs getPosition, getPositionX, getPositionY

-}

import Easing exposing (Easing)
import Scroll.Internal.Engine.Sub as Internal
import Scroll.Internal.ScrollBuilder as SB



-- ============================================================
-- TYPES
-- ============================================================


{-| Animation builder type for configuring scroll animations.
-}
type alias ScrollBuilder =
    SB.ScrollBuilder


{-| The animation state type used to store scroll animation state.

Store it in your model to track ongoing scrolls, query their state,
react to their progress, or control them mid-flight.

    type alias Model =
        { scrollState : Scroll.AnimState }

-}
type alias AnimState =
    Internal.AnimState


{-| Internal message type.
-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Animation lifecycle events emitted by the scroll engine.

  - `Started` - A scroll animation began playing
  - `Ended` - A scroll animation completed naturally
  - `Stopped` - A scroll animation was stopped via [`stop`](#stop)
  - `Restarted` - A scroll animation was restarted via [`restart`](#restart)
  - `Paused` - A scroll animation was paused via [`pause`](#pause)
  - `Resumed` - A scroll animation was resumed via [`resume`](#resume)
  - `Progress` - A scroll animation frame with current position and progress (0.0 to 1.0)

The `String` parameter identifies the container (`"document"` for document body, or the element ID).

All events are collected and returned through the [`update`](#update) function.

-}
type AnimEvent
    = Started String
    | Ended String
    | Stopped String
    | Restarted String
    | Paused String
    | Resumed String
    | Progress String { x : Float, y : Float } Float



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Initialize empty scroll animation state.

    init : Model
    init =
        { scrollState = Scroll.init }

-}
init : AnimState
init =
    Internal.init



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Trigger a stateful scroll animation.

    type Msg
        = ScrollMsg Scroll.AnimMsg
        | ...

    let
        ( newScrollState, scrollCmd ) =
            Scroll.animate ScrollMsg model.scrollState <|
                scrollToElement "target-section"
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
animate : (AnimMsg -> msg) -> AnimState -> (ScrollBuilder -> ScrollBuilder) -> ( AnimState, Cmd msg )
animate =
    Internal.animate



-- ============================================================
-- UPDATE
-- ============================================================


{-| Handle scroll animation lifecycle messages and events.

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollMsg scrollMsg ->
                let
                    ( newScrollState, events, scrollCmd ) =
                        Scroll.update ScrollMsg scrollMsg model.scrollState
                in
                handleEvents events <|
                    ( { model | scrollState = newScrollState }, scrollCmd )

-}
update : (AnimMsg -> msg) -> AnimMsg -> AnimState -> ( AnimState, List AnimEvent, Cmd msg )
update toMsg msg animState =
    let
        ( newState, internalEvents, cmd ) =
            Internal.update toMsg msg animState
    in
    ( newState, List.map toAnimEvent internalEvents, cmd )


toAnimEvent : Internal.AnimEvent -> AnimEvent
toAnimEvent event =
    case event of
        Internal.Started cid ->
            Started cid

        Internal.Ended cid ->
            Ended cid

        Internal.Progress cid pos progress ->
            Progress cid pos progress

        Internal.Stopped cid ->
            Stopped cid

        Internal.Paused cid ->
            Paused cid

        Internal.Resumed cid ->
            Resumed cid

        Internal.Restarted cid ->
            Restarted cid



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


{-| Subscribe to receive scroll animation updates - without this your scrolls won't run.

    type Msg
        = ScrollMsg Scroll.AnimMsg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Scroll.subscriptions ScrollMsg model.scrollState

-}
subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions =
    Internal.subscriptions



-- ============================================================
-- PLAYBACK SETTINGS
-- ============================================================


{-| Set the global default duration in milliseconds.

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Scroll.duration 1000
            >> Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.build

-}
duration : Int -> ScrollBuilder -> ScrollBuilder
duration =
    Internal.duration


{-| Set the global default speed in pixels per second.

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Scroll.speed 200
            >> Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.build

-}
speed : Float -> ScrollBuilder -> ScrollBuilder
speed =
    Internal.speed


{-| Set the global default easing function.

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Scroll.easing BounceOut
            >> Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.speed 200
            >> Builder.build

-}
easing : Easing -> ScrollBuilder -> ScrollBuilder
easing =
    Internal.easing


{-| Set the global default delay in milliseconds.

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Scroll.delay 100
            >> Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.speed 200
            >> Builder.build

-}
delay : Int -> ScrollBuilder -> ScrollBuilder
delay =
    Internal.delay



-- ============================================================
-- STATE QUERIES
-- ============================================================


{-| Check if any scroll animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : AnimState -> Maybe Bool
anyRunning =
    Internal.anyRunning


{-| Check if a scroll animation for a specific container is currently running.

Use `"document"` for document body.

Returns `Nothing` if there are no animations for the container.

-}
isRunning : String -> AnimState -> Maybe Bool
isRunning =
    Internal.isRunning



-- ============================================================
-- POSITION QUERIES
-- ============================================================


{-| Get the current scroll position for a specific container.

Returns X and Y coordinates as a record.

Returns `Nothing` if the container is not found or scroll position is unavailable.

-}
getPosition : String -> AnimState -> Maybe { x : Float, y : Float }
getPosition =
    Internal.getScrollPosition


{-| Get current horizontal scroll position for a specific container.
-}
getPositionX : String -> AnimState -> Maybe Float
getPositionX =
    Internal.getScrollPositionX


{-| Get current vertical scroll position for a specific container.
-}
getPositionY : String -> AnimState -> Maybe Float
getPositionY =
    Internal.getScrollPositionY



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


{-| Stop a scroll animation by jumping to the target position.

Pass `"document"` for the document body, or a container element ID.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.stop "document" ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

    let
        ( newScrollState, scrollCmd ) =
            Scroll.stop "my-container" ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
stop : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
stop =
    Internal.stop


{-| Pause a scroll animation.

Pass `"document"` for the document body, or a container element ID.

    Scroll.pause "document" model.scrollState

    Scroll.pause "my-container" model.scrollState

-}
pause : String -> AnimState -> AnimState
pause =
    Internal.pause


{-| Resume a scroll animation.

Pass `"document"` for the document body, or a container element ID.

    Scroll.resume "document" model.scrollState

    Scroll.resume "my-container" model.scrollState

-}
resume : String -> AnimState -> AnimState
resume =
    Internal.resume


{-| Reset a scroll animation to its starting position.

Pass `"document"` for the document body, or a container element ID.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.reset "document" ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

    let
        ( newScrollState, scrollCmd ) =
            Scroll.reset "my-container" ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
reset : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
reset =
    Internal.reset


{-| Restart a scroll animation from its starting position.

Pass `"document"` for the document body, or a container element ID.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.restart "document" ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

    let
        ( newScrollState, scrollCmd ) =
            Scroll.restart "my-container" ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
restart : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart =
    Internal.restart
