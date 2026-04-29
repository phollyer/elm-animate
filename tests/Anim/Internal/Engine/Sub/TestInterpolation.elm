module Anim.Internal.Engine.Sub.TestInterpolation exposing (suite)

import Anim.Internal.Engine.Sub.Animation exposing (PropertyAnimation)
import Anim.Internal.Engine.Sub.Interpolation as Interpolation
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Internal.Engine.Sub.Interpolation"
        [ calculateProgressSuite
        , interpolateFloatSuite
        , interpolateEasedProgressSuite
        ]



-- ============================================================
-- CALCULATE PROGRESS
-- ============================================================


calculateProgressSuite : Test
calculateProgressSuite =
    describe "calculateProgress"
        [ describe "basic progress"
            [ test "elapsed 0 gives progress 0" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 0
                        , delayMs = 0
                        , totalDurationMs = 1000
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 0.0
            , test "elapsed half gives progress 0.5" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 500
                        , delayMs = 0
                        , totalDurationMs = 1000
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 0.5
            , test "elapsed full gives progress 1.0" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 1000
                        , delayMs = 0
                        , totalDurationMs = 1000
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 1.0
            , test "elapsed quarter gives progress 0.25" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 250
                        , delayMs = 0
                        , totalDurationMs = 1000
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 0.25
            , test "elapsed three quarters gives progress 0.75" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 750
                        , delayMs = 0
                        , totalDurationMs = 1000
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 0.75
            ]
        , describe "delay handling"
            [ test "elapsed within delay gives progress 0" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 200
                        , delayMs = 500
                        , totalDurationMs = 1000
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 0.0
            , test "elapsed at delay boundary gives progress 0" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 500
                        , delayMs = 500
                        , totalDurationMs = 1000
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 0.0
            , test "elapsed past delay by half duration gives progress 0.5" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 1000
                        , delayMs = 500
                        , totalDurationMs = 1000
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 0.5
            , test "elapsed past delay by full duration gives progress 1.0" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 1500
                        , delayMs = 500
                        , totalDurationMs = 1000
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 1.0
            ]
        , describe "clamping"
            [ test "elapsed beyond duration clamps to 1.0" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 2000
                        , delayMs = 0
                        , totalDurationMs = 1000
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 1.0
            , test "negative elapsed treated as 0 progress" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = -100
                        , delayMs = 0
                        , totalDurationMs = 1000
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 0.0
            ]
        , describe "isComplete flag"
            [ test "isComplete true always returns 1.0 regardless of elapsed" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 0
                        , delayMs = 0
                        , totalDurationMs = 1000
                        , isComplete = True
                        }
                        |> Expect.within (Expect.Absolute 0.001) 1.0
            , test "isComplete true with partial elapsed still returns 1.0" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 300
                        , delayMs = 0
                        , totalDurationMs = 1000
                        , isComplete = True
                        }
                        |> Expect.within (Expect.Absolute 0.001) 1.0
            ]
        , describe "zero duration"
            [ test "zero duration returns 1.0" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 0
                        , delayMs = 0
                        , totalDurationMs = 0
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 1.0
            , test "negative duration returns 1.0" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 500
                        , delayMs = 0
                        , totalDurationMs = -100
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 1.0
            ]
        , describe "very small durations"
            [ test "1ms duration at 0.5ms gives 0.5" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 0.5
                        , delayMs = 0
                        , totalDurationMs = 1
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 0.5
            , test "very long duration at halfway" <|
                \_ ->
                    Interpolation.calculateProgress
                        { elapsedMs = 50000
                        , delayMs = 0
                        , totalDurationMs = 100000
                        , isComplete = False
                        }
                        |> Expect.within (Expect.Absolute 0.001) 0.5
            ]
        ]



-- ============================================================
-- INTERPOLATE FLOAT
-- ============================================================


