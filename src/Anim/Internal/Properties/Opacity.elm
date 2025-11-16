module Anim.Internal.Properties.Opacity exposing
    ( Opacity
    , distance
    , encode
    , equal
    , fromFloat
    , isFullyOpaque
    , isFullyTransparent
    , map
    , one
    , toFloat
    , toString
    , zero
    )

import Json.Encode as Encode


type Opacity
    = Opacity Float


toString : Opacity -> String
toString (Opacity o) =
    String.fromFloat o


toFloat : Opacity -> Float
toFloat (Opacity o) =
    o


fromFloat : Float -> Opacity
fromFloat o =
    Opacity o


map : (Float -> Float) -> Opacity -> Opacity
map fn (Opacity o) =
    Opacity (fn o)


equal : Opacity -> Opacity -> Bool
equal (Opacity o1) (Opacity o2) =
    o1 == o2


isFullyOpaque : Opacity -> Bool
isFullyOpaque (Opacity o) =
    o >= 1


isFullyTransparent : Opacity -> Bool
isFullyTransparent (Opacity o) =
    o <= 0


zero : Opacity
zero =
    Opacity 0


{-| Calculate distance between two Opacity values using absolute difference.

This follows industry standard for 1-dimensional opacity values:

  - distance = |opacity2 - opacity1|

Example:
distance (fromFloat 0.2) (fromFloat 0.8)
-- Returns: 0.6

-}
distance : Opacity -> Opacity -> Float
distance (Opacity o1) (Opacity o2) =
    abs (o2 - o1)


one : Opacity
one =
    Opacity 1


encode : Opacity -> Encode.Value
encode (Opacity o) =
    Encode.float o
