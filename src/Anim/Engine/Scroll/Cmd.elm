module Anim.Engine.Scroll.Cmd exposing
    ( AnimBuilder
    , animate
    , delay
    , duration, speed
    , easing
    )

{-| Fire-and-forget scroll animations via Cmd.

Use this module when you don't need state management, error handling,
or animation control. The scroll runs and completes independently.

For detailed guides and examples, see the
[full documentation](https://phollyer.github.io/elm-animate/engines/scroll/).

Use the [Builder](Anim-Engine-Scroll-Builder) module to configure scroll targets.


# Types

@docs AnimBuilder


# Trigger

@docs animate


# Default Settings

@docs delay

@docs duration, speed

@docs easing

-}

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Engine.Scroll as InternalScroll


{-| Animation builder type for configuring scroll animations.
-}
type alias AnimBuilder =
    InternalScroll.AnimBuilder


{-| Execute scroll animations as a fire-and-forget [Cmd](https://package.elm-lang.org/packages/elm/core/latest/Cmd).

    type Msg
        = ScrollCompleted
        | ...

    Scroll.animate ScrollCompleted <|
        scrollToElement "target-section"

-}
animate : msg -> (AnimBuilder -> AnimBuilder) -> Cmd msg
animate =
    InternalScroll.toCmd


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
    InternalScroll.duration


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
    InternalScroll.speed


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
    InternalScroll.easing


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
    InternalScroll.delay
