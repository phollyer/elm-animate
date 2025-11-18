module Anim.Internal.Timing.Delay exposing
    ( encode
    , encodeMaybe
    , toCssString
    )

import Json.Encode as Encode


toCssString : Maybe Int -> String
toCssString maybeDelayValue =
    case maybeDelayValue of
        Just d ->
            String.fromInt d ++ "ms"

        Nothing ->
            "0ms"


encodeMaybe : Maybe Int -> Encode.Value
encodeMaybe maybeDelay =
    case maybeDelay of
        Just delayValue ->
            encode delayValue

        Nothing ->
            Encode.null


encode : Int -> Encode.Value
encode delayValue =
    Encode.int delayValue
