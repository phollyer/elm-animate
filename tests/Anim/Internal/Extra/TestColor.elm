module Anim.Internal.Extra.TestColor exposing (suite)

import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Color as ElmColor
import Expect
import Json.Encode as Encode
import Test exposing (..)


suite : Test
suite =
    describe "Internal.Property.Color"
        [ constructors
        , cssStrings
        , hexConversions
        , hslConversions
        , rgbConversions
        , alphaUtilities
        , colorManipulation
        , interpolation
        , distanceMeasure
        , equality
        , luminance
        , stringParsing
        , encoding
        , elmColorIntegration
        ]



-- CONSTRUCTORS


constructors : Test
constructors =
    describe "Constructors"
        [ test "fromRGB creates Rgb" <|
            \_ ->
                Color.fromRGB { r = 100, g = 150, b = 200 }
                    |> expectRgb { r = 100, g = 150, b = 200 }
        , test "fromRGBA creates Rgba" <|
            \_ ->
                Color.fromRGBA { r = 100, g = 150, b = 200, a = 0.5 }
                    |> expectRgba { r = 100, g = 150, b = 200, a = 0.5 }
        , test "fromHSL creates Hsl" <|
            \_ ->
                Color.fromHSL { h = 180, s = 50, l = 60 }
                    |> expectHsl { h = 180, s = 50, l = 60 }
        , test "fromHSLA creates Hsla" <|
            \_ ->
                Color.fromHSLA { h = 180, s = 50, l = 60, a = 0.8 }
                    |> expectHsla { h = 180, s = 50, l = 60, a = 0.8 }
        , test "fromHex with valid 6-digit hex" <|
            \_ ->
                Color.fromHex "#FF8800"
                    |> Expect.notEqual Nothing
        , test "fromHex with valid 3-digit hex" <|
            \_ ->
                Color.fromHex "#F80"
                    |> Expect.notEqual Nothing
        , test "fromHex with valid 8-digit hex (with alpha)" <|
            \_ ->
                Color.fromHex "#FF880080"
                    |> Expect.notEqual Nothing
        , test "fromHex rejects invalid hex" <|
            \_ ->
                Color.fromHex "#GGGGGG"
                    |> Expect.equal Nothing
        , test "fromHex rejects wrong length" <|
            \_ ->
                Color.fromHex "#FFFF"
                    |> Expect.equal Nothing
        , test "fromHex without # prefix" <|
            \_ ->
                Color.fromHex "FF8800"
                    |> Expect.notEqual Nothing
        , test "predefined black" <|
            \_ ->
                Color.black
                    |> Color.toRgb
                    |> Expect.equal { r = 0, g = 0, b = 0 }
        , test "predefined white" <|
            \_ ->
                Color.white
                    |> Color.toRgb
                    |> Expect.equal { r = 255, g = 255, b = 255 }
        , test "predefined red" <|
            \_ ->
                Color.red
                    |> Color.toRgb
                    |> Expect.equal { r = 255, g = 0, b = 0 }
        , test "predefined green" <|
            \_ ->
                Color.green
                    |> Color.toRgb
                    |> Expect.equal { r = 0, g = 255, b = 0 }
        , test "predefined blue" <|
            \_ ->
                Color.blue
                    |> Color.toRgb
                    |> Expect.equal { r = 0, g = 0, b = 255 }
        , test "predefined transparent" <|
            \_ ->
                Color.transparent
                    |> expectRgba { r = 255, g = 255, b = 255, a = 0 }
        ]



-- CSS STRINGS


cssStrings : Test
cssStrings =
    describe "toCssString"
        [ test "Hex passthrough" <|
            \_ ->
                Color.fromHex "#FF0000"
                    |> Maybe.map Color.toCssString
                    |> Expect.equal (Just "#FF0000")
        , test "RGB format" <|
            \_ ->
                Color.fromRGB { r = 255, g = 128, b = 0 }
                    |> Color.toCssString
                    |> Expect.equal "rgb(255, 128, 0)"
        , test "RGBA format" <|
            \_ ->
                Color.fromRGBA { r = 255, g = 128, b = 0, a = 0.5 }
                    |> Color.toCssString
                    |> Expect.equal "rgba(255, 128, 0, 0.5)"
        , test "HSL format" <|
            \_ ->
                Color.fromHSL { h = 180, s = 50, l = 60 }
                    |> Color.toCssString
                    |> Expect.equal "hsl(180, 50%, 60%)"
        , test "HSLA format" <|
            \_ ->
                Color.fromHSLA { h = 180, s = 50, l = 60, a = 0.8 }
                    |> Color.toCssString
                    |> Expect.equal "hsla(180, 50%, 60%, 0.8)"
        ]



