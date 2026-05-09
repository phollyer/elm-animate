module Shared.TimeSpec exposing
    ( TimeSpec(..)
    , duration
    , speed
    , toCssString
    )


type TimeSpec
    = Duration Int -- milliseconds
    | Speed Float -- units per second


duration : Float -> TimeSpec -> Float
duration distance timeSpec =
    case timeSpec of
        Duration ms ->
            toFloat ms

        Speed unitsPerSecond ->
            if unitsPerSecond == 0 then
                0

            else
                distance / unitsPerSecond * 1000


speed : Float -> Float -> TimeSpec -> Float
speed distance_ duration_ timeSpec =
    case timeSpec of
        Duration ms ->
            if ms <= 0 then
                distance_ * duration_ * 1000

            else
                distance_ / (toFloat ms / 1000)

        Speed unitsPerSecond ->
            unitsPerSecond


toCssString : Float -> Maybe TimeSpec -> String
toCssString distance maybeTimespec =
    case maybeTimespec of
        Just timespec ->
            duration distance timespec
                |> round
                |> String.fromInt
                |> (\msStr -> msStr ++ "ms")

        Nothing ->
            "0ms"
