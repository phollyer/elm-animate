module Anim.Properties.BackgroundColor exposing
    ( Color(..), Builder, for, build
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

@docs Color, Builder, for, build


# Configure


## Start Color

The first time the animation runs, if no starting color is set, it will default to black (#000000).

On subsequent animations, it will start from the last known color, so you only need to set this when you want to override that behavior.

@docs from


## End Color

@docs to


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.BackgroundColor as CB
import Anim.Internal.Properties.BackgroundColor as BC
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
        |> BackgroundColor.for "my-element"
        |> ...

-}
for : String -> AnimBuilder -> Builder
for elementId =
    CB.for elementId


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
duration milliseconds =
    CB.duration milliseconds


{-| Set the easing function for the animation.

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing easing_ =
    Easing.mapInternal CB.easing easing_


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay delay_ =
    CB.delay delay_


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
