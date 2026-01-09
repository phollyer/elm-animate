module Anim.Internal.Properties.FontColor exposing
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
    Color.hex


hsl : Float -> Float -> Float -> Color
hsl =
    Color.hsl


hsla : Float -> Float -> Float -> Float -> Color
hsla =
    Color.hsla


rgb : Int -> Int -> Int -> Color
rgb =
    Color.rgb


rgba : Int -> Int -> Int -> Float -> Color
rgba =
    Color.rgba



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
distance =
    Color.distance


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
