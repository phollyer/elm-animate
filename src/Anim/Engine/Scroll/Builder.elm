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

    scrollToCoordinates : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToCoordinates =
        Builder.forContainer "containerId"
            >> Builder.toXY 100 200
            >> ... -- Configure the animation
            >> Builder.build

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    SB.toXY


{-| Scroll to specific X coordinate only.

    scrollToX : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToX =
        Builder.forDocument
            >> Builder.toX 100
            >> ... -- Configure the animation
            >> Builder.build

-}
toX : Float -> Builder -> Builder
toX =
    SB.toX


{-| Scroll to specific Y coordinate only.

    scrollToY : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToY =
        Builder.forDocument
            >> Builder.toY 200
            >> ... -- Configure the animation
            >> Builder.build

-}
toY : Float -> Builder -> Builder
toY =
    SB.toY


{-| Scroll to the top of the container.

    scrollToTop : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToTop =
        Builder.forDocument
            >> Builder.toTop
            >> ... -- Configure the animation
            >> Builder.build

-}
toTop : Builder -> Builder
toTop =
    SB.toTop


{-| Scroll to the bottom of the container.

    scrollToBottom : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToBottom =
        Builder.forContainer "containerId"
            >> Builder.toBottom
            >> ... -- Configure the animation
            >> Builder.build

-}
toBottom : Builder -> Builder
toBottom =
    SB.toBottom


{-| Scroll to the center of the container.

    scrollToCenter : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToCenter =
        Builder.forContainer "containerId"
            >> Builder.toCenter
            >> ... -- Configure the animation
            >> Builder.build

-}
toCenter : Builder -> Builder
toCenter =
    SB.toCenter


{-| Scroll to the left edge of the container.

    scrollToLeft : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToLeft =
        Builder.forContainer "containerId"
            >> Builder.toLeft
            >> ... -- Configure the animation
            >> Builder.build

-}
toLeft : Builder -> Builder
toLeft =
    SB.toLeft


{-| Scroll to the right edge of the container.

    scrollToRight : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToRight =
        Builder.forContainer "containerId"
            >> Builder.toRight
            >> ... -- Configure the animation
            >> Builder.build

-}
toRight : Builder -> Builder
toRight =
    SB.toRight


{-| Scroll to the top-left corner of the container.

    scrollToTopLeft : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToTopLeft =
        Builder.forContainer "containerId"
            >> Builder.toTopLeft
            >> ... -- Configure the animation
            >> Builder.build

-}
toTopLeft : Builder -> Builder
toTopLeft =
    SB.toTopLeft


{-| Scroll to the top-right corner of the container.

    scrollToTopRight : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToTopRight =
        Builder.forContainer "containerId"
            >> Builder.toTopRight
            >> ... -- Configure the animation
            >> Builder.build

-}
toTopRight : Builder -> Builder
toTopRight =
    SB.toTopRight


{-| Scroll to the bottom-left corner of the container.

    scrollToBottomLeft : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToBottomLeft =
        Builder.forContainer "containerId"
            >> Builder.toBottomLeft
            >> ... -- Configure the animation
            >> Builder.build

-}
toBottomLeft : Builder -> Builder
toBottomLeft =
    SB.toBottomLeft


{-| Scroll to the bottom-right corner of the container.

    scrollToBottomRight : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToBottomRight =
        Builder.forContainer "containerId"
            >> Builder.toBottomRight
            >> ... -- Configure the animation
            >> Builder.build

-}
toBottomRight : Builder -> Builder
toBottomRight =
    SB.toBottomRight


{-| Scroll to percentage of container size.

    scrollToPercentage : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToPercentage =
        Builder.forContainer "containerId"
            >> Builder.toPercentageXY 0.5 0.8
            >> ... -- Configure the animation
            >> Builder.build

-}
toPercentageXY : Float -> Float -> Builder -> Builder
toPercentageXY =
    SB.toPercentageXY


{-| Scroll to percentage of container width (X axis only).

    scrollToPercentageX : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToPercentageX =
        Builder.forContainer "containerId"
            >> Builder.toPercentageX 0.5
            >> ... -- Configure the animation
            >> Builder.build

-}
toPercentageX : Float -> Builder -> Builder
toPercentageX =
    SB.toPercentageX


{-| Scroll to percentage of container height (Y axis only).

    scrollToPercentageY : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollToPercentageY =
        Builder.forContainer "containerId"
            >> Builder.toPercentageY 0.8
            >> ... -- Configure the animation
            >> Builder.build

-}
toPercentageY : Float -> Builder -> Builder
toPercentageY =
    SB.toPercentageY


{-| Scroll by a relative amount on both X and Y axes.

Positive values scroll right/down, negative values scroll left/up.

    scrollByXY : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollByXY =
        Builder.forDocument
            >> Builder.byXY 100 200
            >> ... -- Configure the animation
            >> Builder.build

-}
byXY : Float -> Float -> Builder -> Builder
byXY =
    SB.byXY


