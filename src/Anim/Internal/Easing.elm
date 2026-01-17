module Anim.Internal.Easing exposing
    ( generateKeyframes
    , toCSS
    , toFunction
    , toWebAnimations
    )

import Anim.Easing exposing (Easing(..))
import Ease as E


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

        BackInAdvanced _ ->
            "linear"

        BackOutAdvanced _ ->
            "linear"

        BackInOutAdvanced _ ->
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

        BackInAdvanced _ ->
            "linear"

        BackOutAdvanced _ ->
            "linear"

        BackInOutAdvanced _ ->
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


toFunction : Float -> Easing -> (Float -> Float)
toFunction durationMs easing =
    let
        velocityFactor =
            1000.0 / durationMs
    in
    case easing |> Debug.log "Easing" of
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

        BackInOutCustom strength ->
            customBackInOut strength

        BackInAdvanced params ->
            advancedBackIn params

        BackOutAdvanced params ->
            advancedBackOut params

        BackInOutAdvanced params ->
            advancedBackInOut params

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

        ElasticInOutCustom strength ->
            customElasticInOut velocityFactor strength

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

        BounceInOutCustom strength ->
            customBounceInOut velocityFactor strength

        BounceInAdvanced params ->
            advancedBounceIn velocityFactor params

        BounceOutAdvanced params ->
            advancedBounceOut velocityFactor params

        BounceInOutAdvanced params ->
            advancedBounceInOut velocityFactor params


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


customBounceInOut : Float -> Float -> Float -> Float
customBounceInOut velocityFactor strength t =
    if t < 0.5 then
        -- First half: BounceIn scaled to 0-0.5
        customBounceIn velocityFactor strength (t * 2) * 0.5

    else
        -- Second half: BounceOut scaled to 0.5-1.0
        0.5 + (customBounceOut velocityFactor strength ((t - 0.5) * 2) * 0.5)


{-| Advanced bounce easing with full parameter control.
-}
advancedBounceOut : Float -> { bounces : Int, amplitude : Float, decay : Float } -> Float -> Float
advancedBounceOut velocityFactor params t =
    advancedBounceOutHelper params.bounces (params.amplitude * velocityFactor) params.decay t


advancedBounceIn : Float -> { bounces : Int, amplitude : Float, decay : Float } -> Float -> Float
advancedBounceIn velocityFactor params t =
    1.0 - advancedBounceOut velocityFactor params (1.0 - t)


advancedBounceInOut : Float -> { bounces : Int, amplitude : Float, decay : Float } -> Float -> Float
advancedBounceInOut velocityFactor params t =
    if t < 0.5 then
        -- First half: BounceIn scaled to 0-0.5
        advancedBounceIn velocityFactor params (t * 2) * 0.5

    else
        -- Second half: BounceOut scaled to 0.5-1.0
        0.5 + (advancedBounceOut velocityFactor params ((t - 0.5) * 2) * 0.5)


{-| Helper function to calculate bounce with given parameters.
The element reaches the endpoint (1.0) before each bounce, then bounces back.
-}
advancedBounceOutHelper : Int -> Float -> Float -> Float -> Float
advancedBounceOutHelper bounceCount amplitude decay t =
    let
        -- Ensure at least 1 bounce
        clampedBounces =
            max 1 bounceCount

        -- Clamp amplitude and decay to reasonable ranges
        clampedAmplitude =
            clamp 0.1 1.0 amplitude

        clampedDecay =
            clamp 0.1 0.9 decay

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
                bounceT * toFloat clampedBounces

            currentBounce =
                floor bounceProgress

            -- Progress within current bounce (0.0 to 1.0)
            -- At 0.0 and 1.0, we should be at rest (displacement = 0)
            localT =
                bounceProgress - toFloat currentBounce

            -- Amplitude for this bounce (decreases exponentially)
            currentAmplitude =
                if currentBounce < clampedBounces then
                    clampedAmplitude * (clampedDecay ^ toFloat currentBounce)

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



{- ELASTIC EASING IMPLEMENTATIONS -}


{-| Custom elastic easing with simple strength parameter (0.1-1.0).
Strength controls oscillation intensity.
-}
customElasticOut : Float -> Float -> Float -> Float
customElasticOut velocityFactor strength t =
    let
        clampedStrength =
            clamp 0.1 1.0 strength

        -- More strength = more oscillations and higher amplitude
        frequency =
            2 + (clampedStrength * 3)

        amplitude =
            (0.5 + (clampedStrength * 0.5)) * velocityFactor

        decay =
            6 + (clampedStrength * 2)
    in
    advancedElasticOutHelper frequency amplitude decay t


customElasticIn : Float -> Float -> Float -> Float
customElasticIn velocityFactor strength t =
    1.0 - customElasticOut velocityFactor strength (1.0 - t)


customElasticInOut : Float -> Float -> Float -> Float
customElasticInOut velocityFactor strength t =
    if t < 0.5 then
        customElasticIn velocityFactor strength (t * 2) * 0.5

    else
        0.5 + (customElasticOut velocityFactor strength ((t - 0.5) * 2) * 0.5)


{-| Advanced elastic easing with full parameter control.
-}
advancedElasticOut : Float -> { frequency : Float, amplitude : Float, decay : Float } -> Float -> Float
advancedElasticOut velocityFactor params t =
    advancedElasticOutHelper params.frequency (params.amplitude * velocityFactor) params.decay t


advancedElasticIn : Float -> { frequency : Float, amplitude : Float, decay : Float } -> Float -> Float
advancedElasticIn velocityFactor params t =
    1.0 - advancedElasticOut velocityFactor params (1.0 - t)


