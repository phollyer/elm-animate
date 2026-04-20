module Internal.Timing.TestTimeSpec exposing (suite)

import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..), duration, speed, toCssString)
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Internal.Timing.TimeSpec"
        [ durationTests
        , speedTests
        , toCssStringTests
        ]



-- DURATION


durationTests : Test
durationTests =
    describe "duration"
        [ test "Duration returns milliseconds regardless of distance" <|
            \_ ->
                duration 500 (Duration 300)
                    |> Expect.equal 300
        , test "Speed computes duration from distance" <|
            \_ ->
                -- 100 units at 50 units/sec = 2000ms
                duration 100 (Speed 50)
                    |> Expect.within (Expect.Absolute 0.001) 2000
        , test "Speed zero returns zero duration" <|
            \_ ->
                duration 100 (Speed 0)
                    |> Expect.equal 0
        , test "Speed with zero distance returns zero" <|
            \_ ->
                duration 0 (Speed 100)
                    |> Expect.equal 0
        , test "Duration ignores distance entirely" <|
            \_ ->
                Expect.equal
                    (duration 0 (Duration 500))
                    (duration 9999 (Duration 500))
        ]



-- SPEED


speedTests : Test
speedTests =
    describe "speed"
        [ test "Speed returns stored value regardless of args" <|
            \_ ->
                speed 100 500 (Speed 42)
                    |> Expect.equal 42
        , test "Duration computes speed from distance and ms" <|
            \_ ->
                -- 100 units in 2000ms = 50 units/sec
                speed 100 2000 (Duration 2000)
                    |> Expect.within (Expect.Absolute 0.001) 50
        , test "Duration zero or negative uses fallback calculation" <|
            \_ ->
                speed 10 500 (Duration 0)
                    |> Expect.notEqual 0
        ]



-- TO CSS STRING


toCssStringTests : Test
toCssStringTests =
    describe "toCssString"
        [ test "Nothing produces 0ms" <|
            \_ ->
                toCssString 100 Nothing
                    |> Expect.equal "0ms"
        , test "Duration produces ms string" <|
            \_ ->
                toCssString 100 (Just (Duration 350))
                    |> Expect.equal "350ms"
        , test "Speed computes and rounds to ms" <|
            \_ ->
                -- 100 units at 200 units/sec = 500ms
                toCssString 100 (Just (Speed 200))
                    |> Expect.equal "500ms"
        , test "Speed zero produces 0ms" <|
            \_ ->
                toCssString 100 (Just (Speed 0))
                    |> Expect.equal "0ms"
        ]
