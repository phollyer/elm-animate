module Anim.Property.BackgroundColor exposing
    ( Color(..), Builder, for, init, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Background Color animation functions.

Use these functions to configure background color animations in the builder chain:

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.to (Hex "#ff0000")
        |> ... -- other color configuration steps
        |> BackgroundColor.build
        |> ... -- continue with animation


# Build

@docs Color, Builder, for, init, build


# Configure


## Start Color

The first time a background color animation is configured, if no starting color is set, it will default to `transparent white (rgba 255 255 255 0)`.
On subsequent animations, it will start from the last known background color.

The last known background color is tracked in your Engine's model, so you only need to set this when you want to override that behavior, or, if you choose not to track state in your model.

@docs from


## End Color

@docs to


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.BackgroundColor as CB
import Anim.Internal.Properties.BackgroundColor as BC
import Color



-- COLOR CONFIGURATION


{-| Color values in different formats.

  - Use `Hex` for hex color strings like "#ff0000"
  - Use `Rgb` or `Rgba` for RGB values
  - Use `Hsl` or `Hsla` for HSL values
  - Use `ElmColor` to integrate with the [avh4/elm-color](https://package.elm-lang.org/packages/avh4/elm-color/latest/) package,
    which provides named colors (`Color.red`, `Color.blue`, etc.) and color manipulation functions

-}
type Color
    = Hex String
    | Rgb { r : Int, g : Int, b : Int }
    | Rgba { r : Int, g : Int, b : Int, a : Float }
    | Hsl { h : Float, s : Float, l : Float }
    | Hsla { h : Float, s : Float, l : Float, a : Float }
    | ElmColor Color.Color


{-| Type alias for the internal `ColorBuilder`.
-}
type alias Builder =
    CB.ColorBuilder


{-| Start configuring a color animation for a specific element.

    animBuilder
        |> BackgroundColor.for "my-element"
        |> ...

-}
for : String -> AnimBuilder -> Builder
for elementId =
    CB.for elementId


{-| Set initial background color value without animation.

Use this to initialize property values in the builder pipeline:

    animBuilder
        |> BackgroundColor.init "my-element" (Hex "#ff0000")
        |> ... -- continue with animation

-}
init : String -> Color -> AnimBuilder -> AnimBuilder
init elementId color animBuilder =
    animBuilder
        |> CB.for elementId
        |> CB.from (toInternal color)
        |> CB.to (toInternal color)
        |> CB.build


{-| Complete the color animation configuration and return an [AnimBuilder](Anim#AnimBuilder)
so you can continue building the overall animation.

    animBuilder
        |> BackgroundColor.for "my-element"
        |> ... -- Color configuration steps
        |> BackgroundColor.build
        |> ... -- continue with animation

-}
build : Builder -> AnimBuilder
build =
    CB.build



-- COLOR CONFIGURATION


{-| Set the starting color for the current element.

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.from (Hex "#ff0000")
        |> ...

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.from (ElmColor Color.red)
        |> ...

-}
from : Color -> Builder -> Builder
from color =
    CB.from (toInternal color)


{-| Set the target color for the current element.

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.to (Hex "#ff0000")
        |> ...

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.to (Rgb { r = 255, g = 0, b = 0 })
        |> ...

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.to (ElmColor Color.blue)
        |> ...

-}
to : Color -> Builder -> Builder
to color =
    CB.to (toInternal color)


{-| Set the animation speed.

The speed is calibrated so that `1.0` means the maximum possible color change
(black to white) takes 1 second. Most color changes will be faster since they
cover less distance in color space.

**Note:** For color animations, `duration` is usually more intuitive than `speed`.
Most folks would tend to think "this color change should take 300ms" rather than "this should
change at a specific rate". Consider using `duration` unless you specifically need
speed-based timing that adapts to color distance.

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.to (Hex "#ff0000")
        |> BackgroundColor.speed 1.0
        |> ...

-}
speed : Float -> Builder -> Builder
speed =
    CB.speed


{-| Set the animation duration (milliseconds).

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration =
    CB.duration


{-| Set the easing function for the animation.

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing =
    CB.easing


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay =
    CB.delay


toInternal : Color -> BC.Color
toInternal color =
    case color of
        Hex hexString ->
            BC.Hex hexString

        Rgb rgb ->
            BC.Rgb rgb

        Rgba rgba ->
            BC.Rgba rgba

        Hsl hsl ->
            BC.Hsl hsl

        Hsla hsla ->
            BC.Hsla hsla

        ElmColor elmColor ->
            let
                rgba =
                    Color.toRgba elmColor
            in
            BC.Rgba
                { r = round (rgba.red * 255)
                , g = round (rgba.green * 255)
                , b = round (rgba.blue * 255)
                , a = rgba.alpha
                }
