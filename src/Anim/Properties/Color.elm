module Anim.Properties.Color exposing
    ( Builder, for, build, from, to, speed, duration, easing, delay
    , Color(..), Hex, HSL, HSLA, RGB, RGBA
    )

{-| Color animation property functions.

Use these functions to configure color animations in the builder chain:

    Anim.init
        |> Color.for "my-element"
        |> Color.to (Hex "#ff0000")
        |> Color.speed 255
        |> Color.build
        |> CSS.animate


# Build

@docs Builder, for, build, from, to, speed, duration, easing, delay


# Types

@docs Color, Hex, HSL, HSLA, RGB, RGBA

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Color as CB
import Anim.Internal.Properties.Color as C
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)



-- COLOR CONFIGURATION


{-| Type alias for the ColorBuilder.
-}
type alias Builder =
    CB.ColorBuilder


{-| Start configuring color animation for a specific element.

    Anim.init
        |> Color.for "my-element"
        |> Color.to (Hex "#ff0000")
        |> Color.build
        |> CSS.animate

-}
for : String -> AnimBuilder -> Builder
for elementId =
    CB.for elementId


{-| Complete the color configuration and return to AnimBuilder.

    Color.for "element"
        |> Color.to (Hex "#ff0000")
        |> Color.build

-}
build : Builder -> AnimBuilder
build =
    CB.build


{-| Color values in different formats.
-}
type Color
    = Hex Hex
    | Rgb RGB
    | Rgba RGBA
    | Hsl HSL
    | Hsla HSLA


{-| Hex color string, e.g. "#ff0000".
-}
type alias Hex =
    String


{-| HSL color representation.
-}
type alias HSL =
    { h : Float, s : Float, l : Float }


{-| HSLA color representation.
-}
type alias HSLA =
    { h : Float, s : Float, l : Float, a : Float }


{-| RGB color representation.
-}
type alias RGB =
    { r : Int, g : Int, b : Int }


{-| RGBA color representation.
-}
type alias RGBA =
    { r : Int, g : Int, b : Int, a : Float }



-- COLOR CONFIGURATION


{-| Set the starting color for the current element.

    builder |> Color.from (Hex "#ff0000")

    If no starting color is specified, it defaults to black (#000000).

-}
from : Color -> Builder -> Builder
from color =
    CB.from (toInternal color)


{-| Set the target color for the current element.

    builder |> Color.to (Hex "#ff0000")

    builder |> Color.to (Rgb { r = 255, g = 0, b = 0 })

-}
to : Color -> Builder -> Builder
to color =
    CB.to (toInternal color)


{-| Set animation speed for color (color value units per second).

    builder |> Color.speed 255

-}
speed : Float -> Builder -> Builder
speed pixelsPerSecond =
    CB.speed pixelsPerSecond


{-| Set animation duration for color (milliseconds).

    builder |> Color.duration 2000

-}
duration : Int -> Builder -> Builder
duration milliseconds =
    CB.duration milliseconds


{-| Set easing function for color animation.

    builder |> Color.easing EaseInOut

-}
easing : Easing -> Builder -> Builder
easing easing_ =
    Easing.mapInternal CB.easing easing_


{-| Set delay for color animation (milliseconds).

    builder |> Color.delay 500

-}
delay : Delay -> Builder -> Builder
delay delay_ =
    Delay.mapInternal CB.delay delay_


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
