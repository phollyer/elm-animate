module Anim.Engine.WAAPI.ViewTimeline exposing (AnimBuilder, Axis, axis, view, rangeEnd, rangeStart, target, attributes, easing, alternate, iterations)

{-| View-driven animations that tie progress to an element's position within the viewport.

Unlike time-based animations, these run automatically as the element scrolls into
and out of view — no `AnimState`, `update`, or `subscriptions` required.

For setup instructions and the JavaScript companion, see the
[WAAPI Engine Documentation](https://phollyer.github.io/elm-animate/engines/animation/waapi/).

@docs AnimBuilder, Axis, axis, view, rangeEnd, rangeStart, target, attributes, easing, alternate, iterations

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


{-| Animation builder for view-driven pipelines.
-}
type alias AnimBuilder =
    Builder.AnimBuilder Timeline.ForView


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
    Timeline.view portFn <|
        Timeline.asView
            << pipeline



-- ============================================================
-- CONFIGURATION
-- ============================================================


{-| Set the `ViewTimeline` range start.

Accepts standard CSS animation-range values such as `"entry 0%"` or `"contain 25%"`.

-}
rangeStart : String -> AnimBuilder -> AnimBuilder
rangeStart =
    Timeline.rangeStart


{-| Set the `ViewTimeline` range end.

Accepts standard CSS animation-range values such as `"exit 100%"` or `"contain 75%"`.

-}
rangeEnd : String -> AnimBuilder -> AnimBuilder
rangeEnd =
    Timeline.rangeEnd


{-| Set an explicit DOM target id for the current animation group.

Use this to decouple animation group names from element lookup ids.

-}
target : String -> AnimBuilder -> AnimBuilder
target =
    Timeline.setTarget


{-| Attach the target identifier to an element without requiring AnimState.

    div (ViewTimeline.attributes "hero-card") [ ... ]

-}
attributes : String -> List (Html.Attribute msg)
attributes targetId =
    [ Html.Attributes.attribute "data-anim-target" targetId ]


{-| Set the view axis. Defaults to `Block` if not called.
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
