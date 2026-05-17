module Anim.Property.PerspectiveOrigin exposing
    ( Builder, AnimGroupName
    , initPx, initPercent
    , for, build
    , px, percent
    , from, fromXY, fromX, fromY
    , to, toXY, toX, toY
    , delay, duration, speed
    , easing
    , spring
    , clampX, clampY, unclampX, unclampY
    , resizePolicy, bounds
    )

{-| Animate the CSS `perspective-origin` property, which controls the vanishing point
for 3D transforms applied to a parent element.

**Default unit**: `%`. Use [`px`](#px) to switch to pixel values.

**Default value**: `50% 50%` (center of the element)

    import Easing exposing (Easing(..))


    -- Percentages (default)
    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 100
            >> PerspectiveOrigin.duration 500
            >> PerspectiveOrigin.easing EaseInOut
            >> PerspectiveOrigin.build

    -- Pixels
    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.px
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.duration 500
            >> PerspectiveOrigin.easing EaseInOut
            >> PerspectiveOrigin.build

The Engines track the end value of each animation, so new animations with no start value
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

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/engines/overview/#start-values)
for details.

@docs from, fromXY, fromX, fromY


## End Value

@docs to, toXY, toX, toY


## Timing

@docs delay, duration, speed


## Easing

@docs easing


## Spring

@docs spring


## Bounds

Declare persistent per-axis clamps that constrain every value flowing through
the pipeline. See [clampX](#clampX) for behaviour.

@docs clampX, clampY, unclampX, unclampY


## Resize

Set how perspective-origin responds to viewport/container resize and provide
new bounds during `onResize`.

@docs resizePolicy, bounds

-}

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.PerspectiveOrigin as PB
import Anim.Internal.Resize.Builder as ResizeBuilder
import Anim.Resize as Resize
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `PerspectiveOriginBuilder`.
-}
type alias Builder mode =
    PB.PerspectiveOriginBuilder mode



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
initPx : AnimGroupName -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
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
initPercent : AnimGroupName -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
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

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder mode -> Builder mode
for =
    PB.for


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> PerspectiveOrigin.build
            >> ... -- continue with animation

-}
build : Builder mode -> AnimBuilder mode
build =
    PB.build



-- ============================================================
-- UNIT
-- ============================================================


{-| Use pixel values for all `from`, `to`, `toX`, and `toY` calls.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.px
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.duration 500
            >> PerspectiveOrigin.build

-}
px : Builder mode -> Builder mode
px =
    PB.px


{-| Use percentage values (0 - 100) for all `from`, `to`, `toX`, and `toY` calls. This is the default.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.percent
            >> PerspectiveOrigin.to 25
            >> PerspectiveOrigin.duration 500
            >> PerspectiveOrigin.build

-}
percent : Builder mode -> Builder mode
percent =
    PB.percent



-- ============================================================
-- FROM
-- ============================================================


{-| Set the uniform starting X and Y values.
-}
from : Float -> Builder mode -> Builder mode
from xy =
    PB.fromXY xy xy


{-| Set the starting X and Y values.
-}
fromXY : Float -> Float -> Builder mode -> Builder mode
fromXY =
    PB.fromXY


{-| Set the starting X value, preserving the current Y value.
-}
fromX : Float -> Builder mode -> Builder mode
fromX =
    PB.fromX


{-| Set the starting Y value, preserving the current X value.
-}
fromY : Float -> Builder mode -> Builder mode
fromY =
    PB.fromY



-- ============================================================
-- TO
-- ============================================================


{-| Set the uniform target X and Y values.
-}
to : Float -> Builder mode -> Builder mode
to xy =
    PB.toXY xy xy


{-| Set the target X and Y values.
-}
toXY : Float -> Float -> Builder mode -> Builder mode
toXY =
    PB.toXY


{-| Set the target X value, preserving the current Y value.
-}
toX : Float -> Builder mode -> Builder mode
toX =
    PB.toX


