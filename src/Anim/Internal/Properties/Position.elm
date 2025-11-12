module Anim.Internal.Properties.Position exposing
    ( Position
    , add
    , distance
    , duration
    , encode
    , fromTuple
    , interpolate
    , scale
    , speed
    , subtract
    , toCssString
    , toRecord
    , toString
    , toTuple
    , x
    , y
    )

import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))
import Json.Encode as Encode



{- UTITLITY FUNCTIONS FOR THE PUBLIC Position TYPE, AND IT'S API -}


type Position
    = Position { x : Float, y : Float }


x : Position -> Float
x (Position coords) =
    coords.x


y : Position -> Float
y (Position coords) =
    coords.y


fromTuple : ( Float, Float ) -> Position
fromTuple ( xCoord, yCoord ) =
    Position { x = xCoord, y = yCoord }


toTuple : Position -> ( Float, Float )
toTuple (Position coords) =
    ( coords.x, coords.y )


add : Position -> Position -> Position
add (Position a) (Position b) =
    Position { x = a.x + b.x, y = a.y + b.y }


subtract : Position -> Position -> Position
subtract (Position a) (Position b) =
    Position { x = a.x - b.x, y = a.y - b.y }


scale : Float -> Position -> Position
scale factor (Position coords) =
    Position { x = coords.x * factor, y = coords.y * factor }


distance : Position -> Position -> Float
distance (Position a) (Position b) =
    let
        dx =
            a.x - b.x

        dy =
            a.y - b.y
    in
    sqrt (dx * dx + dy * dy)


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
        }


toString : Position -> String
toString (Position coords) =
    "Position(x: " ++ String.fromFloat coords.x ++ ", y: " ++ String.fromFloat coords.y ++ ")"


toCssString : Position -> String
toCssString (Position coords) =
    String.fromFloat coords.x ++ "px, " ++ String.fromFloat coords.y ++ "px"


toRecord : Position -> { x : Float, y : Float }
toRecord (Position coords) =
    { x = coords.x, y = coords.y }


encode : Position -> Encode.Value
encode (Position coords) =
    Encode.object
        [ ( "x", Encode.float coords.x )
        , ( "y", Encode.float coords.y )
        ]
