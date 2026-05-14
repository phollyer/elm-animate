module Anim.Resize exposing
    ( Strategy(..), AxisBounds, Bounds
    , Builder, onResize
    )

{-| Shared types and builder for describing how an in-flight animation
should adapt when its container's bounds change.

Property modules (e.g. [`Anim.Property.Translate`](Anim-Property-Translate))
expose `onResize` builders that consume these types, and the engines
([`Anim.Engine.WAAPI`](Anim-Engine-WAAPI),
[`Anim.Engine.Sub`](Anim-Engine-Sub)) accept a composed
[`Builder`](#Builder) of those entries.


# Types

@docs Strategy, AxisBounds, Bounds


# Builder

@docs Builder, onResize

-}

import Anim.Internal.Resize.Builder as Internal


{-| How a resize should reposition in-flight animation values when the
bounding range changes.

  - `Proportional` preserves normalized progress within the old/new bounds.
    A box halfway across the track stays halfway across the track. Best for
    looping/ping-pong animations where you want the rhythm preserved.
  - `Clamp` keeps the current animated value as-is and re-clamps it (and
    the target) into the new bounds. Best for one-shot animations where
    you only want the new range to act as a wall.

-}
type Strategy
    = Proportional
    | Clamp


{-| Inclusive numeric range for a single axis.
-}
type alias AxisBounds =
    { min : Float, max : Float }


{-| Per-axis bounds describing the new container size. An axis left as
`Nothing` is untouched.

    { x = Just { min = 0, max = newWidth - boxSize }
    , y = Nothing
    , z = Nothing
    }

-}
type alias Bounds =
    { x : Maybe AxisBounds
    , y : Maybe AxisBounds
    , z : Maybe AxisBounds
    }


{-| Composable container of per-property resize directives passed to a
WAAPI / Sub engine's `onResize` function.

`Builder` is opaque: callers construct it by piping per-property
`onResize` functions exposed from property modules (e.g.
[`Anim.Property.Translate.onResize`](Anim-Property-Translate#onResize)),
or by setting a per-group group-wide default with [`onResize`](#onResize),
then hand the composed transformer to an engine:

    WAAPI.onResize model.animState <|
        Resize.onResize "box"
            Resize.Proportional
            { x = Just { min = 0, max = w }, y = Nothing, z = Nothing }

A single builder can carry directives for many anim groups at once -
each call records its directive against the supplied anim group name.
Per-property entries override the group-wide default for that property
on the same group, so the two can be combined for fine-grained control:

    WAAPI.onResize model.animState <|
        Resize.onResize "box" Resize.Proportional bounds
            >> Translate.onResize "box" Resize.Clamp translateBounds
            >> Resize.onResize "card" Resize.Proportional cardBounds

-}
type alias Builder =
    Internal.Builder


{-| Set a group-wide resize directive that applies to every supported
property in the named anim group. Per-property `onResize` calls (e.g.
[`Translate.onResize`](Anim-Property-Translate#onResize)) override this
default for that property on the same group.

Use this when every supported property in the group should react to the
same container resize with the same strategy and bounds - which is the
common case when an animation is scoped to a single container.

-}
onResize : Internal.AnimGroupName -> Strategy -> Bounds -> Builder -> Builder
onResize =
    Internal.setDefault toStrategy


toStrategy : Strategy -> Internal.Strategy
toStrategy strategy =
    case strategy of
        Proportional ->
            Internal.Proportional

        Clamp ->
            Internal.Clamp