-- HEX CONVERSIONS


hexConversions : Test
hexConversions =
    describe "Hex conversions"
        [ test "hexToRgb parses 6 digit hex" <|
            \_ ->
                Color.hexToRgb "#FF8000"
                    |> Expect.equal { r = 255, g = 128, b = 0 }
        , test "hexToRgba parses 8 digit hex with alpha" <|
            \_ ->
                let
                    rgba =
                        Color.hexToRgba "#FF800080"
                in
                Expect.all
                    [ \_ ->
                        rgba.r
                            |> Expect.equal 255
                    , \_ ->
                        rgba.g
                            |> Expect.equal 128
                    , \_ ->
                        rgba.b
                            |> Expect.equal 0
                    , \_ ->
                        rgba.a
                            |> Expect.within (Expect.Absolute 0.01) 0.502
                    ]
                    ()
        , test "hexToRgba defaults alpha to 1.0 for 6 digit hex" <|
            \_ ->
                let
                    rgba =
                        Color.hexToRgba "#FF8000"
                in
                rgba.a
                    |> Expect.within (Expect.Absolute 0.01) 1.0
        , test "toHex from RGB" <|
            \_ ->
                Color.fromRGB { r = 255, g = 0, b = 0 }
                    |> Color.toHex
                    |> Expect.equal "#FF0000"
        , test "toHex from RGBA" <|
            \_ ->
                Color.fromRGBA { r = 255, g = 0, b = 0, a = 0.5 }
                    |> Color.toHex
                    |> Expect.equal "#FF000080"
        , test "toHex from Hex is identity" <|
            \_ ->
                Color.fromHex "#AABBCC"
                    |> Maybe.map Color.toHex
                    |> Expect.equal (Just "#AABBCC")
        , test "hexToHsl returns correct values" <|
            \_ ->
                let
                    hsl =
                        Color.hexToHsl "#FF0000"
                in
                Expect.all
                    [ \_ ->
                        hsl.h
                            |> Expect.within (Expect.Absolute 1) 0
                    , \_ ->
                        hsl.s
                            |> Expect.within (Expect.Absolute 1) 100
                    , \_ ->
                        hsl.l
                            |> Expect.within (Expect.Absolute 1) 50
                    ]
                    ()
        ]



-- HSL CONVERSIONS


hslConversions : Test
hslConversions =
    describe "HSL conversions"
        [ test "toHsl from HSL is identity" <|
            \_ ->
                Color.fromHSL { h = 120, s = 50, l = 75 }
                    |> Color.toHsl
                    |> Expect.equal { h = 120, s = 50, l = 75 }
        , test "toHsl from HSLA drops alpha" <|
            \_ ->
                Color.fromHSLA { h = 120, s = 50, l = 75, a = 0.5 }
                    |> Color.toHsl
                    |> Expect.equal { h = 120, s = 50, l = 75 }
        , test "toHsla from HSLA is identity" <|
            \_ ->
                Color.fromHSLA { h = 120, s = 50, l = 75, a = 0.5 }
                    |> Color.toHsla
                    |> Expect.equal { h = 120, s = 50, l = 75, a = 0.5 }
        , test "toHsla from non-alpha color defaults alpha to 1.0" <|
            \_ ->
                Color.fromRGB { r = 0, g = 128, b = 0 }
                    |> Color.toHsla
                    |> .a
                    |> Expect.within (Expect.Absolute 0.01) 1.0
        , test "RGB red converts to HSL h=0 s=100 l=50" <|
            \_ ->
                let
                    hsl =
                        Color.fromRGB { r = 255, g = 0, b = 0 }
                            |> Color.toHsl
                in
                Expect.all
                    [ \_ ->
                        hsl.h
                            |> Expect.within (Expect.Absolute 1) 0
                    , \_ ->
                        hsl.s
                            |> Expect.within (Expect.Absolute 1) 100
                    , \_ ->
                        hsl.l
                            |> Expect.within (Expect.Absolute 1) 50
                    ]
                    ()
        , test "HSL to RGB round-trip for pure green" <|
            \_ ->
                Color.fromHSL { h = 120, s = 100, l = 50 }
                    |> Color.toRgb
                    |> Expect.equal { r = 0, g = 255, b = 0 }
        , test "HSL to RGB for achromatic gray" <|
            \_ ->
                Color.fromHSL { h = 0, s = 0, l = 50 }
                    |> Color.toRgb
                    |> Expect.equal { r = 128, g = 128, b = 128 }
        ]



