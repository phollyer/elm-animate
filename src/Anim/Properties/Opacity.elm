module Anim.Properties.Opacity exposing
    ( Builder, for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Opacity animation functions.

Use these functions to configure opacity animations in the builder chain:

    animBuilder
        |> Opacity.for "my-element"
        |> Opacity.to 0.5
        |> ... -- other opacity configuration steps
        |> Opacity.build
        |> ... -- continue with animation


# Build

@docs Builder, for, build


# Configure


## Start Opacity

The first time an opacity animation is configured, if no starting opacity is set, it will default to: `1.0` (fully opaque).
On subsequent animations, it will start from the last known opacity.

The last known opacity is tracked in your Engine's model, so you only need to set this when you want to override that behavior, or, if you choose not to track state in your model.

@docs from


## End Opacity

@docs to


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Opacity as OB
import Anim.Internal.Properties.Opacity as O



-- OPACITY CONFIGURATION


{-| Type alias for the internal `OpacityBuilder`.
-}
type alias Builder =
    OB.OpacityBuilder


{-| Start configuring an opacity animation for a specific element.

    animBuilder
        |> Opacity.for "my-element"
        |> ...

-}
for : String -> AnimBuilder -> Builder
for elementId =
    OB.for elementId


{-| Complete the opacity animation configuration and return an [AnimBuilder](Anim.AnimBuilder)
so you can continue building the overall animation.

    animBuilder
        |> Opacity.for "my-element"
        |> ... -- Opacity configuration steps
        |> Opacity.build
        |> ...

-}
build : Builder -> AnimBuilder
build =
    OB.build


{-| Animate from a specific opacity value.

    animBuilder
        |> Opacity.for "element"
        |> Opacity.from 1.0
        |> ...

-}
from : Float -> Builder -> Builder
from opacity =
    OB.from (O.fromFloat opacity)


{-| Animate to a specific opacity value.

    animBuilder
        |> Opacity.for "element"
        |> Opacity.to 0.5
        |> ...

-}
to : Float -> Builder -> Builder
to opacity =
    OB.to (O.fromFloat opacity)


{-| Set the animation speed (opacity units per second).

The speed represents how much the opacity value changes per second. Since opacity
ranges from 0.0 (transparent) to 1.0 (opaque), a speed of `2.0` means the opacity
will change by 2.0 units per second (e.g., from 0.0 to 1.0 takes 0.5 seconds).

    animBuilder
        |> Opacity.for "my-element"
        |> Opacity.to 0.0
        |> Opacity.speed 1.0
        |> ...

-}
speed : Float -> Builder -> Builder
speed pixelsPerSecond =
    OB.speed pixelsPerSecond


{-| Set the animation duration (milliseconds).

    animBuilder
        |> Opacity.for "my-element"
        |> Opacity.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration milliseconds =
    OB.duration milliseconds


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> Opacity.for "my-element"
        |> Opacity.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay delay_ =
    OB.delay delay_


{-| Set the easing function for the animation.

    animBuilder
        |> Opacity.for "my-element"
        |> Opacity.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing =
    OB.easing
