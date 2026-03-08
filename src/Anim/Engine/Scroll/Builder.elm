module Anim.Engine.Scroll.Builder exposing
    ( Builder, forDocument, forContainer, build
    , toElement
    , toTop, toBottom, toCenter
    , toLeft, toRight
    , toTopLeft, toTopRight, toBottomLeft, toBottomRight
    , toXY, toX, toY, toPercentageXY, toPercentageX, toPercentageY
    , byXY, byX, byY
    , withOffsetXY, withOffsetX, withOffsetY
    , delay, duration, speed
    , easing
    , onBothAxes, onXAxis, onYAxis
    )

{-| Configure individual scroll animations.

Use this module to define where and how each scroll animation should behave.
The [Scroll Engine](Anim-Engine-Scroll) handles execution and state management,
while this module handles per-scroll configuration.

    import Anim.Engine.Scroll as Scroll
    import Anim.Engine.Scroll.Builder as ScrollTo
    import Anim.Extra.Easing exposing (Easing(..))

    scrollToSection : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToSection =
        ScrollTo.forDocument
            >> ScrollTo.toElement "section-header"
            >> ScrollTo.duration 500
            >> ScrollTo.easing EaseInOut
            >> ScrollTo.build


# Build

@docs Builder, forDocument, forContainer, build


# Element Targeting

@docs toElement


# Position Targeting

@docs toTop, toBottom, toCenter
@docs toLeft, toRight
@docs toTopLeft, toTopRight, toBottomLeft, toBottomRight


# Coordinate Targeting

@docs toXY, toX, toY, toPercentageXY, toPercentageX, toPercentageY


# Relative Scrolling

@docs byXY, byX, byY


# Offsets

@docs withOffsetXY, withOffsetX, withOffsetY


# Timing

@docs delay, duration, speed


# Easing

@docs easing


# Axis Selection

@docs onBothAxes, onXAxis, onYAxis

-}

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Scroll as SB


{-| Type alias for the internal `ScrollBuilder`.
-}
type alias Builder =
    SB.ScrollBuilder