-- RGB CONVERSIONS


rgbConversions : Test
rgbConversions =
    describe "RGB conversions"
        [ test "toRgb from Hex" <|
            \_ ->
                Color.fromHex "#FF8000"
                    |> Maybe.map Color.toRgb
                    |> Expect.equal (Just { r = 255, g = 128, b = 0 })
        , test "toRgb from RGBA drops alpha" <|
            \_ ->
                Color.fromRGBA { r = 100, g = 200, b = 50, a = 0.5 }
                    |> Color.toRgb
                    |> Expect.equal { r = 100, g = 200, b = 50 }
        , test "toRgba from RGB defaults alpha to 1.0" <|
            \_ ->
                Color.fromRGB { r = 100, g = 200, b = 50 }
                    |> Color.toRgba
                    |> .a
                    |> Expect.equal 1.0
        , test "toRgba from RGBA is identity" <|
            \_ ->
                Color.fromRGBA { r = 100, g = 200, b = 50, a = 0.7 }
                    |> Color.toRgba
                    |> Expect.equal { r = 100, g = 200, b = 50, a = 0.7 }
        , test "toRgba from HSLA goes through conversion" <|
            \_ ->
                let
                    rgba =
                        Color.fromHSLA { h = 0, s = 100, l = 50, a = 0.5 }
                            |> Color.toRgba
                in
                Expect.all
                    [ \_ ->
                        rgba.r
                            |> Expect.equal 255
                    , \_ ->
                        rgba.g
                            |> Expect.equal 0
                    , \_ ->
                        rgba.b
                            |> Expect.equal 0
                    , \_ ->
                        rgba.a
                            |> Expect.within (Expect.Absolute 0.01) 0.5
                    ]
                    ()
        ]



-- ALPHA UTILITIES


