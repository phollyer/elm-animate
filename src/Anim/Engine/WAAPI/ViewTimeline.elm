module Anim.Engine.WAAPI.ViewTimeline exposing
    ( AnimBuilder
    , animate
    , attributes
    , horizontal
    , Unit(..), Range(..), rangeStart, rangeEnd
    , iterations, alternate
    , easing
    )

{-| View-driven animations that tie progress to an element's position within the viewport.

Unlike time-based animations, these run automatically as the element scrolls into
and out of view — no `AnimState`, `update`, or `subscriptions` required.

The Engine uses the [ViewTimeline](https://developer.mozilla.org/en-US/docs/Web/API/ViewTimeline)
interface to the Web Animations API (WAAPI) and so requires the `elm-animate-waapi` JavaScript
companion library.

For specific Engine guides, setup instructions, and examples, see the
[ViewTimeline Engine Documentation](https://phollyer.github.io/elm-animate/animation/engines/view-timeline/).

For Engine comparisons, shared features, examples and code, see the
[Engine Overview](https://phollyer.github.io/elm-animate/engines/animation/overview/) section in the docs.


# Types

@docs AnimBuilder


# Trigger

@docs animate


# View

@docs attributes


# Axis

@docs horizontal


# Range

@docs Unit, Range, rangeStart, rangeEnd


# Playback

@docs iterations, alternate


# Easing

@docs easing

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.WAAPI as WAAPI
import Anim.Internal.Engine.WAAPI.Timeline as Timeline
import Easing exposing (Easing)
import Html
import Html.Attributes
import Json.Encode as Encode



-- ============================================================
-- MODEL
-- ============================================================


{-| Animation builder type for configuring view-driven animations.
-}
type alias AnimBuilder =
    Builder.AnimBuilder Timeline.ForView



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Fire-and-forget view-driven animation using the browser's `ViewTimeline`.

    port waapiCommand : Encode.Value -> Cmd msg

    ViewTimeline.animate waapiCommand <|
        Opacity.for "hero-card"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
animate : (Encode.Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg
animate portFn pipeline =
    Timeline.view portFn <|
        Timeline.asView
            << pipeline



-- ============================================================
-- VIEW
-- ============================================================


{-| Attach the animation group identifier to an element.

    div (ViewTimeline.attributes "hero-card") [ ... ]

-}
attributes : String -> List (Html.Attribute msg)
attributes targetId =
    [ Html.Attributes.attribute "data-anim-target" targetId ]



-- ============================================================
-- AXIS
-- ============================================================


{-| Use horizontal viewport tracking for the timeline.

Vertical scroll is the default, so this is only needed when the
container scrolls horizontally.

    -- Animate an element entering from the side in a horizontal layout
    ViewTimeline.animate waapiCommand <|
        ViewTimeline.horizontal
            >> Opacity.for "slide"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

-}
horizontal : AnimBuilder -> AnimBuilder
horizontal =
    Timeline.setScrollAxis "inline"



-- ============================================================
-- RANGE
-- ============================================================


{-| The unit for a `Range` offset value.

  - `Perc` — percentage of the named range (`Cover 20 Perc` → `cover 20%`)
  - `Px` — fixed pixel offset (`Cover 100 Px` → `cover 100px`)

-}
type Unit
    = Perc
    | Px


{-| A position along the view timeline, used to configure `rangeStart` and `rangeEnd`.

Each constructor takes a numeric value and a `Unit`:

    rangeStart (Entry 0 Perc) -- entry 0%

    rangeEnd (Exit 100 Px) -- exit 100px

See the [Range section](https://phollyer.github.io/elm-animate/animation/engines/view-timeline/#range)
in the docs for a full breakdown of each constructor.

-}
type Range
    = Cover Float Unit
    | Contain Float Unit
    | Entry Float Unit
    | EntryCrossing Float Unit
    | Exit Float Unit
    | ExitCrossing Float Unit
    | Scroll Float Unit


unitToString : Unit -> String
unitToString unit =
    case unit of
        Perc ->
            "%"

        Px ->
            "px"


rangeToString : Range -> String
rangeToString range =
    case range of
        Cover n u ->
            "cover " ++ String.fromFloat n ++ unitToString u

        Contain n u ->
            "contain " ++ String.fromFloat n ++ unitToString u

        Entry n u ->
            "entry " ++ String.fromFloat n ++ unitToString u

        EntryCrossing n u ->
            "entry-crossing " ++ String.fromFloat n ++ unitToString u

        Exit n u ->
            "exit " ++ String.fromFloat n ++ unitToString u

        ExitCrossing n u ->
            "exit-crossing " ++ String.fromFloat n ++ unitToString u

        Scroll n u ->
            "scroll " ++ String.fromFloat n ++ unitToString u


{-| Set when the animation starts relative to the element's position in the viewport.

Optional — defaults to `Cover 0 Perc` when not called.

    -- Start animating as the element enters the viewport
    ViewTimeline.rangeStart (Entry 0 Perc)

    -- Start animating once the element is fully visible
    ViewTimeline.rangeStart (Entry 100 Perc)

-}
rangeStart : Range -> AnimBuilder -> AnimBuilder
rangeStart range =
    Timeline.rangeStart (rangeToString range)


{-| Set when the animation ends relative to the element's position in the viewport.

Optional — defaults to `Cover 100 Perc` when not called.

    -- End animating as the element begins to leave the viewport
    ViewTimeline.rangeEnd (Exit 0 Perc)

    -- End animating once the element has fully left the viewport
    ViewTimeline.rangeEnd (Exit 100 Perc)

-}
rangeEnd : Range -> AnimBuilder -> AnimBuilder
rangeEnd range =
    Timeline.rangeEnd (rangeToString range)



-- ============================================================
-- PLAYBACK
-- ============================================================


{-| Set how many times the animation should repeat.
-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    WAAPI.iterations


{-| Alternate direction on each iteration (ping-pong).

If `iterations` has not been set, this defaults to `2` so that the
alternate direction has a second iteration to play.

-}
alternate : AnimBuilder -> AnimBuilder
alternate builder =
    let
        withIterations =
            case Builder.getIterations builder of
                Builder.Once ->
                    Builder.iterations 2 builder

                _ ->
                    builder
    in
    WAAPI.alternate withIterations



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function.
-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    WAAPI.easing
