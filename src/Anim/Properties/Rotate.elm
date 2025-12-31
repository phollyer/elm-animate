module Anim.Properties.Rotate exposing
    ( Builder, for, build
    , from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
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

For 3D rotations, you just need to set a value for the 'Z' axis and a perspective (either globally on the Engine or per-property using [perspective](#perspective)):

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.fromXYZ 0 0 0
        |> Rotate.toXYZ 45 90 180
        |> Rotate.speed 90
        |> Rotate.build


# Build

@docs Builder, for, build


# Configure


## Start Rotation

The first time a rotation animation is configured, if no starting rotation is set, it will default to: `{ x = 0, y = 0, z = 0 }`, i.e. no rotation.
On subsequent animations, it will start from the last known rotation.

The last known rotation is tracked in your Engine's model, so you only need to set this when you want to override that behavior, or, if you choose not to track state in your model.

@docs from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## End Rotation

@docs to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ


## Timing

@docs delay, duration, speed


## Easing

@docs easing


## Perspective

For 3D scaling this is required to give a sense of depth. Without it, Z scaling will have no visual effect.

You can set a global perspective for all 3D animations directly on the Engine you are using, or you can set it on a per-property basis using this function.

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
for =
    RB.for


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


{-| Set the starting uniform rotation for the current element (degrees).

    animBuilder
        |> Rotation.for "my-element"
        |> Rotation.from 45
        |> ...

This is equivalent to `fromXYZ 45 45 45`.

-}
from : Float -> Builder -> Builder
from =
    RB.from << R.fromFloat


{-| Set the starting X, Y, and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.fromXYZ 45 90 180
        |> ...

-}
fromXYZ : Float -> Float -> Float -> Builder -> Builder
fromXYZ =
    RB.fromXYZ


{-| Set the starting X and Y rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.fromXY 45 90
        |> ...

The Z rotation remains unchanged, or zero if not set.

-}
fromXY : Float -> Float -> Builder -> Builder
fromXY =
    RB.fromXY


{-| Set the starting X and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.fromXZ 45 180
        |> ...

The Y rotation remains unchanged, or zero if not set.

-}
fromXZ : Float -> Float -> Builder -> Builder
fromXZ =
    RB.fromXZ


{-| Set the starting X-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.fromX 45
        |> ...

The Y and Z rotations remain unchanged, or zero if not set.

-}
fromX : Float -> Builder -> Builder
fromX =
    RB.fromX


{-| Set the starting Y and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.fromYZ 90 180
        |> ...

The X rotation remains unchanged, or zero if not set.

-}
fromYZ : Float -> Float -> Builder -> Builder
fromYZ =
    RB.fromYZ


{-| Set the starting Y-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.fromY 90
        |> ...

The X and Z rotations remain unchanged, or zero if not set.

-}
fromY : Float -> Builder -> Builder
fromY =
    RB.fromY


{-| Set the starting Z-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.fromZ 180
        |> ...

The X and Y rotations remain unchanged, or zero if not set.

-}
fromZ : Float -> Builder -> Builder
fromZ =
    RB.fromZ


{-| Set the target uniform rotation for the current element.

    animBuilder
        |> Rotation.for "my-element"
        |> Rotation.to 180
        |> ...

This is equivalent to `toXYZ 180 180 180`.

-}
to : Float -> Builder -> Builder
to =
    RB.to << R.fromFloat


{-| Set the target X, Y, and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.toXYZ 45 90 180
        |> ...

-}
toXYZ : Float -> Float -> Float -> Builder -> Builder
toXYZ =
    RB.toXYZ


{-| Set the target X and Y rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.toXY 45 90
        |> ...

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    RB.toXY


{-| Set the target X and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.toXZ 45 180
        |> ...

-}
toXZ : Float -> Float -> Builder -> Builder
toXZ =
    RB.toXZ


{-| Set the target X-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.toX 45
        |> ...

The Y and Z rotations remain unchanged, or zero if not set.

-}
toX : Float -> Builder -> Builder
toX =
    RB.toX


{-| Set the target Y and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.toYZ 90 180
        |> ...

-}
toYZ : Float -> Float -> Builder -> Builder
toYZ =
    RB.toYZ


{-| Set the target Y-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.toY 90
        |> ...

The X and Z rotations remain unchanged, or zero if not set.

-}
toY : Float -> Builder -> Builder
toY =
    RB.toY


{-| Set the target Z-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.toZ 180
        |> ...

The X and Y rotations remain unchanged, or zero if not set.

-}
toZ : Float -> Builder -> Builder
toZ =
    RB.toZ


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
speed =
    RB.speed


{-| Set the animation duration (milliseconds).

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration =
    RB.duration


{-| Set the easing function for the animation.

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing =
    RB.easing << Easing.mapInternal identity


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay =
    RB.delay


{-| Set the perspective for 3D rotation.

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

**Note**: You also need to set the perspective attributes on the container element in your HTML/CSS
for the effect to be visible. You can do this with the `perspectiveStyles` function in each of the Engines.

-}
perspective : String -> Float -> Builder -> Builder
perspective =
    RB.perspective
