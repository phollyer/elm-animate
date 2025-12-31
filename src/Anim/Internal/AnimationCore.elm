module Anim.Internal.AnimationCore exposing (animationSteps, animationStepsWithFrames)

{- Core animation interpolation functions.

   This module contains code derived from SmoothScroll by Linus Schoemaker and Ruben Lie King (2019).
   The animationStepsWithFrames function implements frame-based interpolation logic from the original work.

-}

import Ease


animationSteps : Int -> Ease.Easing -> Float -> Float -> List Float
animationSteps speed easing start stop =
    let
        diff =
            abs <| start - stop

        frames =
            max 1 <| round diff // speed
    in
    animationStepsWithFrames frames easing start stop


animationStepsWithFrames : Int -> Ease.Easing -> Float -> Float -> List Float
animationStepsWithFrames frames easing start stop =
    let
        diff =
            abs <| start - stop

        framesFloat =
            toFloat frames

        weights =
            List.map (\i -> easing (toFloat i / framesFloat)) (List.range 0 (frames - 1))

        operator =
            if start > stop then
                (-)

            else
                (+)

        steps =
            List.map (\weight -> operator start (weight * diff)) weights

        -- Ensure the final step is exactly the target value
        -- This fixes issues where easing functions don't return exactly 1.0 at progress=1.0
        finalSteps =
            case List.reverse steps of
                [] ->
                    []

                _ :: rest ->
                    List.reverse (stop :: rest)
    in
    if frames <= 0 || start == stop then
        []

    else
        finalSteps
