module Anim.Internal.Properties.Color exposing
    ( Color(..)
    , applyAlphaFromStart
    , distance
    , duration
    , elmColorToHex
    , encode
    , fromElmColor
    , fromHSL
    , fromHSLA
    , fromHex
    , fromRGB
    , fromRGBA
    , fromRgbString
    , hasExplicitAlpha
    , hexToElmColor
    , hexToHsl
    , hexToHsla
    , hexToRgb
    , hexToRgba
    , interpolate
    , speed
    , toCssString
    , toElmColor
    , toHex
    , toHsl
    , toHsla
    , toRgb
    , toRgba
    )

{- Color Utility Module

   Color creation and manipulation functions
-}

import Anim.Internal.Timing.TimeSpec as TimeSpec exposing (TimeSpec)
import Color
import Json.Encode as Encode


type Color
    = Hex String
    | Rgb { r : Int, g : Int, b : Int }
    | Rgba { r : Int, g : Int, b : Int, a : Float }
    | Hsl { h : Float, s : Float, l : Float }
    | Hsla { h : Float, s : Float, l : Float, a : Float }
    | ElmColor Color.Color


type alias HSL a =
    { a | h : Float, s : Float, l : Float }


type alias HSLA a =
    { a | h : Float, s : Float, l : Float, a : Float }


type alias RGB a =
    { a | r : Int, g : Int, b : Int }


type alias RGBA a =
    { a | r : Int, g : Int, b : Int, a : Float }


toCssString : Color -> String
toCssString color =
    case color of
        Hex hex ->
            hex

        Rgb rgb_ ->
            "rgb(" ++ String.fromInt rgb_.r ++ ", " ++ String.fromInt rgb_.g ++ ", " ++ String.fromInt rgb_.b ++ ")"

        Rgba rgba_ ->
            "rgba(" ++ String.fromInt rgba_.r ++ ", " ++ String.fromInt rgba_.g ++ ", " ++ String.fromInt rgba_.b ++ ", " ++ String.fromFloat rgba_.a ++ ")"

        Hsl hsl_ ->
            "hsl(" ++ String.fromFloat hsl_.h ++ ", " ++ String.fromFloat hsl_.s ++ "%, " ++ String.fromFloat hsl_.l ++ "%)"

        Hsla hsla_ ->
            "hsla(" ++ String.fromFloat hsla_.h ++ ", " ++ String.fromFloat hsla_.s ++ "%, " ++ String.fromFloat hsla_.l ++ "%, " ++ String.fromFloat hsla_.a ++ ")"

        ElmColor elmColor_ ->
            Color.toCssString elmColor_



{- Elm Color Integration -}


fromElmColor : Color.Color -> Color
fromElmColor =
    ElmColor


toElmColor : Color -> Color.Color
toElmColor color =
    case color of
        ElmColor elmColor_ ->
            elmColor_

        _ ->
            let
                rgba_ =
                    toRgba color
            in
            Color.rgba
                (toFloat rgba_.r / 255)
                (toFloat rgba_.g / 255)
                (toFloat rgba_.b / 255)
                rgba_.a


elmColorToHex : Color.Color -> String
elmColorToHex =
    ElmColor
        >> toRgba
        >> rgbaToHex



{- Hex Utilities -}


fromHex : String -> Color
fromHex =
    Hex


toHex : Color -> String
toHex color =
    case color of
        Hex hexStr ->
            hexStr

        Rgb rgb_ ->
            rgbToHex rgb_

        Rgba rgba_ ->
            rgbaToHex rgba_

        Hsl hsl_ ->
            hslToHex hsl_

        Hsla hsla_ ->
            hslaToHex hsla_

        ElmColor elmColor_ ->
            elmColorToHex elmColor_


hexToElmColor : String -> Color.Color
hexToElmColor hexStr =
    let
        rgba_ =
            hexToRgba hexStr
    in
    Color.rgba
        (toFloat rgba_.r / 255)
        (toFloat rgba_.g / 255)
        (toFloat rgba_.b / 255)
        rgba_.a


