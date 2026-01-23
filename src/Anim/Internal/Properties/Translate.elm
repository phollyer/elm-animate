module Anim.Internal.Properties.Translate exposing
    ( Translate
    , add
    , default
    , distance
    , duration
    , encode
    , fromRecord
    , fromTriple
    , fromTuple
    , interpolate
    , scale
    , speed
    , subtract
    , toCssString
    , toRecord
    , toString
    , toTriple
    , toTuple
    , x
    , y
    , z
    )

import Anim.Internal.Builders.Coordinate3D as Coordinate3D
import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))
import Json.Encode as Encode



{- UTITLITY FUNCTIONS FOR THE PUBLIC Translate TYPE, AND IT'S API -}


type Translate
    = Translate { x : Float, y : Float, z : Float }


default : Translate
default =
    Translate { x = 0, y = 0, z = 0 }


{-| Support interface for generic 3D coordinate operations
-}
support : Coordinate3D.Coordinate3DSupport Translate
support =
    { zero = default
    , fromRecord = Translate
    , toRecord = \(Translate coords) -> coords
    , add = \(Translate a) (Translate b) -> Translate { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
    , subtract = \(Translate a) (Translate b) -> Translate { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
    , scale = \factor (Translate coords) -> Translate { x = coords.x * factor, y = coords.y * factor, z = coords.z * factor }
    }


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
    Coordinate3D.fromTuple support


fromTriple : ( Float, Float, Float ) -> Translate
fromTriple =
    Coordinate3D.fromTriple support


toTuple : Translate -> ( Float, Float )
toTuple =
    Coordinate3D.toTuple support


toTriple : Translate -> ( Float, Float, Float )
toTriple =
    Coordinate3D.toTriple support


add : Translate -> Translate -> Translate
add =
    Coordinate3D.add support


subtract : Translate -> Translate -> Translate
subtract =
    Coordinate3D.subtract support


scale : Float -> Translate -> Translate
scale =
    Coordinate3D.scale support


distance : Translate -> Translate -> Float
distance =
    Coordinate3D.distance support


interpolate : Float -> Translate -> Translate -> Translate
interpolate =
    Coordinate3D.interpolate support


fromRecord : { x : Float, y : Float, z : Float } -> Translate
fromRecord =
    Coordinate3D.fromRecord support


toRecord : Translate -> { x : Float, y : Float, z : Float }
toRecord =
    Coordinate3D.toRecord support


speed : Float -> Float -> TimeSpec -> Float
speed distance_ duration_ timeSpec =
    case timeSpec of
        TimeSpec.Duration ms ->
            if ms == 0 then
                distance_ * duration_ * 1000

            else
                distance_ / (Basics.toFloat ms / 1000)

        TimeSpec.Speed unitsPerSecond ->
            unitsPerSecond


duration : Float -> TimeSpec -> Float
duration distance_ timeSpec =
    case timeSpec of
        TimeSpec.Duration ms ->
            Basics.toFloat ms

        TimeSpec.Speed unitsPerSecond ->
            distance_ / unitsPerSecond * 1000


toString : Translate -> String
toString (Translate coords) =
    "Translate(x: " ++ String.fromFloat coords.x ++ ", y: " ++ String.fromFloat coords.y ++ ", z: " ++ String.fromFloat coords.z ++ ")"


toCssString : Translate -> String
toCssString (Translate coords) =
    String.fromFloat coords.x ++ "px, " ++ String.fromFloat coords.y ++ "px, " ++ String.fromFloat coords.z ++ "px"


encode : Translate -> Encode.Value
encode (Translate coords) =
    Encode.object
        [ ( "x", Encode.float coords.x )
        , ( "y", Encode.float coords.y )
        , ( "z", Encode.float coords.z )
        ]
