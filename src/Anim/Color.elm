module Anim.Color exposing
    ( Color
    , rgb, rgba
    , hsl, hsla
    , hex, hexStringToRgb, hexStringToRgba
    , elmColor
    , toHex, toRgb, fromRgbString, toRgba, toHsl, toHsla, toElmColor, toCssString
    , distance, encode
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

@docs distance, encode

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
toRgb =
    CP.toRgb


{-| Convert to an RGBA color record.
-}
toRgba : Color -> { r : Int, g : Int, b : Int, a : Float }
toRgba =
    CP.toRgba


{-| Convert to an HSL color record.
-}
toHsl : Color -> { h : Float, s : Float, l : Float }
toHsl =
    CP.toHsl


{-| Convert to an HSLA color record.
-}
toHsla : Color -> { h : Float, s : Float, l : Float, a : Float }
toHsla =
    CP.toHsla


{-| Convert to an ElmColor Color.Color value.
-}
toElmColor : Color -> Color.Color
toElmColor =
    CP.toElmColor


{-| Convert a hex string to an RGB color record.
-}
hexStringToRgb : String -> { r : Int, g : Int, b : Int }
hexStringToRgb =
    CP.hexToRgb


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
