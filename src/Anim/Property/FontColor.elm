module Anim.Property.FontColor exposing
    ( init
    , Builder, for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Font/Text Color animation functions.

Build animations that change the font color of elements.

    import Anim.Extra.Color exposing (hex)

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.to (hex "#ff0000")
        |> ... -- other color configuration steps
        |> FontColor.build
        |> ... -- continue with animation


# Initialize

@docs init


# Build

@docs Builder, for, build


# Configure


## Initial Value

The first time a FontColor animation is configured, if no initial value is set, the [default](#default) is used.
On subsequent _stateful_ animations, it will start from the last known Color, so you only need to set this
when you want to override that behavior.

@docs from


## Target Value

@docs to


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.FontColor as CB
import Anim.Internal.Properties.Color exposing (Color(..))


{-| Type alias for the internal `ColorBuilder`.
-}
type alias Builder =
    CB.ColorBuilder


{-| Turn the `AnimBuilder` into a font color animation `Builder` for the specified element.

From here, you can continue configuring the font color animation, then call [build](#build) to turn
the `Builder` back into an `AnimBuilder` and then either continue configuring other property animations or
animate it with the Engine.

    animBuilder
        |> FontColor.for "my-element"
        |> ... -- continue with font color configuration

-}
for : String -> AnimBuilder -> Builder
for elementId =
    CB.for elementId


{-| Set the initial font/text color.

Use this to initialize the text color in your `init` function.

    import Anim.Extra.Color exposing (hex)
    import Anim.Engine.* as Engine
    import Anim.Property.FontColor as FontColor

    Engine.init
        |> Engine.builder
        |> FontColor.init "element-id" (hex "#ff0000")
        |> ... -- continue setting initial values
        |> Engine.animate

-}
init : String -> Color -> AnimBuilder -> AnimBuilder
init elementId color animBuilder =
    animBuilder
        |> CB.for elementId
        |> CB.from color
        |> CB.to color
        |> CB.build


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue with the animation.

    import Anim.Property.FontColor as FontColor

        animBuilder
        |> FontColor.for "my-element"
        |> ... -- Color configuration steps
        |> FontColor.build
        |> ... -- continue with animation or execute

-}
build : Builder -> AnimBuilder
build =
    CB.build


{-| Set the starting color for the current element.

    import Anim.Extra.Color exposing (hex, elmColor)
    import Color

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.from (hex "#0000ff")
        |> ... -- continue with animation

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.from (elmColor Color.blue)
        |> ... -- continue with animation

-}
from : Color -> Builder -> Builder
from =
    CB.from


{-| Set the target color for the current element.

    import Anim.Extra.Color exposing (hex, rgb, elmColor)
    import Color

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.from (rgb 0 0 255)
        |> FontColor.to (hex "#ff0000")
        |> ... -- continue with animation

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.from (elmColor Color.blue)
        |> FontColor.to (rgb 255 0 0)
        |> ... -- continue with animation

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.from (hex "#0000ff")
        |> FontColor.to (elmColor Color.red)
        |> ... -- continue with animation

-}
to : Color -> Builder -> Builder
to =
    CB.to


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.delay 500
        |> ... -- continue with animation

-}
delay : Int -> Builder -> Builder
delay =
    CB.delay


{-| Set the duration (milliseconds) of the animation.

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.duration 1000
        |> ... -- continue with animation

-}
duration : Int -> Builder -> Builder
duration =
    CB.duration


{-| Set the animation speed.

The speed is calibrated so that `1.0` means the maximum possible color change
(black to white) takes 1 second. Most color changes will be faster since they
cover less distance in color space.

**Note:** For color animations, `duration` is usually more intuitive than `speed`.
Most folks would tend to think "this color change should take 300ms" rather than "this should
change at a specific rate". Consider using `duration` unless you specifically need
speed-based timing that adapts to color distance.

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.speed 300
        |> ... -- continue with animation

-}
speed : Float -> Builder -> Builder
speed =
    CB.speed


{-| Set the easing function for the animation.

See [Anim.Easing](Anim-Easing) for available easing functions.

    import Anim.Extra.Easing exposing (Easing(..))

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.easing EaseInOut
        |> ... -- continue with animation

-}
easing : Easing -> Builder -> Builder
easing =
    CB.easing
