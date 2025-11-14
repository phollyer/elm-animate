module Anim.Properties.Opacity exposing
    ( from, to, speed, duration, easing, delay
    , Opacity
    )

{-| Opacity animation property functions.

Use these functions to configure opacity animations in the builder chain:

    Anim.init "my-element"
        |> Opacity.to 0.5
        |> Opacity.speed 500
        |> ...


# Opacity Configuration

@doc Opacity

@docs from, to, speed, duration, easing, delay

-}

import Anim.Internal.Builders.Opacity as OB
import Anim.Internal.Properties.Opacity as O
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)



-- OPACITY CONFIGURATION


type alias OpacityBuilder =
    OB.OpacityBuilder


{-| Opacity value for elements.
-}
type alias Opacity =
    Float


from : Opacity -> OpacityBuilder -> OpacityBuilder
from opacity =
    OB.from (toInternal opacity)


{-| Animate to a specific opacity value.

    Anim.init "element"
        |> Opacity.to 0.5
        |> Anim.CSS.animate

-}
to : Opacity -> OpacityBuilder -> OpacityBuilder
to opacity =
    OB.to (toInternal opacity)


{-| Set animation speed for position (pixels per second).

    builder |> Position.speed 500

-}
speed : Float -> OpacityBuilder -> OpacityBuilder
speed pixelsPerSecond =
    OB.speed pixelsPerSecond


{-| Set animation duration for position (milliseconds).

    builder |> Position.duration 2000

-}
duration : Int -> OpacityBuilder -> OpacityBuilder
duration milliseconds =
    OB.duration milliseconds


{-| Set delay.
-}
delay : Delay -> OpacityBuilder -> OpacityBuilder
delay delay_ =
    OB.delay (Delay.mapInternal identity delay_)


{-| Set easing function.

    builder |> Opacity.easing EaseInOut

-}
easing : Easing -> OpacityBuilder -> OpacityBuilder
easing easing_ =
    OB.easing (Easing.mapInternal identity easing_)



-- INTERNAL HELPERS


toInternal : Opacity -> O.Opacity
toInternal opacity =
    O.fromFloat opacity
