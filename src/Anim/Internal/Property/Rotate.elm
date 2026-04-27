module Anim.Internal.Property.Rotate exposing
    ( Rotate
    , default
    , distance
    , duration
    , fromRecord
    , fromTriple
    , getX
    , getY
    , getZ
    , interpolate
    , speed
    , toCssString
    , toRecord
    , toTriple
    )

import Anim.Internal.Property.Shared.Axis3 as Axis
import Shared.TimeSpec as TimeSpec exposing (TimeSpec)


type Rotate
    = Rotate { x : Float, y : Float, z : Float }


default : Rotate
default =
    Rotate { x = 0, y = 0, z = 0 }


{-| Support interface for generic 3D coordinate operations
-}
support : Axis.Axis3Support Rotate
support =
    { zero = default
    , fromRecord = Rotate
    , toRecord = \(Rotate angles) -> angles
    , add = \(Rotate a) (Rotate b) -> Rotate { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
    , subtract = \(Rotate a) (Rotate b) -> Rotate { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
    , scale = \factor (Rotate angles) -> Rotate { x = angles.x * factor, y = angles.y * factor, z = angles.z * factor }
    }



-- ============================================================
-- QUERY
-- ============================================================


getX : Rotate -> Float
getX (Rotate angles) =
    angles.x


getY : Rotate -> Float
getY (Rotate angles) =
    angles.y


getZ : Rotate -> Float
getZ (Rotate angles) =
    angles.z



-- ============================================================
-- TRANSFORM
-- ============================================================


fromRecord : { x : Float, y : Float, z : Float } -> Rotate
fromRecord =
    Axis.fromRecord support


fromTriple : ( Float, Float, Float ) -> Rotate
fromTriple =
    Axis.fromTriple support


toCssString : Rotate -> String
toCssString (Rotate angles) =
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


toRecord : Rotate -> { x : Float, y : Float, z : Float }
toRecord =
    Axis.toRecord support


toTriple : Rotate -> ( Float, Float, Float )
toTriple =
    Axis.toTriple support



-- ============================================================
-- TIMING
-- ============================================================


speed : Float -> Float -> TimeSpec -> Float
speed =
    TimeSpec.speed


duration : Float -> TimeSpec -> Float
duration =
    TimeSpec.duration



-- ============================================================
-- MATH
-- ============================================================


interpolate : Float -> Rotate -> Rotate -> Rotate
interpolate =
    Axis.interpolate support


distance : Rotate -> Rotate -> Float
distance =
    Axis.distance support