advancedElasticInOut : Float -> { frequency : Float, amplitude : Float, decay : Float } -> Float -> Float
advancedElasticInOut velocityFactor params t =
    if t < 0.5 then
        advancedElasticIn velocityFactor params (t * 2) * 0.5

    else
        0.5 + (advancedElasticOut velocityFactor params ((t - 0.5) * 2) * 0.5)


{-| Helper function for elastic easing with exponential decay and oscillation.
-}
advancedElasticOutHelper : Float -> Float -> Float -> Float -> Float
advancedElasticOutHelper frequency amplitude decay t =
    if t == 0 then
        0

    else if t == 1 then
        1

    else
        let
            clampedFrequency =
                clamp 1 5 frequency

            clampedAmplitude =
                clamp 0.1 2.0 amplitude

            clampedDecay =
                clamp 1 10 decay

            -- Exponential decay
            envelope =
                clampedAmplitude * (2 ^ (-clampedDecay * t))

            -- Oscillation
            oscillation =
                sin (t * clampedFrequency * 2 * pi)
        in
        1 - (envelope * oscillation)



{- BACK EASING IMPLEMENTATIONS -}


{-| Custom back easing with simple strength parameter (0.1-3.0).
Strength controls overshoot amount.
-}
customBackOut : Float -> Float -> Float
customBackOut strength t =
    let
        clampedStrength =
            clamp 0.1 3.0 strength

        -- Map strength to overshoot amount (standard is 1.70158)
        overshoot =
            1.0 + (clampedStrength * 0.70158)
    in
    advancedBackOutHelper overshoot t


customBackIn : Float -> Float -> Float
customBackIn strength t =
    1.0 - customBackOut strength (1.0 - t)


customBackInOut : Float -> Float -> Float
customBackInOut strength t =
    if t < 0.5 then
        customBackIn strength (t * 2) * 0.5

    else
        0.5 + (customBackOut strength ((t - 0.5) * 2) * 0.5)


{-| Advanced back easing with full overshoot control.
-}
advancedBackOut : { overshoot : Float } -> Float -> Float
advancedBackOut params t =
    advancedBackOutHelper params.overshoot t


advancedBackIn : { overshoot : Float } -> Float -> Float
advancedBackIn params t =
    1.0 - advancedBackOut params (1.0 - t)


advancedBackInOut : { overshoot : Float } -> Float -> Float
advancedBackInOut params t =
    if t < 0.5 then
        advancedBackIn params (t * 2) * 0.5

    else
        0.5 + (advancedBackOut params ((t - 0.5) * 2) * 0.5)


{-| Helper function for back easing with configurable overshoot.
-}
advancedBackOutHelper : Float -> Float -> Float
advancedBackOutHelper overshoot t =
    let
        clampedOvershoot =
            clamp 0.5 3.0 overshoot

        s =
            clampedOvershoot

        p =
            t - 1
    in
    p * p * ((s + 1) * p + s) + 1



{- KEYFRAME GENERATION -}


