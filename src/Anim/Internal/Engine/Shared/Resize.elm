module Anim.Internal.Engine.Shared.Resize exposing
    ( AxisBounds
    , AxisResult
    , ResizeBounds
    , Strategy(..)
    , applyAxis
    )

{-| Engine-agnostic math for adapting an in-flight translate animation to
new bounds.

Both the Sub engine (Elm-side state) and the WAAPI engine (port-driven)
use this to compute the new per-axis `start` / `end` / `current` triple.
The engines themselves remain responsible for applying the result —
mutating `PropertyAnimation` for Sub, issuing a port command for WAAPI.

-}


{-| How a resize should reposition translate values when the bounding
range changes.

  - `Proportional` preserves normalized progress within the old/new bounds.
    A box halfway across the track stays halfway across the track. Best
    for looping/ping-pong animations where you want the rhythm preserved.
  - `Clamp` keeps the current animated value as-is and re-clamps it (and
    the target) into the new bounds. Best for one-shot animations where
    you only want the new range to act as a wall.

-}
type Strategy
    = Proportional
    | Clamp


{-| New per-axis translate bounds. An axis left as `Nothing` is untouched.
-}
type alias ResizeBounds =
    { x : Maybe AxisBounds
    , y : Maybe AxisBounds
    }


type alias AxisBounds =
    { min : Float, max : Float }


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
                                b.min

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
