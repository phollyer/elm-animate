module Anim.Internal.Properties.Scale exposing
    ( Scale
    , encode
    , equal
    , fromTuple
    , fromUniform
    , isUniform
    , map
    , toTuple
    , toUniform
    )

import Json.Encode as Encode


type Scale
    = Scale Float Float


toTuple : Scale -> ( Float, Float )
toTuple (Scale sx sy) =
    ( sx, sy )


fromTuple : ( Float, Float ) -> Scale
fromTuple ( sx, sy ) =
    Scale sx sy


fromUniform : Float -> Scale
fromUniform s =
    Scale s s


toUniform : Scale -> Float
toUniform (Scale sx sy) =
    if sx == sy then
        sx

    else
        1


isUniform : Scale -> Bool
isUniform (Scale sx sy) =
    sx == sy


equal : Scale -> Scale -> Bool
equal (Scale sx1 sy1) (Scale sx2 sy2) =
    sx1 == sx2 && sy1 == sy2


map : (Float -> Float) -> Scale -> Scale
map fn (Scale sx sy) =
    Scale (fn sx) (fn sy)


encode : Scale -> Encode.Value
encode (Scale sx sy) =
    Encode.object
        [ ( "x", Encode.float sx )
        , ( "y", Encode.float sy )
        ]
