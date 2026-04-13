module Anim.Property.Opacity exposing
    ( Builder, GroupName
    , init
    , for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Animate the opacity of elements.

**Default**: 1.0 (fully opaque)

This property uses a 'sensible default' approach to configuring animations.
When no start value is available, the default will be used.

    import Anim.Extra.Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.to 0.5
            >> Opacity.duration 1000
            >> Opacity.easing EaseInOut
            >> Opacity.build

The Engines track the end value of the animation, so new animations with no start value
will use the current end value as the start, ensuring a smooth transition between animations.


# Types

@docs Builder, GroupName


# Initialize

@docs init


# Build

@docs for, build


# Configure


## Start Value

How setting a start value behaves depends on the engine:

  - **Keyframe** — use this to set explicit starting values; otherwise property defaults apply.
  - **WAAPI `fireAndForget`** — use this to set explicit starting values; otherwise property defaults apply.
  - **Sub / WAAPI** — only useful to override the current tracked position, since these engines track values mid-flight.
  - **Transition** — ignored; the browser computes starting values.

@docs from


## End Value

@docs to


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Opacity as OB
import Anim.Internal.Property.Opacity as O


{-| Type alias for the animation group name.
-}
type alias GroupName =
    String


{-| Type alias for the internal `OpacityBuilder`.
-}
type alias Builder =
    OB.OpacityBuilder


{-| Turn the `AnimBuilder` into an opacity animation `Builder` for the specified animation group.

Use this to start configuring an opacity animation.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Opacity.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : GroupName -> AnimBuilder -> Builder
for =
    OB.for


{-| Set the initial opacity.

Use this to initialize the opacity in your Engine's `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.Opacity as Opacity

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Opacity.init "animGroupName" 0.5 ] }
        , Cmd.none
        )

-}
init : GroupName -> Float -> AnimBuilder -> AnimBuilder
init animationKey value animBuilder =
    animBuilder
        |> OB.for animationKey
        |> OB.from (O.fromFloat value)
        |> OB.to (O.fromFloat value)
        |> OB.build


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Opacity.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Opacity.build
            >> ... -- continue with animation

-}
build : Builder -> AnimBuilder
build =
    OB.build


{-| Set the starting opacity.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.from 1.0
            >> ... -- continue with animation

-}
from : Float -> Builder -> Builder
from =
    OB.from << O.fromFloat


{-| Set the target opacity for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.to 0.5
            >> ... -- continue with animation

-}
to : Float -> Builder -> Builder
to =
    OB.to << O.fromFloat


{-| Set the animation speed (opacity units per second).

The speed represents how much the opacity value changes per second. Since opacity
ranges from 0.0 (transparent) to 1.0 (opaque), a speed of `2.0` means the opacity
will change by 2.0 units per second (e.g., from 0.0 to 1.0 takes 0.5 seconds).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.to 0.0
            >> Opacity.speed 1.0
            >> ... -- continue with animation

-}
speed : Float -> Builder -> Builder
speed =
    OB.speed


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.to 0.5
            >> Opacity.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder -> Builder
duration =
    OB.duration


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.to 0.5
            >> Opacity.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder -> Builder
delay =
    OB.delay


{-| Set the easing function for the animation.

    import Anim.Extra.Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Opacity.for "animGroupName"
            >> Opacity.to 0.5
            >> Opacity.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder -> Builder
easing =
    OB.easing
