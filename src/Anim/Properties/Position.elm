module Anim.Properties.Position exposing
    ( Builder, for, build
    , fromXY, fromX, fromY
    , toXY, toX, toY
    , speed, duration, easing, delay
    )

{-| Position animation functions.

Use these functions to configure position animations in the builder chain:

    animBuilder
        |> Position.for "my-element"
        |> Position.fromXY 100 20
        |> Position.toY 200
        |> Position.speed 500
        |> ... -- other position configuration steps
        |> Position.build
        |> ... -- continue with animation


# Build

@docs Builder, for, build


# Configure


## Start Position

The first time the animation runs, if no starting position is set, it will default to (0, 0).

On subsequent animations, it will start from the last known position, so you only need to set this when you want to override that behavior.

@docs fromXY, fromX, fromY


## End Position

@docs toXY, toX, toY


## Timing

@docs speed, duration, easing, delay

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Position as PB
import Anim.Internal.Properties.Position as P
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)



-- POSITION CONFIGURATION


{-| Type alias for the internal `PositionBuilder`.
-}
type alias Builder =
    PB.PositionBuilder


{-| Start configuring a position animation for a specific element.

    animBuilder
        |> Position.for "my-element"
        |> ...

-}
for : String -> AnimBuilder -> Builder
for elementId =
    PB.for elementId


{-| Complete the position animation configuration and return an [AnimBuilder](Anim.AnimBuilder)
so you can continue building the overall animation.

    animBuilder
        |> Position.for "my-element"
        |> ... -- Position configuration steps
        |> Position.build
        |> ... -- continue with animation

-}
build : Builder -> AnimBuilder
build =
    PB.build


{-| Set the starting position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.fromXY 100 20
        |> ...

-}
fromXY : Float -> Float -> Builder -> Builder
fromXY =
    PB.fromXY


{-| Set the starting X position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.fromX 100
        |> ...

The starting Y position remains unchanged, or zero if not set.

-}
fromX : Float -> Builder -> Builder
fromX =
    PB.fromX


{-| Set the starting Y position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.fromY 50
        |> ...

The starting X position remains unchanged, or zero if not set.

-}
fromY : Float -> Builder -> Builder
fromY =
    PB.fromY


{-| Set the target X and Y position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.toXY 100 200
        |> ...

-}
toXY : Float -> Float -> Builder -> Builder
toXY x y =
    PB.to (P.fromTuple ( x, y ))


{-| Set the target X position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.toX 150
        |> ...

The Y position remains unchanged, or zero if not set.

-}
toX : Float -> Builder -> Builder
toX x =
    PB.toX x


{-| Set the target Y position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.toY 250
        |> ...

The X position remains unchanged, or zero if not set.

-}
toY : Float -> Builder -> Builder
toY y =
    PB.toY y


{-| Set the animation speed (pixels per second).

    animBuilder
        |> Position.for "my-element"
        |> Position.toY 300
        |> Position.speed 500
        |> ...

-}
speed : Float -> Builder -> Builder
speed =
    PB.speed


{-| Set the animation duration (milliseconds).

    animBuilder
        |> Position.for "my-element"
        |> Position.toY 300
        |> Position.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration =
    PB.duration


{-| Set the easing function for the animation.

    animBuilder
        |> Position.for "my-element"
        |> Position.toY 300
        |> Position.speed 400
        |> Position.easing Ease.inOutQuad
        |> ...

-}
easing : Easing -> Builder -> Builder
easing easing_ =
    PB.easing (Easing.mapInternal identity easing_)


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> Position.for "my-element"
        |> Position.toY 300
        |> Position.speed 400
        |> Position.delay 500
        |> ...

-}
delay : Delay -> Builder -> Builder
delay delay_ =
    PB.delay (Delay.mapInternal identity delay_)
