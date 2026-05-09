module Shared.Easing.Physics exposing (transitionFractionOf)

{-| Physics-derived ratios that describe how complex easings divide their
total runtime between the user-facing transition (the smooth A → B ramp)
and the bounces or oscillations that physics says should extend beyond
it.

Lives in its own module so that both `Shared.Easing` (which needs the
ratio to extend `toFunction` durations and re-exports the function for
engines) and `Shared.Easing.Keyframes` (which needs the ratio to split
the keyframe array between transition and oscillation samples) can
import it without re-introducing an import cycle.

-}

import Easing exposing (Easing(..))


{-| Fraction of an easing's curve that constitutes the A → B transition
(the smooth ramp), as opposed to bounces or oscillations that physics
says should extend beyond the transition.

Returns 1.0 for simple easings (the whole curve is the transition).

For complex easings, the value is derived from the bounce/elastic physics:

  - Bounces (coefficient-of-restitution model): a ball dropped over time
    `T` then bounces with each round-trip taking `2T · cor^n`. Total
    runtime is `T · (1 + 2 · Σ cor^n)`, so the transition fraction is
    `1 / (1 + 2 · Σ cor^n)`.
  - Elastics (exponentially decaying sine): each cycle takes `T /
    elasticity`, and the envelope drops below 1% of amplitude after
    `log₂(100) / decay` baseline-seconds. Total oscillation time is
    therefore `T · log₂(100) / decay`, giving a transition fraction of
    `decay / (decay + log₂(100))`.

For `*InOut` variants the "transition" is the bridge between the two
halves; the in-bounces and out-bounces extend beyond it on either side.

The value is independent of `velocityFactor`/`durationMs` because every
time in the formula scales linearly with `T`, so `T` cancels in the
ratio. This means the function only needs the `Easing` value, not the
duration.

-}
transitionFractionOf : Easing -> Float
transitionFractionOf easing =
    case easing of
        BounceOutCustom strength ->
            customBounceFraction strength

        BounceInCustom strength ->
            customBounceFraction strength

        BounceInOutCustom ( strengthIn, strengthOut ) ->
            inOutBounceFraction (customBounceFraction strengthIn) (customBounceFraction strengthOut)

        BounceOutAdvanced params ->
            advancedBounceFraction params

        BounceInAdvanced params ->
            advancedBounceFraction params

        BounceInOutAdvanced params ->
            inOutBounceFraction (advancedBounceFraction params.in_) (advancedBounceFraction params.out)

        ElasticOutCustom strength ->
            customElasticFraction strength

        ElasticInCustom strength ->
            customElasticFraction strength

        ElasticInOutCustom ( strengthIn, strengthOut ) ->
            inOutBounceFraction (customElasticFraction strengthIn) (customElasticFraction strengthOut)

        ElasticOutAdvanced params ->
            advancedElasticFraction params

        ElasticInAdvanced params ->
            advancedElasticFraction params

        ElasticInOutAdvanced params ->
            inOutBounceFraction (advancedElasticFraction params.in_) (advancedElasticFraction params.out)

        _ ->
            -- Simple easings (Linear, CubicBezier, Quad/Cubic/Quart/etc.,
            -- and the algebraic Back*Custom variants) are the transition
            -- itself — nothing extends beyond.
            1.0


{-| Bounce-physics transition fraction from a single 0..1 strength knob.
Mirrors `customBounceParams` in `Shared.Easing.Keyframes` so all engines
agree on the same physics.
-}
customBounceFraction : Float -> Float
customBounceFraction strength =
    let
        clamped =
            clamp 0.1 1.0 strength

        cor =
            0.5 + (clamped * 0.25)

        firstAmplitude =
            0.15 + (clamped * clamped * 0.75)

        bounces =
            visibleBounces 0.02 cor firstAmplitude
    in
    bounceFractionFromCor cor bounces


{-| Advanced bounce variant: derive an effective coefficient of
restitution from the exponential `decay` parameter so the same physics
formula applies. Heights ratio per bounce is `2 ^ -decay`, which equals
`cor ^ 2`, so `cor = 2 ^ (-decay / 2)`.
-}
advancedBounceFraction : { a | bounces : Int, decay : Float } -> Float
advancedBounceFraction params =
    let
        cor =
            2 ^ (-params.decay / 2)
    in
    bounceFractionFromCor cor (max 1 params.bounces)


{-| Common bounce-physics formula: `1 / (1 + 2 · Σₙ₌₁··N corⁿ)`.
The geometric sum has a closed form: `Σₙ₌₁··N rⁿ = r · (1 - rᴺ) / (1 - r)`.
-}
bounceFractionFromCor : Float -> Int -> Float
bounceFractionFromCor cor bounces =
    if cor <= 0 || cor >= 1 then
        1.0

    else
        let
            n =
                toFloat bounces

            sumOfHeights =
                cor * (1.0 - cor ^ n) / (1.0 - cor)
        in
        1.0 / (1.0 + 2.0 * sumOfHeights)


{-| Count visible bounces under a coefficient-of-restitution decay,
mirroring `Shared.Easing.Keyframes.countVisibleBounces` so both modules
agree.
-}
visibleBounces : Float -> Float -> Float -> Int
visibleBounces minVisibleHeight cor start =
    let
        step current count =
            if current < minVisibleHeight || count >= 6 then
                count

            else
                step (current * cor * cor) (count + 1)
    in
    max 1 (step start 0)


{-| Elastic-physics transition fraction from a single 0..1 strength knob.
Mirrors `customElasticParams` in `Shared.Easing.Keyframes`.
-}
customElasticFraction : Float -> Float
customElasticFraction strength =
    let
        clamped =
            clamp 0.1 1.0 strength

        decay =
            6 + (clamped * 2)
    in
    elasticFractionFromDecay decay


{-| Advanced elastic variant: read the `decay` parameter directly.
-}
advancedElasticFraction : { a | decay : Float } -> Float
advancedElasticFraction params =
    elasticFractionFromDecay params.decay


{-| Common elastic-physics formula: `decay / (decay + log₂(100))`.
`log₂(100) ≈ 6.6438` is the cycles-baseline needed for the envelope
to fall below 1% of amplitude.
-}
elasticFractionFromDecay : Float -> Float
elasticFractionFromDecay decay =
    if decay <= 0 then
        1.0

    else
        decay / (decay + logBase 2 100)


{-| Combine the two halves of an `*InOut` variant into a single
transition fraction.

For `*InOut` the user's duration represents the bridge between the two
halves. Each half has its own out-bounce/in-bounce sequence whose
length relative to the bridge is `(1 - halfFraction) / halfFraction`.
Total extension factor = `1 + (in-extension) + (out-extension)`, and
the transition fraction is the reciprocal.

-}
inOutBounceFraction : Float -> Float -> Float
inOutBounceFraction inHalfFraction outHalfFraction =
    let
        inExtension =
            (1.0 - inHalfFraction) / inHalfFraction

        outExtension =
            (1.0 - outHalfFraction) / outHalfFraction
    in
    1.0 / (1.0 + inExtension + outExtension)
