module Anim.Properties.Position exposing
    ( to, speed, duration, easing, delay
    , Position
    )

{-| Position animation property functions.

Use these functions to configure position animations in the builder chain:

    Anim.init "my-element"
        |> Position.to { x = 100, y = 200 }
        |> Position.speed 500
        |> ...


# Position Configuration

@doc Position

@docs to, speed, duration, easing, delay

-}

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PB
import Anim.Internal.Properties.Position as Position
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)
import Anim.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))



-- POSITION CONFIGURATION


{-| 2D position type.

    { x = Float, y = Float }

-}
type alias Position =
    { x : Float, y : Float }


{-| Set the target position for the current element.

    builder |> Position.to { x = 100, y = 200 }

-}
to : Position -> AnimBuilder -> AnimBuilder
to { x, y } builder =
    let
        positionConfig =
            Builder.PositionConfig (Position.fromTuple ( x, y ))
                { timing = Nothing
                , easing = Nothing
                , delay = Nothing
                }
    in
    PB.to positionConfig builder


{-| Set animation speed for position (pixels per second).

    builder |> Position.speed 500

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed pixelsPerSecond =
    timeSpec (Speed pixelsPerSecond)


{-| Set animation duration for position (milliseconds).

    builder |> Position.duration 2000

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration milliseconds =
    timeSpec (Duration milliseconds)


timeSpec : TimeSpec -> AnimBuilder -> AnimBuilder
timeSpec spec builder =
    TimeSpec.mapInternal (\internalSpec -> PB.timeSpec updatePropertySpec internalSpec builder) spec


{-| Set easing function for position animation.

    builder |> Position.easing Ease.inOutQuad

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing easing_ builder =
    Easing.mapInternal (\internalSpec -> PB.easing updatePropertySpec internalSpec builder) easing_


{-| Set delay for position animation (milliseconds).

    builder |> Position.delay 500

-}
delay : Delay -> AnimBuilder -> AnimBuilder
delay delay_ builder =
    Delay.mapInternal (\internalSpec -> PB.delay updatePropertySpec internalSpec builder) delay_


updatePropertySpec : (Builder.PropertySpec -> Builder.PropertySpec) -> Builder.PropertyConfig -> Builder.PropertyConfig
updatePropertySpec updateFn property =
    case property of
        Builder.PositionConfig position spec ->
            Builder.PositionConfig position (updateFn spec)

        other ->
            other