{-| Generate keyframe progress values for complex easings.
Returns a list of 30 progress values (0.0 to 1.0) with the easing function applied.
This allows WAAPI to use accurate easing through linear interpolation between keyframes.
-}
generateKeyframes : Easing -> Float -> List Float
generateKeyframes easing durationMs =
    let
        keyframeCount =
            30

        -- Calculate velocity factor for physics-based easings
        -- Baseline: 1 second (1000ms) = normal velocity
        -- Faster (500ms) = 2x velocity factor = bigger bounces/oscillations
        -- Slower (2000ms) = 0.5x velocity factor = smaller bounces/oscillations
        velocityFactor =
            1000.0 / durationMs
    in
    case easing of
        -- Custom bounce easings get special treatment to ensure they hit 1.0 at bounce boundaries
        BounceOutCustom strength ->
            let
                clampedStrength =
                    clamp 0.1 1.0 strength

                firstBounceAmplitude =
                    (0.15 + (clampedStrength * clampedStrength * 0.75)) * velocityFactor

                coefficientOfRestitution =
                    0.5 + (clampedStrength * 0.25)

                bounces =
                    let
                        minVisibleHeight =
                            0.02

                        calculateBounceCount current count =
                            if current < minVisibleHeight || count >= 6 then
                                count

                            else
                                calculateBounceCount (current * coefficientOfRestitution * coefficientOfRestitution) (count + 1)
                    in
                    max 1 (calculateBounceCount firstBounceAmplitude 0)

                -- Helper: Create bounce-out keyframes (bounces at end, around 1.0)
                createBounceOutKeyframes bounceCnt amp cor =
                    let
                        allBounceFrames =
                            generateBounceKeyframes bounceCnt amp cor

                        firstPeakIndex =
                            allBounceFrames
                                |> List.indexedMap Tuple.pair
                                |> List.filter (\( _, v ) -> v >= 0.99)
                                |> List.head
                                |> Maybe.map Tuple.first
                                |> Maybe.withDefault 10
                    in
                    List.drop (firstPeakIndex + 1) allBounceFrames

                -- Velocity-aware transition frame count
                transitionFrameCount =
                    round (30.0 / velocityFactor) |> clamp 15 60

                -- Helper: Create QuartIn transition (0->1, start slow, accelerate)
                createBounceOutTransition =
                    List.range 0 (transitionFrameCount - 1)
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / toFloat (transitionFrameCount - 1)

                                    easedT =
                                        t * t * t * t
                                in
                                easedT
                            )

                bounceKeyframes =
                    createBounceOutKeyframes bounces firstBounceAmplitude coefficientOfRestitution
            in
            createBounceOutTransition ++ bounceKeyframes

        BounceInCustom strength ->
            let
                clampedStrength =
                    clamp 0.1 1.0 strength

                firstBounceAmplitude =
                    (0.15 + (clampedStrength * clampedStrength * 0.75)) * velocityFactor

                coefficientOfRestitution =
                    0.5 + (clampedStrength * 0.25)

                bounces =
                    let
                        minVisibleHeight =
                            0.02

                        calculateBounceCount current count =
                            if current < minVisibleHeight || count >= 6 then
                                count

                            else
                                calculateBounceCount (current * coefficientOfRestitution * coefficientOfRestitution) (count + 1)
                    in
                    max 1 (calculateBounceCount firstBounceAmplitude 0)

                -- Helper: Create bounce-in keyframes (bounces at start, around 0)
                createBounceInKeyframes bounceCnt amp cor =
                    let
                        allBounceFrames =
                            generateBounceKeyframes bounceCnt amp cor

                        firstPeakIndex =
                            allBounceFrames
                                |> List.indexedMap Tuple.pair
                                |> List.filter (\( _, v ) -> v >= 0.99)
                                |> List.head
                                |> Maybe.map Tuple.first
                                |> Maybe.withDefault 10

                        bouncesOnly =
                            allBounceFrames
                                |> List.drop (firstPeakIndex + 1)
                                |> List.reverse
                                |> List.map (\v -> 1.0 - v)
                    in
                    bouncesOnly

                -- Velocity-aware transition frame count
                transitionFrameCount =
                    round (30.0 / velocityFactor) |> clamp 15 60

                -- Helper: Create QuartOut transition (0->1, start fast, decelerate)
                createBounceInTransition =
                    List.range 0 (transitionFrameCount - 1)
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / toFloat (transitionFrameCount - 1)

                                    invT =
                                        1.0 - t

                                    easedT =
                                        1.0 - (invT * invT * invT * invT)
                                in
                                easedT
                            )

                bounceKeyframes =
                    createBounceInKeyframes bounces firstBounceAmplitude coefficientOfRestitution

                allKeyframes =
                    bounceKeyframes ++ createBounceInTransition
            in
            allKeyframes

        BounceInOutCustom strength ->
            let
                clampedStrength =
                    clamp 0.1 1.0 strength

                firstBounceAmplitude =
                    (0.15 + (clampedStrength * clampedStrength * 0.75)) * velocityFactor

                coefficientOfRestitution =
                    0.5 + (clampedStrength * 0.25)

                bounces =
                    let
                        minVisibleHeight =
                            0.02

                        calculateBounceCount current count =
                            if current < minVisibleHeight || count >= 6 then
                                count

                            else
                                calculateBounceCount (current * coefficientOfRestitution * coefficientOfRestitution) (count + 1)
                    in
                    max 1 (calculateBounceCount firstBounceAmplitude 0)

                -- Helper: Create bounce-in keyframes (bounces at start, around 0)
                createBounceInKeyframes bounceCnt amp cor =
                    let
                        allBounceFrames =
                            generateBounceKeyframes bounceCnt amp cor

                        firstPeakIndex =
                            allBounceFrames
                                |> List.indexedMap Tuple.pair
                                |> List.filter (\( _, v ) -> v >= 0.99)
                                |> List.head
                                |> Maybe.map Tuple.first
                                |> Maybe.withDefault 10

                        bouncesOnly =
                            allBounceFrames
                                |> List.drop (firstPeakIndex + 1)
                                |> List.reverse
                                |> List.map (\v -> 1.0 - v)
                    in
                    bouncesOnly

                -- Helper: Create bounce-out keyframes (bounces at end, around 1.0)
                createBounceOutKeyframes bounceCnt amp cor =
                    let
                        allBounceFrames =
                            generateBounceKeyframes bounceCnt amp cor

                        firstPeakIndex =
                            allBounceFrames
                                |> List.indexedMap Tuple.pair
                                |> List.filter (\( _, v ) -> v >= 0.99)
                                |> List.head
                                |> Maybe.map Tuple.first
                                |> Maybe.withDefault 10
                    in
                    List.drop (firstPeakIndex + 1) allBounceFrames

                -- Helper: Create linear transition matching bounce velocities
                -- Transitions from near 0 to near 1 with velocity matching the bounces
                createBounceInOutTransition bounceInFrames bounceOutFrames =
                    let
                        -- Start very close to 0 for smooth continuation
                        startValue =
                            0.0

                        -- End very close to 1 (just before the bounce-out frames start)
                        endValue =
                            1.0

                        -- Calculate velocity from last few bounce-in frames
                        bounceInVelocity =
                            let
                                lastFrames =
                                    List.reverse bounceInFrames |> List.take 5

                                first =
                                    List.head lastFrames |> Maybe.withDefault 0

                                last =
                                    List.reverse lastFrames |> List.head |> Maybe.withDefault 0
                            in
                            abs (first - last) / 4.0

                        -- Calculate velocity from first few bounce-out frames
                        bounceOutVelocity =
                            let
                                firstFrames =
                                    List.take 5 bounceOutFrames

                                first =
                                    List.head firstFrames |> Maybe.withDefault 1

                                last =
                                    List.drop 4 firstFrames |> List.head |> Maybe.withDefault 1
                            in
                            abs (first - last) / 4.0

                        -- Use average velocity to determine frame count
                        avgVelocity =
                            (bounceInVelocity + bounceOutVelocity) / 2.0

                        -- Distance to travel
                        distance =
                            abs (endValue - startValue)

                        -- Calculate frame count based on velocity (fewer frames = faster)
                        -- Reduced frame count range to match bounce speed better
                        frameCount =
                            if avgVelocity > 0 then
                                round (distance / (avgVelocity * 2.0)) |> clamp 5 15

                            else
                                10
                    in
                    -- Create linear interpolation
                    List.range 0 (frameCount - 1)
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / toFloat (frameCount - 1)
                                in
                                startValue + (t * (endValue - startValue))
                            )

                bounceInKeyframes =
                    createBounceInKeyframes bounces firstBounceAmplitude coefficientOfRestitution

                bounceOutKeyframes =
                    createBounceOutKeyframes bounces firstBounceAmplitude coefficientOfRestitution

                transitionKeyframes =
                    createBounceInOutTransition bounceInKeyframes bounceOutKeyframes

                allKeyframes =
                    bounceInKeyframes ++ transitionKeyframes ++ bounceOutKeyframes
            in
            allKeyframes

        BounceOutAdvanced params ->
            let
                -- Apply velocity scaling to amplitude
                scaledAmplitude =
                    params.amplitude * velocityFactor

                -- Velocity-aware transition frame count
                transitionFrameCount =
                    round (30.0 / velocityFactor) |> clamp 15 60

                -- Helper: Create QuartIn transition (0->1, start slow, accelerate)
                createBounceOutTransition =
                    List.range 0 (transitionFrameCount - 1)
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / toFloat (transitionFrameCount - 1)

                                    easedT =
                                        t * t * t * t
                                in
                                easedT
                            )

                transitionKeyframes =
                    createBounceOutTransition

                -- Generate ONLY the bounce oscillations (no approach)
                bounceKeyframes =
                    generateBounceOscillations params.bounces scaledAmplitude params.decay

                allKeyframes =
                    transitionKeyframes ++ bounceKeyframes
            in
            allKeyframes

        BounceInAdvanced params ->
            let
                -- Apply velocity scaling to amplitude
                scaledAmplitude =
                    params.amplitude * velocityFactor

                -- Generate small bounces at start that settle to 0
                bounceKeyframes =
                    generateBounceOscillations params.bounces scaledAmplitude params.decay
                        |> List.map (\v -> 1.0 - v)
                        |> List.reverse

                -- Helper: Create QuartOut transition (0->1, start fast, decelerate)
                createBounceInTransition =
                    List.range 0 29
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / 29.0

                                    invT =
                                        1.0 - t

                                    easedT =
                                        1.0 - (invT * invT * invT * invT)
                                in
                                easedT
                            )

                transitionKeyframes =
                    createBounceInTransition

                allKeyframes =
                    bounceKeyframes ++ transitionKeyframes
            in
            allKeyframes

        BounceInOutAdvanced params ->
            let
                -- Apply velocity scaling to amplitude
                scaledAmplitude =
                    params.amplitude * velocityFactor

                -- Helper: Create bounce-in keyframes (bounces at start, around 0)
                createBounceInKeyframes bounceCnt amp dec =
                    generateBounceOscillations bounceCnt amp dec
                        |> List.map (\v -> 1.0 - v)
                        |> List.reverse

                -- Helper: Create bounce-out keyframes (bounces at end, around 1.0)
                createBounceOutKeyframes bounceCnt amp dec =
                    generateBounceOscillations bounceCnt amp dec

                -- Helper: Create transition matching bounce velocities
                createBounceInOutTransition bounceInFrames bounceOutFrames =
                    let
                        startValue =
                            0.0

                        endValue =
                            1.0

                        -- Calculate velocity from last few bounce-in frames
                        bounceInVelocity =
                            let
                                lastFrames =
                                    List.reverse bounceInFrames |> List.take 5

                                first =
                                    List.head lastFrames |> Maybe.withDefault 0

                                last =
                                    List.reverse lastFrames |> List.head |> Maybe.withDefault 0
                            in
                            abs (first - last) / 4.0

                        -- Calculate velocity from first few bounce-out frames
                        bounceOutVelocity =
                            let
                                firstFrames =
                                    List.take 5 bounceOutFrames

                                first =
                                    List.head firstFrames |> Maybe.withDefault 1

                                last =
                                    List.drop 4 firstFrames |> List.head |> Maybe.withDefault 1
                            in
                            abs (first - last) / 4.0

                        avgVelocity =
                            (bounceInVelocity + bounceOutVelocity) / 2.0

                        distance =
                            abs (endValue - startValue)

                        frameCount =
                            if avgVelocity > 0 then
                                round (distance / (avgVelocity * 2.0)) |> clamp 5 15

                            else
                                10
                    in
                    List.range 0 (frameCount - 1)
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / toFloat (frameCount - 1)
                                in
                                startValue + (t * (endValue - startValue))
                            )

                bounceInKeyframes =
                    createBounceInKeyframes params.bounces scaledAmplitude params.decay

                bounceOutKeyframes =
                    createBounceOutKeyframes params.bounces scaledAmplitude params.decay

                transitionKeyframes =
                    createBounceInOutTransition bounceInKeyframes bounceOutKeyframes

                allKeyframes =
                    bounceInKeyframes
                        ++ transitionKeyframes
                        ++ bounceOutKeyframes
            in
            allKeyframes

        ElasticOutCustom strength ->
            let
                clampedStrength =
                    clamp 0.1 1.0 strength

                -- More strength = more oscillations and higher amplitude
                frequency =
                    2 + (clampedStrength * 3)

                amplitude =
                    (0.5 + (clampedStrength * 0.5)) * velocityFactor

                decay =
                    6 + (clampedStrength * 2)

                -- Velocity-aware transition frame count
                transitionFrameCount =
                    round (30.0 / velocityFactor) |> clamp 15 60

                -- Helper: Create QuartIn transition (0->1, start slow, accelerate)
                createElasticOutTransition =
                    List.range 0 (transitionFrameCount - 1)
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / toFloat (transitionFrameCount - 1)

                                    easedT =
                                        t * t * t * t
                                in
                                easedT
                            )

                transitionKeyframes =
                    createElasticOutTransition

                -- Generate ONLY the elastic oscillations
                oscillationKeyframes =
                    generateElasticOscillations frequency amplitude decay

                allKeyframes =
                    transitionKeyframes ++ oscillationKeyframes
            in
            allKeyframes

        ElasticInCustom strength ->
            let
                clampedStrength =
                    clamp 0.1 1.0 strength

                -- More strength = more oscillations and higher amplitude
                frequency =
                    2 + (clampedStrength * 3)

                amplitude =
                    (0.5 + (clampedStrength * 0.5)) * velocityFactor

                decay =
                    6 + (clampedStrength * 2)

                -- Generate ONLY the elastic oscillations (reversed for In)
                oscillationKeyframes =
                    generateElasticOscillations frequency amplitude decay
                        |> List.reverse
                        |> List.map (\v -> 1.0 - v)

                -- Velocity-aware transition frame count
                transitionFrameCount =
                    round (30.0 / velocityFactor) |> clamp 15 60

                -- Helper: Create QuartOut transition (0->1, fast then decelerate)
                createElasticInTransition =
                    List.range 0 (transitionFrameCount - 1)
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / toFloat (transitionFrameCount - 1)

                                    invT =
                                        1.0 - t

                                    easedT =
                                        1.0 - (invT * invT * invT * invT)
                                in
                                easedT
                            )

                transitionKeyframes =
                    createElasticInTransition

                allKeyframes =
                    oscillationKeyframes ++ transitionKeyframes
            in
            allKeyframes

        ElasticInOutCustom strength ->
            let
                clampedStrength =
                    clamp 0.1 1.0 strength

                -- More strength = more oscillations and higher amplitude
                frequency =
                    2 + (clampedStrength * 3)

                amplitude =
                    (0.5 + (clampedStrength * 0.5)) * velocityFactor

                decay =
                    6 + (clampedStrength * 2)

                -- In portion: Use same oscillations as ElasticIn (reversed and inverted)
                elasticInOscillations =
                    generateElasticOscillations frequency amplitude decay
                        |> List.reverse
                        |> List.map (\v -> 1.0 - v)

                -- Out portion: Use same oscillations as ElasticOut
                elasticOutOscillations =
                    generateElasticOscillations frequency amplitude decay

                -- Calculate velocities at connection points
                -- Last In oscillation: approach 0 from below (negative to 0)
                lastInFrames =
                    List.drop (List.length elasticInOscillations - 2) elasticInOscillations

                lastInVelocity =
                    case ( List.head lastInFrames, List.head (List.drop 1 lastInFrames) ) of
                        ( Just v1, Just v2 ) ->
                            v2 - v1

                        _ ->
                            0.02

                -- First Out oscillation: leave 1 going negative initially
                firstOutFrames =
                    List.take 2 elasticOutOscillations

                firstOutVelocity =
                    case ( List.head firstOutFrames, List.head (List.drop 1 firstOutFrames) ) of
                        ( Just v1, Just v2 ) ->
                            v2 - v1

                        _ ->
                            -0.02

                -- Transition needs to smoothly connect from velocity matching last In to first Out
                -- Linear transition since velocities match
                transitionFrameCount =
                    round (30.0 / velocityFactor) |> clamp 15 60

                transitionKeyframes =
                    List.range 0 (transitionFrameCount - 1)
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / toFloat (transitionFrameCount - 1)
                                in
                                t
                            )

                allKeyframes =
                    elasticInOscillations
                        ++ transitionKeyframes
                        ++ elasticOutOscillations

                _ =
                    Debug.log "ElasticInOutCustom"
                        { inFrames = List.length elasticInOscillations
                        , transitionFrames = List.length transitionKeyframes
                        , outFrames = List.length elasticOutOscillations
                        , lastInVelocity = lastInVelocity
                        , firstOutVelocity = firstOutVelocity
                        , lastInValues = List.drop (List.length elasticInOscillations - 3) elasticInOscillations
                        , firstOutValues = List.take 3 elasticOutOscillations
                        }
            in
            allKeyframes

        ElasticOutAdvanced params ->
            let
                -- Apply velocity scaling to amplitude
                scaledAmplitude =
                    params.amplitude * velocityFactor

                -- Velocity-aware transition frame count
                transitionFrameCount =
                    round (30.0 / velocityFactor) |> clamp 15 60

                -- Helper: Create QuartIn transition (0->1, start slow, accelerate)
                createElasticOutTransition =
                    List.range 0 (transitionFrameCount - 1)
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / toFloat (transitionFrameCount - 1)

                                    easedT =
                                        t * t * t * t
                                in
                                easedT
                            )

                transitionKeyframes =
                    createElasticOutTransition

                -- Generate ONLY the elastic oscillations
                oscillationKeyframes =
                    generateElasticOscillations params.frequency scaledAmplitude params.decay

                allKeyframes =
                    transitionKeyframes ++ oscillationKeyframes
            in
            allKeyframes

        ElasticInAdvanced params ->
            let
                -- Apply velocity scaling to amplitude
                scaledAmplitude =
                    params.amplitude * velocityFactor

                -- Generate ONLY the elastic oscillations (reversed for In)
                oscillationKeyframes =
                    generateElasticOscillations params.frequency scaledAmplitude params.decay
                        |> List.reverse
                        |> List.map (\v -> 1.0 - v)

                -- Velocity-aware transition frame count
                transitionFrameCount =
                    round (30.0 / velocityFactor) |> clamp 15 60

                -- Helper: Create QuartOut transition (0->1, fast then decelerate)
                createElasticInTransition =
                    List.range 0 (transitionFrameCount - 1)
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / toFloat (transitionFrameCount - 1)

                                    invT =
                                        1.0 - t

                                    easedT =
                                        1.0 - (invT * invT * invT * invT)
                                in
                                easedT
                            )

                transitionKeyframes =
                    createElasticInTransition

                allKeyframes =
                    oscillationKeyframes ++ transitionKeyframes
            in
            allKeyframes

        ElasticInOutAdvanced params ->
            let
                -- Apply velocity scaling to amplitude
                scaledAmplitude =
                    params.amplitude * velocityFactor

                -- In portion: Use same oscillations as ElasticIn (reversed and inverted)
                elasticInOscillations =
                    generateElasticOscillations params.frequency scaledAmplitude params.decay
                        |> List.reverse
                        |> List.map (\v -> 1.0 - v)

                -- Out portion: Use same oscillations as ElasticOut
                elasticOutOscillations =
                    generateElasticOscillations params.frequency scaledAmplitude params.decay

                -- Calculate velocities at connection points
                -- Last In oscillation: approach 0 from below (negative to 0)
                lastInFrames =
                    List.drop (List.length elasticInOscillations - 2) elasticInOscillations

                lastInVelocity =
                    case ( List.head lastInFrames, List.head (List.drop 1 lastInFrames) ) of
                        ( Just v1, Just v2 ) ->
                            v2 - v1

                        _ ->
                            0.02

                -- First Out oscillation: leave 1 going negative initially
                firstOutFrames =
                    List.take 2 elasticOutOscillations

                firstOutVelocity =
                    case ( List.head firstOutFrames, List.head (List.drop 1 firstOutFrames) ) of
                        ( Just v1, Just v2 ) ->
                            v2 - v1

                        _ ->
                            -0.02

                -- Transition needs to smoothly connect from velocity matching last In to first Out
                -- Linear transition since velocities match
                transitionFrameCount =
                    round (30.0 / velocityFactor) |> clamp 15 60

                transitionKeyframes =
                    List.range 0 (transitionFrameCount - 1)
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / toFloat (transitionFrameCount - 1)
                                in
                                t
                            )

                allKeyframes =
                    elasticInOscillations
                        ++ transitionKeyframes
                        ++ elasticOutOscillations

                _ =
                    Debug.log "ElasticInOut"
                        { inFrames = List.length elasticInOscillations
                        , transitionFrames = List.length transitionKeyframes
                        , outFrames = List.length elasticOutOscillations
                        , lastInVelocity = lastInVelocity
                        , firstOutVelocity = firstOutVelocity
                        , lastInValues = List.drop (List.length elasticInOscillations - 3) elasticInOscillations
                        , firstOutValues = List.take 3 elasticOutOscillations
                        }
            in
            allKeyframes

        BackOutCustom strength ->
            let
                easingFunction =
                    customBackOut strength
            in
            List.range 0 (keyframeCount - 1)
                |> List.map (\i -> easingFunction (toFloat i / toFloat (keyframeCount - 1)))

        BackInCustom strength ->
            let
                easingFunction =
                    customBackIn strength
            in
            List.range 0 (keyframeCount - 1)
                |> List.map (\i -> easingFunction (toFloat i / toFloat (keyframeCount - 1)))

        BackInOutCustom strength ->
            let
                easingFunction =
                    customBackInOut strength
            in
            List.range 0 (keyframeCount - 1)
                |> List.map (\i -> easingFunction (toFloat i / toFloat (keyframeCount - 1)))

        BackOutAdvanced params ->
            let
                easingFunction =
                    advancedBackOut params
            in
            List.range 0 (keyframeCount - 1)
                |> List.map (\i -> easingFunction (toFloat i / toFloat (keyframeCount - 1)))

        BackInAdvanced params ->
            let
                easingFunction =
                    advancedBackIn params
            in
            List.range 0 (keyframeCount - 1)
                |> List.map (\i -> easingFunction (toFloat i / toFloat (keyframeCount - 1)))

        BackInOutAdvanced params ->
            let
                easingFunction =
                    advancedBackInOut params
            in
            List.range 0 (keyframeCount - 1)
                |> List.map (\i -> easingFunction (toFloat i / toFloat (keyframeCount - 1)))

        _ ->
            -- Standard approach: sample the easing function
            let
                easingFunction =
                    toFunction durationMs easing

                linearProgress i =
                    toFloat i / toFloat (keyframeCount - 1)

                keyframeValues =
                    List.range 0 (keyframeCount - 1)
                        |> List.map (\i -> easingFunction (linearProgress i))
            in
            keyframeValues


