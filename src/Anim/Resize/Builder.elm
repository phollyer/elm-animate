module Anim.Resize.Builder exposing (Builder, onResize)

{-| Composable container of per-property resize directives passed to a
WAAPI / Sub engine's `onResize` function.

`Builder` is opaque: callers construct it by piping per-property
`onResize` functions exposed from property modules (e.g.
[`Anim.Property.Translate.onResize`](Anim-Property-Translate#onResize)),
or by setting a single group-wide default with [`onResize`](#onResize),
then hand the composed transformer to an engine:

    WAAPI.onResize "box" model.animState <|
        Resize.Builder.onResize Resize.Proportional
            { x = Just { min = 0, max = w }, y = Nothing, z = Nothing }

Per-property entries override the group-wide default for that property,
so the two can be combined for fine-grained control:

    WAAPI.onResize "box" model.animState <|
        Resize.Builder.onResize Resize.Proportional bounds
            >> Translate.onResize Resize.Clamp translateBounds

@docs Builder, onResize

-}

import Anim.Internal.Resize.Builder as Internal
import Anim.Resize as Resize


{-| Opaque accumulator. Build with property-module `onResize` functions
and / or [`onResize`](#onResize) for a group-wide default.
-}
type alias Builder =
    Internal.Builder


{-| Set a group-wide resize directive that applies to every supported
property in the group. Per-property `onResize` calls (e.g.
[`Translate.onResize`](Anim-Property-Translate#onResize)) override this
default for that property.

Use this when every supported property in the group should react to the
same container resize with the same strategy and bounds - which is the
common case when an animation is scoped to a single container.

-}
onResize : Resize.Strategy -> Resize.Bounds -> Builder -> Builder
onResize =
    Internal.setDefault
