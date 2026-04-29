module Anim.Property.Skew exposing
    ( Builder, AnimGroupName
    , initXY, initX, initY
    , for, build
    , fromXY, fromX, fromY
    , toXY, toX, toY
    , delay, duration, speed
    , easing
    )

{-| Skew elements along the X and Y axes.

**Default**: 0 degrees for both axes

This property uses a 'sensible default' approach to configuring animations.
When no start value is available for any axis, the default will be used.

Any axis that is not defined in the animation configuration will remain unchanged,
or zero if not set.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Skew.for "animGroupName"
            >> Skew.toXY 12 0
            >> Skew.duration 500
            >> Skew.easing EaseInOut
            >> Skew.build

The Engines track the end value of each animation, so new animations with no start value
will use the current end value as the start, ensuring a smooth transition between animations.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs initXY, initX, initY


# Build

@docs for, build


# Configure


## Start Value

When not set, the engine determines the start value - behaviour
varies by engine and context.

📖 See [Start Values](https://phollyer.github.io/elm-animate/animation/engines/overview/#start-values)
for details.

@docs fromXY, fromX, fromY


## End Value

@docs toXY, toX, toY


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Skew as SB
import Easing exposing (Easing)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `SkewBuilder`.
-}
type alias Builder =
    SB.SkewBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Turn the `AnimBuilder` into a skew animation `Builder` for the specified animation group.

Use this to start configuring a skew animation.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Skew.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder -> Builder
for =
    SB.for


{-| Set the initial X and Y skew.

    import Anim.Engine.* as Engine
    import Anim.Property.Skew as Skew

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Skew.initXY "animGroupName" 12 6 ] }
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


{-| Set the initial X skew.

    import Anim.Engine.* as Engine
    import Anim.Property.Skew as Skew

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Skew.initX "animGroupName" 12 ] }
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


{-| Set the initial Y skew.

    import Anim.Engine.* as Engine
    import Anim.Property.Skew as Skew

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Skew.initY "animGroupName" 8 ] }
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



-- ============================================================
-- BUILD
-- ============================================================


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Skew.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Skew.build
            >> ... -- continue with animation

-}
build : Builder -> AnimBuilder
build =
    SB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting X and Y skew (degrees).
-}
fromXY : Float -> Float -> Builder -> Builder
fromXY =
    SB.fromXY


{-| Set the starting X skew (degrees).
-}
fromX : Float -> Builder -> Builder
fromX =
    SB.fromX


{-| Set the starting Y skew (degrees).
-}
fromY : Float -> Builder -> Builder
fromY =
    SB.fromY



-- ============================================================
-- TO
-- ============================================================


{-| Set the target X and Y skew (degrees).
-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    SB.toXY


{-| Set the target X skew (degrees).
-}
toX : Float -> Builder -> Builder
toX =
    SB.toX


{-| Set the target Y skew (degrees).
-}
toY : Float -> Builder -> Builder
toY =
    SB.toY



-- ============================================================
-- TIMING
-- ============================================================


{-| The speed represents how many degrees the skew changes per second.

For example, a skew animation from `0` to `30` degrees with a speed of `15.0` will take 2 seconds to complete.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Skew.for "animGroupName"
            >> Skew.toXY 30 0
            >> Skew.speed 15.0
            >> ... -- continue with animation

-}
speed : Float -> Builder -> Builder
speed =
    SB.speed


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Skew.for "animGroupName"
            >> Skew.toXY 12 0
            >> Skew.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder -> Builder
duration =
    SB.duration


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Skew.for "animGroupName"
            >> Skew.toXY 12 0
            >> Skew.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder -> Builder
easing =
    SB.easing


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Skew.for "animGroupName"
            >> Skew.toXY 12 0
            >> Skew.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder -> Builder
delay =
    SB.delay
