module Anim.Properties.Rotate exposing
    ( Builder, for, build
    , from
    , to
    , speed, duration, easing, delay
    )

{-| Rotate animation functions.

Use these functions to configure rotate animations in the builder chain:

    animBuilder
        |> Rotate.for "my-element"
        |> Rotate.to 180
        |> ... -- other rotate configuration steps
        |> Rotate.build
        |> ... -- continue with animation


# Build

@docs Builder, for, build


# Configure


## Start Rotation

The first time the animation runs, if no starting rotation is set, it will default to 0 degrees.

On subsequent animations, it will start from the last known rotation, so you only need to set this when you want to override that behavior.

@docs from


## End Rotation

@docs to


## Timing

@docs speed, duration, easing, delay

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


{-| Set the target rotation for the current element.

    animBuilder
        |> Rotation.for "my-element"
        |> Rotation.to 180
        |> ...

-}
to : Float -> Builder -> Builder
to targetRotation =
    RB.to (R.fromFloat targetRotation)


{-| Set animation speed for rotation (degrees per second).

    animBuilder
        |> Rotation.for "my-element"
        |> Rotation.to 180
        |> Rotation.speed 90
        |> ...

-}
speed : Float -> Builder -> Builder
speed degreesPerSecond =
    RB.speed degreesPerSecond


{-| Set animation duration for rotation (milliseconds).

    animBuilder
        |> Rotation.for "my-element"
        |> Rotation.to 180
        |> Rotation.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration milliseconds =
    RB.duration milliseconds


{-| Set easing function for rotation animation.

    animBuilder
        |> Rotation.for "my-element"
        |> Rotation.to 180
        |> Rotation.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing easingFunction =
    RB.easing (Easing.mapInternal identity easingFunction)


{-| Set delay for rotation animation (milliseconds).

    animBuilder
        |> Rotation.for "my-element"
        |> Rotation.to 180
        |> Rotation.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay delay_ =
    RB.delay delay_
