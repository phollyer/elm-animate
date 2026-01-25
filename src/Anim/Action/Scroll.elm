module Anim.Action.Scroll exposing
    ( Builder, forDocument, forContainer, build
    , toElement
    , toTop, toBottom, toCenter
    , toLeft, toRight
    , toTopLeft, toTopRight, toBottomLeft, toBottomRight
    , toXY, toX, toY, toPercentageXY, toPercentageX, toPercentageY
    , byXY, byX, byY
    , onBothAxes, onXAxis, onYAxis
    , onBothAxesWithOffset, onXAxisWithOffset, onYAxisWithOffset
    , delay, duration, speed
    , easing
    )

{-| Scroll animation functions.

Build animations that scroll the document or container elements to specific elements or coordinates.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.toElement "section-1"
        |> Scroll.onYAxisWithOffset 60
        |> Scroll.speed 500
        |> Scroll.build

You can chain multiple scroll targets with different containers.

    animBuilder
        |> Scroll.forContainer "container-1"
        |> Scroll.toElement "target-1"
        |> Scroll.speed 800
        |> Scroll.build
        |> Scroll.forDocument
        |> Scroll.toTop
        |> Scroll.duration 1000
        |> Scroll.easing BounceOut
        |> Scroll.build

**Note**: `animBuilder` is provided by the [Scroll Engine](Anim-Engine-Scroll).


# Build

@docs Builder, forDocument, forContainer, build


# Targeting


## Element Targeting

@docs toElement


## Position Targeting

@docs toTop, toBottom, toCenter
@docs toLeft, toRight
@docs toTopLeft, toTopRight, toBottomLeft, toBottomRight


## Coordinate Targeting

@docs toXY, toX, toY, toPercentageXY, toPercentageX, toPercentageY


## Relative Scrolling

@docs byXY, byX, byY


# Axis Selection

@docs onBothAxes, onXAxis, onYAxis


## With Offsets

@docs onBothAxesWithOffset, onXAxisWithOffset, onYAxisWithOffset


# Timing

These override their equivalent global settings.

@docs delay, duration, speed


# Easing

This overrides any global easing setting.

@docs easing

-}

import Anim.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Scroll as SB


{-| Type alias for the internal ScrollBuilder.
-}
type alias Builder =
    SB.ScrollBuilder



-- BUILD


{-| Start configuring a scroll animation for the document body.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.toTop
        |> Scroll.duration 500
        |> Scroll.build

-}
forDocument : AnimBuilder -> Builder
forDocument =
    SB.forDocument


