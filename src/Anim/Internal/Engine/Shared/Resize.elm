module Anim.Internal.Engine.Shared.Resize exposing
    ( AxisBounds
    , AxisResult
    , ResizeBounds
    , Strategy
    , applyAxis
    , isEmpty
    )

{-| Engine-agnostic math for adapting an in-flight translate animation to
new bounds.

Both the Sub engine (Elm-side state) and the WAAPI engine (port-driven)
use this to compute the new per-axis `start` / `end` / `current` triple.
The engines themselves remain responsible for applying the result —
mutating `PropertyAnimation` for Sub, issuing a port command for WAAPI.

The user-facing types live in [`Anim.Resize`](Anim-Resize); this module
re-exports them so internal engines keep their existing import surface.

-}

import Anim.Resize as Public


{-| Re-export of [`Anim.Resize.Strategy`](Anim-Resize#Strategy). Use the
constructors via `Anim.Resize.Proportional` / `Anim.Resize.Clamp`.
-}
type alias Strategy =
    Public.Strategy


{-| Re-export of [`Anim.Resize.AxisBounds`](Anim-Resize#AxisBounds).
-}
type alias AxisBounds =
    Public.AxisBounds


{-| Re-export of [`Anim.Resize.Bounds`](Anim-Resize#Bounds). Now 3D —
each engine consumes whichever axes the user populated.
-}
type alias ResizeBounds =
    Public.Bounds


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
isEmpty : ResizeBounds -> Bool
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
                Public.Clamp ->
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

                Public.Proportional ->
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
