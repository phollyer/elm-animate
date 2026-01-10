module Anim.Internal.Builders.Coordinate3D exposing
    ( Coordinate3DSupport
    , add
    , distance
    , fromRecord
    , fromTriple
    , fromTuple
    , interpolate
    , scale
    , subtract
    , toRecord
    , toTriple
    , toTuple
    , zero
    )

{-| Generic 3D coordinate system builder patterns for use across Position, Rotate, and Scale modules.
Eliminates duplication by providing common operations through a support interface.
-}


{-| Support interface for 3D coordinate types.
Allows generic operations on Position, Rotate, Scale without duplicating code.
All operations are optional to support different coordinate semantics.
-}
type alias Coordinate3DSupport a =
    { -- Constructors
      zero : a
    , fromRecord : { x : Float, y : Float, z : Float } -> a

    -- Accessors
    , toRecord : a -> { x : Float, y : Float, z : Float }

    -- Optional operations (may be identity functions for some types)
    , add : a -> a -> a
    , subtract : a -> a -> a
    , scale : Float -> a -> a
    }


{-| Create coordinate from 2D tuple, Z defaults to 0
-}
fromTuple : Coordinate3DSupport a -> ( Float, Float ) -> a
fromTuple support ( x, y ) =
    support.fromRecord { x = x, y = y, z = 0 }


{-| Create coordinate from 3D tuple
-}
fromTriple : Coordinate3DSupport a -> ( Float, Float, Float ) -> a
fromTriple support ( x, y, z ) =
    support.fromRecord { x = x, y = y, z = z }


{-| Convert coordinate to 2D tuple
-}
toTuple : Coordinate3DSupport a -> a -> ( Float, Float )
toTuple support coord =
    let
        record =
            support.toRecord coord
    in
    ( record.x, record.y )


{-| Convert coordinate to 3D tuple
-}
toTriple : Coordinate3DSupport a -> a -> ( Float, Float, Float )
toTriple support coord =
    let
        record =
            support.toRecord coord
    in
    ( record.x, record.y, record.z )


{-| Add two coordinates
-}
add : Coordinate3DSupport a -> a -> a -> a
add support =
    support.add


{-| Subtract two coordinates
-}
subtract : Coordinate3DSupport a -> a -> a -> a
subtract support =
    support.subtract


{-| Scale coordinate by factor
-}
scale : Coordinate3DSupport a -> Float -> a -> a
scale support =
    support.scale


{-| Calculate distance between coordinates (Manhattan distance)
-}
distance : Coordinate3DSupport a -> a -> a -> Float
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
interpolate : Coordinate3DSupport a -> Float -> a -> a -> a
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


{-| Create coordinate from record
-}
fromRecord : Coordinate3DSupport a -> { x : Float, y : Float, z : Float } -> a
fromRecord support =
    support.fromRecord


{-| Convert coordinate to record
-}
toRecord : Coordinate3DSupport a -> a -> { x : Float, y : Float, z : Float }
toRecord support =
    support.toRecord


{-| Zero coordinate
-}
zero : Coordinate3DSupport a -> a
zero support =
    support.zero
