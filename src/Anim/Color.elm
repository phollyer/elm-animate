module Anim.Color exposing
    ( Color(..)
    , rgb, rgba
    , hsl, hsla
    , hex
    , elmColor
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

@docs hex


# Elm Color Integration

@docs elmColor

-}

import Color


{-| Color values in different formats.

  - Use `Hex` for hex color strings like "#ff0000"
  - Use `Rgb` or `Rgba` for RGB values
  - Use `Hsl` or `Hsla` for HSL values
  - Use `ElmColor` to integrate with the [avh4/elm-color](https://package.elm-lang.org/packages/avh4/elm-color/latest/) package,
    which provides named colors (`Color.red`, `Color.blue`, etc.) and color manipulation functions

-}
type Color
    = Hex String
    | Rgb { r : Int, g : Int, b : Int }
    | Rgba { r : Int, g : Int, b : Int, a : Float }
    | Hsl { h : Float, s : Float, l : Float }
    | Hsla { h : Float, s : Float, l : Float, a : Float }
    | ElmColor Color.Color



-- RGB COLORS


{-| Create an RGB color.

    rgb 255 0 0 -- Red

-}
rgb : Int -> Int -> Int -> Color
rgb r g b =
    Rgb { r = r, g = g, b = b }


{-| Create an RGBA color with alpha transparency.

    rgba 255 0 0 0.5 -- Semi-transparent red

-}
rgba : Int -> Int -> Int -> Float -> Color
rgba r g b a =
    Rgba { r = r, g = g, b = b, a = a }



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
hsl h s l =
    Hsl { h = h, s = s, l = l }


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
hsla h s l a =
    Hsla { h = h, s = s, l = l, a = a }



-- HEX COLORS


{-| Create a color from a hex string.

    hex "#ff0000" -- Red

    hex "#f00" -- Red (shorthand)

-}
hex : String -> Color
hex hexString =
    Hex hexString



-- ELM COLOR INTEGRATION


{-| Use a color from the [avh4/elm-color](https://package.elm-lang.org/packages/avh4/elm-color/latest/) package.

    import Color

    elmColor Color.red
    elmColor Color.blue

This allows you to use the color manipulation functions from elm-color.

-}
elmColor : Color.Color -> Color
elmColor color =
    ElmColor color
