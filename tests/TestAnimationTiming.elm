module TestAnimationTiming exposing (suite)

import Anim.Properties.Position as Position
import Anim.Sub as Sub
import Expect
import Test exposing (..)


{-| Test animation timing accuracy to identify discrepancies between
getDuration and actual animation frame counts.
-}
suite : Test
suite =
    describe "Animation timing accuracy tests"
        [ test "2992ms duration should have correct frame count" <|
            \_ ->
                let
                    inputDuration =
                        2992

                    animationState =
                        Sub.init
                            |> Sub.builder
                            |> Position.for "test-element"
                            |> Position.toX 100.0
                            |> Position.duration inputDuration
                            |> Position.build
                            |> Sub.animate

                    reportedDuration =
                        Sub.getDuration "test-element" animationState
                            |> Maybe.withDefault 0

                    -- Let's calculate what the actual frame count should be
                    expectedFrames =
                        inputDuration // 16

                    -- 2992 // 16 = 187
                    calculatedDuration =
                        expectedFrames * 16

                    -- 187 * 16 = 2992
                in
                Expect.all
                    [ \_ -> Expect.equal (Just reportedDuration) (Just calculatedDuration)
                    , \_ -> Expect.atLeast 2900 reportedDuration -- Should be close to input
                    , \_ -> Expect.atMost 3100 reportedDuration
                    ]
                    ()
        , test "3000ms duration timing calculation" <|
            \_ ->
                let
                    inputDuration =
                        3000

                    animationState =
                        Sub.init
                            |> Sub.builder
                            |> Position.for "test-element"
                            |> Position.toX 100.0
                            |> Position.duration inputDuration
                            |> Position.build
                            |> Sub.animate

                    reportedDuration =
                        Sub.getDuration "test-element" animationState
                            |> Maybe.withDefault 0

                    -- Manual calculation: round(3000 / 16) = round(187.5) = 188 frames
                    expectedFrames =
                        188

                    expectedReportedDuration =
                        expectedFrames * 16

                    -- 188 * 16 = 3008
                in
                Expect.equal expectedReportedDuration reportedDuration
        , test "Frame calculation rounding behavior - 2992ms case" <|
            \_ ->
                let
                    inputMs =
                        2992

                    expectedFrames =
                        187

                    -- round(2992 / 16) = round(187.0) = 187
                    animationState =
                        Sub.init
                            |> Sub.builder
                            |> Position.for "test"
                            |> Position.toX 100.0
                            |> Position.duration inputMs
                            |> Position.build
                            |> Sub.animate

                    reportedDuration =
                        Sub.getDuration "test" animationState
                            |> Maybe.withDefault 0

                    expectedDuration =
                        expectedFrames * 16

                    -- 187 * 16 = 2992
                in
                Expect.equal expectedDuration reportedDuration
        , test "Animation frame delta consistency" <|
            \_ ->
                -- This test checks if the animation frame subscription timing
                -- matches our 16ms assumption
                let
                    -- Create an animation that should run for exactly 1 second
                    animationState =
                        Sub.init
                            |> Sub.builder
                            |> Position.for "timing-test"
                            |> Position.toX 100.0
                            |> Position.duration 1000
                            |> Position.build
                            |> Sub.animate

                    reportedDuration =
                        Sub.getDuration "timing-test" animationState
                            |> Maybe.withDefault 0

                    -- 1000ms / 16ms = 62.5 -> round(62.5) = 63 frames -> 63 * 16 = 1008ms
                    expectedDuration =
                        63 * 16
                in
                Expect.equal expectedDuration reportedDuration
        ]
