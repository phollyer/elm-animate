module Anim.Action.Scroll exposing
    ( Builder, for, forDocument, forContainer, build
    , toElement
    , toTop, toBottom, toCenter
    , toLeft, toRight
    , toTopLeft, toTopRight, toBottomLeft, toBottomRight
    , toXY, toX, toY, toCoordinates, toPercentage
    , onBothAxes, onXAxis, onYAxis
    , onBothAxesWithOffset, onXAxisWithOffset, onYAxisWithOffset
    , delay, duration, speed
    , easing
    )

{-| Scroll animation functions for document and container scrolling.

Use these functions to configure scroll animations in the builder chain:

    import Anim.Engine.Scroll as Scroll
    import Anim.Action.Scroll as ScrollAction

    Scroll.init
        |> Scroll.builder
        |> Scroll.speed 500  -- global default
        |> ScrollAction.for "document"
        |> ScrollAction.toElement "section-1"
        |> ScrollAction.onYAxisWithOffset 60
        |> ScrollAction.build
        |> Scroll.animate ScrollMsg

You can chain multiple scroll targets with different containers:

    Scroll.init
        |> Scroll.builder
        |> Scroll.easing EaseInOut
        -- global default
        |> ScrollAction.for "container-1"
        |> ScrollAction.toElement "target-1"
        |> ScrollAction.speed 800
        -- override for this scroll
        |> ScrollAction.build
        |> ScrollAction.for "document"
        |> ScrollAction.toTop
        |> ScrollAction.duration 1000
        -- different timing
        |> ScrollAction.build
        |> Scroll.toCmd ScrollCompleted


# Build

@docs Builder, for, forDocument, forContainer, build


# Targeting


## Element Targeting

@docs toElement


## Position Targeting

@docs toTop, toBottom, toCenter
@docs toLeft, toRight
@docs toTopLeft, toTopRight, toBottomLeft, toBottomRight


## Coordinate Targeting

@docs toXY, toX, toY, toCoordinates, toPercentage


# Axis Selection

@docs onBothAxes, onXAxis, onYAxis


## With Offsets

@docs onBothAxesWithOffset, onXAxisWithOffset, onYAxisWithOffset


# Timing

These override global timing settings for this specific scroll.

@docs delay, duration, speed


# Easing

This overrides the global easing setting for this specific scroll.

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


{-| Start configuring a scroll animation for a specific container.

Use "document" for document body scrolling:

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toTop
        |> Scroll.build

Or use an element ID for container scrolling:

    animBuilder
        |> Scroll.for "my-scrollable-container"
        |> Scroll.toElement "target"
        |> Scroll.build

-}
for : String -> AnimBuilder -> Builder
for =
    SB.for


{-| Start configuring a scroll animation for the document body.

Type-safe alternative to `for "document"`.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.toTop
        |> Scroll.build

-}
forDocument : AnimBuilder -> Builder
forDocument =
    SB.forDocument


{-| Start configuring a scroll animation for a specific container element.

Type-safe alternative to `for "container-id"`.

    animBuilder
        |> Scroll.forContainer "my-scrollable-container"
        |> Scroll.toElement "target"
        |> Scroll.build

-}
forContainer : String -> AnimBuilder -> Builder
forContainer =
    SB.forContainer


{-| Complete the scroll configuration and return to AnimBuilder.

    animBuilder
        |> Scroll.forContainer "container"
        |> Scroll.toElement "target"
        |> Scroll.speed 500
        |> Scroll.build  -- Returns AnimBuilder
        |> ... -- Continue with more animations or execute

-}
build : Builder -> AnimBuilder
build =
    SB.build



-- TARGET CONFIGURATION


{-| Scroll to a specific element by ID.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toElement "section-header"
        |> Scroll.build

-}
toElement : String -> Builder -> Builder
toElement =
    SB.toElement


{-| Scroll to specific X and Y coordinates.

    animBuilder
        |> Scroll.for "container"
        |> Scroll.toXY 100 200
        |> Scroll.build

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    SB.toXY


{-| Scroll to specific X coordinate only.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toX 100
        |> Scroll.build

-}
toX : Float -> Builder -> Builder
toX =
    SB.toX


{-| Scroll to specific Y coordinate only.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toY 200
        |> Scroll.build

-}
toY : Float -> Builder -> Builder
toY =
    SB.toY


{-| Scroll to the top of the container.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toTop
        |> Scroll.build

-}
toTop : Builder -> Builder
toTop =
    SB.toTop


{-| Scroll to the bottom of the container.

    animBuilder
        |> Scroll.for "container"
        |> Scroll.toBottom
        |> Scroll.build

-}
toBottom : Builder -> Builder
toBottom =
    SB.toBottom


{-| Scroll to the center of the container.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toCenter
        |> Scroll.build

-}
toCenter : Builder -> Builder
toCenter =
    SB.toCenter


{-| Scroll to the left edge of the container.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toLeft
        |> Scroll.build

-}
toLeft : Builder -> Builder
toLeft =
    SB.toLeft


{-| Scroll to the right edge of the container.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toRight
        |> Scroll.build

-}
toRight : Builder -> Builder
toRight =
    SB.toRight


{-| Scroll to the top-left corner of the container.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toTopLeft
        |> Scroll.build

-}
toTopLeft : Builder -> Builder
toTopLeft =
    SB.toTopLeft


{-| Scroll to the top-right corner of the container.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toTopRight
        |> Scroll.build

-}
toTopRight : Builder -> Builder
toTopRight =
    SB.toTopRight


{-| Scroll to the bottom-left corner of the container.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toBottomLeft
        |> Scroll.build

-}
toBottomLeft : Builder -> Builder
toBottomLeft =
    SB.toBottomLeft


{-| Scroll to the bottom-right corner of the container.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toBottomRight
        |> Scroll.build

-}
toBottomRight : Builder -> Builder
toBottomRight =
    SB.toBottomRight


{-| Scroll to specific coordinates.

    animBuilder
        |> Scroll.for "container"
        |> Scroll.toCoordinates 150 300
        |> Scroll.build

-}
toCoordinates : Float -> Float -> Builder -> Builder
toCoordinates =
    SB.toCoordinates


{-| Scroll to percentage of container size.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toPercentage 0.5 0.8
        -- 50% width, 80% height
        |> Scroll.build

-}
toPercentage : Float -> Float -> Builder -> Builder
toPercentage =
    SB.toPercentage



-- AXIS SELECTION


{-| Scroll on both X and Y axes (default).

    animBuilder
        |> Scroll.for "document"
        |> Scroll.onBothAxes
        |> Scroll.toElement "section-1"
        |> Scroll.build

-}
onBothAxes : Builder -> Builder
onBothAxes =
    SB.onBothAxes


{-| Scroll on X axis only.

    animBuilder
        |> Scroll.for "container"
        |> Scroll.onXAxis
        |> Scroll.toX 500
        |> Scroll.build

-}
onXAxis : Builder -> Builder
onXAxis =
    SB.onXAxis


{-| Scroll on Y axis only.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.onYAxis
        |> Scroll.toElement "section-1"
        |> Scroll.build

-}
onYAxis : Builder -> Builder
onYAxis =
    SB.onYAxis


{-| Scroll on both axes with offsets.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.onBothAxesWithOffset 20 60
        |> Scroll.toElement "section-1"
        |> Scroll.build

-}
onBothAxesWithOffset : Float -> Float -> Builder -> Builder
onBothAxesWithOffset =
    SB.onBothAxesWithOffset


{-| Scroll on X axis with offset.

    animBuilder
        |> Scroll.for "container"
        |> Scroll.onXAxisWithOffset 60
        |> Scroll.toElement "section-1"
        |> Scroll.build

-}
onXAxisWithOffset : Float -> Builder -> Builder
onXAxisWithOffset =
    SB.onXAxisWithOffset


{-| Scroll on Y axis with offset.

    animBuilder
        |> Scroll.for "document"
        |> Scroll.onYAxisWithOffset 60
        |> Scroll.toElement "section-1"
        |> Scroll.build

-}
onYAxisWithOffset : Float -> Builder -> Builder
onYAxisWithOffset =
    SB.onYAxisWithOffset



-- TIMING


{-| Set delay before this scroll animation starts (overrides global).

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toTop
        |> Scroll.delay 500
        |> Scroll.build

-}
delay : Int -> Builder -> Builder
delay =
    SB.delay


{-| Set duration for this scroll animation (overrides global).

    animBuilder
        |> Scroll.for "container"
        |> Scroll.toElement "target"
        |> Scroll.duration 1000
        |> Scroll.build

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| Set speed for this scroll animation (overrides global).

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toTop
        |> Scroll.speed 500
        |> Scroll.build

-}
speed : Float -> Builder -> Builder
speed =
    SB.speed



-- EASING


{-| Set easing function for this scroll animation (overrides global).

    animBuilder
        |> Scroll.for "document"
        |> Scroll.toElement "section-1"
        |> Scroll.easing EaseInOutQuad
        |> Scroll.build

-}
easing : Easing -> Builder -> Builder
easing =
    SB.easing
