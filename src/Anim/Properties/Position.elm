module Anim.Properties.Position exposing
    ( Position
    , from, to, speed, duration, easing, delay
    , toInternal
    )

{-| Position animation property functions.

Use these functions to configure position animations in the builder chain:

    Anim.init "my-element"
        |> Position.to { x = 100, y = 200 }
        |> Position.speed 500
        |> ...


# Position Configuration

@docs Position

@docs from, to, speed, duration, easing, delay

-}

import Anim.Internal.Builders.Position as PB
import Anim.Internal.Properties.Position as P
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)



-- POSITION CONFIGURATION


type alias PositionBuilder =
    PB.PositionBuilder


{-| Opaque Position type.
-}
type Position
    = Position { x : Float, y : Float }


from : Position -> PositionBuilder -> PositionBuilder
from position =
    PB.from (toInternal position)


{-| Set the target position for the current element.

    builder |> Position.to { x = 100, y = 200 }

-}
to : Position -> PositionBuilder -> PositionBuilder
to position =
    PB.to (toInternal position)


{-| Set animation speed for position (pixels per second).

    builder |> Position.speed 500

-}
speed : Float -> PositionBuilder -> PositionBuilder
speed =
    PB.speed


{-| Set animation duration for position (milliseconds).

    builder |> Position.duration 2000

-}
duration : Int -> PositionBuilder -> PositionBuilder
duration =
    PB.duration


{-| Set easing function for position animation.

    builder |> Position.easing Ease.inOutQuad

-}
easing : Easing -> PositionBuilder -> PositionBuilder
easing easing_ =
    PB.easing (Easing.mapInternal identity easing_)


{-| Set delay for position animation (milliseconds).

    builder |> Position.delay 500

-}
delay : Delay -> PositionBuilder -> PositionBuilder
delay delay_ =
    PB.delay (Delay.mapInternal identity delay_)


toInternal : Position -> P.Position
toInternal (Position { x, y }) =
    P.fromTuple ( x, y )
