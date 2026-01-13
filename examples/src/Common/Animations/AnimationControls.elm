module Common.Animations.AnimationControls exposing (animate, init)

{-| Common Animation Control functions that work across all animation engines.
These functions take an AnimBuilder and return an AnimBuilder, making them
portable across CSS Transitions, CSS Keyframes, Sub, and WAAPI engines.

This demonstrates the "easy migration" feature of elm-animate - the same
animation logic works identically across all engines!

-}

import Anim.Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder
import Anim.Property.Position as Position


{-| Initialize the starting position
-}
init : String -> Float -> Float -> Builder.AnimBuilder -> Builder.AnimBuilder
init =
    Position.initXY


{-| Animate the element to a specific position (X=300, Y=150)
-}
animate : String -> Builder.AnimBuilder -> Builder.AnimBuilder
animate elementId builder =
    builder
        |> Position.for elementId
        |> Position.fromY 50
        |> Position.toY 300
        |> Position.speed 200
        |> Position.easing BounceOut
        |> Position.build
