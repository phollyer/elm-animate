module Anim.Internal.Properties.Position exposing
    ( Position
    , add
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

import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))
import Json.Encode as Encode



{- UTITLITY FUNCTIONS FOR THE PUBLIC Position TYPE, AND IT'S API -}


type Position
    = Position { x : Float, y : Float, z : Float }


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
fromTuple ( xCoord, yCoord ) =
    Position { x = xCoord, y = yCoord, z = 0 }


fromTriple : ( Float, Float, Float ) -> Position
fromTriple ( xCoord, yCoord, zCoord ) =
    Position { x = xCoord, y = yCoord, z = zCoord }


toTuple : Position -> ( Float, Float )
toTuple (Position coords) =
    ( coords.x, coords.y )


toTriple : Position -> ( Float, Float, Float )
toTriple (Position coords) =
    ( coords.x, coords.y, coords.z )


add : Position -> Position -> Position
add (Position a) (Position b) =
    Position { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }


subtract : Position -> Position -> Position
subtract (Position a) (Position b) =
    Position { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }


scale : Float -> Position -> Position
scale factor (Position coords) =
    Position { x = coords.x * factor, y = coords.y * factor, z = coords.z * factor }


distance : Position -> Position -> Float
distance (Position a) (Position b) =
    let
        dx =
            abs (a.x - b.x)

        dy =
            abs (a.y - b.y)

        dz =
            abs (a.z - b.z)
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

        TimeSpec.Speed unitsPerSecond ->
            unitsPerSecond


duration : Float -> TimeSpec -> Float
duration distance_ timeSpec =
    case timeSpec of
        TimeSpec.Duration ms ->
            Basics.toFloat ms

        TimeSpec.Speed unitsPerSecond ->
            distance_ / unitsPerSecond * 1000


interpolate : Float -> Position -> Position -> Position
interpolate t (Position start) (Position endPos) =
    Position
        { x = start.x + (endPos.x - start.x) * t
        , y = start.y + (endPos.y - start.y) * t
        , z = start.z + (endPos.z - start.z) * t
        }


toString : Position -> String
toString (Position coords) =
    "Position(x: " ++ String.fromFloat coords.x ++ ", y: " ++ String.fromFloat coords.y ++ ", z: " ++ String.fromFloat coords.z ++ ")"


toCssString : Position -> String
toCssString (Position coords) =
    String.fromFloat coords.x ++ "px, " ++ String.fromFloat coords.y ++ "px, " ++ String.fromFloat coords.z ++ "px"


fromRecord : { x : Float, y : Float, z : Float } -> Position
fromRecord record =
    Position record


toRecord : Position -> { x : Float, y : Float, z : Float }
toRecord (Position coords) =
    { x = coords.x, y = coords.y, z = coords.z }


encode : Position -> Encode.Value
encode (Position coords) =
    Encode.object
        [ ( "x", Encode.float coords.x )
        , ( "y", Encode.float coords.y )
        , ( "z", Encode.float coords.z )
        ]
