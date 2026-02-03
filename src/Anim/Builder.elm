module Anim.Builder exposing (AnimBuilder)

{-| The core animation builder type used across all engines.

This module exposes the `AnimBuilder` type for creating reusable animation
functions that work with any engine (CSS, WAAPI, Sub, Scroll).


# Type

@docs AnimBuilder

-}

import Anim.Internal.Builder as Internal


{-| A builder for configuring animations.

Use this type when creating reusable animation functions that should work
across all engines:

    import Anim.Builder exposing (AnimBuilder)
    import Anim.Property.Translate as Translate

    moveRight : AnimBuilder -> AnimBuilder
    moveRight =
        Translate.for "box"
            >> Translate.toX 200
            >> Translate.speed 100
            >> Translate.build

These functions can then be used with any engine:

    -- With CSS Engine
    CSS.animate animState moveRight

    -- With WAAPI Engine
    WAAPI.animate animState moveRight

    -- With Sub Engine
    Sub.animate animState moveRight

-}
type alias AnimBuilder =
    Internal.AnimBuilder
