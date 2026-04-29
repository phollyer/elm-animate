module Anim.Internal.Property.TestScale exposing (suite)

import Anim.Internal.Property.Scale as Scale
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Internal.Property.Scale"
        [ construction
        , accessors
        , conversions
        , distanceMeasure
        , interpolation
        , cssOutput
        ]



-- CONSTRUCTION


construction : Test
construction =
    describe "Construction"
        [ test "default is identity scale (1,1,1)" <|
            \_ ->
                Scale.default
                    |> Scale.toTriple
                    |> Expect.equal ( 1, 1, 1 )
        , test "fromTriple sets all axes" <|
            \_ ->
                Scale.fromTriple ( 0.5, 1.5, 2 )
                    |> Scale.toTriple
                    |> Expect.equal ( 0.5, 1.5, 2 )
        , test "fromRecord sets all axes" <|
            \_ ->
                Scale.fromRecord { x = 0.5, y = 1, z = 2 }
                    |> Scale.toTriple
                    |> Expect.equal ( 0.5, 1, 2 )
        ]



-- ACCESSORS


accessors : Test
accessors =
    describe "Accessors"
        [ test "getX returns x" <|
            \_ ->
                Scale.fromTriple ( 2, 1, 1 )
                    |> Scale.getX
                    |> Expect.equal 2
        , test "getY returns y" <|
            \_ ->
                Scale.fromTriple ( 1, 3, 1 )
                    |> Scale.getY
                    |> Expect.equal 3
        , test "getZ returns z" <|
            \_ ->
                Scale.fromTriple ( 1, 1, 4 )
                    |> Scale.getZ
                    |> Expect.equal 4
        ]



-- CONVERSIONS


conversions : Test
conversions =
    describe "Conversions"
        [ test "toRecord preserves all axes" <|
            \_ ->
                Scale.fromTriple ( 0.5, 1, 2 )
                    |> Scale.toRecord
                    |> Expect.equal { x = 0.5, y = 1, z = 2 }
        ]



-- DISTANCE


distanceMeasure : Test
distanceMeasure =
    describe "Distance (Chebyshev)"
        [ test "identity to identity is zero" <|
            \_ ->
                Scale.distance Scale.default Scale.default
                    |> Expect.equal 0
        , test "uses max axis difference" <|
            \_ ->
                Scale.distance
                    (Scale.fromTriple ( 1, 1, 1 ))
                    (Scale.fromTriple ( 1, 1, 3 ))
                    |> Expect.equal 2
        , test "is symmetric" <|
            \_ ->
                let
                    a =
                        Scale.fromTriple ( 1, 1, 1 )

                    b =
                        Scale.fromTriple ( 2, 3, 4 )
                in
                Expect.equal
                    (Scale.distance a b)
                    (Scale.distance b a)
        ]



-- INTERPOLATION


interpolation : Test
interpolation =
    describe "Interpolation"
        [ test "t=0 returns start" <|
            \_ ->
                Scale.interpolate 0
                    (Scale.fromTriple ( 1, 1, 1 ))
                    (Scale.fromTriple ( 2, 2, 2 ))
                    |> Scale.toTriple
                    |> Expect.equal ( 1, 1, 1 )
        , test "t=1 returns end" <|
            \_ ->
                Scale.interpolate 1
                    (Scale.fromTriple ( 1, 1, 1 ))
                    (Scale.fromTriple ( 2, 2, 2 ))
                    |> Scale.toTriple
                    |> Expect.equal ( 2, 2, 2 )
        , test "t=0.5 returns midpoint" <|
            \_ ->
                Scale.interpolate 0.5
                    (Scale.fromTriple ( 1, 1, 1 ))
                    (Scale.fromTriple ( 3, 3, 3 ))
                    |> Scale.toTriple
                    |> Expect.equal ( 2, 2, 2 )
        ]



-- CSS OUTPUT


cssOutput : Test
cssOutput =
    describe "CSS Output"
        [ test "identity scale produces scale3d(1,1,1)" <|
            \_ ->
                Scale.default
                    |> Scale.toCssString
                    |> Expect.equal "scale3d(1,1,1)"
        , test "non-identity single axis" <|
            \_ ->
                Scale.fromTriple ( 2, 1, 1 )
                    |> Scale.toCssString
                    |> Expect.equal "scaleX(2)"
        , test "multiple non-identity axes" <|
            \_ ->
                Scale.fromTriple ( 2, 3, 1 )
                    |> Scale.toCssString
                    |> String.contains "scaleX(2)"
                    |> Expect.equal True
        ]
