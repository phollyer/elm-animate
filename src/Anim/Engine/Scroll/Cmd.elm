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

For specific Engine guides and examples, see the
[Scroll Cmd Engine Documentation](https://phollyer.github.io/elm-animate/engines/scroll/cmd/).

For Engine comparisons, shared features, examples and code, see the
[Scroll Overview](https://phollyer.github.io/elm-animate/engines/scroll/overview/) section in the docs.

Use the [Builder](Anim-Engine-Scroll-Builder) module to configure scroll targets.


# Types

@docs AnimBuilder


# Trigger

@docs animate


# Playback Settings


## Timing

@docs delay

@docs duration, speed


## Easing

@docs easing

📖 See [Timing](https://phollyer.github.io/elm-animate/getting-started/timing/) and
[Easing](https://phollyer.github.io/elm-animate/getting-started/easing/) in the docs.

-}

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Scroll.Cmd as InternalScrollCmd
import Anim.Internal.Engine.Scroll.Sub as InternalScrollSub



-- ============================================================
-- TYPES
-- ============================================================


{-| Animation builder type for configuring scroll animations.
-}
type alias AnimBuilder =
    InternalScrollSub.AnimBuilder



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Execute scroll animations as a fire-and-forget [Cmd](https://package.elm-lang.org/packages/elm/core/latest/Cmd).

    type Msg
        = ScrollCompleted
        | ...

    Scroll.animate ScrollCompleted <|
        scrollToElement "target-section"

**Note:** Because each call to `animate` pre-calculates its frame steps from the
current DOM state at the moment it runs, triggering a new scroll while a
previous one is still in flight starts a second independent scroll sequence.
The new scroll does not cancel or replace the old one, so overlapping scrolls
to different targets can compete with each other. If you need to interrupt or
retrigger scrolls safely, use
[Anim.Engine.Scroll.Sub](Anim-Engine-Scroll-Sub) instead.

-}
animate : msg -> (AnimBuilder -> AnimBuilder) -> Cmd msg
animate =
    InternalScrollCmd.animate



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
    Builder.duration


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
    Builder.speed


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
    Builder.easing


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
    Builder.delay
