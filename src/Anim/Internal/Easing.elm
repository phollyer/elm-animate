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
        customBounceIn strength (t * 2) * 0.5

    else
        0.5 + customBounceOut strength ((t - 0.5) * 2) * 0.5


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
        advancedBounceIn params (t * 2) * 0.5

    else
        0.5 + advancedBounceOut params ((t - 0.5) * 2) * 0.5


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

                -- More strength = more bounces and higher amplitude
                bounces =
                    2 + round (clampedStrength * 2)

                amplitude =
                    0.3 + (clampedStrength * 0.5)

                decay =
                    0.5 + (clampedStrength * 0.3)

                keyframes =
                    generateBounceKeyframes bounces amplitude decay

                _ =
                    Debug.log ("BounceOutCustom " ++ String.fromFloat strength ++ " -> bounces=" ++ String.fromInt bounces ++ " amp=" ++ String.fromFloat amplitude ++ " decay=" ++ String.fromFloat decay) keyframes
            in
            keyframes

        BounceInCustom strength ->
            let
                clampedStrength =
                    clamp 0.1 1.0 strength

                bounces =
                    2 + round (clampedStrength * 2)

                amplitude =
                    0.3 + (clampedStrength * 0.5)

                decay =
                    0.5 + (clampedStrength * 0.3)
            in
            generateBounceKeyframes bounces amplitude decay
                |> List.reverse
                |> List.map (\v -> 1.0 - v)

        BounceInOutCustom strength ->
            let
                clampedStrength =
                    clamp 0.1 1.0 strength

                bounces =
                    1 + round (clampedStrength * 1)

                amplitude =
                    0.3 + (clampedStrength * 0.5)

                decay =
                    0.5 + (clampedStrength * 0.3)

                half =
                    generateBounceKeyframes bounces amplitude decay
                        |> List.take 15

                secondHalf =
                    List.reverse half
                        |> List.map (\v -> 1.0 - v)
            in
            half ++ secondHalf

        BounceOutAdvanced params ->
            generateBounceKeyframes params.bounces params.amplitude params.decay

        BounceInAdvanced params ->
            generateBounceKeyframes params.bounces params.amplitude params.decay
                |> List.reverse
                |> List.map (\v -> 1.0 - v)

        BounceInOutAdvanced params ->
            let
                half =
                    generateBounceKeyframes params.bounces params.amplitude params.decay
                        |> List.take 15

                secondHalf =
                    List.reverse half
                        |> List.map (\v -> 1.0 - v)
            in
            half ++ secondHalf

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


{-| Generate keyframes for bounce effect with explicit 1.0 values at bounce boundaries.
This ensures the element visibly reaches the endpoint between bounces.
The number of keyframes varies to ensure clean bounce boundaries.
-}
generateBounceKeyframes : Int -> Float -> Float -> List Float
generateBounceKeyframes bounces amplitude decay =
    let
        -- Clamp parameters
        clampedBounces =
            max 1 bounces

        clampedAmplitude =
            clamp 0.1 1.0 amplitude

        clampedDecay =
            clamp 0.1 0.9 decay

        -- Phase 1: Approach (first 5 keyframes)
        approachFrames =
            5

        -- Phase 2: Each bounce gets 8 keyframes for smooth motion
        -- This ensures we have enough resolution and clean boundaries
        framesPerBounce =
            8

        -- Generate approach keyframes using cubic-out
        approach =
            List.range 0 (approachFrames - 1)
                |> List.map
                    (\i ->
                        let
                            t =
                                toFloat i / toFloat (approachFrames - 1)

                            p =
                                1.0 - t
                        in
                        1.0 - (p * p * p)
                    )

        -- Generate bounce keyframes
        -- Each bounce cycle: starts at 1.0, dips down, ends at 1.0
        bounces_ =
            List.range 0 (clampedBounces - 1)
                |> List.concatMap
                    (\bounceIndex ->
                        let
                            currentAmplitude =
                                clampedAmplitude * (clampedDecay ^ toFloat bounceIndex)

                            -- Generate frames for this bounce
                            -- Quadratic easing for more speed variation: very fast at endpoints, slow at peak
                            bounceFrames =
                                List.range 0 framesPerBounce
                                    |> List.map
                                        (\frameIndex ->
                                            if frameIndex == 0 && bounceIndex > 0 then
                                                -- Explicitly 1.0 at start of bounce (except first bounce, approach already ends at 1.0)
                                                1.0

                                            else if frameIndex == 0 && bounceIndex == 0 then
                                                -- Skip starting 1.0 for first bounce to avoid duplicate with approach phase
                                                -999.0

                                            else if frameIndex == framesPerBounce && bounceIndex == clampedBounces - 1 then
                                                -- Only add ending 1.0 for the LAST bounce
                                                1.0

                                            else if frameIndex == framesPerBounce then
                                                -- Skip the ending frame for non-final bounces to avoid duplicates
                                                -- The next bounce will provide the 1.0 at its start
                                                -999.0

                                            else
                                                -- Use quadratic easing for more pronounced speed variation
                                                -- Element speeds up dramatically near endpoints
                                                let
                                                    localT =
                                                        toFloat frameIndex / toFloat framesPerBounce

                                                    -- Map to range -1 to 1 (centered at 0)
                                                    centered =
                                                        (localT - 0.5) * 2

                                                    -- Quadratic curve: 1 - t^2
                                                    -- At t=0: value=1 (max displacement)
                                                    -- At t=±1: value=0 (at endpoint, no displacement)
                                                    -- This creates faster motion near endpoints
                                                    easedProgress =
                                                        1.0 - (centered * centered)

                                                    displacement =
                                                        currentAmplitude * easedProgress
                                                in
                                                1.0 - displacement
                                        )
                                    |> List.filter (\v -> v /= -999.0)
                        in
                        bounceFrames
                    )
    in
    approach ++ bounces_
