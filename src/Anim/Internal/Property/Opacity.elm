module Anim.Internal.Property.Opacity exposing
    ( Opacity
    , default
    , distance
    , duration
    , fromFloat
    , interpolate
    , isFullyOpaque
    , isFullyTransparent
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
speed =
    TimeSpec.speed


duration : Float -> TimeSpec -> Float
duration =
    TimeSpec.duration
