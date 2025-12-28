module Anim.Internal.Properties.Scale exposing
    ( Scale(..)
    , distance
    , encode
    , equal
    , fromTriple
    , fromTuple
    , fromUniform
    , getX
    , getY
    , getZ
    , isUniform
    , map
    , to3DCssString
    , toCssString
    , toRecord
    , toString
    , toTriple
    , toTuple
    , toUniform
    )

import Json.Encode as Encode


type Scale
    = Scale { x : Float, y : Float, z : Float }


toString : Scale -> String
toString (Scale { x, y, z }) =
    "Scale(x: " ++ String.fromFloat x ++ ", y: " ++ String.fromFloat y ++ ", z: " ++ String.fromFloat z ++ ")"



-- 2D backward compatible CSS string


toCssString : Scale -> String
toCssString (Scale { x, y }) =
    String.fromFloat x ++ "," ++ String.fromFloat y



-- 3D CSS string using scale3d()


to3DCssString : Scale -> String
to3DCssString (Scale { x, y, z }) =
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


toTuple : Scale -> ( Float, Float )
toTuple (Scale { x, y }) =
    ( x, y )


fromTuple : ( Float, Float ) -> Scale
fromTuple ( x, y ) =
    Scale { x = x, y = y, z = 1.0 }


toTriple : Scale -> ( Float, Float, Float )
toTriple (Scale { x, y, z }) =
    ( x, y, z )


fromTriple : ( Float, Float, Float ) -> Scale
fromTriple ( x, y, z ) =
    Scale { x = x, y = y, z = z }


toRecord : Scale -> { x : Float, y : Float, z : Float }
toRecord (Scale record) =
    record


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


equal : Scale -> Scale -> Bool
equal (Scale scale1) (Scale scale2) =
    scale1.x == scale2.x && scale1.y == scale2.y && scale1.z == scale2.z


map : (Float -> Float) -> Scale -> Scale
map fn (Scale { x, y, z }) =
    Scale { x = fn x, y = fn y, z = fn z }


encode : Scale -> Encode.Value
encode (Scale { x, y, z }) =
    Encode.object
        [ ( "x", Encode.float x )
        , ( "y", Encode.float y )
        , ( "z", Encode.float z )
        ]


getY : Scale -> Float
getY (Scale { y }) =
    y


getX : Scale -> Float
getX (Scale { x }) =
    x


getZ : Scale -> Float
getZ (Scale { z }) =
    z



{- Calculate distance between two Scale values using Euclidean distance in 3D scale space.

   This follows industry standard vector magnitude calculation for 3D scale transformations:

     - distance = sqrt((sx2-sx1)² + (sy2-sy1)² + (sz2-sz1)²)

   Example:
   distance (fromTriple (1.0, 1.0, 1.0)) (fromTriple (2.0, 1.5, 1.2))
   -- Returns: sqrt((2-1)² + (1.5-1)² + (1.2-1)²) = sqrt(1.29) ≈ 1.136

-}


distance : Scale -> Scale -> Float
distance (Scale scale1) (Scale scale2) =
    let
        dx =
            scale2.x - scale1.x

        dy =
            scale2.y - scale1.y

        dz =
            scale2.z - scale1.z
    in
    sqrt (dx * dx + dy * dy + dz * dz)
