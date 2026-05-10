module Anim.Property.Size exposing
    ( Builder, AnimGroupName
    , init, initHW, initW, initH
    , for, build
    , fromHW, fromH, fromW, from
    , toHW, toH, toW
    , delay, duration, speed
    , easing
    , spring
    )

{-| Animate the width and height of elements.

**Default**: 0 for width and height

This property uses a 'sensible default' approach to configuring animations.
When no start value is available, the default will be used.

If height or width is not defined in the animation configuration, it will remain unchanged,
or 0 if not set.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 200 100
            >> Size.duration 1000
            >> Size.easing EaseInOut
            >> Size.build

The Engines track the end value of each animation, so new animations with no start value
will use the current end value as the start, ensuring a smooth transition between animations.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs init, initHW, initW, initH


# Build

@docs for, build


# Configure


## Start Value

When not set, the engine determines the start value - behaviour
varies by engine and context.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/engines/overview/#start-values)
for details.

@docs fromHW, fromH, fromW, from


## End Value

@docs toHW, toH, toW


## Timing

@docs delay, duration, speed


## Easing

@docs easing


## Spring

@docs spring

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Size as SB
import Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `SizeBuilder`.
-}
type alias Builder mode =
    SB.SizeBuilder mode



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial size.

Use this to initialize the size in your Engine's `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.Size as Size

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Size.init "animGroupName" 100 ] }
        , Cmd.none
        )

This is equivalent to calling `initHW 100 100`.

-}
init : AnimGroupName -> Float -> AnimBuilder mode -> AnimBuilder mode
init animationKey value animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromHW value value
        |> SB.toHW value value
        |> SB.build


{-| Set the initial width and height.

    import Anim.Engine.* as Engine
    import Anim.Property.Size as Size

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Size.initHW "animGroupName" 200 100 ] }
        , Cmd.none
        )

-}
initHW : AnimGroupName -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
initHW animationKey h w animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromHW h w
        |> SB.toHW h w
        |> SB.build


{-| Set the initial width.

    import Anim.Engine.* as Engine
    import Anim.Property.Size as Size

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Size.initW "animGroupName" 200 ] }
        , Cmd.none
        )

-}
initW : AnimGroupName -> Float -> AnimBuilder mode -> AnimBuilder mode
initW animationKey w animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromW w
        |> SB.toW w
        |> SB.build


{-| Set the initial height.

    import Anim.Engine.* as Engine
    import Anim.Property.Size as Size

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Size.initH "animGroupName" 150 ] }
        , Cmd.none
        )

-}
initH : AnimGroupName -> Float -> AnimBuilder mode -> AnimBuilder mode
initH animationKey h animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromH h
        |> SB.toH h
        |> SB.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a size animation `Builder` for the specified animation group.

Use this to start configuring a size animation.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder mode -> Builder mode
for =
    SB.for


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Size.build
            >> ... -- continue with animation

-}
build : Builder mode -> AnimBuilder mode
build =
    SB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting height and width.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> Size.fromHW 200 100
            >> ... -- continue with animation

-}
fromHW : Float -> Float -> Builder mode -> Builder mode
fromHW =
    SB.fromHW


{-| Set the starting height, keeping the current width.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> Size.fromH 150
            >> ... -- continue with animation

The width remains unchanged, or 0 if not set.

-}
fromH : Float -> Builder mode -> Builder mode
fromH =
    SB.fromH


{-| Set the starting width, keeping the current height.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> Size.fromW 250
            >> ... -- continue with animation

The height remains unchanged, or 0 if not set.

-}
fromW : Float -> Builder mode -> Builder mode
fromW =
    SB.fromW


{-| Set the starting width and height to the same value.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> Size.from 100
            >> ... -- continue with animation

This is equivalent to calling `fromHW 100 100`.

-}
from : Float -> Builder mode -> Builder mode
from value =
    SB.fromHW value value



-- ============================================================
-- TO
-- ============================================================


{-| Set the target height and width for the current animation group.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 200 100
            >> ... -- continue with animation

-}
toHW : Float -> Float -> Builder mode -> Builder mode
toHW =
    SB.toHW


{-| Set the target height for the current animation group, keeping the current target width.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> Size.toH 150
            >> ... -- continue with animation

The width remains unchanged, or 0 if not set.

-}
toH : Float -> Builder mode -> Builder mode
toH =
    SB.toH


{-| Set the target width for the current animation group, keeping the current target height.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> Size.toW 250
            >> ... -- continue with animation

The height remains unchanged, or 0 if not set.

-}
toW : Float -> Builder mode -> Builder mode
toW =
    SB.toW



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 200 100
            >> Size.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder mode -> Builder mode
delay =
    SB.delay


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 200 100
            >> Size.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder mode -> Builder mode
duration =
    SB.duration


{-| The speed represents how many pixels the element's size changes per second.

For example, lets take a size animation from `(100, 100)` to `(200, 200)`.
A speed of `50.0` means the size will change by 50 pixels per second, so our animation will take 2 seconds to complete.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 200 200
            >> Size.speed 50
            >> ... -- continue with animation

Similarly, a speed of `100.0` would complete the same animation in 1 second, and a speed of `25.0` would take 4 seconds.

-}
speed : Float -> Builder mode -> Builder mode
speed =
    SB.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 200 100
            >> Size.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder mode -> Builder mode
easing =
    SB.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Drive this property with a spring instead of an easing curve.

Spring-driven motion has _emergent_ duration: the motion ends when
the value has settled at the target. Any `duration` or `speed` set on
this property is ignored when a spring is used. `delay` is honoured.

Setting `spring` clears any previously-set `easing` on this property,
and vice versa — they are mutually exclusive.

    import Motion.Spring as Spring

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Size.for "animGroupName"
            >> Size.toHW 200 100
            >> Size.spring Spring.wobbly

-}
spring : Spring -> Builder mode -> Builder mode
spring =
    SB.spring
