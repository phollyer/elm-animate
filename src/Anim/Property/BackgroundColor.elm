module Anim.Property.BackgroundColor exposing
    ( init
    , Builder, for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Background Color animation functions.

Use these functions to configure background color animations in the builder chain:

    import Anim.Color exposing (Color(..))

    animBuilder
        |> BackgroundColor.for "my-element"
        |> BackgroundColor.to (hex "#ff0000")
        |> ... -- other color configuration steps
        |> BackgroundColor.build
        |> ... -- continue with animation


# Initialize

@docs init


# Build

@docs Builder, for, build


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

import Anim.Color exposing (Color(..))
import Anim.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.BackgroundColor as CB


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


{-| Complete the color animation configuration and return an [AnimBuilder](Anim#AnimBuilder)
so you can continue building the overall animation.

    animBuilderColor exposing (hex)
    import Anim.Engine.* as Engine
    import Anim.Property.BackgroundColor as BackgroundColor

    Engine.init
        |> Engine.builder
        |> BackgroundColor.init "element-id" (h

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
