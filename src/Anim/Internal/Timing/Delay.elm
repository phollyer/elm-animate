module Anim.Internal.Timing.Delay exposing
    ( encode
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


encode : Int -> Encode.Value
encode delayValue =
    Encode.int delayValue
