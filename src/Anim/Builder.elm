module Anim.Builder exposing (AnimBuilder)

{-| The core animation builder type.

This is the type used by all animation configuration functions across all properties and engines.

It is exposed by each Engine for simplicity, so you can import it from there, but if you are building
a module of reusable animation functions that are engine-agnostic, you can import it directly from here.

    import Anim.Builder exposing (AnimBuilder)
    import Anim.Property.Translate as Translate

    moveRight : AnimBuilder -> AnimBuilder
    moveRight =
        Translate.for "animGroupName"
            >> Translate.fromX 0
            >> Translate.toX 200
            >> Translate.speed 100
            >> Translate.build


# Type

@docs AnimBuilder

-}

import Anim.Internal.Builder as Internal


{-| The builder type for configuring animations.
-}
type alias AnimBuilder =
    Internal.AnimBuilder
