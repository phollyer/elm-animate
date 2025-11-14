module Anim.Internal.Properties.Rotation exposing
    ( Rotation
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


type Rotation
    = Rotation Float


toFloat : Rotation -> Float
toFloat (Rotation angle) =
    angle


toString : Rotation -> String
toString (Rotation angle) =
    String.fromFloat angle


toCssString : Rotation -> String
toCssString rotation =
    toString rotation ++ "deg"


fromFloat : Float -> Rotation
fromFloat angle =
    Rotation angle


map : (Float -> Float) -> Rotation -> Rotation
map fn (Rotation angle) =
    Rotation (fn angle)


equal : Rotation -> Rotation -> Bool
equal (Rotation angle1) (Rotation angle2) =
    angle1 == angle2


isZero : Rotation -> Bool
isZero (Rotation angle) =
    angle == 0


zero : Rotation
zero =
    Rotation 0


add : Rotation -> Rotation -> Rotation
add (Rotation angle1) (Rotation angle2) =
    Rotation (angle1 + angle2)


subtract : Rotation -> Rotation -> Rotation
subtract (Rotation angle1) (Rotation angle2) =
    Rotation (angle1 - angle2)


distance : Rotation -> Rotation -> Float
distance (Rotation start) (Rotation end) =
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


scale : Float -> Rotation -> Rotation
scale factor (Rotation angle) =
    Rotation (angle * factor)


encode : Rotation -> Encode.Value
encode (Rotation angle) =
    Encode.float angle
