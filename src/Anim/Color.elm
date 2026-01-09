module Anim.Color exposing
    ( Color
    , rgb, rgba
    , hsl, hsla
    , hex, hexStringToRgb, hexStringToRgba
    , elmColor
    , toHex, toRgb, fromRgbString, toRgba, toHsl, toHsla, toElmColor, toCssString
    , distance, interpolate, encode
    )

{-| Shared color type for all color-based animation properties.

This module provides a unified color API that can be used with:

  - [BackgroundColor](Anim-Property-BackgroundColor)
  - [FontColor](Anim-Property-FontColor)
  - BorderColor (coming soon)


# Color Type

@docs Color


# RGB Colors

@docs rgb, rgba


# HSL Colors

@docs hsl, hsla


# Hex Colors

@docs hex, hexStringToRgb, hexStringToRgba


# Elm Color Integration

@docs elmColor


# Color Transformations

@docs toHex, toRgb, fromRgbString, toRgba, toHsl, toHsla, toElmColor, toCssString

@docs distance, interpolate, encode

-}

import Anim.Internal.Properties.Color as CP exposing (Color(..))
import Color
import Json.Encode as Encode


{-| Type alias for Color values used in animations.
-}
type alias Color =
    CP.Color


{-| Convert a Color to its CSS string representation.
-}
toCssString : Color -> String
toCssString =
    CP.toCssString



-- HEX COLORS


{-| Create a color from a hex string.

    hex "#ff0000" -- Red

    hex "#f00" -- Red (shorthand)

-}
hex : String -> Color
hex =
    CP.fromHex



-- RGB COLORS


{-| Create an RGB color.

    rgb 255 0 0 -- Red

-}
rgb : Int -> Int -> Int -> Color
rgb =
    CP.fromRGB


{-| Create an RGBA color with alpha transparency.

    rgba 255 0 0 0.5 -- Semi-transparent red

-}
rgba : Int -> Int -> Int -> Float -> Color
rgba =
    CP.fromRGBA


{-| Create a Color from an "rgb(r, g, b)" formatted string.

    fromRgbString "rgb(255, 0, 0)" -- Red

-}
fromRgbString : String -> Maybe Color
fromRgbString =
    CP.fromRgbString



-- HSL COLORS


{-| Create an HSL color.

  - `h` (hue): 0-360 degrees
  - `s` (saturation): 0-100 percent
  - `l` (lightness): 0-100 percent

```
hsl 0 100 50 -- Red
```

-}
hsl : Float -> Float -> Float -> Color
hsl =
    CP.fromHSL


{-| Create an HSLA color with alpha transparency.

  - `h` (hue): 0-360 degrees
  - `s` (saturation): 0-100 percent
  - `l` (lightness): 0-100 percent
  - `a` (alpha): 0-1

```
hsla 0 100 50 0.5 -- Semi-transparent red
```

-}
hsla : Float -> Float -> Float -> Float -> Color
hsla =
    CP.fromHSLA



-- ELM COLOR INTEGRATION


