module Shared.Spring exposing
    ( MotionParams
    , SpringConfig
    , bake
    , settleTimeMs
    , valueAt
    , velocityAt
    )

{-| Analytical damped-harmonic-oscillator solver for spring-based motion.

Solves the standard second-order ODE

    m · ẍ + c · ẋ + k · x = 0

in closed form across all three damping regimes (under-, critically-,
over-damped). No numerical integration: every query is O(1) regardless
of how far along in time it is.

The variable `x` represents _displacement from the target_, so a
configuration animating from value `f` to value `t` is solved with
initial conditions `x(0) = f - t`, `ẋ(0) = initialVelocity`. Position
at time `τ` is then `t + x(τ)`.

Time is exposed in milliseconds at the API boundary (consistent with
the rest of the codebase) and converted to seconds internally for the
physics math.

-}


{-| Spring configuration.

  - `stiffness` — Hooke's-law `k`. Higher = snappier. Typical 100..400.
  - `damping` — viscous-friction `c`. Higher = less wobble. Typical 10..40.
  - `mass` — oscillator `m`. Typical 1.0.
  - `initialVelocity` — `ẋ(0)` in units per second. Zero unless handing
    off from a gesture.

The damping ratio `ζ = c / (2·√(k·m))` determines which regime applies:

  - `ζ < 1` — under-damped, oscillates and decays
  - `ζ = 1` — critically damped, fastest no-overshoot settle
  - `ζ > 1` — over-damped, slow no-overshoot approach

-}
type alias SpringConfig =
    { stiffness : Float
    , damping : Float
    , mass : Float
    , initialVelocity : Float
    }


{-| The combined inputs to a single spring motion: a configuration plus
the start and end values.
-}
type alias MotionParams =
    { spring : SpringConfig
    , from : Float
    , to : Float
    }


{-| Position at the given time (in milliseconds from motion start).

Returns `from` at `timeMs = 0` and converges to `to` as `timeMs`
increases past the settle time.

-}
valueAt : MotionParams -> Float -> Float
valueAt params timeMs =
    params.to + displacement (precompute params) (timeMs / 1000.0)


{-| Velocity at the given time, in units per second.

Returns `spring.initialVelocity` at `timeMs = 0` and converges to 0 as
`timeMs` increases past the settle time.

-}
velocityAt : MotionParams -> Float -> Float
velocityAt params timeMs =
    velocity (precompute params) (timeMs / 1000.0)


{-| Time at which the motion is considered settled, in milliseconds.

Settled means displacement and velocity have both decayed below a
visually negligible threshold. Hard-capped at 8 seconds to keep keyframe
arrays bounded for pathological configurations (e.g. very low stiffness,
near-zero damping).

-}
settleTimeMs : MotionParams -> Float
settleTimeMs params =
    settleTimeS (precompute params) * 1000.0


{-| Bake the motion to keyframe samples for engines that need a static
representation (Keyframe `@keyframes` stops, WAAPI `easingKeyframes`
arrays, scroll-timeline scrubbing).

Returns:

  - `durationMs` — total wall-clock time the motion takes to settle.
    Engines should use this as the animation's `duration` so that the
    baked samples play out at real-time speed.
  - `samples` — list of `(offset, value)` pairs where `offset` is the
    fraction of `durationMs` (i.e. `0..1`) and `value` is the position
    at that point in time. The first sample is `(0, from)` and the last
    sample is `(1, to)`.

The sample count is fixed at 60 for now (uniform spacing in time);
non-uniform peak-aware placement is a possible future refinement.

-}
bake :
    MotionParams
    -> { durationMs : Float, samples : List ( Float, Float ) }
bake params =
    let
        sol =
            precompute params

        durationS =
            settleTimeS sol

        durationMs =
            durationS * 1000.0

        n =
            60

        sampleAt i =
            let
                offset =
                    toFloat i / toFloat (n - 1)

                tSec =
                    offset * durationS
            in
            ( offset, params.to + displacement sol tSec )

        rawSamples =
            List.map sampleAt (List.range 0 (n - 1))
    in
    { durationMs = durationMs
    , samples = snapEndpoints params.from params.to rawSamples
    }


{-| Replace the first sample's value with `from` exactly and the last
sample's value with `to` exactly. Guards against floating-point drift
or the rare case where the settle threshold leaves a hairline error in
the final sample.
-}
snapEndpoints : Float -> Float -> List ( Float, Float ) -> List ( Float, Float )
snapEndpoints from to samples =
    case samples of
        [] ->
            []

        ( firstOffset, _ ) :: rest ->
            let
                withSnappedHead =
                    ( firstOffset, from ) :: rest
            in
            case List.reverse withSnappedHead of
                ( lastOffset, _ ) :: tail ->
                    List.reverse (( lastOffset, to ) :: tail)

                [] ->
                    withSnappedHead



-- ============================================================
-- ANALYTICAL SOLUTION
-- ============================================================


{-| Pre-computed coefficients for one of the three damping regimes.

Stored as a tagged record so the per-time-step `displacement` and
`velocity` evaluations can branch on regime exactly once and then run
the appropriate closed-form expression.

-}
type Solution
    = Underdamped UnderdampedCoeffs
    | Critically CriticallyDampedCoeffs
    | Overdamped OverdampedCoeffs


