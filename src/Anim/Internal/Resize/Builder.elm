module Anim.Internal.Resize.Builder exposing
    ( AnimGroupName
    , AxisBounds
    , AxisResult
    , Bounds
    , Builder
    , CurrentPolicy(..)
    , Entry
    , Policy
    , RangePolicy(..)
    , TimingPolicy(..)
    , applyAxis
    , bounds
    , build
    , clampPolicy
    , empty
    , getScale
    , getTranslate
    , groups
    , isEmpty
    , proportionalPolicy
    , retargetPolicy
    , setScale
    , setTranslate
    )

{-| Internal accumulator used by `Anim.Resize.Builder.Builder` (the public
opaque alias) and consumed by engine `onResize` functions.

A `Builder` is constructed by composing per-property `bounds` functions
exposed from property modules - e.g.

    Translate.bounds "box" bounds

Each call records a bounds directive against a specific anim group, so a single
builder can target many groups at once. Per-group group-wide defaults
may also be supplied via [`Anim.Resize.bounds`](Anim-Resize#bounds);
engines look up the resize policy for each property from the `AnimBuilder`'s
persistent state and fall back to `proportionalPolicy` by default.

-}

import Dict exposing (Dict)


{-| Determines whether animation endpoints follow the new bounds or keep their
configured values.
-}
type RangePolicy
    = Pinned
    | Adaptive


{-| Determines how the in-flight current value is repositioned when bounds
change.
-}
type CurrentPolicy
    = Fixed
    | Relative


{-| Determines how the animation's time cursor is updated after a resize.
-}
type TimingPolicy
    = SolveFromCurrent
    | PreserveProgress


{-| Composable resize policy controlling endpoint, current-value, and timing
behaviour independently.

Use the preset helpers (`proportionalPolicy`, `clampPolicy`, `retargetPolicy`)
as a starting point and combine field-level setters for fine-grained control.

-}
type alias Policy =
    { range : RangePolicy
    , current : CurrentPolicy
    , timing : TimingPolicy
    }


{-| Preserve normalised progress: endpoints track the new bounds, current
value is proportionally remapped, and the timing cursor is preserved.
-}
proportionalPolicy : Policy
proportionalPolicy =
    { range = Adaptive
    , current = Relative
    , timing = PreserveProgress
    }


{-| Clamp to new bounds: endpoints stay at their configured values (clipped),
and the current value is clipped. JS solves for the matching time cursor.
-}
clampPolicy : Policy
clampPolicy =
    { range = Pinned
    , current = Fixed
    , timing = SolveFromCurrent
    }


{-| Track bounds edge-to-edge: endpoints follow the new bounds, current value
stays on its pixel (clamped), and JS solves for the matching time cursor.
-}
retargetPolicy : Policy
retargetPolicy =
    { range = Adaptive
    , current = Fixed
    , timing = SolveFromCurrent
    }


{-| The name of an anim group a directive targets.
-}
type alias AnimGroupName =
    String


{-| One pending resize bounds directive for a single property (or the group
default). The policy controlling how bounds are applied is stored in the
`AnimBuilder`'s persistent state and looked up at resize time.
-}
type alias Entry =
    { bounds : Bounds }


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


{-| Record the group-wide default bounds directive used as a fallback for any
property on this group that has no explicit entry.
-}
bounds : AnimGroupName -> Bounds -> Builder -> Builder
bounds name bounds_ (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\e -> { e | default = Just { bounds = bounds_ } }))
            d
        )


{-| Record a translate-axis resize bounds directive for the given anim group.
-}
setTranslate : AnimGroupName -> Bounds -> Builder -> Builder
setTranslate name bounds_ (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\e -> { e | translate = Just { bounds = bounds_ } }))
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


{-| Record a scale-axis resize bounds directive for the given anim group.
-}
setScale : AnimGroupName -> Bounds -> Builder -> Builder
setScale name bounds_ (Builder d) =
    Builder
        (Dict.update name
            (updateEntries (\e -> { e | scale = Just { bounds = bounds_ } }))
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
isEmpty bounds_ =
    bounds_.x == Nothing && bounds_.y == Nothing && bounds_.z == Nothing


{-| Compute new per-axis start / end / current.

`Nothing` bounds = leave axis untouched.

`isLooping` controls whether the result preserves full extremes (so that
ping-pong continues to span the full new range) or shrinks to a single
leg (one-shot animations finish at the new target).

-}
applyAxis :
    Policy
    -> Bool
    -> Maybe AxisBounds
    -> Float
    -> Float
    -> Float
    -> AxisResult
applyAxis policy isLooping maybeBounds startV endV currentV =
    case maybeBounds of
        Nothing ->
            { start = startV, end = endV, current = currentV }

        Just b ->
            if startV == endV then
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
                case policy.range of
                    Pinned ->
                        -- The configured start/end are treated as the
                        -- animation's intent; the new bounds only act as a
                        -- clip box.
                        { start = clamp b.min b.max startV
                        , end = clamp b.min b.max endV
                        , current = clamp b.min b.max currentV
                        }

                    Adaptive ->
                        -- Bounds drive the leg's endpoints.
                        let
                            newCurrent =
                                case policy.current of
                                    Fixed ->
                                        -- Current value stays on its pixel
                                        -- (clamped into bounds) - no visual jump.
                                        clamp b.min b.max currentV

                                    Relative ->
                                        -- Current value is proportionally
                                        -- remapped from old range into new range.
                                        let
                                            oldMin =
                                                Basics.min startV endV

                                            oldMax =
                                                Basics.max startV endV

                                            oldRange =
                                                oldMax - oldMin

                                            newRange =
                                                b.max - b.min
                                        in
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
