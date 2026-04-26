module Scroll.Internal.ScrollBuilder exposing
    ( ScrollBuilder
    , ScrollConfig
    , addScrollTarget
    , build
    , byX
    , byXY
    , byY
    , configDelay
    , configDuration
    , configEasing
    , configSpeed
    , delay
    , duration
    , easing
    , for
    , forContainer
    , forDocument
    , getDelay
    , getDelayWithDefault
    , getEasing
    , getEasingWithDefault
    , getScrollTargets
    , getTimeSpecWithDefault
    , init
    , onBothAxes
    , onXAxis
    , onYAxis
    , speed
    , toBottom
    , toBottomLeft
    , toBottomRight
    , toCenter
    , toElement
    , toLeft
    , toPercentageX
    , toPercentageXY
    , toPercentageY
    , toRight
    , toTop
    , toTopLeft
    , toTopRight
    , toX
    , toXY
    , toY
    , withOffsetX
    , withOffsetXY
    , withOffsetY
    )

{-| Scroll builder types and configuration functions.

`ScrollBuilder` is the accumulating type consumed by scroll engines — it holds
a list of scroll targets plus global defaults for timing, easing, and delay.

`ScrollConfig` is the per-scroll configuration state used while building a
single scroll target. `forDocument` / `forContainer` create one, the `to*` /
`by*` / `with*` functions configure it, and `build` commits it back into the
`ScrollBuilder`.

-}

import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Easing exposing (Easing(..))
import Scroll.Internal.Engine.ScrollTarget as ScrollTarget exposing (Axis(..), ScrollTarget, ScrollTargetType(..))



-- ============================================================
-- TYPES
-- ============================================================


{-| Accumulating builder consumed by scroll engines.

Holds a list of scroll targets and global defaults for timing, easing, and delay.

-}
type ScrollBuilder
    = ScrollBuilder
        { scrollTargets : List ScrollTarget
        , timing : Maybe TimeSpec
        , easing : Maybe Easing
        , delay : Int
        }


{-| Per-scroll configuration state.

Wraps a `ScrollBuilder` and holds the configuration for a single scroll target
being built. Use `forDocument` or `forContainer` to create one, configure it
with the `to*` / `by*` / `with*` functions, then call `build` to commit it.

-}
type ScrollConfig
    = ScrollConfig
        { scrollBuilder : ScrollBuilder
        , containerId : String
        , scrollTarget : ScrollTarget
        , timing : Maybe TimeSpec
        , easing : Maybe Easing
        , delay : Int
        }



-- ============================================================
-- SCROLLBUILDER INIT
-- ============================================================


init : ScrollBuilder
init =
    ScrollBuilder
        { scrollTargets = []
        , timing = Nothing
        , easing = Nothing
        , delay = 0
        }



-- ============================================================
-- SCROLLBUILDER SETTERS (global defaults)
-- ============================================================


addScrollTarget : ScrollTarget -> ScrollBuilder -> ScrollBuilder
addScrollTarget scrollTarget (ScrollBuilder data) =
    ScrollBuilder { data | scrollTargets = scrollTarget :: data.scrollTargets }


duration : Int -> ScrollBuilder -> ScrollBuilder
duration ms (ScrollBuilder data) =
    ScrollBuilder { data | timing = Just (Duration ms) }


speed : Float -> ScrollBuilder -> ScrollBuilder
speed pxPerSec (ScrollBuilder data) =
    ScrollBuilder { data | timing = Just (Speed pxPerSec) }


easing : Easing -> ScrollBuilder -> ScrollBuilder
easing easingFn (ScrollBuilder data) =
    ScrollBuilder { data | easing = Just easingFn }


delay : Int -> ScrollBuilder -> ScrollBuilder
delay ms (ScrollBuilder data) =
    ScrollBuilder { data | delay = ms }



-- ============================================================
-- SCROLLBUILDER GETTERS
-- ============================================================


getScrollTargets : ScrollBuilder -> List ScrollTarget
getScrollTargets (ScrollBuilder data) =
    data.scrollTargets


getTimeSpecWithDefault : ScrollBuilder -> TimeSpec
getTimeSpecWithDefault (ScrollBuilder data) =
    data.timing |> Maybe.withDefault (Duration 0)


getEasing : ScrollBuilder -> Maybe Easing
getEasing (ScrollBuilder data) =
    data.easing


getEasingWithDefault : ScrollBuilder -> Easing
getEasingWithDefault (ScrollBuilder data) =
    data.easing |> Maybe.withDefault QuintOut


getDelay : ScrollBuilder -> Maybe Int
getDelay (ScrollBuilder data) =
    if data.delay == 0 then
        Nothing

    else
        Just data.delay


