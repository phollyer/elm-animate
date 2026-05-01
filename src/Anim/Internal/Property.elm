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

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Easing exposing (Easing)



-- ============================================================
-- TYPES
-- ============================================================


type CustomPropertyBuilder mode
    = CustomPropertyBuilder String String (Builder.AnimationConfig Float) (AnimBuilder mode)



-- ============================================================
-- BUILD
-- ============================================================


for : String -> String -> String -> AnimBuilder mode -> CustomPropertyBuilder mode
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


build : CustomPropertyBuilder mode -> AnimBuilder mode
build (CustomPropertyBuilder cssName unit config builder) =
    PropertyBuilder.upsert (Builder.CustomPropertyConfig cssName unit config) builder



-- ============================================================
-- FROM
-- ============================================================


defaultConfig : Builder.AnimationConfig Float
defaultConfig =
    PropertyBuilder.defaultConfig 0


from : Float -> CustomPropertyBuilder mode -> CustomPropertyBuilder mode
from value (CustomPropertyBuilder cssName unit config builder) =
    CustomPropertyBuilder cssName unit { config | start = Just value } builder



-- ============================================================
-- TO
-- ============================================================


to : Float -> CustomPropertyBuilder mode -> CustomPropertyBuilder mode
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


speed : Float -> CustomPropertyBuilder mode -> CustomPropertyBuilder mode
speed spd (CustomPropertyBuilder cssName unit config builder) =
    CustomPropertyBuilder cssName unit (PropertyBuilder.speed spd config) builder


duration : Int -> CustomPropertyBuilder mode -> CustomPropertyBuilder mode
duration dur (CustomPropertyBuilder cssName unit config builder) =
    CustomPropertyBuilder cssName unit (PropertyBuilder.duration dur config) builder


easing : Easing -> CustomPropertyBuilder mode -> CustomPropertyBuilder mode
easing ease (CustomPropertyBuilder cssName unit config builder) =
    CustomPropertyBuilder cssName unit (PropertyBuilder.easing ease config) builder


delay : Int -> CustomPropertyBuilder mode -> CustomPropertyBuilder mode
delay dly (CustomPropertyBuilder cssName unit config builder) =
    CustomPropertyBuilder cssName unit (PropertyBuilder.delay dly config) builder
