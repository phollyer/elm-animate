module Anim.Property.PerspectiveOrigin exposing
    ( Builder, AnimGroupName
    , initPx, initPercent
    , for, build
    , px, percent
    , from, fromXY, fromX, fromY
    , to, toXY, toX, toY
    , delay, duration, speed
    , easing
    )

{-| Animate the CSS `perspective-origin` property, which controls the vanishing point
for 3D transforms applied to a parent element.

**Default unit**: pixels. Call [`percent`](#percent) to switch to percentage values.

**Default value**: `50% 50%` (center of the element)

This property uses a 'sensible default' approach to configuring animations.
When no start value is available, `50% 50%` will be used.

    import Easing exposing (Easing(..))


    -- Pixels (default)
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 100 50
            >> PerspectiveOrigin.duration 500
            >> PerspectiveOrigin.easing EaseInOut
            >> PerspectiveOrigin.build

    -- Percentages
    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.percent
            >> PerspectiveOrigin.to 25 75
            >> PerspectiveOrigin.duration 500
            >> PerspectiveOrigin.easing EaseInOut
            >> PerspectiveOrigin.build

The engines track the end value of each animation, so new animations with no start value
will use the current end value as the start, ensuring a smooth transition between animations.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs initPx, initPercent


# Build

@docs for, build


# Configure


## Unit

Call `px` or `percent` once at the start of the pipeline to set the unit for all
`from`, `to`, `toX`, and `toY` calls. Defaults to pixels.

@docs px, percent


## Start Value

When not set, the engine determines the start value - behaviour
varies by engine and context.

📖 See [Start Values](https://phollyer.github.io/elm-animate/animation/engines/overview/#start-values)
for details.

@docs from, fromXY, fromX, fromY


## End Value

@docs to, toXY, toX, toY


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builder.PerspectiveOrigin as PB
import Easing exposing (Easing)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `PerspectiveOriginBuilder`.
-}
type alias Builder =
    PB.PerspectiveOriginBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Set the initial perspective origin using pixel values.

    import Anim.Engine.* as Engine
    import Anim.Property.PerspectiveOrigin as PerspectiveOrigin

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ PerspectiveOrigin.initPx "animGroupName" 200 150 ] }
        , Cmd.none
        )

-}
initPx : AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder
initPx animationKey x y animBuilder =
    animBuilder
        |> for animationKey
        |> fromXY x y
        |> toXY x y
        |> build


{-| Set the initial perspective origin using percentage values.

    import Anim.Engine.* as Engine
    import Anim.Property.PerspectiveOrigin as PerspectiveOrigin

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ PerspectiveOrigin.initPercent "animGroupName" 50 50 ] }
        , Cmd.none
        )

-}
initPercent : AnimGroupName -> Float -> Float -> AnimBuilder -> AnimBuilder
initPercent animationKey x y animBuilder =
    animBuilder
        |> for animationKey
        |> percent
        |> fromXY x y
        |> toXY x y
        |> build



-- ============================================================
-- BUILD
-- ============================================================


{-| Turn the `AnimBuilder` into a perspective origin animation `Builder` for the specified animation group.

Use this to start configuring a perspective origin animation.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder -> Builder
for =
    PB.for


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> PerspectiveOrigin.build
            >> ... -- continue with animation

-}
build : Builder -> AnimBuilder
build =
    PB.build



-- ============================================================
-- UNIT
-- ============================================================


{-| Use pixel values for all `from`, `to`, `toX`, and `toY` calls. This is the default.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.px
            >> PerspectiveOrigin.to 200 150
            >> PerspectiveOrigin.duration 500
            >> PerspectiveOrigin.build

-}
px : Builder -> Builder
px =
    PB.px


{-| Use percentage values (0 - 100) for all `from`, `to`, `toX`, and `toY` calls.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.percent
            >> PerspectiveOrigin.to 25 75
            >> PerspectiveOrigin.duration 500
            >> PerspectiveOrigin.build

-}
percent : Builder -> Builder
percent =
    PB.percent



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting X and Y values. Uses the unit set by [`px`](#px) or [`percent`](#percent).
-}
from : Float -> Builder -> Builder
from xy =
    PB.fromXY xy xy


{-| Set the starting X and Y values. Uses the unit set by [`px`](#px) or [`percent`](#percent).
-}
fromXY : Float -> Float -> Builder -> Builder
fromXY =
    PB.fromXY


{-| Set the starting X value, preserving the current Y value. Uses the active unit.
-}
fromX : Float -> Builder -> Builder
fromX =
    PB.fromX


{-| Set the starting Y value, preserving the current X value. Uses the active unit.
-}
fromY : Float -> Builder -> Builder
fromY =
    PB.fromY



-- ============================================================
-- TO
-- ============================================================


{-| Set the target X and Y values. Uses the unit set by [`px`](#px) or [`percent`](#percent).
-}
to : Float -> Builder -> Builder
to xy =
    PB.toXY xy xy


{-| Set the target X and Y values. Uses the unit set by [`px`](#px) or [`percent`](#percent).
-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    PB.toXY


{-| Set the target X value, preserving the current Y value. Uses the active unit.
-}
toX : Float -> Builder -> Builder
toX =
    PB.toX


{-| Set the target Y value, preserving the current X value. Uses the active unit.
-}
toY : Float -> Builder -> Builder
toY =
    PB.toY



-- ============================================================
-- TIMING
-- ============================================================


{-| The speed represents how many units per second the perspective origin changes.

For example, an animation from `0` to `200px` with a speed of `100.0` will take 2 seconds to complete.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200 150
            >> PerspectiveOrigin.speed 100.0
            >> ... -- continue with animation

-}
speed : Float -> Builder -> Builder
speed =
    PB.speed


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200 150
            >> PerspectiveOrigin.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder -> Builder
duration =
    PB.duration


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200 150
            >> PerspectiveOrigin.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder -> Builder
easing =
    PB.easing


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder -> AnimBuilder
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200 150
            >> PerspectiveOrigin.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder -> Builder
delay =
    PB.delay
