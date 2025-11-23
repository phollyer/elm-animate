module Anim.Internal.Properties.Color exposing
    ( Color(..)
    , HSL
    , HSLA
    , Hex
    , RGB
    , RGBA
    , distance
    , duration
    , encode
    , floatMod
    , hex
    , hexStringToInt
    , hexToRgb
    , hexToRgba
    , hslPercent
    , hslToRgb
    , hslaPercent
    , hslaToRgba
    , interpolate
    , rgb255
    , rgbToHsl
    , rgba255
    , rgbaToHsla
    , speed
    , toString
    )

import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec)
import Json.Encode as Encode


type Color
    = Hex Hex
    | Rgb RGB
    | Rgba RGBA
    | Hsl HSL
    | Hsla HSLA


type alias Hex =
    String


type alias HSL =
    { h : Float, s : Float, l : Float }


type alias HSLA =
    { h : Float, s : Float, l : Float, a : Float }


type alias RGB =
    { r : Int, g : Int, b : Int }


type alias RGBA =
    { r : Int, g : Int, b : Int, a : Float }


hex : String -> Color
hex str =
    Hex str


rgb255 : Int -> Int -> Int -> Color
rgb255 r g b =
    Rgb { r = r, g = g, b = b }


rgba255 : Int -> Int -> Int -> Float -> Color
rgba255 r g b a =
    Rgba { r = r, g = g, b = b, a = a }


hslPercent : Float -> Float -> Float -> Color
hslPercent h s l =
    Hsl { h = h, s = s, l = l }


hslaPercent : Float -> Float -> Float -> Float -> Color
hslaPercent h s l a =
    Hsla { h = h, s = s, l = l, a = a }



-- COLOR UTILITIES


interpolate : Color -> Color -> Float -> Color
interpolate start end t =
    case ( start, end ) of
        ( Hex startHex, Hex endHex ) ->
            -- Convert hex to RGB, interpolate, then convert back
            let
                startRgb =
                    hexToRgb startHex

                endRgb =
                    hexToRgb endHex

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
            -- Convert start color to match end color type and interpolate
            case end of
                Hex _ ->
                    let
                        startAsHex =
                            Hex (toHex start)
                    in
                    interpolate startAsHex end t

                Rgb _ ->
                    let
                        startAsRgb =
                            Rgb (toRgb start)
                    in
                    interpolate startAsRgb end t

                Rgba _ ->
                    let
                        startAsRgba =
                            Rgba (toRgba start)
                    in
                    interpolate startAsRgba end t

                Hsl _ ->
                    let
                        startAsHsl =
                            Hsl (toHsl start)
                    in
                    interpolate startAsHsl end t

                Hsla _ ->
                    let
                        startAsHsla =
                            Hsla (toHsla start)
                    in
                    interpolate startAsHsla end t



{- Encoder/Decoder Utilities -}


encode : Color -> Encode.Value
encode color =
    case color of
        Hex hex_ ->
            Encode.object
                [ ( "type", Encode.string "hex" )
                , ( "value", Encode.string hex_ )
                ]

        Rgb rgb ->
            Encode.object
                [ ( "type", Encode.string "rgb" )
                , ( "r", Encode.int rgb.r )
                , ( "g", Encode.int rgb.g )
                , ( "b", Encode.int rgb.b )
                ]

        Rgba rgba ->
            Encode.object
                [ ( "type", Encode.string "rgba" )
                , ( "r", Encode.int rgba.r )
                , ( "g", Encode.int rgba.g )
                , ( "b", Encode.int rgba.b )
                , ( "a", Encode.float rgba.a )
                ]

        Hsl hsl ->
            Encode.object
                [ ( "type", Encode.string "hsl" )
                , ( "h", Encode.float hsl.h )
                , ( "s", Encode.float hsl.s )
                , ( "l", Encode.float hsl.l )
                ]

        Hsla hsla ->
            Encode.object
                [ ( "type", Encode.string "hsla" )
                , ( "h", Encode.float hsla.h )
                , ( "s", Encode.float hsla.s )
                , ( "l", Encode.float hsla.l )
                , ( "a", Encode.float hsla.a )
                ]



{- Transforms -}


toString : Color -> String
toString color =
    case color of
        Hex hexString ->
            hexString

        Rgb rgb ->
            "rgb(" ++ String.fromInt rgb.r ++ ", " ++ String.fromInt rgb.g ++ ", " ++ String.fromInt rgb.b ++ ")"

        Rgba rgba ->
            "rgba(" ++ String.fromInt rgba.r ++ ", " ++ String.fromInt rgba.g ++ ", " ++ String.fromInt rgba.b ++ ", " ++ String.fromFloat rgba.a ++ ")"

        Hsl hsl ->
            "hsl(" ++ String.fromFloat hsl.h ++ ", " ++ String.fromFloat hsl.s ++ "%, " ++ String.fromFloat hsl.l ++ "%)"

        Hsla hsla ->
            "hsla(" ++ String.fromFloat hsla.h ++ ", " ++ String.fromFloat hsla.s ++ "%, " ++ String.fromFloat hsla.l ++ "%, " ++ String.fromFloat hsla.a ++ ")"


floatMod : Float -> Float -> Float
floatMod a b =
    a - (toFloat (floor (a / b)) * b)


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


