module Anim.Timing.Delay exposing
    ( Millis
    , encode, encodeMaybe
    )

{-| Animation delay configuration.

@docs Millis

@docs encode, encodeMaybe

-}

import Anim.Internal.Timing.Delay as D
import Json.Encode as Encode


{-| Type alias for milliseconds.
-}
type alias Millis =
    Int


{-| Encode Maybe Delay to JSON value.
-}
encodeMaybe : Maybe Millis -> Encode.Value
encodeMaybe =
    D.encodeMaybe


{-| Encode Delay to JSON value.
-}
encode : Millis -> Encode.Value
encode =
    D.encode
