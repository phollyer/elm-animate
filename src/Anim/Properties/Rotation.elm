module Anim.Properties.Rotation exposing
    ( Rotation, Builder
    , for, build, to, speed, duration, easing, delay
    )

{-| Rotation animation property functions.

Use these functions to configure rotation animations in the builder chain:

    Anim.init
        |> Rotation.for "my-element"
        |> Rotation.to 180
        |> Rotation.speed 90
        |> Rotation.build
        |> CSS.animate


# Types

@docs Rotation, Builder


# Rotation Configuration

@docs for, build, to, speed, duration, easing, delay

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Rotation as RB
import Anim.Internal.Properties.Rotation as R
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)



-- ROTATION CONFIGURATION


type alias Builder =
    RB.RotationBuilder


{-| Rotation value in degrees.
-}
type alias Rotation =
    Float


{-| Start configuring rotation animation for a specific element.

    Anim.init
        |> Rotation.for "my-element"
        |> Rotation.to 180
        |> Rotation.build

-}
for : String -> AnimBuilder -> Builder
for elementId =
    RB.for elementId


{-| Complete the rotation animation configuration and return an AnimBuilder.

    animations
        |> CSS.builder
        |> Rotation.for "my-element"
        |> Rotation.to 180
        |> Rotation.build
        |> CSS.animate

-}
build : Builder -> AnimBuilder
build =
    RB.build


{-| Set the target rotation angle for the current element (in degrees).

    builder |> Rotate.to 180

-}
to : Rotation -> Builder -> Builder
to targetRotation =
    RB.to (toInternal targetRotation)


{-| Set animation speed for rotation (degrees per second).

    builder |> Rotate.speed 90

-}
speed : Float -> Builder -> Builder
speed degreesPerSecond =
    RB.speed degreesPerSecond


{-| Set animation duration for rotation (milliseconds).

    builder |> Rotate.duration 2000

-}
duration : Int -> Builder -> Builder
duration milliseconds =
    RB.duration milliseconds


{-| Set easing function for rotation animation.

    builder |> Rotate.easing EaseInOut

-}
easing : Easing -> Builder -> Builder
easing easingFunction =
    RB.easing (Easing.mapInternal identity easingFunction)


{-| Set delay for rotation animation (milliseconds).

    builder |> Rotate.delay 500

-}
delay : Delay -> Builder -> Builder
delay delay_ =
    RB.delay (Delay.mapInternal identity delay_)



-- HELPER FUNCTIONS


toInternal : Rotation -> R.Rotation
toInternal degrees =
    R.fromFloat degrees
