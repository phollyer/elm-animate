module Anim.Property.Translate exposing
    ( Builder, GroupName
    , initXYZ, initXY, initXZ, initX, initYZ, initY, initZ
    , for, build
    , fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , byXYZ, byXY, byXZ, byX, byYZ, byY, byZ
    , delay, duration, speed
    , easing
    )

{-| Move elements along the X, Y, and Z axes.

**Default**: 0 for all axes

This property uses a 'sensible default' approach to configuring animations.
When no start value is available for any axis, the default will be used for that axis.

Any axis that is not defined in the animation configuration will remain unchanged,
or zero if not set.

    import Anim.Extra.Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toXY 200 100
            >> Translate.duration 1000
            >> Translate.easing EaseInOut
            >> Translate.build

The Engines track the end value of the animation, so new animations with no start value
will use the current end value as the start, ensuring a smooth transition between animations.


# Types

@docs Builder, GroupName


# Initialize

@docs initXYZ, initXY, initXZ, initX, initYZ, initY, initZ


# Build

@docs for, build


# Configure


## Start Value

How setting a start value behaves depends on the engine:

  - **Keyframes** — use this to set explicit starting values; otherwise property defaults apply.
  - **WAAPI `fireAndForget`** — use this to set explicit starting values; otherwise property defaults apply.
  - **Sub / WAAPI** — useful to override the current tracked position.
  - **Transitions** — ignored; the browser computes starting values.

@docs fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## End Value (Absolute)

@docs toXYZ, toXY, toXZ, toX, toYZ, toY, toZ


## End Value (Relative)

The end value is computed as `current + delta` at build time.

How the **current** position is determined depends on
the engine, the underlying technology being targeted, and the state of the animation:

  - **Sub / WAAPI** — _always accurate_; both track current animated position, even mid-flight.


### Animations that have completed:

  - **Keyframes / Transitions** — _always accurate_;
      - uses the current configurations start value if provided
      - otherwise, uses the previous animation's end value
      - otherwise, the default value (0 for translate) applies


### Animations that are in-flight:

CSS Keyframes and Transitions do not track the current position of the animation mid-flight,
so relative movements are based on the start and end values of the current/previous configuration:

  - **Keyframes/Transitions** — _not accurate_;
      - uses the start value of the current configuration if it exists
      - otherwise, uses the in-flight end value
      - otherwise, the default value (0 for translate) applies

@docs byXYZ, byXY, byXZ, byX, byYZ, byY, byZ


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Translate as TB


{-| Type alias for the animation group name.
-}
type alias GroupName =
    String


{-| Type alias for the internal `TranslateBuilder`.
-}
type alias Builder =
    TB.TranslateBuilder


{-| Turn the `AnimBuilder` into a translate animation `Builder` for the specified animation group.

Use this to start configuring a translate animation.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : GroupName -> AnimBuilder -> Builder
for =
    TB.for


{-| Set the initial X, Y, and Z position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Translate.initXYZ "animGroupName" 100 20 50 ] }
        , Cmd.none
        )

-}
initXYZ : GroupName -> Float -> Float -> Float -> AnimBuilder -> AnimBuilder
initXYZ animationKey x y z =
    TB.for animationKey
        >> fromXYZ x y z
        >> TB.toXYZ x y z
        >> TB.build


{-| Set the initial X and Y position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Translate.initXY "animGroupName" 100 20 ] }
        , Cmd.none
        )

-}
initXY : GroupName -> Float -> Float -> AnimBuilder -> AnimBuilder
initXY animationKey x y animBuilder =
    animBuilder
        |> TB.for animationKey
        |> fromXY x y
        |> TB.toXY x y
        |> TB.build


{-| Set the initial X and Z position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Translate.initXZ "animGroupName" 100 50 ] }
        , Cmd.none
        )

-}
initXZ : GroupName -> Float -> Float -> AnimBuilder -> AnimBuilder
initXZ animationKey x z animBuilder =
    animBuilder
        |> TB.for animationKey
        |> fromXZ x z
        |> TB.toXZ x z
        |> TB.build


{-| Set the initial X position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Translate.initX "animGroupName" 100 ] }
        , Cmd.none
        )

-}
initX : GroupName -> Float -> AnimBuilder -> AnimBuilder
initX animationKey x animBuilder =
    animBuilder
        |> TB.for animationKey
        |> fromX x
        |> TB.toX x
        |> TB.build


{-| Set the initial Y and Z position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Translate.initYZ "animGroupName" 20 50 ] }
        , Cmd.none
        )

-}
initYZ : GroupName -> Float -> Float -> AnimBuilder -> AnimBuilder
initYZ animationKey y z animBuilder =
    animBuilder
        |> TB.for animationKey
        |> fromYZ y z
        |> TB.toYZ y z
        |> TB.build


{-| Set the initial Y position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Translate.initY "animGroupName" 20 ] }
        , Cmd.none
        )

-}
initY : GroupName -> Float -> AnimBuilder -> AnimBuilder
initY animationKey y animBuilder =
    animBuilder
        |> TB.for animationKey
        |> fromY y
        |> TB.toY y
        |> TB.build


{-| Set the initial Z position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Translate.initZ "animGroupName" 50 ] }
        , Cmd.none
        )

-}
initZ : GroupName -> Float -> AnimBuilder -> AnimBuilder
initZ animationKey z animBuilder =
    animBuilder
        |> TB.for animationKey
        |> fromZ z
        |> TB.toZ z
        |> TB.build


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Translate.build
            >> ... -- continue with animation

-}
build : Builder -> AnimBuilder
build =
    TB.build


{-| Set the starting X, Y, and Z position.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXYZ 100 20 50
            >> ... -- continue with animation

-}
fromXYZ : Float -> Float -> Float -> Builder -> Builder
fromXYZ =
    TB.fromXYZ


