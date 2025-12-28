module Anim.Properties.Position exposing
    ( Builder, for, build
    , fromXY, fromX, fromY, fromXYZ, fromZ
    , toXY, toX, toY, toXYZ, toZ
    , speed, duration, easing, delay
    , Position, getX, getY, getZ, toTuple, toTriple, toRecord
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

For 3D positioning, use the XYZ functions:

    animBuilder
        |> Position.for "my-element"
        |> Position.fromXYZ 100 20 50
        |> Position.toZ 200
        |> Position.speed 500
        |> Position.build


# Build

@docs Builder, for, build


# Configure


## Start Position

The first time an animation runs, if no starting position is set, it will be set to the default (0, 0, 0).

On subsequent animations, providing you are tracking animation state in your model, it will start from the last known position, so you
only need to set this when you want to override that behaviour.

@docs fromXY, fromX, fromY, fromXYZ, fromZ


## End Position

@docs toXY, toX, toY, toXYZ, toZ


## Timing

@docs speed, duration, easing, delay


## Accessor Functions

@docs Position, getX, getY, getZ, toTuple, toTriple, toRecord

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Position as PB
import Anim.Internal.Properties.Position as P
import Anim.Timing.Easing as Easing exposing (Easing)


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


{-| Set the starting X, Y, and Z position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.fromXYZ 100 20 50
        |> ...

-}
fromXYZ : Float -> Float -> Float -> Builder -> Builder
fromXYZ =
    PB.fromXYZ


{-| Set the starting Z position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.fromZ 75
        |> ...

The starting X and Y positions remain unchanged, or zero if not set.

-}
fromZ : Float -> Builder -> Builder
fromZ =
    PB.fromZ


{-| Set the target X and Y position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.toXY 100 200
        |> ...

-}
toXY : Float -> Float -> Builder -> Builder
toXY x y =
    PB.toXY x y


{-| Set the target X, Y, and Z position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.toXYZ 100 200 50
        |> ...

-}
toXYZ : Float -> Float -> Float -> Builder -> Builder
toXYZ x y z =
    PB.toXYZ x y z


{-| Set the target X position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.toX 150
        |> ...

The Y and Z positions remain unchanged, or zero if not set.

-}
toX : Float -> Builder -> Builder
toX x =
    PB.toX x


{-| Set the target Y position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.toY 250
        |> ...

The X and Z positions remain unchanged, or zero if not set.

-}
toY : Float -> Builder -> Builder
toY y =
    PB.toY y


{-| Set the target Z position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.toZ 75
        |> ...

The X and Y positions remain unchanged, or zero if not set.

-}
toZ : Float -> Builder -> Builder
toZ z =
    PB.toZ z


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
easing =
    Easing.mapInternal identity >> PB.easing


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> Position.for "my-element"
        |> Position.toY 300
        |> Position.speed 400
        |> Position.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay delay_ =
    PB.delay delay_



-- Accessor Functions


{-| Type alias for the internal `Position`.
-}
type alias Position =
    P.Position


{-| Get the X coordinate from a `Position`.
-}
getX : Position -> Float
getX =
    P.x


{-| Get the Y coordinate from a `Position`.
-}
getY : Position -> Float
getY =
    P.y


{-| Get the Z coordinate from a `Position`.
-}
getZ : Position -> Float
getZ =
    P.z


{-| Convert a `Position` to a tuple `( x, y )`.
-}
toTuple : Position -> ( Float, Float )
toTuple =
    P.toTuple


{-| Convert a `Position` to a triple `( x, y, z )`.
-}
toTriple : Position -> ( Float, Float, Float )
toTriple =
    P.toTriple


{-| Convert a `Position` to a record `{ x : Float, y : Float, z : Float }`.
-}
toRecord : Position -> { x : Float, y : Float, z : Float }
toRecord =
    P.toRecord
