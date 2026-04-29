module Anim.Property.Rotate exposing
    ( Builder, AnimGroupName
    , initXYZ, initXY, initXZ, initX, initYZ, initY, initZ
    , for, build
    , fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , delay, duration, speed
    , easing
    )

{-| Rotate elements around the X, Y, and Z axes.

**Default**: 0 degrees for all axes

This property uses a 'sensible default' approach to configuring animations.
When no start value is available for any axis, the default will be used for that axis.

Any axis that is not defined in the animation configuration will remain unchanged,
or zero if not set.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toZ 180
            >> Rotate.duration 1000
            >> Rotate.easing EaseInOut
            >> Rotate.build

The Engines track the end value of each animation, so new animations with no start value
will use the current end value as the start, ensuring a smooth transition between animations.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs initXYZ, initXY, initXZ, initX, initYZ, initY, initZ


# Build

@docs for, build


# Configure


## Start Value

Use `from` to set an explicit start value. When not set, the engine determines
the start - behaviour varies by engine and context. See [Mid-Flight Interruptions](https://phollyer.github.io/elm-animate/animation/concepts/interrupting-animations/)
for details.

@docs fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## End Value

@docs toXYZ, toXY, toXZ, toX, toYZ, toY, toZ


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Rotate as RB
import Easing exposing (Easing)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `RotateBuilder`.
-}
type alias Builder =
    RB.RotateBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Turn the `AnimBuilder` into a rotate animation `Builder` for the specified animation group.

Use this to start configuring a rotate animation.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder -> Builder
for =
    RB.for


{-| Set the initial X, Y, and Z rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Rotate.initXYZ "animGroupName" 45 30 60 ] }
        , Cmd.none
        )

-}
initXYZ : AnimGroupName -> Float -> Float -> Float -> AnimBuilder -> AnimBuilder
initXYZ animationKey x y z animBuilder =
    animBuilder
        |> for animationKey
        |> fromXYZ x y z
        |> toXYZ x y z
        |> build


{-| Set the initial X and Y rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Rotate.initXY "animGroupName" 45 30 ] }
        , Cmd.none
        )

-}
initXY : AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder
initXY animationKey x y animBuilder =
    animBuilder
        |> for animationKey
        |> fromXY x y
        |> toXY x y
        |> build


{-| Set the initial X and Z rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Rotate.initXZ "animGroupName" 45 60 ] }
        , Cmd.none
        )

-}
initXZ : AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder
initXZ animationKey x z animBuilder =
    animBuilder
        |> for animationKey
        |> fromXZ x z
        |> toXZ x z
        |> build


{-| Set the initial X rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Rotate.initX "animGroupName" 45 ] }
        , Cmd.none
        )

-}
initX : AnimGroupName -> Float -> AnimBuilder -> AnimBuilder
initX animationKey x animBuilder =
    animBuilder
        |> for animationKey
        |> fromX x
        |> toX x
        |> build


{-| Set the initial Y and Z rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Rotate.initYZ "animGroupName" 30 60 ] }
        , Cmd.none
        )

-}
initYZ : AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder
initYZ animationKey y z animBuilder =
    animBuilder
        |> for animationKey
        |> fromYZ y z
        |> toYZ y z
        |> build


{-| Set the initial Y rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Rotate.initY "animGroupName" 30 ] }
        , Cmd.none
        )

-}
initY : AnimGroupName -> Float -> AnimBuilder -> AnimBuilder
initY animationKey y animBuilder =
    animBuilder
        |> for animationKey
        |> fromY y
        |> toY y
        |> build


{-| Set the initial Z rotation.

    import Anim.Engine.* as Engine
    import Anim.Property.Rotate as Rotate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Rotate.initZ "animGroupName" 60 ] }
        , Cmd.none
        )

-}
initZ : AnimGroupName -> Float -> AnimBuilder -> AnimBuilder
initZ animationKey z animBuilder =
    animBuilder
        |> for animationKey
        |> fromZ z
        |> toZ z
        |> build


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Rotate.build
            >> ... -- continue with animation

