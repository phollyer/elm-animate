module Scroll.Internal.TestScrollBuilder exposing (suite)

import Expect
import Scroll.Internal.ScrollBuilder as ScrollBuilder
import Shared.TimeSpec exposing (TimeSpec(..))
import Test exposing (..)


suite : Test
suite =
    describe "Scroll.Internal.ScrollBuilder"
        [ initTests
        , builderChainTests
        , timingConfigTests
        , scrollTargetsTests
        ]


initTests : Test
initTests =
    describe "init"
        [ test "creates empty ScrollBuilder" <|
            \_ ->
                ScrollBuilder.init
                    |> ScrollBuilder.getScrollTargets
                    |> List.isEmpty
                    |> Expect.equal True
        , test "initial delay is 0" <|
            \_ ->
                ScrollBuilder.init
                    |> ScrollBuilder.getDelayWithDefault
                    |> Expect.equal 0
        ]


builderChainTests : Test
builderChainTests =
    describe "builder creation and build"
        [ test "build adds scroll target to builder" <|
            \_ ->
                let
                    builder =
                        ScrollBuilder.init
                            |> ScrollBuilder.for "container"

                    result =
                        builder |> ScrollBuilder.build
                in
                ScrollBuilder.getScrollTargets result
                    |> List.isEmpty
                    |> Expect.equal False
        ]


timingConfigTests : Test
timingConfigTests =
    describe "timing configuration"
        [ test "duration sets timing to Duration" <|
            \_ ->
                let
                    builder =
                        ScrollBuilder.init
                            |> ScrollBuilder.for "container"
                            |> ScrollBuilder.duration 500

                    result =
                        builder |> ScrollBuilder.build
                in
                ScrollBuilder.getScrollTargets result
                    |> List.isEmpty
                    |> Expect.equal False
        , test "speed sets timing to Speed" <|
            \_ ->
                let
                    builder =
                        ScrollBuilder.init
                            |> ScrollBuilder.for "container"
                            |> ScrollBuilder.speed 100

                    result =
                        builder |> ScrollBuilder.build
                in
                ScrollBuilder.getScrollTargets result
                    |> List.isEmpty
                    |> Expect.equal False
        , test "delay sets delay value" <|
            \_ ->
                let
                    builder =
                        ScrollBuilder.init
                            |> ScrollBuilder.for "container"
                            |> ScrollBuilder.delay 200

                    result =
                        builder |> ScrollBuilder.build
                in
                ScrollBuilder.getDelay result
                    |> Expect.equal (Just 200)
        , test "getDelayWithDefault returns non-zero after delay set" <|
            \_ ->
                let
                    result =
                        ScrollBuilder.init
                            |> ScrollBuilder.for "container"
                            |> ScrollBuilder.delay 100
                            |> ScrollBuilder.build
                in
                ScrollBuilder.getDelayWithDefault result
                    |> Expect.equal 100
        ]


scrollTargetsTests : Test
scrollTargetsTests =
    describe "scroll target management"
        [ test "getScrollTargets returns all added targets" <|
            \_ ->
                let
                    builder =
                        ScrollBuilder.init
                            |> ScrollBuilder.for "container"
                            |> ScrollBuilder.toXY 100 200

                    result =
                        builder |> ScrollBuilder.build
                in
                ScrollBuilder.getScrollTargets result
                    |> List.length
                    |> Expect.equal 1
        , test "multiple for..build chains add multiple targets" <|
            \_ ->
                let
                    sb1 =
                        ScrollBuilder.init
                            |> ScrollBuilder.for "container1"
                            |> ScrollBuilder.build

                    sb2 =
                        sb1
                            |> ScrollBuilder.for "container2"
                            |> ScrollBuilder.build
                in
                ScrollBuilder.getScrollTargets sb2
                    |> List.length
                    |> Expect.equal 2
        ]
