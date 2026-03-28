module Internal.Property.TestOpacity exposing (suite)

import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Internal.Property.Opacity"
        [ construction
        , conversion
        , queries
        , distanceMeasure
        , interpolation
        ]



-- CONSTRUCTION


construction : Test
construction =
    describe "Construction"
        [ test "default is fully opaque" <|
            \_ ->
                Opacity.default
                    |> Opacity.toFloat
                    |> Expect.equal 1
        , test "fromFloat stores value" <|
            \_ ->
                Opacity.fromFloat 0.5
                    |> Opacity.toFloat
                    |> Expect.within (Expect.Absolute 0.001) 0.5
        , test "fromFloat zero" <|
            \_ ->
                Opacity.fromFloat 0
                    |> Opacity.toFloat
                    |> Expect.equal 0
        ]



-- CONVERSION


conversion : Test
conversion =
    describe "Conversion"
        [ test "toString of 1" <|
            \_ ->
                Opacity.fromFloat 1
                    |> Opacity.toString
                    |> Expect.equal "1"
        , test "toString of 0.5" <|
            \_ ->
                Opacity.fromFloat 0.5
                    |> Opacity.toString
                    |> Expect.equal "0.5"
        , test "toString of 0" <|
            \_ ->
                Opacity.fromFloat 0
                    |> Opacity.toString
                    |> Expect.equal "0"
        , test "toFloat round-trips with fromFloat" <|
            \_ ->
                Opacity.fromFloat 0.73
                    |> Opacity.toFloat
                    |> Expect.within (Expect.Absolute 0.001) 0.73
        ]



-- QUERIES


queries : Test
queries =
    describe "Queries"
        [ test "isFullyOpaque true at 1.0" <|
            \_ ->
                Opacity.fromFloat 1.0
                    |> Opacity.isFullyOpaque
                    |> Expect.equal True
        , test "isFullyOpaque true above 1.0" <|
            \_ ->
                Opacity.fromFloat 1.5
                    |> Opacity.isFullyOpaque
                    |> Expect.equal True
        , test "isFullyOpaque false below 1.0" <|
            \_ ->
                Opacity.fromFloat 0.99
                    |> Opacity.isFullyOpaque
                    |> Expect.equal False
        , test "isFullyTransparent true at 0" <|
            \_ ->
                Opacity.fromFloat 0
                    |> Opacity.isFullyTransparent
                    |> Expect.equal True
        , test "isFullyTransparent true below 0" <|
            \_ ->
                Opacity.fromFloat -0.1
                    |> Opacity.isFullyTransparent
                    |> Expect.equal True
        , test "isFullyTransparent false above 0" <|
            \_ ->
                Opacity.fromFloat 0.01
                    |> Opacity.isFullyTransparent
                    |> Expect.equal False
        , test "default is fully opaque" <|
            \_ ->
                Opacity.default
                    |> Opacity.isFullyOpaque
                    |> Expect.equal True
        , test "default is not fully transparent" <|
            \_ ->
                Opacity.default
                    |> Opacity.isFullyTransparent
                    |> Expect.equal False
        ]



-- DISTANCE


distanceMeasure : Test
distanceMeasure =
    describe "Distance"
        [ test "same opacity has zero distance" <|
            \_ ->
                Opacity.distance
                    (Opacity.fromFloat 0.5)
                    (Opacity.fromFloat 0.5)
                    |> Expect.within (Expect.Absolute 0.001) 0
        , test "full range distance is 1.0" <|
            \_ ->
                Opacity.distance
                    (Opacity.fromFloat 0)
                    (Opacity.fromFloat 1)
                    |> Expect.within (Expect.Absolute 0.001) 1.0
        , test "distance is symmetric" <|
            \_ ->
                let
                    a =
                        Opacity.fromFloat 0.2

                    b =
                        Opacity.fromFloat 0.8
                in
                Expect.within (Expect.Absolute 0.001)
                    (Opacity.distance a b)
                    (Opacity.distance b a)
        , test "partial distance" <|
            \_ ->
                Opacity.distance
                    (Opacity.fromFloat 0.3)
                    (Opacity.fromFloat 0.7)
                    |> Expect.within (Expect.Absolute 0.001) 0.4
        ]



-- INTERPOLATION


interpolation : Test
interpolation =
    describe "Interpolation"
        [ test "t=0 returns start" <|
            \_ ->
                Opacity.interpolate 0.0
                    (Opacity.fromFloat 0.2)
                    (Opacity.fromFloat 0.8)
                    |> Opacity.toFloat
                    |> Expect.within (Expect.Absolute 0.001) 0.2
        , test "t=1 returns end" <|
            \_ ->
                Opacity.interpolate 1.0
                    (Opacity.fromFloat 0.2)
                    (Opacity.fromFloat 0.8)
                    |> Opacity.toFloat
                    |> Expect.within (Expect.Absolute 0.001) 0.8
        , test "t=0.5 returns midpoint" <|
            \_ ->
                Opacity.interpolate 0.5
                    (Opacity.fromFloat 0.0)
                    (Opacity.fromFloat 1.0)
                    |> Opacity.toFloat
                    |> Expect.within (Expect.Absolute 0.001) 0.5
        , test "interpolate same values returns that value" <|
            \_ ->
                Opacity.interpolate 0.5
                    (Opacity.fromFloat 0.6)
                    (Opacity.fromFloat 0.6)
                    |> Opacity.toFloat
                    |> Expect.within (Expect.Absolute 0.001) 0.6
        , test "interpolate at quarter" <|
            \_ ->
                Opacity.interpolate 0.25
                    (Opacity.fromFloat 0.0)
                    (Opacity.fromFloat 1.0)
                    |> Opacity.toFloat
                    |> Expect.within (Expect.Absolute 0.001) 0.25
        ]
