module Internal.Property.TestRotate exposing (suite)

import Anim.Internal.Property.Rotate as Rotate
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Internal.Property.Rotate"
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
        [ test "default is zero rotation" <|
            \_ ->
                Rotate.default
                    |> Rotate.toTriple
                    |> Expect.equal ( 0, 0, 0 )
        , test "fromRecord sets individual axes" <|
            \_ ->
                Rotate.fromRecord { x = 10, y = 20, z = 30 }
                    |> Rotate.toTriple
                    |> Expect.equal ( 10, 20, 30 )
        , test "fromTriple sets all axes" <|
            \_ ->
                Rotate.fromTriple ( 90, 180, 270 )
                    |> Rotate.toTriple
                    |> Expect.equal ( 90, 180, 270 )
        ]



-- ACCESSORS


accessors : Test
accessors =
    describe "Accessors"
        [ test "rotateX returns x component" <|
            \_ ->
                Rotate.fromRecord { x = 45, y = 0, z = 0 }
                    |> Rotate.getX
                    |> Expect.equal 45
        , test "rotateY returns y component" <|
            \_ ->
                Rotate.fromRecord { x = 0, y = 90, z = 0 }
                    |> Rotate.getY
                    |> Expect.equal 90
        , test "rotateZ returns z component" <|
            \_ ->
                Rotate.fromRecord { x = 0, y = 0, z = 180 }
                    |> Rotate.getZ
                    |> Expect.equal 180
        ]



-- CONVERSIONS


conversions : Test
conversions =
    describe "Conversions"
        [ test "toRecord preserves all axes" <|
            \_ ->
                Rotate.fromTriple ( 1, 2, 3 )
                    |> Rotate.toRecord
                    |> Expect.equal { x = 1, y = 2, z = 3 }
        ]



-- DISTANCE


distanceMeasure : Test
distanceMeasure =
    describe "Distance (Chebyshev)"
        [ test "same rotation has zero distance" <|
            \_ ->
                Rotate.distance
                    (Rotate.fromTriple ( 45, 45, 45 ))
                    (Rotate.fromTriple ( 45, 45, 45 ))
                    |> Expect.equal 0
        , test "uses max axis difference" <|
            \_ ->
                Rotate.distance
                    (Rotate.fromTriple ( 0, 0, 0 ))
                    (Rotate.fromTriple ( 10, 90, 45 ))
                    |> Expect.equal 90
        , test "is symmetric" <|
            \_ ->
                let
                    a =
                        Rotate.fromTriple ( 0, 0, 0 )

                    b =
                        Rotate.fromTriple ( 90, 180, 270 )
                in
                Expect.equal
                    (Rotate.distance a b)
                    (Rotate.distance b a)
        ]



-- INTERPOLATION


interpolation : Test
interpolation =
    describe "Interpolation"
        [ test "t=0 returns start" <|
            \_ ->
                Rotate.interpolate 0
                    (Rotate.fromTriple ( 0, 0, 0 ))
                    (Rotate.fromTriple ( 90, 180, 360 ))
                    |> Rotate.toTriple
                    |> Expect.equal ( 0, 0, 0 )
        , test "t=1 returns end" <|
            \_ ->
                Rotate.interpolate 1
                    (Rotate.fromTriple ( 0, 0, 0 ))
                    (Rotate.fromTriple ( 90, 180, 360 ))
                    |> Rotate.toTriple
                    |> Expect.equal ( 90, 180, 360 )
        , test "t=0.5 returns midpoint" <|
            \_ ->
                Rotate.interpolate 0.5
                    (Rotate.fromTriple ( 0, 0, 0 ))
                    (Rotate.fromTriple ( 90, 180, 360 ))
                    |> Rotate.toTriple
                    |> Expect.equal ( 45, 90, 180 )
        ]



-- CSS OUTPUT


cssOutput : Test
cssOutput =
    describe "CSS Output"
        [ test "zero rotation produces rotateZ(0deg)" <|
            \_ ->
                Rotate.default
                    |> Rotate.toCssString
                    |> Expect.equal "rotateZ(0deg)"
        , test "single z-axis rotation" <|
            \_ ->
                Rotate.fromRecord { x = 0, y = 0, z = 45 }
                    |> Rotate.toCssString
                    |> Expect.equal "rotateZ(45deg)"
        , test "multi-axis rotation includes all non-zero axes" <|
            \_ ->
                let
                    css =
                        Rotate.fromRecord { x = 45, y = 90, z = 0 }
                            |> Rotate.toCssString
                in
                Expect.all
                    [ \c -> String.contains "rotateX(45deg)" c |> Expect.equal True
                    , \c -> String.contains "rotateY(90deg)" c |> Expect.equal True
                    ]
                    css
        ]
