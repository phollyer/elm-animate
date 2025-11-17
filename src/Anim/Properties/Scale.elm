module Anim.Properties.Scale exposing
    ( Builder, for, build
    , from
    , to
    , speed, duration, easing, delay
    , Scale, ScaleXY
    )

{-| Scale animation functions.

Use these functions to configure scale animations in the builder chain:

    animBuilder
        |> Scale.for "my-element"
        |> Scale.to (ScaleXY 1.5 1.5)
        |> Scale.speed 2.0
        |> ... -- other scale configuration steps
        |> Scale.build
        |> ... -- continue with animation


# Build

@docs Builder, for, build


# Configure


## Start Scale

The first time the animation runs, if no starting scale is set, it will default to (1.0, 1.0).

On subsequent animations, it will start from the last known scale, so you only need to set this when you want to override that behavior.

@docs from


## End Scale

@docs to


## Timing

@docs speed, duration, easing, delay


# Types

@docs Scale, ScaleXY

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Scale as SB
import Anim.Internal.Properties.Scale as S
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)



-- SCALE CONFIGURATION


{-| Type alias for the internal `ScaleBuilder`.
-}
type alias Builder =
    SB.ScaleBuilder


{-| Opaque Scale type.
-}
type Scale
    = ScaleXY Float Float


{-| Convenience type alias for ScaleXY constructor.
-}
type alias ScaleXY =
    Float -> Float -> Scale


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


{-| Set the starting scale for the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.from (ScaleXY 1.0 1.0)
        |> ...

-}
from : Scale -> Builder -> Builder
from scale =
    SB.from (toInternal scale)


{-| Set the target scale for the current element.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.to (ScaleXY 1.5 1.5)
        |> ...

-}
to : Scale -> Builder -> Builder
to targetScale =
    SB.to (toInternal targetScale)


{-| Set animation speed for scale (scale factor units per second).

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


{-| Set animation duration for scale (milliseconds).

    animBuilder
        |> Scale.for "my-element"
        |> Scale.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| Set easing function for scale animation.

    animBuilder
        |> Scale.for "my-element"
        |> Scale.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing easing_ =
    SB.easing (Easing.mapInternal identity easing_)


{-| Set delay for scale animation (milliseconds).

    animBuilder
        |> Scale.for "my-element"
        |> Scale.delay 500
        |> ...

-}
delay : Delay -> Builder -> Builder
delay delay_ =
    SB.delay (Delay.mapInternal identity delay_)



-- HELPER FUNCTIONS


toInternal : Scale -> S.Scale
toInternal scale =
    case scale of
        ScaleXY x y ->
            S.ScaleXY x y
