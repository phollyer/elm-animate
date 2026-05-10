module Scroll.Engine.Task exposing
    ( ScrollBuilder, Container(..)
    , ScrollError(..), ScrollOk
    , scroll, scrollEach
    , delay, duration, speed
    , easing
    )

{-| Composable scroll animations via Task with error handling.

Use this module when you need to handle scroll success or failure,
or compose scroll operations with other Tasks.

For specific Engine guides and examples, see the
[Scroll Task Engine Documentation](https://phollyer.github.io/elm-motion/engines/scroll/task/).

For Engine comparisons, shared features, examples and code, see the
[Scroll Overview](https://phollyer.github.io/elm-motion/engines/scroll/overview/) section in the docs.

Use the [Builder](Scroll-Builder) module to configure scroll targets.


# Types

@docs ScrollBuilder, Container


# Trigger

@docs ScrollError, ScrollOk

@docs scroll, scrollEach


# Timing

@docs delay, duration, speed

📖 See [Timing](https://phollyer.github.io/elm-motion/animation/concepts/timing/) in the docs.


# Easing

@docs easing

📖 See [Easing](https://phollyer.github.io/elm-motion/animation/concepts/easing/) in the docs.

-}

import Browser.Dom as Dom
import Motion.Easing as Easing exposing (Easing(..))
import Scroll.Internal.Engine.Task as Internal
import Scroll.Internal.ScrollBuilder as SB
import Task exposing (Task)



-- ============================================================
-- TYPES
-- ============================================================


{-| Animation builder type for configuring scroll animations.
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


{-| Error type for failed scroll [Task](http://package.elm-lang.org/packages/elm/core/latest/Task)s.

Provides details about what failed during a scroll operation:

  - `container`: The container that was being scrolled
  - `targetElementId`: The element ID if scrolling to an element target
  - `domError`: The underlying [Dom.Error](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Dom#Error) that caused the scroll to fail

-}
type ScrollError
    = ScrollError
        { container : Container
        , targetElementId : Maybe String
        , domError : Dom.Error
        }


{-| Value type for successful scroll [Task](http://package.elm-lang.org/packages/elm/core/latest/Task)s.

Provides details about the completed scroll operation:

  - `container`: The container that was scrolled
  - `targetElementId`: The element ID if scrolled to an element target

-}
type alias ScrollOk =
    { container : Container
    , targetElementId : Maybe String
    }



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Execute scroll animations as a [Task](https://package.elm-lang.org/packages/elm/core/latest/Task).

Returns a `List ScrollOk` because a single builder can chain multiple scroll targets.
Each target produces one `ScrollOk` on success. If any target fails, the task fails
immediately with `ScrollError` and remaining scrolls are abandoned. Use
[`scrollEach`](#scrollEach) if you need all scrolls to run regardless of failures.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Task as Task
    import Task

    type Msg
        = HandleScrollResult (Result ScrollError (List ScrollOk))
        | ...

    Task.scroll (scrollToElement "target-section")
         |> Task.attempt HandleScrollResult

**Note:** Because each call to `scroll` pre-calculates its frame steps from the
current DOM state at the moment it runs, triggering the same scroll sequence
multiple times in quick succession can lead to unexpected results.

For example, subsequent scrolls do not cancel or replace the old one, so overlapping
scrolls on the same container will compete with each other. If you need to interrupt or
retrigger scrolls safely, use
[Scroll.Engine.Sub](Scroll-Engine-Sub) instead.

-}
scroll : (ScrollBuilder -> ScrollBuilder) -> Task ScrollError (List ScrollOk)
scroll =
    Internal.scroll
        >> Task.mapError toPublicError
        >> Task.map (List.map toPublicOk)


{-| Execute each scroll target in sequence and collect per-target results.

Unlike [`scroll`](#scroll), this function continues after failures and always
returns all results in pipeline order — one `Result` per scroll target.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Task as Task
    import Task

    type Msg
        = HandleScrollResults (List (Result ScrollError ScrollOk))
        | ...

    Task.scrollEach (scrollSequence "chapter-2")
         |> Task.perform HandleScrollResults

-}
scrollEach : (ScrollBuilder -> ScrollBuilder) -> Task Never (List (Result ScrollError ScrollOk))
scrollEach =
    Internal.scrollEach
        >> Task.map (List.map (Result.mapError toPublicError >> Result.map toPublicOk))


toPublicError : Internal.ScrollError -> ScrollError
toPublicError error =
    case error of
        Internal.ScrollError { containerId, targetElementId, domError } ->
            ScrollError
                { container = containerFromId containerId
                , targetElementId = targetElementId
                , domError = domError
                }


toPublicOk : { containerId : String, targetElementId : Maybe String } -> ScrollOk
toPublicOk ok =
    { container = containerFromId ok.containerId
    , targetElementId = ok.targetElementId
    }


containerFromId : String -> Container
containerFromId containerId =
    if containerId == "document" then
        Document

    else
        Container containerId



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay for all scrolls.

This will be inherited by all scrolls that
don't define their own delay.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Task as Task

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Task.delay 100
            >> Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.speed 200
            >> Scroll.build

-}
delay : Int -> ScrollBuilder -> ScrollBuilder
delay =
    SB.setDelay


{-| Set the duration of all scrolls.

This will be inherited by all scrolls that
don't define their own duration.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Task as Task

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Task.duration 1000
            >> Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.build

-}
duration : Int -> ScrollBuilder -> ScrollBuilder
duration =
    SB.setDuration


{-| Set the speed that scrolls should run at.

This will be inherited by all scrolls that
don't define their own speed.

    import Scroll.Builder as Scroll
    import Scroll.Engine.Task as Task

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Task.speed 200
            >> Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.build

-}
speed : Float -> ScrollBuilder -> ScrollBuilder
speed =
    SB.setSpeed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function to be used by all scrolls.

This will be inherited by all scrolls that
don't define their own easing.

    import Easing exposing (Easing(..))
    import Scroll.Builder as Scroll
    import Scroll.Engine.Task as Task

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Task.easing BounceOut
            >> Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.speed 200
            >> Scroll.build

-}
easing : Easing -> ScrollBuilder -> ScrollBuilder
easing =
    SB.setEasing
