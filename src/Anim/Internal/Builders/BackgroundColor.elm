module Anim.Internal.Builders.BackgroundColor exposing
    ( ColorBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , speed
    , to
    )

import Anim.Easing exposing (Easing)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Properties.BackgroundColor as BackgroundColor exposing (Color(..))
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))


type ColorBuilder
    = ColorBuilder (Builder.AnimationConfig Color) AnimBuilder


for : String -> AnimBuilder -> ColorBuilder
for elementId builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.BackgroundColorConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.createFor extractExisting defaultConfig elementId builder
    in
    ColorBuilder config <|
        Builder.for elementId builder


build : ColorBuilder -> AnimBuilder
build (ColorBuilder config builder) =
    PropertyBuilder.upsert (Builder.BackgroundColorConfig config) builder


type alias ColorConfig =
    Builder.AnimationConfig Color


defaultConfig : ColorConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        BackgroundColor.rgb255 0 0 0


from : Color -> ColorBuilder -> ColorBuilder
from color (ColorBuilder config builder) =
    let
        -- Preserve alpha from previous animation's end value if:
        -- 1. New color has no explicit alpha (RGB/Hex/HSL), AND
        -- 2. Previous animation's end has explicit alpha (RGBA/HSLA)
        colorWithPreservedAlpha =
            case ( hasExplicitAlpha color, hasExplicitAlpha config.end ) of
                ( False, True ) ->
                    -- New color has no alpha, previous end has alpha -> preserve it
                    applyAlphaFromStart color config.end

                _ ->
                    -- Otherwise, use the color as-is
                    color
    in
    ColorBuilder { config | start = Just colorWithPreservedAlpha } builder


to : Color -> ColorBuilder -> ColorBuilder
to color (ColorBuilder config builder) =
    let
        startPos =
            case config.start of
                Just opacity_ ->
                    opacity_

                Nothing ->
                    BackgroundColor.rgb255 0 0 0

        -- Preserve alpha from start color only if:
        -- 1. New color has no explicit alpha (RGB/Hex/HSL), AND
        -- 2. Start color has explicit alpha (RGBA/HSLA)
        colorWithPreservedAlpha =
            case ( hasExplicitAlpha color, hasExplicitAlpha startPos ) of
                ( False, True ) ->
                    -- New color has no alpha, start has alpha -> preserve it
                    applyAlphaFromStart color startPos

                _ ->
                    -- Otherwise, use the color as-is
                    color
    in
    ColorBuilder
        { config
            | end = colorWithPreservedAlpha
            , distance = BackgroundColor.distance startPos colorWithPreservedAlpha
            , start = Just startPos
        }
        builder


{-| Check if a color has explicit alpha (RGBA/HSLA).
-}
hasExplicitAlpha : Color -> Bool
hasExplicitAlpha color =
    case color of
        Rgba _ ->
            True

        Hsla _ ->
            True

        _ ->
            False


{-| Apply alpha from start color to new color.
Only call this when you know both conditions are true:

  - New color has no explicit alpha
  - Start color has explicit alpha

-}
applyAlphaFromStart : Color -> Color -> Color
applyAlphaFromStart newColor startColor =
    let
        -- Extract alpha from start color
        startAlpha =
            case startColor of
                Rgba rgba ->
                    rgba.a

                Hsla hsla ->
                    hsla.a

                _ ->
                    -- Should never happen if caller checks hasExplicitAlpha first
                    1.0
    in
    case newColor of
        Rgb rgb ->
            Rgba { r = rgb.r, g = rgb.g, b = rgb.b, a = startAlpha }

        Hex hex ->
            let
                rgb =
                    BackgroundColor.hexToRgb hex
            in
            Rgba { r = rgb.r, g = rgb.g, b = rgb.b, a = startAlpha }

        Hsl hsl ->
            Hsla { h = hsl.h, s = hsl.s, l = hsl.l, a = startAlpha }

        -- Should never happen if caller checks hasExplicitAlpha first
        _ ->
            newColor


speed : Float -> ColorBuilder -> ColorBuilder
speed spd (ColorBuilder config builder) =
    let
        -- Black to white distance is exactly √(255² + 255² + 255²) ≈ 441.67
        maxColorDistance =
            441.67

        rgbDistancePerSecond =
            spd * maxColorDistance
    in
    ColorBuilder
        { config
            | speed = rgbDistancePerSecond
            , timing =
                Just <|
                    Speed rgbDistancePerSecond
        }
        builder


duration : Int -> ColorBuilder -> ColorBuilder
duration ms (ColorBuilder config builder) =
    ColorBuilder (PropertyBuilder.withDuration ms config) builder


easing : Easing -> ColorBuilder -> ColorBuilder
easing ease (ColorBuilder config builder) =
    ColorBuilder (PropertyBuilder.withEasing ease config) builder


delay : Int -> ColorBuilder -> ColorBuilder
delay dly (ColorBuilder config builder) =
    ColorBuilder (PropertyBuilder.withDelay dly config) builder
