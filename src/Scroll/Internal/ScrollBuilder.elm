module Scroll.Internal.ScrollBuilder exposing
    ( Builder
    , ScrollBuilder
    , addScrollTarget
    , build
    , byX
    , byXY
    , byY
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
    , setDelay
    , setDuration
    , setEasing
    , setSpeed
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

`Builder` is the per-scroll configuration state used while building a single
scroll target. `forDocument` / `forContainer` create one, the `to*` / `by*` /
`with*` functions configure it, and `build` commits it back into the
`ScrollBuilder`.

-}

import Easing exposing (Easing(..))
import Scroll.Internal.Engine.ScrollTarget as ScrollTarget exposing (Axis(..), ScrollTarget, ScrollTargetType(..))
import Shared.TimeSpec exposing (TimeSpec(..))



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
type Builder
    = Builder
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
-- SCROLLBUILDER SETTERS (global defaults, used by engines)
-- ============================================================


addScrollTarget : ScrollTarget -> ScrollBuilder -> ScrollBuilder
addScrollTarget scrollTarget (ScrollBuilder data) =
    ScrollBuilder { data | scrollTargets = scrollTarget :: data.scrollTargets }


setDuration : Int -> ScrollBuilder -> ScrollBuilder
setDuration ms (ScrollBuilder data) =
    ScrollBuilder { data | timing = Just (Duration ms) }


setSpeed : Float -> ScrollBuilder -> ScrollBuilder
setSpeed pxPerSec (ScrollBuilder data) =
    ScrollBuilder { data | timing = Just (Speed (max 1 pxPerSec)) }


setEasing : Easing -> ScrollBuilder -> ScrollBuilder
setEasing easingFn (ScrollBuilder data) =
    ScrollBuilder { data | easing = Just easingFn }


setDelay : Int -> ScrollBuilder -> ScrollBuilder
setDelay ms (ScrollBuilder data) =
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
-- BUILDER — BUILD
-- ============================================================


{-| Start configuring a scroll animation for a specific container.

Use `"document"` for document body scrolling, or an element ID for container scrolling.

-}
for : String -> ScrollBuilder -> Builder
for containerId scrollBuilder =
    Builder
        { scrollBuilder = scrollBuilder
        , containerId = containerId
        , scrollTarget = ScrollTarget.for containerId
        , timing = Nothing
        , easing = Nothing
        , delay = 0
        }


{-| Start configuring a scroll animation for the document body.
-}
forDocument : ScrollBuilder -> Builder
forDocument =
    for "document"


{-| Start configuring a scroll animation for a specific container element.
-}
forContainer : String -> ScrollBuilder -> Builder
forContainer =
    for


{-| Complete the scroll configuration and add the target to the `ScrollBuilder`.
-}
build : Builder -> ScrollBuilder
build (Builder config) =
    config.scrollBuilder
        |> applyTiming config.timing
        |> applyEasing config.easing
        |> applyDelay config.delay
        |> addScrollTarget config.scrollTarget


applyTiming : Maybe TimeSpec -> ScrollBuilder -> ScrollBuilder
applyTiming maybeTiming scrollBuilder =
    case maybeTiming of
        Just (Duration ms) ->
            setDuration ms scrollBuilder

        Just (Speed pxPerSec) ->
            setSpeed pxPerSec scrollBuilder

        Nothing ->
            scrollBuilder


applyEasing : Maybe Easing -> ScrollBuilder -> ScrollBuilder
applyEasing maybeEasing scrollBuilder =
    case maybeEasing of
        Just easingFn ->
            setEasing easingFn scrollBuilder

        Nothing ->
            scrollBuilder


applyDelay : Int -> ScrollBuilder -> ScrollBuilder
applyDelay delayMs scrollBuilder =
    if delayMs > 0 then
        setDelay delayMs scrollBuilder

    else
        scrollBuilder



-- ============================================================
-- BUILDER — TIMING OVERRIDES
-- ============================================================


{-| Set the delay (milliseconds) for this scroll animation, overriding the global default.
-}
delay : Int -> Builder -> Builder
delay delayMs (Builder config) =
    Builder { config | delay = delayMs }


{-| Set the duration (milliseconds) for this scroll animation, overriding the global default.
-}
duration : Int -> Builder -> Builder
duration durationMs (Builder config) =
    Builder { config | timing = Just (Duration durationMs) }


{-| Set the speed (pixels per second) for this scroll animation, overriding the global default.
-}
speed : Float -> Builder -> Builder
speed speedPxPerSec (Builder config) =
    Builder { config | timing = Just (Speed speedPxPerSec) }


{-| Set the easing function for this scroll animation, overriding the global default.
-}
easing : Easing -> Builder -> Builder
easing easingFn (Builder config) =
    Builder { config | easing = Just easingFn }



-- ============================================================
-- BUILDER — TARGET CONFIGURATION
-- ============================================================


{-| Scroll to a specific element by ID.
-}
toElement : String -> Builder -> Builder
toElement elementId (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toElement elementId config.scrollTarget
        }


