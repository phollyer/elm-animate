module Shared.SpringSpec exposing (suite)

import Expect
import Shared.Spring as Spring
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Shared.Spring"
        [ initialConditionsTests
        , convergenceTests
        , regimeShapeTests
        , analyticalReferenceTests
        , initialVelocityTests
        , bakeTests
        , settleTimeTests
        , degenerateTests
        ]



-- ============================================================
-- TEST FIXTURES
-- ============================================================
--
-- Reusable spring presets that exercise each damping regime.


underdampedSpring : Spring.SpringConfig
underdampedSpring =
    -- ζ = 0.1, oscillates plenty
    { stiffness = 100, damping = 2, mass = 1, initialVelocity = 0 }


criticallyDampedSpring : Spring.SpringConfig
criticallyDampedSpring =
    -- ζ = 1 exactly: c = 2·√(k·m) = 20
    { stiffness = 100, damping = 20, mass = 1, initialVelocity = 0 }


overdampedSpring : Spring.SpringConfig
overdampedSpring =
    -- ζ = 2
    { stiffness = 100, damping = 40, mass = 1, initialVelocity = 0 }


zeroToOne : Spring.SpringConfig -> Spring.MotionParams
zeroToOne spring =
    { spring = spring, from = 0, to = 1 }



-- ============================================================
-- INITIAL CONDITIONS
-- ============================================================


initialConditionsTests : Test
initialConditionsTests =
    describe "initial conditions"
        [ test "valueAt 0 returns from" <|
            \_ ->
                Spring.valueAt (zeroToOne underdampedSpring) 0
                    |> Expect.within (Expect.Absolute 1.0e-9) 0
        , test "valueAt 0 returns from (critically damped)" <|
            \_ ->
                Spring.valueAt (zeroToOne criticallyDampedSpring) 0
                    |> Expect.within (Expect.Absolute 1.0e-9) 0
        , test "valueAt 0 returns from (overdamped)" <|
            \_ ->
                Spring.valueAt (zeroToOne overdampedSpring) 0
                    |> Expect.within (Expect.Absolute 1.0e-9) 0
        , test "valueAt 0 returns from when from is non-zero" <|
            \_ ->
                Spring.valueAt
                    { spring = underdampedSpring, from = 50, to = 200 }
                    0
                    |> Expect.within (Expect.Absolute 1.0e-9) 50
        , test "velocityAt 0 returns initialVelocity (zero)" <|
            \_ ->
                Spring.velocityAt (zeroToOne underdampedSpring) 0
                    |> Expect.within (Expect.Absolute 1.0e-9) 0
        , test "velocityAt 0 returns initialVelocity (non-zero)" <|
            \_ ->
                let
                    spring =
                        { underdampedSpring | initialVelocity = 12.5 }
                in
                Spring.velocityAt { spring = spring, from = 0, to = 1 } 0
                    |> Expect.within (Expect.Absolute 1.0e-9) 12.5
        ]



-- ============================================================
-- CONVERGENCE
-- ============================================================


convergenceTests : Test
convergenceTests =
    describe "convergence to target"
        [ test "settles to target after long time (underdamped)" <|
            \_ ->
                Spring.valueAt (zeroToOne underdampedSpring) 20000
                    |> Expect.within (Expect.Absolute 0.001) 1
        , test "settles to target after long time (critically damped)" <|
            \_ ->
                Spring.valueAt (zeroToOne criticallyDampedSpring) 20000
                    |> Expect.within (Expect.Absolute 0.001) 1
        , test "settles to target after long time (overdamped)" <|
            \_ ->
                Spring.valueAt (zeroToOne overdampedSpring) 20000
                    |> Expect.within (Expect.Absolute 0.001) 1
        , test "velocity decays to zero at long time" <|
            \_ ->
                Spring.velocityAt (zeroToOne underdampedSpring) 20000
                    |> Expect.within (Expect.Absolute 0.001) 0
        ]



-- ============================================================
-- REGIME SHAPE PROPERTIES
-- ============================================================


regimeShapeTests : Test
regimeShapeTests =
    describe "regime shape properties"
        [ test "underdamped overshoots target at least once" <|
            \_ ->
                let
                    params =
                        zeroToOne underdampedSpring

                    -- Sample across one expected oscillation cycle
                    -- (T = 2π/ω_d ≈ 2π/√(k/m·(1-ζ²)) ≈ 0.63s for these params).
                    samples =
                        List.range 1 200
                            |> List.map
                                (\i ->
                                    Spring.valueAt params (toFloat i * 5)
                                )

                    overshot =
                        List.any (\v -> v > 1.0001) samples
                in
                if overshot then
                    Expect.pass

                else
                    Expect.fail
                        "expected underdamped spring to overshoot 1.0 at some sample"
        , test "critically damped does not overshoot target" <|
            \_ ->
                let
                    params =
                        zeroToOne criticallyDampedSpring

                    samples =
                        List.range 0 1000
                            |> List.map
                                (\i ->
                                    Spring.valueAt params (toFloat i * 10)
                                )

                    maxValue =
                        List.maximum samples |> Maybe.withDefault 0
                in
                maxValue
                    |> Expect.atMost 1.0001
        , test "overdamped does not overshoot target" <|
            \_ ->
                let
                    params =
                        zeroToOne overdampedSpring

                    samples =
                        List.range 0 1000
                            |> List.map
                                (\i ->
                                    Spring.valueAt params (toFloat i * 10)
                                )

                    maxValue =
                        List.maximum samples |> Maybe.withDefault 0
                in
                maxValue
                    |> Expect.atMost 1.0001
        ]



