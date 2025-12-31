module Anim.Internal.Builders.Opacity exposing
    ( OpacityBuilder
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
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))


type OpacityBuilder
    = OpacityBuilder (Builder.AnimationConfig Opacity) AnimBuilder


for : String -> AnimBuilder -> OpacityBuilder
for elementId builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.OpacityConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.createFor extractExisting defaultConfig elementId builder
    in
    OpacityBuilder config (Builder.for elementId builder)


build : OpacityBuilder -> AnimBuilder
build (OpacityBuilder config builder) =
    PropertyBuilder.upsert (Builder.OpacityConfig config) builder


type alias OpacityConfig =
    Builder.AnimationConfig Opacity


defaultConfig : OpacityConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        Opacity.fromFloat 1


from : Opacity -> OpacityBuilder -> OpacityBuilder
from opacity (OpacityBuilder config builder) =
    OpacityBuilder { config | start = Just opacity } builder


to : Opacity -> OpacityBuilder -> OpacityBuilder
to opacity (OpacityBuilder config builder) =
    let
        startPos =
            case config.start of
                Just opacity_ ->
                    opacity_

                Nothing ->
                    Opacity.fromFloat 1
    in
    OpacityBuilder
        { config
            | end = opacity
            , distance = Opacity.distance startPos opacity
            , start = Just startPos
        }
        builder


speed : Float -> OpacityBuilder -> OpacityBuilder
speed spd (OpacityBuilder config builder) =
    OpacityBuilder (PropertyBuilder.withSpeed spd config) builder


duration : Int -> OpacityBuilder -> OpacityBuilder
duration dur (OpacityBuilder config builder) =
    OpacityBuilder (PropertyBuilder.withDuration dur config) builder


easing : Easing -> OpacityBuilder -> OpacityBuilder
easing ease (OpacityBuilder config builder) =
    OpacityBuilder (PropertyBuilder.withEasing ease config) builder


delay : Int -> OpacityBuilder -> OpacityBuilder
delay dly (OpacityBuilder config builder) =
    OpacityBuilder (PropertyBuilder.withDelay dly config) builder
