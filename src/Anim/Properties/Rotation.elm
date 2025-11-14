module Anim.Properties.Rotation exposing (to, speed, duration, easing, delay)

{-| Rotation animation property functions.

Use these functions to configure rotation animations in the builder chain:

    Anim.init "my-element"
        |> Rotate.to 180
        |> Rotate.speed 90
        |> ...


# Rotation Configuration

@doc Rotation

@docs to, speed, duration, easing, delay

-}

import Anim.Internal.Builders.Rotation as RB
import Anim.Internal.Properties.Rotation as R
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)



-- ROTATION CONFIGURATION


type alias RotationBuilder =
    RB.RotationBuilder


{-| Rotation value in degrees.
-}
type alias Rotation =
    Float


{-| Set the target rotation angle for the current element (in degrees).

    builder |> Rotate.to 180

-}
to : Rotation -> RotationBuilder -> RotationBuilder
to targetRotation =
    RB.to (toInternal targetRotation)


{-| Set animation speed for rotation (degrees per second).

    builder |> Rotate.speed 90

-}
speed : Float -> RotationBuilder -> RotationBuilder
speed degreesPerSecond =
    RB.speed degreesPerSecond


{-| Set animation duration for rotation (milliseconds).

    builder |> Rotate.duration 2000

-}
duration : Int -> RotationBuilder -> RotationBuilder
duration milliseconds =
    RB.duration milliseconds


{-| Set easing function for rotation animation.

    builder |> Rotate.easing EaseInOut

-}
easing : Easing -> RotationBuilder -> RotationBuilder
easing easingFunction =
    RB.easing (Easing.mapInternal identity easingFunction)


{-| Set delay for rotation animation (milliseconds).

    builder |> Rotate.delay 500

-}
delay : Delay -> RotationBuilder -> RotationBuilder
delay delay_ =
    RB.delay (Delay.mapInternal identity delay_)



-- HELPER FUNCTIONS


toInternal : Rotation -> R.Rotation
toInternal degrees =
    R.fromFloat degrees