{-| Generate keyframes for bounce effect with physics-based calculations.
Uses coefficient of restitution to calculate natural bounce heights through energy loss.

Parameters:

  - bounces: Number of bounces
  - firstAmplitude: Height of first bounce (0.1-1.0)
  - coefficientOfRestitution: Energy retention per bounce (0.5-0.7)
      - Each bounce amplitude = previous amplitude \* CoR²
      - CoR² because energy is lost on both downward and upward motion

-}
generateBounceKeyframes : Int -> Float -> Float -> List Float
generateBounceKeyframes bounces firstAmplitude coefficientOfRestitution =
    let
        -- Clamp parameters
        clampedBounces =
            max 1 bounces

        clampedAmplitude =
            clamp 0.1 1.0 firstAmplitude

        clampedCoR =
            clamp 0.5 0.7 coefficientOfRestitution

        -- Phase 1: Approach - inverse correlation with bounce strength
        -- Lower bounces = smaller/slower, need more approach time for balance
        -- Higher bounces = bigger/faster, can use shorter approach
        -- Approach gets 25-45% for weak bounces, 15-25% for strong bounces
        approachRatio =
            0.45 - (clampedAmplitude * 0.2)

        approachFrames =
            max 3 (round (approachRatio * 30))

        -- Generate approach keyframes using cubic-in for acceleration
        -- Starts slow, speeds up dramatically towards endpoint (like gravity)
        approach =
            List.range 0 (approachFrames - 1)
                |> List.map
                    (\i ->
                        let
                            t =
                                toFloat i / toFloat (approachFrames - 1)

                            -- CubicIn: starts slow, accelerates
                            progress =
                                t * t * t
                        in
                        progress
                    )

        -- Physics: Calculate bounce amplitudes using coefficient of restitution
        -- Each bounce: amplitude_n = amplitude_0 * CoR^(2n)
        -- CoR² because energy loss occurs on impact (downward) and rebound (upward)
        bounceAmplitudes =
            List.range 0 (clampedBounces - 1)
                |> List.map
                    (\i ->
                        let
                            energyLossFactor =
                                clampedCoR ^ (2 * toFloat i)
                        in
                        clampedAmplitude * energyLossFactor
                    )

        -- Physics: Time for each bounce proportional to sqrt(height)
        -- From gravitational physics: t ∝ √h
        totalBounceTime =
            List.map sqrt bounceAmplitudes |> List.sum

        totalBounceFrames =
            30

        bounces_ =
            List.indexedMap
                (\bounceIndex bounceAmplitude ->
                    let
                        bounceTime =
                            sqrt bounceAmplitude

                        framesForThisBounce =
                            max 6 (round (bounceTime / totalBounceTime * toFloat totalBounceFrames))

                        bounceFrames =
                            List.range 0 framesForThisBounce
                                |> List.map
                                    (\frameIndex ->
                                        if frameIndex == 0 && bounceIndex > 0 then
                                            -- Start of non-first bounce: explicit 1.0
                                            1.0

                                        else if frameIndex == 0 && bounceIndex == 0 then
                                            -- Start of first bounce: skip (no boundary yet)
                                            -999.0

                                        else if frameIndex == framesForThisBounce && bounceIndex == clampedBounces - 1 then
                                            -- End of last bounce: explicit 1.0
                                            1.0

                                        else if frameIndex == framesForThisBounce then
                                            -- End of non-last bounce: skip (next bounce starts with 1.0)
                                            -999.0

                                        else
                                            let
                                                localT =
                                                    toFloat frameIndex / toFloat framesForThisBounce

                                                -- Quadratic curve: slow at endpoints, fast in middle
                                                centered =
                                                    (localT - 0.5) * 2

                                                easedProgress =
                                                    1.0 - (centered * centered)

                                                displacement =
                                                    bounceAmplitude * easedProgress
                                            in
                                            1.0 - displacement
                                    )
                                |> List.filter (\v -> v /= -999.0)
                    in
                    bounceFrames
                )
                bounceAmplitudes
                |> List.concat
    in
    approach ++ bounces_


