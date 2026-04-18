module Anim.Internal.Engine.Animation.CSS.Keyframe.Animation exposing
    ( Animation
    , getKeyframes
    , init
    , setAnimationName
    , setDirection
    , setDuration
    , setIterations
    , setKeyframes
    , toCssString
    )

import Anim.Internal.Builder as Builder



-- ============================================================
-- MODEL
-- ============================================================


type Animation
    = Animation
        { animationName : String
        , keyframes : String
        , duration : Int
        , iterations : Builder.Iterations
        , direction : Builder.AnimationDirection
        }



-- ============================================================
-- INITIALIZE
-- ============================================================


init : Animation
init =
    Animation
        { animationName = ""
        , keyframes = ""
        , duration = 0
        , iterations = Builder.Once
        , direction = Builder.Normal
        }



-- ============================================================
-- GETTERS
-- ============================================================


getKeyframes : Animation -> String
getKeyframes (Animation animation) =
    animation.keyframes



-- ============================================================
-- SETTERS
-- ============================================================


setAnimationName : String -> Animation -> Animation
setAnimationName animationName (Animation animation) =
    Animation { animation | animationName = animationName }


setKeyframes : String -> Animation -> Animation
setKeyframes keyframes (Animation animation) =
    Animation { animation | keyframes = keyframes }


setDuration : Int -> Animation -> Animation
setDuration duration (Animation animation) =
    Animation { animation | duration = duration }


setIterations : Builder.Iterations -> Animation -> Animation
setIterations iterations (Animation animation) =
    Animation { animation | iterations = iterations }


setDirection : Builder.AnimationDirection -> Animation -> Animation
setDirection direction (Animation animation) =
    Animation { animation | direction = direction }



-- ============================================================
-- VIEW
-- ============================================================


toCssString : Animation -> String
toCssString (Animation animation) =
    let
        iterationString =
            case animation.iterations of
                Builder.Once ->
                    "1"

                Builder.Times n ->
                    String.fromInt n

                Builder.Infinite ->
                    "infinite"

        directionString =
            case animation.direction of
                Builder.Normal ->
                    "normal"

                Builder.Alternate ->
                    "alternate"
    in
    animation.animationName
        ++ " "
        ++ String.fromInt animation.duration
        ++ "ms linear 0ms "
        ++ iterationString
        ++ " "
        ++ directionString
        ++ " forwards"
