module Anim.Internal.Builders.Scroll exposing
    ( ScrollBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , forContainer
    , forDocument
    , onBothAxes
    , onBothAxesWithOffset
    , onXAxis
    , onXAxisWithOffset
    , onYAxis
    , onYAxisWithOffset
    , speed
    , toBottom
    , toBottomLeft
    , toBottomRight
    , toCenter
    , toElement
    , toLeft
    , toPercentage
    , toRight
    , toTop
    , toTopLeft
    , toTopRight
    , toX
    , toXY
    , toY
    )

{-| Internal scroll builder implementation.

This module provides the ScrollBuilder type and functions for building scroll animations
with type-safe boundaries between AnimBuilder and per-scroll configuration.

-}

import Anim.Easing exposing (Easing)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Properties.ScrollTarget as ScrollTarget exposing (Axis(..), ScrollTarget, ScrollTargetType(..))
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))


{-| The scroll builder type that maintains per-scroll configuration.
-}
type ScrollBuilder
    = ScrollBuilder
        { animBuilder : AnimBuilder
        , containerId : String
        , scrollTarget : ScrollTarget
        , timing : Maybe TimeSpec
        , easing : Maybe Easing
        , delay : Int
        }



-- START: AnimBuilder → ScrollBuilder


{-| Start configuring a scroll animation for a specific container.

Use "document" for document body scrolling, or an element ID for container scrolling.

-}
for : String -> AnimBuilder -> ScrollBuilder
for containerId animBuilder =
    ScrollBuilder
        { animBuilder = animBuilder
        , containerId = containerId
        , scrollTarget = ScrollTarget.for containerId
        , timing = Nothing
        , easing = Nothing
        , delay = 0
        }


{-| Start configuring a scroll animation for the document body.

    animBuilder
        |> Scroll.forDocument
        |> Scroll.toTop
        |> Scroll.build

-}
forDocument : AnimBuilder -> ScrollBuilder
forDocument =
    for "document"


{-| Start configuring a scroll animation for a specific container element.

    animBuilder
        |> Scroll.forContainer "my-scrollable-container"
        |> Scroll.toElement "target"
        |> Scroll.build

-}
forContainer : String -> AnimBuilder -> ScrollBuilder
forContainer =
    for



-- END: ScrollBuilder → AnimBuilder


{-| Complete the scroll configuration and return to AnimBuilder.
-}
build : ScrollBuilder -> AnimBuilder
build (ScrollBuilder config) =
    -- Add the completed scroll target to the AnimBuilder
    config.animBuilder
        |> Builder.addScrollTarget config.scrollTarget



-- TARGET CONFIGURATION


{-| Scroll to a specific element by ID.
-}
toElement : String -> ScrollBuilder -> ScrollBuilder
toElement elementId (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toElement elementId
        }


{-| Scroll to specific X and Y coordinates.
-}
toXY : Float -> Float -> ScrollBuilder -> ScrollBuilder
toXY x y (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toXY x y
        }


{-| Scroll to specific X coordinate only.
-}
toX : Float -> ScrollBuilder -> ScrollBuilder
toX x (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toX x
        }


{-| Scroll to specific Y coordinate only.
-}
toY : Float -> ScrollBuilder -> ScrollBuilder
toY y (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toY y
        }


{-| Scroll to the top of the container.
-}
toTop : ScrollBuilder -> ScrollBuilder
toTop (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toTop
        }


{-| Scroll to the bottom of the container.
-}
toBottom : ScrollBuilder -> ScrollBuilder
toBottom (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toBottom
        }


{-| Scroll to the center of the container.
-}
toCenter : ScrollBuilder -> ScrollBuilder
toCenter (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toCenter
        }


{-| Scroll to the left edge of the container.
-}
toLeft : ScrollBuilder -> ScrollBuilder
toLeft (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toX 0
        }


{-| Scroll to the right edge of the container.
-}
toRight : ScrollBuilder -> ScrollBuilder
toRight (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toPercentage 1.0 0
        }


{-| Scroll to the top-left corner of the container.
-}
toTopLeft : ScrollBuilder -> ScrollBuilder
toTopLeft (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toXY 0 0
        }


{-| Scroll to the top-right corner of the container.
-}
toTopRight : ScrollBuilder -> ScrollBuilder
toTopRight (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toPercentage 1.0 0
        }


