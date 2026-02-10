module Anim.Property.Scale exposing
    ( init, initXYZ, initXY, initXZ, initX, initYZ, initY, initZ
    , Builder, for, build
    , from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , delay, duration, speed
    , easing
    )

{-| Scale animation functions with 3D support.

Build animations that scale elements along the X, Y, and Z axes.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.fromXY 0.8 0.8
        |> Scale.toXY 1.5 1.5
        |> Scale.speed 2.0
        |> ... -- other scale configuration steps
        |> Scale.build
        |> ... -- continue with animation

For 3D scaling, set a non-zero value for the 'Z' axis and add perspective to the parent container using `Anim.View3D`:

    import Anim.Extra.View3D as View3D

    view model =
        div [ id "container", View3D.perspective 1000 ]
            [ animatedElement ]


# Initialize

@docs init, initXYZ, initXY, initXZ, initX, initYZ, initY, initZ


# Build

@docs Builder, for, build


# Configure


## Initial Value

The first time a scale animation is configured, if no initial value is set, the [default](#default) is used.
On subsequent _stateful_ animations, it will start from the last known scale, so you only need to set this
when you want to override that behavior.

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
import Anim.Internal.Builders.Scale as SB


{-| The default scale value used when no initial value is specified:

`{ x = 1, y = 1, z = 1 }` (no scaling).

-}
default : { x : Float, y : Float, z : Float }
default =
    { x = 1, y = 1, z = 1 }


{-| Type alias for the internal `ScaleBuilder`.
-}
type alias Builder =
    SB.ScaleBuilder


{-| Turn the `AnimBuilder` into a scale animation `Builder` for the specified element.

From here, you can continue configuring the scale animation, then call [build](#build) to turn
the `Builder` back into an `AnimBuilder` and then either continue configuring other property animations or
animate it with the Engine.

    animBuilder
        |> Scale.for "my-element"
        |> ... -- continue with scale configuration

-}
for : String -> AnimBuilder -> Builder
for =
    SB.for


{-| Set the initial scale.

Use this to initialize the scale in your `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    Engine.init
        |> Engine.builder
        |> Scale.init "element-id" 1.5
        |> ... -- continue setting initial values
        |> Engine.animate

This is equivalent to calling `initXYZ 1.5 1.5 1.5`.

-}
init : String -> Float -> AnimBuilder -> AnimBuilder
init elementId value animBuilder =
    animBuilder
        |> SB.for elementId
        |> from value
        |> to value
        |> SB.build


{-| Set the initial X, Y, and Z scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    Engine.init
        |> Engine.builder
        |> Scale.initXYZ "element-id" 1.5 1.2 1.0
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initXYZ : String -> Float -> Float -> Float -> AnimBuilder -> AnimBuilder
initXYZ elementId x y z animBuilder =
    animBuilder
        |> SB.for elementId
        |> fromXYZ x y z
        |> SB.toXYZ x y z
        |> SB.build


{-| Set the initial X and Y scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    Engine.init
        |> Engine.builder
        |> Scale.initXY "element-id" 1.5 1.2
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initXY : String -> Float -> Float -> AnimBuilder -> AnimBuilder
initXY elementId x y animBuilder =
    animBuilder
        |> SB.for elementId
        |> fromXY x y
        |> SB.toXY x y
        |> SB.build


{-| Set the initial X and Z scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    Engine.init
        |> Engine.builder
        |> Scale.initXZ "element-id" 1.5 1.0
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initXZ : String -> Float -> Float -> AnimBuilder -> AnimBuilder
initXZ elementId x z animBuilder =
    animBuilder
        |> SB.for elementId
        |> fromXZ x z
        |> SB.toXZ x z
        |> SB.build


{-| Set the initial X scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    Engine.init
        |> Engine.builder
        |> Scale.initX "element-id" 1.5
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initX : String -> Float -> AnimBuilder -> AnimBuilder
initX elementId x animBuilder =
    animBuilder
        |> SB.for elementId
        |> fromX x
        |> SB.toX x
        |> SB.build


{-| Set the initial Y and Z scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    Engine.init
        |> Engine.builder
        |> Scale.initYZ "element-id" 1.2 1.0
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initYZ : String -> Float -> Float -> AnimBuilder -> AnimBuilder
initYZ elementId y z animBuilder =
    animBuilder
        |> SB.for elementId
        |> fromYZ y z
        |> SB.toYZ y z
        |> SB.build


{-| Set the initial Y scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    Engine.init
        |> Engine.builder
        |> Scale.initY "element-id" 1.2
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initY : String -> Float -> AnimBuilder -> AnimBuilder
initY elementId y animBuilder =
    animBuilder
        |> SB.for elementId
        |> fromY y
        |> SB.toY y
        |> SB.build


{-| Set the initial Z scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    Engine.init
        |> Engine.builder
        |> Scale.initZ "element-id" 1.0
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initZ : String -> Float -> AnimBuilder -> AnimBuilder
initZ elementId z animBuilder =
    animBuilder
        |> SB.for elementId
        |> fromZ z
        |> SB.toZ z
        |> SB.build


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue with the animation.

    animBuilder
        |> Scale.for "my-element"
        |> ... -- Scale configuration steps
        |> Scale.build
        |> ... -- continue with animation or execute

-}
build : Builder -> AnimBuilder
build =
    SB.build


{-| Set the uniform starting scale for the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.from 0.8
        |> ...

This is equivalent to `Scale.fromXYZ 0.8 0.8 0.8`.

-}
from : Float -> Builder -> Builder
from uniformScale =
    SB.fromXYZ uniformScale uniformScale uniformScale


{-| Set the starting scale for the X, Y, and Z axes of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.fromXYZ 0.8 1.2 0.9
        |> ...

-}
fromXYZ : Float -> Float -> Float -> Builder -> Builder
fromXYZ =
    SB.fromXYZ


{-| Set the starting scale for the X and Y axes of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.fromXY 0.8 1.2
        |> ...

The Z scale remains unchanged, or 1.0 if not set.

-}
fromXY : Float -> Float -> Builder -> Builder
fromXY =
    SB.fromXY


{-| Set the starting scale for the X and Z axes of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.fromXZ 0.8 0.9
        |> ...

The Y scale remains unchanged, or 1.0 if not set.

-}
fromXZ : Float -> Float -> Builder -> Builder
fromXZ =
    SB.fromXZ


{-| Set the starting scale for the X axis of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.fromX 0.8
        |> ...

The Y and Z scales remain unchanged, or 1.0 if not set.

-}
fromX : Float -> Builder -> Builder
fromX =
    SB.fromX


{-| Set the starting scale for the Y and Z axes of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.fromYZ 1.2 0.9
        |> ...

The X scale remains unchanged, or 1.0 if not set.

-}
fromYZ : Float -> Float -> Builder -> Builder
fromYZ =
    SB.fromYZ


{-| Set the starting scale for the Y axis of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.fromY 1.2
        |> ...

The X and Z scales remain unchanged, or 1.0 if not set.

-}
fromY : Float -> Builder -> Builder
fromY =
    SB.fromY


{-| Set the starting scale for the Z axis of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.fromZ 1.1
        |> ...

The X and Y scales remain unchanged, or 1.0 if not set.

-}
fromZ : Float -> Builder -> Builder
fromZ =
    SB.fromZ


{-| Set the uniform target scale for the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.to 1.5
        |> ...

This is equivalent to `toXYZ 1.5 1.5 1.5`.

-}
to : Float -> Builder -> Builder
to targetScale =
    SB.toXYZ targetScale targetScale targetScale


{-| Set the target scale for the X, Y, and Z axes of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toXYZ 1.5 2.0 0.8
        |> ...

-}
toXYZ : Float -> Float -> Float -> Builder -> Builder
toXYZ =
    SB.toXYZ


{-| Set the target scale for the X and Y axes of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toXY 1.5 2.0
        |> ...

The Z scale remains unchanged, or 1.0 if not set.

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    SB.toXY


{-| Set the target scale for the X and Z axes of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toXZ 1.5 0.8
        |> ...

The Y scale remains unchanged, or 1.0 if not set.

-}
toXZ : Float -> Float -> Builder -> Builder
toXZ =
    SB.toXZ


{-| Set the target scale for the X axis of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toX 2.0
        |> ...

The Y and Z scales remain unchanged, or 1.0 if not set.

-}
toX : Float -> Builder -> Builder
toX =
    SB.toX


{-| Set the target scale for the Y and Z axes of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toYZ 1.5 0.8
        |> ...

The X scale remains unchanged, or 1.0 if not set.

-}
toYZ : Float -> Float -> Builder -> Builder
toYZ =
    SB.toYZ


{-| Set the target scale for the Y axis of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toY 1.5
        |> ...

The X and Z scales remain unchanged, or 1.0 if not set.

-}
toY : Float -> Builder -> Builder
toY =
    SB.toY


{-| Set the target scale for the Z axis of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toZ 0.8
        |> ...

The X and Y scales remain unchanged, or 1.0 if not set.

-}
toZ : Float -> Builder -> Builder
toZ =
    SB.toZ


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay =
    SB.delay


{-| Set the animation duration (milliseconds).

    animBuilder
        |> Scale.for "my-element"
        |> Scale.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| The speed represents how much the scale factor changes per second.

For example, lets take a scale animation from `1.0` to `5.0`.
A speed of `2.0` means the scale will change by 2.0 units per second, so our animation will take 2 seconds to complete (1.0 -> 3.0 in 1 second, then 3.0 -> 5.0 in the next second).

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toXYZ 5.0 5.0 5.0
        |> Scale.speed 2.0
        |> ...

Similarly, a speed of `4.0` would complete the same animation in 1 second, and a speed of `1.0` would take 4 seconds.

-}
speed : Float -> Builder -> Builder
speed =
    SB.speed


{-| Set the easing function for the animation.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing =
    SB.easing
