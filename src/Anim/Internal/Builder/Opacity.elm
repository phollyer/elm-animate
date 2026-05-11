module Anim.Internal.Builder.Opacity exposing
    ( OpacityBuilder
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
    PropertyBuilder.upsert (Builder.OpacityConfig (applyClamps builder config)) builder


applyClamps : AnimBuilder mode -> OpacityConfig -> OpacityConfig
applyClamps builder config =
    case Builder.getCurrentAnimGroupName builder of
        Nothing ->
            config

        Just animGroupName ->
            case Builder.getClamp animGroupName "opacity" "value" builder of
                Nothing ->
                    config

                Just ( lo, hi ) ->
                    let
                        clampValue v =
                            Opacity.fromFloat (Basics.clamp lo hi (Opacity.toFloat v))

                        clampedStart =
                            Maybe.map clampValue config.start

                        clampedEnd =
                            clampValue config.end

                        startForDistance =
                            Maybe.withDefault Opacity.default clampedStart
                    in
                    { config
                        | start = clampedStart
                        , end = clampedEnd
                        , distance = Opacity.distance startForDistance clampedEnd
                    }



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



-- ============================================================
-- BOUNDS
-- ============================================================


clamp : Float -> Float -> OpacityBuilder mode -> OpacityBuilder mode
clamp lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "opacity" "value" lo hi)


unclamp : OpacityBuilder mode -> OpacityBuilder mode
unclamp =
    updateBuilderClamp (\name -> Builder.clearClamp name "opacity" "value")


updateBuilderClamp : (String -> AnimBuilder mode -> AnimBuilder mode) -> OpacityBuilder mode -> OpacityBuilder mode
updateBuilderClamp f (OpacityBuilder config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            OpacityBuilder config (f animGroupName builder)

        Nothing ->
            OpacityBuilder config builder
