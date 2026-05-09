module Shared.Easing.Keyframes exposing
    ( defaultKeyframeCount
    , generateKeyframes
    )

{-| Physics-based keyframe generation for complex easings.

The WAAPI engine cannot represent Bounce or Elastic easings accurately with
a single cubic-bezier curve, so it requests a pre-computed keyframe array
instead (`easingKeyframes`). This module produces those arrays. The Keyframe
engine samples its `@keyframes` stops at the same density to keep the two
engines visually consistent.

The dispatcher `generateKeyframes` picks one of two strategies:

  - For physics-based bounce/elastic variants, run a small numerical
    simulation (coefficient-of-restitution decay for bounces, exponential
    decay × sine for elastic) and return the resulting samples.
  - For everything else, fall back to uniform sampling of
    `Shared.Easing.toFunction` — accurate at any density for the standard
    cubic-bezier easings as well as the algebraic `Back*Custom` variants.

Velocity is normalized against a 1-second baseline: faster animations get
larger oscillation amplitudes, slower animations get smaller ones, so the
visual feel stays consistent across durations.

-}

import Easing exposing (Easing(..))
import Shared.Easing



-- ============================================================
-- KEYFRAME COUNT
-- ============================================================


{-| Default number of keyframe samples used by both the WAAPI engine
(per-property `easingKeyframes` arrays) and the Keyframe engine
(`@keyframes` stop count).

This describes curve shape, not playback frame rate — the browser still
animates at its native refresh rate and interpolates linearly between
the samples.

-}
defaultKeyframeCount : Int
defaultKeyframeCount =
    30



-- ============================================================
-- KEYFRAME GENERATION
-- ============================================================