getDelayWithDefault : ScrollBuilder -> Int
getDelayWithDefault (ScrollBuilder data) =
    data.delay



-- ============================================================
-- SCROLLCONFIG — BUILD
-- ============================================================


{-| Start configuring a scroll animation for a specific container.

Use `"document"` for document body scrolling, or an element ID for container scrolling.

-}
for : String -> ScrollBuilder -> ScrollConfig
for containerId scrollBuilder =
    ScrollConfig
        { scrollBuilder = scrollBuilder
        , containerId = containerId
        , scrollTarget = ScrollTarget.for containerId
        , timing = Nothing
        , easing = Nothing
        , delay = 0
        }


{-| Start configuring a scroll animation for the document body.
-}
forDocument : ScrollBuilder -> ScrollConfig
forDocument =
    for "document"


{-| Start configuring a scroll animation for a specific container element.
-}
forContainer : String -> ScrollBuilder -> ScrollConfig
forContainer =
    for


{-| Complete the scroll configuration and add the target to the `ScrollBuilder`.
-}
build : ScrollConfig -> ScrollBuilder
build (ScrollConfig config) =
    config.scrollBuilder
        |> applyTiming config.timing
        |> applyEasing config.easing
        |> applyDelay config.delay
        |> addScrollTarget config.scrollTarget


applyTiming : Maybe TimeSpec -> ScrollBuilder -> ScrollBuilder
applyTiming maybeTiming scrollBuilder =
    case maybeTiming of
        Just (Duration ms) ->
            duration ms scrollBuilder

        Just (Speed pxPerSec) ->
            speed pxPerSec scrollBuilder

        Nothing ->
            scrollBuilder


applyEasing : Maybe Easing -> ScrollBuilder -> ScrollBuilder
applyEasing maybeEasing scrollBuilder =
    case maybeEasing of
        Just easingFn ->
            easing easingFn scrollBuilder

        Nothing ->
            scrollBuilder


applyDelay : Int -> ScrollBuilder -> ScrollBuilder
applyDelay delayMs scrollBuilder =
    if delayMs > 0 then
        delay delayMs scrollBuilder

    else
        scrollBuilder



-- ============================================================
-- SCROLLCONFIG — PER-SCROLL TIMING OVERRIDES
-- ============================================================


{-| Set the delay (milliseconds) for this scroll animation, overriding the global default.
-}
configDelay : Int -> ScrollConfig -> ScrollConfig
configDelay delayMs (ScrollConfig config) =
    ScrollConfig { config | delay = delayMs }


{-| Set the duration (milliseconds) for this scroll animation, overriding the global default.
-}
configDuration : Int -> ScrollConfig -> ScrollConfig
configDuration durationMs (ScrollConfig config) =
    ScrollConfig { config | timing = Just (Duration durationMs) }


{-| Set the speed (pixels per second) for this scroll animation, overriding the global default.
-}
configSpeed : Float -> ScrollConfig -> ScrollConfig
configSpeed speedPxPerSec (ScrollConfig config) =
    ScrollConfig { config | timing = Just (Speed speedPxPerSec) }


{-| Set the easing function for this scroll animation, overriding the global default.
-}
configEasing : Easing -> ScrollConfig -> ScrollConfig
configEasing easingFn (ScrollConfig config) =
    ScrollConfig { config | easing = Just easingFn }



-- ============================================================
-- SCROLLCONFIG — TARGET CONFIGURATION
-- ============================================================


{-| Scroll to a specific element by ID.
-}
toElement : String -> ScrollConfig -> ScrollConfig
toElement elementId (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toElement elementId config.scrollTarget
        }


{-| Scroll to specific X and Y coordinates.
-}
toXY : Float -> Float -> ScrollConfig -> ScrollConfig
toXY x y (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toXY x y config.scrollTarget
        }


{-| Scroll to specific X coordinate only.
-}
toX : Float -> ScrollConfig -> ScrollConfig
toX x (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toX x config.scrollTarget
        }


{-| Scroll to specific Y coordinate only.
-}
toY : Float -> ScrollConfig -> ScrollConfig
toY y (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toY y config.scrollTarget
        }


{-| Scroll to the top of the container.
-}
toTop : ScrollConfig -> ScrollConfig
toTop (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toPercentageY 0 config.scrollTarget
        }


{-| Scroll to the bottom of the container.
-}
toBottom : ScrollConfig -> ScrollConfig
toBottom (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toPercentageY 1.0 config.scrollTarget
        }


