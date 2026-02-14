module Anim.Property.Opacity exposing
    ( init
    , Builder, for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Opacity animation functions.

Build animations that change the opacity of elements.

    animBuilder
        |> Opacity.for "animGroupName"
        |> Opacity.to 0.5
        |> ... -- other opacity configuration steps
        |> Opacity.build
        |> ... -- continue with animation


# Initialize

@docs init


# Build

@docs Builder, for, build


# Configure


## Initial Value

The first time an opacity animation is configured, if no initial value is set, the [default](#default) is used.
On subsequent _stateful_ animations, it will start from the last known opacity, so you only need to set this
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
import Anim.Internal.Builders.Opacity as OB
import Anim.Internal.Properties.Opacity as O


{-| Type alias for the internal `OpacityBuilder`.
-}
type alias Builder =
    OB.OpacityBuilder


{-| Turn the `AnimBuilder` into an opacity animation `Builder` for the specified animation group.

The group name identifies which animations run together. All animations in the same pipeline that share
the same group will run simultaneously on the same element.

From here, you can continue configuring the opacity animation, then call [build](#build) to turn
the `Builder` back into an `AnimBuilder` and then either continue configuring other property animations or
animate it with the Engine.

    animBuilder
        |> Opacity.for "animGroupName"
        |> ... -- continue with opacity configuration

-}
for : String -> AnimBuilder -> Builder
for =
    OB.for


{-| Set the initial opacity.

Use this to initialize the opacity in your `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.Opacity as Opacity

    Engine.init
        |> Engine.builder
        |> Opacity.init "animGroupName" 0.5
        |> ... -- continue setting initial values
        |> Engine.animate

-}
init : String -> Float -> AnimBuilder -> AnimBuilder
init animationKey value animBuilder =
    animBuilder
        |> OB.for animationKey
        |> OB.from (O.fromFloat value)
        |> OB.to (O.fromFloat value)
        |> OB.build


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue with the animation.

    animBuilder
        |> Opacity.for "animGroupName"
        |> ... -- Opacity configuration steps
        |> Opacity.build
        |> ... -- continue with animation or execute

-}
build : Builder -> AnimBuilder
build =
    OB.build


{-| Animate from a specific opacity value.

    animBuilder
        |> Opacity.for "animGroupName"
        |> Opacity.from 1.0
        |> ...

-}
from : Float -> Builder -> Builder
from =
    OB.from << O.fromFloat


{-| Animate to a specific opacity value.

    animBuilder
        |> Opacity.for "animGroupName"
        |> Opacity.to 0.5
        |> ...

-}
to : Float -> Builder -> Builder
to =
    OB.to << O.fromFloat


{-| Set the animation speed (opacity units per second).

The speed represents how much the opacity value changes per second. Since opacity
ranges from 0.0 (transparent) to 1.0 (opaque), a speed of `2.0` means the opacity
will change by 2.0 units per second (e.g., from 0.0 to 1.0 takes 0.5 seconds).

    animBuilder
        |> Opacity.for "animGroupName"
        |> Opacity.to 0.0
        |> Opacity.speed 1.0
        |> ...

-}
speed : Float -> Builder -> Builder
speed =
    OB.speed


{-| Set the animation duration (milliseconds).

    animBuilder
        |> Opacity.for "animGroupName"
        |> Opacity.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration =
    OB.duration


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> Opacity.for "animGroupName"
        |> Opacity.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay =
    OB.delay


{-| Set the easing function for the animation.

    animBuilder
        |> Opacity.for "animGroupName"
        |> Opacity.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing =
    OB.easing
