module Scroll.Engine.Cmd exposing
    ( ScrollBuilder
    , scroll
    , delay
    , duration, speed
    , easing
    )

{-| Fire-and-forget scroll animations via Cmd.

Use this module when you don't need state management, error handling,
or animation control. The scroll runs and completes independently.

For specific Engine guides and examples, see the
[Scroll Cmd Engine Documentation](https://phollyer.github.io/elm-animate/engines/scroll/cmd/).

For Engine comparisons, shared features, examples and code, see the
[Scroll Overview](https://phollyer.github.io/elm-animate/engines/scroll/overview/) section in the docs.

Use the [Builder](Scroll-Builder) module to configure scroll targets.


# Types

@docs ScrollBuilder


# Trigger

@docs scroll


# Playback Settings


## Timing

@docs delay

@docs duration, speed


## Easing

@docs easing

📖 See [Timing](https://phollyer.github.io/elm-animate/getting-started/timing/) and
[Easing](https://phollyer.github.io/elm-animate/getting-started/easing/) in the docs.

-}

import Easing exposing (Easing)
import Scroll.Internal.Engine.Cmd as Internal
import Scroll.Internal.ScrollBuilder as SB



-- ============================================================
-- TYPES
-- ============================================================


{-| Animation builder type for configuring scroll animations.
-}
type alias ScrollBuilder =
    SB.ScrollBuilder



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Execute scroll animations as a fire-and-forget [Cmd](https://package.elm-lang.org/packages/elm/core/latest/Cmd).

    type Msg
        = ScrollCompleted
        | ...

    Cmd.scroll ScrollCompleted <|
        scrollToElement "target-section"

**Note:** Because each call to `scroll` pre-calculates its frame steps from the
current DOM state at the moment it runs, triggering the same scroll sequence
multiple times in quick succession can lead to unexpected results.

For example, subsequent scrolls do not cancel or replace the old one, so overlapping
scrolls on the same container will compete with each other. If you need to interrupt or
retrigger scrolls safely, use
[Scroll.Engine.Sub](Scroll-Engine-Sub) instead.

-}
scroll : msg -> (ScrollBuilder -> ScrollBuilder) -> Cmd msg
scroll =
    Internal.scroll



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
    SB.setDuration


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
    SB.setSpeed


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
    SB.setEasing


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
    SB.setDelay
