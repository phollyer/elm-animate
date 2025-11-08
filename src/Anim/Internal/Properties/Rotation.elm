module Anim.Internal.Properties.Rotation exposing
    ( Rotation
    , encode
    , equal
    , fromFloat
    , isZero
    , map
    , toFloat
    , zero
    )

import Json.Encode as Encode


type Rotation
    = Rotation Float


toFloat : Rotation -> Float
toFloat (Rotation angle) =
    angle


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


scale : Float -> Rotation -> Rotation
scale factor (Rotation angle) =
    Rotation (angle * factor)


encode : Rotation -> Encode.Value
encode (Rotation angle) =
    Encode.float angle
