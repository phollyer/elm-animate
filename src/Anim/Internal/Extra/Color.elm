module Anim.Internal.Extra.Color exposing
    ( Color(..)
    , applyAlphaFromStart
    , black
    , blue
    , brighten
    , darken
    , desaturate
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
    , fromString
    , getAlpha
    , green
    , hasExplicitAlpha
    , hexToElmColor
    , hexToHsl
    , hexToHsla
    , hexToRgb
    , hexToRgba
    , interpolate
    , isDark
    , isEqual
    , isLight
    , red
    , saturate
    , setAlpha
    , speed
    , toCssString
    , toElmColor
    , toHex
    , toHsl
    , toHsla
    , toRgb
    , toRgba
    , transparent
    , white
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


toCssString : Color -> String
toCssString color =
    let
        stringify : String -> List String -> String
        stringify constructor components =
            constructor ++ "(" ++ String.join ", " components ++ ")"
    in
    case color of
        Hex hex ->
            hex

        Rgb { r, g, b } ->
            stringify "rgb" <|
                [ String.fromInt r
                , String.fromInt g
                , String.fromInt b
                ]

        Rgba { r, g, b, a } ->
            stringify "rgba" <|
                [ String.fromInt r
                , String.fromInt g
                , String.fromInt b
                , String.fromFloat a
                ]

        Hsl { h, s, l } ->
            stringify "hsl" <|
                [ String.fromFloat h
                , String.fromFloat s ++ "%"
                , String.fromFloat l ++ "%"
                ]

        Hsla { h, s, l, a } ->
            stringify "hsla" <|
                [ String.fromFloat h
                , String.fromFloat s ++ "%"
                , String.fromFloat l ++ "%"
                , String.fromFloat a
                ]

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
            -- Elm Color expects RGBA values to be in the range 0-1, so we need to convert from 0-255
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


fromHex : String -> Maybe Color
fromHex str =
    let
        cleanHex_ =
            cleanHex str

        isValidLength =
            case String.length cleanHex_ of
                3 ->
                    True

                6 ->
                    True

                8 ->
                    True

                _ ->
                    False

        isValidChars =
            String.all Char.isHexDigit cleanHex_
    in
    if isValidLength && isValidChars then
        Just (Hex ("#" ++ cleanHex_))

    else
        Nothing


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
        cleanHex_ =
            cleanHex hex_

        r =
            hexByteAt 0 0 cleanHex_

        g =
            hexByteAt 2 0 cleanHex_

        b =
            hexByteAt 4 0 cleanHex_
    in
    { r = r, g = g, b = b }


hexToRgba : String -> { r : Int, g : Int, b : Int, a : Float }
hexToRgba hex_ =
    let
        cleanHex_ =
            cleanHex hex_

        rgb_ =
            hexToRgb cleanHex_

        alpha_ =
            hexByteAt 6 255 cleanHex_
                |> toFloat
                |> (\a -> a / 255)
    in
    { r = rgb_.r, g = rgb_.g, b = rgb_.b, a = alpha_ }


cleanHex : String -> String
cleanHex hex_ =
    if String.startsWith "#" hex_ then
        String.dropLeft 1 hex_

    else
        hex_


hexByteAt : Int -> Int -> String -> Int
hexByteAt start default hex_ =
    hex_
        |> String.slice start (start + 2)
        |> hexToInt
        |> Maybe.withDefault default



{- HSL Utilities -}


fromHSL : { h : Float, s : Float, l : Float } -> Color
fromHSL { h, s, l } =
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


type alias HSL a =
    { a | h : Float, s : Float, l : Float }


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


fromHSLA : { h : Float, s : Float, l : Float, a : Float } -> Color
fromHSLA { h, s, l, a } =
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


type alias HSLA a =
    { a | h : Float, s : Float, l : Float, a : Float }


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


type alias RGB a =
    { a | r : Int, g : Int, b : Int }


fromRGB : { r : Int, g : Int, b : Int } -> Color
fromRGB { r, g, b } =
    Rgb { r = r, g = g, b = b }


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


type alias RGBA a =
    { a | r : Int, g : Int, b : Int, a : Float }


fromRGBA : RGBA a -> Color
fromRGBA { r, g, b, a } =
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


interpolate : Float -> Color -> Color -> Color
interpolate t start end =
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
                    interpolate t (Hsla startHsla) (Hsla { endHsla | a = startAlpha })

                -- If end is HSLA (explicit alpha), use it
                ( _, Hsla _ ) ->
                    interpolate t (Hsla (toHsla start)) end

                -- If end is RGB/Hex (no alpha), normalize to RGBA preserving start alpha
                ( _, Rgb _ ) ->
                    let
                        startRgba =
                            toRgba start

                        endRgba =
                            toRgba end
                    in
                    interpolate t (Rgba startRgba) (Rgba { endRgba | a = startAlpha })

                ( _, Hex _ ) ->
                    let
                        startRgba =
                            toRgba start

                        endRgba =
                            toRgba end
                    in
                    interpolate t (Rgba startRgba) (Rgba { endRgba | a = startAlpha })

                -- If end is RGBA (explicit alpha), use it
                ( _, Rgba _ ) ->
                    interpolate t (Rgba (toRgba start)) (Rgba (toRgba end))

                -- If end is ElmColor, convert to RGBA and preserve alpha
                ( _, ElmColor _ ) ->
                    let
                        startRgba =
                            toRgba start

                        endRgba =
                            toRgba end
                    in
                    interpolate t (Rgba startRgba) (Rgba endRgba)



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
speed =
    TimeSpec.speed


duration : Float -> TimeSpec -> Float
duration =
    TimeSpec.duration


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



{- UTILITY FUNCTIONS -}


setAlpha : Float -> Color -> Color
setAlpha alpha color =
    case color of
        Rgba rgba_ ->
            Rgba { rgba_ | a = clamp 0 1 alpha }

        Hsla hsla_ ->
            Hsla { hsla_ | a = clamp 0 1 alpha }

        _ ->
            let
                rgba_ =
                    toRgba color
            in
            Rgba { rgba_ | a = clamp 0 1 alpha }


getAlpha : Color -> Float
getAlpha color =
    case color of
        Rgba rgba_ ->
            rgba_.a

        Hsla hsla_ ->
            hsla_.a

        ElmColor elmColor_ ->
            (Color.toRgba elmColor_).alpha

        _ ->
            1.0


brighten : Float -> Color -> Color
brighten amount color =
    let
        hsl_ =
            toHsl color

        newLightness =
            clamp 0 100 (hsl_.l + amount * 100)
    in
    case color of
        Hsla hsla_ ->
            Hsla { hsla_ | l = newLightness }

        _ ->
            if hasExplicitAlpha color then
                let
                    hsla_ =
                        toHsla color
                in
                Hsla { hsla_ | l = newLightness }

            else
                Hsl { hsl_ | l = newLightness }


darken : Float -> Color -> Color
darken amount color =
    brighten -amount color


saturate : Float -> Color -> Color
saturate amount color =
    let
        hsl_ =
            toHsl color

        newSaturation =
            clamp 0 100 (hsl_.s + amount * 100)
    in
    case color of
        Hsla hsla_ ->
            Hsla { hsla_ | s = newSaturation }

        _ ->
            if hasExplicitAlpha color then
                let
                    hsla_ =
                        toHsla color
                in
                Hsla { hsla_ | s = newSaturation }

            else
                Hsl { hsl_ | s = newSaturation }


desaturate : Float -> Color -> Color
desaturate amount color =
    saturate -amount color


isLight : Color -> Bool
isLight color =
    let
        rgb_ =
            toRgb color

        -- Calculate relative luminance using the formula for sRGB
        luminance =
            let
                toLinear component =
                    let
                        sRGB =
                            toFloat component / 255
                    in
                    if sRGB <= 0.03928 then
                        sRGB / 12.92

                    else
                        ((sRGB + 0.055) / 1.055) ^ 2.4

                r =
                    toLinear rgb_.r

                g =
                    toLinear rgb_.g

                b =
                    toLinear rgb_.b
            in
            0.2126 * r + 0.7152 * g + 0.0722 * b
    in
    luminance > 0.5


isDark : Color -> Bool
isDark color =
    not (isLight color)


isEqual : Color -> Color -> Bool
isEqual color1 color2 =
    let
        rgba1 =
            toRgba color1

        rgba2 =
            toRgba color2
    in
    (rgba1.r == rgba2.r)
        && (rgba1.g == rgba2.g)
        && (rgba1.b == rgba2.b)
        && (rgba1.a == rgba2.a)


fromString : String -> Maybe Color
fromString str =
    let
        trimmed =
            String.trim str
    in
    if String.startsWith "#" trimmed then
        fromHex trimmed

    else if String.startsWith "rgb(" trimmed then
        parseRgbString trimmed

    else if String.startsWith "rgba(" trimmed then
        parseRgbaString trimmed

    else if String.startsWith "hsl(" trimmed then
        parseHslString trimmed

    else if String.startsWith "hsla(" trimmed then
        parseHslaString trimmed

    else
        -- Try parsing as hex without # prefix
        fromHex trimmed


parseRgbString : String -> Maybe Color
parseRgbString str =
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


parseRgbaString : String -> Maybe Color
parseRgbaString str =
    -- Parse "rgba(r, g, b, a)" format
    let
        content =
            String.dropLeft 5 (String.dropRight 1 str)

        -- Remove "rgba(" and ")"
        parts =
            String.split "," content |> List.map String.trim
    in
    case parts of
        [ rStr, gStr, bStr, aStr ] ->
            let
                r =
                    String.toInt rStr

                g =
                    String.toInt gStr

                b =
                    String.toInt bStr

                a =
                    String.toFloat aStr
            in
            case ( ( r, g, b ), a ) of
                ( ( Just rVal, Just gVal, Just bVal ), Just aVal ) ->
                    Just (fromRGBA { r = rVal, g = gVal, b = bVal, a = aVal })

                _ ->
                    Nothing

        _ ->
            Nothing


parseHslString : String -> Maybe Color
parseHslString str =
    -- Parse "hsl(h, s%, l%)" format
    let
        content =
            String.dropLeft 4 (String.dropRight 1 str)

        -- Remove "hsl(" and ")"
        parts =
            String.split "," content |> List.map (String.trim >> String.replace "%" "")
    in
    case parts of
        [ hStr, sStr, lStr ] ->
            let
                h =
                    String.toFloat hStr

                s =
                    String.toFloat sStr

                l =
                    String.toFloat lStr
            in
            case ( h, s, l ) of
                ( Just hVal, Just sVal, Just lVal ) ->
                    Just <|
                        fromHSL { h = hVal, s = sVal, l = lVal }

                _ ->
                    Nothing

        _ ->
            Nothing


parseHslaString : String -> Maybe Color
parseHslaString str =
    -- Parse "hsla(h, s%, l%, a)" format
    let
        content =
            String.dropLeft 5 (String.dropRight 1 str)

        -- Remove "hsla(" and ")"
        parts =
            String.split "," content |> List.map String.trim

        cleanedParts =
            case parts of
                [ hStr, sStr, lStr, aStr ] ->
                    [ hStr, String.replace "%" "" sStr, String.replace "%" "" lStr, aStr ]

                _ ->
                    []
    in
    case cleanedParts of
        [ hStr, sStr, lStr, aStr ] ->
            let
                h =
                    String.toFloat hStr

                s =
                    String.toFloat sStr

                l =
                    String.toFloat lStr

                a =
                    String.toFloat aStr
            in
            case ( ( h, s, l ), a ) of
                ( ( Just hVal, Just sVal, Just lVal ), Just aVal ) ->
                    Just <|
                        fromHSLA { h = hVal, s = sVal, l = lVal, a = aVal }

                _ ->
                    Nothing

        _ ->
            Nothing


{-| Common predefined colors
-}
transparent : Color
transparent =
    Rgba { r = 255, g = 255, b = 255, a = 0 }


black : Color
black =
    Rgb { r = 0, g = 0, b = 0 }


white : Color
white =
    Rgb { r = 255, g = 255, b = 255 }


red : Color
red =
    Rgb { r = 255, g = 0, b = 0 }


green : Color
green =
    Rgb { r = 0, g = 255, b = 0 }


blue : Color
blue =
    Rgb { r = 0, g = 0, b = 255 }


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
