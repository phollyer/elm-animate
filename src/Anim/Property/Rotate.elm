module Anim.Property.Rotate exposing
    ( init, initXYZ, initXY, initXZ, initX, initYZ, initY, initZ
    , Builder, for, build
    , from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , delay, duration, speed
    , easing
    )

{-| Rotate elements around the X, Y, and Z axes.

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.to 180
        |> Rotate.build


# Initialize

@docs init, initXYZ, initXY, initXZ, initX, initYZ, initY, initZ


# Build

@docs Builder, for, build


# Configure


## Initial Value

@docs from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## Target Value

@docs to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Rotate as RB
import Anim.Internal.Properties.Rotate as R


{-| Type alias for the internal `RotateBuilder`.
-}
type alias Builder =
    RB.RotateBuilder


{-| Turn the `AnimBuilder` into a rotate animation `Builder` for the specified animation group.

The group name identifies which animations run together. All animations in the same pipeline that share
the same group will run simultaneously on the same element.

From here, you can continue configuring the rotate animation, then call [build](#build) to turn
the `Builder` back into an `AnimBuilder` and then either continue configuring other property animations or
animate it with the Engine.

    animBuilder
        |> Rotate.for "animGroupName"
        |> ... -- continue with rotation configuration

-}
for : String -> AnimBuilder -> Builder
for =
    RB.for


{-| Set the initial rotation.

Use this to initialize the rotation in your `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    Engine.init
        |> Engine.builder
        |> Rotate.init "animGroupName" 45
        |> ... -- continue setting initial values
        |> Engine.animate

This is equivalent to calling `initXYZ 45 45 45`.

-}
init : String -> Float -> AnimBuilder -> AnimBuilder
init animationKey value animBuilder =
    animBuilder
        |> for animationKey
        |> from value
        |> to value
        |> build


{-| Set the initial X, Y, and Z rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    Engine.init
        |> Engine.builder
        |> Rotate.initXYZ "animGroupName" 45 30 60
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initXYZ : String -> Float -> Float -> Float -> AnimBuilder -> AnimBuilder
initXYZ animationKey x y z animBuilder =
    animBuilder
        |> for animationKey
        |> fromXYZ x y z
        |> toXYZ x y z
        |> build


{-| Set the initial X and Y rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    Engine.init
        |> Engine.builder
        |> Rotate.initXY "animGroupName" 45 30
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initXY : String -> Float -> Float -> AnimBuilder -> AnimBuilder
initXY animationKey x y animBuilder =
    animBuilder
        |> for animationKey
        |> fromXY x y
        |> toXY x y
        |> build


{-| Set the initial X and Z rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    Engine.init
        |> Engine.builder
        |> Rotate.initXZ "animGroupName" 45 60
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initXZ : String -> Float -> Float -> AnimBuilder -> AnimBuilder
initXZ animationKey x z animBuilder =
    animBuilder
        |> for animationKey
        |> fromXZ x z
        |> toXZ x z
        |> build


{-| Set the initial X rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    Engine.init
        |> Engine.builder
        |> Rotate.initX "animGroupName" 45
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initX : String -> Float -> AnimBuilder -> AnimBuilder
initX animationKey x animBuilder =
    animBuilder
        |> for animationKey
        |> fromX x
        |> toX x
        |> build


{-| Set the initial Y and Z rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    Engine.init
        |> Engine.builder
        |> Rotate.initYZ "animGroupName" 30 60
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initYZ : String -> Float -> Float -> AnimBuilder -> AnimBuilder
initYZ animationKey y z animBuilder =
    animBuilder
        |> for animationKey
        |> fromYZ y z
        |> toYZ y z
        |> build


{-| Set the initial Y rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    Engine.init
        |> Engine.builder
        |> Rotate.initY "animGroupName" 30
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initY : String -> Float -> AnimBuilder -> AnimBuilder
initY animationKey y animBuilder =
    animBuilder
        |> for animationKey
        |> fromY y
        |> toY y
        |> build


{-| Set the initial Z rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    Engine.init
        |> Engine.builder
        |> Rotate.initZ "animGroupName" 60
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initZ : String -> Float -> AnimBuilder -> AnimBuilder
initZ animationKey z animBuilder =
    animBuilder
        |> for animationKey
        |> fromZ z
        |> toZ z
        |> build


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue with the animation.

    animBuilder
        |> Rotate.for "animGroupName"
        |> ... -- Rotate configuration steps
        |> Rotate.build
        |> ... -- continue with animation or execute

-}
build : Builder -> AnimBuilder
build =
    RB.build


{-| Set the starting uniform rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotation.from 45
        |> ...

This is equivalent to `fromXYZ 45 45 45`.

-}
from : Float -> Builder -> Builder
from =
    RB.from << R.fromFloat


{-| Set the starting X, Y, and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.fromXYZ 45 90 180
        |> ...

-}
fromXYZ : Float -> Float -> Float -> Builder -> Builder
fromXYZ =
    RB.fromXYZ


{-| Set the starting X and Y rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.fromXY 45 90
        |> ...

The Z rotation remains unchanged, or zero if not set.

-}
fromXY : Float -> Float -> Builder -> Builder
fromXY =
    RB.fromXY


{-| Set the starting X and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.fromXZ 45 180
        |> ...

The Y rotation remains unchanged, or zero if not set.

-}
fromXZ : Float -> Float -> Builder -> Builder
fromXZ =
    RB.fromXZ


{-| Set the starting X-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.fromX 45
        |> ...

The Y and Z rotations remain unchanged, or zero if not set.

-}
fromX : Float -> Builder -> Builder
fromX =
    RB.fromX


{-| Set the starting Y and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.fromYZ 90 180
        |> ...

The X rotation remains unchanged, or zero if not set.

-}
fromYZ : Float -> Float -> Builder -> Builder
fromYZ =
    RB.fromYZ


{-| Set the starting Y-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.fromY 90
        |> ...

The X and Z rotations remain unchanged, or zero if not set.

-}
fromY : Float -> Builder -> Builder
fromY =
    RB.fromY


{-| Set the starting Z-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.fromZ 180
        |> ...

The X and Y rotations remain unchanged, or zero if not set.

-}
fromZ : Float -> Builder -> Builder
fromZ =
    RB.fromZ


{-| Set the target uniform rotation for the current element.

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotation.to 180
        |> ...

This is equivalent to `toXYZ 180 180 180`.

-}
to : Float -> Builder -> Builder
to =
    RB.to << R.fromFloat


{-| Set the target X, Y, and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.toXYZ 45 90 180
        |> ...

-}
toXYZ : Float -> Float -> Float -> Builder -> Builder
toXYZ =
    RB.toXYZ


{-| Set the target X and Y rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.toXY 45 90
        |> ...

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    RB.toXY


{-| Set the target X and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.toXZ 45 180
        |> ...

-}
toXZ : Float -> Float -> Builder -> Builder
toXZ =
    RB.toXZ


{-| Set the target X-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.toX 45
        |> ...

The Y and Z rotations remain unchanged, or zero if not set.

-}
toX : Float -> Builder -> Builder
toX =
    RB.toX


{-| Set the target Y and Z rotations for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.toYZ 90 180
        |> ...

-}
toYZ : Float -> Float -> Builder -> Builder
toYZ =
    RB.toYZ


{-| Set the target Y-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.toY 90
        |> ...

The X and Z rotations remain unchanged, or zero if not set.

-}
toY : Float -> Builder -> Builder
toY =
    RB.toY


{-| Set the target Z-axis rotation for the current element (degrees).

    animBuilder
        |> Rotate.for "animGroupName"
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
        |> Rotate.for "animGroupName"
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
        |> Rotate.for "animGroupName"
        |> Rotate.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration =
    RB.duration


{-| Set the easing function for the animation.

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing =
    RB.easing


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> Rotate.for "animGroupName"
        |> Rotate.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay =
    RB.delay