{-| Generate ONLY the bounce oscillations around 1.0, without the approach phase.
Used for BounceOut/BounceIn Advanced where we already have a separate transition.
-}
generateBounceOscillations : Int -> Float -> Float -> List Float
generateBounceOscillations bounces firstAmplitude coefficientOfRestitution =
    let
        -- Clamp parameters
        clampedBounces =
            max 1 bounces

        clampedAmplitude =
            clamp 0.1 1.0 firstAmplitude

        clampedCoR =
            clamp 0.5 0.7 coefficientOfRestitution

        -- Physics: Calculate bounce amplitudes using coefficient of restitution
        bounceAmplitudes =
            List.range 0 (clampedBounces - 1)
                |> List.map
                    (\i ->
                        let
                            energyLossFactor =
                                clampedCoR ^ (2 * toFloat i)
                        in
                        clampedAmplitude * energyLossFactor
                    )

        -- Time for each bounce proportional to sqrt(height)
        totalBounceTime =
            List.map sqrt bounceAmplitudes |> List.sum

        totalBounceFrames =
            52

        bounces_ =
            List.indexedMap
                (\bounceIndex bounceAmplitude ->
                    let
                        bounceTime =
                            sqrt bounceAmplitude

                        framesForThisBounce =
                            max 6 (round (bounceTime / totalBounceTime * toFloat totalBounceFrames))

                        bounceFrames =
                            List.range 0 framesForThisBounce
                                |> List.map
                                    (\frameIndex ->
                                        if frameIndex == 0 && bounceIndex > 0 then
                                            -- Start of non-first bounce: explicit 1.0
                                            1.0

                                        else if frameIndex == 0 && bounceIndex == 0 then
                                            -- Start of first bounce: skip (no boundary yet)
                                            -999.0

                                        else if frameIndex == framesForThisBounce && bounceIndex == clampedBounces - 1 then
                                            -- End of last bounce: explicit 1.0
                                            1.0

                                        else if frameIndex == framesForThisBounce then
                                            -- End of non-last bounce: skip (next bounce starts with 1.0)
                                            -999.0

                                        else
                                            let
                                                localT =
                                                    toFloat frameIndex / toFloat framesForThisBounce

                                                -- Quadratic curve: slow at endpoints, fast in middle
                                                centered =
                                                    (localT - 0.5) * 2

                                                easedProgress =
                                                    1.0 - (centered * centered)

                                                displacement =
                                                    bounceAmplitude * easedProgress
                                            in
                                            1.0 - displacement
                                    )
                                |> List.filter (\v -> v /= -999.0)
                    in
                    bounceFrames
                )
                bounceAmplitudes
                |> List.concat
    in
    bounces_


