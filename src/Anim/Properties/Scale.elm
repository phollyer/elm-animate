module Anim.Properties.Scale exposing (from, to, speed, duration, easing, delay)

{-| Scale animation property functions.

Use these functions to configure scale animations in the builder chain:

    Anim.init "my-element"
        |> Scale.to { x = 1.5, y = 1.5 }
        |> Scale.speed 2.0
        |> animate portFunction


# Scale Configuration

@docs Scale

@docs from, to, speed, duration, easing, delay

-}

import Anim.Internal.Builders.Scale as SB
import Anim.Internal.Properties.Scale as S
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)



-- SCALE CONFIGURATION


type alias ScaleBuilder =
    SB.ScaleBuilder


{-| Opaque Scale type.
-}
type Scale
    = ScaleXY Float Float


{-| Set the starting scale for the current element.

    builder |> Scale.from { x = 1.0, y = 1.0 }

-}
from : Scale -> ScaleBuilder -> ScaleBuilder
from scale =
    SB.from (toInternal scale)


{-| Set the target scale for the current element.

    builder |> Scale.to { x = 1.5, y = 1.5 }

-}
to : Scale -> ScaleBuilder -> ScaleBuilder
to targetScale =
    SB.to (toInternal targetScale)


{-| Set animation speed for scale (scale units per second).

    builder |> Scale.speed 2.0

-}
speed : Float -> ScaleBuilder -> ScaleBuilder
speed =
    SB.speed


{-| Set animation duration for scale (milliseconds).

    builder |> Scale.duration 2000

-}
duration : Int -> ScaleBuilder -> ScaleBuilder
duration =
    SB.duration


{-| Set easing function for scale animation.

    builder |> Scale.easing EaseInOut

-}
easing : Easing -> ScaleBuilder -> ScaleBuilder
easing easing_ =
    SB.easing (Easing.mapInternal identity easing_)


{-| Set delay for scale animation (milliseconds).

    builder |> Scale.delay 500

-}
delay : Delay -> ScaleBuilder -> ScaleBuilder
delay delay_ =
    SB.delay (Delay.mapInternal identity delay_)



-- HELPER FUNCTIONS


toInternal : Scale -> S.Scale
toInternal scale =
    case scale of
        ScaleXY x y ->
            S.ScaleXY x y
