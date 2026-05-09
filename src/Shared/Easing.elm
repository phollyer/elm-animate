module Shared.Easing exposing
    ( toCSS
    , toFunction
    , toWebAnimations
    , transitionFractionOf
    )

import Array
import Ease as E
import Easing exposing (Easing(..))
import Shared.Easing.Keyframes as Keyframes
import Shared.Easing.Physics as Physics



-- ============================================================
-- CSS CONVERSION
-- ============================================================


toCSS : Maybe Easing -> String
toCSS maybeEasing =
    case maybeEasing of
        Just easing ->
            easingToCSS easing

        Nothing ->
            "ease"


easingToCSS : Easing -> String
easingToCSS easing =
    case easing of
        CubicBezier p1x p1y p2x p2y ->
            "cubic-bezier("
                ++ String.fromFloat p1x
                ++ ", "
                ++ String.fromFloat p1y
                ++ ", "
                ++ String.fromFloat p2x
                ++ ", "
                ++ String.fromFloat p2y
                ++ ")"

        Linear ->
            "linear"

        Ease ->
            "ease"

        EaseIn ->
            "ease-in"

        EaseOut ->
            "ease-out"

        EaseInOut ->
            "ease-in-out"

        SineIn ->
            "cubic-bezier(0.12, 0, 0.39, 0)"

        SineOut ->
            "cubic-bezier(0.61, 1, 0.88, 1)"

        SineInOut ->
            "cubic-bezier(0.37, 0, 0.63, 1)"

        QuadIn ->
            "cubic-bezier(0.11, 0, 0.5, 0)"

        QuadOut ->
            "cubic-bezier(0.5, 1, 0.89, 1)"

        QuadInOut ->
            "cubic-bezier(0.45, 0, 0.55, 1)"

        CubicIn ->
            "cubic-bezier(0.32, 0, 0.67, 0)"

        CubicOut ->
            "cubic-bezier(0.33, 1, 0.68, 1)"

        CubicInOut ->
            "cubic-bezier(0.65, 0, 0.35, 1)"

        QuartIn ->
            "cubic-bezier(0.5, 0, 0.75, 0)"

        QuartOut ->
            "cubic-bezier(0.25, 1, 0.5, 1)"

        QuartInOut ->
            "cubic-bezier(0.76, 0, 0.24, 1)"

        QuintIn ->
            "cubic-bezier(0.64, 0, 0.78, 0)"

        QuintOut ->
            "cubic-bezier(0.22, 1, 0.36, 1)"

        QuintInOut ->
            "cubic-bezier(0.83, 0, 0.17, 1)"

        ExpoIn ->
            "cubic-bezier(0.7, 0, 0.84, 0)"

        ExpoOut ->
            "cubic-bezier(0.16, 1, 0.3, 1)"

        ExpoInOut ->
            "cubic-bezier(0.87, 0, 0.13, 1)"

        CircIn ->
            "cubic-bezier(0.55, 0, 1, 0.45)"

        CircOut ->
            "cubic-bezier(0, 0.55, 0.45, 1)"

        CircInOut ->
            "cubic-bezier(0.85, 0, 0.15, 1)"

        BackIn ->
            "cubic-bezier(0.36, 0, 0.66, -0.56)"

        BackOut ->
            "cubic-bezier(0.34, 1.56, 0.64, 1)"

        BackInOut ->
            "cubic-bezier(0.68, -0.6, 0.32, 1.6)"

        BackInCustom _ ->
            "linear"

        BackOutCustom _ ->
            "linear"

        BackInOutCustom _ ->
            "linear"

        ElasticIn ->
            "cubic-bezier(0.55, 0.055, 0.675, 0.19)"

        ElasticOut ->
            "cubic-bezier(0.175, 0.885, 0.32, 1.275)"

        ElasticInOut ->
            "cubic-bezier(0.445, 0.05, 0.55, 0.95)"

        ElasticInCustom _ ->
            "linear"

        ElasticOutCustom _ ->
            "linear"

        ElasticInOutCustom _ ->
            "linear"

        ElasticInAdvanced _ ->
            "linear"

        ElasticOutAdvanced _ ->
            "linear"

        ElasticInOutAdvanced _ ->
            "linear"

        BounceIn ->
            "cubic-bezier(0.6, 0.04, 0.98, 0.335)"

        BounceOut ->
            "cubic-bezier(0.175, 0.885, 0.32, 1.275)"

        BounceInOut ->
            "cubic-bezier(0.445, 0.050, 0.550, 0.950)"

        BounceInCustom _ ->
            "linear"

        BounceOutCustom _ ->
            "linear"

        BounceInOutCustom _ ->
            "linear"

        BounceInAdvanced _ ->
            "linear"

        BounceOutAdvanced _ ->
            "linear"

        BounceInOutAdvanced _ ->
            "linear"



