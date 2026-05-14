module Anim.Internal.Resize.Builder exposing
    ( AnimGroupName
    , Builder
    , Entry
    , build
    , empty
    , getScale
    , getTranslate
    , groups
    , setDefault
    , setScale
    , setTranslate
    )

{-| Internal accumulator used by `Anim.Resize.Builder.Builder` (the public
opaque alias) and consumed by engine `onResize` functions.

A `Builder` is constructed by composing per-property `onResize` functions
exposed from property modules - e.g.

    Translate.onResize "box" Resize.Proportional bounds

Each call records a directive against a specific anim group, so a single
builder can target many groups at once. Per-group group-wide defaults
may also be supplied via [`Anim.Resize.Builder.onResize`](Anim-Resize-Builder#onResize);
engines fall back to a group's default whenever a property has no
explicit per-property entry for that group.

-}

import Anim.Resize exposing (Bounds, Strategy)
import Dict exposing (Dict)


{-| The name of an anim group a directive targets.
-}
type alias AnimGroupName =
    String


{-| One pending resize directive for a single property (or the group default).
-}
type alias Entry =
    { strategy : Strategy
    , bounds : Bounds
    }


{-| Per-group accumulator. Adding a new supported property means
extending this record and providing matching `setX` / `getX` helpers.

`default` is the group-wide fallback applied to any supported property
on this group that has no explicit per-property entry.

-}
type alias GroupEntries =
    { default : Maybe Entry
    , translate : Maybe Entry
    , scale : Maybe Entry
    }


{-| Opaque accumulator. Indexed by anim group name so a single builder
can carry directives for many groups in one engine `onResize` call.
-}
type Builder
    = Builder (Dict AnimGroupName GroupEntries)


{-| Empty builder with no resize directives for any group.
-}
empty : Builder
empty =
    Builder Dict.empty


emptyEntries : GroupEntries
emptyEntries =
    { default = Nothing, translate = Nothing, scale = Nothing }


{-| Apply a builder transformer (composed property `onResize` calls) to
the empty builder.
-}
build : (Builder -> Builder) -> Builder
build fn =
    fn empty


updateEntries : (GroupEntries -> GroupEntries) -> Maybe GroupEntries -> Maybe GroupEntries
updateEntries fn maybeEntries =
    Just (fn (Maybe.withDefault emptyEntries maybeEntries))


{-| Record the group-wide default directive used as a fallback for any
property on this group that has no explicit entry.
-}
setDefault : AnimGroupName -> Strategy -> Bounds -> Builder -> Builder
setDefault name strategy bounds (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\e -> { e | default = Just { strategy = strategy, bounds = bounds } }))
            d
        )


{-| Record a translate-axis resize directive for the given anim group.
-}
setTranslate : AnimGroupName -> Strategy -> Bounds -> Builder -> Builder
setTranslate name strategy bounds (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\e -> { e | translate = Just { strategy = strategy, bounds = bounds } }))
            d
        )


{-| Read the effective translate directive for the given anim group: the
explicit per-property entry if present, otherwise the group-wide default.
-}
getTranslate : AnimGroupName -> Builder -> Maybe Entry
getTranslate name (Builder d) =
    Dict.get name d
        |> Maybe.andThen
            (\e ->
                case e.translate of
                    Just _ ->
                        e.translate

                    Nothing ->
                        e.default
            )


{-| Record a scale-axis resize directive for the given anim group.
-}
setScale : AnimGroupName -> Strategy -> Bounds -> Builder -> Builder
setScale name strategy bounds (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\e -> { e | scale = Just { strategy = strategy, bounds = bounds } }))
            d
        )


{-| Read the effective scale directive for the given anim group: the
explicit per-property entry if present, otherwise the group-wide default.
-}
getScale : AnimGroupName -> Builder -> Maybe Entry
getScale name (Builder d) =
    Dict.get name d
        |> Maybe.andThen
            (\e ->
                case e.scale of
                    Just _ ->
                        e.scale

                    Nothing ->
                        e.default
            )


{-| All anim group names that have at least one directive recorded
against them. Engines iterate over this list to apply directives.
-}
groups : Builder -> List AnimGroupName
groups (Builder d) =
    Dict.keys d