-}
build : Builder -> AnimBuilder
build =
    RB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting X, Y, and Z rotations (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromXYZ 45 90 180
            >> ... -- continue with animation

-}
fromXYZ : Float -> Float -> Float -> Builder -> Builder
fromXYZ =
    RB.fromXYZ


{-| Set the starting X and Y rotations (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromXY 45 90
            >> ... -- continue with animation

The Z rotation remains unchanged, or zero if not set.

-}
fromXY : Float -> Float -> Builder -> Builder
fromXY =
    RB.fromXY


{-| Set the starting X and Z rotations (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromXZ 45 180
            >> ... -- continue with animation

The Y rotation remains unchanged, or zero if not set.

-}
fromXZ : Float -> Float -> Builder -> Builder
fromXZ =
    RB.fromXZ


{-| Set the starting X-axis rotation (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromX 45
            >> ... -- continue with animation

The Y and Z rotations remain unchanged, or zero if not set.

-}
fromX : Float -> Builder -> Builder
fromX =
    RB.fromX


{-| Set the starting Y and Z rotations (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromYZ 90 180
            >> ... -- continue with animation

The X rotation remains unchanged, or zero if not set.

-}
fromYZ : Float -> Float -> Builder -> Builder
fromYZ =
    RB.fromYZ


{-| Set the starting Y-axis rotation (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromY 90
            >> ... -- continue with animation

The X and Z rotations remain unchanged, or zero if not set.

-}
fromY : Float -> Builder -> Builder
fromY =
    RB.fromY


{-| Set the starting Z-axis rotation (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.fromZ 180
            >> ... -- continue with animation

The X and Y rotations remain unchanged, or zero if not set.

-}
fromZ : Float -> Builder -> Builder
fromZ =
    RB.fromZ



-- ============================================================
-- TO
-- ============================================================


{-| Set the target X, Y, and Z rotations for the current animation group (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toXYZ 45 90 180
            >> ... -- continue with animation

-}
toXYZ : Float -> Float -> Float -> Builder -> Builder
toXYZ =
    RB.toXYZ


{-| Set the target X and Y rotations for the current animation group (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toXY 45 90
            >> ... -- continue with animation

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    RB.toXY


{-| Set the target X and Z rotations for the current animation group (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toXZ 45 180
            >> ... -- continue with animation

-}
toXZ : Float -> Float -> Builder -> Builder
toXZ =
    RB.toXZ


{-| Set the target X-axis rotation for the current animation group (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toX 45
            >> ... -- continue with animation

The Y and Z rotations remain unchanged, or zero if not set.

-}
toX : Float -> Builder -> Builder
toX =
    RB.toX


{-| Set the target Y and Z rotations for the current animation group (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toYZ 90 180
            >> ... -- continue with animation

-}
toYZ : Float -> Float -> Builder -> Builder
toYZ =
    RB.toYZ


{-| Set the target Y-axis rotation for the current animation group (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toY 90
            >> ... -- continue with animation

The X and Z rotations remain unchanged, or zero if not set.

-}
toY : Float -> Builder -> Builder
toY =
    RB.toY


{-| Set the target Z-axis rotation for the current animation group (degrees).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toZ 180
            >> ... -- continue with animation

The X and Y rotations remain unchanged, or zero if not set.

-}
toZ : Float -> Builder -> Builder
toZ =
    RB.toZ



-- ============================================================
-- TIMING
-- ============================================================


{-| The speed represents how many degrees the element rotates per second.

For example, lets take a rotation animation from `0°` to `180°`.
A speed of `90.0` means the element will rotate 90 degrees per second, so our animation will take 2 seconds to complete (0° -> 90° in 1 second, then 90° -> 180° in the next second).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toZ 180
            >> Rotate.speed 90
            >> ... -- continue with animation

Similarly, a speed of `180.0` would complete the same animation in 1 second, and a speed of `45.0` would take 4 seconds.

-}
speed : Float -> Builder -> Builder
speed =
    RB.speed


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toZ 180
            >> Rotate.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder -> Builder
duration =
    RB.duration


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toZ 180
            >> Rotate.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder -> Builder
easing =
    RB.easing


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Rotate.for "animGroupName"
            >> Rotate.toZ 180
            >> Rotate.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder -> Builder
delay =
    RB.delay
