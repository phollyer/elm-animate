module Anim.Property.Translate exposing
    ( Builder, AnimGroupName
    , initXYZ, initXY, initXZ, initX, initYZ, initY, initZ
    , for, build
    , continueFor
    , fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , byXYZ, byXY, byXZ, byX, byYZ, byY, byZ
    , delay, duration, speed
    , easing
    , spring
    , clampX, clampY, clampZ, unclampX, unclampY, unclampZ
    )

{-| Move elements along the X, Y, and Z axes.

**Default**: 0 for all axes

This property uses a 'sensible default' approach to configuring animations.
When no start value is available for any axis, the default will be used for that axis.

Any axis that is not defined in the animation configuration will remain unchanged,
or zero if not set.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toXY 200 100
            >> Translate.duration 1000
            >> Translate.easing EaseInOut
            >> Translate.build

The Engines track the end value of each animation, so new animations with no start value
will use the current end value as the start, ensuring a smooth transition between animations.


# Types

@docs Builder, AnimGroupName


# Initialize

@docs initXYZ, initXY, initXZ, initX, initYZ, initY, initZ


# Build

@docs for, build


# Continue a Running Animation

@docs continueFor


# Configure


## Start Value

When not set, the engine determines the start value - behaviour
varies by engine and context.

📖 See [Start Values](https://phollyer.github.io/elm-motion/animation/engines/overview/#start-values)
for details.

@docs fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## End Value (Absolute)

@docs toXYZ, toXY, toXZ, toX, toYZ, toY, toZ


## End Value (Relative)

The end value is computed as `current + delta` at build time.

How the **current** position is determined depends on
the engine, the underlying technology being targeted, and the state of the animation:

  - **Sub / WAAPI** — _always accurate_; both track current animated position, even mid-flight.


### Animations that have completed:

  - **Keyframe / Transition** — _always accurate_;
      - uses the current configurations start value if provided
      - otherwise, uses the previous animation's end value
      - otherwise, the default value (0 for translate) applies


### Animations that are in-flight:

CSS Keyframe and Transition do not track the current position of the animation mid-flight,
so relative movements are based on the start and end values of the current/previous configuration:

  - **Keyframe/Transition** — _not accurate_;
      - uses the start value of the current configuration if it exists
      - otherwise, uses the in-flight end value
      - otherwise, the default value (0 for translate) applies

@docs byXYZ, byXY, byXZ, byX, byYZ, byY, byZ


## Timing

@docs delay, duration, speed


## Easing

@docs easing


## Spring

@docs spring


## Bounds

Declare a per-axis range that every translate value on this animGroup must
stay within. Clamps are persistent across `animate` / `retarget` calls until
you clear them, and apply to every value that flows through the property
pipeline — explicit `from*` / `to*`, relative `by*`, and the auto-from value
used by `continueFor` / `retarget`.

A value outside the range snaps to the nearest boundary. A relative `byX`
that would push the element past the boundary stops at the boundary instead
— useful for keeping a player ship on-screen, or making sure a resize from
landscape to portrait pulls a now-off-canvas element back into view.

@docs clampX, clampY, clampZ, unclampX, unclampY, unclampZ

-}

import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Translate as TB
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| Type alias for the animation group name.
-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `TranslateBuilder`.
-}
type alias Builder mode =
    TB.TranslateBuilder mode



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Turn the `AnimBuilder` into a translate animation `Builder` for the specified animation group.

Use this to start configuring a translate animation.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> ... -- Configure and build the animation

-}
for : AnimGroupName -> AnimBuilder mode -> Builder mode
for =
    TB.for


{-| Like [for](#for), but inherits `easing`, `spring`, `delay`, and timing
(`duration` / `speed`) from the previous translate animation on the same
animation group.

Use this when the surrounding world changed (e.g. window resize, parent
relayout) and the animation should continue toward an updated target while
keeping the same visual character.

    -- on resize:
    Translate.continueFor "box"
        >> Translate.toX newTargetX
        >> Translate.build

Any of the four inherited fields can still be overridden by setting them
explicitly after `continueFor`:

    Translate.continueFor "box"
        >> Translate.toX newTargetX
        >> Translate.speed 200
        -- override inherited timing
        >> Translate.build

If no previous translate animation exists for the group, `continueFor`
behaves exactly like `for`.

-}
continueFor : AnimGroupName -> AnimBuilder mode -> Builder mode
continueFor =
    TB.forContinuing


{-| Set the initial X, Y, and Z position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { animState = Engine.init [ Translate.initXYZ "animGroupName" 100 20 50 ] }
        , Cmd.none
        )

-}
initXYZ : AnimGroupName -> Float -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
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
initXY : AnimGroupName -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
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
initXZ : AnimGroupName -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
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
initX : AnimGroupName -> Float -> AnimBuilder mode -> AnimBuilder mode
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
initYZ : AnimGroupName -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
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
initY : AnimGroupName -> Float -> AnimBuilder mode -> AnimBuilder mode
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
initZ : AnimGroupName -> Float -> AnimBuilder mode -> AnimBuilder mode
initZ animationKey z animBuilder =
    animBuilder
        |> TB.for animationKey
        |> fromZ z
        |> TB.toZ z
        |> TB.build



