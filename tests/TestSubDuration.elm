module TestSubDuration exposing (suite)

import Anim.Engine.Sub as Sub
import Anim.Properties.Position as Position
import Anim.Timing.Easing as Easing
import Expect
import Test exposing (..)


{-| Test the Sub.getDuration function to ensure it returns the correct duration
for animations created with explicit duration settings.
-}
suite : Test
suite =
    describe "Sub.getDuration function tests"
        [ test "getDuration returns correct duration for position animation with explicit duration" <|
            \_ ->
                let
                    targetX =
                        100.0

                    easing =
                        Easing.Linear

                    animationState =
                        Sub.init
                            |> Sub.builder
                            |> Position.for "page-content"
                            |> Position.toX targetX
                            |> Position.duration 2000
                            |> Position.easing easing
                            |> Position.build
                            |> Sub.animate

                    duration =
                        Sub.getDuration "page-content" animationState
                in
                Expect.equal (Just 2000) duration
        , test "getDuration returns correct duration for position animation with speed setting" <|
            \_ ->
                let
                    targetX =
                        200.0

                    speed =
                        100.0

                    -- speed of 100 pixels per second
                    easing =
                        Easing.EaseInOut

                    animationState =
                        Sub.init
                            |> Sub.builder
                            |> Position.for "speed-element"
                            |> Position.toX targetX
                            |> Position.speed speed
                            |> Position.easing easing
                            |> Position.build
                            |> Sub.animate

                    duration =
                        Sub.getDuration "speed-element" animationState

                    -- With 200px distance and 100px/s speed, duration should be 2000ms
                    expectedDuration =
                        2000
                in
                Expect.equal (Just expectedDuration) duration
        , test "getDuration returns Nothing for non-existent element" <|
            \_ ->
                let
                    animationState =
                        Sub.init
                            |> Sub.builder
                            |> Position.for "page-content"
                            |> Position.toX 100.0
                            |> Position.duration 1500
                            |> Position.build
                            |> Sub.animate

                    duration =
                        Sub.getDuration "non-existent-element" animationState
                in
                Expect.equal Nothing duration
        , test "getDuration returns Nothing for empty animation state" <|
            \_ ->
                let
                    duration =
                        Sub.getDuration "any-element" Sub.init
                in
                Expect.equal Nothing duration
        ]