{-| Generate keyframe progress values for an `Easing` over a given duration.

Returns a list of progress values (0.0 to 1.0) sampled densely enough to
reproduce complex easings via linear interpolation between samples.

-}
generateKeyframes : Easing -> Float -> List Float
generateKeyframes easing durationMs =
    let
        keyframeCount =
            defaultKeyframeCount

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
                    round (toFloat defaultKeyframeCount / velocityFactor) |> clamp 15 60

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
                    round (toFloat defaultKeyframeCount / velocityFactor) |> clamp 15 60

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

        BounceInOutCustom ( strengthIn, strengthOut ) ->
            let
                clampedStrengthIn =
                    clamp 0.1 1.0 strengthIn

                clampedStrengthOut =
                    clamp 0.1 1.0 strengthOut

                -- In parameters
                firstBounceAmplitudeIn =
                    (0.15 + (clampedStrengthIn * clampedStrengthIn * 0.75)) * velocityFactor

                coefficientOfRestitutionIn =
                    0.5 + (clampedStrengthIn * 0.25)

                bouncesIn =
                    let
                        minVisibleHeight =
                            0.02

                        calculateBounceCount current count =
                            if current < minVisibleHeight || count >= 6 then
                                count

                            else
                                calculateBounceCount (current * coefficientOfRestitutionIn * coefficientOfRestitutionIn) (count + 1)
                    in
                    max 1 (calculateBounceCount firstBounceAmplitudeIn 0)

                -- Out parameters
                firstBounceAmplitudeOut =
                    (0.15 + (clampedStrengthOut * clampedStrengthOut * 0.75)) * velocityFactor

                coefficientOfRestitutionOut =
                    0.5 + (clampedStrengthOut * 0.25)

                bouncesOut =
                    let
                        minVisibleHeight =
                            0.02

                        calculateBounceCount current count =
                            if current < minVisibleHeight || count >= 6 then
                                count

                            else
                                calculateBounceCount (current * coefficientOfRestitutionOut * coefficientOfRestitutionOut) (count + 1)
                    in
                    max 1 (calculateBounceCount firstBounceAmplitudeOut 0)

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
                -- Transition from near 0 to near 1 with velocity matching the bounces
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
                    createBounceInKeyframes bouncesIn firstBounceAmplitudeIn coefficientOfRestitutionIn

                bounceOutKeyframes =
                    createBounceOutKeyframes bouncesOut firstBounceAmplitudeOut coefficientOfRestitutionOut

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
                    round (toFloat defaultKeyframeCount / velocityFactor) |> clamp 15 60

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
                -- Apply velocity scaling to amplitudes
                scaledAmplitudeIn =
                    params.in_.amplitude * velocityFactor

                scaledAmplitudeOut =
                    params.out.amplitude * velocityFactor

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
                    createBounceInKeyframes params.in_.bounces scaledAmplitudeIn params.in_.decay

                bounceOutKeyframes =
                    createBounceOutKeyframes params.out.bounces scaledAmplitudeOut params.out.decay

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
                elasticity =
                    2 + (clampedStrength * 3)

                amplitude =
                    (0.5 + (clampedStrength * 0.5)) * velocityFactor

                decay =
                    6 + (clampedStrength * 2)

                -- Transition should take the full duration
                -- At 60fps: frames = durationMs / 16.67ms
                transitionFrameCount =
                    round (durationMs / 16.67) |> max 10

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
                    generateElasticOscillations elasticity amplitude decay

                allKeyframes =
                    transitionKeyframes ++ oscillationKeyframes
            in
            allKeyframes

        ElasticInCustom strength ->
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

                -- Generate ONLY the elastic oscillations (reversed for In)
                oscillationKeyframes =
                    generateElasticOscillations elasticity amplitude decay
                        |> List.reverse
                        |> List.map (\v -> 1.0 - v)

                -- Transition should take the full duration
                -- At 60fps: frames = durationMs / 16.67ms
                transitionFrameCount =
                    round (durationMs / 16.67) |> max 10

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

        ElasticInOutCustom ( strengthIn, strengthOut ) ->
            let
                clampedStrengthIn =
                    clamp 0.1 1.0 strengthIn

                clampedStrengthOut =
                    clamp 0.1 1.0 strengthOut

                -- In parameters
                elasticityIn =
                    2 + (clampedStrengthIn * 3)

                amplitudeIn =
                    (0.5 + (clampedStrengthIn * 0.5)) * velocityFactor

                decayIn =
                    6 + (clampedStrengthIn * 2)

                -- Out parameters
                elasticityOut =
                    2 + (clampedStrengthOut * 3)

                amplitudeOut =
                    (0.5 + (clampedStrengthOut * 0.5)) * velocityFactor

                decayOut =
                    6 + (clampedStrengthOut * 2)

                -- Transition should take the full duration
                -- At 60fps: frames = durationMs / 16.67ms
                transitionFrameCount =
                    round (durationMs / 16.67) |> max 10

                -- Calculate transition velocity: distance / time
                transitionVelocity =
                    1.0 / toFloat transitionFrameCount

                -- Oscillations should match transition velocity
                -- For a sine wave with amplitude A, one cycle travels ~4*A distance
                -- To match velocity: 4*amplitude / framesPerCycle = transitionVelocity
                -- So: framesPerCycle = 4*amplitude / transitionVelocity
                framesPerCycleIn =
                    round (4.0 * amplitudeIn / transitionVelocity) |> max 8

                framesPerCycleOut =
                    round (4.0 * amplitudeOut / transitionVelocity) |> max 8

                -- In portion: Use physics-based oscillations (reversed and inverted)
                elasticInOscillations =
                    generateElasticOscillationsWithFrames elasticityIn amplitudeIn decayIn framesPerCycleIn
                        |> List.reverse
                        |> List.map (\v -> 1.0 - v)

                -- Out portion: Use duration-aware oscillations
                elasticOutOscillations =
                    generateElasticOscillationsWithFrames elasticityOut amplitudeOut decayOut framesPerCycleOut

                -- Transition needs to smoothly connect from velocity matching last In to first Out
                -- Linear transition since velocities match
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
            in
            allKeyframes

        ElasticOutAdvanced params ->
            let
                -- Apply velocity scaling to amplitude
                scaledAmplitude =
                    params.amplitude * velocityFactor

                -- Velocity-aware transition frame count
                transitionFrameCount =
                    round (toFloat defaultKeyframeCount / velocityFactor) |> clamp 15 60

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
                    generateElasticOscillations params.elasticity scaledAmplitude params.decay

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
                    generateElasticOscillations params.elasticity scaledAmplitude params.decay
                        |> List.reverse
                        |> List.map (\v -> 1.0 - v)

                -- Transition should take the full duration
                -- At 60fps: frames = durationMs / 16.67ms
                transitionFrameCount =
                    round (durationMs / 16.67) |> max 10

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
                -- Apply velocity scaling to amplitudes
                scaledAmplitudeIn =
                    params.in_.amplitude * velocityFactor

                scaledAmplitudeOut =
                    params.out.amplitude * velocityFactor

                -- Transition should take the full duration
                -- At 60fps: frames = durationMs / 16.67ms
                transitionFrameCount =
                    round (durationMs / 16.67) |> max 10

                -- Calculate transition velocity: distance / time
                transitionVelocity =
                    1.0 / toFloat transitionFrameCount

                -- Oscillations should match transition velocity
                -- For a sine wave with amplitude A, one cycle travels ~4*A distance
                -- To match velocity: 4*amplitude / framesPerCycle = transitionVelocity
                -- So: framesPerCycle = 4*amplitude / transitionVelocity
                framesPerCycleIn =
                    round (4.0 * scaledAmplitudeIn / transitionVelocity) |> max 8

                framesPerCycleOut =
                    round (4.0 * scaledAmplitudeOut / transitionVelocity) |> max 8

                -- In portion: Use physics-based oscillations (reversed and inverted)
                elasticInOscillations =
                    generateElasticOscillationsWithFrames params.in_.elasticity scaledAmplitudeIn params.in_.decay framesPerCycleIn
                        |> List.reverse
                        |> List.map (\v -> 1.0 - v)

                -- Out portion: Use duration-aware oscillations
                elasticOutOscillations =
                    generateElasticOscillationsWithFrames params.out.elasticity scaledAmplitudeOut params.out.decay framesPerCycleOut

                -- Transition needs to smoothly connect from velocity matching last In to first Out
                -- Linear transition since velocities match
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
            in
            allKeyframes

        _ ->
            -- Standard approach: sample the easing function uniformly.
            -- Covers Linear, all standard CubicBezier easings, and the
            -- algebraic BackInCustom/BackOutCustom/BackInOutCustom variants
            -- (which are accurate at any sampling density).
            let
                easingFunction =
                    Shared.Easing.toFunction durationMs easing

                linearProgress i =
                    toFloat i / toFloat (keyframeCount - 1)

                keyframeValues =
                    List.range 0 (keyframeCount - 1)
                        |> List.map (\i -> easingFunction (linearProgress i))
            in
            keyframeValues



