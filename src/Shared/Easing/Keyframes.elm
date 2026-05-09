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
        velocityFactor =
            -- Baseline: 1 second (1000ms) = normal velocity.
            -- Faster (500ms) = 2x velocity = bigger bounces/oscillations.
            -- Slower (2000ms) = 0.5x velocity = smaller bounces/oscillations.
            1000.0 / durationMs

        bounceFrames =
            bounceTransitionFrames velocityFactor

        elasticFrames =
            elasticTransitionFrames durationMs
    in
    case easing of
        BounceOutCustom strength ->
            let
                p =
                    customBounceParams velocityFactor strength
            in
            quartInTransition bounceFrames
                ++ customBounceOutSegment p.bounces p.firstAmplitude p.cor

        BounceInCustom strength ->
            let
                p =
                    customBounceParams velocityFactor strength
            in
            customBounceInSegment p.bounces p.firstAmplitude p.cor
                ++ quartOutTransition bounceFrames

        BounceInOutCustom ( strengthIn, strengthOut ) ->
            let
                pIn =
                    customBounceParams velocityFactor strengthIn

                pOut =
                    customBounceParams velocityFactor strengthOut

                inFrames =
                    customBounceInSegment pIn.bounces pIn.firstAmplitude pIn.cor

                outFrames =
                    customBounceOutSegment pOut.bounces pOut.firstAmplitude pOut.cor
            in
            inFrames
                ++ velocityMatchedTransition inFrames outFrames
                ++ outFrames

        BounceOutAdvanced params ->
            quartInTransition bounceFrames
                ++ generateBounceOscillations params.bounces (params.amplitude * velocityFactor) params.decay

        BounceInAdvanced params ->
            advancedBounceInSegment velocityFactor params
                -- BounceInAdvanced uses a fixed 30-frame transition,
                -- not the velocity-aware one used elsewhere.
                ++ quartOutTransition 30

        BounceInOutAdvanced params ->
            let
                inFrames =
                    advancedBounceInSegment velocityFactor params.in_

                outFrames =
                    generateBounceOscillations params.out.bounces (params.out.amplitude * velocityFactor) params.out.decay
            in
            inFrames
                ++ velocityMatchedTransition inFrames outFrames
                ++ outFrames

        ElasticOutCustom strength ->
            let
                p =
                    customElasticParams velocityFactor strength
            in
            quartInTransition elasticFrames
                ++ generateElasticOscillations p.elasticity p.amplitude p.decay

        ElasticInCustom strength ->
            let
                p =
                    customElasticParams velocityFactor strength
            in
            invertReversedOscillations (generateElasticOscillations p.elasticity p.amplitude p.decay)
                ++ quartOutTransition elasticFrames

        ElasticInOutCustom ( strengthIn, strengthOut ) ->
            let
                pIn =
                    customElasticParams velocityFactor strengthIn

                pOut =
                    customElasticParams velocityFactor strengthOut

                fpcIn =
                    framesPerCycleFor elasticFrames pIn.amplitude

                fpcOut =
                    framesPerCycleFor elasticFrames pOut.amplitude
            in
            invertReversedOscillations (generateElasticOscillationsWithFrames pIn.elasticity pIn.amplitude pIn.decay fpcIn)
                ++ linearTransition elasticFrames
                ++ generateElasticOscillationsWithFrames pOut.elasticity pOut.amplitude pOut.decay fpcOut

        ElasticOutAdvanced params ->
            -- Note: ElasticOutAdvanced uses the bounce-style velocity-aware
            -- transition count, not the duration-based elastic one.
            quartInTransition bounceFrames
                ++ generateElasticOscillations params.elasticity (params.amplitude * velocityFactor) params.decay

        ElasticInAdvanced params ->
            invertReversedOscillations
                (generateElasticOscillations params.elasticity (params.amplitude * velocityFactor) params.decay)
                ++ quartOutTransition elasticFrames

        ElasticInOutAdvanced params ->
            let
                ampIn =
                    params.in_.amplitude * velocityFactor

                ampOut =
                    params.out.amplitude * velocityFactor

                fpcIn =
                    framesPerCycleFor elasticFrames ampIn

                fpcOut =
                    framesPerCycleFor elasticFrames ampOut
            in
            invertReversedOscillations
                (generateElasticOscillationsWithFrames params.in_.elasticity ampIn params.in_.decay fpcIn)
                ++ linearTransition elasticFrames
                ++ generateElasticOscillationsWithFrames params.out.elasticity ampOut params.out.decay fpcOut

        _ ->
            -- Standard approach: sample the easing function uniformly.
            -- Covers Linear, all standard CubicBezier easings, and the
            -- algebraic BackInCustom/BackOutCustom/BackInOutCustom variants
            -- (which are accurate at any sampling density).
            uniformSamples (Shared.Easing.toFunction durationMs easing) defaultKeyframeCount



