module Anim.Property.Translate exposing
    ( default
    , init, initXYZ, initXY, initXZ, initX, initYZ, initY, initZ
    , Builder, for, build
    , from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ
    , to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ
    , by, byXYZ, byXY, byXZ, byX, byYZ, byY, byZ
    , delay, duration, speed
    , easing
    )

{-| Translate animation functions with 3D support.

Build animations that move the position of elements along the X, Y, and Z axes.

So if we're moving an element's position, why `Translate` and not something like `Position` for the module name?
In web development, "translate" refers to _moving an element's position_ along the X, Y, and Z axes.
Whereas "position" often refers to the CSS `position` property which controls _how an element is positioned_ in the document flow (like `static`, `relative`, `absolute`, etc.).

    animBuilder
        |> Translate.for "my-element"
        |> Translate.fromXY 100 20
        |> Translate.toY 200
        |> Translate.speed 500
        |> ... -- other translate configuration steps
        |> Translate.build
        |> ... -- continue with animation

For 3D positioning, set a non-zero value for the 'Z' axis and add perspective to the parent container using `Anim.View3D`:

    import Anim.View3D as View3D

    view model =
        div [ id "container", View3D.perspective 1000 ]
            [ animatedElement ]


# Default

@docs default


# Initialize

@docs init, initXYZ, initXY, initXZ, initX, initYZ, initY, initZ


# Build

@docs Builder, for, build


# Configure


## Initial Value

The first time a translate animation is configured, if no initial value is set, the [default](#default) is used.
On subsequent _stateful_ animations, it will start from the last known position, so you only need to set this
when you want to override that behavior.

@docs from, fromXYZ, fromXY, fromXZ, fromX, fromYZ, fromY, fromZ


## Target Value (Absolute)

@docs to, toXYZ, toXY, toXZ, toX, toYZ, toY, toZ


## Target Value (Relative)

Move by a specific amount relative to the start position.

@docs by, byXYZ, byXY, byXZ, byX, byYZ, byY, byZ


## Timing

@docs delay, duration, speed


## Easing

@docs easing

-}

import Anim.Easing exposing (Easing)
import Anim.Internal.Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Translate as TB
import Anim.Internal.Properties.Translate as T


{-| The default translate value used when no initial value is specified:

`{ x = 0, y = 0, z = 0 }` (no translation).

-}
default : { x : Float, y : Float, z : Float }
default =
    { x = 0, y = 0, z = 0 }


{-| Type alias for the internal `TranslateBuilder`.
-}
type alias Builder =
    TB.TranslateBuilder


{-| Turn the `AnimBuilder` into a translate animation `Builder` for the specified element.

From here, you can continue configuring the translate animation, then call [build](#build) to turn
the `Builder` back into an `AnimBuilder` and then either continue configuring other property animations or
animate it with the Engine.

    animBuilder
        |> Translate.for "my-element"
        |> ... -- continue with translate configuration

-}
for : String -> AnimBuilder -> Builder
for =
    TB.for


{-| Set the initial position.

Use this to initialize the position in your `init` function.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    Engine.init
        |> Engine.builder
        |> Translate.init "element-id" 100
        |> ... -- continue setting initial values
        |> Engine.animate

This is equivalent to calling `initXYZ 100 100 100`.

-}
init : String -> Float -> AnimBuilder -> AnimBuilder
init elementId value animBuilder =
    animBuilder
        |> TB.for elementId
        |> from value
        |> to value
        |> TB.build


{-| Set the initial X, Y, and Z position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    Engine.init
        |> Engine.builder
        |> Translate.initXYZ "element-id" 100 20 50
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initXYZ : String -> Float -> Float -> Float -> AnimBuilder -> AnimBuilder
initXYZ elementId x y z animBuilder =
    animBuilder
        |> TB.for elementId
        |> fromXYZ x y z
        |> TB.toXYZ x y z
        |> TB.build


{-| Set the initial X and Y position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    Engine.init
        |> Engine.builder
        |> Translate.initXY "element-id" 100 20
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initXY : String -> Float -> Float -> AnimBuilder -> AnimBuilder
initXY elementId x y animBuilder =
    animBuilder
        |> TB.for elementId
        |> fromXY x y
        |> TB.toXY x y
        |> TB.build


{-| Set the initial X and Z position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    Engine.init
        |> Engine.builder
        |> Translate.initXZ "element-id" 100 50
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initXZ : String -> Float -> Float -> AnimBuilder -> AnimBuilder
initXZ elementId x z animBuilder =
    animBuilder
        |> TB.for elementId
        |> fromXZ x z
        |> TB.toXZ x z
        |> TB.build


{-| Set the initial X position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    Engine.init
        |> Engine.builder
        |> Translate.initX "element-id" 100
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initX : String -> Float -> AnimBuilder -> AnimBuilder
initX elementId x animBuilder =
    animBuilder
        |> TB.for elementId
        |> fromX x
        |> TB.toX x
        |> TB.build


{-| Set the initial Y and Z position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    Engine.init
        |> Engine.builder
        |> Translate.initYZ "element-id" 20 50
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initYZ : String -> Float -> Float -> AnimBuilder -> AnimBuilder
initYZ elementId y z animBuilder =
    animBuilder
        |> TB.for elementId
        |> fromYZ y z
        |> TB.toYZ y z
        |> TB.build


{-| Set the initial Y position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    Engine.init
        |> Engine.builder
        |> Translate.initY "element-id" 20
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initY : String -> Float -> AnimBuilder -> AnimBuilder
initY elementId y animBuilder =
    animBuilder
        |> TB.for elementId
        |> fromY y
        |> TB.toY y
        |> TB.build


{-| Set the initial Z position.

    import Anim.Engine.* as Engine
    import Anim.Property.Translate as Translate

    Engine.init
        |> Engine.builder
        |> Translate.initZ "element-id" 50
        |> ... -- continue setting initial values
        |> Engine.animate

-}
initZ : String -> Float -> AnimBuilder -> AnimBuilder
initZ elementId z animBuilder =
    animBuilder
        |> TB.for elementId
        |> fromZ z
        |> TB.toZ z
        |> TB.build


{-| Complete the [Builder](#Builder) animation configuration and return an `AnimBuilder`
so you can continue with the animation.

    animBuilder
        |> Translate.for "my-element"
        |> ... -- Translate configuration steps
        |> Translate.build
        |> ... -- continue with animation or execute

-}
build : Builder -> AnimBuilder
build =
    TB.build


{-| Set the uniform starting position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.from 100
        |> ...

This is equivalent to calling `fromXYZ 100 100 100`.

-}
from : Float -> Builder -> Builder
from =
    TB.from << T.fromTriple << (\v -> ( v, v, v ))


{-| Set the starting X, Y, and Z position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.fromXYZ 100 20 50
        |> ...

-}
fromXYZ : Float -> Float -> Float -> Builder -> Builder
fromXYZ =
    TB.fromXYZ


{-| Set the starting position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.fromXY 100 20
        |> ...

The Z position remains unchanged, or zero if not set.

-}
fromXY : Float -> Float -> Builder -> Builder
fromXY =
    TB.fromXY


{-| Set the starting X and Z position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.fromXZ 100 50
        |> ...

The Y position remains unchanged, or zero if not set.

-}
fromXZ : Float -> Float -> Builder -> Builder
fromXZ =
    TB.fromXZ


{-| Set the starting X position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.fromX 100
        |> ...

The Y and Z positions remain unchanged, or zero if not set.

-}
fromX : Float -> Builder -> Builder
fromX =
    TB.fromX


{-| Set the starting Y and Z position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.fromYZ 200 50
        |> ...

The X position remains unchanged, or zero if not set.

-}
fromYZ : Float -> Float -> Builder -> Builder
fromYZ =
    TB.fromYZ


{-| Set the starting Y position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.fromY 50
        |> ...

The X and Z positions remain unchanged, or zero if not set.

-}
fromY : Float -> Builder -> Builder
fromY =
    TB.fromY


{-| Set the starting Z position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.fromZ 75
        |> ...

The X and Y positions remain unchanged, or zero if not set.

-}
fromZ : Float -> Builder -> Builder
fromZ =
    TB.fromZ


{-| Set the target uniform position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.to 100
        |> ...

This is equivalent to calling `toXYZ 100 100 100`.

-}
to : Float -> Builder -> Builder
to =
    TB.to << T.fromTriple << (\v -> ( v, v, v ))


{-| Set the target X, Y, and Z position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.toXYZ 100 200 50
        |> ...

-}
toXYZ : Float -> Float -> Float -> Builder -> Builder
toXYZ =
    TB.toXYZ


{-| Set the target X and Y position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.toXY 100 200
        |> ...

The Z position remains unchanged, or zero if not set.

-}
toXY : Float -> Float -> Builder -> Builder
toXY =
    TB.toXY


{-| Set the target X and Z position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.toXZ 100 50
        |> ...

The Y position remains unchanged, or zero if not set.

-}
toXZ : Float -> Float -> Builder -> Builder
toXZ =
    TB.toXZ


{-| Set the target X position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.toX 150
        |> ...

The Y and Z positions remain unchanged, or zero if not set.

-}
toX : Float -> Builder -> Builder
toX =
    TB.toX


{-| Set the target Y and Z position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.toYZ 200 75
        |> ...

The X position remains unchanged, or zero if not set.

-}
toYZ : Float -> Float -> Builder -> Builder
toYZ =
    TB.toYZ


{-| Set the target Y position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.toY 250
        |> ...

The X and Z positions remain unchanged, or zero if not set.

-}
toY : Float -> Builder -> Builder
toY =
    TB.toY


{-| Set the target Z position for the current element.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.toZ 75
        |> ...

The X and Y positions remain unchanged, or zero if not set.

-}
toZ : Float -> Builder -> Builder
toZ =
    TB.toZ


{-| The speed represents how many pixels the element moves per second.

For example, lets take a translate animation from `(0, 0)` to `(100, 0)`.
A speed of `50.0` means the element will move 50 pixels per second, so our animation will take 2 seconds to complete (0 -> 50 in 1 second, then 50 -> 100 in the next second).

    animBuilder
        |> Translate.for "my-element"
        |> Translate.toY 300
        |> Translate.speed 500
        |> ...

Similarly, a speed of `100.0` would complete the same animation in 1 second, and a speed of `25.0` would take 4 seconds.

-}
speed : Float -> Builder -> Builder
speed =
    TB.speed


{-| Set the animation duration (milliseconds).

    animBuilder
        |> Translate.for "my-element"
        |> Translate.toY 300
        |> Translate.duration 2000
        |> ...

-}
duration : Int -> Builder -> Builder
duration =
    TB.duration


{-| Set the easing function for the animation.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.toY 300
        |> Translate.speed 400
        |> Translate.easing Ease.inOutQuad
        |> ...

-}
easing : Easing -> Builder -> Builder
easing =
    TB.easing


{-| Set the delay (milliseconds) before the animation starts.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.toY 300
        |> Translate.speed 400
        |> Translate.delay 500
        |> ...

-}
delay : Int -> Builder -> Builder
delay =
    TB.delay



-- BY (relative movement)


{-| Move uniformly by a specific amount on all axes.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.by 50
        |> ...

This is equivalent to calling `byXYZ 50 50 50`.

-}
by : Float -> Builder -> Builder
by delta =
    TB.byXYZ delta delta delta


{-| Move by specific amounts on the X, Y, and Z axes.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.fromXY 100 100
        |> Translate.byXYZ 50 -25 10
        |> ...

This would animate from `(100, 100, 0)` to `(150, 75, 10)`.

-}
byXYZ : Float -> Float -> Float -> Builder -> Builder
byXYZ =
    TB.byXYZ


{-| Move by specific amounts on the X and Y axes.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.fromXY 100 100
        |> Translate.byXY 50 -25
        |> ...

This would animate from `(100, 100)` to `(150, 75)`.

-}
byXY : Float -> Float -> Builder -> Builder
byXY =
    TB.byXY


{-| Move by specific amounts on the X and Z axes.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.byXZ 50 10
        |> ...

-}
byXZ : Float -> Float -> Builder -> Builder
byXZ =
    TB.byXZ


{-| Move by a specific amount on the X axis.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.fromX 100
        |> Translate.byX 50
        |> ...

This would animate from `100` to `150` on the X axis.

-}
byX : Float -> Builder -> Builder
byX =
    TB.byX


{-| Move by specific amounts on the Y and Z axes.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.byYZ -25 10
        |> ...

-}
byYZ : Float -> Float -> Builder -> Builder
byYZ =
    TB.byYZ


{-| Move by a specific amount on the Y axis.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.fromY 100
        |> Translate.byY -50
        |> ...

This would animate from `100` to `50` on the Y axis.

-}
byY : Float -> Builder -> Builder
byY =
    TB.byY


{-| Move by a specific amount on the Z axis.

    animBuilder
        |> Translate.for "my-element"
        |> Translate.fromZ 0
        |> Translate.byZ 100
        |> ...

This would animate from `0` to `100` on the Z axis.

-}
byZ : Float -> Builder -> Builder
byZ =
    TB.byZ
