module Anim.Timing.Delay exposing
    ( Delay
    , encode
    , encodeMaybe
    , fromInt
    , toInt
    )

import Json.Encode as Encode


type Delay
    = Delay Int
    | NoDelay


toInt : Delay -> Int
toInt delayValue =
    case delayValue of
        Delay d ->
            d

        NoDelay ->
            0


fromInt : Int -> Delay
fromInt d =
    if d <= 0 then
        NoDelay

    else
        Delay d


encodeMaybe : Maybe Delay -> Encode.Value
encodeMaybe maybeDelay =
    case maybeDelay of
        Just delayValue ->
            encode delayValue

        Nothing ->
            Encode.null


encode : Delay -> Encode.Value
encode delayValue =
    case delayValue of
        Delay d ->
            Encode.int d

        NoDelay ->
            Encode.null
