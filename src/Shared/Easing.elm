module Shared.Easing exposing
    ( toCSS
    , toFunction
    , toWebAnimations
    )

import Ease as E
import Easing exposing (Easing(..))



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

        ElasticInCustom strength ->
            customElasticIn velocityFactor strength

        ElasticOutCustom strength ->
            customElasticOut velocityFactor strength

        ElasticInOutCustom strengthTuple ->
            customElasticInOut velocityFactor strengthTuple

        ElasticInAdvanced params ->
            advancedElasticIn velocityFactor params

        ElasticOutAdvanced params ->
            advancedElasticOut velocityFactor params

        ElasticInOutAdvanced params ->
            advancedElasticInOut velocityFactor params

        BounceIn ->
            E.inBounce

        BounceOut ->
            E.outBounce

        BounceInOut ->
            E.inOutBounce

        BounceInCustom strength ->
            customBounceIn velocityFactor strength

        BounceOutCustom strength ->
            customBounceOut velocityFactor strength

        BounceInOutCustom strengthTuple ->
            customBounceInOut velocityFactor strengthTuple

        BounceInAdvanced params ->
            advancedBounceIn velocityFactor params

        BounceOutAdvanced params ->
            advancedBounceOut velocityFactor params

        BounceInOutAdvanced params ->
            advancedBounceInOut velocityFactor params



-- ============================================================
-- BOUNCE IMPLEMENTATIONS
-- ============================================================


{-| Custom bounce easing with simple strength parameter (0.0-1.0).
Strength controls bounce intensity: 0.2 = soft, 0.5 = medium, 0.8 = hard.
-}
customBounceOut : Float -> Float -> Float -> Float
customBounceOut velocityFactor strength t =
    let
        -- Convert strength to bounce parameters
        -- Clamp strength between 0.1 and 1.0
        clampedStrength =
            clamp 0.1 1.0 strength

        -- More strength = more bounces and higher amplitude
        bounces =
            2 + round (clampedStrength * 2)

        amplitude =
            (0.3 + (clampedStrength * 0.5)) * velocityFactor

        decay =
            0.5 + (clampedStrength * 0.3)
    in
    advancedBounceOutHelper bounces amplitude decay t


customBounceIn : Float -> Float -> Float -> Float
customBounceIn velocityFactor strength t =
    1.0 - customBounceOut velocityFactor strength (1.0 - t)


customBounceInOut : Float -> ( Float, Float ) -> Float -> Float
customBounceInOut velocityFactor ( strengthIn, strengthOut ) t =
    if t < 0.5 then
        -- First half: BounceIn scaled to 0-0.5
        customBounceIn velocityFactor strengthIn (t * 2) * 0.5

    else
        -- Second half: BounceOut scaled to 0.5-1.0
        0.5 + (customBounceOut velocityFactor strengthOut ((t - 0.5) * 2) * 0.5)


{-| Advanced bounce easing with full parameter control.
-}
advancedBounceOut : Float -> { bounces : Int, amplitude : Float, decay : Float } -> Float -> Float
advancedBounceOut velocityFactor params t =
    advancedBounceOutHelper params.bounces (params.amplitude * velocityFactor) params.decay t


advancedBounceIn : Float -> { bounces : Int, amplitude : Float, decay : Float } -> Float -> Float
advancedBounceIn velocityFactor params t =
    1.0 - advancedBounceOut velocityFactor params (1.0 - t)


advancedBounceInOut : Float -> { in_ : { bounces : Int, amplitude : Float, decay : Float }, out : { bounces : Int, amplitude : Float, decay : Float } } -> Float -> Float
advancedBounceInOut velocityFactor params t =
    if t < 0.5 then
        -- First half: BounceIn scaled to 0-0.5
        advancedBounceIn velocityFactor params.in_ (t * 2) * 0.5

    else
        -- Second half: BounceOut scaled to 0.5-1.0
        0.5 + (advancedBounceOut velocityFactor params.out ((t - 0.5) * 2) * 0.5)


