module Anim.Properties.Opacity exposing
    ( Builder, for, build
    , from
    , to
    , speed, duration, easing, delay
    , Opacity
    )

{-| Opacity animation functions.

Use these functions to configure opacity animations in the builder chain:

    animBuilder
        |> Opacity.for "my-element"
        |> Opacity.to 0.5
        |> Opacity.speed 500
        |> ... -- other opacity configuration steps
        |> Opacity.build
        |> ... -- continue with animation


# Build

@docs Builder, for, build


# Configure


## Start Opacity

The first time the animation runs, if no starting opacity is set, it will default to 1.0 (fully opaque).

On subsequent animations, it will start from the last known opacity, so you only need to set this when you want to override that behavior.

@docs from


## End Opacity

@docs to


## Timing

@docs speed, duration, easing, delay


# Types

@docs Opacity

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Opacity as OB
import Anim.Internal.Properties.Opacity as O
import Anim.Timing.Delay as Delay exposing (Delay)
import Anim.Timing.Easing as Easing exposing (Easing)



-- OPACITY CONFIGURATION


{-| Type alias for the internal `OpacityBuilder`.
-}
type alias Builder =
    OB.OpacityBuilder


{-| Opacity value for elements.
-}
type alias Opacity =
    Float


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
from : Opacity -> Builder -> Builder
from opacity =
    OB.from (toInternal opacity)


{-| Animate to a specific opacity value.

    animBuilder
        |> Opacity.for "element"
        |> Opacity.to 0.5
        |> ...

-}
to : Opacity -> Builder -> Builder
to opacity =
    OB.to (toInternal opacity)


{-| Set animation speed for opacity (opacity units per second).

    animBuilder
        |> Opacity.for "my-element"
        |> Opacity.speed 500
        |> ...

-}
speed : Float -> Builder -> Builder
speed pixelsPerSecond =
    OB.speed pixelsPerSecond


{-| Set animation duration for opacity (milliseconds).

    animBuilder
        |> Opacity.for "my-element"
        |> Opacity.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration milliseconds =
    OB.duration milliseconds


{-| Set delay.
-}
delay : Delay -> Builder -> Builder
delay delay_ =
    OB.delay (Delay.mapInternal identity delay_)


{-| Set easing function for opacity animation.

    animBuilder
        |> Opacity.for "my-element"
        |> Opacity.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing easing_ =
    OB.easing (Easing.mapInternal identity easing_)



-- INTERNAL HELPERS


toInternal : Opacity -> O.Opacity
toInternal opacity =
    O.fromFloat opacity
