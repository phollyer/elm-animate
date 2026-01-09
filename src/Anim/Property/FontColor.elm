module Anim.Property.FontColor exposing
    ( init
    , Builder, for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Font/Text Color animation functions.

Use these functions to configure text color animations in the builder chain:

    import Anim.Color exposing (Color(..))

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


## Start Color

The first time a text color animation is configured, if no starting color is set, it will default to `black (rgb 0 0 0)`.
On subsequent animations, it will start from the last known text color.

The last known text color is tracked in your Engine's model, so you only need to set this when you want to override that behavior, or, if you choose not to track state in your model.

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
import Anim.Internal.Builders.FontColor as CB


{-| Type alias for the internal `ColorBuilder`.
-}
type alias Builder =
    CB.ColorBuilder


{-| Start configuring a text color animation for a specific element.

    animBuilder
        |> FontColor.for "my-element"
        |> ...

-}
for : String -> AnimBuilder -> Builder
for elementId =
    CB.for elementId


{-| Set the initial font/text color.

Use this to initialize the text color in your `init` function.

    import Anim.Color exposing (hex)
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


{-| Complete the color animation configuration and return an [AnimBuilder](Anim#AnimBuilder)
so you can continue building the overall animation.

    animBuiFontColor.for "my-element"
        |> ... -- Color configuration steps
        |> FontColor.build
        |> ... -- continue with animation

-}
build : Builder -> AnimBuilder
build =
    CB.build



-- COLOR CONFIGURATION


{-| Set the starting color for the current element.

    import Anim.Color exposing (hex)

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.from (hex "#0000ff")
        |> ...

-}
from : Color -> Builder -> Builder
from =
    CB.from


{-| Set the ending color for the current element.

    import Anim.Color exposing (hex)

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.to (hmy-element"
        |> Color.to (Hex "#ff0000")
        |> ...

-}
to : Color -> Builder -> Builder
to =
    CB.to



-- TIMING CONFIGURATION


{-| Set the delay (in milliseconds) before the animation starts.

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay =
    CB.delay


{-| Set the duration (in milliseconds) of the animation.

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.duration 1000
        |> ...

-}
duration : Int -> Builder -> Builder
duration =
    CB.duration


{-| Set the animation speed based on RGB distance per second.

For color animations:

  - Speed represents RGB distance units per second
  - The maximum RGB distance (black to white) is approximately 441.67 units
  - A speed of 1.0 would take ~442 seconds to go from black to white
  - A speed of 441.67 would take 1 second to go from black to white

For example, a speed of 200 means the color will change by 200 RGB distance units per second.

    animBuilder
        |> FontColor.for "my-element"
        |> FontColor.speed 300
        |> ...

-}
speed : Float -> Builder -> Builder
speed =
    CB.speed



-- EASING CONFIGURATION


{-| Set the easing function for the animation.

See [Anim.Easing](Anim-Easing) for available easing functions.

    import Anim.Easing exposing (ease)

    animBuilder
        |> FontColor.for "my-element"
        |> FontAnim.Easing exposing (ease)

    animBuilder
        |> Color.for "my-element"
        |> Color.easing ease.inOutQuad
        |> ...

-}
easing : Easing -> Builder -> Builder
easing =
    CB.easing
