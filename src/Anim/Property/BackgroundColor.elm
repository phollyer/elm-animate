module Anim.Property.BackgroundColor exposing
    ( default
    , init
    , Builder, for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Background Color animation functions.

Build animations that change the background color of elements.

    import Anim.Color exposing (Color(..))

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.to (Hex "#ff0000")
        |> ... -- other color configuration steps
        |> BackgroundColor.build
        |> ... -- continue with animation


# Default

@docs default


# Initialize

@docs init


# Build

@docs Builder, for, build


# Configure


## Initial Value

The first time a BackgroundColor animation is configured, if no initial value is set, the [default](#default) is used.
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

import Anim.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.BackgroundColor as CB
import Anim.Internal.Properties.Color exposing (Color(..))


{-| The default background color used when no initial value is specified:

`rgba(255, 255, 255, 0)` (fully transparent white).

-}
default : Color
default =
    Rgba { r = 255, g = 255, b = 255, a = 0 }


{-| Type alias for the internal `ColorBuilder`.
-}
type alias Builder =
    CB.ColorBuilder


{-| Turn the `AnimBuilder` into a background color animation `Builder` for the specified element.

From here, you can continue configuring the background color animation, then call [build](#build) to turn
the `Builder` back into an `AnimBuilder` and then either continue configuring other property animations or
animate it with the Engine.

    animBuilder
        |> BackgroundColor.for "my-element"
        |> ... -- continue with background color configuration

-}
for : String -> AnimBuilder -> Builder
for elementId =
    CB.for elementId


{-| Set the initial background color.

Use this to initialize the background color in your `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.BackgroundColor as BackgroundColor exposing (Color(..))

    Engine.init
        |> Engine.builder
        |> BackgroundColor.init "element-id" (Hex "#ff0000")
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

    import Anim.Property.BackgroundColor as BackgroundColor

    animBuilder
        |> BackgroundColor.for "element-id"
        |> ... -- BackgroundColor configuration steps
        |> BackgroundColor.build
        |> ... -- continue with animation or execute

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
    CB.from color


{-| Set the target color for the current element.

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.from (Rgb { r = 0, g = 0, b = 255 })
        |> BackgroundColor.to (Hex "#ff0000")
        |> ...

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.from (ElmColor Color.blue)
        |> BackgroundColor.to (Rgb { r = 255, g = 0, b = 0 })
        |> ...

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.from (Hex "#0000ff")
        |> BackgroundColor.to (ElmColor Color.red)
        |> ...

-}
to : Color -> Builder -> Builder
to color =
    CB.to color


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
