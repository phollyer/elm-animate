module Anim.Engine.WAAPI.ViewTimeline exposing (AnimBuilder, Axis, axis, view, rangeEnd, rangeStart, easing, alternate, iterations, loopForever)

{-| View-driven animations that tie progress to an element's position within the viewport.

Unlike time-based animations, these run automatically as the element scrolls into
and out of view — no `AnimState`, `update`, or `subscriptions` required.

For setup instructions and the JavaScript companion, see the
[WAAPI Engine Documentation](https://phollyer.github.io/elm-animate/engines/animation/waapi/).

@docs AnimBuilder, Axis, axis, view, rangeEnd, rangeStart, easing, alternate, iterations, loopForever

-}

import Anim.Engine.WAAPI as WAAPI
import Easing exposing (Easing)
import Json.Encode as Encode



-- ============================================================
-- TYPES
-- ============================================================


{-| Animation builder for view-driven pipelines.
-}
type alias AnimBuilder =
    WAAPI.AnimBuilder WAAPI.ForView


{-| The view axis.

  - `Block` - the block axis (vertical scrolling in most writing modes)
  - `Inline` - the inline axis (horizontal scrolling in most writing modes)

-}
type Axis
    = Block
    | Inline



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Fire-and-forget view-driven animation using the browser's `ViewTimeline`.

The animated element itself is used as the `ViewTimeline` subject.

    port waapiCommand : Encode.Value -> Cmd msg

    ViewTimeline.view waapiCommand <|
        ViewTimeline.rangeStart "entry 0%"
            >> ViewTimeline.rangeEnd "entry 50%"
            >> Opacity.for "card"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
view : (Encode.Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg
view portFn pipeline =
    WAAPI.view portFn (WAAPI.asView >> pipeline)



-- ============================================================
-- CONFIGURATION
-- ============================================================


{-| Set the `ViewTimeline` range start.

Accepts standard CSS animation-range values such as `"entry 0%"` or `"contain 25%"`.

-}
rangeStart : String -> AnimBuilder -> AnimBuilder
rangeStart =
    WAAPI.rangeStart


{-| Set the `ViewTimeline` range end.

Accepts standard CSS animation-range values such as `"exit 100%"` or `"contain 75%"`.

-}
rangeEnd : String -> AnimBuilder -> AnimBuilder
rangeEnd =
    WAAPI.rangeEnd


{-| Set the view axis. Defaults to `Block` if not called.
-}
axis : Axis -> AnimBuilder -> AnimBuilder
axis axisValue =
    WAAPI.axis
        (case axisValue of
            Block ->
                WAAPI.Block

            Inline ->
                WAAPI.Inline
        )



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function.
-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    WAAPI.easing



-- ============================================================
-- PLAYBACK
-- ============================================================


{-| Set how many times the animation should repeat.
-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    WAAPI.iterations


{-| Loop the animation infinitely.
-}
loopForever : AnimBuilder -> AnimBuilder
loopForever =
    WAAPI.loopForever


{-| Alternate direction on each iteration (ping-pong).
-}
alternate : AnimBuilder -> AnimBuilder
alternate =
    WAAPI.alternate
