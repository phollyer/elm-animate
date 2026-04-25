module Common.Animations.Translate exposing
    ( animGroup
    , init
    , moveDown
    , moveLeft
    , moveRight
    , moveToPosition1
    , moveToPosition2
    , moveToXY
    , moveUp
    , returnToOrigin
    )

{-| Common Translate animations that work across all animation engines.

These functions take an AnimBuilder and return an AnimBuilder, making them
portable across CSS Transition, CSS Keyframe, Sub, and WAAPI engines.

This demonstrates the "easy migration" feature of elm-animate - the same
animation logic works identically across all engines!

-}

import Anim.Builder exposing (AnimBuilder)
import Anim.Property.Translate as Translate
import Easing exposing (Easing(..))


animGroup : String
animGroup =
    "box"


init : AnimBuilder -> AnimBuilder
init =
    Translate.initXY animGroup 0 0


moveToXY : Float -> Float -> Easing -> AnimBuilder -> AnimBuilder
moveToXY x y easing =
    Translate.for animGroup
        >> Translate.toXY x y
        >> Translate.speed 100
        >> Translate.easing easing
        >> Translate.build


moveToX : Float -> Easing -> AnimBuilder -> AnimBuilder
moveToX x easing =
    Translate.for animGroup
        >> Translate.toX x
        >> Translate.speed 100
        >> Translate.easing easing
        >> Translate.build


moveToY : Float -> Easing -> AnimBuilder -> AnimBuilder
moveToY y easing =
    Translate.for animGroup
        >> Translate.toY y
        >> Translate.speed 100
        >> Translate.easing easing
        >> Translate.build


moveToPosition1 : AnimBuilder -> AnimBuilder
moveToPosition1 =
    moveToXY 100 100 BackIn


moveToPosition2 : AnimBuilder -> AnimBuilder
moveToPosition2 =
    moveToXY 300 200 BackOut


moveLeft : AnimBuilder -> AnimBuilder
moveLeft =
    moveToX 0
        (BackInCustom 1.7)


{-| Move to the right edge (X=450) with bounce effect
-}
moveRight : AnimBuilder -> AnimBuilder
moveRight =
    moveToX 450
        (BackOutCustom 1.7)


{-| Move to the top edge (Y=0) with BounceInOut effect
-}
moveUp : AnimBuilder -> AnimBuilder
moveUp =
    moveToY 0 (BackInOutCustom ( 1.7, 0.1 ))


{-| Move to the bottom edge (Y=300) with ease in
-}
moveDown : AnimBuilder -> AnimBuilder
moveDown =
    moveToY 350 (BackInOutCustom ( 1.7, 10 ))


{-| Return to origin (0, 0) with smooth easing
-}
returnToOrigin : AnimBuilder -> AnimBuilder
returnToOrigin =
    moveToXY 0 0 BackInOut
