module Anim.Internal.Builder.Color exposing (..)

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Extra.Color as Color exposing (Color)
import Easing exposing (Easing)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type alias ColorBuilderConfig =
    { propertyName : String
    , extractExisting : Builder.PropertyConfig -> Maybe (Builder.AnimationConfig Color)
    , wrapConfig : Builder.AnimationConfig Color -> Builder.PropertyConfig
    , extractBaseline : PropertyBaselines -> Maybe Color
    , defaultColor : Color
    }


type ColorBuilder
    = ColorBuilder (Builder.AnimationConfig Color) AnimBuilder



-- ============================================================
-- BUILD
-- ============================================================


for : ColorBuilderConfig -> String -> AnimBuilder -> ColorBuilder
for cfg animGroupName builder =
    let
        config =
            PropertyBuilder.for animGroupName cfg.extractBaseline cfg.extractExisting (defaultConfig cfg) builder
    in
    ColorBuilder config <|
        Builder.for animGroupName builder


build : ColorBuilderConfig -> ColorBuilder -> AnimBuilder
build cfg (ColorBuilder config builder) =
    PropertyBuilder.upsert (cfg.wrapConfig config) builder


defaultConfig : ColorBuilderConfig -> Builder.AnimationConfig Color
defaultConfig cfg =
    PropertyBuilder.defaultConfig cfg.defaultColor



-- ============================================================
-- INITIALIZE
-- ============================================================


init : Color -> ColorBuilder -> ColorBuilder
init color (ColorBuilder config builder) =
    ColorBuilder { config | start = Just color, end = color, distance = 0 } builder



-- ============================================================
-- FROM
-- ============================================================


from : Color -> ColorBuilder -> ColorBuilder
from color (ColorBuilder config builder) =
    let
        colorWithPreservedAlpha =
            case config.start of
                Nothing ->
                    color

                Just _ ->
                    case ( Color.hasExplicitAlpha color, Color.hasExplicitAlpha config.end ) of
                        ( False, True ) ->
                            Color.applyAlphaFromStart color config.end

                        _ ->
                            color
    in
    ColorBuilder { config | start = Just colorWithPreservedAlpha } builder



-- ============================================================
-- TO
-- ============================================================


to : ColorBuilderConfig -> Color -> ColorBuilder -> ColorBuilder
to cfg color (ColorBuilder config builder) =
    let
        startPos =
            case config.start of
                Just color_ ->
                    color_

                Nothing ->
                    cfg.defaultColor

        colorWithPreservedAlpha =
            case config.start of
                Nothing ->
                    color

                Just _ ->
                    case ( Color.hasExplicitAlpha color, Color.hasExplicitAlpha startPos ) of
                        ( False, True ) ->
                            Color.applyAlphaFromStart color startPos

                        _ ->
                            color
    in
    ColorBuilder
        { config
            | end = colorWithPreservedAlpha
            , distance = Color.distance startPos colorWithPreservedAlpha
            , start = Just startPos
        }
        builder



-- ============================================================
-- TIMING
-- ============================================================


speed : Float -> ColorBuilder -> ColorBuilder
speed spd (ColorBuilder config builder) =
    let
        maxColorDistance =
            441.67

        rgbDistancePerSecond =
            spd * maxColorDistance
    in
    ColorBuilder
        { config
            | timing =
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