hexToHsl : String -> { h : Float, s : Float, l : Float }
hexToHsl =
    hexToRgb >> rgbToHsl


hexToHsla : String -> { h : Float, s : Float, l : Float, a : Float }
hexToHsla =
    hexToRgba >> rgbaToHsla


hexToRgb : String -> { r : Int, g : Int, b : Int }
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
            String.slice 0 2 cleanHex |> hexToInt |> Maybe.withDefault 0

        g =
            String.slice 2 4 cleanHex |> hexToInt |> Maybe.withDefault 0

        b =
            String.slice 4 6 cleanHex |> hexToInt |> Maybe.withDefault 0
    in
    { r = r, g = g, b = b }


hexToRgba : String -> { r : Int, g : Int, b : Int, a : Float }
hexToRgba hex_ =
    let
        rgb_ =
            hexToRgb hex_

        alpha_ =
            hexAlpha hex_
    in
    { r = rgb_.r, g = rgb_.g, b = rgb_.b, a = alpha_ }


hexAlpha : String -> Float
hexAlpha hex_ =
    let
        cleanHex =
            String.dropLeft
                (if String.startsWith "#" hex_ then
                    1

                 else
                    0
                )
                hex_

        alphaStr =
            String.slice 6 8 cleanHex

        alphaInt =
            hexToInt alphaStr |> Maybe.withDefault 255
    in
    toFloat alphaInt / 255



{- HSL Utilities -}


fromHSL : Float -> Float -> Float -> Color
fromHSL h s l =
    Hsl { h = h, s = s, l = l }


toHsl : Color -> { h : Float, s : Float, l : Float }
toHsl color =
    case color of
        Hsl hsl_ ->
            hsl_

        Hsla hslaValue ->
            { h = hslaValue.h, s = hslaValue.s, l = hslaValue.l }

        _ ->
            toRgb color |> rgbToHsl


hslToHex : HSL a -> String
hslToHex =
    hslToRgb >> rgbToHex


hslToRgb : HSL a -> { r : Int, g : Int, b : Int }
hslToRgb hslValue =
    let
        s =
            hslValue.s / 100

        l =
            hslValue.l / 100

        c =
            (1 - abs (2 * l - 1)) * s

        x =
            c * (1 - abs (floatMod (hslValue.h / 60) 2 - 1))

        m =
            l - c / 2

        ( r1, g1, b1 ) =
            if hslValue.h < 60 then
                ( c, x, 0 )

            else if hslValue.h < 120 then
                ( x, c, 0 )

            else if hslValue.h < 180 then
                ( 0, c, x )

            else if hslValue.h < 240 then
                ( 0, x, c )

            else if hslValue.h < 300 then
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



{- HSLA Utilities -}


fromHSLA : Float -> Float -> Float -> Float -> Color
fromHSLA h s l a =
    Hsla { h = h, s = s, l = l, a = a }


toHsla : Color -> { h : Float, s : Float, l : Float, a : Float }
toHsla color =
    case color of
        Hsla hsla_ ->
            hsla_

        Rgba rgba_ ->
            rgbaToHsla rgba_

        _ ->
            let
                hslValue =
                    toHsl color
            in
            { h = hslValue.h, s = hslValue.s, l = hslValue.l, a = 1.0 }


hslaToHex : HSLA a -> String
hslaToHex =
    hslaToRgba >> rgbaToHex


hslaToRgba : HSLA a -> { r : Int, g : Int, b : Int, a : Float }
hslaToRgba hslaValue =
    let
        rgb_ =
            hslToRgb { h = hslaValue.h, s = hslaValue.s, l = hslaValue.l }
    in
    { r = rgb_.r, g = rgb_.g, b = rgb_.b, a = hslaValue.a }



{- RGB Utilities -}


fromRGB : Int -> Int -> Int -> Color
fromRGB r g b =
    Rgb { r = r, g = g, b = b }


