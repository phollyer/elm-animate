module Anim.Internal.Builder.Opacity exposing
    ( OpacityBuilder
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
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type OpacityBuilder mode
    = OpacityBuilder (Builder.AnimationConfig Opacity) (AnimBuilder mode)


type alias OpacityConfig =
    Builder.AnimationConfig Opacity


defaultConfig : OpacityConfig
defaultConfig =
    PropertyBuilder.defaultConfig Opacity.default



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder mode -> OpacityBuilder mode
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.OpacityConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName "opacity" PropertyBaselines.getOpacity extractExisting defaultConfig builder
    in
    OpacityBuilder config <|
        Builder.for animGroupName builder


build : OpacityBuilder mode -> AnimBuilder mode
build (OpacityBuilder config builder) =
    PropertyBuilder.upsert (Builder.OpacityConfig config) builder



-- ============================================================
-- FROM
-- ============================================================


from : Opacity -> OpacityBuilder mode -> OpacityBuilder mode
from opacity (OpacityBuilder config builder) =
    OpacityBuilder { config | start = Just opacity } builder



-- ============================================================
-- TO
-- ============================================================


to : Opacity -> OpacityBuilder mode -> OpacityBuilder mode
to endPos (OpacityBuilder config builder) =
    let
        startPos =
            Maybe.withDefault Opacity.default config.start
    in
    OpacityBuilder
        { config
            | end = endPos
            , distance = Opacity.distance startPos endPos
            , start = Just startPos
        }
        builder



-- ============================================================
-- TIMING
-- ============================================================


speed : Float -> OpacityBuilder mode -> OpacityBuilder mode
speed spd (OpacityBuilder config builder) =
    OpacityBuilder (PropertyBuilder.speed spd config) builder


duration : Int -> OpacityBuilder mode -> OpacityBuilder mode
duration dur (OpacityBuilder config builder) =
    OpacityBuilder (PropertyBuilder.duration dur config) builder


delay : Int -> OpacityBuilder mode -> OpacityBuilder mode
delay dly (OpacityBuilder config builder) =
    OpacityBuilder (PropertyBuilder.delay dly config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> OpacityBuilder mode -> OpacityBuilder mode
easing ease (OpacityBuilder config builder) =
    OpacityBuilder (PropertyBuilder.easing ease config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> OpacityBuilder mode -> OpacityBuilder mode
spring s (OpacityBuilder config builder) =
    OpacityBuilder (PropertyBuilder.spring s config) builder
