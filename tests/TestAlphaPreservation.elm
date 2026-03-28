module TestAlphaPreservation exposing (suite)

import Anim.Internal.Property.Color as Color
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Alpha Preservation in Color Interpolation"
        [ test "RGBA to RGB should preserve alpha from start" <|
            \_ ->
                let
                    start =
                        Color.fromRGBA { r = 255, g = 0, b = 0, a = 0.5 }

                    end =
                        Color.fromRGB { r = 0, g = 0, b = 255 }

                    result =
                        Color.interpolate start end 0.5
                in
                case result of
                    Color.Rgba rgba ->
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
                        Color.fromRGBA { r = 255, g = 0, b = 0, a = 0.3 }

                    end =
                        Color.fromHex "#0000FF" |> Maybe.withDefault Color.blue

                    result =
                        Color.interpolate start end 0.5
                in
                case result of
                    Color.Rgba rgba ->
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
                        Color.fromRGBA { r = 255, g = 0, b = 0, a = 0.5 }

                    end =
                        Color.fromRGBA { r = 0, g = 0, b = 255, a = 1.0 }

                    result =
                        Color.interpolate start end 0.5
                in
                case result of
                    Color.Rgba rgba ->
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
                        Color.fromHSLA { h = 0, s = 100, l = 50, a = 0.7 }

                    end =
                        Color.fromHSL { h = 240, s = 100, l = 50 }

                    result =
                        Color.interpolate start end 0.5
                in
                case result of
                    Color.Hsla hsla ->
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
                        Color.fromRGB { r = 255, g = 0, b = 0 }

                    end =
                        Color.fromRGB { r = 0, g = 0, b = 255 }

                    result =
                        Color.interpolate start end 0.5
                in
                case result of
                    Color.Rgb rgb ->
                        Expect.all
                            [ \_ -> rgb.r |> Expect.equal 128
                            , \_ -> rgb.g |> Expect.equal 0
                            , \_ -> rgb.b |> Expect.equal 128
                            ]
                            ()

                    _ ->
                        Expect.fail "Expected RGB result"
        ]
