module Anim.Properties.Scale exposing
    ( Builder, for, build
    , from, fromXY, fromXYZ, fromX, fromY, fromZ
    , to, toXY, toXYZ, toX, toY, toZ
    , speed, duration, easing, delay, perspective
    )

{-| Scale animation functions with 3D support.

Use these functions to configure scale animations in the builder chain:

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toXYZ 1.5 1.5 1.2  -- 3D scaling
        |> Scale.speed 2.0
        |> ... -- other scale configuration steps
        |> Scale.build
        |> ... -- continue with animation


# Build

@docs Builder, for, build


# Configure


## Start Scale

The first time the animation runs, if no starting scale is set, it will default to (1.0, 1.0, 1.0).

On subsequent animations, it will start from the last known scale, so you only need to set this when you want to override that behavior.

@docs from, fromXY, fromXYZ, fromX, fromY, fromZ


## End Scale

@docs to, toXY, toXYZ, toX, toY, toZ


## Timing

@docs speed, duration, easing, delay, perspective

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Scale as SB
import Anim.Timing.Easing as Easing exposing (Easing)



-- SCALE CONFIGURATION


{-| Type alias for the internal `ScaleBuilder`.
-}
type alias Builder =
    SB.ScaleBuilder


{-| Start configuring a scale animation for a specific element.

    animBuilder
        |> Scale.for "my-element"
        |> ...

-}
for : String -> AnimBuilder -> Builder
for elementId =
    SB.for elementId


{-| Complete the scale animation configuration and return an [AnimBuilder](Anim.AnimBuilder)
so you can continue building the overall animation.

    animBuilder
        |> Scale.for "my-element"
        |> ... -- Scale configuration steps
        |> Scale.build
        |> ...

-}
build : Builder -> AnimBuilder
build =
    SB.build


{-| Set the uniform starting scale for the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.from 0.8
        |> ...

-}
from : Float -> Builder -> Builder
from uniformScale =
    SB.fromXYZ uniformScale uniformScale uniformScale


{-| Set the starting scale for the X and Y axes of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.fromXY 0.8 1.2
        |> ...

-}
fromXY : Float -> Float -> Builder -> Builder
fromXY =
    SB.fromXY


{-| Set the starting scale for the X, Y, and Z axes of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.fromXYZ 0.8 1.2 0.9
        |> ...

-}
fromXYZ : Float -> Float -> Float -> Builder -> Builder
fromXYZ =
    SB.fromXYZ


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

-}
to : Float -> Builder -> Builder
to targetScale =
    SB.toXYZ targetScale targetScale targetScale


{-| Set the target scale for the X and Y axes of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toXY 1.5 2.0
        |> ...

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    SB.toXY


{-| Set the target scale for the X, Y, and Z axes of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toXYZ 1.5 2.0 0.8
        |> ...

-}
toXYZ : Float -> Float -> Float -> Builder -> Builder
toXYZ =
    SB.toXYZ


{-| Set the target scale for the X axis of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toX 2.0
        |> ...

The Y and Z scales remain unchanged.

-}
toX : Float -> Builder -> Builder
toX =
    SB.toX


{-| Set the target scale for the Y axis of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toY 1.5
        |> ...

The X and Z scales remain unchanged.

-}
toY : Float -> Builder -> Builder
toY =
    SB.toY


{-| Set the target scale for the Z axis of the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toZ 0.8
        |> ...

The X and Y scales remain unchanged.

-}
toZ : Float -> Builder -> Builder
toZ =
    SB.toZ


{-| Set the animation speed (scale factor units per second).

The speed represents how much the scale factor changes per second. For example,
a speed of `2.0` means the scale will change by 2.0 units per second (e.g., from 1.0 to 3.0 takes 1 second).

    animBuilder
        |> Scale.for "my-element"
        |> Scale.speed 2.0
        |> ...

-}
speed : Float -> Builder -> Builder
speed =
    SB.speed


{-| Set the animation duration (milliseconds).

    animBuilder
        |> Scale.for "my-element"
        |> Scale.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| Set the easing function for the animation.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing easing_ =
    SB.easing (Easing.mapInternal identity easing_)


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay =
    SB.delay


{-| Set the perspective for 3D scaling on this specific property.

This allows you to override the global perspective setting for scale animations
on a per-container basis. The perspective value determines the distance between
the viewer and the z=0 plane, affecting how 3D scaling appears.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.toXYZ 1.5 1.5 1.2
        |> Scale.perspective "special-container" 800
        |> ...

The first parameter is the container ID, and the second is the perspective value in pixels.
This will override any global perspective set via `Css.perspective` for this scale animation.

-}
perspective : String -> Float -> Builder -> Builder
perspective =
    SB.perspective
