module Anim.Properties.Color exposing
    ( Color, Hex, HSL, HSLA, RGB, RGBA
    , to, speed, duration, easing, delay
    )

{-| Color animation property functions.

Use these functions to configure color animations in the builder chain:

    Anim.init "my-element"
        |> Color.to (Hex "#ff0000")
        |> Color.speed 255
        |> animate portFunction


# Types

@docs Color, Hex, HSL, HSLA, RGB, RGBA


# Color Configuration

@docs to, speed, duration, easing, delay

-}

import Anim exposing (AnimBuilder)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PB
import Anim.Internal.Properties.Color as C
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)
import Anim.Timing.TimeSpec as TimeSpec exposing (TimeSpec(..))


{-| Color values in different formats.
-}
type Color
    = Hex Hex
    | Rgb RGB
    | Rgba RGBA
    | Hsl HSL
    | Hsla HSLA


type alias Hex =
    String


type alias HSL =
    { h : Float, s : Float, l : Float }


type alias HSLA =
    { h : Float, s : Float, l : Float, a : Float }


type alias RGB =
    { r : Int, g : Int, b : Int }


type alias RGBA =
    { r : Int, g : Int, b : Int, a : Float }



-- COLOR CONFIGURATION


{-| Set the target color for the current element.

    builder |> Color.to (Hex "#ff0000")

    builder |> Color.to (Rgb { r = 255, g = 0, b = 0 })

-}
to : Color -> AnimBuilder -> AnimBuilder
to color builder =
    let
        colorConfig =
            Builder.ColorConfig (toInternal color)
                { timing = Nothing
                , easing = Nothing
                , delay = Nothing
                }
    in
    PB.to colorConfig builder


{-| Set animation speed for color (color value units per second).

    builder |> Color.speed 255

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed pixelsPerSecond =
    timeSpec (Speed pixelsPerSecond)


{-| Set animation duration for color (milliseconds).

    builder |> Color.duration 2000

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration milliseconds =
    timeSpec (Duration milliseconds)


timeSpec : TimeSpec -> AnimBuilder -> AnimBuilder
timeSpec spec builder =
    TimeSpec.mapInternal (\internalSpec -> PB.timeSpec updatePropertySpec internalSpec builder) spec


{-| Set easing function for color animation.

    builder |> Color.easing EaseInOut

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing easing_ builder =
    Easing.mapInternal (\internalSpec -> PB.easing updatePropertySpec internalSpec builder) easing_


{-| Set delay for color animation (milliseconds).

    builder |> Color.delay 500

-}
delay : Delay -> AnimBuilder -> AnimBuilder
delay delay_ builder =
    Delay.mapInternal (\internalSpec -> PB.delay updatePropertySpec internalSpec builder) delay_


toInternal : Color -> C.Color
toInternal color =
    case color of
        Hex hexString ->
            C.Hex hexString

        Rgb rgb ->
            C.Rgb rgb

        Rgba rgba ->
            C.Rgba rgba

        Hsl hsl ->
            C.Hsl hsl

        Hsla hsla ->
            C.Hsla hsla


updatePropertySpec : (Builder.AnimSpec -> Builder.AnimSpec) -> Builder.PropertyConfig -> Builder.PropertyConfig
updatePropertySpec updateFn property =
    case property of
        Builder.OpacityConfig value spec ->
            Builder.OpacityConfig value (updateFn spec)

        other ->
            other
