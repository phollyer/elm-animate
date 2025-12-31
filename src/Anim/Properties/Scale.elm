module Anim.Properties.Scale exposing
    ( Builder, for, build
    , from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , delay, duration, speed
    , easing
    , perspective
    )

{-| Scale animation functions with 3D support.

Use these functions to configure scale animations in the builder chain:

    animBuilder
        |> Scale.for "my-element"
        |> Scale.fromXY 0.8 0.8
        |> Scale.toXY 1.5 1.5
        |> Scale.speed 2.0
        |> ... -- other scale configuration steps
        |> Scale.build
        |> ... -- continue with animation

For 3D scaling, you just need to set a non-zero value for the 'Z' axis and a perspective (either globally on the Engine or using the [perspective](#perspective) function for this property):

    -- 3D scale up effect
    animBuilder
        |> Scale.for "my-element"
        |> Scale.perspective "container-id" 800
        |> Scale.fromXYZ 0.8 0.8 0.8
        |> Scale.toXYZ 1.5 1.5 1.5
        |> Scale.speed 2.0
        |> Scale.build


# Build

@docs Builder, for, build


# Configure


## Start Scale

The first time a scale animation is configured, if no starting scale is set, it will default to: `{x = 1.0, y = 1.0, z = 1.0}`
i.e. no scaling. On subsequent animations, it will start from the last known scale.

The last known scale is tracked in your Engine's model, so you only need to set this when you want to override that behavior, or, if you choose not to track state in your model.

@docs from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## End Scale

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
easing easing_ =
    SB.easing (Easing.mapInternal identity easing_)


{-| Set the perspective for 3D scaling.

This allows you to override the global perspective setting for scale animations
on a per-container basis. The perspective value determines the distance between
the viewer and the `z = 0` plane, affecting how 3D scaling appears.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.perspective "special-container" 800
        |> Scale.toXYZ 1.5 1.5 1.2
        |> ...

The first parameter is the container ID, and the second is the perspective value in pixels.
This will override any global perspective set by one of the Engines.

**Note**: You also need to set the perspective attributes on the container element in your HTML/CSS
for the effect to be visible. You can do this with the `perspectiveStyles` function in each of the Engines.

-}
perspective : String -> Float -> Builder -> Builder
perspective =
    SB.perspective