-- ============================================================
-- WEB ANIMATIONS CONVERSION
-- ============================================================


toWebAnimations : Easing -> String
toWebAnimations easing =
    case easing of
        CubicBezier p1x p1y p2x p2y ->
            "cubic-bezier("
                ++ String.fromFloat p1x
                ++ ", "
                ++ String.fromFloat p1y
                ++ ", "
                ++ String.fromFloat p2x
                ++ ", "
                ++ String.fromFloat p2y
                ++ ")"

        Linear ->
            "linear"

        Ease ->
            "ease"

        EaseIn ->
            "ease-in"

        EaseOut ->
            "ease-out"

        EaseInOut ->
            "ease-in-out"

        SineIn ->
            "cubic-bezier(0.12, 0, 0.39, 0)"

        SineOut ->
            "cubic-bezier(0.61, 1, 0.88, 1)"

        SineInOut ->
            "cubic-bezier(0.37, 0, 0.63, 1)"

        QuadIn ->
            "cubic-bezier(0.11, 0, 0.5, 0)"

        QuadOut ->
            "cubic-bezier(0.5, 1, 0.89, 1)"

        QuadInOut ->
            "cubic-bezier(0.45, 0, 0.55, 1)"

        CubicIn ->
            "cubic-bezier(0.32, 0, 0.67, 0)"

        CubicOut ->
            "cubic-bezier(0.67, 0, 0.32, 1)"

        CubicInOut ->
            "cubic-bezier(0.65, 0, 0.35, 1)"

        QuartIn ->
            "cubic-bezier(0.5, 0, 0.75, 0)"

        QuartOut ->
            "cubic-bezier(0.25, 1, 0.5, 1)"

        QuartInOut ->
            "cubic-bezier(0.76, 0, 0.24, 1)"

        QuintIn ->
            "cubic-bezier(0.64, 0, 0.78, 0)"

        QuintOut ->
            "cubic-bezier(0.22, 1, 0.36, 1)"

        QuintInOut ->
            "cubic-bezier(0.83, 0, 0.17, 1)"

        ExpoIn ->
            "cubic-bezier(0.7, 0, 0.84, 0)"

        ExpoOut ->
            "cubic-bezier(0.16, 1, 0.3, 1)"

        ExpoInOut ->
            "cubic-bezier(0.87, 0, 0.13, 1)"

        CircIn ->
            "cubic-bezier(0.55, 0, 1, 0.45)"

        CircOut ->
            "cubic-bezier(0, 0.55, 0.45, 1)"

        CircInOut ->
            "cubic-bezier(0.85, 0, 0.15, 1)"

        BackIn ->
            "cubic-bezier(0.36, 0, 0.66, -0.56)"

        BackOut ->
            "cubic-bezier(0.34, 1.56, 0.64, 1)"

        BackInOut ->
            "cubic-bezier(0.68, -0.6, 0.32, 1.6)"

        BackInCustom _ ->
            "linear"

        BackOutCustom _ ->
            "linear"

        BackInOutCustom _ ->
            "linear"

        ElasticIn ->
            "linear"

        ElasticOut ->
            "linear"

        ElasticInOut ->
            "linear"

        ElasticInCustom _ ->
            "linear"

        ElasticOutCustom _ ->
            "linear"

        ElasticInOutCustom _ ->
            "linear"

        ElasticInAdvanced _ ->
            "linear"

        ElasticOutAdvanced _ ->
            "linear"

        ElasticInOutAdvanced _ ->
            "linear"

        BounceIn ->
            "linear"

        BounceOut ->
            "linear"

        BounceInOut ->
            "linear"

        BounceInCustom _ ->
            "linear"

        BounceOutCustom _ ->
            "linear"

        BounceInOutCustom _ ->
            "linear"

        BounceInAdvanced _ ->
            "linear"

        BounceOutAdvanced _ ->
            "linear"

        BounceInOutAdvanced _ ->
            "linear"



-- ============================================================
-- TRANSITION FRACTION
-- ============================================================


{-| Re-export of `Shared.Easing.Physics.transitionFractionOf` so engine
code can find the function on the same module that owns `toFunction`,
`toCSS`, and `toWebAnimations`. See `Shared.Easing.Physics` for the
documentation and physics derivation.
-}
transitionFractionOf : Easing -> Float
transitionFractionOf =
    Physics.transitionFractionOf



-- ============================================================
-- EASING FUNCTIONS
-- ============================================================


