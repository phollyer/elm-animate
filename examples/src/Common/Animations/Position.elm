module Common.Animations.Position exposing
    ( moveDown
    , moveLeft
    , moveRight
    , moveToXY
    , moveToY
    , moveUp
    , returnToOrigin
    )

{-| Common Position animations that work across all animation engines.

These functions take an AnimBuilder and return an AnimBuilder, making them
portable across CSS Transitions, CSS Keyframes, Sub, and WAAPI engines.

This demonstrates the "easy migration" feature of elm-animate - the same
animation logic works identically across all engines!

-}

import Anim.Easing as Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Property.Position as Position


{-| Move to a specific X,Y position with smooth easing
-}
moveToXY : String -> Float -> Float -> Builder.AnimBuilder -> Builder.AnimBuilder
moveToXY elementId x y builder =
    builder
        |> Position.for elementId
        |> Position.toXY x y
        |> Position.speed 200.0
        |> Position.easing (Easing.Bezier 0.3 0 0.7 0)
        |> Position.build


moveToY : String -> Float -> Easing -> Float -> Builder.AnimBuilder -> Builder.AnimBuilder
moveToY elementId speed easing y builder =
    builder
        |> Position.for elementId
        |> Position.toY y
        |> Position.speed speed
        |> Position.easing easing
        |> Position.build


moveLeft : String -> Builder.AnimBuilder -> Builder.AnimBuilder
moveLeft elementId builder =
    builder
        |> Position.for elementId
        |> Position.toX 0
        |> Position.duration 1000
        |> Position.easing Easing.BounceOut
        |> Position.build


{-| Move to the right edge (X=450) with bounce effect
-}
moveRight : String -> Builder.AnimBuilder -> Builder.AnimBuilder
moveRight elementId builder =
    builder
        |> Position.for elementId
        |> Position.toX 450
        |> Position.duration 1000
        |> Position.easing Easing.BounceIn
        |> Position.build


{-| Move to the top edge (Y=0) with ease out
-}
moveUp : String -> Builder.AnimBuilder -> Builder.AnimBuilder
moveUp elementId builder =
    builder
        |> Position.for elementId
        |> Position.toY 0
        |> Position.duration 800
        |> Position.easing Easing.EaseOut
        |> Position.build


{-| Move to the bottom edge (Y=300) with ease in
-}
moveDown : String -> Builder.AnimBuilder -> Builder.AnimBuilder
moveDown elementId builder =
    builder
        |> Position.for elementId
        |> Position.toY 300
        |> Position.duration 800
        |> Position.easing Easing.EaseIn
        |> Position.build


{-| Return to origin (0, 0) with smooth easing
-}
returnToOrigin : String -> Builder.AnimBuilder -> Builder.AnimBuilder
returnToOrigin elementId builder =
    builder
        |> Position.for elementId
        |> Position.toXY 0 0
        |> Position.duration 600
        |> Position.easing Easing.EaseInOut
        |> Position.build
