module Anim.Engine.WAAPI.ViewTimeline exposing
    ( AnimBuilder
    , view
    , attributes
    , iterations, alternate
    , easing
    , Range, rangeStart, rangeEnd
    , cover, contain, entry, entryCrossing, exit, exitCrossing
    , Axis, axis
    )

{-| View-driven animations that tie progress to an element's position within the viewport.

Unlike time-based animations, these run automatically as the element scrolls into
and out of view — no `AnimState`, `update`, or `subscriptions` required.

Requires the `elm-animate-waapi` JavaScript companion library.

For specific Engine guides, setup instructions, and examples, see the
[WAAPI Engine Documentation](https://phollyer.github.io/elm-animate/engines/animation/waapi/).

For Engine comparisons, shared features, examples and code, see the
[Engine Overview](https://phollyer.github.io/elm-animate/engines/animation/overview/) section in the docs.


# Types

@docs AnimBuilder


# Trigger

@docs view


# View

@docs attributes


# Playback

@docs iterations, alternate


# Easing

@docs easing


# Configuration


## Range

@docs Range, rangeStart, rangeEnd


### Constructors

@docs cover, contain, entry, entryCrossing, exit, exitCrossing


## Axis

@docs Axis, axis

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


{-| The view axis.

  - `Vertical` - maps to CSS `block` axis
  - `Horizontal` - maps to CSS `inline` axis

-}
type Axis
    = Vertical
    | Horizontal



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Fire-and-forget view-driven animation using the browser's `ViewTimeline`.

The animated element itself is used as the `ViewTimeline` subject.

[`rangeStart`](#rangeStart) and [`rangeEnd`](#rangeEnd) are optional — when omitted
the browser defaults to `cover 0` and `cover 100`, meaning the animation
runs from when the element's leading edge enters the viewport until its trailing
edge leaves it.

    port waapiCommand : Encode.Value -> Cmd msg

    ViewTimeline.view waapiCommand <|
        ViewTimeline.rangeStart (Entry 0)
            >> ViewTimeline.rangeEnd (Entry 50)
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


{-| A phantom type representing a position along the view timeline.
Used for configuring `rangeStart` and `rangeEnd`. Use the constructor
functions below to create values of this type.

The range determines when the animation plays during the element's lifecycle in the viewport.

-}
type Range a
    = Range String


{-| Phantom tag for values valid as a range start.
-}
type ForStart
    = ForStart


{-| Phantom tag for values valid as a range end.
-}
type ForEnd
    = ForEnd


{-| Determines when the animation should start in relation
to the element's position in the viewport.

For vertical scrolling, when scrolling up, the element enters
from the bottom with it's top edge. When scrolling down, the
element enters from the top with it's bottom edge.

For horizontal scrolling, when scrolling left, the element enters
from the right with it's left edge. When scrolling right, the element enters
from the left with it's right edge.

Use the constructor functions below to set the behaviour of the range start point.

Optional — defaults to `cover 0` when not called.

-}
rangeStart : Range ForStart -> AnimBuilder -> AnimBuilder
rangeStart (Range str) =
    Timeline.rangeStart str


{-| Determines when the animation should end in relation
to the element's position in the viewport.

For vertical scrolling, when scrolling up, the element exits
towards the top with it's bottom edge. When scrolling down, the
element exits towards the bottom with it's top edge.

For horizontal scrolling, when scrolling left, the element exits
towards the left with it's right edge. When scrolling right, the
element exits towards the right with it's left edge.

Use the constructor functions below to set the behaviour of the range end point.

Optional — defaults to `cover 100` when not called.

-}
rangeEnd : Range ForEnd -> AnimBuilder -> AnimBuilder
rangeEnd (Range str) =
    Timeline.rangeEnd str


{-| Full element coverage of the viewport. Valid for start or end.

Use this when playback should be tied to how much of the element overlaps the
viewport.


### Start Animation

  - `rangeStart (cover 0)` - start when the element first touches the viewport edge on entry.
  - `rangeStart (cover 100)` - start when the entire element is visible on entry.


### End Animation

  - `rangeEnd (cover 0)` - end when the element first touches the viewport edge on exit.
  - `rangeEnd (cover 100)` - end when the entire element has left the viewport on exit.

-}
cover : Float -> Range a
cover pct =
    Range ("cover " ++ String.fromFloat pct ++ "%")


{-| Full element containment within the viewport. Valid for start or end.

Use this when playback should happen while the element is fully inside the
viewport.

As a start value, lower percentages start sooner as containment is reached.
As an end value, higher percentages delay completion until later containment.

-}
contain : Float -> Range a
contain pct =
    Range ("contain " ++ String.fromFloat pct ++ "%")


{-| Element entering the viewport. Only valid as a range start.

This controls when playback begins as the element moves in from outside the
viewport.

Lower percentages start earlier during entry. Higher percentages wait until
more of the element has entered.

-}
entry : Float -> Range ForStart
entry pct =
    Range ("entry " ++ String.fromFloat pct ++ "%")


{-| Element's leading edge crossing the viewport boundary. Only valid as a range start.

This starts playback relative to the moment the element first crosses into
view.

Lower percentages begin closer to first contact. Higher percentages begin later
after further crossing.

-}
entryCrossing : Float -> Range ForStart
entryCrossing pct =
    Range ("entry-crossing " ++ String.fromFloat pct ++ "%")


{-| Element leaving the viewport. Only valid as a range end.

This controls when playback finishes as the element moves out of view.

Lower percentages end earlier during exit. Higher percentages keep playback
going until later in the exit phase.

-}
exit : Float -> Range ForEnd
exit pct =
    Range ("exit " ++ String.fromFloat pct ++ "%")


{-| Element's trailing edge crossing the viewport boundary. Only valid as a range end.

This sets when playback completes relative to the final boundary crossing as
the element leaves view.

Lower percentages complete sooner. Higher percentages complete later, closer to
fully leaving the viewport.

-}
exitCrossing : Float -> Range ForEnd
exitCrossing pct =
    Range ("exit-crossing " ++ String.fromFloat pct ++ "%")


{-| Attach the animation group identifier to an element.

    div (ViewTimeline.attributes "hero-card") [ ... ]

-}
attributes : String -> List (Html.Attribute msg)
attributes targetId =
    [ Html.Attributes.attribute "data-anim-target" targetId ]


{-| Set the view axis. Defaults to `Vertical` if not called.
-}
axis : Axis -> AnimBuilder -> AnimBuilder
axis axisValue =
    Timeline.axis
        (case axisValue of
            Vertical ->
                Timeline.Block

            Horizontal ->
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
