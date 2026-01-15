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
        Bezier p1x p1y p2x p2y ->
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

        ElasticIn ->
            "cubic-bezier(0.55, 0.055, 0.675, 0.19)"

        ElasticOut ->
            "cubic-bezier(0.175, 0.885, 0.32, 1.275)"

        ElasticInOut ->
            "cubic-bezier(0.445, 0.05, 0.55, 0.95)"

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

        Custom value ->
            value


toWebAnimations : Easing -> String
toWebAnimations easing =
    case easing of
        Bezier p1x p1y p2x p2y ->
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

        ElasticIn ->
            "linear"

        ElasticOut ->
            "linear"

        ElasticInOut ->
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

        Custom value ->
            value


toFunction : Easing -> (Float -> Float)
toFunction easing =
    case easing of
        Bezier p1x p1y p2x p2y ->
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

        ElasticIn ->
            E.inElastic

        ElasticOut ->
            E.outElastic

        ElasticInOut ->
            E.inOutElastic

        BounceIn ->
            E.inBounce

        BounceOut ->
            E.outBounce

        BounceInOut ->
            E.inOutBounce

        BounceInCustom strength ->
            customBounceIn strength

        BounceOutCustom strength ->
            customBounceOut strength

        BounceInOutCustom strength ->
            customBounceInOut strength

        BounceInAdvanced params ->
            advancedBounceIn params

        BounceOutAdvanced params ->
            advancedBounceOut params

        BounceInOutAdvanced params ->
            advancedBounceInOut params

        Custom _ ->
            -- TODO: Handle custom easing functions properly
            E.inOutQuad


{-| Custom bounce easing with simple strength parameter (0.0-1.0).
Strength controls bounce intensity: 0.2 = soft, 0.5 = medium, 0.8 = hard.
-}
customBounceOut : Float -> Float -> Float
customBounceOut strength t =
    let
        -- Convert strength to bounce parameters
        -- Clamp strength between 0.1 and 1.0
        clampedStrength =
            clamp 0.1 1.0 strength

        -- More strength = more bounces and higher amplitude
        bounces =
            2 + round (clampedStrength * 2)

        amplitude =
            0.3 + (clampedStrength * 0.5)

        decay =
            0.5 + (clampedStrength * 0.3)
    in
    advancedBounceOutHelper bounces amplitude decay t


customBounceIn : Float -> Float -> Float
customBounceIn strength t =
    1.0 - customBounceOut strength (1.0 - t)


customBounceInOut : Float -> Float -> Float
customBounceInOut strength t =
    if t < 0.5 then
        -- First half: BounceIn scaled to 0-0.5
        customBounceIn strength (t * 2) * 0.5

    else
        -- Second half: BounceOut scaled to 0.5-1.0
        0.5 + (customBounceOut strength ((t - 0.5) * 2) * 0.5)


{-| Advanced bounce easing with full parameter control.
-}
advancedBounceOut : { bounces : Int, amplitude : Float, decay : Float } -> Float -> Float
advancedBounceOut params t =
    advancedBounceOutHelper params.bounces params.amplitude params.decay t


advancedBounceIn : { bounces : Int, amplitude : Float, decay : Float } -> Float -> Float
advancedBounceIn params t =
    1.0 - advancedBounceOut params (1.0 - t)


advancedBounceInOut : { bounces : Int, amplitude : Float, decay : Float } -> Float -> Float
advancedBounceInOut params t =
    if t < 0.5 then
        -- First half: BounceIn scaled to 0-0.5
        advancedBounceIn params (t * 2) * 0.5

    else
        -- Second half: BounceOut scaled to 0.5-1.0
        0.5 + (advancedBounceOut params ((t - 0.5) * 2) * 0.5)


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


