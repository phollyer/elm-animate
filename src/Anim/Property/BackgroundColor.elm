module Anim.Property.BackgroundColor exposing
    ( Builder, GroupName
    , init
    , for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Animate the background color of elements.

**Default**: transparent white

This property uses a 'sensible default' approach to configuring animations.
When no start value is available, the default will be used.

    import Anim.Extra.Color exposing (rgb)
    import Anim.Extra.Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        BackgroundColor.for "animGroupName"
            >> BackgroundColor.to (rgb 255 0 0)
            >> BackgroundColor.duration 1000
            >> BackgroundColor.easing EaseInOut
            >> BackgroundColor.build

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
import Anim.Internal.Builder.BackgroundColor as CB
import Anim.Internal.Extra.Color exposing (Color(..))


{-| Type alias for the animation group name.
-}
type alias GroupName =
    String


{-| Type alias for the internal `ColorBuilder`.
-}
type alias Builder =
    CB.ColorBuilder


{-| Turn the `AnimBuilder` into a background color animation `Builder` for the specified animation group.

Use this to start configuring a background color animation.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        BackgroundColor.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : GroupName -> AnimBuilder -> Builder
for animationKey =
    CB.for animationKey


{-| Set the initial background color.

Use this to initialize the background color in your Engine's `init` function.

    import Anim.Extra.Color exposing (rgb)
    import Anim.Engine.* as Engine
    import Anim.Property.BackgroundColor as BackgroundColor

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ BackgroundColor.init "animGroupName" (rgb 255 0 0) ] }
        , Cmd.none
        )

-}
init : GroupName -> Color -> AnimBuilder -> AnimBuilder
init animationKey color animBuilder =
    animBuilder
        |> CB.for animationKey
        |> CB.init color
        |> CB.build


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        BackgroundColor.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> BackgroundColor.build
            >> ... -- continue with animation

-}
build : Builder -> AnimBuilder
build =
    CB.build


{-| Set the starting background color.

    import Anim.Extra.Color exposing (hex)

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        BackgroundColor.for "animGroupName"
            >> BackgroundColor.from (hex "#0000ff")
            >> ... -- continue with animation

-}
from : Color -> Builder -> Builder
from color =
    CB.from color


{-| Set the target color for the current animation group.

    import Anim.Extra.Color exposing (hex)

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        BackgroundColor.for "animGroupName"
            >> BackgroundColor.to (hex "#0000ff")
            >> ... -- continue with animation

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

    import Anim.Extra.Color exposing (hex)

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        BackgroundColor.for "animGroupName"
            >> BackgroundColor.to (hex "#0000ff")
            >> BackgroundColor.speed 0.5
            >> ... -- continue with animation

-}
speed : Float -> Builder -> Builder
speed =
    CB.speed


{-| Set the animation duration (milliseconds).

    import Anim.Extra.Color exposing (hex)

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        BackgroundColor.for "animGroupName"
            >> BackgroundColor.to (hex "#0000ff")
            >> BackgroundColor.duration 300
            >> ... -- continue with animation

-}
duration : Int -> Builder -> Builder
duration =
    CB.duration


{-| Set the easing function for the animation.

    import Anim.Extra.Color exposing (hex)
    import Anim.Extra.Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        BackgroundColor.for "animGroupName"
            >> BackgroundColor.to (hex "#0000ff")
            >> BackgroundColor.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder -> Builder
easing =
    CB.easing


{-| Set the delay (milliseconds) before the animation starts.

    import Anim.Extra.Color exposing (hex)

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        BackgroundColor.for "animGroupName"
            >> BackgroundColor.to (hex "#0000ff")
            >> BackgroundColor.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder -> Builder
delay =
    CB.delay