type alias UnderdampedCoeffs =
    { omega0 : Float
    , omegaD : Float
    , zeta : Float
    , a : Float
    , b : Float
    }


type alias CriticallyDampedCoeffs =
    { omega0 : Float
    , a : Float
    , b : Float
    }


type alias OverdampedCoeffs =
    { r1 : Float
    , r2 : Float
    , a : Float
    , b : Float
    }


{-| Pick the regime and pre-compute its coefficients from the
configuration and initial conditions.

A small tolerance around `ζ = 1` snaps to the critically-damped formula
so the under-damped (`ω_d → 0`, `B → ∞`) and over-damped (`disc → 0`)
branches stay numerically stable.

-}
precompute : MotionParams -> Solution
precompute { spring, from, to } =
    let
        m =
            max 1.0e-6 spring.mass

        k =
            max 0 spring.stiffness

        c =
            max 0 spring.damping

        omega0 =
            sqrt (k / m)

        zeta =
            if k <= 0 then
                1.0

            else
                c / (2.0 * sqrt (k * m))

        x0 =
            from - to

        v0 =
            spring.initialVelocity
    in
    if abs (zeta - 1.0) < 1.0e-4 then
        Critically
            { omega0 = omega0
            , a = x0
            , b = v0 + omega0 * x0
            }

    else if zeta < 1.0 then
        let
            omegaD =
                omega0 * sqrt (1.0 - zeta * zeta)
        in
        Underdamped
            { omega0 = omega0
            , omegaD = omegaD
            , zeta = zeta
            , a = x0
            , b = (v0 + zeta * omega0 * x0) / omegaD
            }

    else
        let
            disc =
                sqrt (zeta * zeta - 1.0)

            r1 =
                -omega0 * (zeta - disc)

            r2 =
                -omega0 * (zeta + disc)

            a =
                (v0 - r2 * x0) / (r1 - r2)
        in
        Overdamped
            { r1 = r1
            , r2 = r2
            , a = a
            , b = x0 - a
            }


{-| Displacement `x(t)` (relative to target) at time `t` in seconds.
-}
displacement : Solution -> Float -> Float
displacement sol t =
    case sol of
        Underdamped { omega0, omegaD, zeta, a, b } ->
            e
                ^ (-zeta * omega0 * t)
                * (a * cos (omegaD * t) + b * sin (omegaD * t))

        Critically { omega0, a, b } ->
            (a + b * t) * e ^ (-omega0 * t)

        Overdamped { r1, r2, a, b } ->
            a * e ^ (r1 * t) + b * e ^ (r2 * t)


{-| Velocity `ẋ(t)` (units per second) at time `t` in seconds.
-}
velocity : Solution -> Float -> Float
velocity sol t =
    case sol of
        Underdamped { omega0, omegaD, zeta, a, b } ->
            let
                env =
                    e ^ (-zeta * omega0 * t)

                cosWdT =
                    cos (omegaD * t)

                sinWdT =
                    sin (omegaD * t)
            in
            env
                * ((b * omegaD - zeta * omega0 * a)
                    * cosWdT
                    - (a * omegaD + zeta * omega0 * b)
                    * sinWdT
                  )

        Critically { omega0, a, b } ->
            (b - omega0 * a - omega0 * b * t) * e ^ (-omega0 * t)

        Overdamped { r1, r2, a, b } ->
            a * r1 * e ^ (r1 * t) + b * r2 * e ^ (r2 * t)


{-| Time (in seconds) at which the motion is considered settled.

For each regime, settle time is derived from the position envelope so
that `|x(t)| < ε` after that point. The velocity decays with at least
the same exponential rate as position in every regime, so the position
bound is sufficient.

Hard-capped at 8 seconds for pathological configurations (very low
stiffness, near-zero damping).

-}
settleTimeS : Solution -> Float
settleTimeS sol =
    let
        epsilon =
            0.005

        cap =
            8.0
    in
    case sol of
        Underdamped { omega0, zeta, a, b } ->
            if zeta * omega0 <= 0 then
                cap

            else
                let
                    envMax =
                        sqrt (a * a + b * b)
                in
                if envMax <= epsilon then
                    0.0

                else
                    min cap (logBase e (envMax / epsilon) / (zeta * omega0))

        Critically { omega0, a, b } ->
            if omega0 <= 0 then
                cap

            else
                let
                    -- Loose envelope on |(a + b·t)·e^(-ω₀·t)|: the
                    -- linear factor's worst case at the (a + b·t) peak
                    -- is bounded by |a| + |b| / ω₀ once divided by the
                    -- exponential decay.
                    envMax =
                        abs a + abs b / omega0
                in
                if envMax <= epsilon then
                    0.0

                else
                    min cap (logBase e (envMax / epsilon) / omega0)

        Overdamped { r1, r2, a, b } ->
            let
                -- The smaller-magnitude root decays slowest, so its
                -- coefficient dominates the tail.
                ( slowR, slowCoef ) =
                    if abs r1 < abs r2 then
                        ( r1, a )

                    else
                        ( r2, b )
            in
            if slowR >= 0 || abs slowCoef <= epsilon then
                cap

            else
                min cap (logBase e (abs slowCoef / epsilon) / abs slowR)
