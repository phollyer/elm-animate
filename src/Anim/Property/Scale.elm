module Anim.Property.Scale exposing
    ( Builder, AnimGroupName
    , init, initXYZ, initXY, initXZ, initX, initYZ, initY, initZ
    , for, build
    , from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , delay, duration, speed
    , easing
    )

{-| Scale elements along the X, Y, and Z axes.

**Default**: 1.0 (original size) for all axes

This property uses a 'sensible default' approach to configuring animations.
When no start value is available, the default will be used.

Any axis that is not defined in the animation configuration will remain unchanged,
or 1.0 if not set.

    import Anim.Extra.Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toXY 1.5 1.5
            >> Scale.duration 1000
            >> Scale.easing EaseInOut
            >> Scale.build

The Engines track the end value of each animation, so new animations with no start value
will use the current end value as the start, ensuring a smooth transition between animations.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs init, initXYZ, initXY, initXZ, initX, initYZ, initY, initZ


# Build

@docs for, build


# Configure


## Start Value

All engines track end values, so subsequent animations automatically
use the previous end as the new start. Use `from` to override this
behaviour and set an explicit start value.

**Note:** The Transition Engine ignores start values — the browser always computes
starting values from the current computed style.

@docs from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## End Value

@docs to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Scale as SB



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `ScaleBuilder`.
-}
type alias Builder =
    SB.ScaleBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Turn the `AnimBuilder` into a scale animation `Builder` for the specified animation group.

Use this to start configuring a scale animation.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder -> Builder
for =
    SB.for


{-| Set the initial scale.

Use this to initialize the scale in your Engine's `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Scale.init "animGroupName" 1.5 ] }
        , Cmd.none
        )

This is equivalent to calling `initXYZ 1.5 1.5 1.5`.

-}
init : AnimGroupName -> Float -> AnimBuilder -> AnimBuilder
init animationKey value animBuilder =
    animBuilder
        |> SB.for animationKey
        |> from value
        |> to value
        |> SB.build


{-| Set the initial X, Y, and Z scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Scale.initXYZ "animGroupName" 1.5 1.2 1.0 ] }
        , Cmd.none
        )

-}
initXYZ : AnimGroupName -> Float -> Float -> Float -> AnimBuilder -> AnimBuilder
initXYZ animationKey x y z animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromXYZ x y z
        |> SB.toXYZ x y z
        |> SB.build


{-| Set the initial X and Y scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Scale.initXY "animGroupName" 1.5 1.2 ] }
        , Cmd.none
        )

-}
initXY : AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder
initXY animationKey x y animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromXY x y
        |> SB.toXY x y
        |> SB.build


{-| Set the initial X and Z scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Scale.initXZ "animGroupName" 1.5 1.0 ] }
        , Cmd.none
        )

-}
initXZ : AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder
initXZ animationKey x z animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromXZ x z
        |> SB.toXZ x z
        |> SB.build


{-| Set the initial X scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Scale.initX "animGroupName" 1.5 ] }
        , Cmd.none
        )

-}
initX : AnimGroupName -> Float -> AnimBuilder -> AnimBuilder
initX animationKey x animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromX x
        |> SB.toX x
        |> SB.build


{-| Set the initial Y and Z scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Scale.initYZ "animGroupName" 1.2 1.0 ] }
        , Cmd.none
        )

-}
initYZ : AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder
initYZ animationKey y z animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromYZ y z
        |> SB.toYZ y z
        |> SB.build


{-| Set the initial Y scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Scale.initY "animGroupName" 1.2 ] }
        , Cmd.none
        )

-}
initY : AnimGroupName -> Float -> AnimBuilder -> AnimBuilder
initY animationKey y animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromY y
        |> SB.toY y
        |> SB.build


{-| Set the initial Z scale.

    import Anim.Engine.* as Engine
    import Anim.Property.Scale as Scale

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Scale.initZ "animGroupName" 1.0 ] }
        , Cmd.none
        )

-}
initZ : AnimGroupName -> Float -> AnimBuilder -> AnimBuilder
initZ animationKey z animBuilder =
    animBuilder
        |> SB.for animationKey
        |> fromZ z
        |> SB.toZ z
        |> SB.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Scale.build
            >> ... -- continue with animation

-}
build : Builder -> AnimBuilder
build =
    SB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting scale (uniform across all axes).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.from 0.8
            >> ... -- continue with animation

This is equivalent to `Scale.fromXYZ 0.8 0.8 0.8`.

-}
from : Float -> Builder -> Builder
from uniformScale =
    SB.fromXYZ uniformScale uniformScale uniformScale


