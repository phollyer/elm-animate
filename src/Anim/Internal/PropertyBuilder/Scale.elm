module Anim.Internal.PropertyBuilder.Scale exposing
    ( Scale(..)
    , add
    , default
    , distance
    , duration
    , fromRecord
    , fromTriple
    , fromTuple
    , fromUniform
    , getX
    , getY
    , getZ
    , interpolate
    , isUniform
    , speed
    , subtract
    , toCssPropertyValue
    , toCssString
    , toRecord
    , toString
    , toTriple
    , toTuple
    , toUniform
    )

import Anim.Internal.Extra.Coordinate3D as Coordinate3D
import Shared.TimeSpec as TimeSpec exposing (TimeSpec)



-- ============================================================
-- TYPES
-- ============================================================


type Scale
    = Scale { x : Float, y : Float, z : Float }


default : Scale
default =
    Scale { x = 1.0, y = 1.0, z = 1.0 }


{-| Support interface for generic 3D coordinate operations
-}
support : Coordinate3D.Coordinate3DSupport Scale
support =
    { zero = default -- For Scale, "zero" is actually (1,1,1)
    , fromRecord = Scale
    , toRecord = \(Scale coords) -> coords

    -- Scale uses additive operations: 1.0 + 0.2 = 1.2 (120% scale)
    , add = \(Scale a) (Scale b) -> Scale { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
    , subtract = \(Scale a) (Scale b) -> Scale { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
    , scale = \factor (Scale coords) -> Scale { x = coords.x * factor, y = coords.y * factor, z = coords.z * factor }
    }



-- ============================================================
-- CONVERSIONS
-- ============================================================


toString : Scale -> String
toString (Scale { x, y, z }) =
    "Scale(x: " ++ String.fromFloat x ++ ", y: " ++ String.fromFloat y ++ ", z: " ++ String.fromFloat z ++ ")"


toCssString : Scale -> String
toCssString (Scale { x, y, z }) =
    let
        parts =
            [ if x /= 1.0 then
                Just ("scaleX(" ++ String.fromFloat x ++ ")")

              else
                Nothing
            , if y /= 1.0 then
                Just ("scaleY(" ++ String.fromFloat y ++ ")")

              else
                Nothing
            , if z /= 1.0 then
                Just ("scaleZ(" ++ String.fromFloat z ++ ")")

              else
                Nothing
            ]
                |> List.filterMap identity
    in
    case parts of
        [] ->
            "scale3d(1,1,1)"

        [ single ] ->
            single

        multiple ->
            String.join " " multiple


toCssPropertyValue : Scale -> String
toCssPropertyValue (Scale { x, y, z }) =
    if z /= 1.0 then
        String.fromFloat x ++ " " ++ String.fromFloat y ++ " " ++ String.fromFloat z

    else if x == y then
        String.fromFloat x

    else
        String.fromFloat x ++ " " ++ String.fromFloat y



-- ============================================================
-- CONSTRUCTORS
-- ============================================================


toTuple : Scale -> ( Float, Float )
toTuple =
    Coordinate3D.toTuple support


fromTuple : ( Float, Float ) -> Scale
fromTuple ( x, y ) =
    -- Scale uses 1.0 as default Z instead of 0
    Scale { x = x, y = y, z = 1.0 }


toTriple : Scale -> ( Float, Float, Float )
toTriple =
    Coordinate3D.toTriple support


fromTriple : ( Float, Float, Float ) -> Scale
fromTriple =
    Coordinate3D.fromTriple support


toRecord : Scale -> { x : Float, y : Float, z : Float }
toRecord =
    Coordinate3D.toRecord support


fromRecord : { x : Float, y : Float, z : Float } -> Scale
fromRecord =
    Coordinate3D.fromRecord support


fromUniform : Float -> Scale
fromUniform s =
    Scale { x = s, y = s, z = s }


toUniform : Scale -> Float
toUniform (Scale { x, y, z }) =
    if x == y && y == z then
        x

    else
        1


isUniform : Scale -> Bool
isUniform (Scale { x, y, z }) =
    x == y && y == z


getY : Scale -> Float
getY (Scale { y }) =
    y


getX : Scale -> Float
getX (Scale { x }) =
    x


getZ : Scale -> Float
getZ (Scale { z }) =
    z



-- ============================================================
-- MATH
-- ============================================================


add : Scale -> Scale -> Scale
add =
    Coordinate3D.add support


subtract : Scale -> Scale -> Scale
subtract =
    Coordinate3D.subtract support


interpolate : Float -> Scale -> Scale -> Scale
interpolate =
    Coordinate3D.interpolate support



{- Calculate distance between two Scale values using max-axis distance.

   Uses the maximum absolute difference across all scale axes (x, y, z).
   This provides more intuitive animation timing where the longest-changing axis
   determines the duration.

     - distance = max(|sx2-sx1|, |sy2-sy1|, |sz2-sz1|)

   Example:
   distance (fromTriple (1.0, 1.0, 1.0)) (fromTriple (2.0, 1.5, 1.2))
   -- Returns: max(1.0, 0.5, 0.2) = 1.0

-}


distance : Scale -> Scale -> Float
distance =
    Coordinate3D.distance support


{-| Calculate animation speed from distance, duration, and time specification.

For Duration-based timing: speed = distance / (duration in seconds)
For Speed-based timing: returns the specified speed directly

-}
speed : Float -> Float -> TimeSpec -> Float
speed =
    TimeSpec.speed


{-| Calculate animation duration from distance and time specification.

For Duration-based timing: returns the specified duration in milliseconds
For Speed-based timing: duration = (distance / speed) \* 1000

-}
duration : Float -> TimeSpec -> Float
duration =
    TimeSpec.duration
