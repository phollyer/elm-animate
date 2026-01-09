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

import Anim.Internal.Properties.Color as Color exposing (Color)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec)



-- Build


hex : String -> Color
hex hexStr =
    Color.fromHex hexStr |> Maybe.withDefault Color.black


hsl : Float -> Float -> Float -> Color
hsl h s l =
    Color.fromHSL h s l


hsla : Float -> Float -> Float -> Float -> Color
hsla h s l a =
    Color.fromHSLA h s l a


rgb : Int -> Int -> Int -> Color
rgb r g b =
    Color.fromRGB r g b


rgba : Int -> Int -> Int -> Float -> Color
rgba r g b a =
    Color.fromRGBA r g b a



{- Transforms -}


toString : Color -> String
toString =
    Color.toCssString


hexToRgb : String -> Maybe { r : Int, g : Int, b : Int }
hexToRgb =
    Color.fromString >> Maybe.map Color.toRgb


hexToRgba : String -> Maybe { r : Int, g : Int, b : Int, a : Float }
hexToRgba =
    Color.fromString >> Maybe.map Color.toRgba


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


distance : Color -> Color -> Float
distance =
    Color.distance


speed : Float -> Float -> TimeSpec -> Float
speed =
    Color.speed


duration : Float -> TimeSpec -> Float
duration =
    Color.duration
