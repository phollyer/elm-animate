module Scroll.Builder exposing
    ( Builder, forDocument, forContainer, build
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
The Scroll engine modules ([Cmd](Anim-Engine-Scroll-Cmd), [Task](Anim-Engine-Scroll-Task),
[Sub](Anim-Engine-Scroll-Sub)) handle execution, while this module handles per-scroll configuration.

    import Easing exposing (Easing(..))
    import Scroll.Builder as Builder exposing (ScrollBuilder)

    scrollToElement : String -> ScrollBuilder -> ScrollBuilder
    scrollToElement elementId =
        Builder.forDocument
            >> Builder.toElement elementId
            >> Builder.speed 100
            >> Builder.easing EaseInOut
            >> Builder.build

📖 See [Scroll Overview](https://phollyer.github.io/elm-animate/engines/scroll/overview/) section in the docs.


# Build

@docs Builder, forDocument, forContainer, build


# Timing

@docs delay, duration, speed


# Easing

@docs easing


# Element Targeting

@docs toElement

📖 See [Scroll to Element](https://phollyer.github.io/elm-animate/engines/scroll/overview/#scroll-to-element) in the docs.


# Position Targeting

@docs toCenter


## Edges

@docs toTop, toBottom, toLeft, toRight


## Corners

@docs toTopLeft, toTopRight, toBottomLeft, toBottomRight

📖 See [Scroll to Position](https://phollyer.github.io/elm-animate/engines/scroll/overview/#scroll-to-position) in the docs.


# Coordinate Targeting


## Axes

@docs toXY, toX, toY

## Percentages

@docs toPercentageXY, toPercentageX, toPercentageY


## Relative Scrolling

@docs byXY, byX, byY


# Offsets

@docs withOffsetXY, withOffsetX, withOffsetY

📖 See [Offset](https://phollyer.github.io/elm-animate/engines/scroll/overview/#offset) in the docs.


# Axis Selection

@docs onBothAxes, onXAxis, onYAxis

📖 See [Axis](https://phollyer.github.io/elm-animate/engines/scroll/overview/#axis) in the docs.

-}

import Easing exposing (Easing)
import Scroll.Internal.ScrollBuilder as Internal exposing (ScrollBuilder)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the internal `Builder`.
-}
type alias Builder =
    Internal.Builder



-- ============================================================
-- BUILD
-- ============================================================


{-| Start configuring a scroll animation for the document body.

    scrollDocument : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollDocument =
        Builder.forDocument
            >> ... -- Configure and build the animation

-}
forDocument : ScrollBuilder -> Builder
forDocument =
    Internal.forDocument


{-| Start configuring a scroll animation for a specific container element.

    scrollContainer : String -> Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollContainer containerId =
        Builder.forContainer containerId
            >> ... -- Configure and build the animation

-}
forContainer : String -> ScrollBuilder -> Builder
forContainer =
    Internal.forContainer


{-| Complete the scroll animation configuration and return a `ScrollBuilder`
so you can continue configuring other scroll animations or execute
the animation with a Scroll Engine.

    scroll : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scroll =
        Builder.forDocument
            >> ... -- Configure the animation
            >> Builder.build

-}
build : Builder -> ScrollBuilder
build =
    Internal.build



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before this scroll animation starts.

Overrides the global default delay set on a Scroll Engine.

    scrollAfterDelay : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollAfterDelay =
        Builder.forDocument
            >> Builder.toTop
            >> Builder.delay 500
            >> ... -- Configure the animation
            >> Builder.build

-}
delay : Int -> Builder -> Builder
delay =
    Internal.delay


{-| Set the duration (milliseconds) for this scroll animation.

Overrides the global default duration (or speed) set on a Scroll Engine.

    scrollWithDuration : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollWithDuration =
        Builder.forDocument
            >> Builder.toElement "target"
            >> Builder.duration 1000
            >> ... -- Configure the animation
            >> Builder.build

-}
duration : Int -> Builder -> Builder
duration =
    Internal.duration


{-| Set the speed (pixels per second) for this scroll animation.

Overrides the global default speed (or duration) set on a Scroll Engine.

    scrollWithSpeed : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollWithSpeed =
        Builder.forDocument
            >> Builder.toTop
            >> Builder.speed 500
            >> ... -- Configure the animation
            >> Builder.build

-}
speed : Float -> Builder -> Builder
speed =
    Internal.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for this scroll animation.

Overrides the global default easing set on a Scroll Engine.

    scrollWithEasing : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollWithEasing =
        Builder.forDocument
            >> Builder.toElement "section-1"
            >> Builder.easing BounceOut
            >> ... -- Configure the animation
            >> Builder.build

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

    scrollToElement : String -> Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToElement elementId =
        Builder.forDocument
            >> Builder.toElement elementId
            >> ... -- Configure the animation
            >> Builder.build

-}
toElement : String -> Builder -> Builder
toElement =
    Internal.toElement



-- ============================
-- CENTER
-- ============================


{-| Scroll to the center of the container.

    scrollToCenter : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToCenter =
        Builder.forContainer "containerId"
            >> Builder.toCenter
            >> ... -- Configure the animation
            >> Builder.build

-}
toCenter : Builder -> Builder
toCenter =
    Internal.toCenter



-- ============================
-- EDGES
-- ============================


{-| Scroll to the bottom of the container.

    scrollToBottom : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToBottom =
        Builder.forContainer "containerId"
            >> Builder.toBottom
            >> ... -- Configure the animation
            >> Builder.build

-}
toBottom : Builder -> Builder
toBottom =
    Internal.toBottom


{-| Scroll to the left edge of the container.

    scrollToLeft : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToLeft =
        Builder.forContainer "containerId"
            >> Builder.toLeft
            >> ... -- Configure the animation
            >> Builder.build

-}
toLeft : Builder -> Builder
toLeft =
    Internal.toLeft


{-| Scroll to the right edge of the container.

    scrollToRight : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToRight =
        Builder.forContainer "containerId"
            >> Builder.toRight
            >> ... -- Configure the animation
            >> Builder.build

-}
toRight : Builder -> Builder
toRight =
    Internal.toRight


{-| Scroll to the top of the container.

    scrollToTop : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToTop =
        Builder.forDocument
            >> Builder.toTop
            >> ... -- Configure the animation
            >> Builder.build

-}
toTop : Builder -> Builder
toTop =
    Internal.toTop



-- ============================
-- CORNERS
-- ============================


{-| Scroll to the bottom-left corner of the container.

    scrollToBottomLeft : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToBottomLeft =
        Builder.forContainer "containerId"
            >> Builder.toBottomLeft
            >> ... -- Configure the animation
            >> Builder.build

-}
toBottomLeft : Builder -> Builder
toBottomLeft =
    Internal.toBottomLeft


{-| Scroll to the bottom-right corner of the container.

    scrollToBottomRight : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToBottomRight =
        Builder.forContainer "containerId"
            >> Builder.toBottomRight
            >> ... -- Configure the animation
            >> Builder.build

-}
toBottomRight : Builder -> Builder
toBottomRight =
    Internal.toBottomRight


{-| Scroll to the top-left corner of the container.

    scrollToTopLeft : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToTopLeft =
        Builder.forContainer "containerId"
            >> Builder.toTopLeft
            >> ... -- Configure the animation
            >> Builder.build

-}
toTopLeft : Builder -> Builder
toTopLeft =
    Internal.toTopLeft


{-| Scroll to the top-right corner of the container.

    scrollToTopRight : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToTopRight =
        Builder.forContainer "containerId"
            >> Builder.toTopRight
            >> ... -- Configure the animation
            >> Builder.build

-}
toTopRight : Builder -> Builder
toTopRight =
    Internal.toTopRight



-- ============================
-- AXES
-- ============================


{-| Scroll to specific X coordinate only.

    scrollToX : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToX =
        Builder.forDocument
            >> Builder.toX 100
            >> ... -- Configure the animation
            >> Builder.build

-}
toX : Float -> Builder -> Builder
toX =
    Internal.toX


{-| Scroll to specific Y coordinate only.

    scrollToY : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToY =
        Builder.forDocument
            >> Builder.toY 200
            >> ... -- Configure the animation
            >> Builder.build

-}
toY : Float -> Builder -> Builder
toY =
    Internal.toY


{-| Scroll to specific X and Y coordinates.

    scrollToCoordinates : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToCoordinates =
        Builder.forContainer "containerId"
            >> Builder.toXY 100 200
            >> ... -- Configure the animation
            >> Builder.build

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    Internal.toXY



-- ============================
-- PERCENTAGES
-- ============================


{-| Scroll to percentage of container size.

    scrollToPercentage : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToPercentage =
        Builder.forContainer "containerId"
            >> Builder.toPercentageXY 0.5 0.8
            >> ... -- Configure the animation
            >> Builder.build

-}
toPercentageXY : Float -> Float -> Builder -> Builder
toPercentageXY =
    Internal.toPercentageXY


{-| Scroll to percentage of container width (X axis only).

    scrollToPercentageX : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToPercentageX =
        Builder.forContainer "containerId"
            >> Builder.toPercentageX 0.5
            >> ... -- Configure the animation
            >> Builder.build

-}
toPercentageX : Float -> Builder -> Builder
toPercentageX =
    Internal.toPercentageX


{-| Scroll to percentage of container height (Y axis only).

    scrollToPercentageY : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollToPercentageY =
        Builder.forContainer "containerId"
            >> Builder.toPercentageY 0.8
            >> ... -- Configure the animation
            >> Builder.build

-}
toPercentageY : Float -> Builder -> Builder
toPercentageY =
    Internal.toPercentageY



-- ============================
-- DELTAS
-- ============================


{-| Scroll by a relative amount on both X and Y axes.

Positive values scroll right/down, negative values scroll left/up.

    scrollByXY : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollByXY =
        Builder.forDocument
            >> Builder.byXY 100 200
            >> ... -- Configure the animation
            >> Builder.build

-}
byXY : Float -> Float -> Builder -> Builder
byXY =
    Internal.byXY


{-| Scroll by a relative amount on X axis only.

Positive values scroll right, negative values scroll left.

    scrollByX : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollByX =
        Builder.forDocument
            >> Builder.byX 100
            >> ... -- Configure the animation
            >> Builder.build

-}
byX : Float -> Builder -> Builder
byX =
    Internal.byX


{-| Scroll by a relative amount on Y axis only.

Positive values scroll down, negative values scroll up.

    scrollByY : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollByY =
        Builder.forDocument
            >> Builder.byY 200
            >> ... -- Configure the animation
            >> Builder.build

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

    scrollWithOffset : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollWithOffset =
        Builder.forDocument
            >> Builder.toElement "section-1"
            >> Builder.withOffsetXY 20 60
            >> ... -- Configure the animation
            >> Builder.build

-}
withOffsetXY : Float -> Float -> Builder -> Builder
withOffsetXY =
    Internal.withOffsetXY


{-| Set X scroll offset.

    scrollWithOffsetX : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollWithOffsetX =
        Builder.forDocument
            >> Builder.toElement "section-1"
            >> Builder.withOffsetX 20
            >> ... -- Configure the animation
            >> Builder.build

-}
withOffsetX : Float -> Builder -> Builder
withOffsetX =
    Internal.withOffsetX


{-| Set Y scroll offset.

Commonly used to account for fixed headers.

    scrollWithOffsetY : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollWithOffsetY =
        Builder.forDocument
            >> Builder.toElement "section-1"
            >> Builder.withOffsetY 60
            >> ... -- Configure the animation
            >> Builder.build

-}
withOffsetY : Float -> Builder -> Builder
withOffsetY =
    Internal.withOffsetY



-- ============================================================
-- AXIS SELECTION
-- ============================================================


{-| Scroll on both X and Y axes (default).

    scrollBothAxes : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollBothAxes =
        Builder.forContainer "containerId"
            >> Builder.onBothAxes
            >> Builder.toElement "section-1"
            >> ... -- Configure the animation
            >> Builder.build

-}
onBothAxes : Builder -> Builder
onBothAxes =
    Internal.onBothAxes


{-| Scroll on X axis only.

    scrollXOnly : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollXOnly =
        Builder.forContainer "containerId"
            >> Builder.onXAxis
            >> Builder.toX 500
            >> ... -- Configure the animation
            >> Builder.build

-}
onXAxis : Builder -> Builder
onXAxis =
    Internal.onXAxis


{-| Scroll on Y axis only.

    scrollYOnly : Scroll.ScrollBuilder -> Scroll.ScrollBuilder
    scrollYOnly =
        Builder.forDocument
            >> Builder.onYAxis
            >> Builder.toElement "section-1"
            >> ... -- Configure the animation
            >> Builder.build

-}
onYAxis : Builder -> Builder
onYAxis =
    Internal.onYAxis
