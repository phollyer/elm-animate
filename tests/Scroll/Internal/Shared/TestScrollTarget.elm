module Scroll.Internal.Shared.TestScrollTarget exposing (suite)

import Expect
import Scroll.Internal.Shared.ScrollTarget as ScrollTarget exposing (Axis(..), ScrollTargetType(..))
import Test exposing (..)


suite : Test
suite =
    describe "Scroll.Internal.Shared.ScrollTarget"
        [ initTests
        , axisConfigTests
        , coordinateTests
        , elementTests
        , offsetTests
        ]


initTests : Test
initTests =
    describe "init with `for`"
        [ test "creates scroll target for container" <|
            \_ ->
                ScrollTarget.for "container-id"
                    |> ScrollTarget.getContainerId
                    |> Expect.equal "container-id"
        , test "initial target is coordinates type" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.getTargetType
                    |> Expect.equal (Coordinates 0 0)
        , test "initial axis is Both" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.getAxis
                    |> Expect.equal Both
        , test "initial offset is 0,0" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.getOffset
                    |> Expect.equal ( 0, 0 )
        ]


axisConfigTests : Test
axisConfigTests =
    describe "axis configuration"
        [ test "toXY sets axis to Both" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.toXY 100 200
                    |> ScrollTarget.getAxis
                    |> Expect.equal Both
        , test "toX sets axis to X" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.toX 100
                    |> ScrollTarget.getAxis
                    |> Expect.equal X
        , test "toY sets axis to Y" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.toY 200
                    |> ScrollTarget.getAxis
                    |> Expect.equal Y
        , test "byXY sets axis to Both" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.byXY 50 75
                    |> ScrollTarget.getAxis
                    |> Expect.equal Both
        , test "byX sets axis to X" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.byX 50
                    |> ScrollTarget.getAxis
                    |> Expect.equal X
        , test "byY sets axis to Y" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.byY 75
                    |> ScrollTarget.getAxis
                    |> Expect.equal Y
        ]


coordinateTests : Test
coordinateTests =
    describe "coordinate targets"
        [ test "toXY sets absolute coordinates" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.toXY 100 200
                    |> ScrollTarget.getTargetX
                    |> Expect.equal 100
        , test "toXY sets both X and Y" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.toXY 100 200
                    |> ScrollTarget.getTargetY
                    |> Expect.equal 200
        , test "toX sets X coordinate" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.toX 150
                    |> ScrollTarget.getTargetX
                    |> Expect.equal 150
        , test "toY sets Y coordinate" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.toY 250
                    |> ScrollTarget.getTargetY
                    |> Expect.equal 250
        , test "byXY sets relative delta coordinates" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.byXY 50 75
                    |> ScrollTarget.getTargetX
                    |> Expect.equal 50
        , test "byX sets relative X delta" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.byX 50
                    |> ScrollTarget.getTargetX
                    |> Expect.equal 50
        , test "byY sets relative Y delta" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.byY 75
                    |> ScrollTarget.getTargetY
                    |> Expect.equal 75
        ]


elementTests : Test
elementTests =
    describe "element targets"
        [ test "toElement sets target element" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.toElement "element-id"
                    |> ScrollTarget.getTargetElement
                    |> Expect.equal (Just "element-id")
        , test "getTargetType returns Element after toElement" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.toElement "my-element"
                    |> ScrollTarget.getTargetType
                    |> Expect.equal (Element "my-element")
        , test "toPercentage sets percentage target" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.toPercentage 50 75
                    |> ScrollTarget.getTargetType
                    |> Expect.equal (Percentage 50 75)
        , test "toPercentageX sets X percentage" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.toPercentageX 25
                    |> ScrollTarget.getTargetType
                    |> Expect.equal (Percentage 25 0)
        , test "toPercentageY sets Y percentage" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.toPercentageY 75
                    |> ScrollTarget.getTargetType
                    |> Expect.equal (Percentage 0 75)
        ]


offsetTests : Test
offsetTests =
    describe "offset retrieval"
        [ test "getOffset returns initial offset" <|
            \_ ->
                ScrollTarget.for "container"
                    |> ScrollTarget.getOffset
                    |> Expect.equal ( 0, 0 )
        ]