toFunction : Float -> Easing -> (Float -> Float)
toFunction durationMs easing =
    let
        velocityFactor =
            1000.0 / durationMs
    in
    case easing of
        CubicBezier p1x p1y p2x p2y ->
            E.bezier p1x p1y p2x p2y

        Linear ->
            E.linear

        Ease ->
            E.inOutQuad

        EaseIn ->
            E.inQuad

        EaseOut ->
            E.outQuad

        EaseInOut ->
            E.inOutQuad

        SineIn ->
            E.inSine

        SineOut ->
            E.outSine

        SineInOut ->
            E.inOutSine

        QuadIn ->
            E.inQuad

        QuadOut ->
            E.outQuad

        QuadInOut ->
            E.inOutQuad

        CubicIn ->
            E.inCubic

        CubicOut ->
            E.outCubic

        CubicInOut ->
            E.inOutCubic

        QuartIn ->
            E.inQuart

        QuartOut ->
            E.outQuart

        QuartInOut ->
            E.inOutQuart

        QuintIn ->
            E.inQuint

        QuintOut ->
            E.outQuint

        QuintInOut ->
            E.inOutQuint

        ExpoIn ->
            E.inExpo

        ExpoOut ->
            E.outExpo

        ExpoInOut ->
            E.inOutExpo

        CircIn ->
            E.inCirc

        CircOut ->
            E.outCirc

        CircInOut ->
            E.inOutCirc

        BackIn ->
            E.inBack

        BackOut ->
            E.outBack

        BackInOut ->
            E.inOutBack

        BackInCustom strength ->
            customBackIn strength

        BackOutCustom strength ->
            customBackOut strength

        BackInOutCustom strengthTuple ->
            customBackInOut strengthTuple

        ElasticIn ->
            E.inElastic

        ElasticOut ->
            E.outElastic

        ElasticInOut ->
            E.inOutElastic

        ElasticInCustom _ ->
            keyframeBased durationMs easing

        ElasticOutCustom _ ->
            keyframeBased durationMs easing

        ElasticInOutCustom _ ->
            keyframeBased durationMs easing

        ElasticInAdvanced _ ->
            keyframeBased durationMs easing

        ElasticOutAdvanced _ ->
            keyframeBased durationMs easing

        ElasticInOutAdvanced _ ->
            keyframeBased durationMs easing

        BounceIn ->
            E.inBounce

        BounceOut ->
            E.outBounce

        BounceInOut ->
            E.inOutBounce

        BounceInCustom _ ->
            keyframeBased durationMs easing

        BounceOutCustom _ ->
            keyframeBased durationMs easing

        BounceInOutCustom _ ->
            keyframeBased durationMs easing

        BounceInAdvanced _ ->
            keyframeBased durationMs easing

        BounceOutAdvanced _ ->
            keyframeBased durationMs easing

        BounceInOutAdvanced _ ->
            keyframeBased durationMs easing


{-| Sample the keyframe array produced by `Shared.Easing.Keyframes` and
return a function that linearly interpolates between samples for any t
in [0, 1].

Used for the physics-based Bounce/Elastic Custom and Advanced variants
so that all engines (Sub, Keyframe, WAAPI) see the same curve. The
keyframe array is computed once when this function is invoked and
shared by every per-frame call to the returned closure.

-}
keyframeBased : Float -> Easing -> (Float -> Float)
keyframeBased durationMs easing =
    let
        samples =
            Keyframes.generateKeyframes easing durationMs
                |> Array.fromList

        count =
            Array.length samples
    in
    if count < 2 then
        \_ -> 0.0

    else
        \t ->
            let
                clamped =
                    clamp 0.0 1.0 t

                position =
                    clamped * toFloat (count - 1)

                idx =
                    floor position

                fraction =
                    position - toFloat idx

                a =
                    Array.get idx samples |> Maybe.withDefault 0.0

                b =
                    Array.get (min (count - 1) (idx + 1)) samples
                        |> Maybe.withDefault a
            in
            a + (b - a) * fraction



-- ============================================================
-- BACK IMPLEMENTATIONS
-- ============================================================


{-| Custom back easing with strength parameter controlling overshoot amount.
The strength parameter directly controls the overshoot (standard back easing uses 1.70158).
Higher values create more dramatic overshoot effects.
-}
customBackOut : Float -> Float -> Float
customBackOut strength t =
    let
        s =
            strength

        p =
            t - 1
    in
    p * p * ((s + 1) * p + s) + 1


customBackIn : Float -> Float -> Float
customBackIn strength t =
    1.0 - customBackOut strength (1.0 - t)


customBackInOut : ( Float, Float ) -> Float -> Float
customBackInOut ( strengthIn, strengthOut ) t =
    if t < 0.5 then
        customBackIn strengthIn (t * 2) * 0.5

    else
        0.5 + (customBackOut strengthOut ((t - 0.5) * 2) * 0.5)