{-| Generate ONLY elastic oscillations (no transition phase) for use with separate transition keyframes.
Returns keyframes that oscillate around 1.0 with exponential decay.
-}
generateElasticOscillations : Float -> Float -> Float -> List Float
generateElasticOscillations frequency amplitude decay =
    let
        clampedFrequency =
            clamp 1 5 frequency

        clampedAmplitude =
            clamp 0.1 2.0 amplitude

        clampedDecay =
            clamp 1 10 decay

        -- Calculate number of visible oscillation cycles based on decay
        minVisibleAmplitude =
            0.01

        visibleDuration =
            if clampedAmplitude > minVisibleAmplitude then
                logBase 2 (minVisibleAmplitude / clampedAmplitude) / -clampedDecay

            else
                0.0

        -- Total oscillation cycles
        totalCycles =
            round (clampedFrequency * visibleDuration)
                |> max 3
                |> min 12

        -- Calculate amplitude for each oscillation cycle (exponentially decaying)
        cycleAmplitudes =
            List.range 0 (totalCycles - 1)
                |> List.map
                    (\cycleIndex ->
                        let
                            -- Time at the start of this cycle
                            cycleTime =
                                toFloat cycleIndex / clampedFrequency

                            -- Envelope amplitude at this time
                            cycleAmplitude =
                                clampedAmplitude * (2 ^ (-clampedDecay * cycleTime))
                        in
                        cycleAmplitude
                    )

        -- Fixed frames per cycle for evenly spaced peaks and constant velocity
        -- Only amplitude varies between cycles, not timing
        framesPerCycle =
            26

        -- Generate frames for each cycle
        allFrames =
            List.indexedMap
                (\cycleIndex cycleAmplitude ->
                    let
                        -- Fixed frames per cycle for constant velocity
                        framesForCycle =
                            framesPerCycle

                        cycleFrames =
                            List.range 0 framesForCycle
                                |> List.map
                                    (\frameIndex ->
                                        let
                                            -- Local t within this cycle (0 to 1)
                                            localT =
                                                toFloat frameIndex / toFloat framesForCycle

                                            -- Global time
                                            globalTime =
                                                (toFloat cycleIndex + localT) / clampedFrequency

                                            -- Envelope at this time
                                            envelope =
                                                clampedAmplitude * (2 ^ (-clampedDecay * globalTime))

                                            -- Sine wave for this cycle
                                            -- Negative sine so it goes negative first (for proper ElasticIn direction)
                                            oscillation =
                                                -(sin (localT * 2 * pi))

                                            value =
                                                1 - (envelope * oscillation)
                                        in
                                        value
                                    )
                    in
                    cycleFrames
                )
                cycleAmplitudes
                |> List.concat

        _ =
            Debug.log "ElasticOscillations"
                { totalCycles = totalCycles
                , firstCycle = List.head cycleAmplitudes
                , lastCycle = List.reverse cycleAmplitudes |> List.head
                , first5Frames = List.take 5 allFrames
                , last5Frames = List.drop (List.length allFrames - 5) allFrames
                , totalFrames = List.length allFrames
                }
    in
    allFrames


