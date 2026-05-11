module Anim.Internal.Property.Custom exposing
    ( Builder
    , build
    , clamp
    , delay
    , duration
    , easing
    , for
    , from
    , speed
    , spring
    , to
    , unclamp
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


type Builder mode
    = Builder String String (Builder.AnimationConfig Float) (AnimBuilder mode)



-- ============================================================
-- BUILD
-- ============================================================


for : String -> String -> String -> AnimBuilder mode -> Builder mode
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
                ("custom:" ++ cssPropertyName)
                (PropertyBaselines.getCustomProperty cssPropertyName)
                extractExisting
                defaultConfig
                builder
    in
    Builder cssPropertyName unit config <|
        Builder.for animGroupName builder


build : Builder mode -> AnimBuilder mode
build (Builder cssName unit config builder) =
    let
        clampedConfig =
            applyClamps cssName builder config
    in
    PropertyBuilder.upsert (Builder.CustomPropertyConfig cssName unit clampedConfig) builder


applyClamps : String -> AnimBuilder mode -> Builder.AnimationConfig Float -> Builder.AnimationConfig Float
applyClamps cssName builder config =
    case Builder.getCurrentAnimGroupName builder of
        Nothing ->
            config

        Just animGroupName ->
            case Builder.getClamp animGroupName ("custom:" ++ cssName) "value" builder of
                Nothing ->
                    config

                Just ( lo, hi ) ->
                    let
                        clampedStart =
                            Maybe.map (Basics.clamp lo hi) config.start

                        clampedEnd =
                            Basics.clamp lo hi config.end

                        startForDistance =
                            Maybe.withDefault 0 clampedStart
                    in
                    { config
                        | start = clampedStart
                        , end = clampedEnd
                        , distance = abs (clampedEnd - startForDistance)
                    }



-- ============================================================
-- FROM
-- ============================================================


defaultConfig : Builder.AnimationConfig Float
defaultConfig =
    PropertyBuilder.defaultConfig 0


from : Float -> Builder mode -> Builder mode
from value (Builder cssName unit config builder) =
    Builder cssName unit { config | start = Just value } builder



-- ============================================================
-- TO
-- ============================================================


to : Float -> Builder mode -> Builder mode
to endValue (Builder cssName unit config builder) =
    let
        startValue =
            case config.start of
                Just v ->
                    v

                Nothing ->
                    0
    in
    Builder cssName
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


speed : Float -> Builder mode -> Builder mode
speed spd (Builder cssName unit config builder) =
    Builder cssName unit (PropertyBuilder.speed spd config) builder


duration : Int -> Builder mode -> Builder mode
duration dur (Builder cssName unit config builder) =
    Builder cssName unit (PropertyBuilder.duration dur config) builder


easing : Easing -> Builder mode -> Builder mode
easing ease (Builder cssName unit config builder) =
    Builder cssName unit (PropertyBuilder.easing ease config) builder


spring : Spring -> Builder mode -> Builder mode
spring s (Builder cssName unit config builder) =
    Builder cssName unit (PropertyBuilder.spring s config) builder



-- ============================================================
-- BOUNDS
-- ============================================================


clamp : Float -> Float -> Builder mode -> Builder mode
clamp lo hi (Builder cssName unit config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            Builder cssName unit config (Builder.setClamp animGroupName ("custom:" ++ cssName) "value" lo hi builder)

        Nothing ->
            Builder cssName unit config builder


unclamp : Builder mode -> Builder mode
unclamp (Builder cssName unit config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            Builder cssName unit config (Builder.clearClamp animGroupName ("custom:" ++ cssName) "value" builder)

        Nothing ->
            Builder cssName unit config builder


delay : Int -> Builder mode -> Builder mode
delay dly (Builder cssName unit config builder) =
    Builder cssName unit (PropertyBuilder.delay dly config) builder
