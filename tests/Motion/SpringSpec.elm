module Motion.SpringSpec exposing (suite)

import Expect
import Motion.Internal.Spring as Internal
import Motion.Spring as Spring
import Shared.Spring as Solver
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Motion.Spring"
        [ presetTests
        , customTests
        , presetBehaviourTests
        ]



-- ============================================================
-- PRESET CONFIGURATIONS
-- ============================================================
--
-- Lock in the preset values so future tweaks have to be intentional
-- (and visible in the test diff). Numbers come straight from the
-- module source.


presetTests : Test
presetTests =
    describe "preset values"
        [ test "gentle" <|
            \_ ->
                Spring.gentle
                    |> Internal.unwrap
                    |> Expect.equal
                        { stiffness = 120
                        , damping = 14
                        , mass = 1
                        , initialVelocity = 0
                        }
        , test "wobbly" <|
            \_ ->
                Spring.wobbly
                    |> Internal.unwrap
                    |> Expect.equal
                        { stiffness = 180
                        , damping = 12
                        , mass = 1
                        , initialVelocity = 0
                        }
        , test "stiff" <|
            \_ ->
                Spring.stiff
                    |> Internal.unwrap
                    |> Expect.equal
                        { stiffness = 300
                        , damping = 20
                        , mass = 1
                        , initialVelocity = 0
                        }
        , test "slow" <|
            \_ ->
                Spring.slow
                    |> Internal.unwrap
                    |> Expect.equal
                        { stiffness = 60
                        , damping = 18
                        , mass = 1
                        , initialVelocity = 0
                        }
        , test "noWobble (critically damped)" <|
            \_ ->
                let
                    config =
                        Internal.unwrap Spring.noWobble

                    zeta =
                        config.damping
                            / (2 * sqrt (config.stiffness * config.mass))
                in
                -- Should be at or very near critically damped.
                zeta |> Expect.within (Expect.Absolute 0.01) 1.0
        ]



-- ============================================================
-- CUSTOM CONSTRUCTOR
-- ============================================================


customTests : Test
customTests =
    describe "custom"
        [ test "passes through valid values unchanged" <|
            \_ ->
                Spring.custom
                    { stiffness = 250
                    , damping = 18
                    , mass = 1.5
                    }
                    |> Internal.unwrap
                    |> Expect.equal
                        { stiffness = 250
                        , damping = 18
                        , mass = 1.5
                        , initialVelocity = 0
                        }
        , test "clamps negative stiffness to 0" <|
            \_ ->
                Spring.custom
                    { stiffness = -10
                    , damping = 18
                    , mass = 1
                    }
                    |> Internal.unwrap
                    |> .stiffness
                    |> Expect.within (Expect.Absolute 1.0e-9) 0
        , test "clamps negative damping to 0" <|
            \_ ->
                Spring.custom
                    { stiffness = 100
                    , damping = -5
                    , mass = 1
                    }
                    |> Internal.unwrap
                    |> .damping
                    |> Expect.within (Expect.Absolute 1.0e-9) 0
        , test "clamps zero mass to 1e-6" <|
            \_ ->
                Spring.custom
                    { stiffness = 100
                    , damping = 10
                    , mass = 0
                    }
                    |> Internal.unwrap
                    |> .mass
                    |> Expect.within (Expect.Absolute 1.0e-12) 1.0e-6
        , test "always sets initialVelocity to 0" <|
            \_ ->
                -- withVelocity is deferred per Q4; until it ships,
                -- custom must always produce zero v0.
                Spring.custom
                    { stiffness = 100
                    , damping = 10
                    , mass = 1
                    }
                    |> Internal.unwrap
                    |> .initialVelocity
                    |> Expect.within (Expect.Absolute 1.0e-9) 0
        ]



-- ============================================================
-- PRESET BEHAVIOUR
-- ============================================================
--
-- Sanity-check that each preset produces motion with the qualitative
-- character its name promises, by running it through the solver.


presetBehaviourTests : Test
presetBehaviourTests =
    describe "preset behaviour"
        [ test "gentle settles within 8 seconds" <|
            \_ ->
                Solver.settleTimeMs (motion Spring.gentle)
                    |> Expect.atMost 8000
        , test "wobbly overshoots target" <|
            \_ ->
                let
                    params =
                        motion Spring.wobbly

                    samples =
                        List.range 1 200
                            |> List.map
                                (\i -> Solver.valueAt params (toFloat i * 5))

                    overshot =
                        List.any (\v -> v > 1.0001) samples
                in
                if overshot then
                    Expect.pass

                else
                    Expect.fail "expected wobbly to overshoot target"
        , test "noWobble does not overshoot target" <|
            \_ ->
                let
                    params =
                        motion Spring.noWobble

                    samples =
                        List.range 0 1000
                            |> List.map
                                (\i -> Solver.valueAt params (toFloat i * 10))

                    maxValue =
                        List.maximum samples |> Maybe.withDefault 0
                in
                maxValue |> Expect.atMost 1.0001
        , test "stiff settles faster than slow" <|
            \_ ->
                let
                    stiffSettle =
                        Solver.settleTimeMs (motion Spring.stiff)

                    slowSettle =
                        Solver.settleTimeMs (motion Spring.slow)
                in
                stiffSettle |> Expect.lessThan slowSettle
        ]



-- ============================================================
-- HELPERS
-- ============================================================


motion : Spring.Spring -> Solver.MotionParams
motion spring =
    { spring = Internal.unwrap spring
    , from = 0
    , to = 1
    }
