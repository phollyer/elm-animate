module Scroll.Builder exposing
    ( ScrollBuilder, Builder, forDocument, forContainer, build
    , delay, duration, speed
    , easing
    , toElement
    , toCenter
    , toTop, toBottom, toLeft, toRight
    , toTopLeft, toTopRight, toBottomLeft, toBottomRight
    , toXY, toX, toY
    , toPercentageXY, toPercentageX, toPercentageY
    , byXY, byX, byY
    , withOffsetXY, withOffsetX, withOffsetY
    , onBothAxes, onXAxis, onYAxis
    )

{-| Configure individual scroll animations.

Use this module to define where and how each scroll animation should behave.
The Scroll engine modules ([Cmd](Scroll-Engine-Cmd), [Task](Scroll-Engine-Task),
[Sub](Scroll-Engine-Sub)) handle execution, while this module handles per-scroll configuration.

    import Easing exposing (Easing(..))
    import Scroll.Builder as Scroll exposing (ScrollBuilder)

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Scroll.forDocument
            >> Scroll.toElement elementId
            >> Scroll.speed 100
            >> Scroll.easing EaseInOut
            >> Scroll.build

📖 See [Scroll Overview](https://phollyer.github.io/elm-motion/engines/scroll/overview/) section in the docs.


# Build

@docs ScrollBuilder, Builder, forDocument, forContainer, build


# Timing

@docs delay, duration, speed


# Easing

@docs easing


# Element Targeting

@docs toElement

📖 See [Scroll to Element](https://phollyer.github.io/elm-motion/engines/scroll/overview/#scroll-to-element) in the docs.


# Position Targeting

@docs toCenter


## Edges

@docs toTop, toBottom, toLeft, toRight


## Corners

@docs toTopLeft, toTopRight, toBottomLeft, toBottomRight

📖 See [Scroll to Position](https://phollyer.github.io/elm-motion/engines/scroll/overview/#scroll-to-position) in the docs.


# Coordinate Targeting


## Axes

@docs toXY, toX, toY

## Percentages

@docs toPercentageXY, toPercentageX, toPercentageY


## Relative Scrolling

@docs byXY, byX, byY


# Offsets

@docs withOffsetXY, withOffsetX, withOffsetY

📖 See [Offset](https://phollyer.github.io/elm-motion/engines/scroll/overview/#offset) in the docs.


# Axis Selection

Use axis selection when you want to lock one direction and scroll
in the other. Primarily for scrolling containers whose overflow is
scrollable in both directions but you only want to scroll in one direction.

@docs onBothAxes, onXAxis, onYAxis

📖 See [Axis](https://phollyer.github.io/elm-motion/engines/scroll/overview/#axis) in the docs.

-}

import Motion.Easing exposing (Easing)
import Scroll.Internal.ScrollBuilder as Internal exposing (ScrollBuilder)



-- ============================================================
-- TYPES
-- ============================================================


{-| The builder type for configuring scrolls.
-}
type alias ScrollBuilder =
    Internal.ScrollBuilder


{-| Type alias for the internal `Builder`.
-}
type alias Builder =
    Internal.Builder



-- ============================================================
-- BUILD
-- ============================================================


{-| Start configuring a scroll animation for the document body.

    import Scroll.Builder as Scroll

    scrollDocument : ScrollBuilder -> ScrollBuilder
    scrollDocument =
        Scroll.forDocument
            >> ... -- Configure and build the animation

-}
forDocument : ScrollBuilder -> Builder
forDocument =
    Internal.forDocument


{-| Start configuring a scroll animation for a specific container element.

    import Scroll.Builder as Scroll

    scrollContainer : String -> ScrollBuilder -> ScrollBuilder
    scrollContainer containerId =
        Scroll.forContainer containerId
            >> ... -- Configure and build the animation

-}
forContainer : String -> ScrollBuilder -> Builder
forContainer =
    Internal.forContainer


{-| Complete the scroll animation configuration and return a `ScrollBuilder`
so you can continue configuring other scroll animations or execute
the animation with a Scroll Engine.

    import Scroll.Builder as Scroll

    scrollDocument : ScrollBuilder -> ScrollBuilder
    scrollDocument =
        Scroll.forDocument
            >> ... -- Configure the animation
            >> Scroll.build

-}
build : Builder -> ScrollBuilder
build =
    Internal.build



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before this scroll animation starts.

Overrides the global default delay set on a Scroll Engine.

    import Scroll.Builder as Scroll

    scrollAfterDelay : ScrollBuilder -> ScrollBuilder
    scrollAfterDelay =
        Scroll.forDocument
            >> Scroll.toTop
            >> Scroll.delay 500
            >> ... -- Configure the animation
            >> Scroll.build

-}
delay : Int -> Builder -> Builder
delay =
    Internal.delay


{-| Set the duration (milliseconds) for this scroll animation.

Overrides the global default duration (or speed) set on a Scroll Engine.

    import Scroll.Builder as Scroll

    scrollWithDuration : ScrollBuilder -> ScrollBuilder
    scrollWithDuration =
        Scroll.forDocument
            >> Scroll.toElement "target"
            >> Scroll.duration 1000
            >> ... -- Configure the animation
            >> Scroll.build

-}
duration : Int -> Builder -> Builder
duration =
    Internal.duration


{-| Set the speed (pixels per second) for this scroll animation.

Overrides the global default speed (or duration) set on a Scroll Engine.

    import Scroll.Builder as Scroll

    scrollWithSpeed : ScrollBuilder -> ScrollBuilder
    scrollWithSpeed =
        Scroll.forDocument
            >> Scroll.toTop
            >> Scroll.speed 500
            >> ... -- Configure the animation
            >> Scroll.build

-}
speed : Float -> Builder -> Builder
speed =
    Internal.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for this scroll animation.

Overrides the global default easing set on a Scroll Engine.

    import Easing exposing (Easing(..))
    import Scroll.Builder as Scroll

    scrollWithEasing : ScrollBuilder -> ScrollBuilder
    scrollWithEasing =
        Scroll.forDocument
            >> Scroll.toElement "section-1"
            >> Scroll.easing BounceOut
            >> ... -- Configure the animation
            >> Scroll.build

-}
easing : Easing -> Builder -> Builder
easing =
    Internal.easing



-- ============================================================
-- TARGETING
-- ============================================================
--
--
-- ============================
-- ELEMENT
-- ============================


{-| Scroll to a specific element by ID.

    import Scroll.Builder as Scroll

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Scroll.forDocument
            >> Scroll.toElement elementId
            >> ... -- Configure the animation
            >> Scroll.build

-}
toElement : String -> Builder -> Builder
toElement =
    Internal.toElement



-- ============================
-- CENTER
-- ============================


{-| Scroll to the center of the container.

    import Scroll.Builder as Scroll

    scrollToCenter : ScrollBuilder -> ScrollBuilder
    scrollToCenter =
        Scroll.forContainer "containerId"
            >> Scroll.toCenter
            >> ... -- Configure the animation
            >> Scroll.build

-}
toCenter : Builder -> Builder
toCenter =
    Internal.toCenter



-- ============================
-- EDGES
-- ============================


{-| Scroll to the bottom of the container.

    import Scroll.Builder as Scroll

    scrollToBottom : ScrollBuilder -> ScrollBuilder
    scrollToBottom =
        Scroll.forContainer "containerId"
            >> Scroll.toBottom
            >> ... -- Configure the animation
            >> Scroll.build

-}
toBottom : Builder -> Builder
toBottom =
    Internal.toBottom


{-| Scroll to the left edge of the container.

    import Scroll.Builder as Scroll

    scrollToLeft : ScrollBuilder -> ScrollBuilder
    scrollToLeft =
        Scroll.forContainer "containerId"
            >> Scroll.toLeft
            >> ... -- Configure the animation
            >> Scroll.build

-}
toLeft : Builder -> Builder
toLeft =
    Internal.toLeft


{-| Scroll to the right edge of the container.

    import Scroll.Builder as Scroll

    scrollToRight : ScrollBuilder -> ScrollBuilder
    scrollToRight =
        Scroll.forContainer "containerId"
            >> Scroll.toRight
            >> ... -- Configure the animation
            >> Scroll.build

-}
toRight : Builder -> Builder
toRight =
    Internal.toRight


{-| Scroll to the top of the container.

    import Scroll.Builder as Scroll

    scrollToTop : ScrollBuilder -> ScrollBuilder
    scrollToTop =
        Scroll.forDocument
            >> Scroll.toTop
            >> ... -- Configure the animation
            >> Scroll.build

-}
toTop : Builder -> Builder
toTop =
    Internal.toTop



-- ============================
-- CORNERS
-- ============================


{-| Scroll to the bottom-left corner of the container.

    import Scroll.Builder as Scroll

    scrollToBottomLeft : ScrollBuilder -> ScrollBuilder
    scrollToBottomLeft =
        Scroll.forContainer "containerId"
            >> Scroll.toBottomLeft
            >> ... -- Configure the animation
            >> Scroll.build

-}
toBottomLeft : Builder -> Builder
toBottomLeft =
    Internal.toBottomLeft


{-| Scroll to the bottom-right corner of the container.

    import Scroll.Builder as Scroll

    scrollToBottomRight : ScrollBuilder -> ScrollBuilder
    scrollToBottomRight =
        Scroll.forContainer "containerId"
            >> Scroll.toBottomRight
            >> ... -- Configure the animation
            >> Scroll.build

-}
toBottomRight : Builder -> Builder
toBottomRight =
    Internal.toBottomRight


{-| Scroll to the top-left corner of the container.

    import Scroll.Builder as Scroll

    scrollToTopLeft : ScrollBuilder -> ScrollBuilder
    scrollToTopLeft =
        Scroll.forContainer "containerId"
            >> Scroll.toTopLeft
            >> ... -- Configure the animation
            >> Scroll.build

-}
toTopLeft : Builder -> Builder
toTopLeft =
    Internal.toTopLeft


{-| Scroll to the top-right corner of the container.

    import Scroll.Builder as Scroll

    scrollToTopRight : ScrollBuilder -> ScrollBuilder
    scrollToTopRight =
        Scroll.forContainer "containerId"
            >> Scroll.toTopRight
            >> ... -- Configure the animation
            >> Scroll.build

-}
toTopRight : Builder -> Builder
toTopRight =
    Internal.toTopRight



-- ============================
-- AXES
-- ============================


{-| Scroll to specific X coordinate only.

    import Scroll.Builder as Scroll

    scrollToX : ScrollBuilder -> ScrollBuilder
    scrollToX =
        Scroll.forDocument
            >> Scroll.toX 100
            >> ... -- Configure the animation
            >> Scroll.build

-}
toX : Float -> Builder -> Builder
toX =
    Internal.toX


{-| Scroll to specific Y coordinate only.

    import Scroll.Builder as Scroll

    scrollToY : ScrollBuilder -> ScrollBuilder
    scrollToY =
        Scroll.forDocument
            >> Scroll.toY 200
            >> ... -- Configure the animation
            >> Scroll.build

-}
toY : Float -> Builder -> Builder
toY =
    Internal.toY


{-| Scroll to specific X and Y coordinates.

    import Scroll.Builder as Scroll

    scrollToCoordinates : ScrollBuilder -> ScrollBuilder
    scrollToCoordinates =
        Scroll.forContainer "containerId"
            >> Scroll.toXY 100 200
            >> ... -- Configure the animation
            >> Scroll.build

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    Internal.toXY



-- ============================
-- PERCENTAGES
-- ============================


{-| Scroll to percentage of container size.

    import Scroll.Builder as Scroll

    scrollToPercentage : ScrollBuilder -> ScrollBuilder
    scrollToPercentage =
        Scroll.forContainer "containerId"
            >> Scroll.toPercentageXY 0.5 0.8
            >> ... -- Configure the animation
            >> Scroll.build

-}
toPercentageXY : Float -> Float -> Builder -> Builder
toPercentageXY =
    Internal.toPercentageXY


{-| Scroll to percentage of container width (X axis only).

    import Scroll.Builder as Scroll

    scrollToPercentageX : ScrollBuilder -> ScrollBuilder
    scrollToPercentageX =
        Scroll.forContainer "containerId"
            >> Scroll.toPercentageX 0.5
            >> ... -- Configure the animation
            >> Scroll.build

-}
toPercentageX : Float -> Builder -> Builder
toPercentageX =
    Internal.toPercentageX


{-| Scroll to percentage of container height (Y axis only).

    import Scroll.Builder as Scroll

    scrollToPercentageY : ScrollBuilder -> ScrollBuilder
    scrollToPercentageY =
        Scroll.forContainer "containerId"
            >> Scroll.toPercentageY 0.8
            >> ... -- Configure the animation
            >> Scroll.build

-}
toPercentageY : Float -> Builder -> Builder
toPercentageY =
    Internal.toPercentageY



-- ============================
-- DELTAS
-- ============================


{-| Scroll by a relative amount on both X and Y axes.

Positive values scroll right/down, negative values scroll left/up.

    import Scroll.Builder as Scroll

    scrollByXY : ScrollBuilder -> ScrollBuilder
    scrollByXY =
        Scroll.forDocument
            >> Scroll.byXY 100 200
            >> ... -- Configure the animation
            >> Scroll.build

-}
byXY : Float -> Float -> Builder -> Builder
byXY =
    Internal.byXY


{-| Scroll by a relative amount on X axis only.

Positive values scroll right, negative values scroll left.

    import Scroll.Builder as Scroll

    scrollByX : ScrollBuilder -> ScrollBuilder
    scrollByX =
        Scroll.forDocument
            >> Scroll.byX 100
            >> ... -- Configure the animation
            >> Scroll.build

-}
byX : Float -> Builder -> Builder
byX =
    Internal.byX


{-| Scroll by a relative amount on Y axis only.

Positive values scroll down, negative values scroll up.

    import Scroll.Builder as Scroll

    scrollByY : ScrollBuilder -> ScrollBuilder
    scrollByY =
        Scroll.forDocument
            >> Scroll.byY 200
            >> ... -- Configure the animation
            >> Scroll.build

-}
byY : Float -> Builder -> Builder
byY =
    Internal.byY



-- ============================================================
-- OFFSETS
-- ============================================================


{-| Set X and Y scroll offsets.

Offsets are added to the target scroll position. Useful for accounting for
fixed headers or other UI elements.

    import Scroll.Builder as Scroll

    scrollWithOffset : ScrollBuilder -> ScrollBuilder
    scrollWithOffset =
        Scroll.forDocument
            >> Scroll.toElement "section-1"
            >> Scroll.withOffsetXY 20 60
            >> ... -- Configure the animation
            >> Scroll.build

-}
withOffsetXY : Float -> Float -> Builder -> Builder
withOffsetXY =
    Internal.withOffsetXY


{-| Set X scroll offset.

    import Scroll.Builder as Scroll

    scrollWithOffsetX : ScrollBuilder -> ScrollBuilder
    scrollWithOffsetX =
        Scroll.forDocument
            >> Scroll.toElement "section-1"
            >> Scroll.withOffsetX 20
            >> ... -- Configure the animation
            >> Scroll.build

-}
withOffsetX : Float -> Builder -> Builder
withOffsetX =
    Internal.withOffsetX


{-| Set Y scroll offset.

Commonly used to account for fixed headers.

    import Scroll.Builder as Scroll

    scrollWithOffsetY : ScrollBuilder -> ScrollBuilder
    scrollWithOffsetY =
        Scroll.forDocument
            >> Scroll.toElement "section-1"
            >> Scroll.withOffsetY 60
            >> ... -- Configure the animation
            >> Scroll.build

-}
withOffsetY : Float -> Builder -> Builder
withOffsetY =
    Internal.withOffsetY



-- ============================================================
-- AXIS SELECTION
-- ============================================================


{-| Scroll on both X and Y axes (default).

    import Scroll.Builder as Scroll

    scrollBothAxes : ScrollBuilder -> ScrollBuilder
    scrollBothAxes =
        Scroll.forContainer "containerId"
            >> Scroll.onBothAxes
            >> Scroll.toElement "section-1"
            >> ... -- Configure the animation
            >> Scroll.build

-}
onBothAxes : Builder -> Builder
onBothAxes =
    Internal.onBothAxes


{-| Scroll on X axis only.

    import Scroll.Builder as Scroll

    scrollXOnly : ScrollBuilder -> ScrollBuilder
    scrollXOnly =
        Scroll.forContainer "containerId"
            >> Scroll.onXAxis
            >> Scroll.toElement "section-1"
            >> ... -- Configure the animation
            >> Scroll.build

-}
onXAxis : Builder -> Builder
onXAxis =
    Internal.onXAxis


{-| Scroll on Y axis only.

    import Scroll.Builder as Scroll

    scrollYOnly : ScrollBuilder -> ScrollBuilder
    scrollYOnly =
        Scroll.forDocument
            >> Scroll.onYAxis
            >> Scroll.toElement "section-1"
            >> ... -- Configure the animation
            >> Scroll.build

-}
onYAxis : Builder -> Builder
onYAxis =
    Internal.onYAxis
