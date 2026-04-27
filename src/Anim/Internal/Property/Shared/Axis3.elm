module Anim.Internal.Property.Shared.Axis3 exposing
    ( Axis3Support
    , distance
    , fromRecord
    , fromTriple
    , interpolate
    , toRecord
    , toTriple
    )

{-| Generic 3 - axis builder patterns for use across Position, Rotate, and Scale modules.
-}

-- ============================================================
-- MODEL
-- ============================================================


type alias Axis3Support a =
    { -- Constructors
      zero : a
    , fromRecord : { x : Float, y : Float, z : Float } -> a
    , toRecord : a -> { x : Float, y : Float, z : Float }
    , add : a -> a -> a
    , subtract : a -> a -> a
    , scale : Float -> a -> a
    }



-- ============================================================
-- TRANSFORM
-- ============================================================


fromRecord : Axis3Support a -> { x : Float, y : Float, z : Float } -> a
fromRecord support =
    support.fromRecord


toRecord : Axis3Support a -> a -> { x : Float, y : Float, z : Float }
toRecord support =
    support.toRecord


fromTriple : Axis3Support a -> ( Float, Float, Float ) -> a
fromTriple support ( x, y, z ) =
    support.fromRecord { x = x, y = y, z = z }


toTriple : Axis3Support a -> a -> ( Float, Float, Float )
toTriple support coord =
    let
        record =
            support.toRecord coord
    in
    ( record.x, record.y, record.z )



-- ============================================================
-- MATH
-- ============================================================


{-| Calculate distance between coordinates

(Chebyshev distance - the largest single-axis difference)

-}
distance : Axis3Support a -> a -> a -> Float
distance support coord1 coord2 =
    let
        record1 =
            support.toRecord coord1

        record2 =
            support.toRecord coord2

        dx =
            abs (record2.x - record1.x)

        dy =
            abs (record2.y - record1.y)

        dz =
            abs (record2.z - record1.z)
    in
    max dx (max dy dz)


{-| Linear interpolation between coordinates
-}
interpolate : Axis3Support a -> Float -> a -> a -> a
interpolate support t start end =
    let
        startRecord =
            support.toRecord start

        endRecord =
            support.toRecord end
    in
    support.fromRecord
        { x = startRecord.x + (endRecord.x - startRecord.x) * t
        , y = startRecord.y + (endRecord.y - startRecord.y) * t
        , z = startRecord.z + (endRecord.z - startRecord.z) * t
        }