{-| Set the starting X, Y, and Z scale.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromXYZ 0.8 1.2 0.9
            >> ... -- continue with animation

-}
fromXYZ : Float -> Float -> Float -> Builder -> Builder
fromXYZ =
    SB.fromXYZ


{-| Set the starting X and Y scale.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromXY 0.8 1.2
            >> ... -- continue with animation

The Z scale remains unchanged, or 1.0 if not set.

-}
fromXY : Float -> Float -> Builder -> Builder
fromXY =
    SB.fromXY


{-| Set the starting X and Z scale.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromXZ 0.8 0.9
            >> ... -- continue with animation

The Y scale remains unchanged, or 1.0 if not set.

-}
fromXZ : Float -> Float -> Builder -> Builder
fromXZ =
    SB.fromXZ


{-| Set the starting X-axis scale.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromX 0.8
            >> ... -- continue with animation

The Y and Z scales remain unchanged, or 1.0 if not set.

-}
fromX : Float -> Builder -> Builder
fromX =
    SB.fromX


{-| Set the starting Y and Z scale.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromYZ 1.2 0.9
            >> ... -- continue with animation

The X scale remains unchanged, or 1.0 if not set.

-}
fromYZ : Float -> Float -> Builder -> Builder
fromYZ =
    SB.fromYZ


{-| Set the starting Y-axis scale.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromY 1.2
            >> ... -- continue with animation

The X and Z scales remain unchanged, or 1.0 if not set.

-}
fromY : Float -> Builder -> Builder
fromY =
    SB.fromY


{-| Set the starting Z-axis scale.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.fromZ 1.1
            >> ... -- continue with animation

The X and Y scales remain unchanged, or 1.0 if not set.

-}
fromZ : Float -> Builder -> Builder
fromZ =
    SB.fromZ



-- ============================================================
-- TO
-- ============================================================


{-| Set the target scale for the current animation group (uniform across all axes).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.to 1.5
            >> ... -- continue with animation

This is equivalent to `toXYZ 1.5 1.5 1.5`.

-}
to : Float -> Builder -> Builder
to targetScale =
    SB.toXYZ targetScale targetScale targetScale


{-| Set the target X, Y, and Z scale for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toXYZ 1.5 2.0 0.8
            >> ... -- continue with animation

-}
toXYZ : Float -> Float -> Float -> Builder -> Builder
toXYZ =
    SB.toXYZ


{-| Set the target X and Y scale for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toXY 1.5 2.0
            >> ... -- continue with animation

The Z scale remains unchanged, or 1.0 if not set.

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    SB.toXY


{-| Set the target X and Z scale for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toXZ 1.5 0.8
            >> ... -- continue with animation

The Y scale remains unchanged, or 1.0 if not set.

-}
toXZ : Float -> Float -> Builder -> Builder
toXZ =
    SB.toXZ


{-| Set the target X-axis scale for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toX 2.0
            >> ... -- continue with animation

The Y and Z scales remain unchanged, or 1.0 if not set.

-}
toX : Float -> Builder -> Builder
toX =
    SB.toX


{-| Set the target Y and Z scale for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toYZ 1.5 0.8
            >> ... -- continue with animation

The X scale remains unchanged, or 1.0 if not set.

-}
toYZ : Float -> Float -> Builder -> Builder
toYZ =
    SB.toYZ


{-| Set the target Y-axis scale for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toY 1.5
            >> ... -- continue with animation

The X and Z scales remain unchanged, or 1.0 if not set.

-}
toY : Float -> Builder -> Builder
toY =
    SB.toY


{-| Set the target Z-axis scale for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toZ 0.8
            >> ... -- continue with animation

The X and Y scales remain unchanged, or 1.0 if not set.

-}
toZ : Float -> Builder -> Builder
toZ =
    SB.toZ



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.to 1.5
            >> Scale.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder -> Builder
delay =
    SB.delay


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.to 1.5
            >> Scale.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| The speed represents how much the scale factor changes per second.

For example, lets take a scale animation from `1.0` to `5.0`.
A speed of `2.0` means the scale will change by 2.0 units per second, so our animation will take 2 seconds to complete (1.0 -> 3.0 in 1 second, then 3.0 -> 5.0 in the next second).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.toXYZ 5.0 5.0 5.0
            >> Scale.speed 2.0
            >> ... -- continue with animation

Similarly, a speed of `4.0` would complete the same animation in 1 second, and a speed of `1.0` would take 4 seconds.

-}
speed : Float -> Builder -> Builder
speed =
    SB.speed


{-| Set the easing function for the animation.

    import Anim.Extra.Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Scale.for "animGroupName"
            >> Scale.to 1.5
            >> Scale.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder -> Builder
easing =
    SB.easing
