module Internal.Property.TestPerspectiveOrigin exposing (suite)

import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin exposing (Unit(..))
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Internal.Property.PerspectiveOrigin"
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
        [ test "default is 50% 50%" <|
            \_ ->
                PerspectiveOrigin.default
                    |> PerspectiveOrigin.toTuple
                    |> Expect.equal ( 50, 50 )
        , test "default unit is percent" <|
            \_ ->
                PerspectiveOrigin.default
                    |> PerspectiveOrigin.getUnit
                    |> Expect.equal PercentUnit
        , test "fromRecord with PercentUnit stores x and y" <|
            \_ ->
                PerspectiveOrigin.fromRecord PercentUnit { x = 25, y = 75 }
                    |> PerspectiveOrigin.toTuple
                    |> Expect.equal ( 25, 75 )
        , test "fromRecord with PxUnit stores x and y" <|
            \_ ->
                PerspectiveOrigin.fromRecord PxUnit { x = 200, y = 150 }
                    |> PerspectiveOrigin.toTuple
                    |> Expect.equal ( 200, 150 )
        ]



-- ACCESSORS


accessors : Test
accessors =
    describe "Accessors"
        [ test "getX returns x" <|
            \_ ->
                PerspectiveOrigin.fromRecord PercentUnit { x = 25, y = 75 }
                    |> PerspectiveOrigin.getX
                    |> Expect.equal 25
        , test "getY returns y" <|
            \_ ->
                PerspectiveOrigin.fromRecord PercentUnit { x = 25, y = 75 }
                    |> PerspectiveOrigin.getY
                    |> Expect.equal 75
        , test "getUnit returns PercentUnit" <|
            \_ ->
                PerspectiveOrigin.fromRecord PercentUnit { x = 25, y = 75 }
                    |> PerspectiveOrigin.getUnit
                    |> Expect.equal PercentUnit
        , test "getUnit returns PxUnit" <|
            \_ ->
                PerspectiveOrigin.fromRecord PxUnit { x = 200, y = 150 }
                    |> PerspectiveOrigin.getUnit
                    |> Expect.equal PxUnit
        ]



-- CONVERSIONS


conversions : Test
conversions =
    describe "Conversions"
        [ test "toRecord returns x and y" <|
            \_ ->
                PerspectiveOrigin.fromRecord PercentUnit { x = 25, y = 75 }
                    |> PerspectiveOrigin.toRecord
                    |> Expect.equal { x = 25, y = 75 }
        , test "toTuple returns (x, y)" <|
            \_ ->
                PerspectiveOrigin.fromRecord PxUnit { x = 200, y = 150 }
                    |> PerspectiveOrigin.toTuple
                    |> Expect.equal ( 200, 150 )
        ]



-- DISTANCE


distanceMeasure : Test
distanceMeasure =
    describe "Distance (Euclidean)"
        [ test "same origin has zero distance" <|
            \_ ->
                PerspectiveOrigin.distance
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 50, y = 50 })
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 50, y = 50 })
                    |> Expect.equal 0
        , test "horizontal distance only" <|
            \_ ->
                PerspectiveOrigin.distance
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 0, y = 0 })
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 3, y = 0 })
                    |> Expect.within (Expect.Absolute 0.001) 3
        , test "vertical distance only" <|
            \_ ->
                PerspectiveOrigin.distance
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 0, y = 0 })
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 0, y = 4 })
                    |> Expect.within (Expect.Absolute 0.001) 4
        , test "diagonal distance uses Euclidean formula" <|
            \_ ->
                PerspectiveOrigin.distance
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 0, y = 0 })
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 3, y = 4 })
                    |> Expect.within (Expect.Absolute 0.001) 5
        ]



-- INTERPOLATION


interpolation : Test
interpolation =
    describe "Interpolation"
        [ test "t=0 returns start" <|
            \_ ->
                PerspectiveOrigin.interpolate
                    0
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 0, y = 0 })
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 100, y = 100 })
                    |> PerspectiveOrigin.toTuple
                    |> Expect.equal ( 0, 0 )
        , test "t=1 returns end" <|
            \_ ->
                PerspectiveOrigin.interpolate
                    1
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 0, y = 0 })
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 100, y = 100 })
                    |> PerspectiveOrigin.toTuple
                    |> Expect.equal ( 100, 100 )
        , test "t=0.5 returns midpoint" <|
            \_ ->
                PerspectiveOrigin.interpolate
                    0.5
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 0, y = 0 })
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 100, y = 60 })
                    |> PerspectiveOrigin.toTuple
                    |> Expect.equal ( 50, 30 )
        , test "interpolation preserves end unit (percent)" <|
            \_ ->
                PerspectiveOrigin.interpolate
                    0.5
                    (PerspectiveOrigin.fromRecord PxUnit { x = 0, y = 0 })
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 100, y = 100 })
                    |> PerspectiveOrigin.getUnit
                    |> Expect.equal PercentUnit
        , test "interpolation preserves end unit (px)" <|
            \_ ->
                PerspectiveOrigin.interpolate
                    0.5
                    (PerspectiveOrigin.fromRecord PercentUnit { x = 0, y = 0 })
                    (PerspectiveOrigin.fromRecord PxUnit { x = 100, y = 100 })
                    |> PerspectiveOrigin.getUnit
                    |> Expect.equal PxUnit
        ]



-- CSS OUTPUT


cssOutput : Test
cssOutput =
    describe "CSS Output"
        [ test "percent values produce '25% 75%'" <|
            \_ ->
                PerspectiveOrigin.fromRecord PercentUnit { x = 25, y = 75 }
                    |> PerspectiveOrigin.toCssString
                    |> Expect.equal "25% 75%"
        , test "px values produce '200px 150px'" <|
            \_ ->
                PerspectiveOrigin.fromRecord PxUnit { x = 200, y = 150 }
                    |> PerspectiveOrigin.toCssString
                    |> Expect.equal "200px 150px"
        , test "default produces '50% 50%'" <|
            \_ ->
                PerspectiveOrigin.default
                    |> PerspectiveOrigin.toCssString
                    |> Expect.equal "50% 50%"
        , test "integer percent values omit decimal" <|
            \_ ->
                PerspectiveOrigin.fromRecord PercentUnit { x = 100, y = 0 }
                    |> PerspectiveOrigin.toCssString
                    |> Expect.equal "100% 0%"
        ]
