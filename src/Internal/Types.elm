module Internal.Types exposing
    ( Pixels
    , Distance
    , Milliseconds
    , MillisecondsInt
    , Speed
    , Frames
    , CoordinatePair
    )

{-| Internal type aliases used within the scroll library implementation.

These types are not exposed in the public API and are only used for internal
function signatures.

@docs Pixels
@docs Distance
@docs Milliseconds
@docs MillisecondsInt
@docs Speed
@docs Frames
@docs CoordinatePair

-}


{-| Type alias for pixel coordinates and positions.
-}
type alias Pixels =
    Float


{-| Type alias for pixel distances, offsets, and sizes.
-}
type alias Distance =
    Float


{-| Type alias for animation durations in milliseconds.
-}
type alias Milliseconds =
    Float


{-| Type alias for animation durations in milliseconds as integers.
-}
type alias MillisecondsInt =
    Int


{-| Type alias for animation speeds in pixels per second.
-}
type alias Speed =
    Float


{-| Type alias for animation frame counts.
-}
type alias Frames =
    Int


{-| Type alias for coordinate position pairs (x, y).
-}
type alias CoordinatePair =
    ( Float, Float )
