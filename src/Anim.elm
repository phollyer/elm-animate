module Anim exposing
    ( AnimBuilder, init, for
    , duration, speed
    , easing
    , delay
    )

{-| New fluent animation API with property-namespaced builders.


# Builder Pattern

@docs AnimBuilder, init, for


# Global Settings

Any animation that does not have a specific timing, easing, or delay set will
use the global settings defined here.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay

-}

import Anim.Internal.Builder as Builder
import Anim.Timing.Easing as Easing exposing (Easing)



-- CORE TYPES


{-| Opaque animation builder that accumulates configuration.
-}
type alias AnimBuilder =
    Builder.AnimBuilder



-- Easing functions come from elm-community/easing-functions package
-- BUILDER FUNCTIONS


{-| Initialize animation builder for the first element.

    Anim.init "my-element"
        |> Position.to { x = 100, y = 200 }
        |> animate portFunction

-}
init : String -> AnimBuilder
init elementId =
    Builder.init elementId


{-| Switch to configuring a different element.

    Anim.init "element1"
        |> Position.to pos1
        |> Anim.for "element2"
        |> Position.to pos2
        |> animate portFunction

-}
for : String -> AnimBuilder -> AnimBuilder
for elementId animBuilder =
    Builder.for elementId animBuilder


{-| Set global duration in milliseconds (overrides any previous speed setting).

    Anim.init "element"
        |> Anim.duration 1000
        |> Position.to position
        |> animate portFunction

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration ms builder =
    Builder.duration ms builder


{-| Set global speed in units per second (overrides any previous duration setting).

    Anim.init "element"
        |> Anim.speed 100
        |> Position.to position
        |> animate portFunction

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed value builder =
    Builder.speed value builder


{-| Set global easing function.

    import Anim.Easing as Easing

    Anim.init "element"
        |> Anim.easing Easing.easeInOutQuad
        |> Position.to position
        |> CSS.animate

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing easingValue builder =
    Easing.mapInternal Builder.easing easingValue builder


{-| Set global delay in milliseconds.

    Anim.init "element"
        |> Anim.delay 500
        |> Position.to position
        |> animate portFunction

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay ms builder =
    Builder.delay ms builder