{-| Start configuring a scroll animation for a specific container element.

    animBuilder
        |> Scroll.forContainer "container-id"
        |> Scroll.toBottom
        |> Scroll.duration 500
        |> Scroll.build

-}
forContainer : String -> AnimBuilder -> Builder
forContainer =
    SB.forContainer


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`.

    animBuilder
        |> Scroll.forContainer "container"
        |> Scroll.toElement "target-id"
        |> Scroll.speed 500
        |> Scroll.build

From here, you can either animate it with the [Scroll Engine](Anim-Engine-Scroll), or
continue configuring other scroll animations in the same `AnimBuilder` pipeline.

-}
build : Builder -> AnimBuilder
build =
    SB.build



-- TARGET CONFIGURATION


{-| Scroll to a specific element by ID.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.toElement "section-header"
        |> Scroll.speed 500
        |> Scroll.build

-}
toElement : String -> Builder -> Builder
toElement =
    SB.toElement


{-| Scroll to specific X and Y coordinates.

    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.toXY 100 200
        |> Scroll.duration 500
        |> Scroll.build

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    SB.toXY


{-| Scroll to specific X coordinate only.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.toX 100
        |> Scroll.duration 500
        |> Scroll.build

-}
toX : Float -> Builder -> Builder
toX =
    SB.toX


{-| Scroll to specific Y coordinate only.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.toY 200
        |> Scroll.duration 500
        |> Scroll.build

-}
toY : Float -> Builder -> Builder
toY =
    SB.toY


{-| Scroll to the top of the container.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.toTop
        |> Scroll.duration 500
        |> Scroll.build

-}
toTop : Builder -> Builder
toTop =
    SB.toTop


{-| Scroll to the bottom of the container.

    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.toBottom
        |> Scroll.duration 500
        |> Scroll.build

-}
toBottom : Builder -> Builder
toBottom =
    SB.toBottom


{-| Scroll to the center of the container.

    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.toCenter
        |> Scroll.duration 500
        |> Scroll.build

-}
toCenter : Builder -> Builder
toCenter =
    SB.toCenter


{-| Scroll to the left edge of the container.

    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.toLeft
        |> Scroll.duration 500
        |> Scroll.build

-}
toLeft : Builder -> Builder
toLeft =
    SB.toLeft


{-| Scroll to the right edge of the container.

    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.toRight
        |> Scroll.duration 500
        |> Scroll.build

-}
toRight : Builder -> Builder
toRight =
    SB.toRight


{-| Scroll to the top-left corner of the container.

    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.toTopLeft
        |> Scroll.duration 500
        |> Scroll.build

-}
toTopLeft : Builder -> Builder
toTopLeft =
    SB.toTopLeft


{-| Scroll to the top-right corner of the container.

    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.toTopRight
        |> Scroll.duration 500
        |> Scroll.build

-}
toTopRight : Builder -> Builder
toTopRight =
    SB.toTopRight


{-| Scroll to the bottom-left corner of the container.

    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.toBottomLeft
        |> Scroll.duration 500
        |> Scroll.build

-}
toBottomLeft : Builder -> Builder
toBottomLeft =
    SB.toBottomLeft


{-| Scroll to the bottom-right corner of the container.

    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.toBottomRight
        |> Scroll.duration 500
        |> Scroll.build

-}
toBottomRight : Builder -> Builder
toBottomRight =
    SB.toBottomRight


{-| Scroll to percentage of container size.

    -- Scroll to 50% X and 80% Y of the container size.
    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.toPercentageXY 0.5 0.8
        |> Scroll.duration 500
        |> Scroll.build

-}
toPercentageXY : Float -> Float -> Builder -> Builder
toPercentageXY =
    SB.toPercentageXY


{-| Scroll to percentage of container width (X axis only).

    -- Scroll to 50% of the container width.
    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.toPercentageX 0.5
        |> Scroll.duration 500
        |> Scroll.build

-}
toPercentageX : Float -> Builder -> Builder
toPercentageX =
    SB.toPercentageX


{-| Scroll to percentage of container height (Y axis only).

    -- Scroll to 80% of the container height.
    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.toPercentageY 0.8
        |> Scroll.duration 500
        |> Scroll.build

-}
toPercentageY : Float -> Builder -> Builder
toPercentageY =
    SB.toPercentageY


{-| Scroll by a relative amount on both X and Y axes.

Positive values scroll right/down, negative values scroll left/up.

    -- Scroll right 100px and down 200px
    animBuilder
        |> Scroll.forDocument
        |> Scroll.byXY 100 200
        |> Scroll.duration 500
        |> Scroll.build

    -- Scroll left 50px and up 100px
    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.byXY -50 -100
        |> Scroll.duration 500
        |> Scroll.build

-}
byXY : Float -> Float -> Builder -> Builder
byXY =
    SB.byXY


{-| Scroll by a relative amount on X axis only.

Positive values scroll right, negative values scroll left.

    -- Scroll right 100px
    animBuilder
        |> Scroll.forDocument
        |> Scroll.byX 100
        |> Scroll.duration 500
        |> Scroll.build

-}
byX : Float -> Builder -> Builder
byX =
    SB.byX


{-| Scroll by a relative amount on Y axis only.

Positive values scroll down, negative values scroll up.

    -- Scroll down 200px
    animBuilder
        |> Scroll.forDocument
        |> Scroll.byY 200
        |> Scroll.duration 500
        |> Scroll.build

-}
byY : Float -> Builder -> Builder
byY =
    SB.byY



-- AXIS SELECTION


{-| Scroll on both X and Y axes (default).

    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.onBothAxes
        |> Scroll.toElement "section-1"
        |> Scroll.speed 500
        |> Scroll.build

-}
onBothAxes : Builder -> Builder
onBothAxes =
    SB.onBothAxes


{-| Scroll on X axis only.

    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.onXAxis
        |> Scroll.toX 500
        |> Scroll.speed 500
        |> Scroll.build

-}
onXAxis : Builder -> Builder
onXAxis =
    SB.onXAxis


{-| Scroll on Y axis only.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.onYAxis
        |> Scroll.toElement "section-1"
        |> Scroll.speed 500
        |> Scroll.build

-}
onYAxis : Builder -> Builder
onYAxis =
    SB.onYAxis


{-| Scroll on both axes with offsets.

    -- Scroll to element with 20px X offset and 60px Y offset.
    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.onBothAxesWithOffset 20 60
        |> Scroll.toElement "section-1"
        |> Scroll.speed 500
        |> Scroll.build

-}
onBothAxesWithOffset : Float -> Float -> Builder -> Builder
onBothAxesWithOffset =
    SB.onBothAxesWithOffset


{-| Scroll on X axis with offset.

    animBuilder
        |> Scroll.forContainer "element-id"
        |> Scroll.onXAxisWithOffset 60
        |> Scroll.toElement "section-1"
        |> Scroll.speed 500
        |> Scroll.build

-}
onXAxisWithOffset : Float -> Builder -> Builder
onXAxisWithOffset =
    SB.onXAxisWithOffset


{-| Scroll on Y axis with offset.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.onYAxisWithOffset 60
        |> Scroll.toElement "section-1"
        |> Scroll.speed 500
        |> Scroll.build

-}
onYAxisWithOffset : Float -> Builder -> Builder
onYAxisWithOffset =
    SB.onYAxisWithOffset



-- TIMING


{-| Set the delay (milliseconds) before this scroll animation starts.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.toTop
        |> Scroll.delay 500
        |> Scroll.duration 500
        |> Scroll.build

-}
delay : Int -> Builder -> Builder
delay =
    SB.delay


{-| Set the duration (milliseconds) for this scroll animation.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.toElement "target"
        |> Scroll.duration 1000
        |> Scroll.build

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| Set the speed (pixels per second) for this scroll animation.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.toTop
        |> Scroll.speed 500
        |> Scroll.build

-}
speed : Float -> Builder -> Builder
speed =
    SB.speed



-- EASING


{-| Set the easing function for this scroll animation.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.toElement "section-1"
        |> Scroll.duration 500
        |> Scroll.easing EaseInOutQuad
        |> Scroll.build

-}
easing : Easing -> Builder -> Builder
easing =
    SB.easing
