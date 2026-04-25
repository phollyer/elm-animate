module Scroll.Engine.Task exposing
    ( AnimBuilder
    , ScrollError(..), ScrollOk
    , animate, attempt
    , delay, duration, speed
    , easing
    )

{-| Composable scroll animations via Task with error handling.

Use this module when you need to handle scroll success or failure,
or compose scroll operations with other Tasks.

For specific Engine guides and examples, see the
[Scroll Task Engine Documentation](https://phollyer.github.io/elm-animate/engines/scroll/task/).

For Engine comparisons, shared features, examples and code, see the
[Scroll Overview](https://phollyer.github.io/elm-animate/engines/scroll/overview/) section in the docs.

Use the [Builder](Anim-Engine-Scroll-Builder) module to configure scroll targets.


# Types

@docs AnimBuilder


# Trigger

@docs ScrollError, ScrollOk

@docs animate, attempt


# Playback Settings


## Timing

@docs delay, duration, speed

📖 See [Timing](https://phollyer.github.io/elm-animate/getting-started/timing/) in the docs.


## Easing

@docs easing

📖 See [Easing](https://phollyer.github.io/elm-animate/getting-started/easing/) in the docs.

-}

import Anim.Internal.Builder as InternalBuilder
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Dom as Dom
import Easing exposing (Easing(..))
import Scroll.Internal.Engine.Internal exposing (Container(..))
import Scroll.Internal.Engine.Task as ScrollTask
import Task exposing (Task)



-- ============================================================
-- TYPES
-- ============================================================


{-| Animation builder type for configuring scroll animations.
-}
type alias AnimBuilder =
    InternalBuilder.AnimBuilder


{-| Error type for failed scroll [Task](http://package.elm-lang.org/packages/elm/core/latest/Task)s.

Provides details about what failed during a scroll operation:

  - `containerId`: The container that was being scrolled ("document" for document body)
  - `targetElementId`: The element ID if scrolling to an element target
  - `domError`: The underlying [Dom.Error](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Dom#Error) that caused the scroll to fail

-}
type ScrollError
    = ScrollError
        { containerId : String
        , targetElementId : Maybe String
        , domError : Dom.Error
        }


{-| Value type for successful scroll [Task](http://package.elm-lang.org/packages/elm/core/latest/Task)s.

Provides details about the completed scroll operation:

  - `containerId`: The container that was scrolled
  - `targetElementId`: The element ID if scrolled to an element target

-}
type alias ScrollOk =
    { containerId : String
    , targetElementId : Maybe String
    }



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Execute scroll animations as a [Task](https://package.elm-lang.org/packages/elm/core/latest/Task).

    type Msg
        = HandleScrollResult (Result ScrollError (List ScrollOk))
        | ...

    Scroll.animate (scrollToElement "target-section")
         |> Task.attempt HandleScrollResult

**Note:** Because each call to `animate` pre-calculates its frame steps from the
current DOM state at the moment it runs, triggering a new scroll while a
previous one is still in flight starts a second independent scroll sequence.
The new scroll does not cancel or replace the old one, so overlapping scrolls
to different targets can compete with each other. If you need to interrupt or
retrigger scrolls safely, use
[Scroll.Engine.Sub](Anim-Engine-Scroll-Sub) instead.

-}
animate : (AnimBuilder -> AnimBuilder) -> Task ScrollError (List ScrollOk)
animate =
    ScrollTask.animate
        >> Task.mapError toPublicError


{-| Execute each scroll in sequence and collect per - scroll results.

Unlike [`animate`](#animate), this function continues after failures and always
returns all results in pipeline order.

    type Msg
        = HandleScrollAttempts (List (Result ScrollError ScrollOk))
        | ...

    Scroll.attempt (scrollSequence "chapter-2")
         |> Task.perform HandleScrollAttempts

-}
attempt : (AnimBuilder -> AnimBuilder) -> Task Never (List (Result ScrollError ScrollOk))
attempt =
    ScrollTask.attempt
        >> Task.map (List.map (Result.mapError toPublicError))


toPublicError : ScrollTask.ScrollError -> ScrollError
toPublicError error =
    case error of
        ScrollTask.ScrollError { containerId, targetElementId, domError } ->
            ScrollError
                { containerId = containerId
                , targetElementId = targetElementId
                , domError = domError
                }



-- ============================================================
-- PLAYBACK SETTINGS
-- ============================================================


{-| Set the global default duration in milliseconds.

    scrollToElement : String -> AnimBuilder -> AnimBuilder
    scrollToElement elementId =
        Scroll.duration 1000
            >> Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.build

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalBuilder.duration


{-| Set the global default speed in pixels per second.

    scrollToElement : String -> AnimBuilder -> AnimBuilder
    scrollToElement elementId =
        Scroll.speed 200
            >> Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.build

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalBuilder.speed


{-| Set the global default easing function.

    scrollToElement : String -> AnimBuilder -> AnimBuilder
    scrollToElement elementId =
        Scroll.easing BounceOut
            >> Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.speed 200
            >> Builder.build

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalBuilder.easing


{-| Set the global default delay in milliseconds.

    scrollToElement : String -> AnimBuilder -> AnimBuilder
    scrollToElement elementId =
        Scroll.delay 100
            >> Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.speed 200
            >> Builder.build

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalBuilder.delay
