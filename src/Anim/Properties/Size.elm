module Anim.Properties.Size exposing
    ( Size, Builder, for, build
    , fromHW, fromH, fromW, fromTuple
    , toHW, toH, toW
    , speed, duration, easing, delay
    , asRecord, toTuple
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

@docs Size, Builder, for, build


# Configure


## Start Size

The first time the animation runs, if no starting size is set, it will default to (0, 0).

On subsequent animations, it will start from the last known size, so you only need to set this when you want to override that behavior.

@docs fromHW, fromH, fromW, fromTuple


## End Size

@docs toHW, toH, toW


## Timing

@docs speed, duration, easing, delay


## Convert Size

@docs asRecord, toTuple

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Size as SB
import Anim.Internal.Properties.Size as Internal
import Anim.Timing.Easing as Easing exposing (Easing)


{-| Type representing a size with width and height dimensions.
-}
type alias Size =
    Internal.Size


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


{-| Convert a Size to a tuple of ( width, height ).
-}
toTuple : Size -> ( Float, Float )
toTuple =
    Internal.toTuple


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


{-| Set the animation speed in pixels per second.

    Size.speed 100 -- pixels per second

-}
speed : Float -> Builder -> Builder
speed =
    SB.speed


{-| Set the animation duration in milliseconds.

    Size.duration 2000 -- 2 seconds

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| Set the easing function for the animation.

    Size.easing Easing.easeInOutQuad

-}
easing : Easing -> Builder -> Builder
easing =
    Easing.mapInternal identity >> SB.easing


{-| Set the delay before starting the animation.

    Size.delay 500 -- 500ms delay

-}
delay : Int -> Builder -> Builder
delay =
    SB.delay


{-| Convert a Size to a record for external use.

    -- This would work in the context of a builder pattern:
    -- mySize |> Size.asRecord
    -- --> { width = 100, height = 50 }



-}
asRecord : Size -> { width : Float, height : Float }
asRecord size =
    let
        ( width, height ) =
            Internal.toTuple size
    in
    { width = width, height = height }