interpolateFloatSuite : Test
interpolateFloatSuite =
    describe "interpolateFloat"
        [ describe "basic interpolation"
            [ test "t=0 returns start" <|
                \_ ->
                    Interpolation.interpolateFloat 0.0 10 50
                        |> Expect.within (Expect.Absolute 0.001) 10
            , test "t=1 returns end" <|
                \_ ->
                    Interpolation.interpolateFloat 1.0 10 50
                        |> Expect.within (Expect.Absolute 0.001) 50
            , test "t=0.5 returns midpoint" <|
                \_ ->
                    Interpolation.interpolateFloat 0.5 0 100
                        |> Expect.within (Expect.Absolute 0.001) 50
            , test "t=0.25 returns quarter" <|
                \_ ->
                    Interpolation.interpolateFloat 0.25 0 100
                        |> Expect.within (Expect.Absolute 0.001) 25
            , test "t=0.75 returns three quarters" <|
                \_ ->
                    Interpolation.interpolateFloat 0.75 0 100
                        |> Expect.within (Expect.Absolute 0.001) 75
            ]
        , describe "negative ranges"
            [ test "interpolate with negative start" <|
                \_ ->
                    Interpolation.interpolateFloat 0.5 -100 100
                        |> Expect.within (Expect.Absolute 0.001) 0
            , test "interpolate with both negative" <|
                \_ ->
                    Interpolation.interpolateFloat 0.5 -200 -100
                        |> Expect.within (Expect.Absolute 0.001) -150
            , test "interpolate reversed range (start > end)" <|
                \_ ->
                    Interpolation.interpolateFloat 0.5 100 0
                        |> Expect.within (Expect.Absolute 0.001) 50
            ]
        , describe "same start and end"
            [ test "same values at t=0 returns that value" <|
                \_ ->
                    Interpolation.interpolateFloat 0.0 42 42
                        |> Expect.within (Expect.Absolute 0.001) 42
            , test "same values at t=0.5 returns that value" <|
                \_ ->
                    Interpolation.interpolateFloat 0.5 42 42
                        |> Expect.within (Expect.Absolute 0.001) 42
            , test "same values at t=1 returns that value" <|
                \_ ->
                    Interpolation.interpolateFloat 1.0 42 42
                        |> Expect.within (Expect.Absolute 0.001) 42
            ]
        , describe "out-of-range t values"
            [ test "t < 0 extrapolates below start" <|
                \_ ->
                    Interpolation.interpolateFloat -0.5 0 100
                        |> Expect.within (Expect.Absolute 0.001) -50
            , test "t > 1 extrapolates beyond end" <|
                \_ ->
                    Interpolation.interpolateFloat 1.5 0 100
                        |> Expect.within (Expect.Absolute 0.001) 150
            ]
        , describe "precision"
            [ test "small range interpolation" <|
                \_ ->
                    Interpolation.interpolateFloat 0.5 0.001 0.002
                        |> Expect.within (Expect.Absolute 0.0001) 0.0015
            , test "large range interpolation" <|
                \_ ->
                    Interpolation.interpolateFloat 0.5 0 10000
                        |> Expect.within (Expect.Absolute 0.001) 5000
            ]
        ]



-- ============================================================
-- INTERPOLATE EASED PROGRESS
-- ============================================================


