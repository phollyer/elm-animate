module Scroll.Engine.Sub exposing
    ( ScrollState, ScrollBuilder, Container(..)
    , init
    , scroll
    , ScrollMsg, update
    , subscriptions
    , ScrollEvent(..)
    , delay, duration, speed
    , easing
    , stop
    , pause
    , resume
    , reset
    , restart
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

Use the [Builder](Scroll-Builder) module to configure scroll targets.


# Types

@docs ScrollState, ScrollBuilder, Container


# Initialize

@docs init


# Trigger

@docs scroll


# Update

@docs ScrollMsg, update

📖 See [React](https://phollyer.github.io/elm-animate/animation-workflow/react/) in the docs.


# Subscriptions

@docs subscriptions


# Events

@docs ScrollEvent


# Timing

@docs delay, duration, speed

📖 See [Timing](https://phollyer.github.io/elm-animate/getting-started/timing/) in the docs.


# Easing

@docs easing

📖 See [Easing](https://phollyer.github.io/elm-animate/getting-started/easing/) in the docs.


# Scroll Controls


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


# State Queries

@docs anyRunning, isRunning


# Querying Scroll Position

@docs getPosition, getPositionX, getPositionY

-}

import Browser exposing (UrlRequest(..))
import Easing exposing (Easing)
import Scroll.Internal.Engine.Sub as Internal
import Scroll.Internal.ScrollBuilder as SB



-- ============================================================
-- TYPES
-- ============================================================


{-| The internal state type used to store scroll state.

Store it in your model to track ongoing scrolls, query their state,
react to their progress, or control them mid-flight.

    import Scroll.Engine.Sub as Sub

    type alias Model =
        { scrollState : Sub.ScrollState }

-}
type alias ScrollState =
    Internal.ScrollState


{-| Scroll builder type for configuring scroll animations.
-}
type alias ScrollBuilder =
    SB.ScrollBuilder


{-| Identifies the scroll surface handled by the engine.

Use `Document` for the document body, or `Container "element-id"` for a
specific scrollable element.

-}
type Container
    = Document
    | Container String


{-| Internal message type.
-}
type alias ScrollMsg =
    Internal.ScrollMsg


{-| Scroll lifecycle events emitted by the scroll engine.

  - `Started` - A scroll animation began playing
  - `Ended` - A scroll animation completed naturally
  - `Stopped` - A scroll animation was stopped via [`stop`](#stop)
  - `Restarted` - A scroll animation was restarted via [`restart`](#restart)
  - `Paused` - A scroll animation was paused via [`pause`](#pause)
  - `Resumed` - A scroll animation was resumed via [`resume`](#resume)
  - `Progress` - A scroll animation frame with current position and progress (0.0 to 1.0)

The `Container` parameter identifies the scroll surface.

All events are collected and returned through the [`update`](#update) function.

-}
type ScrollEvent
    = Started Container
    | Ended Container
    | Stopped Container
    | Restarted Container
    | Paused Container
    | Resumed Container
    | Progress Container { x : Float, y : Float } Float



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Initialize empty scroll animation state.

    import Scroll.Engine.Sub as Sub

    init : Model
    init =
        { scrollState = Scroll.init }

-}
init : ScrollState
init =
    Internal.init



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Trigger a stateful scroll animation.

    import Scroll.Engine.Sub as Sub

    type Msg
        = ScrollMsg Sub.ScrollMsg
        | ...

    let
        ( newScrollState, scrollCmd ) =
            Sub.scroll ScrollMsg model.scrollState <|
                scrollToElement "target-section"
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
scroll : (ScrollMsg -> msg) -> ScrollState -> (ScrollBuilder -> ScrollBuilder) -> ( ScrollState, Cmd msg )
scroll =
    Internal.scroll



-- ============================================================
-- UPDATE
-- ============================================================


{-| Handle scroll animation lifecycle messages and events.

    import Scroll.Engine.Sub as Sub

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollMsg scrollMsg ->
                let
                    ( newScrollState, events, scrollCmd ) =
                        Sub.update ScrollMsg scrollMsg model.scrollState
                in
                handleEvents events <|
                    ( { model | scrollState = newScrollState }, scrollCmd )

-}
update : (ScrollMsg -> msg) -> ScrollMsg -> ScrollState -> ( ScrollState, List ScrollEvent, Cmd msg )
update =
    Internal.update fromInternalEvent


fromInternalEvent : Internal.ScrollEvent -> ScrollEvent
fromInternalEvent event =
    case event of
        Internal.Started cid ->
            Started (containerFromId cid)

        Internal.Ended cid ->
            Ended (containerFromId cid)

        Internal.Progress cid pos progress ->
            Progress (containerFromId cid) pos progress

        Internal.Stopped cid ->
            Stopped (containerFromId cid)

        Internal.Paused cid ->
            Paused (containerFromId cid)

        Internal.Resumed cid ->
            Resumed (containerFromId cid)

        Internal.Restarted cid ->
            Restarted (containerFromId cid)


containerFromId : String -> Container
containerFromId containerId =
    if containerId == "document" then
        Document

    else
        Container containerId


containerToId : Container -> String
containerToId container =
    case container of
        Document ->
            "document"

        Container containerId ->
            containerId



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


{-| Subscribe to receive scroll animation updates - without this your scrolls won't run.

    import Scroll.Engine.Sub as Sub

    type Msg
        = ScrollMsg Scroll.ScrollMsg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions ScrollMsg model.scrollState

-}
subscriptions : (ScrollMsg -> msg) -> ScrollState -> Sub msg
subscriptions =
    Internal.subscriptions



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay for all scrolls.

This will be inherited by all scrolls that
don't define their own delay.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Sub as Sub

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Sub.delay 100
            >> Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.speed 200
            >> Scroll.build

-}
delay : Int -> ScrollBuilder -> ScrollBuilder
delay =
    Internal.delay


{-| Set the duration of all scrolls.

This will be inherited by all scrolls that
don't define their own duration.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Sub as Sub

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Sub.duration 1000
            >> Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.build

-}
duration : Int -> ScrollBuilder -> ScrollBuilder
duration =
    Internal.duration


{-| Set the speed that scrolls should run at.

This will be inherited by all scrolls that
don't define their own speed.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Sub as Sub

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Sub.speed 200
            >> Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.build

-}
speed : Float -> ScrollBuilder -> ScrollBuilder
speed =
    Internal.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function to be used by all scrolls.

This will be inherited by all scrolls that
don't define their own easing.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Sub as Sub

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Sub.easing BounceOut
            >> Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.speed 200
            >> Scroll.build

-}
easing : Easing -> ScrollBuilder -> ScrollBuilder
easing =
    Internal.easing



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


{-| Stop a scroll animation by jumping to the target position.

Pass `Document` for the document body, or `Container "container-id"` for a
scrollable element.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.stop Document ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

    let
        ( newScrollState, scrollCmd ) =
            Scroll.stop (Container "my-container") ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
stop : Container -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )
stop container toMsg scrollState =
    Internal.stop (containerToId container) toMsg scrollState


{-| Pause a scroll animation.

Pass `Document` for the document body, or `Container "container-id"` for a
scrollable element.

    Scroll.pause Document model.scrollState

    Scroll.pause (Container "my-container") model.scrollState

-}
pause : Container -> ScrollState -> ScrollState
pause container =
    Internal.pause (containerToId container)


{-| Resume a scroll animation.

Pass `Document` for the document body, or `Container "container-id"` for a
scrollable element.

    Scroll.resume Document model.scrollState

    Scroll.resume (Container "my-container") model.scrollState

-}
resume : Container -> ScrollState -> ScrollState
resume container =
    Internal.resume (containerToId container)


{-| Reset a scroll animation to its starting position.

Pass `Document` for the document body, or `Container "container-id"` for a
scrollable element.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.reset Document ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

    let
        ( newScrollState, scrollCmd ) =
            Scroll.reset (Container "my-container") ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
reset : Container -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )
reset container toMsg scrollState =
    Internal.reset (containerToId container) toMsg scrollState


{-| Restart a scroll animation from its starting position.

Pass `Document` for the document body, or `Container "container-id"` for a
scrollable element.

    let
        ( newScrollState, scrollCmd ) =
            Scroll.restart Document ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

    let
        ( newScrollState, scrollCmd ) =
            Scroll.restart (Container "my-container") ScrollMsg model.scrollState
    in
    ( { model | scrollState = newScrollState }, scrollCmd )

-}
restart : Container -> (ScrollMsg -> msg) -> ScrollState -> ( ScrollState, Cmd msg )
restart container toMsg scrollState =
    Internal.restart (containerToId container) toMsg scrollState



-- ============================================================
-- STATE QUERIES
-- ============================================================


{-| Check if any scroll animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : ScrollState -> Maybe Bool
anyRunning =
    Internal.anyRunning


{-| Check if a scroll animation for a specific container is currently running.

Returns `Nothing` if there are no animations for the container.

-}
isRunning : Container -> ScrollState -> Maybe Bool
isRunning container =
    Internal.isRunning (containerToId container)



-- ============================================================
-- POSITION QUERIES
-- ============================================================


{-| Get the current scroll position for a specific container.

Returns X and Y coordinates as a record.

Returns `Nothing` if the container is not found or scroll position is unavailable.

-}
getPosition : Container -> ScrollState -> Maybe { x : Float, y : Float }
getPosition container =
    Internal.getScrollPosition (containerToId container)


{-| Get current horizontal scroll position for a specific container.
-}
getPositionX : Container -> ScrollState -> Maybe Float
getPositionX container =
    Internal.getScrollPositionX (containerToId container)


{-| Get current vertical scroll position for a specific container.
-}
getPositionY : Container -> ScrollState -> Maybe Float
getPositionY container =
    Internal.getScrollPositionY (containerToId container)
