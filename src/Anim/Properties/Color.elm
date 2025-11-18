module Anim.Properties.Color exposing
    ( Color(..), Builder, for, build
    , from
    , to
    , duration, speed, easing, delay
    )

{-| Color animation functions.

Use these functions to configure color animations in the builder chain:

    animBuilder
        |> Color.for "my-element"
        |> Color.to (Hex "#ff0000")
        |> ... -- other color configuration steps
        |> Color.build
        |> ... -- continue with animation


# Build

@docs Color, Builder, for, build


# Configure


## Start Color

The first time the animation runs, if no starting color is set, it will default to black (#000000).

On subsequent animations, it will start from the last known color, so you only need to set this when you want to override that behavior.

@docs from


## End Color

@docs to


## Timing

@docs duration, speed, easing, delay

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Color as CB
import Anim.Internal.Properties.Color as C
import Anim.Timing.Easing as Easing exposing (Easing)



-- COLOR CONFIGURATION


{-| Color values in different formats.
-}
type Color
    = Hex String
    | Rgb { r : Int, g : Int, b : Int }
    | Rgba { r : Int, g : Int, b : Int, a : Float }
    | Hsl { h : Float, s : Float, l : Float }
    | Hsla { h : Float, s : Float, l : Float, a : Float }


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


{-| Set the animation speed.

The speed is calibrated so that `1.0` means the maximum possible color change
(black to white) takes 1 second. Most color changes will be faster since they
cover less distance in color space.

**Note:** For color animations, `duration` is usually more intuitive than `speed`.
Most folks would tend to think "this color change should take 300ms" rather than "this should
change at a specific rate". Consider using `duration` unless you specifically need
speed-based timing that adapts to color distance.

    animBuilder
        |> Color.for "my-element"
        |> Color.to (Hex "#ff0000")
        |> Color.speed 1.0
        |> ...

-}
speed : Float -> Builder -> Builder
speed =
    CB.speed


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
delay : Int -> Builder -> Builder
delay delay_ =
    CB.delay delay_


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