-- ============================================================
-- TRANSITION CURVES
-- ============================================================
--
-- A "transition" is the smooth 0 → 1 ramp that wraps the physics-based
-- oscillation segments. Every transition is sampled at `n` evenly spaced
-- progress values t ∈ [0, 1].


{-| Linear ramp t ∈ [0, 1].
-}
linearTransition : Int -> List Float
linearTransition n =
    uniformSamples identity n


{-| QuartIn ramp: t⁴. Starts slow, accelerates. Used as the lead-in for
Out variants (the bounce/oscillation lands at the end).
-}
quartInTransition : Int -> List Float
quartInTransition n =
    uniformSamples (\t -> t * t * t * t) n


{-| QuartOut ramp: 1 - (1 - t)⁴. Starts fast, decelerates. Used as the
tail for In variants (the bounce/oscillation kicks off at the start).
-}
quartOutTransition : Int -> List Float
quartOutTransition n =
    uniformSamples
        (\t ->
            let
                invT =
                    1.0 - t
            in
            1.0 - (invT * invT * invT * invT)
        )
        n


{-| Sample a `0..1 -> Float` function at `n` evenly spaced points across
[0, 1] (inclusive on both ends).
-}
uniformSamples : (Float -> Float) -> Int -> List Float
uniformSamples f n =
    if n <= 1 then
        if n == 1 then
            [ f 0 ]

        else
            []

    else
        List.range 0 (n - 1)
            |> List.map (\i -> f (toFloat i / toFloat (n - 1)))



-- ============================================================
-- TRANSITION FRAME COUNTS
-- ============================================================


{-| Bounce transition length: scales inversely with playback velocity so
slower animations get longer ramps. Clamped to 15..60 frames.
-}
bounceTransitionFrames : Float -> Int
bounceTransitionFrames velocityFactor =
    round (toFloat defaultKeyframeCount / velocityFactor) |> clamp 15 60


{-| Elastic transition length: roughly one frame per ~16.67ms of
duration (≈60fps), with a 10-frame floor.
-}
elasticTransitionFrames : Float -> Int
elasticTransitionFrames durationMs =
    round (durationMs / 16.67) |> max 10


{-| Pick a frames-per-cycle so an oscillation's surface velocity matches
the linear transition that bridges In and Out halves of an InOut easing.

A sine wave with amplitude `A` traverses ~4·A units of distance per
cycle. To match the transition's per-frame velocity (1 / transitionFrames),
each cycle therefore needs `4·A · transitionFrames` frames.

-}
framesPerCycleFor : Int -> Float -> Int
framesPerCycleFor transitionFrames amplitude =
    let
        transitionVelocity =
            1.0 / toFloat transitionFrames
    in
    round (4.0 * amplitude / transitionVelocity) |> max 8



-- ============================================================
-- BOUNCE PARAMETER DERIVATION
-- ============================================================


{-| Derive bounce parameters from a single 0..1 strength knob.

  - `firstAmplitude` grows quadratically with strength and scales with velocity.
  - `cor` (coefficient of restitution) grows linearly with strength.
  - `bounces` is the count of visible bounces given the geometric decay
    `firstAmplitude · cor^(2n)`, capped at 6.

-}
customBounceParams :
    Float
    -> Float
    -> { firstAmplitude : Float, cor : Float, bounces : Int }
customBounceParams velocityFactor strength =
    let
        clamped =
            clamp 0.1 1.0 strength

        firstAmplitude =
            (0.15 + (clamped * clamped * 0.75)) * velocityFactor

        cor =
            0.5 + (clamped * 0.25)
    in
    { firstAmplitude = firstAmplitude
    , cor = cor
    , bounces = countVisibleBounces 0.02 cor firstAmplitude
    }


{-| Count the bounces that stay above `minVisibleHeight`. Bounce `n` has
height `start · cor^(2n)`. Capped at 6, floor of 1.
-}
countVisibleBounces : Float -> Float -> Float -> Int
countVisibleBounces minVisibleHeight cor start =
    let
        step current count =
            if current < minVisibleHeight || count >= 6 then
                count

            else
                step (current * cor * cor) (count + 1)
    in
    max 1 (step start 0)



