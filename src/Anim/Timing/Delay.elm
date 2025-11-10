module Anim.Timing.Delay exposing
    ( Delay(..), Millis
    , fromInt, toInt, none
    , encode, encodeMaybe
    , mapInternal
    )

{-| Animation delay configuration.

@docs Delay, Millis

@docs fromInt, toInt, none

@docs encode, encodeMaybe

@docs mapInternal

-}

import Anim.Internal.Timing.Delay as D
import Json.Encode as Encode


{-| Animation delay configuration.
-}
type Delay
    = Delay Millis
    | NoDelay


{-| Type alias for milliseconds.
-}
type alias Millis =
    Int


{-| Convert Delay to integer milliseconds.
-}
toInt : Delay -> Millis
toInt delayValue =
    case delayValue of
        Delay d ->
            d

        NoDelay ->
            0


{-| Create Delay from integer milliseconds.
-}
fromInt : Millis -> Delay
fromInt d =
    if d <= 0 then
        NoDelay

    else
        Delay d


{-| No delay.
-}
none : Delay
none =
    NoDelay


{-| Encode Maybe Delay to JSON value.
-}
encodeMaybe : Maybe Delay -> Encode.Value
encodeMaybe maybeDelay =
    case maybeDelay of
        Nothing ->
            Encode.null

        Just delay ->
            mapInternal D.encode delay


{-| Encode Delay to JSON value.
-}
encode : Delay -> Encode.Value
encode =
    mapInternal D.encode


{-| Internal mapping function to convert Delay to underlying representation.
-}
mapInternal : (D.Delay -> a) -> Delay -> a
mapInternal fn =
    fn << toInternal


toInternal : Delay -> D.Delay
toInternal delay =
    case delay of
        Delay d ->
            D.Delay d

        NoDelay ->
            D.NoDelay
