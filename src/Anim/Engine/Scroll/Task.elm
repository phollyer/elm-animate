module Anim.Engine.Scroll.Task exposing
    ( AnimBuilder
    , ScrollError(..), ScrollOk
    , animate
    , delay
    , duration, speed
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

@docs animate


# Playback Settings

@docs delay

@docs duration, speed

@docs easing

See [Timing](https://phollyer.github.io/elm-animate/getting-started/timing/) and
[Easing](https://phollyer.github.io/elm-animate/getting-started/easing/) in the docs.

-}

import Anim.Extra.Easing exposing (Easing(..))
import Anim.Internal.Builder as InternalBuilder
import Anim.Internal.Engine.Scroll.Internal exposing (Container(..))
import Anim.Internal.Engine.Scroll.Task as ScrollTask
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Dom as Dom
import Task exposing (Task)


{-| Animation builder type for configuring scroll animations.
-}
type alias AnimBuilder =
    InternalBuilder.AnimBuilder


{-| Error type for failed scroll [Task](http://package.elm-lang.org/packages/elm/core/latest/Task)s.

Provides details about what failed during a scroll operation:

  - `containerId`: The container that was being scrolled ("document" for document body)
  - `targetElementId`: The element ID if scrolling to an element target
  - `domError`: The underlying DOM error (typically element not found)

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
  - `targetDescription`: Human-readable description of the scroll target

-}
type alias ScrollOk =
    { containerId : String
    , targetElementId : Maybe String
    , targetDescription : String
    }


{-| Execute scroll animations as a [Task](https://package.elm-lang.org/packages/elm/core/latest/Task).

    type Msg
        = HandleScrollResult (Result ScrollError ScrollOk)
        | ...

    Scroll.animate (scrollToElement "target-section")
         |> Task.attempt HandleScrollResult

-}
animate : (AnimBuilder -> AnimBuilder) -> Task ScrollError ScrollOk
animate =
    ScrollTask.animate
        >> Task.mapError
            (\error ->
                case error of
                    ScrollTask.ScrollError { containerId, targetElementId, domError } ->
                        ScrollError
                            { containerId = containerId
                            , targetElementId = targetElementId
                            , domError = domError
                            }
            )


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