alphaUtilities : Test
alphaUtilities =
    describe "Alpha utilities"
        [ test "hasExplicitAlpha true for RGBA" <|
            \_ ->
                Color.fromRGBA { r = 0, g = 0, b = 0, a = 1 }
                    |> Color.hasExplicitAlpha
                    |> Expect.equal True
        , test "hasExplicitAlpha true for HSLA" <|
            \_ ->
                Color.fromHSLA { h = 0, s = 0, l = 0, a = 1 }
                    |> Color.hasExplicitAlpha
                    |> Expect.equal True
        , test "hasExplicitAlpha false for RGB" <|
            \_ ->
                Color.fromRGB { r = 0, g = 0, b = 0 }
                    |> Color.hasExplicitAlpha
                    |> Expect.equal False
        , test "hasExplicitAlpha false for Hex" <|
            \_ ->
                Color.fromHex "#000000"
                    |> Maybe.map Color.hasExplicitAlpha
                    |> Expect.equal (Just False)
        , test "hasExplicitAlpha false for HSL" <|
            \_ ->
                Color.fromHSL { h = 0, s = 0, l = 0 }
                    |> Color.hasExplicitAlpha
                    |> Expect.equal False
        , test "getAlpha returns alpha from RGBA" <|
            \_ ->
                Color.fromRGBA { r = 0, g = 0, b = 0, a = 0.3 }
                    |> Color.getAlpha
                    |> Expect.within (Expect.Absolute 0.001) 0.3
        , test "getAlpha returns alpha from HSLA" <|
            \_ ->
                Color.fromHSLA { h = 0, s = 0, l = 0, a = 0.7 }
                    |> Color.getAlpha
                    |> Expect.within (Expect.Absolute 0.001) 0.7
        , test "getAlpha returns 1.0 for non-alpha colors" <|
            \_ ->
                Color.fromRGB { r = 0, g = 0, b = 0 }
                    |> Color.getAlpha
                    |> Expect.equal 1.0
        , test "setAlpha on RGB produces RGBA" <|
            \_ ->
                Color.fromRGB { r = 255, g = 0, b = 0 }
                    |> Color.setAlpha 0.5
                    |> expectRgba { r = 255, g = 0, b = 0, a = 0.5 }
        , test "setAlpha clamps above 1.0" <|
            \_ ->
                Color.fromRGBA { r = 0, g = 0, b = 0, a = 0.5 }
                    |> Color.setAlpha 2.0
                    |> Color.getAlpha
                    |> Expect.equal 1.0
        , test "setAlpha clamps below 0.0" <|
            \_ ->
                Color.fromRGBA { r = 0, g = 0, b = 0, a = 0.5 }
                    |> Color.setAlpha -1.0
                    |> Color.getAlpha
                    |> Expect.equal 0.0
        , test "applyAlphaFromStart transfers alpha to RGB" <|
            \_ ->
                let
                    result =
                        Color.applyAlphaFromStart
                            (Color.fromRGB { r = 0, g = 255, b = 0 })
                            (Color.fromRGBA { r = 255, g = 0, b = 0, a = 0.4 })
                in
                result
                    |> expectRgba { r = 0, g = 255, b = 0, a = 0.4 }
        , test "applyAlphaFromStart transfers alpha to Hex" <|
            \_ ->
                let
                    result =
                        Color.applyAlphaFromStart
                            (Color.fromHex "#00FF00"
                                |> Maybe.withDefault Color.green
                            )
                            (Color.fromRGBA { r = 255, g = 0, b = 0, a = 0.6 })
                in
                case result of
                    Rgba rgba ->
                        rgba.a
                            |> Expect.within (Expect.Absolute 0.001) 0.6

                    _ ->
                        Expect.fail "Expected RGBA result"
        , test "applyAlphaFromStart transfers alpha to HSL" <|
            \_ ->
                let
                    result =
                        Color.applyAlphaFromStart
                            (Color.fromHSL { h = 120, s = 100, l = 50 })
                            (Color.fromHSLA { h = 0, s = 100, l = 50, a = 0.3 })
                in
                case result of
                    Hsla hsla ->
                        hsla.a
                            |> Expect.within (Expect.Absolute 0.001) 0.3

                    _ ->
                        Expect.fail "Expected HSLA result"
        ]



-- COLOR MANIPULATION


