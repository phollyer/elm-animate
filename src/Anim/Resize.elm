module Anim.Resize exposing (Strategy(..), AxisBounds, Bounds)

{-| Shared types describing how an in-flight animation should adapt when
its container's bounds change.

Property modules (e.g. [`Anim.Property.Translate`](Anim-Property-Translate))
expose `onResize` builders that consume these types, and the engines
([`Anim.Engine.WAAPI`](Anim-Engine-WAAPI),
[`Anim.Engine.Sub`](Anim-Engine-Sub)) accept a composed
[`Anim.Resize.Builder.Builder`](Anim-Resize-Builder#Builder) of those
entries.

@docs Strategy, AxisBounds, Bounds

-}


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
