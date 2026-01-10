module Anim.Internal.Properties.Position exposing
    ( Position
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



{- UTITLITY FUNCTIONS FOR THE PUBLIC Position TYPE, AND IT'S API -}


type Position
    = Position { x : Float, y : Float, z : Float }


default : Position
default =
    Position { x = 0, y = 0, z = 0 }


{-| Support interface for generic 3D coordinate operations
-}
support : Coordinate3D.Coordinate3DSupport Position
support =
    { zero = default
    , fromRecord = Position
    , toRecord = \(Position coords) -> coords
    , add = \(Position a) (Position b) -> Position { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
    , subtract = \(Position a) (Position b) -> Position { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
    , scale = \factor (Position coords) -> Position { x = coords.x * factor, y = coords.y * factor, z = coords.z * factor }
    }


x : Position -> Float
x (Position coords) =
    coords.x


y : Position -> Float
y (Position coords) =
    coords.y


z : Position -> Float
z (Position coords) =
    coords.z


fromTuple : ( Float, Float ) -> Position
fromTuple =
    Coordinate3D.fromTuple support


fromTriple : ( Float, Float, Float ) -> Position
fromTriple =
    Coordinate3D.fromTriple support


toTuple : Position -> ( Float, Float )
toTuple =
    Coordinate3D.toTuple support


toTriple : Position -> ( Float, Float, Float )
toTriple =
    Coordinate3D.toTriple support


add : Position -> Position -> Position
add =
    Coordinate3D.add support


subtract : Position -> Position -> Position
subtract =
    Coordinate3D.subtract support


scale : Float -> Position -> Position
scale =
    Coordinate3D.scale support


distance : Position -> Position -> Float
distance =
    Coordinate3D.distance support


interpolate : Float -> Position -> Position -> Position
interpolate =
    Coordinate3D.interpolate support


fromRecord : { x : Float, y : Float, z : Float } -> Position
fromRecord =
    Coordinate3D.fromRecord support


toRecord : Position -> { x : Float, y : Float, z : Float }
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


toString : Position -> String
toString (Position coords) =
    "Position(x: " ++ String.fromFloat coords.x ++ ", y: " ++ String.fromFloat coords.y ++ ", z: " ++ String.fromFloat coords.z ++ ")"


toCssString : Position -> String
toCssString (Position coords) =
    String.fromFloat coords.x ++ "px, " ++ String.fromFloat coords.y ++ "px, " ++ String.fromFloat coords.z ++ "px"


encode : Position -> Encode.Value
encode (Position coords) =
    Encode.object
        [ ( "x", Encode.float coords.x )
        , ( "y", Encode.float coords.y )
        , ( "z", Encode.float coords.z )
        ]
