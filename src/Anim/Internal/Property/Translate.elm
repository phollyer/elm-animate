module Anim.Internal.Property.Translate exposing
    ( Translate
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
    , toCssPropertyValue
    , toCssString
    , toRecord
    , toTriple
    )

import Anim.Internal.Property.Shared.Axis3 as Axis
import Shared.TimeSpec as TimeSpec exposing (TimeSpec)



-- ============================================================
-- TYPES
-- ============================================================


type Translate
    = Translate { x : Float, y : Float, z : Float }


default : Translate
default =
    Translate { x = 0, y = 0, z = 0 }


{-| Support interface for generic 3D coordinate operations
-}
support : Axis.Axis3Support Translate
support =
    { zero = default
    , fromRecord = Translate
    , toRecord = \(Translate coords) -> coords
    , add = \(Translate a) (Translate b) -> Translate { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
    , subtract = \(Translate a) (Translate b) -> Translate { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
    , scale = \factor (Translate coords) -> Translate { x = coords.x * factor, y = coords.y * factor, z = coords.z * factor }
    }



-- ============================================================
-- CONSTRUCTORS
-- ============================================================


getX : Translate -> Float
getX (Translate coords) =
    coords.x


getY : Translate -> Float
getY (Translate coords) =
    coords.y


getZ : Translate -> Float
getZ (Translate coords) =
    coords.z


fromTriple : ( Float, Float, Float ) -> Translate
fromTriple =
    Axis.fromTriple support


toTriple : Translate -> ( Float, Float, Float )
toTriple =
    Axis.toTriple support



-- ============================================================
-- MATH
-- ============================================================


distance : Translate -> Translate -> Float
distance =
    Axis.distance support


interpolate : Float -> Translate -> Translate -> Translate
interpolate =
    Axis.interpolate support


fromRecord : { x : Float, y : Float, z : Float } -> Translate
fromRecord =
    Axis.fromRecord support


toRecord : Translate -> { x : Float, y : Float, z : Float }
toRecord =
    Axis.toRecord support


speed : Float -> Float -> TimeSpec -> Float
speed =
    TimeSpec.speed


duration : Float -> TimeSpec -> Float
duration =
    TimeSpec.duration



-- ============================================================
-- CONVERSIONS
-- ============================================================


toCssString : Translate -> String
toCssString (Translate coords) =
    "translate3d(" ++ String.fromFloat coords.x ++ "px, " ++ String.fromFloat coords.y ++ "px, " ++ String.fromFloat coords.z ++ "px)"


toCssPropertyValue : Translate -> String
toCssPropertyValue (Translate coords) =
    String.fromFloat coords.x ++ "px " ++ String.fromFloat coords.y ++ "px " ++ String.fromFloat coords.z ++ "px"
