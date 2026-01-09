module Anim.Color exposing
    ( Color
    , fromHex, toHex, hexStringToRgb, hexStringToRgba
    , fromRgb, fromRgba, fromRgbString, toRgb, toRgba
    , fromHsl, fromHsla, toHsl, toHsla
    , fromElmColor, toElmColor
    , toCssString
    , distance
    , encode
    )

{-| Shared color type for all color-based animation properties.


# Color Type

@docs Color


# Hex Colors

@docs fromHex, toHex, hexStringToRgb, hexStringToRgba


# RGB Colors

@docs fromRgb, fromRgba, fromRgbString, toRgb, toRgba


# HSL Colors

@docs fromHsl, fromHsla, toHsl, toHsla


# Elm Color Integration

Use colors from the [avh4/elm-color](https://package.elm-lang.org/packages/avh4/elm-color/latest/) package.

@docs fromElmColor, toElmColor


# Color Transformations

@docs toCssString


# Color Distance

@docs distance


# Encoding

@docs encode

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
fromHex : String -> Color
fromHex =
    CP.fromHex



-- RGB COLORS


{-| Create an RGB color.

    rgb 255 0 0 -- Red

-}
fromRgb : Int -> Int -> Int -> Color
fromRgb =
    CP.fromRGB


{-| Create an RGBA color with alpha transparency.

    rgba 255 0 0 0.5 -- Semi-transparent red

-}
fromRgba : Int -> Int -> Int -> Float -> Color
fromRgba =
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
fromHsl : Float -> Float -> Float -> Color
fromHsl =
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
fromHsla : Float -> Float -> Float -> Float -> Color
fromHsla =
    CP.fromHSLA



-- ELM COLOR INTEGRATION


{-| Create a [Color](#Color) from an [elm-color](https://package.elm-lang.org/packages/avh4/elm-color/latest/) [Color](https://package.elm-lang.org/packages/avh4/elm-color/latest/Color) value.

    import Color

    fromElmColor Color.red
    fromElmColor Color.blue

-}
fromElmColor : Color.Color -> Color
fromElmColor =
    CP.fromElmColor



-- Transform
--
--
-- HEX STRINGS


{-| Convert a Color to a hex string .
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


{-| Convert to an [elm-color](https://package.elm-lang.org/packages/avh4/elm-color/latest/) [Color](https://package.elm-lang.org/packages/avh4/elm-color/latest/Color) value.
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
hexStringToRgba =
    CP.hexToRgba


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
distance =
    CP.distance


{-| Encode Color to JSON for serialization.
-}
encode : Color -> Encode.Value
encode =
    CP.encode
