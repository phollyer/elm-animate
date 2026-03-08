module Anim.Property.BackgroundColor exposing
    ( init
    , Builder, for, build
    , from
    , to
    , delay, duration, speed
    , easing
    )

{-| Animate the background color of elements.

    import Anim.Extra.Color exposing (hex)
    import Anim.Extra.Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        BackgroundColor.for "animGroupName"
            >> BackgroundColor.to (hex "#ff0000")
            >> BackgroundColor.duration 1000
            >> BackgroundColor.easing EaseInOut
            >> BackgroundColor.build


# Initialize

@docs init


# Build

@docs Builder, for, build


# Configure


## Start Value

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
import Anim.Internal.Builders.BackgroundColor as CB
import Anim.Internal.Properties.Color exposing (Color(..))


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
for : String -> AnimBuilder -> Builder
for animationKey =
    CB.for animationKey


{-| Set the initial background color.

Use this to initialize the background color in your Engine's `init` function.

    import Anim.Extra.Color exposing (hex)
    import Anim.Engine.* as Engine
    import Anim.Property.BackgroundColor as BackgroundColor

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ BackgroundColor.init "animGroupName" (hex "#ff0000") ] }
        , Cmd.none
        )

-}
init : String -> Color -> AnimBuilder -> AnimBuilder
init animationKey color animBuilder =
    animBuilder
        |> CB.for animationKey
        |> CB.from color
        |> CB.to color
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

How this behaves depends on the engine:

  - **Keyframes** — use this to set explicit starting values; otherwise property defaults apply.
  - **WAAPI `fireAndForget`** — use this to set explicit starting values; otherwise property defaults apply.
  - **Sub / WAAPI** — only useful to override the current tracked position, since these engines track values mid-flight.
  - **Transitions** — ignored; the browser computes starting values.

&nbsp;

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