{-| Scroll to the center of the container.
-}
toCenter : ScrollConfig -> ScrollConfig
toCenter (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toPercentage 0.5 0.5 config.scrollTarget
        }


{-| Scroll to the left edge of the container.
-}
toLeft : ScrollConfig -> ScrollConfig
toLeft (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toPercentageX 0 config.scrollTarget
        }


{-| Scroll to the right edge of the container.
-}
toRight : ScrollConfig -> ScrollConfig
toRight (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toPercentageX 1.0 config.scrollTarget
        }


{-| Scroll to the top-left corner of the container.
-}
toTopLeft : ScrollConfig -> ScrollConfig
toTopLeft (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toPercentage 0 0 config.scrollTarget
        }


{-| Scroll to the top-right corner of the container.
-}
toTopRight : ScrollConfig -> ScrollConfig
toTopRight (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toPercentage 1.0 0 config.scrollTarget
        }


{-| Scroll to the bottom-left corner of the container.
-}
toBottomLeft : ScrollConfig -> ScrollConfig
toBottomLeft (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toPercentage 0 1.0 config.scrollTarget
        }


{-| Scroll to the bottom-right corner of the container.
-}
toBottomRight : ScrollConfig -> ScrollConfig
toBottomRight (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toPercentage 1.0 1.0 config.scrollTarget
        }


{-| Scroll to percentage of container size.
-}
toPercentageXY : Float -> Float -> ScrollConfig -> ScrollConfig
toPercentageXY xPercent yPercent (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toPercentage xPercent yPercent config.scrollTarget
        }


{-| Scroll to percentage of container width (X axis only).
-}
toPercentageX : Float -> ScrollConfig -> ScrollConfig
toPercentageX xPercent (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toPercentageX xPercent config.scrollTarget
        }


{-| Scroll to percentage of container height (Y axis only).
-}
toPercentageY : Float -> ScrollConfig -> ScrollConfig
toPercentageY yPercent (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.toPercentageY yPercent config.scrollTarget
        }


{-| Scroll by a relative amount on both X and Y axes.
-}
byXY : Float -> Float -> ScrollConfig -> ScrollConfig
byXY dx dy (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.byXY dx dy config.scrollTarget
        }


{-| Scroll by a relative amount on X axis only.
-}
byX : Float -> ScrollConfig -> ScrollConfig
byX dx (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.byX dx config.scrollTarget
        }


{-| Scroll by a relative amount on Y axis only.
-}
byY : Float -> ScrollConfig -> ScrollConfig
byY dy (ScrollConfig config) =
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.byY dy config.scrollTarget
        }



-- ============================================================
-- SCROLLCONFIG — AXIS SELECTION
-- ============================================================


{-| Scroll on both X and Y axes (default).
-}
onBothAxes : ScrollConfig -> ScrollConfig
onBothAxes (ScrollConfig config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget
    in
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.ScrollTarget { targetData | axis = Both }
        }


{-| Scroll on X axis only.
-}
onXAxis : ScrollConfig -> ScrollConfig
onXAxis (ScrollConfig config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget
    in
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.ScrollTarget { targetData | axis = X }
        }


{-| Scroll on Y axis only.
-}
onYAxis : ScrollConfig -> ScrollConfig
onYAxis (ScrollConfig config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget
    in
    ScrollConfig
        { config
            | scrollTarget = ScrollTarget.ScrollTarget { targetData | axis = Y }
        }



-- ============================================================
-- SCROLLCONFIG — OFFSETS
-- ============================================================


{-| Set X and Y scroll offsets.
-}
withOffsetXY : Float -> Float -> ScrollConfig -> ScrollConfig
withOffsetXY offsetX offsetY (ScrollConfig config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget
    in
    ScrollConfig
        { config
            | scrollTarget =
                ScrollTarget.ScrollTarget
                    { targetData | offset = ( offsetX, offsetY ) }
        }


{-| Set X scroll offset.
-}
withOffsetX : Float -> ScrollConfig -> ScrollConfig
withOffsetX offsetX (ScrollConfig config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget

        ( _, offsetY ) =
            targetData.offset
    in
    ScrollConfig
        { config
            | scrollTarget =
                ScrollTarget.ScrollTarget
                    { targetData | offset = ( offsetX, offsetY ) }
        }


{-| Set Y scroll offset.
-}
withOffsetY : Float -> ScrollConfig -> ScrollConfig
withOffsetY offsetY (ScrollConfig config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget

        ( offsetX, _ ) =
            targetData.offset
    in
    ScrollConfig
        { config
            | scrollTarget =
                ScrollTarget.ScrollTarget
                    { targetData | offset = ( offsetX, offsetY ) }
        }
