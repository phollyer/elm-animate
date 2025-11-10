module Anim.Properties.Scale exposing (to, speed, duration, easing, delay)

{-| Scale animation property functions.

Use these functions to configure scale animations in the builder chain:

    Anim.init "my-element"
        |> Scale.to { x = 1.5, y = 1.5 }
        |> Scale.speed 2.0
        |> animate portFunction


# Scale Configuration

@docs to, speed, duration, easing, delay

-}

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PB
import Anim.Internal.Properties.Scale as S
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)
import Anim.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))



-- SCALE CONFIGURATION


type Scale
    = ScaleXY Float Float


{-| Set the target scale for the current element.

    builder |> Scale.to { x = 1.5, y = 1.5 }

-}
to : Scale -> AnimBuilder -> AnimBuilder
to targetScale builder =
    let
        scaleConfig =
            Builder.ScaleConfig (toInternal targetScale)
                { timing = Nothing
                , easing = Nothing
                , delay = Nothing
                }
    in
    PB.to scaleConfig builder


{-| Set animation speed for scale (scale units per second).

    builder |> Scale.speed 2.0

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed unitsPerSecond =
    timeSpec (Speed unitsPerSecond)


{-| Set animation duration for scale (milliseconds).

    builder |> Scale.duration 2000

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration milliseconds =
    timeSpec (Duration milliseconds)


timeSpec : TimeSpec -> AnimBuilder -> AnimBuilder
timeSpec spec builder =
    TimeSpec.mapInternal (\internalSpec -> PB.timeSpec updatePropertySpec internalSpec builder) spec


{-| Set easing function for scale animation.

    builder |> Scale.easing EaseInOut

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing easing_ builder =
    Easing.mapInternal (\internalSpec -> PB.easing updatePropertySpec internalSpec builder) easing_


{-| Set delay for scale animation (milliseconds).

    builder |> Scale.delay 500

-}
delay : Delay -> AnimBuilder -> AnimBuilder
delay delay_ builder =
    Delay.mapInternal (\internalSpec -> PB.delay updatePropertySpec internalSpec builder) delay_



-- HELPER FUNCTIONS


updatePropertySpec : (Builder.PropertySpec -> Builder.PropertySpec) -> Builder.PropertyConfig -> Builder.PropertyConfig
updatePropertySpec updateFn property =
    case property of
        Builder.ScaleConfig scale spec ->
            Builder.ScaleConfig scale (updateFn spec)

        other ->
            other


toInternal : Scale -> S.Scale
toInternal scale =
    case scale of
        ScaleXY x y ->
            S.ScaleXY x y
