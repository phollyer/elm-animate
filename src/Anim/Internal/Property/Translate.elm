module Anim.Internal.Property.Translate exposing
    ( Translate
    , add
    , default
    , distance
    , duration
    , fromRecord
    , fromTriple
    , fromTuple
    , interpolate
    , speed
    , subtract
    , toCssPropertyValue
    , toCssString
    , toName
    , toRecord
    , toString
    , toTriple
    , toTuple
    , x
    , y
    , z
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


x : Translate -> Float
x (Translate coords) =
    coords.x


y : Translate -> Float
y (Translate coords) =
    coords.y


z : Translate -> Float
z (Translate coords) =
    coords.z


fromTuple : ( Float, Float ) -> Translate
fromTuple =
    Axis.fromTuple support


fromTriple : ( Float, Float, Float ) -> Translate
fromTriple =
    Axis.fromTriple support


toTuple : Translate -> ( Float, Float )
toTuple =
    Axis.toTuple support


toTriple : Translate -> ( Float, Float, Float )
toTriple =
    Axis.toTriple support



-- ============================================================
-- MATH
-- ============================================================


add : Translate -> Translate -> Translate
add =
    Axis.add support


subtract : Translate -> Translate -> Translate
subtract =
    Axis.subtract support


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


toString : Translate -> String
toString (Translate coords) =
    "Translate(x: " ++ String.fromFloat coords.x ++ ", y: " ++ String.fromFloat coords.y ++ ", z: " ++ String.fromFloat coords.z ++ ")"


toCssString : Translate -> String
toCssString (Translate coords) =
    "translate3d(" ++ String.fromFloat coords.x ++ "px, " ++ String.fromFloat coords.y ++ "px, " ++ String.fromFloat coords.z ++ "px)"


toCssPropertyValue : Translate -> String
toCssPropertyValue (Translate coords) =
    String.fromFloat coords.x ++ "px " ++ String.fromFloat coords.y ++ "px " ++ String.fromFloat coords.z ++ "px"


toName : String
toName =
    "translate"