{-| Start configuring a scroll animation for the document body.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.toTop
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
forDocument : AnimBuilder -> Builder
forDocument =
    SB.forDocument


{-| Start configuring a scroll animation for a specific container element.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "container-id"
            >> ScrollTo.toBottom
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
forContainer : String -> AnimBuilder -> Builder
forContainer =
    SB.forContainer


{-| Complete the scroll animation configuration and return an `AnimBuilder`
so you can continue configuring other scroll animations or execute
the animation with the [Scroll Engine](Anim-Engine-Scroll).

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "container"
            >> ScrollTo.toElement "target-id"
            >> ScrollTo.speed 500
            >> ScrollTo.build

-}
build : Builder -> AnimBuilder
build =
    SB.build



-- TARGET CONFIGURATION


{-| Scroll to a specific element by ID.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.toElement "section-header"
            >> ScrollTo.speed 500
            >> ScrollTo.build

-}
toElement : String -> Builder -> Builder
toElement =
    SB.toElement


{-| Scroll to specific X and Y coordinates.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.toXY 100 200
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    SB.toXY


{-| Scroll to specific X coordinate only.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.toX 100
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toX : Float -> Builder -> Builder
toX =
    SB.toX


{-| Scroll to specific Y coordinate only.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.toY 200
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toY : Float -> Builder -> Builder
toY =
    SB.toY


{-| Scroll to the top of the container.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.toTop
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toTop : Builder -> Builder
toTop =
    SB.toTop


{-| Scroll to the bottom of the container.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.toBottom
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toBottom : Builder -> Builder
toBottom =
    SB.toBottom


{-| Scroll to the center of the container.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.toCenter
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toCenter : Builder -> Builder
toCenter =
    SB.toCenter


{-| Scroll to the left edge of the container.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.toLeft
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toLeft : Builder -> Builder
toLeft =
    SB.toLeft


{-| Scroll to the right edge of the container.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.toRight
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toRight : Builder -> Builder
toRight =
    SB.toRight


{-| Scroll to the top-left corner of the container.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.toTopLeft
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toTopLeft : Builder -> Builder
toTopLeft =
    SB.toTopLeft


{-| Scroll to the top-right corner of the container.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.toTopRight
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toTopRight : Builder -> Builder
toTopRight =
    SB.toTopRight


{-| Scroll to the bottom-left corner of the container.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.toBottomLeft
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toBottomLeft : Builder -> Builder
toBottomLeft =
    SB.toBottomLeft


{-| Scroll to the bottom-right corner of the container.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.toBottomRight
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toBottomRight : Builder -> Builder
toBottomRight =
    SB.toBottomRight


{-| Scroll to percentage of container size.

    -- Scroll to 50% X and 80% Y of the container size.
    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.toPercentageXY 0.5 0.8
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toPercentageXY : Float -> Float -> Builder -> Builder
toPercentageXY =
    SB.toPercentageXY


{-| Scroll to percentage of container width (X axis only).

    -- Scroll to 50% of the container width.
    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.toPercentageX 0.5
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toPercentageX : Float -> Builder -> Builder
toPercentageX =
    SB.toPercentageX


{-| Scroll to percentage of container height (Y axis only).

    -- Scroll to 80% of the container height.
    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.toPercentageY 0.8
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
toPercentageY : Float -> Builder -> Builder
toPercentageY =
    SB.toPercentageY


{-| Scroll by a relative amount on both X and Y axes.

Positive values scroll right/down, negative values scroll left/up.

    -- Scroll right 100px and down 200px
    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.byXY 100 200
            >> ScrollTo.duration 500
            >> ScrollTo.build

    -- Scroll left 50px and up 100px
    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.byXY -50 -100
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
byXY : Float -> Float -> Builder -> Builder
byXY =
    SB.byXY


{-| Scroll by a relative amount on X axis only.

Positive values scroll right, negative values scroll left.

    -- Scroll right 100px
    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.byX 100
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
byX : Float -> Builder -> Builder
byX =
    SB.byX


{-| Scroll by a relative amount on Y axis only.

Positive values scroll down, negative values scroll up.

    -- Scroll down 200px
    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.byY 200
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
byY : Float -> Builder -> Builder
byY =
    SB.byY



-- AXIS SELECTION


{-| Scroll on both X and Y axes (default).

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.onBothAxes
            >> ScrollTo.toElement "section-1"
            >> ScrollTo.speed 500
            >> ScrollTo.build

-}
onBothAxes : Builder -> Builder
onBothAxes =
    SB.onBothAxes


{-| Scroll on X axis only.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forContainer "containerId"
            >> ScrollTo.onXAxis
            >> ScrollTo.toX 500
            >> ScrollTo.speed 500
            >> ScrollTo.build

-}
onXAxis : Builder -> Builder
onXAxis =
    SB.onXAxis


{-| Scroll on Y axis only.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.onYAxis
            >> ScrollTo.toElement "section-1"
            >> ScrollTo.speed 500
            >> ScrollTo.build

-}
onYAxis : Builder -> Builder
onYAxis =
    SB.onYAxis


{-| Set X and Y scroll offsets.

Offsets are added to the target scroll position. Useful for accounting for
fixed headers or other UI elements.

    -- Scroll to element with 20px X offset and 60px Y offset.
    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.toElement "section-1"
            >> ScrollTo.withOffsetXY 20 60
            >> ScrollTo.speed 500
            >> ScrollTo.build

-}
withOffsetXY : Float -> Float -> Builder -> Builder
withOffsetXY =
    SB.withOffsetXY


{-| Set X scroll offset.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.toElement "section-1"
            >> ScrollTo.withOffsetX 20
            >> ScrollTo.speed 500
            >> ScrollTo.build

-}
withOffsetX : Float -> Builder -> Builder
withOffsetX =
    SB.withOffsetX


{-| Set Y scroll offset.

Commonly used to account for fixed headers.

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.toElement "section-1"
            >> ScrollTo.withOffsetY 60
            >> ScrollTo.speed 500
            >> ScrollTo.build

-}
withOffsetY : Float -> Builder -> Builder
withOffsetY =
    SB.withOffsetY



-- PER-SCROLL TIMING


{-| Set the delay (milliseconds) before this scroll animation starts.

Overrides the global default delay set on the [Scroll Engine](Anim-Engine-Scroll).

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.toTop
            >> ScrollTo.delay 500
            >> ScrollTo.duration 500
            >> ScrollTo.build

-}
delay : Int -> Builder -> Builder
delay =
    SB.delay


{-| Set the duration (milliseconds) for this scroll animation.

Overrides the global default duration set on the [Scroll Engine](Anim-Engine-Scroll).

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.toElement "target"
            >> ScrollTo.duration 1000
            >> ScrollTo.build

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| Set the speed (pixels per second) for this scroll animation.

Overrides the global default speed set on the [Scroll Engine](Anim-Engine-Scroll).

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.toTop
            >> ScrollTo.speed 500
            >> ScrollTo.build

-}
speed : Float -> Builder -> Builder
speed =
    SB.speed



-- PER-SCROLL EASING


{-| Set the easing function for this scroll animation.

Overrides the global default easing set on the [Scroll Engine](Anim-Engine-Scroll).

    Scroll.toCmd ScrollCompleted <|
        ScrollTo.forDocument
            >> ScrollTo.toElement "section-1"
            >> ScrollTo.duration 500
            >> ScrollTo.easing BounceOut
            >> ScrollTo.build

-}
easing : Easing -> Builder -> Builder
easing =
    SB.easing