{-| Scroll to the bottom-left corner of the container.
-}
toBottomLeft : ScrollBuilder -> ScrollBuilder
toBottomLeft (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toPercentage 0 1.0
        }


{-| Scroll to the bottom-right corner of the container.
-}
toBottomRight : ScrollBuilder -> ScrollBuilder
toBottomRight (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toPercentage 1.0 1.0
        }


{-| Scroll to percentage of container size.

    -- 50% width, 80% height
    |> toPercentage 0.5 0.8

-}
toPercentage : Float -> Float -> ScrollBuilder -> ScrollBuilder
toPercentage xPercent yPercent (ScrollBuilder config) =
    ScrollBuilder
        { config
            | scrollTarget = config.scrollTarget |> ScrollTarget.toPercentage xPercent yPercent
        }



-- AXIS SELECTION


{-| Scroll on both X and Y axes (default).
-}
onBothAxes : ScrollBuilder -> ScrollBuilder
onBothAxes (ScrollBuilder config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget
    in
    ScrollBuilder
        { config
            | scrollTarget = ScrollTarget.ScrollTarget { targetData | axis = Both }
        }


{-| Scroll on X axis only.
-}
onXAxis : ScrollBuilder -> ScrollBuilder
onXAxis (ScrollBuilder config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget
    in
    ScrollBuilder
        { config
            | scrollTarget = ScrollTarget.ScrollTarget { targetData | axis = X }
        }


{-| Scroll on Y axis only.
-}
onYAxis : ScrollBuilder -> ScrollBuilder
onYAxis (ScrollBuilder config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget
    in
    ScrollBuilder
        { config
            | scrollTarget = ScrollTarget.ScrollTarget { targetData | axis = Y }
        }


{-| Scroll on both axes with offsets.
-}
onBothAxesWithOffset : Float -> Float -> ScrollBuilder -> ScrollBuilder
onBothAxesWithOffset offsetX offsetY (ScrollBuilder config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget
    in
    ScrollBuilder
        { config
            | scrollTarget =
                ScrollTarget.ScrollTarget
                    { targetData
                        | axis = Both
                        , offset = ( offsetX, offsetY )
                    }
        }


{-| Scroll on X axis with offset.
-}
onXAxisWithOffset : Float -> ScrollBuilder -> ScrollBuilder
onXAxisWithOffset offset (ScrollBuilder config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget

        ( _, offsetY ) =
            targetData.offset
    in
    ScrollBuilder
        { config
            | scrollTarget =
                ScrollTarget.ScrollTarget
                    { targetData
                        | axis = X
                        , offset = ( offset, offsetY )
                    }
        }


{-| Scroll on Y axis with offset.
-}
onYAxisWithOffset : Float -> ScrollBuilder -> ScrollBuilder
onYAxisWithOffset offset (ScrollBuilder config) =
    let
        (ScrollTarget.ScrollTarget targetData) =
            config.scrollTarget

        ( offsetX, _ ) =
            targetData.offset
    in
    ScrollBuilder
        { config
            | scrollTarget =
                ScrollTarget.ScrollTarget
                    { targetData
                        | axis = Y
                        , offset = ( offsetX, offset )
                    }
        }



-- TIMING


{-| Set delay before this scroll animation starts (overrides global).
-}
delay : Int -> ScrollBuilder -> ScrollBuilder
delay delayMs (ScrollBuilder config) =
    ScrollBuilder { config | delay = delayMs }


{-| Set duration for this scroll animation (overrides global).
-}
duration : Int -> ScrollBuilder -> ScrollBuilder
duration durationMs (ScrollBuilder config) =
    ScrollBuilder { config | timing = Just (Duration durationMs) }


{-| Set speed for this scroll animation (overrides global).
-}
speed : Float -> ScrollBuilder -> ScrollBuilder
speed speedPxPerSec (ScrollBuilder config) =
    ScrollBuilder { config | timing = Just (Speed speedPxPerSec) }



-- EASING


{-| Set easing function for this scroll animation (overrides global).
-}
easing : Easing -> ScrollBuilder -> ScrollBuilder
easing easingFn (ScrollBuilder config) =
    ScrollBuilder { config | easing = Just easingFn }
