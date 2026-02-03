module Common.Animations.Controls exposing
    ( animate
    , elementId
    , init
    )

{-| Common Animation Control functions that work across all animation engines.
These functions take an AnimBuilder and return an AnimBuilder, making them
portable across CSS Transitions, CSS Keyframes, Sub, and WAAPI engines.

This demonstrates the "easy migration" feature of elm-animate - the same
animation logic works identically across all engines!

-}

import Anim.Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Property.Translate as Translate


elementId : String
elementId =
    "bouncing-ball"


init : Int -> AnimBuilder -> AnimBuilder
init animationAreaWidth =
    let
        xPos =
            toFloat animationAreaWidth / 2 - 25
    in
    Translate.initXY elementId xPos 50


animate : AnimBuilder -> AnimBuilder
animate =
    Translate.for elementId
        >> Translate.fromY 50
        >> Translate.toY 300
        >> Translate.speed 200
        >> Translate.easing BounceOut
        >> Translate.build
