module Anim.Internal.Resize.Builder exposing
    ( Builder
    , Entry
    , build
    , empty
    , getScale
    , getTranslate
    , setDefault
    , setScale
    , setTranslate
    )

{-| Internal accumulator used by `Anim.Resize.Builder.Builder` (the public
opaque alias) and consumed by engine `onResize` functions.

A `Builder` is constructed by composing per-property `onResize` functions
exposed from property modules - e.g.

    Translate.onResize Resize.Proportional bounds

A group-wide default may also be supplied via
[`Anim.Resize.Builder.onResize`](Anim-Resize-Builder#onResize); engines
fall back to it whenever a property has no explicit directive. Each
entry records the target property's strategy and per-axis bounds.

-}

import Anim.Resize exposing (Bounds, Strategy)


{-| One pending resize directive for a single property (or the group default).
-}
type alias Entry =
    { strategy : Strategy
    , bounds : Bounds
    }


{-| Opaque accumulator. New properties are added by extending the record
and providing matching `setX` / `getX` helpers.

`default` is the group-wide fallback applied to any supported property
that has no explicit per-property entry.

-}
type Builder
    = Builder
        { default : Maybe Entry
        , translate : Maybe Entry
        , scale : Maybe Entry
        }


{-| Empty builder with no resize directives.
-}
empty : Builder
empty =
    Builder { default = Nothing, translate = Nothing, scale = Nothing }


{-| Apply a builder transformer (composed property `onResize` calls) to
the empty builder.
-}
build : (Builder -> Builder) -> Builder
build fn =
    fn empty


{-| Record the group-wide default directive used as a fallback for any
property that has no explicit entry.
-}
setDefault : Strategy -> Bounds -> Builder -> Builder
setDefault strategy bounds (Builder b) =
    Builder { b | default = Just { strategy = strategy, bounds = bounds } }


{-| Record a translate-axis resize directive.
-}
setTranslate : Strategy -> Bounds -> Builder -> Builder
setTranslate strategy bounds (Builder b) =
    Builder { b | translate = Just { strategy = strategy, bounds = bounds } }


{-| Read the effective translate directive: the explicit per-property
entry if present, otherwise the group-wide default.
-}
getTranslate : Builder -> Maybe Entry
getTranslate (Builder b) =
    case b.translate of
        Just _ ->
            b.translate

        Nothing ->
            b.default


{-| Record a scale-axis resize directive.
-}
setScale : Strategy -> Bounds -> Builder -> Builder
setScale strategy bounds (Builder b) =
    Builder { b | scale = Just { strategy = strategy, bounds = bounds } }


{-| Read the effective scale directive: the explicit per-property entry
if present, otherwise the group-wide default.
-}
getScale : Builder -> Maybe Entry
getScale (Builder b) =
    case b.scale of
        Just _ ->
            b.scale

        Nothing ->
            b.default
