module Anim.Internal.Property exposing
    ( CustomPropertyBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , speed
    , to
    )

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines



-- ============================================================
-- TYPES
-- ============================================================


type CustomPropertyBuilder
    = CustomPropertyBuilder String String (Builder.AnimationConfig Float) AnimBuilder



-- ============================================================
-- BUILD
-- ============================================================


for : String -> String -> String -> AnimBuilder -> CustomPropertyBuilder
for animGroupName cssPropertyName unit builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.CustomPropertyConfig name _ cfg ->
                    if name == cssPropertyName then
                        Just cfg

                    else
                        Nothing

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName
                (PropertyBaselines.getCustomProperty cssPropertyName)
                extractExisting
                defaultConfig
                builder
    in
    CustomPropertyBuilder cssPropertyName unit config <|
        Builder.for animGroupName builder


build : CustomPropertyBuilder -> AnimBuilder
build (CustomPropertyBuilder cssName unit config builder) =
    PropertyBuilder.upsert (Builder.CustomPropertyConfig cssName unit config) builder



-- ============================================================
-- FROM
-- ============================================================


defaultConfig : Builder.AnimationConfig Float
defaultConfig =
    PropertyBuilder.defaultConfig 0


from : Float -> CustomPropertyBuilder -> CustomPropertyBuilder
from value (CustomPropertyBuilder cssName unit config builder) =
    CustomPropertyBuilder cssName unit { config | start = Just value } builder



-- ============================================================
-- TO
-- ============================================================


to : Float -> CustomPropertyBuilder -> CustomPropertyBuilder
to endValue (CustomPropertyBuilder cssName unit config builder) =
    let
        startValue =
            case config.start of
                Just v ->
                    v

                Nothing ->
                    0
    in
    CustomPropertyBuilder cssName
        unit
        { config
            | end = endValue
            , distance = abs (endValue - startValue)
            , start = Just startValue
        }
        builder



-- ============================================================
-- TIMING
-- ============================================================


speed : Float -> CustomPropertyBuilder -> CustomPropertyBuilder
speed spd (CustomPropertyBuilder cssName unit config builder) =
    CustomPropertyBuilder cssName unit (PropertyBuilder.withSpeed spd config) builder


duration : Int -> CustomPropertyBuilder -> CustomPropertyBuilder
duration dur (CustomPropertyBuilder cssName unit config builder) =
    CustomPropertyBuilder cssName unit (PropertyBuilder.withDuration dur config) builder


easing : Easing -> CustomPropertyBuilder -> CustomPropertyBuilder
easing ease (CustomPropertyBuilder cssName unit config builder) =
    CustomPropertyBuilder cssName unit (PropertyBuilder.withEasing ease config) builder


delay : Int -> CustomPropertyBuilder -> CustomPropertyBuilder
delay dly (CustomPropertyBuilder cssName unit config builder) =
    CustomPropertyBuilder cssName unit (PropertyBuilder.withDelay dly config) builder