-- ============================================================
-- BUILD
-- ============================================================


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue configuring other property animations or execute the animation with an Engine.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> ... -- configure the animation with from, to, duration, easing, etc.
            >> Translate.build
            >> ... -- continue with animation

-}
build : Builder mode -> AnimBuilder mode
build =
    TB.build



-- ============================================================
-- FROM
-- ============================================================


{-| Set the starting X, Y, and Z position.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXYZ 100 20 50
            >> ... -- continue with animation

-}
fromXYZ : Float -> Float -> Float -> Builder mode -> Builder mode
fromXYZ =
    TB.fromXYZ


{-| Set the starting X and Y position.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXY 100 20
            >> ... -- continue with animation

The Z position remains unchanged, or zero if not set.

-}
fromXY : Float -> Float -> Builder mode -> Builder mode
fromXY =
    TB.fromXY


{-| Set the starting X and Z position.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXZ 100 50
            >> ... -- continue with animation

The Y position remains unchanged, or zero if not set.

-}
fromXZ : Float -> Float -> Builder mode -> Builder mode
fromXZ =
    TB.fromXZ


{-| Set the starting X position.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromX 100
            >> ... -- continue with animation

The Y and Z positions remain unchanged, or zero if not set.

-}
fromX : Float -> Builder mode -> Builder mode
fromX =
    TB.fromX


{-| Set the starting Y and Z position.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromYZ 200 50
            >> ... -- continue with animation

The X position remains unchanged, or zero if not set.

-}
fromYZ : Float -> Float -> Builder mode -> Builder mode
fromYZ =
    TB.fromYZ


{-| Set the starting Y position.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromY 50
            >> ... -- continue with animation

The X and Z positions remain unchanged, or zero if not set.

-}
fromY : Float -> Builder mode -> Builder mode
fromY =
    TB.fromY


{-| Set the starting Z position.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromZ 75
            >> ... -- continue with animation

The X and Y positions remain unchanged, or zero if not set.

-}
fromZ : Float -> Builder mode -> Builder mode
fromZ =
    TB.fromZ



-- ============================================================
-- TO
-- ============================================================


{-| Set the target X, Y, and Z position for the current animation group.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toXYZ 100 200 50
            >> ... -- continue with animation

-}
toXYZ : Float -> Float -> Float -> Builder mode -> Builder mode
toXYZ =
    TB.toXYZ


{-| Set the target X and Y position for the current animation group.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toXY 100 200
            >> ... -- continue with animation

The Z position remains unchanged, or zero if not set.

-}
toXY : Float -> Float -> Builder mode -> Builder mode
toXY =
    TB.toXY


{-| Set the target X and Z position for the current animation group.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toXZ 100 50
            >> ... -- continue with animation

The Y position remains unchanged, or zero if not set.

-}
toXZ : Float -> Float -> Builder mode -> Builder mode
toXZ =
    TB.toXZ


{-| Set the target X position for the current animation group.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toX 150
            >> ... -- continue with animation

The Y and Z positions remain unchanged, or zero if not set.

-}
toX : Float -> Builder mode -> Builder mode
toX =
    TB.toX


{-| Set the target Y and Z position for the current animation group.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toYZ 200 75
            >> ... -- continue with animation

The X position remains unchanged, or zero if not set.

-}
toYZ : Float -> Float -> Builder mode -> Builder mode
toYZ =
    TB.toYZ


{-| Set the target Y position for the current animation group.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toY 250
            >> ... -- continue with animation

The X and Z positions remain unchanged, or zero if not set.

-}
toY : Float -> Builder mode -> Builder mode
toY =
    TB.toY


{-| Set the target Z position for the current animation group.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toZ 75
            >> ... -- continue with animation

The X and Y positions remain unchanged, or zero if not set.

-}
toZ : Float -> Builder mode -> Builder mode
toZ =
    TB.toZ



-- ============================================================
-- TIMING
-- ============================================================


{-| The speed represents how many pixels the element moves per second.

For example, lets take a translate animation from `(0, 0)` to `(100, 0)`.
A speed of `50.0` means the element will move 50 pixels per second, so our animation will take 2 seconds to complete (0 -> 50 in 1 second, then 50 -> 100 in the next second).

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toX 100
            >> Translate.speed 50
            >> ... -- continue with animation

Similarly, a speed of `100.0` would complete the same animation in 1 second, and a speed of `25.0` would take 4 seconds.

-}
speed : Float -> Builder mode -> Builder mode
speed =
    TB.speed


{-| Set the animation duration (milliseconds).

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toY 300
            >> Translate.duration 2000
            >> ... -- continue with animation

-}
duration : Int -> Builder mode -> Builder mode
duration =
    TB.duration


{-| Set the easing function for the animation.

    import Easing exposing (Easing(..))

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toY 300
            >> Translate.easing EaseInOut
            >> ... -- continue with animation

-}
easing : Easing -> Builder mode -> Builder mode
easing =
    TB.easing



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
        Translate.for "animGroupName"
            >> Translate.toY 300
            >> Translate.spring Spring.wobbly

