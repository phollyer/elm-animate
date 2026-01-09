module Anim.Internal.Properties.BackgroundColor exposing
    ( distance
    , duration
    , hex
    , hexToRgb
    , hexToRgba
    , hsl
    , hsla
    , rgb
    , rgba
    , speed
    , toHsl
    , toHsla
    , toRgb
    , toRgba
    , toString
    )

import Anim.Color as Color exposing (Color)
import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec)



-- Build


hex : String -> Color
hex =
    Color.fromHex


hsl : Float -> Float -> Float -> Color
hsl h s l =
    Color.fromHsl h s l


hsla : Float -> Float -> Float -> Float -> Color
hsla h s l a =
    Color.fromHsla h s l a


rgb : Int -> Int -> Int -> Color
rgb r g b =
    Color.fromRgb r g b


rgba : Int -> Int -> Int -> Float -> Color
rgba r g b a =
    Color.fromRgba r g b a



{- Transforms -}


toString : Color -> String
toString =
    Color.toCssString


hexToRgb : String -> { r : Int, g : Int, b : Int }
hexToRgb =
    Color.hexStringToRgb


hexToRgba : String -> { r : Int, g : Int, b : Int, a : Float }
hexToRgba =
    Color.hexStringToRgba


toRgb : Color -> { r : Int, g : Int, b : Int }
toRgb =
    Color.toRgb


toRgba : Color -> { r : Int, g : Int, b : Int, a : Float }
toRgba =
    Color.toRgba


toHsl : Color -> { h : Float, s : Float, l : Float }
toHsl =
    Color.toHsl


toHsla : Color -> { h : Float, s : Float, l : Float, a : Float }
toHsla =
    Color.toHsla


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


speed : Float -> Float -> TimeSpec -> Float
speed distance_ duration_ timeSpec =
    case timeSpec of
        TimeSpec.Duration ms ->
            if ms <= 0 then
                distance_ * duration_ * 1000

            else
                distance_ / (Basics.toFloat ms / 1000)

        TimeSpec.Speed unitsPerSecond ->
            unitsPerSecond


duration : Float -> TimeSpec -> Float
duration distance_ timeSpec =
    case timeSpec of
        TimeSpec.Duration ms ->
            Basics.toFloat ms

        TimeSpec.Speed unitsPerSecond ->
            distance_ / unitsPerSecond * 1000
