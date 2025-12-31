module Anim.Properties.Size exposing
    ( Builder, for, build
    , fromHW, fromH, fromW, fromTuple
    , toHW, toH, toW
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

The first time the animation runs, if no starting size is set, it will default to (0, 0).

On subsequent animations, it will start from the last known size, so you only need to set this when you want to override that behavior.

@docs fromHW, fromH, fromW, fromTuple


## End Size

@docs toHW, toH, toW


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Size as SB
import Anim.Timing.Easing as Easing exposing (Easing)


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


{-| Set the starting width and height for the current element.

    Size.fromHW 100 50 -- Start from width=100, height=50

-}
fromHW : Float -> Float -> Builder -> Builder
fromHW =
    SB.fromHW


{-| Set the starting width and height from a tuple.

    Size.fromTuple ( 100, 50 ) -- Start from width=100, height=50

-}
fromTuple : ( Float, Float ) -> Builder -> Builder
fromTuple ( width, height ) =
    SB.fromHW width height


{-| Set the starting height for the current element, keeping the current width.

    Size.fromH 100 -- Start from height=100

-}
fromH : Float -> Builder -> Builder
fromH =
    SB.fromH


{-| Set the starting width for the current element, keeping the current height.

    Size.fromW 200 -- Start from width=200

-}
fromW : Float -> Builder -> Builder
fromW =
    SB.fromW


{-| Set the target width and height for the animation.

    Size.toHW 200 300 -- animate to height=200, width=300

-}
toHW : Float -> Float -> Builder -> Builder
toHW height width =
    SB.toHW height width


{-| Set the target height for the animation, keeping the current target width.

    Size.toH 200 -- animate to height=200

-}
toH : Float -> Builder -> Builder
toH =
    SB.toH


{-| Set the target width for the animation, keeping the current target height.

    Size.toW 300 -- animate to width=300

-}
toW : Float -> Builder -> Builder
toW =
    SB.toW


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


{-| Set the animation duration (milliseconds).

    animBuilder
        |> Size.for "my-element"
        |> Size.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| Set the easing function for the animation.

    animBuilder
        |> Size.for "my-element"
        |> Size.easing EaseInOut
        |> ...

-}
easing : Easing -> Builder -> Builder
easing =
    Easing.mapInternal identity >> SB.easing


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> Size.for "my-element"
        |> Size.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay =
    SB.delay
