module Anim.Internal.Engine.AnimationCore exposing (steps)

{- Core animation interpolation functions.

   This module contains code derived from SmoothScroll by Linus Schoemaker and Ruben Lie King (2019).
   The animationStepsWithFrames function implements frame-based interpolation logic from the original work.

-}

import Ease


steps : Int -> Ease.Easing -> Float -> Float -> List Float
steps frames easing start stop =
    let
        diff =
            abs <| start - stop

        framesFloat =
            toFloat frames

        -- Use (frames - 1) as divisor so progress ranges from 0.0 to 1.0 exactly
        -- Frame 0: 0/(frames-1) = 0.0, Frame (frames-1): (frames-1)/(frames-1) = 1.0
        weights =
            List.map (\i -> easing (toFloat i / (framesFloat - 1))) (List.range 0 (frames - 1))

        operator =
            if start > stop then
                (-)

            else
                (+)

        steps_ =
            List.map (\weight -> operator start (weight * diff)) weights

        -- Ensure the final step is exactly the target value
        -- This fixes issues where easing functions don't return exactly 1.0 at progress=1.0
        finalSteps =
            case List.reverse steps_ of
                [] ->
                    []

                _ :: rest ->
                    List.reverse (stop :: rest)
    in
    if frames <= 0 || start == stop then
        []

    else
        finalSteps