{-| Set the target Y value, preserving the current X value.
-}
toY : Float -> Builder mode -> Builder mode
toY =
    PB.toY



-- ============================================================
-- TIMING
-- ============================================================


{-| The speed represents how many units per second the perspective origin changes.

For example, an animation from `0` to `200px` with a speed of `100.0` will take 2 seconds to complete.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.speed 100
            >> ... -- continue with animation

-}
speed : Float -> Builder mode -> Builder mode
speed =
    PB.speed


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder mode -> Builder mode
duration =
    PB.duration


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder mode -> Builder mode
easing =
    PB.easing



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
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.spring Spring.wobbly

-}
spring : Spring -> Builder mode -> Builder mode
spring =
    PB.spring


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        PerspectiveOrigin.for "animGroupName"
            >> PerspectiveOrigin.to 200
            >> PerspectiveOrigin.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder mode -> Builder mode
delay =
    PB.delay



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Constrain the X axis of the active animGroup's perspective-origin to
`[min, max]`.

The clamp is persistent: once declared it applies to every subsequent
`animate` / `retarget` call on this animGroup until you call [unclampX](#unclampX)
(or call `clampX` again with new bounds). Clamps are applied at [build](#build)
time, so they affect every value declared in the pipeline regardless of order.
If `min > max` the arguments are swapped automatically. The active unit
(percent or px) on each value is preserved.

-}
clampX : Float -> Float -> Builder mode -> Builder mode
clampX =
    PB.clampX


{-| Constrain the Y axis of the active animGroup's perspective-origin to
`[min, max]`.

See [clampX](#clampX) for behaviour.

-}
clampY : Float -> Float -> Builder mode -> Builder mode
clampY =
    PB.clampY


{-| Remove a previously declared X axis clamp on the active animGroup. No-op
if no clamp is set.
-}
unclampX : Builder mode -> Builder mode
unclampX =
    PB.unclampX


{-| Remove a previously declared Y axis clamp on the active animGroup. No-op
if no clamp is set.
-}
unclampY : Builder mode -> Builder mode
unclampY =
    PB.unclampY



-- ============================================================
-- RESIZE
-- ============================================================


{-| Set the perspective-origin resize policy for an anim group.

Call this once at init time. Later, when `PerspectiveOrigin.bounds` is used,
the engine applies these rules to in-flight perspective-origin animation.

If you do not set a policy, perspective-origin uses
[`Resize.proportional`](Anim-Resize#proportional).

-}
resizePolicy : AnimGroupName -> Resize.Policy -> AnimBuilder mode -> AnimBuilder mode
resizePolicy groupName policy =
    Builder.setPropertyResizePolicy groupName "perspectiveOrigin" (toInternalResizePolicy policy)


toInternalResizePolicy : Resize.Policy -> ResizeBuilder.Policy
toInternalResizePolicy p =
    { range =
        case Resize.range p of
            Resize.Pinned ->
                ResizeBuilder.Pinned

            Resize.Adaptive ->
                ResizeBuilder.Adaptive
    , current =
        case Resize.current p of
            Resize.Fixed ->
                ResizeBuilder.Fixed

            Resize.Relative ->
                ResizeBuilder.Relative
    , timing =
        case Resize.timing p of
            Resize.SolveFromCurrent ->
                ResizeBuilder.SolveFromCurrent

            Resize.PreserveProgress ->
                ResizeBuilder.PreserveProgress
    }


{-| Perspective-origin's contribution to a resize bounds directive for the
named anim group.

Pass this to `WAAPI.onResize` or `Sub.onResize`.

Leave an axis as `Nothing` to ignore it. `z` is ignored for this property.
Set the matching policy first with [`resizePolicy`](#resizePolicy).

-}
bounds : AnimGroupName -> Resize.Bounds -> Resize.Builder -> Resize.Builder
bounds =
    ResizeBuilder.setPerspectiveOrigin