-- ============================================================
-- BOUNCE PHYSICS
-- ============================================================


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
        -- Ensure at least 1 bounce
        validBounces =
            max 1 bounces

        -- Phase 1: Approach - inverse correlation with bounce strength
        -- Lower bounces = smaller/slower, need more approach time for balance
        -- Higher bounces = bigger/faster, can use shorter approach
        -- Approach gets 25-45% for weak bounces, 15-25% for strong bounces
        approachRatio =
            0.45 - (firstAmplitude * 0.2)

        approachFrames =
            max 3 (round (approachRatio * toFloat defaultKeyframeCount))

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
            List.range 0 (validBounces - 1)
                |> List.map
                    (\i ->
                        let
                            energyLossFactor =
                                coefficientOfRestitution ^ (2 * toFloat i)
                        in
                        firstAmplitude * energyLossFactor
                    )

        -- Physics: Time for each bounce proportional to sqrt(height)
        -- From gravitational physics: t ∝ √h
        totalBounceTime =
            List.map sqrt bounceAmplitudes |> List.sum

        totalBounceFrames =
            defaultKeyframeCount

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

                                        else if frameIndex == framesForThisBounce && bounceIndex == validBounces - 1 then
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
        -- Ensure at least 1 bounce
        validBounces =
            max 1 bounces

        -- Physics: Calculate bounce amplitudes using coefficient of restitution
        bounceAmplitudes =
            List.range 0 (validBounces - 1)
                |> List.map
                    (\i ->
                        let
                            energyLossFactor =
                                coefficientOfRestitution ^ (2 * toFloat i)
                        in
                        firstAmplitude * energyLossFactor
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

                                        else if frameIndex == framesForThisBounce && bounceIndex == validBounces - 1 then
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



-- ============================================================
-- ELASTIC PHYSICS
-- ============================================================


{-| Generate ONLY elastic oscillations (no transition phase) for use with separate transition keyframes.
Returns keyframes that oscillate around 1.0 with exponential decay.
-}
generateElasticOscillations : Float -> Float -> Float -> List Float
generateElasticOscillations elasticity amplitude decay =
    let
        -- Calculate number of visible oscillation cycles based on decay
        -- Use strict 1% threshold to ensure oscillations finish close to zero
        minVisibleAmplitude =
            amplitude * 0.01

        visibleDuration =
            if amplitude > minVisibleAmplitude then
                logBase 2 (minVisibleAmplitude / amplitude) / -decay

            else
                0.0

        -- Total oscillation cycles + 1 buffer cycle for smooth tail-off
        totalCycles =
            (round (elasticity * visibleDuration) + 1)
                |> max 3
                |> min 24

        -- Fixed frames per cycle for evenly spaced peaks and constant velocity
        -- Only amplitude varies between cycles, not timing
        framesPerCycle =
            52

        -- Generate frames for each cycle
        allFrames =
            List.indexedMap
                (\cycleIndex _ ->
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
                                                (toFloat cycleIndex + localT) / elasticity

                                            -- Envelope at this time
                                            envelope =
                                                amplitude * (2 ^ (-decay * globalTime))

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
                (List.range 0 (totalCycles - 1))
                |> List.concat
    in
    allFrames


{-| Generate elastic oscillations with custom frames per cycle for velocity-aware animations.
This version allows InOut to match the oscillation velocity to the transition phase velocity.
-}
generateElasticOscillationsWithFrames : Float -> Float -> Float -> Int -> List Float
generateElasticOscillationsWithFrames elasticity amplitude decay framesPerCycle =
    let
        -- Calculate number of visible oscillation cycles based on decay
        -- Use strict 1% threshold to ensure oscillations finish close to zero
        minVisibleAmplitude =
            amplitude * 0.01

        visibleDuration =
            if amplitude > minVisibleAmplitude then
                logBase 2 (minVisibleAmplitude / amplitude) / -decay

            else
                0.0

        -- Total oscillation cycles + 1 buffer cycle for smooth tail-off
        totalCycles =
            (round (elasticity * visibleDuration) + 1)
                |> max 3
                |> min 24

        -- Generate frames for each cycle
        allFrames =
            List.indexedMap
                (\cycleIndex _ ->
                    let
                        cycleFrames =
                            List.range 0 framesPerCycle
                                |> List.map
                                    (\frameIndex ->
                                        let
                                            -- Local t within this cycle (0 to 1)
                                            localT =
                                                toFloat frameIndex / toFloat framesPerCycle

                                            -- Global time
                                            globalTime =
                                                (toFloat cycleIndex + localT) / elasticity

                                            -- Envelope at this time
                                            envelope =
                                                amplitude * (2 ^ (-decay * globalTime))

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
                (List.range 0 (totalCycles - 1))
                |> List.concat
    in
    allFrames
