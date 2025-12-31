module Anim.Properties.Rotate exposing
    ( Builder, for, build
    , from, fromX, fromY, fromZ, fromXYZ
    , to, toX, toY, toZ, toXYZ
    , delay, duration, speed
    , easing
    , perspective
    )

{-| Rotate animation functions.

Use these functions to configure rotate animations in the builder chain:

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.to 180
        |> ... -- other rotate configuration steps
        |> Rotate.build
        |> ... -- continue with animation

For 3D rotation, use the XYZ functions:

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.fromXYZ 0 0 0
        |> Rotate.toXYZ 45 90 180
        -- X, Y, Z axis rotations
        |> Rotate.speed 90
        |> Rotate.build


# Build

@docs Builder, for, build


# Configure


## Start Rotation

The first time the animation runs, if no starting rotation is set, it will default to (0, 0, 0) degrees.

On subsequent animations, providing you are tracking animation state in your model, it will start from the last known rotation,
so you only need to set this when you want to override that behavior.

@docs from, fromX, fromY, fromZ, fromXYZ


## End Rotation

@docs to, toX, toY, toZ, toXYZ


## Timing

@docs delay, duration, speed


## Easing

@docs easing


## 3D Animations

@docs perspective

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Rotate as RB
import Anim.Internal.Properties.Rotate as R
import Anim.Timing.Easing as Easing exposing (Easing)



-- ROTATE CONFIGURATION


{-| Type alias for the internal `RotateBuilder`.
-}
type alias Builder =
    RB.RotateBuilder


{-| Start configuring a rotation animation for a specific element.

    animBuilder
        |> Rotation.for "my-element"
        |> ...

-}
for : String -> AnimBuilder -> Builder
for elementId =
    RB.for elementId


{-| Complete the rotation animation configuration and return an [AnimBuilder](Anim.AnimBuilder)
so you can continue building the overall animation.

    animBuilder
        |> Rotate.for "my-element"
        |> ... -- Rotate configuration steps
        |> Rotate.build
        |> ...

-}
build : Builder -> AnimBuilder
build =
    RB.build


{-| Set the starting rotation for the current element (degrees).

    animBuilder
        |> Rotation.for "my-element"
        |> Rotation.from 45
        |> ...

-}
from : Float -> Builder -> Builder
from rotation =
    RB.from (R.fromFloat rotation)


{-| Set the starting X-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.fromX 45
        |> ...

The Y and Z rotations remain unchanged, or zero if not set.

-}
fromX : Float -> Builder -> Builder
fromX x =
    RB.fromX x


{-| Set the starting Y-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.fromY 90
        |> ...

The X and Z rotations remain unchanged, or zero if not set.

-}
fromY : Float -> Builder -> Builder
fromY y =
    RB.fromY y


{-| Set the starting Z-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.fromZ 180
        |> ...

The X and Y rotations remain unchanged, or zero if not set.

-}
fromZ : Float -> Builder -> Builder
fromZ z =
    RB.fromZ z


{-| Set the starting X, Y, and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.fromXYZ 45 90 180
        |> ...

-}
fromXYZ : Float -> Float -> Float -> Builder -> Builder
fromXYZ x y z =
    RB.fromXYZ x y z


{-| Set the target rotation for the current element.

    animBuilder
        |> Rotation.for "my-element"
        |> Rotation.to 180
        |> ...

-}
to : Float -> Builder -> Builder
to targetRotation =
    RB.to (R.fromFloat targetRotation)


{-| Set the target X-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.toX 45
        |> ...

The Y and Z rotations remain unchanged, or zero if not set.

-}
toX : Float -> Builder -> Builder
toX x =
    RB.toX x


{-| Set the target Y-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.toY 90
        |> ...

The X and Z rotations remain unchanged, or zero if not set.

-}
toY : Float -> Builder -> Builder
toY y =
    RB.toY y


{-| Set the target Z-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.toZ 180
        |> ...

The X and Y rotations remain unchanged, or zero if not set.

-}
toZ : Float -> Builder -> Builder
toZ z =
    RB.toZ z


{-| Set the target X, Y, and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.toXYZ 45 90 180
        |> ...

-}
toXYZ : Float -> Float -> Float -> Builder -> Builder
toXYZ x y z =
    RB.toXYZ x y z


{-| The speed represents how many degrees the element rotates per second.

For example, lets take a rotation animation from `0°` to `180°`.
A speed of `90.0` means the element will rotate 90 degrees per second, so our animation will take 2 seconds to complete (0° -> 90° in 1 second, then 90° -> 180° in the next second).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.to 180
        |> Rotate.speed 90
        |> ...

Similarly, a speed of `180.0` would complete the same animation in 1 second, and a speed of `45.0` would take 4 seconds.

-}
speed : Float -> Builder -> Builder
speed degreesPerSecond =
    RB.speed degreesPerSecond


{-| Set the animation duration (milliseconds).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration milliseconds =
    RB.duration milliseconds


{-| Set the easing function for the animation.

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing easingFunction =
    RB.easing (Easing.mapInternal identity easingFunction)


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay delay_ =
    RB.delay delay_


{-| Set the perspective for 3D rotation on this specific property.

This allows you to override the global perspective setting for rotation animations
on a per-container basis. The perspective value determines the distance between
the viewer and the `z = 0` plane, affecting how 3D rotations appear.

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.perspective "special-container" 800
        |> Rotate.toXYZ 45 90 180
        |> ...

The first parameter is the container ID, and the second is the perspective value in pixels.
This will override any global perspective set by one of the Engines.

-}
perspective : String -> Float -> Builder -> Builder
perspective =
    RB.perspective
