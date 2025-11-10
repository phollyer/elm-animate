module Anim.Timing.TimeSpec exposing
    ( TimeSpec(..)
    , encode
    , mapInternal
    )

import Anim.Internal.Timing.TimeSpec as TS
import Json.Encode as Encode


type TimeSpec
    = Duration Millis
    | Speed PixelsPerSecond


type alias Millis =
    Int


type alias PixelsPerSecond =
    Float


encode : TimeSpec -> Encode.Value
encode =
    mapInternal TS.encode


mapInternal : (TS.TimeSpec -> a) -> TimeSpec -> a
mapInternal fn =
    fn << toInternal


toInternal : TimeSpec -> TS.TimeSpec
toInternal spec =
    case spec of
        Duration ms ->
            TS.Duration ms

        Speed value ->
            TS.Speed value
