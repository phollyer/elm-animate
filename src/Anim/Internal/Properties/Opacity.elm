module Anim.Internal.Properties.Opacity exposing
    ( Opacity
    , default
    , distance
    , duration
    , fromFloat
    , interpolate
    , isFullyOpaque
    , isFullyTransparent
    , one
    , speed
    , toFloat
    , toString
    , zero
    )

import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec)


type Opacity
    = Opacity Float


default : Opacity
default =
    Opacity 1


toString : Opacity -> String
toString (Opacity o) =
    String.fromFloat o


toFloat : Opacity -> Float
toFloat (Opacity o) =
    o


fromFloat : Float -> Opacity
fromFloat o =
    Opacity o


isFullyOpaque : Opacity -> Bool
isFullyOpaque (Opacity o) =
    o >= 1


isFullyTransparent : Opacity -> Bool
isFullyTransparent (Opacity o) =
    o <= 0


zero : Opacity
zero =
    Opacity 0


distance : Opacity -> Opacity -> Float
distance (Opacity o1) (Opacity o2) =
    abs (o2 - o1)


interpolate : Float -> Opacity -> Opacity -> Opacity
interpolate t (Opacity start) (Opacity end) =
    Opacity (start + (end - start) * t)


speed : Float -> Float -> TimeSpec -> Float
speed distance_ duration_ timeSpec =
    case timeSpec of
        TimeSpec.Duration ms ->
            if ms <= 0 then
                distance_ * duration_ * 1000

            else
                distance_ / (Basics.toFloat ms / 1000)

        TimeSpec.Speed unitsPerSecond ->
            unitsPerSecond


duration : Float -> TimeSpec -> Float
duration distance_ timeSpec =
    case timeSpec of
        TimeSpec.Duration ms ->
            Basics.toFloat ms

        TimeSpec.Speed unitsPerSecond ->
            distance_ / unitsPerSecond * 1000


one : Opacity
one =
    Opacity 1
