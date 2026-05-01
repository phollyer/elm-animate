module Anim.Engine.WAAPI.ScrollTimeline exposing (AnimBuilder, Axis, scroll, scrollSource, axis, easing, iterations, alternate)

{-| Scroll-driven animations that tie progress to a scroll container's position.

Unlike time-based animations, these run automatically as the user scrolls — no
`AnimState`, `update`, or `subscriptions` required.

**Note**: Because there is no `AnimState`, or rendering managed by Elm,
the JS companion cannot target elements by Anim Group Names. Instead,
target elements directly by their DOM ID in the property configuration. So instead of:

    Opacity.for "animGroupName"
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.build

Use the element's ID:

    Opacity.for "elementId"
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.build

For setup instructions and the JavaScript companion, see the
[WAAPI Engine Documentation](https://phollyer.github.io/elm-animate/engines/animation/waapi/).

@docs AnimBuilder, Axis, scroll, scrollSource, axis, easing, iterations, alternate

-}

import Anim.Engine.WAAPI as WAAPI
import Easing exposing (Easing)
import Json.Encode as Encode



-- ============================================================
-- TYPES
-- ============================================================


{-| Animation builder for scroll-driven pipelines.
-}
type alias AnimBuilder =
    WAAPI.AnimBuilder WAAPI.ForScroll


{-| The scroll axis.

  - `Block` - the block axis (vertical scrolling in most writing modes)
  - `Inline` - the inline axis (horizontal scrolling in most writing modes)

-}
type Axis
    = Block
    | Inline



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Fire-and-forget scroll-driven animation using the browser's `ScrollTimeline`.

    port waapiCommand : Encode.Value -> Cmd msg

    ScrollTimeline.scroll waapiCommand <|
        ScrollTimeline.scrollSource "scroller"
            >> Opacity.for "box"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
scroll : (Encode.Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg
scroll =
    WAAPI.scroll


{-| Set the scroll source element ID.

Pass the element ID of the scrolling container. Use `"document"` to target the
viewport's root scrolling element.

Calling this function is required in a `scroll` pipeline.

-}
scrollSource : String -> AnimBuilder -> AnimBuilder
scrollSource =
    WAAPI.scrollSource



-- ============================================================
-- CONFIGURATION
-- ============================================================


{-| Set the scroll axis. Defaults to `Block` if not called.
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


{-| Alternate direction on each iteration (ping-pong).
-}
alternate : AnimBuilder -> AnimBuilder
alternate =
    WAAPI.alternate
