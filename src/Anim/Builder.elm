module Anim.Builder exposing (AnimBuilder)

{-| The core animation builder type used across all engines.

This module exposes the `AnimBuilder` type for creating reusable animation
functions that work with any engine.


# Type

@docs AnimBuilder

-}

import Anim.Internal.Builder as Internal


{-| A builder for configuring animations.

Use this type when creating reusable animation functions that will work
across all engines:

    import Anim.Builder exposing (AnimBuilder)
    import Anim.Property.Translate as Translate

    moveRight : AnimBuilder -> AnimBuilder
    moveRight =
        Translate.for "animGroupName"
            >> Translate.fromX 0
            >> Translate.toX 200
            >> Translate.speed 100
            >> Translate.build

These functions can then be used with any engine:

    -- With CSS Engines
    CSS.Transitions.animate animState moveRight

    CSS.Transitions.fireAndForget moveRight

    CSS.Keyframes.animate animState moveRight

    CSS.Keyframes.fireAndForget moveRight

    -- With Sub Engine
    Sub.animate animState moveRight

    -- With WAAPI Engine
    WAAPI.animate animState <|
        WAAPI.forElemnt "element-id"
            >> WAAPI.moveRight

-}
type alias AnimBuilder =
    Internal.AnimBuilder
