module Anim.Properties.Opacity exposing
    ( to, speed, duration, easing, delay
    , Opacity
    )

{-| Opacity animation property functions.

Use these functions to configure opacity animations in the builder chain:

    Anim.init "my-element"
        |> Opacity.to 0.5
        |> Opacity.speed 500
        |> ...


# Opacity Configuration

@doc Opacity

@docs to, speed, duration, easing, delay

-}

import Anim exposing (AnimBuilder)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builders.Property as PB
import Anim.Internal.Properties.Opacity as O
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)
import Anim.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))


{-| Opacity value for elements.
-}
type alias Opacity =
    Float


{-| Animate to a specific opacity value.

    Anim.init "element"
        |> Opacity.to 0.5
        |> Anim.CSS.animate

-}
to : Opacity -> AnimBuilder -> AnimBuilder
to opacity builder =
    let
        opacityConfig =
            Builder.OpacityConfig (O.fromFloat opacity)
                { timing = Nothing
                , easing = Nothing
                , delay = Nothing
                }
    in
    PB.to opacityConfig builder


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


{-| Set delay.
-}
delay : Delay -> AnimBuilder -> AnimBuilder
delay delay_ builder =
    Delay.mapInternal (\internalSpec -> PB.delay updatePropertySpec internalSpec builder) delay_


{-| Set easing function.

    builder |> Opacity.easing EaseInOut

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing easing_ builder =
    Easing.mapInternal (\internalSpec -> PB.easing updatePropertySpec internalSpec builder) easing_


updatePropertySpec : (Builder.PropertySpec -> Builder.PropertySpec) -> Builder.PropertyConfig -> Builder.PropertyConfig
updatePropertySpec updateFn property =
    case property of
        Builder.OpacityConfig value spec ->
            Builder.OpacityConfig value (updateFn spec)

        other ->
            other