-- ============================================================
-- ELASTIC PARAMETER DERIVATION
-- ============================================================


{-| Derive elastic parameters from a single 0..1 strength knob. All three
parameters scale linearly with strength; amplitude additionally scales
with velocity.
-}
customElasticParams :
    Float
    -> Float
    -> { elasticity : Float, amplitude : Float, decay : Float }
customElasticParams velocityFactor strength =
    let
        clamped =
            clamp 0.1 1.0 strength
    in
    { elasticity = 2 + (clamped * 3)
    , amplitude = (0.5 + (clamped * 0.5)) * velocityFactor
    , decay = 6 + (clamped * 2)
    }



-- ============================================================
-- BOUNCE / ELASTIC SEGMENTS
-- ============================================================


{-| Custom bounce-out segment: drop the approach phase from
`generateBounceKeyframes` so only the around-1.0 oscillations remain.
-}
customBounceOutSegment : Int -> Float -> Float -> List Float
customBounceOutSegment bounces amp cor =
    generateBounceKeyframes bounces amp cor
        |> dropApproachPhase


{-| Custom bounce-in segment: same shape as the out segment, mirrored
to the start so the bounces happen around 0.
-}
customBounceInSegment : Int -> Float -> Float -> List Float
customBounceInSegment bounces amp cor =
    customBounceOutSegment bounces amp cor
        |> List.reverse
        |> List.map (\v -> 1.0 - v)


{-| Advanced bounce-in segment: mirror the around-1.0 oscillations from
`generateBounceOscillations` to the start so the bounces happen around 0.
-}
advancedBounceInSegment :
    Float
    -> { a | bounces : Int, amplitude : Float, decay : Float }
    -> List Float
advancedBounceInSegment velocityFactor params =
    generateBounceOscillations params.bounces (params.amplitude * velocityFactor) params.decay
        |> List.map (\v -> 1.0 - v)
        |> List.reverse


{-| Drop the leading "approach" phase produced by `generateBounceKeyframes`,
leaving only the bounce oscillations. The boundary is the first sample
that reaches the target (≥ 0.99); fall back to 10 if no peak is found.
-}
dropApproachPhase : List Float -> List Float
dropApproachPhase frames =
    let
        firstPeakIndex =
            frames
                |> List.indexedMap Tuple.pair
                |> List.filter (\( _, v ) -> v >= 0.99)
                |> List.head
                |> Maybe.map Tuple.first
                |> Maybe.withDefault 10
    in
    List.drop (firstPeakIndex + 1) frames


{-| Mirror an around-1.0 elastic oscillation segment to the start so it
oscillates around 0 instead. Used for the "in" half of elastic easings.
-}
invertReversedOscillations : List Float -> List Float
invertReversedOscillations oscillations =
    oscillations
        |> List.reverse
        |> List.map (\v -> 1.0 - v)



-- ============================================================
-- IN/OUT BRIDGE
-- ============================================================


{-| Linear bridge between the "in" and "out" halves of a Bounce InOut.

The frame count is chosen to match the average surface velocity of the
neighbouring oscillation segments (sampled from their first/last 5
samples), so the join is C¹-smooth even though the bridge itself is
linear.

-}
velocityMatchedTransition : List Float -> List Float -> List Float
velocityMatchedTransition inFrames outFrames =
    let
        inEndVelocity =
            tailVelocity inFrames

        outStartVelocity =
            headVelocity outFrames

        avgVelocity =
            (inEndVelocity + outStartVelocity) / 2.0

        frameCount =
            if avgVelocity > 0 then
                round (1.0 / (avgVelocity * 2.0)) |> clamp 5 15

            else
                10
    in
    linearTransition frameCount


{-| Velocity at the tail end of a list, sampled from the last 5 frames.
-}
tailVelocity : List Float -> Float
tailVelocity frames =
    let
        lastFrames =
            List.reverse frames |> List.take 5

        first =
            List.head lastFrames |> Maybe.withDefault 0

        last =
            List.reverse lastFrames |> List.head |> Maybe.withDefault 0
    in
    abs (first - last) / 4.0


{-| Velocity at the head of a list, sampled from the first 5 frames.
-}
headVelocity : List Float -> Float
headVelocity frames =
    let
        firstFrames =
            List.take 5 frames

        first =
            List.head firstFrames |> Maybe.withDefault 1

        last =
            List.drop 4 firstFrames |> List.head |> Maybe.withDefault 1
    in
    abs (first - last) / 4.0



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
