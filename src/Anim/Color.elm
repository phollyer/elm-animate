module Anim.Color exposing
    ( Color
    , hex, rgb, rgba, hsl, hsla, elmColor
    , fromHex, toHex
    , fromRgb, fromRgba, toRgb, toRgba
    , fromHsl, fromHsla, toHsl, toHsla
    , fromElmColor, toElmColor
    , fromString
    , setAlpha, brighten, darken, saturate, desaturate
    , transparent, black, white, red, green, blue
    )

{-| Color manipulation and conversion utilities for the shared Color type.

Use these functions to create, transform, and analyze colors in various formats, then use them in animations.


# Color Type

@docs Color


# Color Constructors

Use these functions to create colors.

@docs hex, rgb, rgba, hsl, hsla, elmColor


# Color Transformations


## Hex Colors

@docs fromHex, toHex


## RGB Colors

@docs fromRgb, fromRgba, toRgb, toRgba


## HSL Colors

@docs fromHsl, fromHsla, toHsl, toHsla


## Elm Color

Use colors from the [avh4/elm-color](https://package.elm-lang.org/packages/avh4/elm-color/latest/) package.

@docs fromElmColor, toElmColor


## Parsing

@docs fromString


# Manipulation

@docs setAlpha, brighten, darken, saturate, desaturate


# Common Colors

@docs transparent, black, white, red, green, blue

-}

import Anim.Internal.Properties.Color as CP exposing (Color(..))
import Color


{-| Type alias for Color values used in animations.
-}
type alias Color =
    CP.Color



-- COLOR CONSTRUCTORS


{-| Create a hex color from a string.

    hex "#ff0000" -- Red

    hex "#f00" -- Red (shorthand)

    hex "ff0000" -- Red (without #)

Invalid hex strings will return `Nothing`.

-}
hex : String -> Maybe Color
hex =
    fromHex


{-| Create an RGB color from individual components.

    rgb 255 0 0 -- Red

-}
rgb : Int -> Int -> Int -> Color
rgb r g b =
    Rgb { r = r, g = g, b = b }


{-| Create an RGBA color from individual components.

    rgba 255 0 0 0.5 -- Semi-transparent red

-}
rgba : Int -> Int -> Int -> Float -> Color
rgba r g b a =
    Rgba { r = r, g = g, b = b, a = a }


{-| Create an HSL color from individual components.

  - `h` (hue): 0-360 degrees
  - `s` (saturation): 0-100 percent
  - `l` (lightness): 0-100 percent

```
hsl 0 100 50 -- Red
```

-}
hsl : Float -> Float -> Float -> Color
hsl h s l =
    Hsl { h = h, s = s, l = l }


{-| Create an HSLA color from individual components.

  - `h` (hue): 0-360 degrees
  - `s` (saturation): 0-100 percent
  - `l` (lightness): 0-100 percent
  - `a` (alpha): 0-1

```
hsla 0 100 50 0.5 -- Semi-transparent red
```

-}
hsla : Float -> Float -> Float -> Float -> Color
hsla h s l a =
    Hsla { h = h, s = s, l = l, a = a }


{-| Create a Color from an [elm-color](https://package.elm-lang.org/packages/avh4/elm-color/latest/) Color value.

    elmColor Color.red

-}
elmColor : Color.Color -> Color
elmColor =
    ElmColor



-- HEX COLORS


{-| Create a color from a hex string.

    fromHex "#ff0000" -- Just Red

    fromHex "#f00" -- Just Red (shorthand)

    fromHex "invalid" -- Nothing

Invalid hex strings will return `Nothing`.

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


{-| Create a Color from RGBA components.

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
