module Anim.Properties.Position exposing
    ( Builder, for, build
    , from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , delay, duration, speed
    , easing
    , perspective
    )

{-| Position animation functions with 3D support.

Use these functions to configure position animations in the builder chain:

    animBuilder
        |> Position.for "my-element"
        |> Position.fromXY 100 20
        |> Position.toY 200
        |> Position.speed 500
        |> ... -- other position configuration steps
        |> Position.build
        |> ... -- continue with animation

For 3D positioning, you just need to set a non-zero value for the 'Z' axis and a perspective (either globally on the Engine or using the [perspective](#perspective) function for this property):

    -- 3D zoom in effect
    animBuilder
        |> Position.for "my-element"
        |> Position.perspective "container-id" 800
        |> Position.fromXYZ 100 20 50
        |> Position.toZ 200
        |> Position.speed 500
        |> Position.build


# Build

@docs Builder, for, build


# Configure


## Start Position

The first time a position animation is configured, if no starting position is set, it will default to: `{ x = 0, y = 0, z = 0 }`, i.e. the origin.
On subsequent animations, it will start from the last known position.

The last known position is tracked in your Engine's model, so you only need to set this when you want to override that behavior, or, if you choose not to track state in your model.

@docs from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## End Position

@docs to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ


## Timing

@docs delay, duration, speed


## Easing

@docs easing


## Perspective

For 3D positioning this is required to give a sense of depth. Without it, Z positioning will have no visual effect.

You can set a global perspective for all 3D animations directly on the Engine you are using, or you can set it on a per-property basis using this function.

@docs perspective

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


{-| Set the uniform starting position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.from 100
        |> ...

This is equivalent to calling `fromXYZ 100 100 100`.

-}
from : Float -> Builder -> Builder
from =
    PB.from << P.fromTriple << (\v -> ( v, v, v ))


{-| Set the starting X, Y, and Z position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.fromXYZ 100 20 50
        |> ...

-}
fromXYZ : Float -> Float -> Float -> Builder -> Builder
fromXYZ =
    PB.fromXYZ


{-| Set the starting position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.fromXY 100 20
        |> ...

The Z position remains unchanged, or zero if not set.

-}
fromXY : Float -> Float -> Builder -> Builder
fromXY =
    PB.fromXY


{-| Set the starting X and Z position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.fromXZ 100 50
        |> ...

The Y position remains unchanged, or zero if not set.

-}
fromXZ : Float -> Float -> Builder -> Builder
fromXZ =
    PB.fromXZ


{-| Set the starting X position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.fromX 100
        |> ...

The Y and Z positions remain unchanged, or zero if not set.

-}
fromX : Float -> Builder -> Builder
fromX =
    PB.fromX


{-| Set the starting Y and Z position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.fromYZ 200 50
        |> ...

The X position remains unchanged, or zero if not set.

-}
fromYZ : Float -> Float -> Builder -> Builder
fromYZ =
    PB.fromYZ


{-| Set the starting Y position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.fromY 50
        |> ...

The X and Z positions remain unchanged, or zero if not set.

-}
fromY : Float -> Builder -> Builder
fromY =
    PB.fromY


{-| Set the starting Z position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.fromZ 75
        |> ...

The X and Y positions remain unchanged, or zero if not set.

-}
fromZ : Float -> Builder -> Builder
fromZ =
    PB.fromZ


{-| Set the target uniform position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.to 100
        |> ...

This is equivalent to calling `toXYZ 100 100 100`.

-}
to : Float -> Builder -> Builder
to =
    PB.to << P.fromTriple << (\v -> ( v, v, v ))


{-| Set the target X, Y, and Z position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.toXYZ 100 200 50
        |> ...

-}
toXYZ : Float -> Float -> Float -> Builder -> Builder
toXYZ x y z =
    PB.toXYZ x y z


{-| Set the target X and Y position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.toXY 100 200
        |> ...

The Z position remains unchanged, or zero if not set.

-}
toXY : Float -> Float -> Builder -> Builder
toXY x y =
    PB.toXY x y


{-| Set the target X and Z position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.toXZ 100 50
        |> ...

The Y position remains unchanged, or zero if not set.

-}
toXZ : Float -> Float -> Builder -> Builder
toXZ =
    PB.toXZ


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


{-| Set the target Y and Z position for the current element.

    animBuilder
        |> Position.for "my-element"
        |> Position.toYZ 200 75
        |> ...

The X position remains unchanged, or zero if not set.

-}
toYZ : Float -> Float -> Builder -> Builder
toYZ =
    PB.toYZ


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


{-| The speed represents how many pixels the element moves per second.

For example, lets take a position animation from `(0, 0)` to `(100, 0)`.
A speed of `50.0` means the element will move 50 pixels per second, so our animation will take 2 seconds to complete (0 -> 50 in 1 second, then 50 -> 100 in the next second).

    animBuilder
        |> Position.for "my-element"
        |> Position.toY 300
        |> Position.speed 500
        |> ...

Similarly, a speed of `100.0` would complete the same animation in 1 second, and a speed of `25.0` would take 4 seconds.

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


{-| Set the perspective for 3D positioning on this specific property.

This allows you to override the global perspective setting for position animations
on a per-container basis. The perspective value determines the distance between
the viewer and the `z = 0` plane, affecting how 3D positioning appears.

    animBuilder
        |> Position.for "my-element"
        |> Position.perspective "special-container" 800
        |> Position.toZ 200
        |> ...

The first parameter is the container ID, and the second is the perspective value in pixels.
This will override any global perspective set by one of the Engines.

**Note**: You also need to set the perspective attributes on the container element in your HTML/CSS
for the effect to be visible. You can do this with the `perspectiveStyles` function in each of the Engines.

-}
perspective : String -> Float -> Builder -> Builder
perspective =
    PB.perspective