{-| Helper function to calculate bounce with given parameters.
The element reaches the endpoint (1.0) before each bounce, then bounces back.
-}
advancedBounceOutHelper : Int -> Float -> Float -> Float -> Float
advancedBounceOutHelper bounceCount amplitude decay t =
    let
        -- Ensure at least 1 bounce
        bounces =
            max 1 bounceCount

        -- Quick approach phase
        approachPhase =
            0.15
    in
    if t <= approachPhase then
        -- Initial approach to endpoint using easeOut curve
        let
            normalizedT =
                t / approachPhase

            -- CubicOut easing for smooth approach that reaches 1.0
            progress =
                let
                    p =
                        1.0 - normalizedT
                in
                1.0 - (p * p * p)
        in
        progress

    else
        -- Bouncing phase: ALWAYS at 1.0 at bounce boundaries
        let
            -- Time within bounce phase (0.0 to 1.0)
            bounceT =
                (t - approachPhase) / (1.0 - approachPhase)

            -- Calculate which bounce we're in
            bounceProgress =
                bounceT * toFloat bounces

            currentBounce =
                floor bounceProgress

            -- Progress within current bounce (0.0 to 1.0)
            -- At 0.0 and 1.0, we should be at rest (displacement = 0)
            localT =
                bounceProgress - toFloat currentBounce

            -- Amplitude for this bounce (decreases exponentially)
            currentAmplitude =
                if currentBounce < bounces then
                    amplitude * (decay ^ toFloat currentBounce)

                else
                    0.0

            -- Use sine wave for smooth bounce that starts and ends at 0
            -- sin(0) = 0, sin(π) = 0
            -- This ensures we're EXACTLY at 1.0 at the start and end of each bounce
            bounceDisplacement =
                currentAmplitude * sin (localT * pi)
        in
        -- Always 1.0 minus the downward displacement
        -- At localT = 0 or 1, displacement = 0, so result = 1.0
        1.0 - bounceDisplacement



-- ============================================================
-- ELASTIC IMPLEMENTATIONS
-- ============================================================


{-| Custom elastic easing with simple strength parameter (0.1-1.0).
Strength controls oscillation intensity.
-}
customElasticOut : Float -> Float -> Float -> Float
customElasticOut velocityFactor strength t =
    let
        clampedStrength =
            clamp 0.1 1.0 strength

        -- More strength = more oscillations and higher amplitude
        elasticity =
            2 + (clampedStrength * 3)

        amplitude =
            (0.5 + (clampedStrength * 0.5)) * velocityFactor

        decay =
            6 + (clampedStrength * 2)
    in
    advancedElasticOutHelper elasticity amplitude decay t


customElasticIn : Float -> Float -> Float -> Float
customElasticIn velocityFactor strength t =
    1.0 - customElasticOut velocityFactor strength (1.0 - t)


customElasticInOut : Float -> ( Float, Float ) -> Float -> Float
customElasticInOut velocityFactor ( strengthIn, strengthOut ) t =
    if t < 0.5 then
        customElasticIn velocityFactor strengthIn (t * 2) * 0.5

    else
        0.5 + (customElasticOut velocityFactor strengthOut ((t - 0.5) * 2) * 0.5)


{-| Advanced elastic easing with full parameter control.
-}
advancedElasticOut : Float -> { elasticity : Float, amplitude : Float, decay : Float } -> Float -> Float
advancedElasticOut velocityFactor params t =
    advancedElasticOutHelper params.elasticity (params.amplitude * velocityFactor) params.decay t


advancedElasticIn : Float -> { elasticity : Float, amplitude : Float, decay : Float } -> Float -> Float
advancedElasticIn velocityFactor params t =
    1.0 - advancedElasticOut velocityFactor params (1.0 - t)


advancedElasticInOut : Float -> { in_ : { elasticity : Float, amplitude : Float, decay : Float }, out : { elasticity : Float, amplitude : Float, decay : Float } } -> Float -> Float
advancedElasticInOut velocityFactor params t =
    if t < 0.5 then
        advancedElasticIn velocityFactor params.in_ (t * 2) * 0.5

    else
        0.5 + (advancedElasticOut velocityFactor params.out ((t - 0.5) * 2) * 0.5)


{-| Helper function for elastic easing with exponential decay and oscillation.
-}
advancedElasticOutHelper : Float -> Float -> Float -> Float -> Float
advancedElasticOutHelper elasticity amplitude decay t =
    if t == 0 then
        0

    else if t == 1 then
        1

    else
        let
            -- Exponential decay
            envelope =
                amplitude * (2 ^ (-decay * t))

            -- Oscillation
            oscillation =
                sin (t * elasticity * 2 * pi)
        in
        1 - (envelope * oscillation)



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

