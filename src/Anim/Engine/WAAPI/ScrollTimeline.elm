module Anim.Engine.WAAPI.ScrollTimeline exposing (AnimBuilder, Axis, scroll, scrollSource, target, attributes, axis, easing, iterations, alternate)

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

@docs AnimBuilder, Axis, scroll, scrollSource, target, attributes, axis, easing, iterations, alternate

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.WAAPI as WAAPI
import Anim.Internal.Engine.WAAPI.Timeline as Timeline
import Easing exposing (Easing)
import Html
import Html.Attributes
import Json.Encode as Encode



-- ============================================================
-- TYPES
-- ============================================================


{-| Animation builder for scroll-driven pipelines.
-}
type alias AnimBuilder =
    Builder.AnimBuilder Timeline.ForScroll


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
    Timeline.scroll


{-| Set the scroll source element ID.

Pass the element ID of the scrolling container. Use `"document"` to target the
viewport's root scrolling element.

Calling this function is required in a `scroll` pipeline.

-}
scrollSource : String -> AnimBuilder -> AnimBuilder
scrollSource =
    Timeline.scrollSource


{-| Set an explicit DOM target id for the current animation group.

Use this to decouple animation group names from element lookup ids.

-}
target : String -> AnimBuilder -> AnimBuilder
target =
    Timeline.setTarget


{-| Attach the target identifier to an element without requiring AnimState.

    div (ScrollTimeline.attributes "hero-card") [ ... ]

-}
attributes : String -> List (Html.Attribute msg)
attributes targetId =
    [ Html.Attributes.attribute "data-anim-target" targetId ]



-- ============================================================
-- CONFIGURATION
-- ============================================================


{-| Set the scroll axis. Defaults to `Block` if not called.
-}
axis : Axis -> AnimBuilder -> AnimBuilder
axis axisValue =
    Timeline.axis
        (case axisValue of
            Block ->
                Timeline.Block

            Inline ->
                Timeline.Inline
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