colorManipulation : Test
colorManipulation =
    describe "Color manipulation"
        [ test "brighten increases lightness" <|
            \_ ->
                let
                    original =
                        Color.fromHSL { h = 0, s = 100, l = 50 }

                    brightened =
                        Color.brighten 0.2 original
                in
                (Color.toHsl brightened).l
                    |> Expect.within (Expect.Absolute 0.1) 70
        , test "darken decreases lightness" <|
            \_ ->
                let
                    original =
                        Color.fromHSL { h = 0, s = 100, l = 50 }

                    darkened =
                        Color.darken 0.2 original
                in
                (Color.toHsl darkened).l
                    |> Expect.within (Expect.Absolute 0.1) 30
        , test "brighten clamps at 100" <|
            \_ ->
                Color.fromHSL { h = 0, s = 100, l = 90 }
                    |> Color.brighten 0.5
                    |> Color.toHsl
                    |> .l
                    |> Expect.within (Expect.Absolute 0.01) 100
        , test "darken clamps at 0" <|
            \_ ->
                Color.fromHSL { h = 0, s = 100, l = 10 }
                    |> Color.darken 0.5
                    |> Color.toHsl
                    |> .l
                    |> Expect.within (Expect.Absolute 0.01) 0
        , test "saturate increases saturation" <|
            \_ ->
                let
                    original =
                        Color.fromHSL { h = 120, s = 50, l = 50 }

                    saturated =
                        Color.saturate 0.2 original
                in
                (Color.toHsl saturated).s
                    |> Expect.within (Expect.Absolute 0.1) 70
        , test "desaturate decreases saturation" <|
            \_ ->
                let
                    original =
                        Color.fromHSL { h = 120, s = 50, l = 50 }

                    desaturated =
                        Color.desaturate 0.2 original
                in
                (Color.toHsl desaturated).s
                    |> Expect.within (Expect.Absolute 0.1) 30
        , test "brighten preserves alpha on HSLA" <|
            \_ ->
                Color.fromHSLA { h = 0, s = 100, l = 50, a = 0.6 }
                    |> Color.brighten 0.1
                    |> Color.getAlpha
                    |> Expect.within (Expect.Absolute 0.001) 0.6
        , test "saturate preserves alpha on HSLA" <|
            \_ ->
                Color.fromHSLA { h = 0, s = 50, l = 50, a = 0.6 }
                    |> Color.saturate 0.1
                    |> Color.getAlpha
                    |> Expect.within (Expect.Absolute 0.001) 0.6
        ]



-- INTERPOLATION


interpolation : Test
interpolation =
    describe "interpolation"
        [ test "RGB at t=0 returns start" <|
            \_ ->
                Color.interpolate
                    0.0
                    (Color.fromRGB { r = 255, g = 0, b = 0 })
                    (Color.fromRGB { r = 0, g = 0, b = 255 })
                    |> expectRgb { r = 255, g = 0, b = 0 }
        , test "RGB at t=1 returns end" <|
            \_ ->
                Color.interpolate
                    1.0
                    (Color.fromRGB { r = 255, g = 0, b = 0 })
                    (Color.fromRGB { r = 0, g = 0, b = 255 })
                    |> expectRgb { r = 0, g = 0, b = 255 }
        , test "RGB at t=0.5 returns midpoint" <|
            \_ ->
                Color.interpolate
                    0.5
                    (Color.fromRGB { r = 0, g = 0, b = 0 })
                    (Color.fromRGB { r = 200, g = 100, b = 50 })
                    |> expectRgb { r = 100, g = 50, b = 25 }
        , test "Hex to Hex interpolation" <|
            \_ ->
                let
                    start =
                        Color.fromHex "#000000"
                            |> Maybe.withDefault Color.black

                    end =
                        Color.fromHex "#FF0000"
                            |> Maybe.withDefault Color.red

                    result =
                        Color.interpolate 0.5 start end
                in
                Color.toRgb result
                    |> .r
                    |> Expect.equal 128
        , test "HSL interpolation at midpoint" <|
            \_ ->
                let
                    result =
                        Color.interpolate
                            0.5
                            (Color.fromHSL { h = 0, s = 100, l = 50 })
                            (Color.fromHSL { h = 120, s = 100, l = 50 })
                in
                case result of
                    Hsl hsl ->
                        hsl.h
                            |> Expect.within (Expect.Absolute 0.1) 60

                    _ ->
                        Expect.fail "Expected HSL result"
        , test "RGBA interpolation blends alpha" <|
            \_ ->
                let
                    result =
                        Color.interpolate
                            0.5
                            (Color.fromRGBA { r = 0, g = 0, b = 0, a = 0.0 })
                            (Color.fromRGBA { r = 255, g = 255, b = 255, a = 1.0 })
                in
                case result of
                    Rgba rgba ->
                        rgba.a
                            |> Expect.within (Expect.Absolute 0.001) 0.5

                    _ ->
                        Expect.fail "Expected RGBA result"
        , test "HSLA interpolation blends alpha" <|
            \_ ->
                let
                    result =
                        Color.interpolate
                            0.5
                            (Color.fromHSLA { h = 0, s = 100, l = 50, a = 0.2 })
                            (Color.fromHSLA { h = 0, s = 100, l = 50, a = 0.8 })
                in
                case result of
                    Hsla hsla ->
                        hsla.a
                            |> Expect.within (Expect.Absolute 0.001) 0.5

                    _ ->
                        Expect.fail "Expected HSLA result"
        , test "Mixed format normalizes to RGBA" <|
            \_ ->
                let
                    result =
                        Color.interpolate
                            0.0
                            (Color.fromRGBA { r = 255, g = 0, b = 0, a = 0.5 })
                            (Color.fromHSL { h = 240, s = 100, l = 50 })
                in
                case result of
                    Rgba rgba ->
                        rgba.a
                            |> Expect.within (Expect.Absolute 0.001) 0.5

                    Hsla hsla ->
                        hsla.a
                            |> Expect.within (Expect.Absolute 0.001) 0.5

                    _ ->
                        Expect.fail "Expected alpha-carrying result"
        ]