{-| Set the starting X and Y position.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXY 100 20
            >> ... -- continue with animation

The Z position remains unchanged, or zero if not set.

-}
fromXY : Float -> Float -> Builder -> Builder
fromXY =
    TB.fromXY


{-| Set the starting X and Z position.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXZ 100 50
            >> ... -- continue with animation

The Y position remains unchanged, or zero if not set.

-}
fromXZ : Float -> Float -> Builder -> Builder
fromXZ =
    TB.fromXZ


{-| Set the starting X position.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromX 100
            >> ... -- continue with animation

The Y and Z positions remain unchanged, or zero if not set.

-}
fromX : Float -> Builder -> Builder
fromX =
    TB.fromX


{-| Set the starting Y and Z position.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromYZ 200 50
            >> ... -- continue with animation

The X position remains unchanged, or zero if not set.

-}
fromYZ : Float -> Float -> Builder -> Builder
fromYZ =
    TB.fromYZ


{-| Set the starting Y position.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromY 50
            >> ... -- continue with animation

The X and Z positions remain unchanged, or zero if not set.

-}
fromY : Float -> Builder -> Builder
fromY =
    TB.fromY


{-| Set the starting Z position.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromZ 75
            >> ... -- continue with animation

The X and Y positions remain unchanged, or zero if not set.

-}
fromZ : Float -> Builder -> Builder
fromZ =
    TB.fromZ


{-| Set the target X, Y, and Z position for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toXYZ 100 200 50
            >> ... -- continue with animation

-}
toXYZ : Float -> Float -> Float -> Builder -> Builder
toXYZ =
    TB.toXYZ


{-| Set the target X and Y position for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toXY 100 200
            >> ... -- continue with animation

The Z position remains unchanged, or zero if not set.

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    TB.toXY


{-| Set the target X and Z position for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toXZ 100 50
            >> ... -- continue with animation

The Y position remains unchanged, or zero if not set.

-}
toXZ : Float -> Float -> Builder -> Builder
toXZ =
    TB.toXZ


{-| Set the target X position for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toX 150
            >> ... -- continue with animation

The Y and Z positions remain unchanged, or zero if not set.

-}
toX : Float -> Builder -> Builder
toX =
    TB.toX


{-| Set the target Y and Z position for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toYZ 200 75
            >> ... -- continue with animation

The X position remains unchanged, or zero if not set.

-}
toYZ : Float -> Float -> Builder -> Builder
toYZ =
    TB.toYZ


{-| Set the target Y position for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toY 250
            >> ... -- continue with animation

The X and Z positions remain unchanged, or zero if not set.

-}
toY : Float -> Builder -> Builder
toY =
    TB.toY


{-| Set the target Z position for the current animation group.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toZ 75
            >> ... -- continue with animation

The X and Y positions remain unchanged, or zero if not set.

-}
toZ : Float -> Builder -> Builder
toZ =
    TB.toZ


{-| The speed represents how many pixels the element moves per second.

For example, lets take a translate animation from `(0, 0)` to `(100, 0)`.
A speed of `50.0` means the element will move 50 pixels per second, so our animation will take 2 seconds to complete (0 -> 50 in 1 second, then 50 -> 100 in the next second).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toX 100
            >> Translate.speed 50
            >> ... -- continue with animation

Similarly, a speed of `100.0` would complete the same animation in 1 second, and a speed of `25.0` would take 4 seconds.

-}
speed : Float -> Builder -> Builder
speed =
    TB.speed


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toY 300
            >> Translate.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder -> Builder
duration =
    TB.duration


{-| Set the easing function for the animation.

    import Anim.Extra.Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toY 300
            >> Translate.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder -> Builder
easing =
    TB.easing


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toY 300
            >> Translate.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder -> Builder
delay =
    TB.delay



-- BY (relative movement)


{-| Move by specific amounts on the X, Y, and Z axes.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXY 100 100
            >> Translate.byXYZ 50 -25 10
            >> ... -- continue with animation

This would animate from `(100, 100, 0)` to `(150, 75, 10)`.

-}
byXYZ : Float -> Float -> Float -> Builder -> Builder
byXYZ =
    TB.byXYZ


{-| Move by specific amounts on the X and Y axes.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXY 100 100
            >> Translate.byXY 50 -25
            >> ... -- continue with animation

This would animate from `(100, 100)` to `(150, 75)`.

-}
byXY : Float -> Float -> Builder -> Builder
byXY =
    TB.byXY


{-| Move by specific amounts on the X and Z axes.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.byXZ 50 10
            >> ... -- continue with animation

-}
byXZ : Float -> Float -> Builder -> Builder
byXZ =
    TB.byXZ


{-| Move by a specific amount on the X axis.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromX 100
            >> Translate.byX 50
            >> ... -- continue with animation

This would animate from `100` to `150` on the X axis.

-}
byX : Float -> Builder -> Builder
byX =
    TB.byX


{-| Move by specific amounts on the Y and Z axes.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.byYZ -25 10
            >> ... -- continue with animation

-}
byYZ : Float -> Float -> Builder -> Builder
byYZ =
    TB.byYZ


{-| Move by a specific amount on the Y axis.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromY 100
            >> Translate.byY -50
            >> ... -- continue with animation

This would animate from `100` to `50` on the Y axis.

-}
byY : Float -> Builder -> Builder
byY =
    TB.byY


{-| Move by a specific amount on the Z axis.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromZ 0
            >> Translate.byZ 100
            >> ... -- continue with animation

This would animate from `0` to `100` on the Z axis.

-}
byZ : Float -> Builder -> Builder
byZ =
    TB.byZ
