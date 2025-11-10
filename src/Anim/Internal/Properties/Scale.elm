module Anim.Internal.Properties.Scale exposing
    ( Scale(..)
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
