module Anim.Internal.Engine.TestPlayState exposing (suite)

import Anim.Internal.Engine.Shared.PlayState as PlayState exposing (PlayState(..))
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Anim.Internal.Engine.PlayState"
        [ statePredicateTests
        , cssStringTests
        ]


statePredicateTests : Test
statePredicateTests =
    describe "state predicates"
        [ describe "isActive"
            [ test "Running is active" <|
                \_ ->
                    PlayState.isActive Running
                        |> Expect.equal True
            , test "Paused is active" <|
                \_ ->
                    PlayState.isActive Paused
                        |> Expect.equal True
            , test "NotStarted is not active" <|
                \_ ->
                    PlayState.isActive NotStarted
                        |> Expect.equal False
            , test "Reset is not active" <|
                \_ ->
                    PlayState.isActive Reset
                        |> Expect.equal False
            , test "Complete is not active" <|
                \_ ->
                    PlayState.isActive Complete
                        |> Expect.equal False
            , test "Cancelled is not active" <|
                \_ ->
                    PlayState.isActive Cancelled
                        |> Expect.equal False
            ]
        , describe "isRunning"
            [ test "Running is running" <|
                \_ ->
                    PlayState.isRunning Running
                        |> Expect.equal True
            , test "Paused is not running" <|
                \_ ->
                    PlayState.isRunning Paused
                        |> Expect.equal False
            , test "NotStarted is not running" <|
                \_ ->
                    PlayState.isRunning NotStarted
                        |> Expect.equal False
            , test "Complete is not running" <|
                \_ ->
                    PlayState.isRunning Complete
                        |> Expect.equal False
            ]
        , describe "isPaused"
            [ test "Paused is paused" <|
                \_ ->
                    PlayState.isPaused Paused
                        |> Expect.equal True
            , test "Running is not paused" <|
                \_ ->
                    PlayState.isPaused Running
                        |> Expect.equal False
            , test "Complete is not paused" <|
                \_ ->
                    PlayState.isPaused Complete
                        |> Expect.equal False
            ]
        , describe "isComplete"
            [ test "Complete is complete" <|
                \_ ->
                    PlayState.isComplete Complete
                        |> Expect.equal True
            , test "Running is not complete" <|
                \_ ->
                    PlayState.isComplete Running
                        |> Expect.equal False
            , test "NotStarted is not complete" <|
                \_ ->
                    PlayState.isComplete NotStarted
                        |> Expect.equal False
            ]
        , describe "isCancelled"
            [ test "Cancelled is cancelled" <|
                \_ ->
                    PlayState.isCancelled Cancelled
                        |> Expect.equal True
            , test "Complete is not cancelled" <|
                \_ ->
                    PlayState.isCancelled Complete
                        |> Expect.equal False
            , test "Running is not cancelled" <|
                \_ ->
                    PlayState.isCancelled Running
                        |> Expect.equal False
            ]
        ]


cssStringTests : Test
cssStringTests =
    describe "toCssString"
        [ test "Running produces 'running'" <|
            \_ ->
                PlayState.toCssString Running
                    |> Expect.equal "running"
        , test "Paused produces 'paused'" <|
            \_ ->
                PlayState.toCssString Paused
                    |> Expect.equal "paused"
        , test "NotStarted produces empty string" <|
            \_ ->
                PlayState.toCssString NotStarted
                    |> Expect.equal ""
        , test "Reset produces empty string" <|
            \_ ->
                PlayState.toCssString Reset
                    |> Expect.equal ""
        , test "Complete produces empty string" <|
            \_ ->
                PlayState.toCssString Complete
                    |> Expect.equal ""
        , test "Cancelled produces empty string" <|
            \_ ->
                PlayState.toCssString Cancelled
                    |> Expect.equal ""
        ]
