module Common.Animations.Position exposing
    ( elementId
    , init
    , moveDown
    , moveLeft
    , moveRight
    , moveToPosition1
    , moveToPosition2
    , moveUp
    , returnToOrigin
    )

{-| Common Position animations that work across all animation engines.

These functions take an AnimBuilder and return an AnimBuilder, making them
portable across CSS Transitions, CSS Keyframes, Sub, and WAAPI engines.

This demonstrates the "easy migration" feature of elm-animate - the same
animation logic works identically across all engines!

-}

import Anim.Easing as Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder
import Anim.Property.Position as Position


elementId : String
elementId =
    "box"


init : Builder.AnimBuilder -> Builder.AnimBuilder
init =
    Position.initXY elementId 0 0


moveToXY : Float -> Float -> Easing -> Builder.AnimBuilder -> Builder.AnimBuilder
moveToXY x y easing =
    Position.for elementId
        >> Position.toXY x y
        >> Position.speed 100
        >> Position.easing easing
        >> Position.build


moveToX : Float -> Easing -> Builder.AnimBuilder -> Builder.AnimBuilder
moveToX x easing =
    Position.for elementId
        >> Position.toX x
        >> Position.speed 100
        >> Position.easing easing
        >> Position.build


moveToY : Float -> Easing -> Builder.AnimBuilder -> Builder.AnimBuilder
moveToY y easing =
    Position.for elementId
        >> Position.toY y
        >> Position.speed 50
        >> Position.easing easing
        >> Position.build


moveToPosition1 : Builder.AnimBuilder -> Builder.AnimBuilder
moveToPosition1 =
    moveToXY 100 100 ElasticOut


moveToPosition2 : Builder.AnimBuilder -> Builder.AnimBuilder
moveToPosition2 =
    moveToXY 300 200 ElasticOut


moveLeft : Builder.AnimBuilder -> Builder.AnimBuilder
moveLeft =
    moveToX 0 ElasticIn


{-| Move to the right edge (X=450) with bounce effect
-}
moveRight : Builder.AnimBuilder -> Builder.AnimBuilder
moveRight =
    moveToX 450 ElasticOut


{-| Move to the top edge (Y=0) with ease out
-}
moveUp : Builder.AnimBuilder -> Builder.AnimBuilder
moveUp =
    moveToY 0 (BounceInCustom 0.1)


{-| Move to the bottom edge (Y=300) with ease in
-}
moveDown : Builder.AnimBuilder -> Builder.AnimBuilder
moveDown =
    moveToY 350 (BounceOutCustom 0.1)


{-| Return to origin (0, 0) with smooth easing
-}
returnToOrigin : Builder.AnimBuilder -> Builder.AnimBuilder
returnToOrigin =
    moveToXY 0 0 BounceInOut
