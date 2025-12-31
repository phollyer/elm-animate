module Anim.Property.Size exposing
    ( Builder, for, build
    , from, fromHW, fromH, fromW
    , to, toHW, toH, toW
    , delay, duration, speed
    , easing
    )

{-| Size animation functions.

Use these functions to configure size animations in the builder chain:

    animBuilder
        |> Size.for "my-element"
        |> Size.fromHW 100 50
        |> Size.toH 200
        |> Size.speed 500
        |> ... -- other size configuration steps
        |> Size.build
        |> ... -- continue with animation


# Build

@docs Builder, for, build


# Configure


## Start Size

The first time a size animation is configured, if no starting size is set, it will default to: `{height = 0, width = 0}`. On subsequent animations,
it will start from the last known size.

The last known size is tracked in your Engine's model, so you only need to set this when you want to override that behavior, or, if you choose not to track state in your model.

@docs from, fromHW, fromH, fromW


## End Size

@docs to, toHW, toH, toW


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Size as SB
import Anim.Internal.Properties.Size as S


{-| Type alias for the internal `SizeBuilder`.
-}
type alias Builder =
    SB.SizeBuilder


{-| Configure a size animation for the specified element.

    animBuilder
        |> Size.for "my-element"
        |> ... -- continue with size configuration

-}
for : String -> AnimBuilder -> Builder
for =
    SB.for


{-| Complete the size animation configuration and return an [AnimBuilder](Anim.AnimBuilder)
so you can continue building the overall animation.

    animBuilder
        |> Size.for "my-element"
        |> ... -- Size configuration steps
        |> Size.build
        |> ... -- continue with animation

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
