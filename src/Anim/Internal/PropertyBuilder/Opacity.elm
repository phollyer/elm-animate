module Anim.Internal.PropertyBuilder.Opacity exposing
    ( Opacity
    , default
    , distance
    , duration
    , fromFloat
    , interpolate
    , isFullyOpaque
    , isFullyTransparent
    , speed
    , toCssString
    , toFloat
    , toString
    )

import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec)



-- ============================================================
-- TYPES
-- ============================================================


type Opacity
    = Opacity Float


default : Opacity
default =
    Opacity 1



-- ============================================================
-- CONSTRUCTORS
-- ============================================================


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



-- ============================================================
-- MATH
-- ============================================================


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



-- ============================================================
-- CONVERSIONS
-- ============================================================


toString : Opacity -> String
toString (Opacity o) =
    String.fromFloat o


toCssString : Opacity -> String
toCssString (Opacity o) =
    String.fromFloat o