interpolateEasedProgressSuite : Test
interpolateEasedProgressSuite =
    describe "interpolateEasedProgress"
        [ describe "with identity easing (linear)"
            [ test "at t=0 returns start value" <|
                \_ ->
                    makePropertyAnimation
                        { start = 0
                        , end = 100
                        , easingFunction = identity
                        , elapsedMs = 0
                        , delayMs = 0
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 0
            , test "at t=0.5 returns midpoint" <|
                \_ ->
                    makePropertyAnimation
                        { start = 0
                        , end = 100
                        , easingFunction = identity
                        , elapsedMs = 500
                        , delayMs = 0
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 50
            , test "at t=1 returns end value" <|
                \_ ->
                    makePropertyAnimation
                        { start = 0
                        , end = 100
                        , easingFunction = identity
                        , elapsedMs = 1000
                        , delayMs = 0
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 100
            , test "at quarter progress returns quarter value" <|
                \_ ->
                    makePropertyAnimation
                        { start = 0
                        , end = 200
                        , easingFunction = identity
                        , elapsedMs = 250
                        , delayMs = 0
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 50
            ]
        , describe "with custom easing"
            [ test "quadratic ease-in at midpoint" <|
                \_ ->
                    -- easeInQuad: t^2, so at t=0.5 -> 0.25 progress
                    makePropertyAnimation
                        { start = 0
                        , end = 100
                        , easingFunction = \t -> t * t
                        , elapsedMs = 500
                        , delayMs = 0
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 25
            , test "quadratic ease-in at three quarters" <|
                \_ ->
                    -- easeInQuad: t^2, so at t=0.75 -> 0.5625 progress
                    makePropertyAnimation
                        { start = 0
                        , end = 100
                        , easingFunction = \t -> t * t
                        , elapsedMs = 750
                        , delayMs = 0
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 56.25
            , test "ease-out (inverse quad) at midpoint" <|
                \_ ->
                    -- easeOut: 1 - (1-t)^2, so at t=0.5 -> 0.75
                    makePropertyAnimation
                        { start = 0
                        , end = 100
                        , easingFunction = \t -> 1 - (1 - t) ^ 2
                        , elapsedMs = 500
                        , delayMs = 0
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 75
            , test "constant easing always returns end" <|
                \_ ->
                    makePropertyAnimation
                        { start = 0
                        , end = 100
                        , easingFunction = \_ -> 1.0
                        , elapsedMs = 100
                        , delayMs = 0
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 100
            , test "constant zero easing always returns start" <|
                \_ ->
                    makePropertyAnimation
                        { start = 0
                        , end = 100
                        , easingFunction = \_ -> 0.0
                        , elapsedMs = 800
                        , delayMs = 0
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 0
            ]
        , describe "with delay"
            [ test "within delay period returns start" <|
                \_ ->
                    makePropertyAnimation
                        { start = 10
                        , end = 90
                        , easingFunction = identity
                        , elapsedMs = 200
                        , delayMs = 500
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 10
            , test "past delay halfway through returns midpoint" <|
                \_ ->
                    makePropertyAnimation
                        { start = 10
                        , end = 90
                        , easingFunction = identity
                        , elapsedMs = 1000
                        , delayMs = 500
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 50
            ]
        , describe "isComplete flag"
            [ test "isComplete returns end value regardless of elapsed" <|
                \_ ->
                    { start = 0
                    , end = 100
                    , easingFunction = identity
                    , elapsedMs = 0
                    , delayMs = 0
                    , totalDurationMs = 1000
                    , isComplete = True
                    }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 100
            ]
        , describe "non-zero start and end"
            [ test "interpolates between non-zero range" <|
                \_ ->
                    makePropertyAnimation
                        { start = 200
                        , end = 400
                        , easingFunction = identity
                        , elapsedMs = 500
                        , delayMs = 0
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 300
            , test "interpolates negative range" <|
                \_ ->
                    makePropertyAnimation
                        { start = -50
                        , end = 50
                        , easingFunction = identity
                        , elapsedMs = 500
                        , delayMs = 0
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 0
            , test "interpolates reversed range (start > end)" <|
                \_ ->
                    makePropertyAnimation
                        { start = 100
                        , end = 0
                        , easingFunction = identity
                        , elapsedMs = 500
                        , delayMs = 0
                        , totalDurationMs = 1000
                        }
                        |> Interpolation.interpolateEasedProgress Interpolation.interpolateFloat
                        |> Expect.within (Expect.Absolute 0.001) 50
            ]
        ]



-- ============================================================
-- HELPERS
-- ============================================================


makePropertyAnimation :
    { start : a
    , end : a
    , easingFunction : Float -> Float
    , elapsedMs : Float
    , delayMs : Float
    , totalDurationMs : Float
    }
    -> PropertyAnimation a
makePropertyAnimation config =
    { start = config.start
    , end = config.end
    , easingFunction = config.easingFunction
    , elapsedMs = config.elapsedMs
    , delayMs = config.delayMs
    , totalDurationMs = config.totalDurationMs
    , isComplete = False
    }
