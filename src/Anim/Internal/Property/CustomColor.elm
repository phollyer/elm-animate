module Anim.Internal.Property.CustomColor exposing
    ( Builder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , speed
    , spring
    , to
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Extra.Color as Color exposing (Color)
import Easing exposing (Easing)
import Motion.Spring exposing (Spring)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type Builder mode
    = Builder String (Builder.AnimationConfig Color) (AnimBuilder mode)


defaultColor : Color
defaultColor =
    Color.fromRGBA { r = 255, g = 255, b = 255, a = 0 }



-- ============================================================
-- BUILD
-- ============================================================


for : String -> String -> AnimBuilder mode -> Builder mode
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
    Builder cssPropertyName config <|
        Builder.for animGroupName builder


build : Builder mode -> AnimBuilder mode
build (Builder cssName config builder) =
    PropertyBuilder.upsert (Builder.CustomColorPropertyConfig cssName config) builder



-- ============================================================
-- FROM
-- ============================================================


from : Color -> Builder mode -> Builder mode
from color (Builder cssName config builder) =
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
    Builder cssName { config | start = Just colorWithPreservedAlpha } builder



-- ============================================================
-- TO
-- ============================================================


to : Color -> Builder mode -> Builder mode
to color (Builder cssName config builder) =
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
    Builder cssName
        { config
            | end = colorWithPreservedAlpha
            , distance = Color.distance startPos colorWithPreservedAlpha
            , start = Just startPos
        }
        builder



-- ============================================================
-- TIMING
-- ============================================================


speed : Float -> Builder mode -> Builder mode
speed spd (Builder cssName config builder) =
    let
        maxColorDistance =
            441.67

        rgbDistancePerSecond =
            spd * maxColorDistance
    in
    Builder cssName
        { config
            | timing =
                Just <|
                    Speed rgbDistancePerSecond
        }
        builder


duration : Int -> Builder mode -> Builder mode
duration dur (Builder cssName config builder) =
    Builder cssName (PropertyBuilder.duration dur config) builder


easing : Easing -> Builder mode -> Builder mode
easing ease (Builder cssName config builder) =
    Builder cssName (PropertyBuilder.easing ease config) builder


spring : Spring -> Builder mode -> Builder mode
spring s (Builder cssName config builder) =
    Builder cssName (PropertyBuilder.spring s config) builder


delay : Int -> Builder mode -> Builder mode
delay dly (Builder cssName config builder) =
    Builder cssName (PropertyBuilder.delay dly config) builder
