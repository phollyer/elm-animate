module Anim.Properties.Rotation exposing (to, speed, duration, easing, delay)

{-| Rotation animation property functions.

Use these functions to configure rotation animations in the builder chain:

    Anim.init "my-element"
        |> Rotate.to 180
        |> Rotate.speed 90
        |> ...


# Rotation Configuration

@doc Rotation

@docs to, speed, duration, easing, delay

-}

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PB
import Anim.Internal.Properties.Rotation as Rotation
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)
import Anim.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))



-- ROTATION CONFIGURATION


{-| Rotation value in degrees.
-}
type alias Rotation =
    Float


{-| Set the target rotation angle for the current element (in degrees).

    builder |> Rotate.to 180

-}
to : Rotation -> AnimBuilder -> AnimBuilder
to targetRotation builder =
    let
        rotateConfig =
            Builder.RotateConfig (Rotation.fromFloat targetRotation)
                { timing = Nothing
                , easing = Nothing
                , delay = Nothing
                }
    in
    PB.to rotateConfig builder


{-| Set animation speed for rotation (degrees per second).

    builder |> Rotate.speed 90

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed degreesPerSecond =
    timeSpec (Speed degreesPerSecond)


{-| Set animation duration for rotation (milliseconds).

    builder |> Rotate.duration 2000

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration milliseconds =
    timeSpec (Duration milliseconds)


timeSpec : TimeSpec -> AnimBuilder -> AnimBuilder
timeSpec spec builder =
    TimeSpec.mapInternal (\internalSpec -> PB.timeSpec updatePropertySpec internalSpec builder) spec


{-| Set easing function for rotation animation.

    builder |> Rotate.easing EaseInOut

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing easingFunction builder =
    Easing.mapInternal (\internalSpec -> PB.easing updatePropertySpec internalSpec builder) easingFunction


{-| Set delay for rotation animation (milliseconds).

    builder |> Rotate.delay 500

-}
delay : Delay -> AnimBuilder -> AnimBuilder
delay delay_ builder =
    Delay.mapInternal (\internalSpec -> PB.delay updatePropertySpec internalSpec builder) delay_



-- HELPER FUNCTIONS


updatePropertySpec : (Builder.PropertySpec -> Builder.PropertySpec) -> Builder.PropertyConfig -> Builder.PropertyConfig
updatePropertySpec updateFn property =
    case property of
        Builder.RotateConfig degrees spec ->
            Builder.RotateConfig degrees (updateFn spec)

        other ->
            other
