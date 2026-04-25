module Common.Animations.Translate exposing
    ( elementId
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

import Easing as Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder
import Anim.Property.Translate as Translate


elementId : String
elementId =
    "box"


init : Builder.AnimBuilder -> Builder.AnimBuilder
init =
    Translate.initXY elementId 0 0


moveToXY : Float -> Float -> Easing -> Builder.AnimBuilder -> Builder.AnimBuilder
moveToXY x y easing =
    Translate.for elementId
        >> Translate.toXY x y
        >> Translate.speed 100
        >> Translate.easing easing
        >> Translate.build


moveToX : Float -> Easing -> Builder.AnimBuilder -> Builder.AnimBuilder
moveToX x easing =
    Translate.for elementId
        >> Translate.toX x
        >> Translate.speed 100
        >> Translate.easing easing
        >> Translate.build


moveToY : Float -> Easing -> Builder.AnimBuilder -> Builder.AnimBuilder
moveToY y easing =
    Translate.for elementId
        >> Translate.toY y
        >> Translate.speed 100
        >> Translate.easing easing
        >> Translate.build


moveToPosition1 : Builder.AnimBuilder -> Builder.AnimBuilder
moveToPosition1 =
    moveToXY 100 100 BackIn


moveToPosition2 : Builder.AnimBuilder -> Builder.AnimBuilder
moveToPosition2 =
    moveToXY 300 200 BackOut


moveLeft : Builder.AnimBuilder -> Builder.AnimBuilder
moveLeft =
    moveToX 0
        (BackInCustom 1.7)


{-| Move to the right edge (X=450) with bounce effect
-}
moveRight : Builder.AnimBuilder -> Builder.AnimBuilder
moveRight =
    moveToX 450
        (BackOutCustom 1.7)


{-| Move to the top edge (Y=0) with BounceInOut effect
-}
moveUp : Builder.AnimBuilder -> Builder.AnimBuilder
moveUp =
    moveToY 0 (BackInOutCustom ( 1.7, 0.1 ))


{-| Move to the bottom edge (Y=300) with ease in
-}
moveDown : Builder.AnimBuilder -> Builder.AnimBuilder
moveDown =
    moveToY 350 (BackInOutCustom ( 1.7, 10 ))


{-| Return to origin (0, 0) with smooth easing
-}
returnToOrigin : Builder.AnimBuilder -> Builder.AnimBuilder
returnToOrigin =
    moveToXY 0 0 BackInOut