{-| Use a color from the [avh4/elm-color](https://package.elm-lang.org/packages/avh4/elm-color/latest/) package.

    import Color

    elmColor Color.red
    elmColor Color.blue

This allows you to use the color manipulation functions from elm-color.

-}
elmColor : Color.Color -> Color
elmColor =
    CP.fromElmColor



-- Transform
--
--
-- HEX STRINGS


{-| Convert to a hex string Color.
-}
toHex : Color -> String
toHex =
    CP.toHex


{-| Convert to an RGB color record.
-}
toRgb : Color -> { r : Int, g : Int, b : Int }
toRgb color =
    case color of
        Hex hexStr ->
            hexStringToRgb hexStr

        Rgb rgb_ ->
            rgb_

        Rgba rgba_ ->
            { r = rgba_.r, g = rgba_.g, b = rgba_.b }

        Hsl hsl_ ->
            hslToRgb hsl_

        Hsla hsla_ ->
            hslToRgb { h = hsla_.h, s = hsla_.s, l = hsla_.l }

        ElmColor elmColor_ ->
            elmColor_
                |> Color.toRgba
                |> (\{ red, green, blue } ->
                        { r = round (red * 255)
                        , g = round (green * 255)
                        , b = round (blue * 255)
                        }
                   )


{-| Convert to an RGBA color record.
-}
toRgba : Color -> { r : Int, g : Int, b : Int, a : Float }
toRgba color =
    case color of
        Hex hexStr ->
            hexStringToRgba hexStr

        Rgb rgb_ ->
            { r = rgb_.r, g = rgb_.g, b = rgb_.b, a = 1.0 }

        Rgba rgba_ ->
            rgba_

        Hsl hsl_ ->
            hslToRgba hsl_

        Hsla hsla_ ->
            hslaToRgba hsla_

        ElmColor elmColor_ ->
            elmColor_
                |> Color.toRgba
                |> (\{ red, green, blue, alpha } ->
                        { r = round (red * 255)
                        , g = round (green * 255)
                        , b = round (blue * 255)
                        , a = alpha
                        }
                   )


{-| Convert to an HSL color record.
-}
toHsl : Color -> { h : Float, s : Float, l : Float }
toHsl color =
    case color of
        Hex hexStr ->
            let
                rgb_ =
                    hexStringToRgb hexStr
            in
            rgbToHsl rgb_

        Rgb rgb_ ->
            rgbToHsl rgb_

        Rgba rgba_ ->
            rgbToHsl { r = rgba_.r, g = rgba_.g, b = rgba_.b }

        Hsl hsl_ ->
            hsl_

        Hsla hsla_ ->
            { h = hsla_.h, s = hsla_.s, l = hsla_.l }

        ElmColor elmColor_ ->
            elmColor_
                |> Color.toRgba
                |> (\{ red, green, blue } ->
                        { r = round (red * 255)
                        , g = round (green * 255)
                        , b = round (blue * 255)
                        }
                   )
                |> rgbToHsl


{-| Convert to an HSLA color record.
-}
toHsla : Color -> { h : Float, s : Float, l : Float, a : Float }
toHsla color =
    case color of
        Hex hexStr ->
            let
                rgb_ =
                    hexStringToRgb hexStr
            in
            { r = rgb_.r, g = rgb_.g, b = rgb_.b, a = 1.0 }
                |> rgbaToHsla

        Rgb rgb_ ->
            { r = rgb_.r, g = rgb_.g, b = rgb_.b, a = 1.0 }
                |> rgbaToHsla

        Rgba rgba_ ->
            { r = rgba_.r, g = rgba_.g, b = rgba_.b, a = rgba_.a }
                |> rgbaToHsla

        Hsl hsl_ ->
            { h = hsl_.h, s = hsl_.s, l = hsl_.l, a = 1.0 }

        Hsla hsla_ ->
            hsla_

        ElmColor elmColor_ ->
            elmColor_
                |> Color.toRgba
                |> (\{ red, green, blue, alpha } ->
                        { r = round (red * 255)
                        , g = round (green * 255)
                        , b = round (blue * 255)
                        , a = alpha
                        }
                   )
                |> rgbaToHsla


{-| Convert to an ElmColor Color.Color value.
-}
toElmColor : Color -> Color
toElmColor color =
    ElmColor <|
        case color of
            Hex hexStr ->
                let
                    rgb_ =
                        hexStringToRgb hexStr
                in
                Color.rgba
                    (toFloat rgb_.r / 255)
                    (toFloat rgb_.g / 255)
                    (toFloat rgb_.b / 255)
                    1.0

            Rgb rgb_ ->
                Color.rgba
                    (toFloat rgb_.r / 255)
                    (toFloat rgb_.g / 255)
                    (toFloat rgb_.b / 255)
                    1.0

            Rgba rgba_ ->
                Color.rgba
                    (toFloat rgba_.r / 255)
                    (toFloat rgba_.g / 255)
                    (toFloat rgba_.b / 255)
                    rgba_.a

            Hsl hsl_ ->
                let
                    rgb_ =
                        hslToRgb hsl_
                in
                Color.rgba
                    (toFloat rgb_.r / 255)
                    (toFloat rgb_.g / 255)
                    (toFloat rgb_.b / 255)
                    1.0

            Hsla hsla_ ->
                let
                    rgb_ =
                        hslToRgb { h = hsla_.h, s = hsla_.s, l = hsla_.l }
                in
                Color.rgba
                    (toFloat rgb_.r / 255)
                    (toFloat rgb_.g / 255)
                    (toFloat rgb_.b / 255)
                    hsla_.a

            ElmColor elmColor_ ->
                elmColor_


floatMod : Float -> Float -> Float
floatMod a b =
    a - (toFloat (floor (a / b)) * b)


hslToRgb : { a | h : Float, s : Float, l : Float } -> { r : Int, g : Int, b : Int }
hslToRgb hsl_ =
    let
        s =
            hsl_.s / 100

        l =
            hsl_.l / 100

        c =
            (1 - abs (2 * l - 1)) * s

        x =
            c * (1 - abs (floatMod (hsl_.h / 60) 2 - 1))

        m =
            l - c / 2

        ( r1, g1, b1 ) =
            if hsl_.h < 60 then
                ( c, x, 0 )

            else if hsl_.h < 120 then
                ( x, c, 0 )

            else if hsl_.h < 180 then
                ( 0, c, x )

            else if hsl_.h < 240 then
                ( 0, x, c )

            else if hsl_.h < 300 then
                ( x, 0, c )

            else
                ( c, 0, x )

        r =
            round ((r1 + m) * 255)

        g =
            round ((g1 + m) * 255)

        b =
            round ((b1 + m) * 255)
    in
    { r = r, g = g, b = b }


hslToRgba : { h : Float, s : Float, l : Float } -> { r : Int, g : Int, b : Int, a : Float }
hslToRgba hsl_ =
    let
        rgb_ =
            hslToRgb hsl_
    in
    { r = rgb_.r, g = rgb_.g, b = rgb_.b, a = 1.0 }


hslaToRgba : { h : Float, s : Float, l : Float, a : Float } -> { r : Int, g : Int, b : Int, a : Float }
hslaToRgba hsla_ =
    let
        rgb_ =
            hslToRgb { h = hsla_.h, s = hsla_.s, l = hsla_.l }
    in
    { r = rgb_.r, g = rgb_.g, b = rgb_.b, a = hsla_.a }


rgbToHsl : { r : Int, g : Int, b : Int } -> { h : Float, s : Float, l : Float }
rgbToHsl rgb_ =
    let
        r =
            toFloat rgb_.r / 255

        g =
            toFloat rgb_.g / 255

        b =
            toFloat rgb_.b / 255

        maxVal =
            max r (max g b)

        minVal =
            min r (min g b)

        delta =
            maxVal - minVal

        l =
            (maxVal + minVal) / 2

        s =
            if delta == 0 then
                0

            else
                delta / (1 - abs (2 * l - 1))

        h =
            if delta == 0 then
                0

            else if maxVal == r then
                60 * floatMod ((g - b) / delta) 6

            else if maxVal == g then
                60 * (((b - r) / delta) + 2)

            else
                60 * (((r - g) / delta) + 4)
    in
    { h =
        if h < 0 then
            h + 360

        else
            h
    , s = s * 100
    , l = l * 100
    }


rgbaToHsla : { r : Int, g : Int, b : Int, a : Float } -> { h : Float, s : Float, l : Float, a : Float }
rgbaToHsla rgba_ =
    let
        hsl_ =
            rgbToHsl { r = rgba_.r, g = rgba_.g, b = rgba_.b }
    in
    { h = hsl_.h, s = hsl_.s, l = hsl_.l, a = rgba_.a }


hexStringToInt : String -> Maybe Int
hexStringToInt str =
    let
        hexCharToInt char =
            case char of
                '0' ->
                    Just 0

                '1' ->
                    Just 1

                '2' ->
                    Just 2

                '3' ->
                    Just 3

                '4' ->
                    Just 4

                '5' ->
                    Just 5

                '6' ->
                    Just 6

                '7' ->
                    Just 7

                '8' ->
                    Just 8

                '9' ->
                    Just 9

                'A' ->
                    Just 10

                'a' ->
                    Just 10

                'B' ->
                    Just 11

                'b' ->
                    Just 11

                'C' ->
                    Just 12

                'c' ->
                    Just 12

                'D' ->
                    Just 13

                'd' ->
                    Just 13

                'E' ->
                    Just 14

                'e' ->
                    Just 14

                'F' ->
                    Just 15

                'f' ->
                    Just 15

                _ ->
                    Nothing

        chars =
            String.toList str
    in
    case chars of
        [ c1, c2 ] ->
            Maybe.map2 (\v1 v2 -> v1 * 16 + v2) (hexCharToInt c1) (hexCharToInt c2)

        _ ->
            Nothing


{-| Convert a hex string to an RGB color record.
-}
hexStringToRgb : String -> { r : Int, g : Int, b : Int }
hexStringToRgb hex_ =
    let
        cleanHex =
            String.dropLeft
                (if String.startsWith "#" hex_ then
                    1

                 else
                    0
                )
                hex_

        r =
            String.slice 0 2 cleanHex |> hexStringToInt |> Maybe.withDefault 0

        g =
            String.slice 2 4 cleanHex |> hexStringToInt |> Maybe.withDefault 0

        b =
            String.slice 4 6 cleanHex |> hexStringToInt |> Maybe.withDefault 0
    in
    { r = r, g = g, b = b }


{-| Convert a hex string to an RGBA color record.
-}
hexStringToRgba : String -> { r : Int, g : Int, b : Int, a : Float }
hexStringToRgba hex_ =
    let
        rgb_ =
            hexStringToRgb hex_
    in
    { r = rgb_.r, g = rgb_.g, b = rgb_.b, a = 1.0 }


{-| Calculate distance between two Color values using RGB Euclidean distance.

This follows a simplified approach to color distance calculation:

  - distance = sqrt((r2-r1)² + (g2-g1)² + (b2-b1)²)

While industry standard Delta E (CIE94/2000) would be more perceptually accurate,
RGB Euclidean distance provides a reasonable approximation for animation timing
and is much simpler to calculate.

Note: All color types are converted to RGB before distance calculation.

Example:
distance (rgb255 255 0 0) (rgb255 0 255 0)
-- Returns: sqrt(255² + 255² + 0²) ≈ 360.6

-}
distance : Color -> Color -> Float
distance color1 color2 =
    let
        rgb1 =
            toRgb color1

        rgb2 =
            toRgb color2

        dr =
            toFloat (rgb2.r - rgb1.r)

        dg =
            toFloat (rgb2.g - rgb1.g)

        db =
            toFloat (rgb2.b - rgb1.b)
    in
    sqrt (dr * dr + dg * dg + db * db)


{-| Interpolate between two Color values.
-}
interpolate : Color -> Color -> Float -> Color
interpolate start end t =
    case ( start, end ) of
        ( Hex startHex, Hex endHex ) ->
            -- Convert hex to RGB, interpolate, then convert back
            let
                startRgb =
                    hexStringToRgb startHex

                endRgb =
                    hexStringToRgb endHex

                r =
                    round <| toFloat startRgb.r + (toFloat (endRgb.r - startRgb.r) * t)

                g =
                    round <| toFloat startRgb.g + (toFloat (endRgb.g - startRgb.g) * t)

                b =
                    round <| toFloat startRgb.b + (toFloat (endRgb.b - startRgb.b) * t)
            in
            Rgb { r = r, g = g, b = b }

        ( Rgb startRgb, Rgb endRgb ) ->
            let
                r =
                    round <| toFloat startRgb.r + (toFloat (endRgb.r - startRgb.r) * t)

                g =
                    round <| toFloat startRgb.g + (toFloat (endRgb.g - startRgb.g) * t)

                b =
                    round <| toFloat startRgb.b + (toFloat (endRgb.b - startRgb.b) * t)
            in
            Rgb { r = r, g = g, b = b }

        ( Rgba startRgba, Rgba endRgba ) ->
            let
                r =
                    round <| toFloat startRgba.r + (toFloat (endRgba.r - startRgba.r) * t)

                g =
                    round <| toFloat startRgba.g + (toFloat (endRgba.g - startRgba.g) * t)

                b =
                    round <| toFloat startRgba.b + (toFloat (endRgba.b - startRgba.b) * t)

                a =
                    startRgba.a + (endRgba.a - startRgba.a) * t
            in
            Rgba { r = r, g = g, b = b, a = a }

        ( Hsl startHsl, Hsl endHsl ) ->
            let
                h =
                    startHsl.h + (endHsl.h - startHsl.h) * t

                s =
                    startHsl.s + (endHsl.s - startHsl.s) * t

                l =
                    startHsl.l + (endHsl.l - startHsl.l) * t
            in
            Hsl { h = h, s = s, l = l }

        ( Hsla startHsla, Hsla endHsla ) ->
            let
                h =
                    startHsla.h + (endHsla.h - startHsla.h) * t

                s =
                    startHsla.s + (endHsla.s - startHsla.s) * t

                l =
                    startHsla.l + (endHsla.l - startHsla.l) * t

                a =
                    startHsla.a + (endHsla.a - startHsla.a) * t
            in
            Hsla { h = h, s = s, l = l, a = a }

        _ ->
            -- Normalize both colors to alpha-enabled formats
            -- Preserve start alpha when end color has no explicit alpha (RGB/Hex/HSL)
            -- Use end alpha when explicitly specified (RGBA/HSLA)
            let
                startAlpha =
                    case start of
                        Rgba rgba_ ->
                            rgba_.a

                        Hsla hsla_ ->
                            hsla_.a

                        _ ->
                            1.0
            in
            case ( start, end ) of
                -- If end is HSL (no alpha), normalize both to HSLA preserving start alpha
                ( _, Hsl _ ) ->
                    let
                        startHsla =
                            toHsla start

                        endHsla =
                            toHsla end
                    in
                    interpolate (Hsla startHsla) (Hsla { endHsla | a = startAlpha }) t

                -- If end is HSLA (explicit alpha), use it
                ( _, Hsla _ ) ->
                    interpolate (Hsla (toHsla start)) end t

                -- If end is RGB/Hex (no alpha), normalize to RGBA preserving start alpha
                ( _, Rgb _ ) ->
                    let
                        startRgba =
                            toRgba start

                        endRgba =
                            toRgba end
                    in
                    interpolate (Rgba startRgba) (Rgba { endRgba | a = startAlpha }) t

                ( _, Hex _ ) ->
                    let
                        startRgba =
                            toRgba start

                        endRgba =
                            toRgba end
                    in
                    interpolate (Rgba startRgba) (Rgba { endRgba | a = startAlpha }) t

                -- If end is RGBA (explicit alpha), use it
                ( _, Rgba _ ) ->
                    interpolate (Rgba (toRgba start)) end t

                ( _, ElmColor _ ) ->
                    interpolate (toElmColor start) end t


{-| Encode Color to JSON for serialization.
-}
encode : Color -> Encode.Value
encode color =
    case color of
        Hex hex_ ->
            Encode.object
                [ ( "type", Encode.string "hex" )
                , ( "value", Encode.string hex_ )
                ]

        Rgb rgb_ ->
            Encode.object
                [ ( "type", Encode.string "rgb" )
                , ( "r", Encode.int rgb_.r )
                , ( "g", Encode.int rgb_.g )
                , ( "b", Encode.int rgb_.b )
                ]

        Rgba rgba_ ->
            Encode.object
                [ ( "type", Encode.string "rgba" )
                , ( "r", Encode.int rgba_.r )
                , ( "g", Encode.int rgba_.g )
                , ( "b", Encode.int rgba_.b )
                , ( "a", Encode.float rgba_.a )
                ]

        Hsl hsl_ ->
            Encode.object
                [ ( "type", Encode.string "hsl" )
                , ( "h", Encode.float hsl_.h )
                , ( "s", Encode.float hsl_.s )
                , ( "l", Encode.float hsl_.l )
                ]

        Hsla hsla_ ->
            Encode.object
                [ ( "type", Encode.string "hsla" )
                , ( "h", Encode.float hsla_.h )
                , ( "s", Encode.float hsla_.s )
                , ( "l", Encode.float hsla_.l )
                , ( "a", Encode.float hsla_.a )
                ]

        ElmColor elmColor_ ->
            Encode.object
                [ ( "type", Encode.string "elmColor" )
                , ( "value", Encode.string (Color.toCssString elmColor_) )
                ]
