module Anim.Internal.Properties.Rotate exposing
    ( Rotate
    , add
    , default
    , distance
    , duration
    , encode
    , equal
    , fromFloat
    , fromRecord
    , fromTriple
    , interpolate
    , isZero
    , map
    , rotateX
    , rotateY
    , rotateZ
    , scale
    , speed
    , subtract
    , to3DCssString
    , toCssString
    , toFloat
    , toRecord
    , toString
    , toTriple
    , zero
    )

import Anim.Internal.Builders.Coordinate3D as Coordinate3D
import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))
import Json.Encode as Encode


type Rotate
    = Rotate { x : Float, y : Float, z : Float }


default : Rotate
default =
    Rotate { x = 0, y = 0, z = 0 }


{-| Support interface for generic 3D coordinate operations
-}
support : Coordinate3D.Coordinate3DSupport Rotate
support =
    { zero = default
    , fromRecord = Rotate
    , toRecord = \(Rotate angles) -> angles
    , add = \(Rotate a) (Rotate b) -> Rotate { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
    , subtract = \(Rotate a) (Rotate b) -> Rotate { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
    , scale = \factor (Rotate angles) -> Rotate { x = angles.x * factor, y = angles.y * factor, z = angles.z * factor }
    }


toFloat : Rotate -> Float
toFloat (Rotate angles) =
    angles.z


rotateX : Rotate -> Float
rotateX (Rotate angles) =
    angles.x


rotateY : Rotate -> Float
rotateY (Rotate angles) =
    angles.y


rotateZ : Rotate -> Float
rotateZ (Rotate angles) =
    angles.z


toString : Rotate -> String
toString (Rotate angles) =
    String.fromFloat angles.z


toCssString : Rotate -> String
toCssString rotate =
    "rotateZ(" ++ toString rotate ++ "deg)"


to3DCssString : Rotate -> String
to3DCssString (Rotate angles) =
    let
        parts =
            [ if angles.x /= 0 then
                Just ("rotateX(" ++ String.fromFloat angles.x ++ "deg)")

              else
                Nothing
            , if angles.y /= 0 then
                Just ("rotateY(" ++ String.fromFloat angles.y ++ "deg)")

              else
                Nothing
            , if angles.z /= 0 then
                Just ("rotateZ(" ++ String.fromFloat angles.z ++ "deg)")

              else
                Nothing
            ]
                |> List.filterMap identity
    in
    if List.isEmpty parts then
        "rotateZ(0deg)"

    else
        String.join " " parts


fromFloat : Float -> Rotate
fromFloat angle =
    Rotate { x = angle, y = angle, z = angle }


fromRecord : { x : Float, y : Float, z : Float } -> Rotate
fromRecord =
    Coordinate3D.fromRecord support


toRecord : Rotate -> { x : Float, y : Float, z : Float }
toRecord =
    Coordinate3D.toRecord support


fromTriple : ( Float, Float, Float ) -> Rotate
fromTriple =
    Coordinate3D.fromTriple support


toTriple : Rotate -> ( Float, Float, Float )
toTriple =
    Coordinate3D.toTriple support


map : (Float -> Float) -> Rotate -> Rotate
map fn (Rotate angles) =
    Rotate { x = fn angles.x, y = fn angles.y, z = fn angles.z }


equal : Rotate -> Rotate -> Bool
equal (Rotate angles1) (Rotate angles2) =
    angles1.x == angles2.x && angles1.y == angles2.y && angles1.z == angles2.z


isZero : Rotate -> Bool
isZero (Rotate angles) =
    angles.x == 0 && angles.y == 0 && angles.z == 0


zero : Rotate
zero =
    Rotate { x = 0, y = 0, z = 0 }


add : Rotate -> Rotate -> Rotate
add =
    Coordinate3D.add support


subtract : Rotate -> Rotate -> Rotate
subtract =
    Coordinate3D.subtract support


interpolate : Float -> Rotate -> Rotate -> Rotate
interpolate =
    Coordinate3D.interpolate support


distance : Rotate -> Rotate -> Float
distance =
    Coordinate3D.distance support


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
scale =
    Coordinate3D.scale support


encode : Rotate -> Encode.Value
encode (Rotate angles) =
    Encode.object
        [ ( "x", Encode.float angles.x )
        , ( "y", Encode.float angles.y )
        , ( "z", Encode.float angles.z )
        ]
