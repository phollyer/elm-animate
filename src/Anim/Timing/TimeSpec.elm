module Anim.Timing.TimeSpec exposing
    ( TimeSpec(..)
    , encode
    )

import Json.Encode as Encode


type TimeSpec
    = Duration Int -- milliseconds
    | Speed Float -- units per second


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
