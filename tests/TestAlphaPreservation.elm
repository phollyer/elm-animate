module TestAlphaPreservation exposing (suite)

import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Alpha Preservation in Color Interpolation"
        [ test "RGBA to RGB should preserve alpha from start" <|
            \_ ->
                let
                    start =
                        BackgroundColor.rgba255 255 0 0 0.5

                    end =
                        BackgroundColor.rgb255 0 0 255

                    result =
                        BackgroundColor.interpolate start end 0.5
                in
                case result of
                    BackgroundColor.Rgba rgba ->
                        Expect.all
                            [ \_ -> rgba.r |> Expect.equal 128
                            , \_ -> rgba.g |> Expect.equal 0
                            , \_ -> rgba.b |> Expect.equal 128
                            , \_ -> rgba.a |> Expect.within (Expect.Absolute 0.001) 0.5
                            ]
                            ()

                    _ ->
                        Expect.fail "Expected RGBA result"
        , test "RGBA to Hex should preserve alpha from start" <|
            \_ ->
                let
                    start =
                        BackgroundColor.rgba255 255 0 0 0.3

                    end =
                        BackgroundColor.hex "#0000FF"

                    result =
                        BackgroundColor.interpolate start end 0.5
                in
                case result of
                    BackgroundColor.Rgba rgba ->
                        Expect.all
                            [ \_ -> rgba.r |> Expect.equal 128
                            , \_ -> rgba.g |> Expect.equal 0
                            , \_ -> rgba.b |> Expect.equal 128
                            , \_ -> rgba.a |> Expect.within (Expect.Absolute 0.001) 0.3
                            ]
                            ()

                    _ ->
                        Expect.fail "Expected RGBA result"
        , test "RGBA to RGBA should interpolate alpha" <|
            \_ ->
                let
                    start =
                        BackgroundColor.rgba255 255 0 0 0.5

                    end =
                        BackgroundColor.rgba255 0 0 255 1.0

                    result =
                        BackgroundColor.interpolate start end 0.5
                in
                case result of
                    BackgroundColor.Rgba rgba ->
                        Expect.all
                            [ \_ -> rgba.r |> Expect.equal 128
                            , \_ -> rgba.g |> Expect.equal 0
                            , \_ -> rgba.b |> Expect.equal 128
                            , \_ -> rgba.a |> Expect.within (Expect.Absolute 0.001) 0.75
                            ]
                            ()

                    _ ->
                        Expect.fail "Expected RGBA result"
        , test "HSLA to HSL should preserve alpha from start" <|
            \_ ->
                let
                    start =
                        BackgroundColor.hslaPercent 0 100 50 0.7

                    end =
                        BackgroundColor.hslPercent 240 100 50

                    result =
                        BackgroundColor.interpolate start end 0.5
                in
                case result of
                    BackgroundColor.Hsla hsla ->
                        Expect.all
                            [ \_ -> hsla.h |> Expect.within (Expect.Absolute 1) 120
                            , \_ -> hsla.s |> Expect.within (Expect.Absolute 0.1) 100
                            , \_ -> hsla.l |> Expect.within (Expect.Absolute 0.1) 50
                            , \_ -> hsla.a |> Expect.within (Expect.Absolute 0.001) 0.7
                            ]
                            ()

                    _ ->
                        Expect.fail "Expected HSLA result"
        , test "RGB to RGB with no alpha should keep alpha at 1.0" <|
            \_ ->
                let
                    start =
                        BackgroundColor.rgb255 255 0 0

                    end =
                        BackgroundColor.rgb255 0 0 255

                    result =
                        BackgroundColor.interpolate start end 0.5
                in
                case result of
                    BackgroundColor.Rgb rgb ->
                        Expect.all
                            [ \_ -> rgb.r |> Expect.equal 128
                            , \_ -> rgb.g |> Expect.equal 0
                            , \_ -> rgb.b |> Expect.equal 128
                            ]
                            ()

                    _ ->
                        Expect.fail "Expected RGB result"
        ]
