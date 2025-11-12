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


duration : Int -> TimeSpec -> Int
duration distance timeSpec =
    case timeSpec of
        Duration ms ->
            ms

        Speed unitsPerSecond ->
            round (Basics.toFloat distance / unitsPerSecond * 1000)


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


toCssString : TimeSpec -> String
toCssString timeSpec =
    case timeSpec of
        Duration ms ->
            String.fromInt ms ++ "ms"

        Speed pixelsPerSecond ->
            -- Convert speed to duration (approximate for CSS)
            -- Assume 100px movement for speed-based timing
            -- TODO: Need to use the actual distance for accurate duration
            -- Add the distance parameter to this function
            -- Then follow the compiler errors back to fix the callsites
            let
                estimatedDuration =
                    round (100 / pixelsPerSecond * 1000)
            in
            String.fromInt estimatedDuration ++ "ms"
