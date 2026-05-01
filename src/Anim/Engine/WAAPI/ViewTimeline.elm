module Anim.Engine.WAAPI.ViewTimeline exposing
    ( AnimBuilder
    , animate
    , attributes
    , horizontal
    , Range, rangeStart, rangeEnd
    , cover, contain, entry, entryCrossing, exit, exitCrossing
    , iterations, alternate
    , easing
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

@docs animate


# View

@docs attributes


# Axis

@docs horizontal


# Range

@docs Range, rangeStart, rangeEnd


## Constructors

@docs cover, contain, entry, entryCrossing, exit, exitCrossing


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

Use this when playback should be tied to the element being fully visible
within the viewport.


### Start Animation

  - `rangeStart (contain 0)` - start when the element first becomes fully visible.
  - `rangeStart (contain 100)` - start just as the element is about to leave the viewport.


### End Animation

  - `rangeEnd (contain 0)` - end as soon as the element becomes fully visible.
  - `rangeEnd (contain 100)` - end just as the element begins to leave the viewport.

-}
contain : Float -> Range a
contain pct =
    Range ("contain " ++ String.fromFloat pct ++ "%")


{-| Element entering the viewport. Only valid as a range start.

Use this when playback should begin as the element enters the viewport.


### Start Animation

  - `rangeStart (entry 0)` - start when the element's leading edge first enters the viewport.
  - `rangeStart (entry 100)` - start when the element has fully entered the viewport.

-}
entry : Float -> Range ForStart
entry pct =
    Range ("entry " ++ String.fromFloat pct ++ "%")


{-| Element's leading edge crossing the viewport boundary. Only valid as a range start.

Similar to `entry`, but focuses specifically on the crossing moment of the
leading edge.


### Start Animation

  - `rangeStart (entryCrossing 0)` - start the moment the element's leading edge crosses into the viewport.
  - `rangeStart (entryCrossing 100)` - start when the element's leading edge reaches the opposite side of the viewport.

-}
entryCrossing : Float -> Range ForStart
entryCrossing pct =
    Range ("entry-crossing " ++ String.fromFloat pct ++ "%")


{-| Element leaving the viewport. Only valid as a range end.

Use this when playback should finish as the element leaves the viewport.


### End Animation

  - `rangeEnd (exit 0)` - end when the element's leading edge starts to leave the viewport.
  - `rangeEnd (exit 100)` - end when the element has fully left the viewport.

-}
exit : Float -> Range ForEnd
exit pct =
    Range ("exit " ++ String.fromFloat pct ++ "%")


{-| Element's trailing edge crossing the viewport boundary. Only valid as a range end.

Similar to `exit`, but focuses specifically on the crossing moment of the
trailing edge.


### End Animation

  - `rangeEnd (exitCrossing 0)` - end when the element's trailing edge begins to cross out of the viewport.
  - `rangeEnd (exitCrossing 100)` - end when the element's trailing edge reaches the opposite side of the viewport.

-}
exitCrossing : Float -> Range ForEnd
exitCrossing pct =
    Range ("exit-crossing " ++ String.fromFloat pct ++ "%")


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
