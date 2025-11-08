module Anim.Properties.Position exposing
    ( to, speed, duration, easing, delay
    , Position
    )

{-| Position animation property functions.

Use these functions to configure position animations in the builder chain:

    Anim.init "my-element"
        |> Position.to { x = 100, y = 200 }
        |> Position.speed 500
        |> animate portFunction


# Position Configuration

@doc Position

@docs to, speed, duration, easing, delay

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Position as PB
import Anim.Internal.Properties.Position as Position
import Anim.Timing.Easing exposing (Easing)



-- POSITION CONFIGURATION


{-| 2D position type.

    { x = Float, y = Float }

-}
type alias Position =
    { x : Float, y : Float }


{-| Set the target position for the current element.

    builder |> Position.to { x = 100, y = 200 }

-}
to : Position -> AnimBuilder -> AnimBuilder
to { x, y } =
    PB.to (Position.fromTuple ( x, y ))


{-| Set animation speed for position (pixels per second).

    builder |> Position.speed 500

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    PB.speed


{-| Set animation duration for position (milliseconds).

    builder |> Position.duration 2000

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    PB.duration


{-| Set easing function for position animation.

    builder |> Position.easing Ease.inOutQuad

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    PB.easing


{-| Set delay for position animation (milliseconds).

    builder |> Position.delay 500

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    PB.delay
