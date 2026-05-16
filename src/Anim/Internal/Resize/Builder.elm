module Anim.Internal.Resize.Builder exposing
    ( AnimGroupName
    , AxisBounds
    , AxisResult
    , Bounds
    , Builder
    , Entry
    , Strategy(..)
    , applyAxis
    , build
    , empty
    , getScale
    , getTranslate
    , groups
    , isEmpty
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

import Dict exposing (Dict)


type Strategy
    = Proportional
    | Clamp
    | Retarget


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
setDefault : (a -> Strategy) -> AnimGroupName -> a -> Bounds -> Builder -> Builder
setDefault toStrategy name value bounds (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\e -> { e | default = Just { strategy = toStrategy value, bounds = bounds } }))
            d
        )


{-| Record a translate-axis resize directive for the given anim group.
-}
setTranslate : (a -> Strategy) -> AnimGroupName -> a -> Bounds -> Builder -> Builder
setTranslate toStrategy name value bounds (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\e -> { e | translate = Just { strategy = toStrategy value, bounds = bounds } }))
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
setScale : (a -> Strategy) -> AnimGroupName -> a -> Bounds -> Builder -> Builder
setScale toStrategy name value bounds (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\e -> { e | scale = Just { strategy = toStrategy value, bounds = bounds } }))
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



-- ============================================================
-- AXIS MATH
-- ============================================================


{-| Per-axis result of resizing one axis.

  - `start` / `end` are the new extremes for the current leg (so the engine's
    alternate-swap on iteration boundary continues to work for looping anims).
  - `current` is the new visual value the box should snap to.

-}
type alias AxisResult =
    { start : Float
    , end : Float
    , current : Float
    }


{-| Convenience predicate: a resize directive with no populated axes is
treated as a no-op by engines.
-}
isEmpty : Bounds -> Bool
isEmpty bounds =
    bounds.x == Nothing && bounds.y == Nothing && bounds.z == Nothing


{-| Compute new per-axis start / end / current.

`Nothing` bounds = leave axis untouched.

`isLooping` controls whether the result preserves full extremes (so that
ping-pong continues to span the full new range) or shrinks to a single
leg (one-shot animations finish at the new target).

-}
applyAxis :
    Strategy
    -> Bool
    -> Maybe AxisBounds
    -> Float
    -> Float
    -> Float
    -> AxisResult
applyAxis strategy isLooping maybeBounds startV endV currentV =
    case maybeBounds of
        Nothing ->
            { start = startV, end = endV, current = currentV }

        Just b ->
            if startV == endV then
                -- Degenerate input leg (no motion to rescale - e.g. an
                -- init-only property whose synthesized baseline has
                -- start == end). Snapping `start`/`end` to the bounds
                -- here would fabricate a leg from `b.min` to `b.max`,
                -- which the WAAPI JS bridge then bakes into the running
                -- transform's keyframes for that sub-property and
                -- stretches the value across the whole track on the
                -- next animation frame (e.g. a default-bounds group
                -- resize would corrupt an init-only Scale of `1` into a
                -- `0 -> trackWidth` ramp regardless of strategy or
                -- looping). Keep the leg degenerate so the engine's
                -- `noChange` guard skips emitting a resize command for
                -- the property that has no real animation.
                let
                    clamped =
                        clamp b.min b.max currentV
                in
                { start = clamped, end = clamped, current = clamped }

            else
                let
                    forward =
                        startV <= endV

                    ( legStart, legEnd ) =
                        if forward then
                            ( b.min, b.max )

                        else
                            ( b.max, b.min )
                in
                case strategy of
                    Clamp ->
                        -- Pure constraint: the user's configured `start`
                        -- and `end` are preserved as the animation's
                        -- intent; the new bounds only act as a clip box.
                        -- Looping and one-shot behave identically here -
                        -- the only role of `isLooping` is in `Retarget`
                        -- and `Proportional` where the leg endpoints
                        -- themselves change.
                        { start = clamp b.min b.max startV
                        , end = clamp b.min b.max endV
                        , current = clamp b.min b.max currentV
                        }

                    Retarget ->
                        -- Bounds drive the leg's endpoints: the animation
                        -- is conceptually defined edge-to-edge (or
                        -- whatever the new track extremes are) and the
                        -- target follows the resize. `current` stays on
                        -- its current pixel (clamped into bounds) so
                        -- there is no visual jump - the proportion of
                        -- the way through the new leg simply changes.
                        if isLooping then
                            { start = legStart
                            , end = legEnd
                            , current = clamp b.min b.max currentV
                            }

                        else
                            { start = clamp b.min b.max currentV
                            , end = legEnd
                            , current = clamp b.min b.max currentV
                            }

                    Proportional ->
                        let
                            oldMin =
                                Basics.min startV endV

                            oldMax =
                                Basics.max startV endV

                            oldRange =
                                oldMax - oldMin

                            newRange =
                                b.max - b.min

                            newCurrent =
                                b.min + ((currentV - oldMin) / oldRange) * newRange
                        in
                        if isLooping then
                            { start = legStart
                            , end = legEnd
                            , current = newCurrent
                            }

                        else
                            { start = newCurrent
                            , end = legEnd
                            , current = newCurrent
                            }
