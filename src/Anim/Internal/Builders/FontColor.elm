module Anim.Internal.Builders.FontColor exposing
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
import Anim.Internal.Properties.Color as Color exposing (Color(..))
import Anim.Internal.Properties.FontColor as FontColor
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))


type ColorBuilder
    = ColorBuilder (Builder.AnimationConfig Color) AnimBuilder


for : String -> AnimBuilder -> ColorBuilder
for elementId builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.FontColorConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        extractBaseline endStates =
            endStates.fontColor

        config =
            PropertyBuilder.createFor extractExisting extractBaseline defaultConfig elementId builder
    in
    ColorBuilder config <|
        Builder.for elementId builder


build : ColorBuilder -> AnimBuilder
build (ColorBuilder config builder) =
    PropertyBuilder.upsert (Builder.FontColorConfig config) builder


type alias ColorConfig =
    Builder.AnimationConfig Color


defaultConfig : ColorConfig
defaultConfig =
    PropertyBuilder.defaultConfig FontColor.default


from : Color -> ColorBuilder -> ColorBuilder
from color (ColorBuilder config builder) =
    let
        -- Preserve alpha from previous animation's end value if:
        -- 1. New color has no explicit alpha (RGB/Hex/HSL), AND
        -- 2. Previous animation's end has explicit alpha (RGBA/HSLA)
        colorWithPreservedAlpha =
            case ( Color.hasExplicitAlpha color, Color.hasExplicitAlpha config.end ) of
                ( False, True ) ->
                    -- New color has no alpha, previous end has alpha -> preserve it
                    Color.applyAlphaFromStart color config.end

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
                    FontColor.default

        -- Preserve alpha from start color only if:
        -- 1. New color has no explicit alpha (RGB/Hex/HSL), AND
        -- 2. Start color has explicit alpha (RGBA/HSLA)
        colorWithPreservedAlpha =
            case ( Color.hasExplicitAlpha color, Color.hasExplicitAlpha startPos ) of
                ( False, True ) ->
                    -- New color has no alpha, start has alpha -> preserve it
                    Color.applyAlphaFromStart color startPos

                _ ->
                    -- Otherwise, use the color as-is
                    color
    in
    ColorBuilder
        { config
            | end = colorWithPreservedAlpha
            , distance = Color.distance startPos colorWithPreservedAlpha
            , start = Just startPos
        }
        builder


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