-- ============================================================
-- ANALYTICAL REFERENCE
-- ============================================================
--
-- Hand-computed reference points for each regime's closed-form
-- solution. Catches sign errors and coefficient-derivation mistakes.


analyticalReferenceTests : Test
analyticalReferenceTests =
    describe "analytical reference points"
        [ test "undamped (ζ=0) yields x(t) = cos(t) for ω₀=1" <|
            \_ ->
                -- k=1, m=1, c=0 → ω₀=1, ζ=0.
                -- x₀ = from - to = 1, v₀ = 0.
                -- x(t) = cos(t). At t=π sec, x = -1, position = to + x = -1.
                let
                    params =
                        { spring =
                            { stiffness = 1
                            , damping = 0
                            , mass = 1
                            , initialVelocity = 0
                            }
                        , from = 1
                        , to = 0
                        }
                in
                Spring.valueAt params (pi * 1000)
                    |> Expect.within (Expect.Absolute 1.0e-6) -1
        , test "critically damped reference at t=1s" <|
            \_ ->
                -- k=1, m=1, c=2 → ω₀=1, ζ=1. A=1, B=1.
                -- x(t) = (1+t)e^(-t). At t=1, x = 2/e ≈ 0.7357588823428847.
                let
                    params =
                        { spring =
                            { stiffness = 1
                            , damping = 2
                            , mass = 1
                            , initialVelocity = 0
                            }
                        , from = 1
                        , to = 0
                        }
                in
                Spring.valueAt params 1000
                    |> Expect.within (Expect.Absolute 1.0e-6) (2 / e)
        , test "overdamped reference at t=1s" <|
            \_ ->
                -- k=1, m=1, c=4 → ω₀=1, ζ=2.
                -- r₁ = -(2-√3) ≈ -0.2679, r₂ = -(2+√3) ≈ -3.7321.
                -- A = (0 - r₂·1)/(r₁-r₂) = (2+√3)/(2√3) = (2+√3)/(2√3).
                -- B = 1 - A.
                -- x(1) = A·e^r₁ + B·e^r₂.
                let
                    params =
                        { spring =
                            { stiffness = 1
                            , damping = 4
                            , mass = 1
                            , initialVelocity = 0
                            }
                        , from = 1
                        , to = 0
                        }

                    sqrt3 =
                        sqrt 3

                    r1 =
                        -(2 - sqrt3)

                    r2 =
                        -(2 + sqrt3)

                    a =
                        (2 + sqrt3) / (2 * sqrt3)

                    b =
                        1 - a

                    expected =
                        a * e ^ r1 + b * e ^ r2
                in
                Spring.valueAt params 1000
                    |> Expect.within (Expect.Absolute 1.0e-9) expected
        ]



-- ============================================================
-- INITIAL VELOCITY
-- ============================================================


initialVelocityTests : Test
initialVelocityTests =
    describe "initial velocity"
        [ test "positive initial velocity moves position forward at small t" <|
            \_ ->
                let
                    base =
                        zeroToOne criticallyDampedSpring

                    boosted =
                        { base
                            | spring =
                                { criticallyDampedSpring | initialVelocity = 10 }
                        }

                    -- At a small dt the velocity-driven term dominates.
                    -- Both start at 0; the boosted one should be ahead.
                    baseAt =
                        Spring.valueAt base 50

                    boostedAt =
                        Spring.valueAt boosted 50
                in
                if boostedAt > baseAt then
                    Expect.pass

                else
                    Expect.fail
                        ("expected boosted ("
                            ++ String.fromFloat boostedAt
                            ++ ") > base ("
                            ++ String.fromFloat baseAt
                            ++ ")"
                        )
        , test "initial velocity affects velocityAt 0 directly" <|
            \_ ->
                let
                    spring =
                        { underdampedSpring | initialVelocity = -7.5 }
                in
                Spring.velocityAt { spring = spring, from = 0, to = 1 } 0
                    |> Expect.within (Expect.Absolute 1.0e-9) -7.5
        ]



-- ============================================================
-- BAKE
-- ============================================================