hexToRgb : String -> RGB
hexToRgb hex_ =
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


hexToRgba : String -> RGBA
hexToRgba hex_ =
    let
        rgb =
            hexToRgb hex_
    in
    { r = rgb.r, g = rgb.g, b = rgb.b, a = 1.0 }


rgbToHsl : RGB -> HSL
rgbToHsl rgb =
    let
        r =
            toFloat rgb.r / 255

        g =
            toFloat rgb.g / 255

        b =
            toFloat rgb.b / 255

        maxVal =
            List.maximum [ r, g, b ] |> Maybe.withDefault 0

        minVal =
            List.minimum [ r, g, b ] |> Maybe.withDefault 0

        l =
            (maxVal + minVal) / 2

        delta =
            maxVal - minVal

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

        hNormalized =
            if h < 0 then
                h + 360

            else if h >= 360 then
                h - 360

            else
                h
    in
    { h = hNormalized, s = s * 100, l = l * 100 }


hslToRgb : HSL -> RGB
hslToRgb hsl =
    let
        s =
            hsl.s / 100

        l =
            hsl.l / 100

        c =
            (1 - abs (2 * l - 1)) * s

        x =
            c * (1 - abs (floatMod (hsl.h / 60) 2 - 1))

        m =
            l - c / 2

        ( r1, g1, b1 ) =
            if hsl.h < 60 then
                ( c, x, 0 )

            else if hsl.h < 120 then
                ( x, c, 0 )

            else if hsl.h < 180 then
                ( 0, c, x )

            else if hsl.h < 240 then
                ( 0, x, c )

            else if hsl.h < 300 then
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


rgbaToHsla : RGBA -> HSLA
rgbaToHsla rgba =
    let
        rgb =
            { r = rgba.r, g = rgba.g, b = rgba.b }

        hsl =
            rgbToHsl rgb
    in
    { h = hsl.h, s = hsl.s, l = hsl.l, a = rgba.a }


hslaToRgba : HSLA -> RGBA
hslaToRgba hsla =
    let
        rgb =
            hslToRgb { h = hsla.h, s = hsla.s, l = hsla.l }
    in
    { r = rgb.r, g = rgb.g, b = rgb.b, a = hsla.a }


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


{-| Convert any Color to RGB for distance calculation.
-}
toRgb : Color -> RGB
toRgb color =
    case color of
        Hex hex_ ->
            hexToRgb hex_

        Rgb rgb ->
            rgb

        Rgba rgba ->
            { r = rgba.r, g = rgba.g, b = rgba.b }

        Hsl hsl ->
            hslToRgb hsl

        Hsla hsla ->
            hslToRgb { h = hsla.h, s = hsla.s, l = hsla.l }


{-| Convert any Color to Hex.
-}
toHex : Color -> String
toHex color =
    let
        rgb =
            toRgb color

        intToHex value =
            -- For now, use a simple mapping for hex conversion
            case value of
                0 ->
                    "00"

                1 ->
                    "01"

                2 ->
                    "02"

                3 ->
                    "03"

                4 ->
                    "04"

                5 ->
                    "05"

                6 ->
                    "06"

                7 ->
                    "07"

                8 ->
                    "08"

                9 ->
                    "09"

                10 ->
                    "0a"

                11 ->
                    "0b"

                12 ->
                    "0c"

                13 ->
                    "0d"

                14 ->
                    "0e"

                15 ->
                    "0f"

                _ ->
                    let
                        high =
                            value // 16

                        low =
                            modBy 16 value

                        highHex =
                            case high of
                                10 ->
                                    "a"

                                11 ->
                                    "b"

                                12 ->
                                    "c"

                                13 ->
                                    "d"

                                14 ->
                                    "e"

                                15 ->
                                    "f"

                                _ ->
                                    String.fromInt high

                        lowHex =
                            case low of
                                10 ->
                                    "a"

                                11 ->
                                    "b"

                                12 ->
                                    "c"

                                13 ->
                                    "d"

                                14 ->
                                    "e"

                                15 ->
                                    "f"

                                _ ->
                                    String.fromInt low
                    in
                    highHex ++ lowHex
    in
    "#" ++ intToHex rgb.r ++ intToHex rgb.g ++ intToHex rgb.b


{-| Convert any Color to HSL.
-}
toHsl : Color -> HSL
toHsl color =
    case color of
        Hsl hsl ->
            hsl

        Hsla hsla ->
            { h = hsla.h, s = hsla.s, l = hsla.l }

        _ ->
            toRgb color |> rgbToHsl


{-| Convert any Color to RGBA.
-}
toRgba : Color -> RGBA
toRgba color =
    case color of
        Rgba rgba ->
            rgba

        Hsla hsla ->
            hslaToRgba hsla

        _ ->
            let
                rgb =
                    toRgb color
            in
            { r = rgb.r, g = rgb.g, b = rgb.b, a = 1.0 }


{-| Convert any Color to HSLA.
-}
toHsla : Color -> HSLA
toHsla color =
    case color of
        Hsla hsla ->
            hsla

        Rgba rgba ->
            rgbaToHsla rgba

        _ ->
            let
                hsl =
                    toHsl color
            in
            { h = hsl.h, s = hsl.s, l = hsl.l, a = 1.0 }
