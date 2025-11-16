module Anim.Internal.Properties.Scale exposing
    ( Scale(..)
    , distance
    , encode
    , equal
    , fromTuple
    , fromUniform
    , isUniform
    , map
    , toCssString
    , toString
    , toTuple
    , toUniform
    )

import Json.Encode as Encode


type Scale
    = ScaleXY Float Float


toString : Scale -> String
toString (ScaleXY sx sy) =
    "Scale(x: " ++ String.fromFloat sx ++ ", y: " ++ String.fromFloat sy ++ ")"


toCssString : Scale -> String
toCssString (ScaleXY sx sy) =
    String.fromFloat sx ++ "," ++ String.fromFloat sy


toTuple : Scale -> ( Float, Float )
toTuple (ScaleXY sx sy) =
    ( sx, sy )


fromTuple : ( Float, Float ) -> Scale
fromTuple ( sx, sy ) =
    ScaleXY sx sy


fromUniform : Float -> Scale
fromUniform s =
    ScaleXY s s


toUniform : Scale -> Float
toUniform (ScaleXY sx sy) =
    if sx == sy then
        sx

    else
        1


isUniform : Scale -> Bool
isUniform (ScaleXY sx sy) =
    sx == sy


equal : Scale -> Scale -> Bool
equal (ScaleXY sx1 sy1) (ScaleXY sx2 sy2) =
    sx1 == sx2 && sy1 == sy2


map : (Float -> Float) -> Scale -> Scale
map fn (ScaleXY sx sy) =
    ScaleXY (fn sx) (fn sy)


encode : Scale -> Encode.Value
encode (ScaleXY sx sy) =
    Encode.object
        [ ( "x", Encode.float sx )
        , ( "y", Encode.float sy )
        ]


{-| Calculate distance between two Scale values using Euclidean distance in scale space.

This follows industry standard vector magnitude calculation for 2D scale transformations:

  - distance = sqrt((sx2-sx1)² + (sy2-sy1)²)

Example:
distance (fromTuple (1.0, 1.0)) (fromTuple (2.0, 1.5))
-- Returns: sqrt((2-1)² + (1.5-1)²) = sqrt(1.25) ≈ 1.118

-}
distance : Scale -> Scale -> Float
distance (ScaleXY sx1 sy1) (ScaleXY sx2 sy2) =
    let
        dx =
            sx2 - sx1

        dy =
            sy2 - sy1
    in
    sqrt (dx * dx + dy * dy)
