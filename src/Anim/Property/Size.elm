module Anim.Property.Size exposing
    ( init, initWH, initW, initH
    , Builder, for, build
    , from, fromHW, fromH, fromW
    , to, toHW, toH, toW
    , delay, duration, speed
    , easing
    )

{-| Size animation functions.

Build animations that change the size (width and height) of elements.

    animBuilder
        |> Size.for "my-element"
        |> Size.fromHW 100 50
        |> Size.toH 200
        |> Size.speed 500
        |> ... -- other size configuration steps
        |> Size.build
        |> ... -- continue with animation


# Initialize

@docs init, initWH, initW, initH


# Build

@docs Builder, for, build


# Configure


## Initial Value

The first time a size animation is configured, if no initial value is set, the [default](#default) is used.
On subsequent _stateful_ animations, it will start from the last known size, so you only need to set this
when you want to override that behavior.

@docs from, fromHW, fromH, fromW


## Target Value

@docs to, toHW, toH, toW


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Size as SB
import Anim.Internal.Properties.Size as S


{-| Type alias for the internal `SizeBuilder`.
-}
type alias Builder =
    SB.SizeBuilder


{-| Turn the `AnimBuilder` into a size animation `Builder` for the specified animation key.

The key is a unique identifier for this animation. For WAAPI engine, this must match the DOM element ID.
For other engines (CSS, Sub), this can be any unique string since the animation is applied via styles.

From here, you can continue configuring the size animation, then call [build](#build) to turn
the `Builder` back into an `AnimBuilder` and then either continue configuring other property animations or
animate it with the Engine.

    animBuilder
        |> Size.for "resize-panel"
        |> ... -- continue with size configuration

-}
for : String -> AnimBuilder -> Builder
for =
    SB.for


{-| Set the initial size.

Use this to initialize the size in your `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.Size as Size

    Engine.init
        |> Engine.builder
        |> Size.init "resize-panel" 100
        |> ... -- continue setting initial values
        |> Engine.animate

This is equivalent to calling `initWH 100 100`.

-}
init : String -> Float -> AnimBuilder -> AnimBuilder
init animationKey value animBuilder =
    animBuilder
        |> SB.for animationKey
        |> from value
        |> to value
        |> SB.build


{-| Set the initial width and height.

    import Anim.Engine.* as Engine
    import Anim.Property.Size as Size

    Engine.init
        |> Engine.builder
        |> Size.initWH "resize-panel" 200 100
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initWH : String -> Float -> Float -> AnimBuilder -> AnimBuilder
initWH animationKey w h animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromHW w h
        |> SB.toHW w h
        |> SB.build


{-| Set the initial width.

    import Anim.Engine.* as Engine
    import Anim.Property.Size as Size

    Engine.init
        |> Engine.builder
        |> Size.initW "resize-panel" 200
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initW : String -> Float -> AnimBuilder -> AnimBuilder
initW animationKey w animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromW w
        |> SB.toW w
        |> SB.build


{-| Set the initial height.

    import Anim.Engine.* as Engine
    import Anim.Property.Size as Size

    Engine.init
        |> Engine.builder
        |> Size.initH "resize-panel" 150
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initH : String -> Float -> AnimBuilder -> AnimBuilder
initH animationKey h animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromH h
        |> SB.toH h
        |> SB.build


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue with the animation.

    animBuilder
        |> Size.for "my-element"
        |> ... -- Size configuration steps
        |> Size.build
        |> ... -- continue with animation or execute

-}
build : Builder -> AnimBuilder
build =
    SB.build


{-| Set the uniform starting size (width and height) for the current element.

    animBuilder
        |> Size.for "my-element"
        |> Size.from 100
        |> ...

This is equivalent to `fromHW 100 100`.

-}
from : Float -> Builder -> Builder
from =
    SB.from << S.fromTuple << (\v -> ( v, v ))


{-| Set the starting height and width for the current element.

    animBuilder
        |> Size.for "my-element"
        |> Size.fromHW 200 100
        |> ...

-}
fromHW : Float -> Float -> Builder -> Builder
fromHW =
    SB.fromHW


{-| Set the starting height for the current element, keeping the current width.

    animBuilder
        |> Size.for "my-element"
        |> Size.fromH 150
        |> ...

The width remains unchanged, or 0 if not set.

-}
fromH : Float -> Builder -> Builder
fromH =
    SB.fromH


{-| Set the starting width for the current element, keeping the current height.

    animBuilder
        |> Size.for "my-element"
        |> Size.fromW 250
        |> ...

The height remains unchanged, or 0 if not set.

-}
fromW : Float -> Builder -> Builder
fromW =
    SB.fromW


{-| Set the uniform target size (height and width) for the animation.

    animBuilder
        |> Size.for "my-element"
        |> Size.to 150
        |> ...

This is equivalent to `toHW 150 150`.

-}
to : Float -> Builder -> Builder
to =
    SB.to << S.fromTuple << (\v -> ( v, v ))


{-| Set the target height and width for the animation.

    animBuilder
        |> Size.for "my-element"
        |> Size.toHW 200 100
        |> ...

-}
toHW : Float -> Float -> Builder -> Builder
toHW =
    SB.toHW


{-| Set the target height for the animation, keeping the current target width.

    animBuilder
        |> Size.for "my-element"
        |> Size.toH 150
        |> ...

The width remains unchanged, or 0 if not set.

-}
toH : Float -> Builder -> Builder
toH =
    SB.toH


{-| Set the target width for the animation, keeping the current target height.

    animBuilder
        |> Size.for "my-element"
        |> Size.toW 250
        |> ...

The height remains unchanged, or 0 if not set.

-}
toW : Float -> Builder -> Builder
toW =
    SB.toW


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> Size.for "my-element"
        |> Size.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay =
    SB.delay


{-| Set the animation duration (milliseconds).

    animBuilder
        |> Size.for "my-element"
        |> Size.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| The speed represents how many pixels the element's size changes per second.

For example, lets take a size animation from `(100, 100)` to `(200, 200)`.
A speed of `50.0` means the size will change by 50 pixels per second, so our animation will take 2 seconds to complete.

    animBuilder
        |> Size.for "my-element"
        |> Size.toHW 200 200
        |> Size.speed 50
        |> ...

Similarly, a speed of `100.0` would complete the same animation in 1 second, and a speed of `25.0` would take 4 seconds.

-}
speed : Float -> Builder -> Builder
speed =
    SB.speed


{-| Set the easing function for the animation.

    animBuilder
        |> Size.for "my-element"
        |> Size.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing =
    SB.easing
