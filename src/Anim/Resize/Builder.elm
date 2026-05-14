module Anim.Resize.Builder exposing (Builder, onResize)

{-| Composable container of per-property resize directives passed to a
WAAPI / Sub engine's `onResize` function.

`Builder` is opaque: callers construct it by piping per-property
`onResize` functions exposed from property modules (e.g.
[`Anim.Property.Translate.onResize`](Anim-Property-Translate#onResize)),
or by setting a per-group group-wide default with [`onResize`](#onResize),
then hand the composed transformer to an engine:

    WAAPI.onResize model.animState <|
        Resize.Builder.onResize "box" Resize.Proportional
            { x = Just { min = 0, max = w }, y = Nothing, z = Nothing }

A single builder can carry directives for many anim groups at once -
each call records its directive against the supplied anim group name.
Per-property entries override the group-wide default for that property
on the same group, so the two can be combined for fine-grained control:

    WAAPI.onResize model.animState <|
        Resize.Builder.onResize "box" Resize.Proportional bounds
            >> Translate.onResize "box" Resize.Clamp translateBounds
            >> Resize.Builder.onResize "card" Resize.Proportional cardBounds

@docs Builder, onResize

-}

import Anim.Internal.Resize.Builder as Internal
import Anim.Resize as Resize


{-| Opaque accumulator. Build with property-module `onResize` functions
and / or [`onResize`](#onResize) for per-group group-wide defaults.
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
onResize : Internal.AnimGroupName -> Resize.Strategy -> Resize.Bounds -> Builder -> Builder
onResize =
    Internal.setDefault