-- DISTANCE


distanceMeasure : Test
distanceMeasure =
    describe "distance"
        [ test "same color has zero distance" <|
            \_ ->
                Color.distance
                    (Color.fromRGB { r = 100, g = 100, b = 100 })
                    (Color.fromRGB { r = 100, g = 100, b = 100 })
                    |> Expect.within (Expect.Absolute 0.001) 0
        , test "black to white is max RGB distance" <|
            \_ ->
                Color.distance Color.black Color.white
                    |> Expect.within (Expect.Absolute 0.01) 441.67
        , test "distance is symmetric" <|
            \_ ->
                let
                    a =
                        Color.fromRGB { r = 50, g = 100, b = 200 }

                    b =
                        Color.fromRGB { r = 200, g = 50, b = 100 }
                in
                Expect.within (Expect.Absolute 0.001)
                    (Color.distance a b)
                    (Color.distance b a)
        , test "pure red to pure blue" <|
            \_ ->
                Color.distance Color.red Color.blue
                    |> Expect.within (Expect.Absolute 0.01) 360.62
        ]



-- EQUALITY


equality : Test
equality =
    describe "isEqual"
        [ test "same RGB values are equal" <|
            \_ ->
                Color.isEqual
                    (Color.fromRGB { r = 128, g = 64, b = 32 })
                    (Color.fromRGB { r = 128, g = 64, b = 32 })
                    |> Expect.equal True
        , test "different RGB values are not equal" <|
            \_ ->
                Color.isEqual
                    (Color.fromRGB { r = 128, g = 64, b = 32 })
                    (Color.fromRGB { r = 128, g = 64, b = 33 })
                    |> Expect.equal False
        , test "cross-format equality via RGBA normalization" <|
            \_ ->
                Color.isEqual
                    (Color.fromRGB { r = 255, g = 0, b = 0 })
                    (Color.fromHex "#FF0000"
                        |> Maybe.withDefault Color.black
                    )
                    |> Expect.equal True
        , test "alpha difference makes colors unequal" <|
            \_ ->
                Color.isEqual
                    (Color.fromRGBA { r = 0, g = 0, b = 0, a = 0.5 })
                    (Color.fromRGBA { r = 0, g = 0, b = 0, a = 0.6 })
                    |> Expect.equal False
        ]



-- LUMINANCE


luminance : Test
luminance =
    describe "isLight / isDark"
        [ test "white is light" <|
            \_ ->
                Color.isLight Color.white
                    |> Expect.equal True
        , test "black is dark" <|
            \_ ->
                Color.isDark Color.black
                    |> Expect.equal True
        , test "white is not dark" <|
            \_ ->
                Color.isDark Color.white
                    |> Expect.equal False
        , test "black is not light" <|
            \_ ->
                Color.isLight Color.black
                    |> Expect.equal False
        , test "bright yellow is light" <|
            \_ ->
                Color.fromRGB { r = 255, g = 255, b = 0 }
                    |> Color.isLight
                    |> Expect.equal True
        , test "dark navy is dark" <|
            \_ ->
                Color.fromRGB { r = 0, g = 0, b = 128 }
                    |> Color.isDark
                    |> Expect.equal True
        ]



-- STRING PARSING


