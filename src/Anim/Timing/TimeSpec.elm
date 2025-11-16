module Anim.Timing.TimeSpec exposing
    ( TimeSpec(..), Millis, UnitsPerSecond
    , encode, mapInternal
    )

{-| Represents a specification of time for animations, either as a fixed duration in milliseconds
or as a speed in 'property specific units' per second.

@docs TimeSpec, Millis, UnitsPerSecond

@docs encode, mapInternal

-}

import Anim.Internal.Timing.TimeSpec as TS
import Json.Encode as Encode


{-| Represents a specification of time for animations.

  - `Duration Int` specifies a fixed duration in milliseconds.
  - `Speed Float` specifies a speed in pixels (or other units) per second.

-}
type TimeSpec
    = Duration Millis
    | Speed UnitsPerSecond


{-| Type alias for milliseconds.
-}
type alias Millis =
    Int


{-| Type alias for units per second (e.g., pixels per second).
-}
type alias UnitsPerSecond =
    Float


{-| Encode a `TimeSpec` into a JSON value.
-}
encode : TimeSpec -> Encode.Value
encode =
    mapInternal TS.encode


{-| Map a function over the internal `TimeSpec` representation.
-}
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
