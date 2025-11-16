module Anim.Properties.Scale exposing
    ( Scale(..), ScaleXY, Builder
    , for, build, from, to, speed, duration, easing, delay
    )

{-| Scale animation property functions.

Use these functions to configure scale animations in the builder chain:

    Anim.init
        |> Scale.for "my-element"
        |> Scale.to (ScaleXY 1.5 1.5)
        |> Scale.speed 2.0
        |> Scale.build
        |> CSS.animate


# Types

@docs Scale, ScaleXY, Builder


# Scale Configuration

@docs for, build, from, to, speed, duration, easing, delay

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Scale as SB
import Anim.Internal.Properties.Scale as S
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)



-- SCALE CONFIGURATION


{-| Type alias for the ScaleBuilder.
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


{-| Start configuring scale animation for a specific element.

    Anim.init
        |> Scale.for "my-element"
        |> Scale.to (ScaleXY 1.5 1.5)
        |> Scale.build

-}
for : String -> AnimBuilder -> Builder
for elementId =
    SB.for elementId


{-| Complete the scale animation configuration and return an AnimBuilder.

    animations
        |> CSS.builder
        |> Scale.for "my-element"
        |> Scale.to (ScaleXY 1.5 1.5)
        |> Scale.build
        |> CSS.animate

-}
build : Builder -> AnimBuilder
build =
    SB.build


{-| Set the starting scale for the current element.

    builder |> Scale.from { x = 1.0, y = 1.0 }

-}
from : Scale -> Builder -> Builder
from scale =
    SB.from (toInternal scale)


{-| Set the target scale for the current element.

    builder |> Scale.to (ScaleXY 1.5 1.5)

-}
to : Scale -> Builder -> Builder
to targetScale =
    SB.to (toInternal targetScale)


{-| Set animation speed for scale (scale units per second).

    builder |> Scale.speed 2.0

-}
speed : Float -> Builder -> Builder
speed =
    SB.speed


{-| Set animation duration for scale (milliseconds).

    builder |> Scale.duration 2000

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| Set easing function for scale animation.

    builder |> Scale.easing EaseInOut

-}
easing : Easing -> Builder -> Builder
easing easing_ =
    SB.easing (Easing.mapInternal identity easing_)


{-| Set delay for scale animation (milliseconds).

    builder |> Scale.delay 500

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