{-| Scroll to specific X and Y coordinates.
-}
toXY : Float -> Float -> Builder -> Builder
toXY x y (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toXY x y config.scrollTarget
        }


{-| Scroll to specific X coordinate only.
-}
toX : Float -> Builder -> Builder
toX x (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toX x config.scrollTarget
        }


{-| Scroll to specific Y coordinate only.
-}
toY : Float -> Builder -> Builder
toY y (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toY y config.scrollTarget
        }


{-| Scroll to the top of the container.
-}
toTop : Builder -> Builder
toTop (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toPercentageY 0 config.scrollTarget
        }


{-| Scroll to the bottom of the container.
-}
toBottom : Builder -> Builder
toBottom (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toPercentageY 1.0 config.scrollTarget
        }


{-| Scroll to the center of the container.
-}
toCenter : Builder -> Builder
toCenter (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toPercentage 0.5 0.5 config.scrollTarget
        }


{-| Scroll to the left edge of the container.
-}
toLeft : Builder -> Builder
toLeft (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toPercentageX 0 config.scrollTarget
        }


{-| Scroll to the right edge of the container.
-}
toRight : Builder -> Builder
toRight (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toPercentageX 1.0 config.scrollTarget
        }


{-| Scroll to the top-left corner of the container.
-}
toTopLeft : Builder -> Builder
toTopLeft (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toPercentage 0 0 config.scrollTarget
        }


{-| Scroll to the top-right corner of the container.
-}
toTopRight : Builder -> Builder
toTopRight (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toPercentage 1.0 0 config.scrollTarget
        }


{-| Scroll to the bottom-left corner of the container.
-}
toBottomLeft : Builder -> Builder
toBottomLeft (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toPercentage 0 1.0 config.scrollTarget
        }


{-| Scroll to the bottom-right corner of the container.
-}
toBottomRight : Builder -> Builder
toBottomRight (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toPercentage 1.0 1.0 config.scrollTarget
        }


{-| Scroll to percentage of container size.
-}
toPercentageXY : Float -> Float -> Builder -> Builder
toPercentageXY xPercent yPercent (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toPercentage xPercent yPercent config.scrollTarget
        }


{-| Scroll to percentage of container width (X axis only).
-}
toPercentageX : Float -> Builder -> Builder
toPercentageX xPercent (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toPercentageX xPercent config.scrollTarget
        }


{-| Scroll to percentage of container height (Y axis only).
-}
toPercentageY : Float -> Builder -> Builder
toPercentageY yPercent (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.toPercentageY yPercent config.scrollTarget
        }


{-| Scroll by a relative amount on both X and Y axes.
-}
byXY : Float -> Float -> Builder -> Builder
byXY dx dy (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.byXY dx dy config.scrollTarget
        }


{-| Scroll by a relative amount on X axis only.
-}
byX : Float -> Builder -> Builder
byX dx (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.byX dx config.scrollTarget
        }


{-| Scroll by a relative amount on Y axis only.
-}
byY : Float -> Builder -> Builder
byY dy (Builder config) =
    Builder
        { config
            | scrollTarget = ScrollTarget.byY dy config.scrollTarget
        }



-- ============================================================
-- BUILDER — AXIS SELECTION
-- ============================================================


{-| Scroll on both X and Y axes (default).
-}
onBothAxes : Builder -> Builder
onBothAxes (Builder config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget
    in
    Builder
        { config
            | scrollTarget = ScrollTarget.ScrollTarget { targetData | axis = Both }
        }


{-| Scroll on X axis only.
-}
onXAxis : Builder -> Builder
onXAxis (Builder config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget
    in
    Builder
        { config
            | scrollTarget = ScrollTarget.ScrollTarget { targetData | axis = X }
        }


{-| Scroll on Y axis only.
-}
onYAxis : Builder -> Builder
onYAxis (Builder config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget
    in
    Builder
        { config
            | scrollTarget = ScrollTarget.ScrollTarget { targetData | axis = Y }
        }



-- ============================================================
-- BUILDER — OFFSETS
-- ============================================================


{-| Set X and Y scroll offsets.
-}
withOffsetXY : Float -> Float -> Builder -> Builder
withOffsetXY offsetX offsetY (Builder config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget
    in
    Builder
        { config
            | scrollTarget =
                ScrollTarget.ScrollTarget
                    { targetData | offset = ( offsetX, offsetY ) }
        }


{-| Set X scroll offset.
-}
withOffsetX : Float -> Builder -> Builder
withOffsetX offsetX (Builder config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget

        ( _, offsetY ) =
            targetData.offset
    in
    Builder
        { config
            | scrollTarget =
                ScrollTarget.ScrollTarget
                    { targetData | offset = ( offsetX, offsetY ) }
        }


{-| Set Y scroll offset.
-}
withOffsetY : Float -> Builder -> Builder
withOffsetY offsetY (Builder config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget

        ( offsetX, _ ) =
            targetData.offset
    in
    Builder
        { config
            | scrollTarget =
                ScrollTarget.ScrollTarget
                    { targetData | offset = ( offsetX, offsetY ) }
        }
