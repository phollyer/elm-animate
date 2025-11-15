module Anim.Properties.Position exposing
    ( Position
    , from, to, speed, duration, easing, delay
    , Builder, build, for, toInternal, toX, toXY, toY
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

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Position as PB
import Anim.Internal.Properties.Position as P
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)



-- POSITION CONFIGURATION


type alias Builder =
    PB.PositionBuilder


{-| Opaque Position type.
-}
type Position
    = Position { x : Float, y : Float }


for : String -> AnimBuilder -> Builder
for elementId =
    PB.for elementId


build : Builder -> AnimBuilder
build =
    PB.build


from : Position -> Builder -> Builder
from position =
    PB.from (toInternal position)


{-| Set the target position for the current element.

    builder |> Position.to { x = 100, y = 200 }

-}
to : Position -> Builder -> Builder
to position =
    PB.to (toInternal position)


toXY : Float -> Float -> Builder -> Builder
toXY x y =
    PB.to (P.fromTuple ( x, y ))


toX : Float -> Builder -> Builder
toX x =
    PB.toX x


toY : Float -> Builder -> Builder
toY y =
    PB.toY y


{-| Set animation speed for position (pixels per second).

    builder |> Position.speed 500

-}
speed : Float -> Builder -> Builder
speed =
    PB.speed


{-| Set animation duration for position (milliseconds).

    builder |> Position.duration 2000

-}
duration : Int -> Builder -> Builder
duration =
    PB.duration


{-| Set easing function for position animation.

    builder |> Position.easing Ease.inOutQuad

-}
easing : Easing -> Builder -> Builder
easing easing_ =
    PB.easing (Easing.mapInternal identity easing_)


{-| Set delay for position animation (milliseconds).

    builder |> Position.delay 500

-}
delay : Delay -> Builder -> Builder
delay delay_ =
    PB.delay (Delay.mapInternal identity delay_)


toInternal : Position -> P.Position
toInternal (Position { x, y }) =
    P.fromTuple ( x, y )