stringParsing : Test
stringParsing =
    describe "fromString"
        [ test "parses hex with #" <|
            \_ ->
                Color.fromString "#FF0000"
                    |> Expect.notEqual Nothing
        , test "parses hex without #" <|
            \_ ->
                Color.fromString "FF0000"
                    |> Expect.notEqual Nothing
        , test "parses rgb()" <|
            \_ ->
                Color.fromString "rgb(255, 128, 0)"
                    |> Maybe.map Color.toRgb
                    |> Expect.equal (Just { r = 255, g = 128, b = 0 })
        , test "parses rgba()" <|
            \_ ->
                Color.fromString "rgba(255, 128, 0, 0.5)"
                    |> Maybe.map Color.toRgba
                    |> Maybe.map (\c -> { r = c.r, g = c.g, b = c.b })
                    |> Expect.equal (Just { r = 255, g = 128, b = 0 })
        , test "parses hsl()" <|
            \_ ->
                Color.fromString "hsl(180, 50%, 60%)"
                    |> Maybe.map Color.toHsl
                    |> Expect.equal (Just { h = 180, s = 50, l = 60 })
        , test "parses hsla()" <|
            \_ ->
                Color.fromString "hsla(180, 50%, 60%, 0.8)"
                    |> Maybe.map Color.toHsla
                    |> Expect.equal (Just { h = 180, s = 50, l = 60, a = 0.8 })
        , test "returns Nothing for invalid input" <|
            \_ ->
                Color.fromString "not-a-color"
                    |> Expect.equal Nothing
        , test "trims whitespace" <|
            \_ ->
                Color.fromString "  #FF0000  "
                    |> Expect.notEqual Nothing
        ]



-- ENCODING


encoding : Test
encoding =
    describe "encode"
        [ test "Hex encodes type and value" <|
            \_ ->
                let
                    json =
                        Color.fromHex "#FF0000"
                            |> Maybe.map Color.encode
                            |> Maybe.map (Encode.encode 0)
                in
                Expect.all
                    [ \_ ->
                        json
                            |> Maybe.map (String.contains "\"type\":\"hex\"")
                            |> Expect.equal (Just True)
                    , \_ ->
                        json
                            |> Maybe.map (String.contains "\"value\":\"#FF0000\"")
                            |> Expect.equal (Just True)
                    ]
                    ()
        , test "RGB encodes with r, g, b fields" <|
            \_ ->
                let
                    json =
                        Color.fromRGB { r = 10, g = 20, b = 30 }
                            |> Color.encode
                            |> Encode.encode 0
                in
                Expect.all
                    [ \_ ->
                        json
                            |> String.contains "\"r\":10"
                            |> Expect.equal True
                    , \_ ->
                        json
                            |> String.contains "\"g\":20"
                            |> Expect.equal True
                    , \_ ->
                        json
                            |> String.contains "\"b\":30"
                            |> Expect.equal True
                    , \_ ->
                        json
                            |> String.contains "\"type\":\"rgb\""
                            |> Expect.equal True
                    ]
                    ()
        , test "RGBA encodes with alpha" <|
            \_ ->
                let
                    json =
                        Color.fromRGBA { r = 10, g = 20, b = 30, a = 0.5 }
                            |> Color.encode
                            |> Encode.encode 0
                in
                Expect.all
                    [ \_ ->
                        json
                            |> String.contains "\"type\":\"rgba\""
                            |> Expect.equal True
                    , \_ ->
                        json
                            |> String.contains "\"a\":0.5"
                            |> Expect.equal True
                    ]
                    ()
        ]



-- ELM COLOR INTEGRATION


