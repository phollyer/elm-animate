module Anim.Internal.PropertyColor exposing
    ( CustomColorBuilder
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
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Extra.Color as Color exposing (Color)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Easing exposing (Easing)



-- ============================================================
-- TYPES
-- ============================================================


type CustomColorBuilder
    = CustomColorBuilder String (Builder.AnimationConfig Color) AnimBuilder


defaultColor : Color
defaultColor =
    Color.fromRGBA { r = 255, g = 255, b = 255, a = 0 }



-- ============================================================
-- BUILD
-- ============================================================


for : String -> String -> AnimBuilder -> CustomColorBuilder
for animGroupName cssPropertyName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.CustomColorPropertyConfig name cfg ->
                    if name == cssPropertyName then
                        Just cfg

                    else
                        Nothing

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName
                (PropertyBaselines.getCustomColorProperty cssPropertyName)
                extractExisting
                (PropertyBuilder.defaultConfig defaultColor)
                builder
    in
    CustomColorBuilder cssPropertyName config <|
        Builder.for animGroupName builder


build : CustomColorBuilder -> AnimBuilder
build (CustomColorBuilder cssName config builder) =
    PropertyBuilder.upsert (Builder.CustomColorPropertyConfig cssName config) builder



-- ============================================================
-- FROM
-- ============================================================


from : Color -> CustomColorBuilder -> CustomColorBuilder
from color (CustomColorBuilder cssName config builder) =
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
    CustomColorBuilder cssName { config | start = Just colorWithPreservedAlpha } builder



-- ============================================================
-- TO
-- ============================================================


to : Color -> CustomColorBuilder -> CustomColorBuilder
to color (CustomColorBuilder cssName config builder) =
    let
        startPos =
            case config.start of
                Just c ->
                    c

                Nothing ->
                    defaultColor

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
    CustomColorBuilder cssName
        { config
            | end = colorWithPreservedAlpha
            , distance = Color.distance startPos colorWithPreservedAlpha
            , start = Just startPos
        }
        builder



-- ============================================================
-- TIMING
-- ============================================================


speed : Float -> CustomColorBuilder -> CustomColorBuilder
speed spd (CustomColorBuilder cssName config builder) =
    let
        maxColorDistance =
            441.67

        rgbDistancePerSecond =
            spd * maxColorDistance
    in
    CustomColorBuilder cssName
        { config
            | timing =
                Just <|
                    Speed rgbDistancePerSecond
        }
        builder


duration : Int -> CustomColorBuilder -> CustomColorBuilder
duration dur (CustomColorBuilder cssName config builder) =
    CustomColorBuilder cssName (PropertyBuilder.withDuration dur config) builder


easing : Easing -> CustomColorBuilder -> CustomColorBuilder
easing ease (CustomColorBuilder cssName config builder) =
    CustomColorBuilder cssName (PropertyBuilder.withEasing ease config) builder


delay : Int -> CustomColorBuilder -> CustomColorBuilder
delay dly (CustomColorBuilder cssName config builder) =
    CustomColorBuilder cssName (PropertyBuilder.withDelay dly config) builder
