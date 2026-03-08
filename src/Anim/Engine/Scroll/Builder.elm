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
    import Anim.Engine.Scroll.Builder as Builder
    import Anim.Extra.Easing exposing (Easing(..))

    scrollToElement : String -> Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToElement elementId =
        Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.speed 100
            >> Builder.easing EaseInOut
            >> Builder.build


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

    scrollDocument : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollDocument =
        Builder.forDocument
            >> ... -- Configure and build the animation

-}
forDocument : AnimBuilder -> Builder
forDocument =
    SB.forDocument


{-| Start configuring a scroll animation for a specific container element.

    scrollContainer : String -> Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollContainer containerId =
        Builder.forContainer containerId
            >> ... -- Configure and build the animation

-}
forContainer : String -> AnimBuilder -> Builder
forContainer =
    SB.forContainer


{-| Complete the scroll animation configuration and return an `AnimBuilder`
so you can continue configuring other scroll animations or execute
the animation with the [Scroll Engine](Anim-Engine-Scroll).

    scroll : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scroll =
        Builder.forDocument
            >> ... -- Configure the animation
            >> Builder.build

-}
build : Builder -> AnimBuilder
build =
    SB.build



-- TARGET CONFIGURATION


{-| Scroll to a specific element by ID.

    scrollToElement : String -> Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToElement elementId =
        Builder.forDocument
            >> Builder.toElement elementId
            >> ... -- Configure the animation
            >> Builder.build

-}
toElement : String -> Builder -> Builder
toElement =
    SB.toElement


