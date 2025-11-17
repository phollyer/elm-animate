module Anim.Properties.Color exposing
    ( Builder, for, build
    , from
    , to
    , speed, duration, easing, delay
    , Color(..), Hex, HSL, HSLA, RGB, RGBA
    )

{-| Color animation functions.

Use these functions to configure color animations in the builder chain:

    animBuilder
        |> Color.for "my-element"
        |> Color.to (Hex "#ff0000")
        |> Color.speed 255
        |> ... -- other color configuration steps
        |> Color.build
        |> ... -- continue with animation


# Build

@docs Builder, for, build


# Configure


## Start Color

The first time the animation runs, if no starting color is set, it will default to black (#000000).

On subsequent animations, it will start from the last known color, so you only need to set this when you want to override that behavior.

@docs from


## End Color

@docs to


## Timing

@docs speed, duration, easing, delay


# Types

@docs Color, Hex, HSL, HSLA, RGB, RGBA

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Color as CB
import Anim.Internal.Properties.Color as C
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)



-- COLOR CONFIGURATION


{-| Type alias for the internal `ColorBuilder`.
-}
type alias Builder =
    CB.ColorBuilder


{-| Start configuring a color animation for a specific element.

    animBuilder
        |> Color.for "my-element"
        |> ...

-}
for : String -> AnimBuilder -> Builder
for elementId =
    CB.for elementId


{-| Complete the color animation configuration and return an [AnimBuilder](Anim#AnimBuilder)
so you can continue building the overall animation.

    animBuilder
        |> Color.for "my-element"
        |> ... -- Color configuration steps
        |> Color.build
        |> ... -- continue with animation

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

    animBuilder
        |> Color.for "my-element"
        |> Color.from (Hex "#ff0000")
        |> ...

-}
from : Color -> Builder -> Builder
from color =
    CB.from (toInternal color)


{-| Set the target color for the current element.

    animBuilder
        |> Color.for "my-element"
        |> Color.to (Hex "#ff0000")
        |> ...

    animBuilder
        |> Color.for "my-element"
        |> Color.to (Rgb { r = 255, g = 0, b = 0 })
        |> ...

-}
to : Color -> Builder -> Builder
to color =
    CB.to (toInternal color)


{-| Set animation speed for color (RGB distance units per second).

The speed represents how fast the color changes based on the Euclidean distance
in RGB color space. A speed of `255.0` means the color will change by 255 RGB
distance units per second (e.g., from black #000000 to white #ffffff takes ~1.5 seconds).

    animBuilder
        |> Color.for "my-element"
        |> Color.to (Hex "#ff0000")
        |> Color.speed 255
        |> ...

-}
speed : Float -> Builder -> Builder
speed unitsPerSecond =
    CB.speed unitsPerSecond


{-| Set the animation duration (milliseconds).

    animBuilder
        |> Color.for "my-element"
        |> Color.to (Hex "#ff0000")
        |> Color.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration milliseconds =
    CB.duration milliseconds


{-| Set the easing function for the animation.

    animBuilder
        |> Color.for "my-element"
        |> Color.to (Hex "#ff0000")
        |> Color.easing Ease.CubicInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing easing_ =
    Easing.mapInternal CB.easing easing_


{-| Set the delay (milliseconds) before the animation runs.

    animBuilder
        |> Color.for "my-element"
        |> Color.to (Hex "#ff0000")
        |> Color.delay 500
        |> ...

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