{-| Generate keyframe progress values for complex easings.
Returns a list of 30 progress values (0.0 to 1.0) with the easing function applied.
This allows WAAPI to use accurate easing through linear interpolation between keyframes.
-}
generateKeyframes : Easing -> List Float
generateKeyframes easing =
    let
        keyframeCount =
            30
    in
    case easing of
        -- Custom bounce easings get special treatment to ensure they hit 1.0 at bounce boundaries
        BounceOutCustom strength ->
            let
                clampedStrength =
                    clamp 0.1 1.0 strength

                -- Physics-based: strength represents impact velocity
                -- First bounce height proportional to kinetic energy (v²)
                firstBounceAmplitude =
                    0.15 + (clampedStrength * clampedStrength * 0.75)

                -- Coefficient of restitution: how much energy retained per bounce
                -- Lower values = faster decay, higher values = more bounces
                -- Wider range (0.525-0.75) gives 1-6 bounce spread
                coefficientOfRestitution =
                    0.5 + (clampedStrength * 0.25)

                -- Calculate number of visible bounces based on when amplitude < 0.02
                -- Each bounce: height = previous * cor²
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

                -- Generate 30 keyframes for A->B transition using QuartIn easing
                -- This gives the characteristic "start slow, speed up" curve
                transitionKeyframes =
                    List.range 0 29
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / 29.0

                                    -- QuartIn: f(t) = t^4
                                    easedT =
                                        t * t * t * t
                                in
                                easedT
                            )

                -- Generate bounce-at-end keyframes
                -- Only take frames AFTER the first peak (1.0) - these are the actual bounces
                bounceKeyframes =
                    let
                        allBounceFrames =
                            generateBounceKeyframes bounces firstBounceAmplitude coefficientOfRestitution

                        -- Find the first frame that reaches 1.0 (or very close)
                        firstPeakIndex =
                            allBounceFrames
                                |> List.indexedMap Tuple.pair
                                |> List.filter (\( _, v ) -> v >= 0.99)
                                |> List.head
                                |> Maybe.map Tuple.first
                                |> Maybe.withDefault 10
                    in
                    -- Drop frames up to and including the first peak, keep only the bouncing part
                    List.drop (firstPeakIndex + 1) allBounceFrames

                _ =
                    Debug.log ("BounceOutCustom " ++ String.fromFloat strength ++ " -> bounces=" ++ String.fromInt bounces ++ " firstAmp=" ++ String.fromFloat firstBounceAmplitude ++ " CoR=" ++ String.fromFloat coefficientOfRestitution) (transitionKeyframes ++ bounceKeyframes)
            in
            transitionKeyframes ++ bounceKeyframes

        BounceInCustom strength ->
            let
                clampedStrength =
                    clamp 0.1 1.0 strength

                firstBounceAmplitude =
                    0.15 + (clampedStrength * clampedStrength * 0.75)

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

                -- Generate bounce-at-start keyframes
                -- Take frames AFTER the first peak (the bouncing part), reverse and invert
                bounceKeyframes =
                    let
                        allBounceFrames =
                            generateBounceKeyframes bounces firstBounceAmplitude coefficientOfRestitution

                        -- Find the first frame that reaches 1.0 (or very close)
                        firstPeakIndex =
                            allBounceFrames
                                |> List.indexedMap Tuple.pair
                                |> List.filter (\( _, v ) -> v >= 0.99)
                                |> List.head
                                |> Maybe.map Tuple.first
                                |> Maybe.withDefault 10

                        -- Take frames after the peak (the bouncing part), reverse, then invert
                        bouncesOnly =
                            allBounceFrames
                                |> List.drop (firstPeakIndex + 1)
                                |> List.reverse
                                |> List.map (\v -> 1.0 - v)
                    in
                    bouncesOnly

                _ =
                    Debug.log "BounceInCustom bounceKeyframes" bounceKeyframes

                -- Generate 30 keyframes for A->B transition using QuartOut easing
                -- This gives "fast start, slow down" to connect smoothly after bounces
                transitionKeyframes =
                    List.range 0 29
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / 29.0

                                    -- QuartOut: f(t) = 1 - (1-t)^4
                                    easedT =
                                        let
                                            invT =
                                                1.0 - t
                                        in
                                        1.0 - (invT * invT * invT * invT)
                                in
                                easedT
                            )

                _ =
                    Debug.log "BounceInCustom transitionKeyframes" transitionKeyframes

                _ =
                    Debug.log "BounceInCustom bounces then transition" ( List.length bounceKeyframes, List.length transitionKeyframes )

                allKeyframes =
                    bounceKeyframes ++ transitionKeyframes

                _ =
                    Debug.log "BounceInCustom FINAL" allKeyframes
            in
            allKeyframes

        BounceInOutCustom strength ->
            let
                clampedStrength =
                    clamp 0.1 1.0 strength

                firstBounceAmplitude =
                    0.15 + (clampedStrength * clampedStrength * 0.75)

                coefficientOfRestitution =
                    0.5 + (clampedStrength * 0.25)

                bounces =
                    let
                        minVisibleHeight =
                            0.02

                        calculateBounceCount current count =
                            if current < minVisibleHeight || count >= 3 then
                                count

                            else
                                calculateBounceCount (current * coefficientOfRestitution * coefficientOfRestitution) (count + 1)
                    in
                    max 1 (calculateBounceCount firstBounceAmplitude 0)

                -- Generate bounce-at-start keyframes (same as BounceInCustom)
                -- Keep all bounce frames
                bounceInKeyframes =
                    let
                        allBounceFrames =
                            generateBounceKeyframes bounces firstBounceAmplitude coefficientOfRestitution

                        firstPeakIndex =
                            allBounceFrames
                                |> List.indexedMap Tuple.pair
                                |> List.filter (\( _, v ) -> v >= 0.99)
                                |> List.head
                                |> Maybe.map Tuple.first
                                |> Maybe.withDefault 10
                    in
                    allBounceFrames
                        |> List.drop (firstPeakIndex + 1)
                        |> List.reverse
                        |> List.map (\v -> 1.0 - v)

                -- Generate 30 keyframes for A->B transition with QuartIn
                -- Skip first 8 frames to avoid starting too close to 0
                transitionKeyframes =
                    List.range 9 29
                        |> List.map
                            (\i ->
                                let
                                    t =
                                        toFloat i / 29.0

                                    -- QuartIn: f(t) = t^4 (start slow, accelerate)
                                    easedT =
                                        t * t * t * t
                                in
                                easedT
                            )

                -- Generate bounce-at-end keyframes (same as BounceOutCustom)
                bounceOutKeyframes =
                    let
                        allBounceFrames =
                            generateBounceKeyframes bounces firstBounceAmplitude coefficientOfRestitution

                        firstPeakIndex =
                            allBounceFrames
                                |> List.indexedMap Tuple.pair
                                |> List.filter (\( _, v ) -> v >= 0.99)
                                |> List.head
                                |> Maybe.map Tuple.first
                                |> Maybe.withDefault 10
                    in
                    List.drop (firstPeakIndex + 1) allBounceFrames

                _ =
                    Debug.log "BounceInOutCustom FINAL allKeyframes (count)" (List.length bounceInKeyframes + List.length transitionKeyframes + List.length bounceOutKeyframes)

                allKeyframes =
                    bounceInKeyframes ++ transitionKeyframes ++ bounceOutKeyframes

                _ =
                    Debug.log "BounceInOutCustom FINAL allKeyframes" allKeyframes
            in
            allKeyframes

        BounceOutAdvanced params ->
            let
                -- Generate 30 keyframes for A->B transition (0->1 linear)
                transitionKeyframes =
                    List.range 0 29
                        |> List.map (\i -> toFloat i / 29.0)

                -- Generate bounce-at-end keyframes
                bounceKeyframes =
                    generateBounceKeyframes params.bounces params.amplitude params.decay
            in
            transitionKeyframes ++ bounceKeyframes

        BounceInAdvanced params ->
            let
                -- Generate bounce-at-start keyframes
                bounceKeyframes =
                    generateBounceKeyframes params.bounces params.amplitude params.decay
                        |> List.reverse
                        |> List.map (\v -> 1.0 - v)

                -- Generate 30 keyframes for A->B transition (0->1 linear)
                transitionKeyframes =
                    List.range 0 29
                        |> List.map (\i -> toFloat i / 29.0)
            in
            bounceKeyframes ++ transitionKeyframes

        BounceInOutAdvanced params ->
            let
                -- Generate bounce-at-start keyframes
                bounceInKeyframes =
                    generateBounceKeyframes params.bounces params.amplitude params.decay
                        |> List.reverse
                        |> List.map (\v -> 1.0 - v)

                -- Generate 30 keyframes for A->B transition (0->1 linear)
                transitionKeyframes =
                    List.range 0 29
                        |> List.map (\i -> toFloat i / 29.0)

                -- Generate bounce-at-end keyframes
                bounceOutKeyframes =
                    generateBounceKeyframes params.bounces params.amplitude params.decay
            in
            bounceInKeyframes ++ transitionKeyframes ++ bounceOutKeyframes

        _ ->
            -- Standard approach: sample the easing function
            let
                easingFunction =
                    toFunction easing

                linearProgress i =
                    toFloat i / toFloat (keyframeCount - 1)

                keyframeValues =
                    List.range 0 (keyframeCount - 1)
                        |> List.map (\i -> easingFunction (linearProgress i))

                _ =
                    case easing of
                        BounceOut ->
                            Debug.log "BounceOut keyframes" keyframeValues

                        _ ->
                            keyframeValues
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
