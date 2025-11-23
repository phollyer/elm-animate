module Scroll.Types exposing
    ( Distance
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


{-| Type alias for pixel distances, offsets, and sizes.
-}
type alias Distance =
    Float


{-| Type alias for animation frame counts.
-}
type alias Frames =
    Int


{-| Type alias for coordinate position pairs (x, y).
-}
type alias CoordinatePair =
    ( Float, Float )
