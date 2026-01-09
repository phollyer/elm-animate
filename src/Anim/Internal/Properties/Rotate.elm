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

import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))
import Json.Encode as Encode


type Rotate
    = Rotate { x : Float, y : Float, z : Float }


default : Rotate
default =
    Rotate { x = 0, y = 0, z = 0 }


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
toCssString rotation =
    toString rotation ++ "deg"


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
fromRecord record =
    Rotate record


toRecord : Rotate -> { x : Float, y : Float, z : Float }
toRecord (Rotate record) =
    record


fromTriple : ( Float, Float, Float ) -> Rotate
fromTriple ( x, y, z ) =
    Rotate { x = x, y = y, z = z }


toTriple : Rotate -> ( Float, Float, Float )
toTriple (Rotate angles) =
    ( angles.x, angles.y, angles.z )


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
add (Rotate angles1) (Rotate angles2) =
    Rotate { x = angles1.x + angles2.x, y = angles1.y + angles2.y, z = angles1.z + angles2.z }


subtract : Rotate -> Rotate -> Rotate
subtract (Rotate angles1) (Rotate angles2) =
    Rotate { x = angles1.x - angles2.x, y = angles1.y - angles2.y, z = angles1.z - angles2.z }


distance : Rotate -> Rotate -> Float
distance (Rotate start) (Rotate end) =
    let
        dx =
            abs (end.x - start.x)

        dy =
            abs (end.y - start.y)

        dz =
            abs (end.z - start.z)
    in
    max dx (max dy dz)


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
scale factor (Rotate angles) =
    Rotate { x = angles.x * factor, y = angles.y * factor, z = angles.z * factor }


encode : Rotate -> Encode.Value
encode (Rotate angles) =
    Encode.object
        [ ( "x", Encode.float angles.x )
        , ( "y", Encode.float angles.y )
        , ( "z", Encode.float angles.z )
        ]
