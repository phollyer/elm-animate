module Anim.Internal.Properties.Rotate exposing
    ( Rotate
    , add
    , distance
    , duration
    , encode
    , equal
    , fromFloat
    , isZero
    , map
    , scale
    , speed
    , subtract
    , toCssString
    , toFloat
    , toString
    , zero
    )

import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))
import Json.Encode as Encode


type Rotate
    = Rotate Float


toFloat : Rotate -> Float
toFloat (Rotate angle) =
    angle


toString : Rotate -> String
toString (Rotate angle) =
    String.fromFloat angle


toCssString : Rotate -> String
toCssString rotation =
    toString rotation ++ "deg"


fromFloat : Float -> Rotate
fromFloat angle =
    Rotate angle


map : (Float -> Float) -> Rotate -> Rotate
map fn (Rotate angle) =
    Rotate (fn angle)


equal : Rotate -> Rotate -> Bool
equal (Rotate angle1) (Rotate angle2) =
    angle1 == angle2


isZero : Rotate -> Bool
isZero (Rotate angle) =
    angle == 0


zero : Rotate
zero =
    Rotate 0


add : Rotate -> Rotate -> Rotate
add (Rotate angle1) (Rotate angle2) =
    Rotate (angle1 + angle2)


subtract : Rotate -> Rotate -> Rotate
subtract (Rotate angle1) (Rotate angle2) =
    Rotate (angle1 - angle2)


distance : Rotate -> Rotate -> Float
distance (Rotate start) (Rotate end) =
    abs (end - start)


speed : Float -> Float -> TimeSpec -> Float
speed distance_ duration_ timeSpec =
    case timeSpec of
        TimeSpec.Duration ms ->
            if ms == 0 then
                distance_ * duration_ * 1000

            else
                distance_ / (Basics.toFloat ms / 1000)

        TimeSpec.Speed degreesPerSecond ->
            degreesPerSecond


duration : Float -> TimeSpec -> Float
duration distance_ timeSpec =
    case timeSpec of
        TimeSpec.Duration ms ->
            Basics.toFloat ms

        TimeSpec.Speed degreesPerSecond ->
            if degreesPerSecond == 0 then
                0

            else
                distance_ / degreesPerSecond * 1000


scale : Float -> Rotate -> Rotate
scale factor (Rotate angle) =
    Rotate (angle * factor)


encode : Rotate -> Encode.Value
encode (Rotate angle) =
    Encode.float angle