fromRgbString : String -> Maybe Color
fromRgbString str =
    -- Simple parser for "rgb(r, g, b)" format
    let
        prefix =
            "rgb("

        suffix =
            ")"

        content =
            String.dropLeft (String.length prefix) (String.dropRight (String.length suffix) str)

        parts =
            String.split "," content |> List.map String.trim
    in
    case parts of
        [ rStr, gStr, bStr ] ->
            case ( String.toInt rStr, String.toInt gStr, String.toInt bStr ) of
                ( Just r, Just g, Just b ) ->
                    Just <|
                        Rgb { r = r, g = g, b = b }

                _ ->
                    Nothing

        _ ->
            Nothing


toRgb : Color -> { r : Int, g : Int, b : Int }
toRgb color =
    case color of
        Hex hex_ ->
            hexToRgb hex_

        Rgb rgb_ ->
            rgb_

        Rgba rgba_ ->
            { r = rgba_.r, g = rgba_.g, b = rgba_.b }

        Hsl hsl_ ->
            hslToRgb hsl_

        Hsla hsla_ ->
            hslToRgb { h = hsla_.h, s = hsla_.s, l = hsla_.l }

        ElmColor elmColor_ ->
            let
                rgba_ =
                    Color.toRgba elmColor_
            in
            { r = round (rgba_.red * 255), g = round (rgba_.green * 255), b = round (rgba_.blue * 255) }


rgbToHex : { a | r : Int, g : Int, b : Int } -> String
rgbToHex { r, g, b } =
    "#" ++ toHexComponent r ++ toHexComponent g ++ toHexComponent b


rgbToHsl : RGB a -> { h : Float, s : Float, l : Float }
rgbToHsl rgb_ =
    let
        r =
            toFloat rgb_.r / 255

        g =
            toFloat rgb_.g / 255

        b =
            toFloat rgb_.b / 255

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



{- RGBA Utilities -}


fromRGBA : Int -> Int -> Int -> Float -> Color
fromRGBA r g b a =
    Rgba { r = r, g = g, b = b, a = a }


toRgba : Color -> { r : Int, g : Int, b : Int, a : Float }
toRgba color =
    case color of
        Rgba rgba_ ->
            rgba_

        Hsla hsla_ ->
            hslaToRgba hsla_

        ElmColor elmColor_ ->
            let
                rgba_ =
                    Color.toRgba elmColor_
            in
            { r = round (rgba_.red * 255), g = round (rgba_.green * 255), b = round (rgba_.blue * 255), a = rgba_.alpha }

        _ ->
            let
                rgb_ =
                    toRgb color
            in
            { r = rgb_.r, g = rgb_.g, b = rgb_.b, a = 1.0 }


rgbaToHex : { r : Int, g : Int, b : Int, a : Float } -> String
rgbaToHex { r, g, b, a } =
    "#" ++ toHexComponent r ++ toHexComponent g ++ toHexComponent b ++ toHexComponent (round (a * 255))


rgbaToHsla : RGBA a -> { h : Float, s : Float, l : Float, a : Float }
rgbaToHsla rgba_ =
    let
        rgb_ =
            { r = rgba_.r, g = rgba_.g, b = rgba_.b }

        hsla_ =
            rgbToHsl rgb_
    in
    { h = hsla_.h, s = hsla_.s, l = hsla_.l, a = rgba_.a }



{- Query Utilities -}


hasExplicitAlpha : Color -> Bool
hasExplicitAlpha color =
    case color of
        Rgba _ ->
            True

        Hsla _ ->
            True

        _ ->
            False


