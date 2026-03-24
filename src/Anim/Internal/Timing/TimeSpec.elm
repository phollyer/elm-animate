module Anim.Internal.Timing.TimeSpec exposing
    ( TimeSpec(..)
    , duration
    , toCssString
    )


type TimeSpec
    = Duration Int -- milliseconds
    | Speed Float -- units per second


duration : Float -> TimeSpec -> Int
duration distance timeSpec =
    case timeSpec of
        Duration ms ->
            ms

        Speed unitsPerSecond ->
            round (distance / unitsPerSecond * 1000)


toCssString : Float -> Maybe TimeSpec -> String
toCssString distance maybeTimespec =
    case maybeTimespec of
        Just timespec ->
            duration distance timespec
                |> String.fromInt
                |> (\msStr -> msStr ++ "ms")

        Nothing ->
            "0ms"