bakeTests : Test
bakeTests =
    describe "bake"
        [ test "returns 60 samples" <|
            \_ ->
                Spring.bake (zeroToOne underdampedSpring)
                    |> .samples
                    |> List.length
                    |> Expect.equal 60
        , test "first sample offset is 0 with value = from" <|
            \_ ->
                let
                    samples =
                        Spring.bake { spring = underdampedSpring, from = 50, to = 200 }
                            |> .samples
                in
                case List.head samples of
                    Just ( o, v ) ->
                        Expect.all
                            [ \_ -> Expect.within (Expect.Absolute 1.0e-9) 0 o
                            , \_ -> Expect.within (Expect.Absolute 1.0e-9) 50 v
                            ]
                            ()

                    Nothing ->
                        Expect.fail "expected at least one sample"
        , test "last sample offset is 1 with value = to" <|
            \_ ->
                let
                    samples =
                        Spring.bake { spring = underdampedSpring, from = 50, to = 200 }
                            |> .samples
                in
                case List.reverse samples |> List.head of
                    Just ( o, v ) ->
                        Expect.all
                            [ \_ -> Expect.within (Expect.Absolute 1.0e-9) 1 o
                            , \_ -> Expect.within (Expect.Absolute 1.0e-9) 200 v
                            ]
                            ()

                    Nothing ->
                        Expect.fail "expected at least one sample"
        , test "offsets are strictly increasing" <|
            \_ ->
                let
                    offsets =
                        Spring.bake (zeroToOne underdampedSpring)
                            |> .samples
                            |> List.map Tuple.first

                    increasingPairs =
                        List.map2 (\a b -> b > a) offsets (List.drop 1 offsets)
                in
                if List.all identity increasingPairs then
                    Expect.pass

                else
                    Expect.fail "expected strictly increasing offsets"
        , test "durationMs > 0 for meaningful motion" <|
            \_ ->
                Spring.bake (zeroToOne underdampedSpring)
                    |> .durationMs
                    |> Expect.greaterThan 0
        , test "durationMs honours 8 second cap" <|
            \_ ->
                Spring.bake (zeroToOne underdampedSpring)
                    |> .durationMs
                    |> Expect.atMost 8000
        ]



-- ============================================================
-- SETTLE TIME
-- ============================================================


settleTimeTests : Test
settleTimeTests =
    describe "settleTimeMs"
        [ test "is 0 when from == to and velocity == 0" <|
            \_ ->
                Spring.settleTimeMs
                    { spring = underdampedSpring, from = 5, to = 5 }
                    |> Expect.within (Expect.Absolute 1.0e-9) 0
        , test "is positive when from /= to" <|
            \_ ->
                Spring.settleTimeMs (zeroToOne underdampedSpring)
                    |> Expect.greaterThan 0
        , test "is bounded by 8 seconds" <|
            \_ ->
                Spring.settleTimeMs (zeroToOne underdampedSpring)
                    |> Expect.atMost 8000
        , test "stiffer spring settles faster than softer" <|
            \_ ->
                let
                    stiff =
                        Spring.settleTimeMs
                            { spring =
                                { stiffness = 400
                                , damping = 40
                                , mass = 1
                                , initialVelocity = 0
                                }
                            , from = 0
                            , to = 1
                            }

                    soft =
                        Spring.settleTimeMs
                            { spring =
                                { stiffness = 50
                                , damping = 14
                                , mass = 1
                                , initialVelocity = 0
                                }
                            , from = 0
                            , to = 1
                            }
                in
                stiff |> Expect.lessThan soft
        ]



-- ============================================================
-- DEGENERATE INPUTS
-- ============================================================
--
-- The solver should never crash or NaN regardless of how silly the
-- caller's numbers are. Validation belongs at the public-API boundary,
-- not here.


degenerateTests : Test
degenerateTests =
    describe "degenerate inputs do not crash"
        [ test "from == to with zero velocity stays at value" <|
            \_ ->
                Spring.valueAt
                    { spring = underdampedSpring, from = 7, to = 7 }
                    500
                    |> Expect.within (Expect.Absolute 1.0e-9) 7
        , test "zero stiffness does not produce NaN" <|
            \_ ->
                let
                    v =
                        Spring.valueAt
                            { spring =
                                { stiffness = 0
                                , damping = 5
                                , mass = 1
                                , initialVelocity = 0
                                }
                            , from = 0
                            , to = 1
                            }
                            500
                in
                if isNaN v then
                    Expect.fail "produced NaN"

                else
                    Expect.pass
        , test "zero damping (undamped) does not crash" <|
            \_ ->
                let
                    v =
                        Spring.valueAt
                            { spring =
                                { stiffness = 100
                                , damping = 0
                                , mass = 1
                                , initialVelocity = 0
                                }
                            , from = 0
                            , to = 1
                            }
                            500
                in
                if isNaN v then
                    Expect.fail "produced NaN"

                else
                    Expect.pass
        , test "zero mass clamps to safe value" <|
            \_ ->
                let
                    v =
                        Spring.valueAt
                            { spring =
                                { stiffness = 100
                                , damping = 10
                                , mass = 0
                                , initialVelocity = 0
                                }
                            , from = 0
                            , to = 1
                            }
                            500
                in
                if isNaN v || isInfinite v then
                    Expect.fail "produced non-finite value"

                else
                    Expect.pass
        ]