elmColorIntegration : Test
elmColorIntegration =
    describe "Elm Color integration"
        [ test "fromElmColor round-trips through toElmColor" <|
            \_ ->
                let
                    original =
                        ElmColor.rgb255 200 100 50

                    roundTripped =
                        Color.fromElmColor original
                            |> Color.toElmColor
                            |> ElmColor.toRgba
                in
                Expect.all
                    [ \_ ->
                        round (roundTripped.red * 255)
                            |> Expect.equal 200
                    , \_ ->
                        round (roundTripped.green * 255)
                            |> Expect.equal 100
                    , \_ ->
                        round (roundTripped.blue * 255)
                            |> Expect.equal 50
                    ]
                    ()
        , test "toElmColor from RGB" <|
            \_ ->
                let
                    elmRgba =
                        Color.fromRGB { r = 128, g = 64, b = 32 }
                            |> Color.toElmColor
                            |> ElmColor.toRgba
                in
                Expect.all
                    [ \_ ->
                        round (elmRgba.red * 255)
                            |> Expect.equal 128
                    , \_ ->
                        round (elmRgba.green * 255)
                            |> Expect.equal 64
                    , \_ ->
                        round (elmRgba.blue * 255)
                            |> Expect.equal 32
                    , \_ ->
                        elmRgba.alpha
                            |> Expect.within (Expect.Absolute 0.01) 1.0
                    ]
                    ()
        , test "elmColorToHex produces valid hex" <|
            \_ ->
                ElmColor.rgb255 255 0 0
                    |> Color.elmColorToHex
                    |> Expect.equal "#FF0000FF"
        , test "hexToElmColor round-trips" <|
            \_ ->
                let
                    elmRgba =
                        Color.hexToElmColor "#00FF00"
                            |> ElmColor.toRgba
                in
                Expect.all
                    [ \_ ->
                        round (elmRgba.red * 255)
                            |> Expect.equal 0
                    , \_ ->
                        round (elmRgba.green * 255)
                            |> Expect.equal 255
                    , \_ ->
                        round (elmRgba.blue * 255)
                            |> Expect.equal 0
                    ]
                    ()
        ]



-- TEST HELPERS


expectRgb : { r : Int, g : Int, b : Int } -> Color -> Expect.Expectation
expectRgb expected color =
    case color of
        Rgb rgb ->
            Expect.equal expected rgb

        _ ->
            Expect.fail ("Expected Rgb, got " ++ colorTag color)


expectRgba : { r : Int, g : Int, b : Int, a : Float } -> Color -> Expect.Expectation
expectRgba expected color =
    case color of
        Rgba rgba ->
            Expect.all
                [ \_ ->
                    rgba.r
                        |> Expect.equal expected.r
                , \_ ->
                    rgba.g
                        |> Expect.equal expected.g
                , \_ ->
                    rgba.b
                        |> Expect.equal expected.b
                , \_ ->
                    rgba.a
                        |> Expect.within (Expect.Absolute 0.001) expected.a
                ]
                ()

        _ ->
            Expect.fail ("Expected Rgba, got " ++ colorTag color)


expectHsl : { h : Float, s : Float, l : Float } -> Color -> Expect.Expectation
expectHsl expected color =
    case color of
        Hsl hsl ->
            Expect.all
                [ \_ ->
                    hsl.h
                        |> Expect.within (Expect.Absolute 0.001) expected.h
                , \_ ->
                    hsl.s
                        |> Expect.within (Expect.Absolute 0.001) expected.s
                , \_ ->
                    hsl.l
                        |> Expect.within (Expect.Absolute 0.001) expected.l
                ]
                ()

        _ ->
            Expect.fail ("Expected Hsl, got " ++ colorTag color)


expectHsla : { h : Float, s : Float, l : Float, a : Float } -> Color -> Expect.Expectation
expectHsla expected color =
    case color of
        Hsla hsla ->
            Expect.all
                [ \_ ->
                    hsla.h
                        |> Expect.within (Expect.Absolute 0.001) expected.h
                , \_ ->
                    hsla.s
                        |> Expect.within (Expect.Absolute 0.001) expected.s
                , \_ ->
                    hsla.l
                        |> Expect.within (Expect.Absolute 0.001) expected.l
                , \_ ->
                    hsla.a
                        |> Expect.within (Expect.Absolute 0.001) expected.a
                ]
                ()

        _ ->
            Expect.fail ("Expected Hsla, got " ++ colorTag color)


colorTag : Color -> String
colorTag color =
    case color of
        Hex _ ->
            "Hex"

        Rgb _ ->
            "Rgb"

        Rgba _ ->
            "Rgba"

        Hsl _ ->
            "Hsl"

        Hsla _ ->
            "Hsla"

        ElmColor _ ->
            "ElmColor"
