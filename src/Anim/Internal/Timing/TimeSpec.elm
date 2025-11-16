module Anim.Internal.Timing.TimeSpec exposing
    ( TimeSpec(..)
    , duration
    , encode
    , toCssString
    )

import Json.Encode as Encode


type TimeSpec
    = Duration Int -- milliseconds
    | Speed Float -- units per second


duration : Float -> TimeSpec -> Int
duration distance timeSpec =
    let
        _ =
            Debug.log "Calculating duration for distance:" ( distance, timeSpec )
    in
    case timeSpec of
        Duration ms ->
            ms

        Speed unitsPerSecond ->
            round (distance / unitsPerSecond * 1000)


encode : TimeSpec -> Encode.Value
encode timeSpec =
    case timeSpec of
        Duration ms ->
            Encode.object
                [ ( "type", Encode.string "duration" )
                , ( "value", Encode.int ms )
                ]

        Speed value ->
            Encode.object
                [ ( "type", Encode.string "speed" )
                , ( "value", Encode.float value )
                ]


toCssString : Float -> Maybe TimeSpec -> String
toCssString distance maybeTimespec =
    case maybeTimespec |> Debug.log "Maybe TimeSpec" of
        Just timespec ->
            duration distance timespec
                |> Debug.log "Duration in ms"
                |> String.fromInt
                |> (\msStr -> msStr ++ "ms")
                |> Debug.log "Computed CSS Time String"

        Nothing ->
            "0ms"
