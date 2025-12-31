module Anim.Internal.Builders.Color exposing
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

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Properties.BackgroundColor as BackgroundColor exposing (Color(..))
import Anim.Internal.Timing.Easing exposing (Easing)
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
    ColorBuilder { config | start = Just color } builder


to : Color -> ColorBuilder -> ColorBuilder
to color (ColorBuilder config builder) =
    let
        startPos =
            case config.start of
                Just opacity_ ->
                    opacity_

                Nothing ->
                    BackgroundColor.rgb255 0 0 0
    in
    ColorBuilder
        { config
            | end = color
            , distance = BackgroundColor.distance startPos color
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