{-| Generate elastic oscillations that settle at 0.0 (for ElasticIn).
These oscillate around 0 and end approaching from below (from negative peak).
-}
generateElasticOscillationsToZero : Float -> Float -> Float -> List Float
generateElasticOscillationsToZero frequency amplitude decay =
    let
        clampedFrequency =
            clamp 1 5 frequency

        clampedAmplitude =
            clamp 0.1 2.0 amplitude

        clampedDecay =
            clamp 1 10 decay

        -- Calculate number of visible oscillation cycles based on decay
        minVisibleAmplitude =
            0.01

        visibleDuration =
            if clampedAmplitude > minVisibleAmplitude then
                logBase 2 (minVisibleAmplitude / clampedAmplitude) / -clampedDecay

            else
                0.0

        -- Total oscillation cycles
        totalCycles =
            round (clampedFrequency * visibleDuration)
                |> max 3
                |> min 12

        -- Calculate amplitude for each oscillation cycle (exponentially decaying)
        cycleAmplitudes =
            List.range 0 (totalCycles - 1)
                |> List.map
                    (\cycleIndex ->
                        let
                            -- Time at the start of this cycle
                            cycleTime =
                                toFloat cycleIndex / clampedFrequency

                            -- Envelope amplitude at this time
                            cycleAmplitude =
                                clampedAmplitude * (2 ^ (-clampedDecay * cycleTime))
                        in
                        cycleAmplitude
                    )

        -- Fixed frames per cycle for evenly spaced peaks and constant velocity
        -- Only amplitude varies between cycles, not timing
        framesPerCycle =
            26

        -- Generate frames for each cycle
        allFrames =
            List.indexedMap
                (\cycleIndex cycleAmplitude ->
                    let
                        -- Fixed frames per cycle for constant velocity
                        framesForCycle =
                            framesPerCycle

                        cycleFrames =
                            List.range 0 framesForCycle
                                |> List.map
                                    (\frameIndex ->
                                        let
                                            -- Local t within this cycle (0 to 1)
                                            localT =
                                                toFloat frameIndex / toFloat framesForCycle

                                            -- Global time
                                            globalTime =
                                                (toFloat cycleIndex + localT) / clampedFrequency

                                            -- Envelope at this time
                                            envelope =
                                                clampedAmplitude * (2 ^ (-clampedDecay * globalTime))

                                            -- Sine wave for this cycle (oscillate around 0)
                                            oscillation =
                                                sin (localT * 2 * pi)

                                            value =
                                                envelope * oscillation
                                        in
                                        value
                                    )
                    in
                    cycleFrames
                )
                cycleAmplitudes
                |> List.concat

        _ =
            Debug.log "ElasticToZero"
                { totalCycles = totalCycles
                , firstCycle = List.head cycleAmplitudes
                , lastCycle = List.reverse cycleAmplitudes |> List.head
                , first5Frames = List.take 5 allFrames
                , last5Frames = List.drop (List.length allFrames - 5) allFrames
                , totalFrames = List.length allFrames
                }
    in
    allFrames