{-| Scroll to specific X and Y coordinates.

    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.toXY 100 200
            >> Builder.duration 500
            >> Builder.build

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    SB.toXY


{-| Scroll to specific X coordinate only.

    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.toX 100
            >> Builder.duration 500
            >> Builder.build

-}
toX : Float -> Builder -> Builder
toX =
    SB.toX


{-| Scroll to specific Y coordinate only.

    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.toY 200
            >> Builder.duration 500
            >> Builder.build

-}
toY : Float -> Builder -> Builder
toY =
    SB.toY


{-| Scroll to the top of the container.

    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.toTop
            >> Builder.duration 500
            >> Builder.build

-}
toTop : Builder -> Builder
toTop =
    SB.toTop


{-| Scroll to the bottom of the container.

    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.toBottom
            >> Builder.duration 500
            >> Builder.build

-}
toBottom : Builder -> Builder
toBottom =
    SB.toBottom


{-| Scroll to the center of the container.

    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.toCenter
            >> Builder.duration 500
            >> Builder.build

-}
toCenter : Builder -> Builder
toCenter =
    SB.toCenter


{-| Scroll to the left edge of the container.

    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.toLeft
            >> Builder.duration 500
            >> Builder.build

-}
toLeft : Builder -> Builder
toLeft =
    SB.toLeft


{-| Scroll to the right edge of the container.

    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.toRight
            >> Builder.duration 500
            >> Builder.build

-}
toRight : Builder -> Builder
toRight =
    SB.toRight


{-| Scroll to the top-left corner of the container.

    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.toTopLeft
            >> Builder.duration 500
            >> Builder.build

-}
toTopLeft : Builder -> Builder
toTopLeft =
    SB.toTopLeft


{-| Scroll to the top-right corner of the container.

    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.toTopRight
            >> Builder.duration 500
            >> Builder.build

-}
toTopRight : Builder -> Builder
toTopRight =
    SB.toTopRight


{-| Scroll to the bottom-left corner of the container.

    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.toBottomLeft
            >> Builder.duration 500
            >> Builder.build

-}
toBottomLeft : Builder -> Builder
toBottomLeft =
    SB.toBottomLeft


{-| Scroll to the bottom-right corner of the container.

    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.toBottomRight
            >> Builder.duration 500
            >> Builder.build

-}
toBottomRight : Builder -> Builder
toBottomRight =
    SB.toBottomRight


{-| Scroll to percentage of container size.

    -- Scroll to 50% X and 80% Y of the container size.
    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.toPercentageXY 0.5 0.8
            >> Builder.duration 500
            >> Builder.build

-}
toPercentageXY : Float -> Float -> Builder -> Builder
toPercentageXY =
    SB.toPercentageXY


{-| Scroll to percentage of container width (X axis only).

    -- Scroll to 50% of the container width.
    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.toPercentageX 0.5
            >> Builder.duration 500
            >> Builder.build

-}
toPercentageX : Float -> Builder -> Builder
toPercentageX =
    SB.toPercentageX


{-| Scroll to percentage of container height (Y axis only).

    -- Scroll to 80% of the container height.
    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.toPercentageY 0.8
            >> Builder.duration 500
            >> Builder.build

-}
toPercentageY : Float -> Builder -> Builder
toPercentageY =
    SB.toPercentageY


{-| Scroll by a relative amount on both X and Y axes.

Positive values scroll right/down, negative values scroll left/up.

    -- Scroll right 100px and down 200px
    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.byXY 100 200
            >> Builder.duration 500
            >> Builder.build

    -- Scroll left 50px and up 100px
    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.byXY -50 -100
            >> Builder.duration 500
            >> Builder.build

-}
byXY : Float -> Float -> Builder -> Builder
byXY =
    SB.byXY


{-| Scroll by a relative amount on X axis only.

Positive values scroll right, negative values scroll left.

    -- Scroll right 100px
    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.byX 100
            >> Builder.duration 500
            >> Builder.build

-}
byX : Float -> Builder -> Builder
byX =
    SB.byX


{-| Scroll by a relative amount on Y axis only.

Positive values scroll down, negative values scroll up.

    -- Scroll down 200px
    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.byY 200
            >> Builder.duration 500
            >> Builder.build

-}
byY : Float -> Builder -> Builder
byY =
    SB.byY



-- AXIS SELECTION


{-| Scroll on both X and Y axes (default).

    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.onBothAxes
            >> Builder.toElement "section-1"
            >> Builder.speed 500
            >> Builder.build

-}
onBothAxes : Builder -> Builder
onBothAxes =
    SB.onBothAxes


{-| Scroll on X axis only.

    Scroll.toCmd ScrollCompleted <|
        Builder.forContainer "containerId"
            >> Builder.onXAxis
            >> Builder.toX 500
            >> Builder.speed 500
            >> Builder.build

-}
onXAxis : Builder -> Builder
onXAxis =
    SB.onXAxis


{-| Scroll on Y axis only.

    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.onYAxis
            >> Builder.toElement "section-1"
            >> Builder.speed 500
            >> Builder.build

-}
onYAxis : Builder -> Builder
onYAxis =
    SB.onYAxis


{-| Set X and Y scroll offsets.

Offsets are added to the target scroll position. Useful for accounting for
fixed headers or other UI elements.

    -- Scroll to element with 20px X offset and 60px Y offset.
    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.toElement "section-1"
            >> Builder.withOffsetXY 20 60
            >> Builder.speed 500
            >> Builder.build

-}
withOffsetXY : Float -> Float -> Builder -> Builder
withOffsetXY =
    SB.withOffsetXY


{-| Set X scroll offset.

    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.toElement "section-1"
            >> Builder.withOffsetX 20
            >> Builder.speed 500
            >> Builder.build

-}
withOffsetX : Float -> Builder -> Builder
withOffsetX =
    SB.withOffsetX


{-| Set Y scroll offset.

Commonly used to account for fixed headers.

    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.toElement "section-1"
            >> Builder.withOffsetY 60
            >> Builder.speed 500
            >> Builder.build

-}
withOffsetY : Float -> Builder -> Builder
withOffsetY =
    SB.withOffsetY



-- PER-SCROLL TIMING


{-| Set the delay (milliseconds) before this scroll animation starts.

Overrides the global default delay set on the [Scroll Engine](Anim-Engine-Scroll).

    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.toTop
            >> Builder.delay 500
            >> Builder.duration 500
            >> Builder.build

-}
delay : Int -> Builder -> Builder
delay =
    SB.delay


{-| Set the duration (milliseconds) for this scroll animation.

Overrides the global default duration set on the [Scroll Engine](Anim-Engine-Scroll).

    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.toElement "target"
            >> Builder.duration 1000
            >> Builder.build

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| Set the speed (pixels per second) for this scroll animation.

Overrides the global default speed set on the [Scroll Engine](Anim-Engine-Scroll).

    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.toTop
            >> Builder.speed 500
            >> Builder.build

-}
speed : Float -> Builder -> Builder
speed =
    SB.speed



-- PER-SCROLL EASING


{-| Set the easing function for this scroll animation.

Overrides the global default easing set on the [Scroll Engine](Anim-Engine-Scroll).

    Scroll.toCmd ScrollCompleted <|
        Builder.forDocument
            >> Builder.toElement "section-1"
            >> Builder.duration 500
            >> Builder.easing BounceOut
            >> Builder.build

-}
easing : Easing -> Builder -> Builder
easing =
    SB.easing
