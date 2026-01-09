module Anim.Color exposing
    ( Color
    , fromHex, toHex
    , fromRgb, fromRgba, toRgb, toRgba
    , fromHsl, fromHsla, toHsl, toHsla
    , fromElmColor, toElmColor
    , fromString
    , toCssString
    , setAlpha, getAlpha
    , brighten, darken, saturate, desaturate
    , isLight, isDark
    , isEqual
    , transparent, black, white, red, green, blue
    , distance
    , encode
    )

{-| Shared color type for all color-based animation properties.


# Color Type

@docs Color


# Hex Colors

@docs fromHex, toHex


# RGB Colors

@docs fromRgb, fromRgba, toRgb, toRgba


# HSL Colors

@docs fromHsl, fromHsla, toHsl, toHsla


# Elm Color Integration

Use colors from the [avh4/elm-color](https://package.elm-lang.org/packages/avh4/elm-color/latest/) package.

@docs fromElmColor, toElmColor


# Color Parsing

@docs fromString


# Color Transformations

@docs toCssString


# Alpha Utilities

@docs setAlpha, getAlpha


# Color Manipulation

@docs brighten, darken, saturate, desaturate


# Color Queries

@docs isLight, isDark


# Color Comparison

@docs isEqual


# Common Colors

@docs transparent, black, white, red, green, blue


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


{-| Create a color from a hex string. Returns `Nothing` if the hex string is invalid.

    fromHex "#ff0000" -- Just Red

    fromHex "#f00" -- Just Red (shorthand)

    fromHex "invalid" -- Nothing

-}
fromHex : String -> Maybe Color
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


{-| Parse a color from various string formats.

Supports:

  - Hex: "#ff0000", "#f00", "ff0000", "f00"

  - RGB: "rgb(255, 0, 0)"

  - RGBA: "rgba(255, 0, 0, 0.5)"

  - HSL: "hsl(0, 100%, 50%)"

  - HSLA: "hsla(0, 100%, 50%, 0.5)"

    fromString "#ff0000" -- Just red
    fromString "rgb(255, 0, 0)" -- Just red
    fromString "invalid" -- Nothing

-}
fromString : String -> Maybe Color
fromString =
    CP.fromString



-- ALPHA UTILITIES


{-| Set the alpha (transparency) value of a color.

    setAlpha 0.5 (fromRgb 255 0 0) -- Semi-transparent red

    Maybe.map (setAlpha 0.0) (fromHex "#ff0000") -- Maybe (fully transparent red)

-}
setAlpha : Float -> Color -> Color
setAlpha =
    CP.setAlpha


{-| Get the alpha value of a color. Returns 1.0 for opaque colors.

    getAlpha (fromRgba 255 0 0 0.5) -- 0.5

    getAlpha (fromRgb 255 0 0) -- 1.0

-}
getAlpha : Color -> Float
getAlpha =
    CP.getAlpha



-- COLOR MANIPULATION


{-| Increase the lightness of a color.

    Maybe.map (brighten 0.2) (fromHex "#808080") -- Maybe (lighter gray)

-}
brighten : Float -> Color -> Color
brighten =
    CP.brighten


{-| Decrease the lightness of a color.

    Maybe.map (darken 0.2) (fromHex "#808080") -- Maybe (darker gray)

-}
darken : Float -> Color -> Color
darken =
    CP.darken


{-| Increase the saturation of a color.

    saturate 0.2 (fromHsl 0 50 50) -- More saturated red

-}
saturate : Float -> Color -> Color
saturate =
    CP.saturate


{-| Decrease the saturation of a color.

    desaturate 0.2 (fromHsl 0 100 50) -- Less saturated red

-}
desaturate : Float -> Color -> Color
desaturate =
    CP.desaturate



-- COLOR QUERIES


{-| Check if a color is considered light based on its luminance.

    isLight white -- True

    isLight black -- False

-}
isLight : Color -> Bool
isLight =
    CP.isLight


{-| Check if a color is considered dark based on its luminance.

    isDark black -- True

    isDark white -- False

-}
isDark : Color -> Bool
isDark =
    CP.isDark



-- COLOR COMPARISON


{-| Check if two colors are equal.

    isEqual red (fromRgb 255 0 0) -- True

-}
isEqual : Color -> Color -> Bool
isEqual =
    CP.isEqual



-- COMMON COLORS


{-| Fully transparent color.
-}
transparent : Color
transparent =
    CP.transparent


{-| Black color.
-}
black : Color
black =
    CP.black


{-| White color.
-}
white : Color
white =
    CP.white


{-| Red color.
-}
red : Color
red =
    CP.red


{-| Green color.
-}
green : Color
green =
    CP.green


{-| Blue color.
-}
blue : Color
blue =
    CP.blue


{-| Encode Color to JSON for serialization.
-}
encode : Color -> Encode.Value
encode =
    CP.encode
