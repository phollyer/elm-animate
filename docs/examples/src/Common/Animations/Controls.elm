module Common.Animations.Controls exposing
    ( animGroup
    , animate
    , init
    )

{-| Common Animation Control functions that work across all animation engines.
These functions take an AnimBuilder and return an AnimBuilder, making them
portable across CSS Transition, CSS Keyframe, Sub, and WAAPI engines.

This demonstrates the "easy migration" feature of elm-animate - the same
animation logic works identically across all engines!

-}

import Anim.Builder exposing (AnimBuilder)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.Translate as Translate


animGroup : String
animGroup =
    "bouncing-ball"


init : Int -> AnimBuilder -> AnimBuilder
init animAreaWidth =
    let
        xPos =
            toFloat animAreaWidth / 2 - 25
    in
    Translate.initXY animGroup xPos 50


animate : AnimBuilder -> AnimBuilder
animate =
    Translate.for animGroup
        >> Translate.fromY 50
        >> Translate.toY 300
        >> Translate.speed 200
        >> Translate.easing BounceOut
        >> Translate.build
