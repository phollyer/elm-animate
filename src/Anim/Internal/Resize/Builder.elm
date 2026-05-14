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
                    if isLooping then
                        { start = legStart
                        , end = legEnd
                        , current = clamp b.min b.max currentV
                        }

                    else
                        { start = clamp b.min b.max currentV
                        , end = clamp b.min b.max endV
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
                            if oldRange == 0 then
                                -- The previous resize collapsed start == end
                                -- (e.g. a one-shot animation finished and was
                                -- then resized so start was set to current).
                                -- There is no proportional position left to
                                -- preserve, so keep `currentV` and just clamp
                                -- it into the new bounds. Snapping to `b.min`
                                -- would teleport a settled box back to the
                                -- start of the track on every subsequent
                                -- resize.
                                clamp b.min b.max currentV

                            else
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