-}
spring : Spring -> Builder mode -> Builder mode
spring =
    TB.spring


{-| Set the delay (milliseconds) before the animation starts.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.toY 300
            >> Translate.delay 500
            >> ... -- continue with animation

-}
delay : Int -> Builder mode -> Builder mode
delay =
    TB.delay



-- ============================================================
-- BY
-- ============================================================


{-| Move by specific amounts on the X, Y, and Z axes.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXY 100 100
            >> Translate.byXYZ 50 -25 10
            >> ... -- continue with animation

This would animate from `(100, 100, 0)` to `(150, 75, 10)`.

-}
byXYZ : Float -> Float -> Float -> Builder mode -> Builder mode
byXYZ =
    TB.byXYZ


{-| Move by specific amounts on the X and Y axes.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromXY 100 100
            >> Translate.byXY 50 -25
            >> ... -- continue with animation

This would animate from `(100, 100)` to `(150, 75)`.

-}
byXY : Float -> Float -> Builder mode -> Builder mode
byXY =
    TB.byXY


{-| Move by specific amounts on the X and Z axes.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.byXZ 50 10
            >> ... -- continue with animation

-}
byXZ : Float -> Float -> Builder mode -> Builder mode
byXZ =
    TB.byXZ


{-| Move by a specific amount on the X axis.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromX 100
            >> Translate.byX 50
            >> ... -- continue with animation

This would animate from `100` to `150` on the X axis.

-}
byX : Float -> Builder mode -> Builder mode
byX =
    TB.byX


{-| Move by specific amounts on the Y and Z axes.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.byYZ -25 10
            >> ... -- continue with animation

-}
byYZ : Float -> Float -> Builder mode -> Builder mode
byYZ =
    TB.byYZ


{-| Move by a specific amount on the Y axis.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromY 100
            >> Translate.byY -50
            >> ... -- continue with animation

This would animate from `100` to `50` on the Y axis.

-}
byY : Float -> Builder mode -> Builder mode
byY =
    TB.byY


{-| Move by a specific amount on the Z axis.

    myAnimation : AnimBuilder mode -> AnimBuilder mode
    myAnimation =
        Translate.for "animGroupName"
            >> Translate.fromZ 0
            >> Translate.byZ 100
            >> ... -- continue with animation

This would animate from `0` to `100` on the Z axis.

-}
byZ : Float -> Builder mode -> Builder mode
byZ =
    TB.byZ



-- ============================================================
-- BOUNDS
-- ============================================================


{-| Constrain the X axis of the named animGroup's translate to `[min, max]`.

The clamp is persistent: once declared it applies to every subsequent
`animate` / `retarget` call on this animGroup until you call [unclampX](#unclampX)
(or call `clampX` again with new bounds). It is enforced at build time on
every value that flows through the pipeline \\u2014 explicit `fromX` / `toX`,
relative `byX`, and the auto-from value used by `continueFor` / `retarget`.

A typical use is the resize handler on a fluid layout, declaring the
playfield bounds whenever the canvas size changes:

    update msg model =
        case msg of
            GotCanvas (Ok element) ->
                let
                    w =
                        element.element.width

                    h =
                        element.element.height
                in
                ( { model | canvasW = w, canvasH = h }
                , WAAPI.retarget model.animState
                    (Translate.clampX animGroupName 0 (w - boxWidth)
                        >> Translate.clampY animGroupName 0 (h - boxWidth)
                        >> Translate.continueFor animGroupName
                        >> Translate.toXY (targetX model.xPos w) (targetY h)
                        >> Translate.build
                    )
                )

If `min > max` the arguments are swapped automatically.

-}
clampX : AnimGroupName -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
clampX =
    Anim.Internal.Builder.setTranslateClampX


{-| Constrain the Y axis of the named animGroup's translate to `[min, max]`.

See [clampX](#clampX) for behaviour and example.

-}
clampY : AnimGroupName -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
clampY =
    Anim.Internal.Builder.setTranslateClampY


{-| Constrain the Z axis of the named animGroup's translate to `[min, max]`.

See [clampX](#clampX) for behaviour and example.

-}
clampZ : AnimGroupName -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
clampZ =
    Anim.Internal.Builder.setTranslateClampZ


{-| Remove a previously declared X axis clamp on the named animGroup. No-op
if no clamp is set.
-}
unclampX : AnimGroupName -> AnimBuilder mode -> AnimBuilder mode
unclampX =
    Anim.Internal.Builder.clearTranslateClampX


{-| Remove a previously declared Y axis clamp on the named animGroup. No-op
if no clamp is set.
-}
unclampY : AnimGroupName -> AnimBuilder mode -> AnimBuilder mode
unclampY =
    Anim.Internal.Builder.clearTranslateClampY


{-| Remove a previously declared Z axis clamp on the named animGroup. No-op
if no clamp is set.
-}
unclampZ : AnimGroupName -> AnimBuilder mode -> AnimBuilder mode
unclampZ =
    Anim.Internal.Builder.clearTranslateClampZ