{-| Scroll by a relative amount on X axis only.

Positive values scroll right, negative values scroll left.

    scrollByX : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollByX =
        Builder.forDocument
            >> Builder.byX 100
            >> ... -- Configure the animation
            >> Builder.build

-}
byX : Float -> Builder -> Builder
byX =
    SB.byX


{-| Scroll by a relative amount on Y axis only.

Positive values scroll down, negative values scroll up.

    scrollByY : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollByY =
        Builder.forDocument
            >> Builder.byY 200
            >> ... -- Configure the animation
            >> Builder.build

-}
byY : Float -> Builder -> Builder
byY =
    SB.byY



-- AXIS SELECTION


{-| Scroll on both X and Y axes (default).

    scrollBothAxes : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollBothAxes =
        Builder.forContainer "containerId"
            >> Builder.onBothAxes
            >> Builder.toElement "section-1"
            >> ... -- Configure the animation
            >> Builder.build

-}
onBothAxes : Builder -> Builder
onBothAxes =
    SB.onBothAxes


{-| Scroll on X axis only.

    scrollXOnly : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollXOnly =
        Builder.forContainer "containerId"
            >> Builder.onXAxis
            >> Builder.toX 500
            >> ... -- Configure the animation
            >> Builder.build

-}
onXAxis : Builder -> Builder
onXAxis =
    SB.onXAxis


{-| Scroll on Y axis only.

    scrollYOnly : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollYOnly =
        Builder.forDocument
            >> Builder.onYAxis
            >> Builder.toElement "section-1"
            >> ... -- Configure the animation
            >> Builder.build

-}
onYAxis : Builder -> Builder
onYAxis =
    SB.onYAxis


{-| Set X and Y scroll offsets.

Offsets are added to the target scroll position. Useful for accounting for
fixed headers or other UI elements.

    scrollWithOffset : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollWithOffset =
        Builder.forDocument
            >> Builder.toElement "section-1"
            >> Builder.withOffsetXY 20 60
            >> ... -- Configure the animation
            >> Builder.build

-}
withOffsetXY : Float -> Float -> Builder -> Builder
withOffsetXY =
    SB.withOffsetXY


{-| Set X scroll offset.

    scrollWithOffsetX : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollWithOffsetX =
        Builder.forDocument
            >> Builder.toElement "section-1"
            >> Builder.withOffsetX 20
            >> ... -- Configure the animation
            >> Builder.build

-}
withOffsetX : Float -> Builder -> Builder
withOffsetX =
    SB.withOffsetX


{-| Set Y scroll offset.

Commonly used to account for fixed headers.

    scrollWithOffsetY : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollWithOffsetY =
        Builder.forDocument
            >> Builder.toElement "section-1"
            >> Builder.withOffsetY 60
            >> ... -- Configure the animation
            >> Builder.build

-}
withOffsetY : Float -> Builder -> Builder
withOffsetY =
    SB.withOffsetY



-- PER-SCROLL TIMING


{-| Set the delay (milliseconds) before this scroll animation starts.

Overrides the global default delay set on the [Scroll Engine](Anim-Engine-Scroll).

    scrollAfterDelay : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollAfterDelay =
        Builder.forDocument
            >> Builder.toTop
            >> Builder.delay 500
            >> ... -- Configure the animation
            >> Builder.build

-}
delay : Int -> Builder -> Builder
delay =
    SB.delay


{-| Set the duration (milliseconds) for this scroll animation.

Overrides the global default duration set on the [Scroll Engine](Anim-Engine-Scroll).

    scrollWithDuration : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollWithDuration =
        Builder.forDocument
            >> Builder.toElement "target"
            >> Builder.duration 1000
            >> ... -- Configure the animation
            >> Builder.build

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| Set the speed (pixels per second) for this scroll animation.

Overrides the global default speed set on the [Scroll Engine](Anim-Engine-Scroll).

    scrollWithSpeed : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollWithSpeed =
        Builder.forDocument
            >> Builder.toTop
            >> Builder.speed 500
            >> ... -- Configure the animation
            >> Builder.build

-}
speed : Float -> Builder -> Builder
speed =
    SB.speed



-- PER-SCROLL EASING


{-| Set the easing function for this scroll animation.

Overrides the global default easing set on the [Scroll Engine](Anim-Engine-Scroll).

    scrollWithEasing : Scroll.AnimBuilder -> Scroll.AnimBuilder
    scrollWithEasing =
        Builder.forDocument
            >> Builder.toElement "section-1"
            >> Builder.easing BounceOut
            >> ... -- Configure the animation
            >> Builder.build

-}
easing : Easing -> Builder -> Builder
easing =
    SB.easing