applyAlphaFromStart : Color -> Color -> Color
applyAlphaFromStart newColor startColor =
    let
        -- Extract alpha from start color
        startAlpha =
            case startColor of
                Rgba rgba_ ->
                    rgba_.a

                Hsla hsla_ ->
                    hsla_.a

                _ ->
                    -- Should never happen if caller checks hasExplicitAlpha first
                    1.0
    in
    case newColor of
        Rgb rgb_ ->
            Rgba { r = rgb_.r, g = rgb_.g, b = rgb_.b, a = startAlpha }

        Hex hex_ ->
            let
                rgb_ =
                    hexToRgb hex_
            in
            Rgba { r = rgb_.r, g = rgb_.g, b = rgb_.b, a = startAlpha }

        Hsl hsl_ ->
            Hsla { h = hsl_.h, s = hsl_.s, l = hsl_.l, a = startAlpha }

        -- Should never happen if caller checks hasExplicitAlpha first
        _ ->
            newColor



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
            -- Normalize both colors to alpha-enabled formats
            -- Preserve start alpha when end color has no explicit alpha (RGB/Hex/HSL)
            -- Use end alpha when explicitly specified (RGBA/HSLA)
            let
                startAlpha =
                    case start of
                        Rgba rgba_ ->
                            rgba_.a

                        Hsla hsla_ ->
                            hsla_.a

                        ElmColor elmColor_ ->
                            let
                                rgba_ =
                                    Color.toRgba elmColor_
                            in
                            rgba_.alpha

                        _ ->
                            1.0
            in
            case ( start, end ) of
                -- If end is HSL (no alpha), normalize both to HSLA preserving start alpha
                ( _, Hsl _ ) ->
                    let
                        startHsla =
                            toHsla start

                        endHsla =
                            toHsla end
                    in
                    interpolate (Hsla startHsla) (Hsla { endHsla | a = startAlpha }) t

                -- If end is HSLA (explicit alpha), use it
                ( _, Hsla _ ) ->
                    interpolate (Hsla (toHsla start)) end t

                -- If end is RGB/Hex (no alpha), normalize to RGBA preserving start alpha
                ( _, Rgb _ ) ->
                    let
                        startRgba =
                            toRgba start

                        endRgba =
                            toRgba end
                    in
                    interpolate (Rgba startRgba) (Rgba { endRgba | a = startAlpha }) t

                ( _, Hex _ ) ->
                    let
                        startRgba =
                            toRgba start

                        endRgba =
                            toRgba end
                    in
                    interpolate (Rgba startRgba) (Rgba { endRgba | a = startAlpha }) t

                -- If end is RGBA (explicit alpha), use it
                ( _, Rgba _ ) ->
                    interpolate (Rgba (toRgba start)) end t

                -- If end is ElmColor, convert to RGBA and preserve alpha
                ( _, ElmColor _ ) ->
                    let
                        startRgba =
                            toRgba start

                        endRgba =
                            toRgba end
                    in
                    interpolate (Rgba startRgba) (Rgba endRgba) t



{- Encoder/Decoder Utilities -}


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
            let
                rgba_ =
                    Color.toRgba elmColor_
            in
            Encode.object
                [ ( "type", Encode.string "rgba" )
                , ( "r", Encode.int (round (rgba_.red * 255)) )
                , ( "g", Encode.int (round (rgba_.green * 255)) )
                , ( "b", Encode.int (round (rgba_.blue * 255)) )
                , ( "a", Encode.float rgba_.alpha )
                ]



{- Transforms -}


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


toHexComponent : Int -> String
toHexComponent value =
    let
        clampedValue =
            clamp 0 255 value

        toHexDigit digit =
            if digit < 10 then
                String.fromInt digit

            else
                case digit of
                    10 ->
                        "A"

                    11 ->
                        "B"

                    12 ->
                        "C"

                    13 ->
                        "D"

                    14 ->
                        "E"

                    15 ->
                        "F"

                    _ ->
                        "F"

        -- fallback, should never happen
        high =
            clampedValue // 16

        low =
            clampedValue |> modBy 16
    in
    toHexDigit high ++ toHexDigit low


hexToInt : String -> Maybe Int
hexToInt str =
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


floatMod : Float -> Float -> Float
floatMod a b =
    a - (toFloat (floor (a / b)) * b)
