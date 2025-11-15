module Anim.Properties.Opacity exposing
    ( Opacity, Builder
    , for, build, from, to, speed, duration, easing, delay
    )

{-| Opacity animation property functions.

Use these functions to configure opacity animations in the builder chain:

    Anim.init
        |> Opacity.for "my-element"
        |> Opacity.to 0.5
        |> Opacity.speed 500
        |> Opacity.build
        |> CSS.animate


# Types

@docs Opacity, Builder


# Opacity Configuration

@docs for, build, from, to, speed, duration, easing, delay

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Opacity as OB
import Anim.Internal.Properties.Opacity as O
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)



-- OPACITY CONFIGURATION


type alias Builder =
    OB.OpacityBuilder


{-| Opacity value for elements.
-}
type alias Opacity =
    Float


{-| Start configuring opacity animation for a specific element.

    Anim.init
        |> Opacity.for "my-element"
        |> Opacity.to 0.5
        |> Opacity.build

-}
for : String -> AnimBuilder -> Builder
for elementId =
    OB.for elementId


{-| Complete the opacity animation configuration and return an AnimBuilder.

    animations
        |> CSS.builder
        |> Opacity.for "my-element"
        |> Opacity.to 0.5
        |> Opacity.build
        |> CSS.animate

-}
build : Builder -> AnimBuilder
build =
    OB.build


from : Opacity -> Builder -> Builder
from opacity =
    OB.from (toInternal opacity)


{-| Animate to a specific opacity value.

    Anim.init
        |> Opacity.for "element"
        |> Opacity.to 0.5
        |> Opacity.build
        |> CSS.animate

-}
to : Opacity -> Builder -> Builder
to opacity =
    OB.to (toInternal opacity)


{-| Set animation speed for position (pixels per second).

    builder |> Position.speed 500

-}
speed : Float -> Builder -> Builder
speed pixelsPerSecond =
    OB.speed pixelsPerSecond


{-| Set animation duration for opacity (milliseconds).

    builder |> Opacity.duration 2000

-}
duration : Int -> Builder -> Builder
duration milliseconds =
    OB.duration milliseconds


{-| Set delay.
-}
delay : Delay -> Builder -> Builder
delay delay_ =
    OB.delay (Delay.mapInternal identity delay_)


{-| Set easing function.

    builder |> Opacity.easing EaseInOut

-}
easing : Easing -> Builder -> Builder
easing easing_ =
    OB.easing (Easing.mapInternal identity easing_)



-- INTERNAL HELPERS


toInternal : Opacity -> O.Opacity
toInternal opacity =
    O.fromFloat opacity
