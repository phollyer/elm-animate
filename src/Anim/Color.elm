module Anim.Color exposing
    ( Color
    , fromHex, toHex
    , fromRgb, fromRgba, toRgb, toRgba
    , fromHsl, fromHsla, toHsl, toHsla
    , fromElmColor, toElmColor
    , fromString
    , setAlpha, getAlpha
    , brighten, darken, saturate, desaturate
    , isLight, isDark
    , isEqual
    , distance
    , transparent, black, white, red, green, blue
    )

{-| Color manipulation and conversion utilities for the shared Color type.

Use these functions to create, transform, and analyze colors in various formats, then use them in animations.


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


# Parsing

@docs fromString


# Alpha

@docs setAlpha, getAlpha


# Manipulation

@docs brighten, darken, saturate, desaturate

@docs isLight, isDark


# Comparison

@docs isEqual


# Distance

@docs distance


# Common Colors

@docs transparent, black, white, red, green, blue

-}

import Anim.Internal.Properties.Color as CP exposing (Color(..))
import Color


{-| Type alias for Color values used in animations.
-}
type alias Color =
    CP.Color



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


{-| Create a Color from RGB components.

    fromRgb { r = 255, g = 0, b = 0 } -- Red

-}
fromRgb : { r : Int, g : Int, b : Int } -> Color
fromRgb =
    CP.fromRGB


{-| Create an Color from RGBA components.

    fromRgba { r = 255, g = 0, b = 0, a = 0.5 } -- Semi-transparent red

-}
fromRgba : { r : Int, g : Int, b : Int, a : Float } -> Color
fromRgba =
    CP.fromRGBA



-- HSL COLORS


{-| Create a Color from HSL components.

  - `h` (hue): 0-360 degrees
  - `s` (saturation): 0-100 percent
  - `l` (lightness): 0-100 percent

```
fromHsl { h = 0, s = 100, l = 50 } -- Red
```

-}
fromHsl : { h : Float, s : Float, l : Float } -> Color
fromHsl =
    CP.fromHSL


{-| Create a Color from HSLA components.

  - `h` (hue): 0-360 degrees
  - `s` (saturation): 0-100 percent
  - `l` (lightness): 0-100 percent
  - `a` (alpha): 0-1

```
fromHsla { h = 0, s = 100, l = 50, a = 0.5 } -- Semi-transparent red
```

-}
fromHsla : { h : Float, s : Float, l : Float, a : Float } -> Color
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


{-| Convert a Color to an RGB color record.
-}
toRgb : Color -> { r : Int, g : Int, b : Int }
toRgb =
    CP.toRgb


{-| Convert a Color to an RGBA color record.
-}
toRgba : Color -> { r : Int, g : Int, b : Int, a : Float }
toRgba =
    CP.toRgba


{-| Convert a Color to an HSL color record.
-}
toHsl : Color -> { h : Float, s : Float, l : Float }
toHsl =
    CP.toHsl


{-| Convert a Color to an HSLA color record.
-}
toHsla : Color -> { h : Float, s : Float, l : Float, a : Float }
toHsla =
    CP.toHsla


{-| Convert a Color to an [elm-color](https://package.elm-lang.org/packages/avh4/elm-color/latest/) [Color](https://package.elm-lang.org/packages/avh4/elm-color/latest/Color) value.
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

    color1 = fromRgb { r = 255, g = 0, b = 0 } -- Red
    color2 = fromRgb { r = 0, g = 255, b = 0 } -- Green

    distance color1 color2
    -- Returns: sqrt((0-255)² + (255-0)² + (0-0)²) = sqrt(65025 + 65025 + 0) = sqrt(130050) ≈ 360.6

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

```elm
fromString "#ff0000" -- Just red

fromString "rgb(255, 0, 0)" -- Just red

fromString "invalid" -- Nothing
```

-}
fromString : String -> Maybe Color
fromString =
    CP.fromString



-- ALPHA UTILITIES


{-| Set the alpha (transparency) value of a color.

    -- Semi-transparent red
    setAlpha 0.5 <|
        fromRgb { r = 255, g = 0, b = 0 }

-}
setAlpha : Float -> Color -> Color
setAlpha =
    CP.setAlpha


{-| Get the alpha value of a color. Returns 1.0 for opaque colors.

    getAlpha <|
        fromRgba { r = 255, g = 0, b = 0, a = 0.5 } -- 0.5

    getAlpha <|
        fromRgb { r = 255, g = 0, b = 0 } -- 1.0

-}
getAlpha : Color -> Float
getAlpha =
    CP.getAlpha



-- COLOR MANIPULATION


{-| Increase the lightness of a color.

    brighten 0.2 <|
        fromRgb { r = 100, g = 100, b = 100 } -- Lighter gray

-}
brighten : Float -> Color -> Color
brighten =
    CP.brighten


{-| Decrease the lightness of a color.

    darken 0.2 <|
        fromRgb { r = 100, g = 100, b = 100 } -- Darker gray

-}
darken : Float -> Color -> Color
darken =
    CP.darken


{-| Increase the saturation of a color.

    saturate 0.2 <|
        fromHsl {h = 0, s = 50, l = 50} -- More saturated red

-}
saturate : Float -> Color -> Color
saturate =
    CP.saturate


{-| Decrease the saturation of a color.

    desaturate 0.2 <|
        fromHsl {h = 0, s = 50, l = 50} -- Less saturated red

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


{-| Fully transparent white.
-}
transparent : Color
transparent =
    CP.transparent


{-| -}
black : Color
black =
    CP.black


{-| -}
white : Color
white =
    CP.white


{-| -}
red : Color
red =
    CP.red


{-| -}
green : Color
green =
    CP.green


{-| -}
blue : Color
blue =
    CP.blue
