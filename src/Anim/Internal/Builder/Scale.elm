module Anim.Internal.Builder.Scale exposing
    ( ScaleBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , fromX
    , fromXY
    , fromXYZ
    , fromXZ
    , fromY
    , fromYZ
    , fromZ
    , speed
    , toX
    , toXY
    , toXYZ
    , toXZ
    , toY
    , toYZ
    , toZ
    )

import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))


type ScaleBuilder
    = ScaleBuilder (Builder.AnimationConfig Scale) AnimBuilder


for : String -> AnimBuilder -> ScaleBuilder
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.ScaleConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        extractBaseline =
            PropertyBaselines.getScale

        config =
            PropertyBuilder.createFor extractExisting extractBaseline defaultConfig animGroupName builder
    in
    ScaleBuilder config <|
        Builder.for animGroupName builder


build : ScaleBuilder -> AnimBuilder
build (ScaleBuilder config builder) =
    let
        frozenAxes =
            Builder.getFrozenAxes "scale" builder

        adjustedConfig =
            if List.isEmpty frozenAxes then
                config

            else
                case config.start of
                    Just startVal ->
                        let
                            startRecord =
                                Scale.toRecord startVal

                            endRecord =
                                Scale.toRecord config.end

                            endX =
                                if List.member "x" frozenAxes then
                                    startRecord.x

                                else
                                    endRecord.x

                            endY =
                                if List.member "y" frozenAxes then
                                    startRecord.y

                                else
                                    endRecord.y

                            endZ =
                                if List.member "z" frozenAxes then
                                    startRecord.z

                                else
                                    endRecord.z

                            adjustedEnd =
                                Scale.fromTriple ( endX, endY, endZ )
                        in
                        { config | end = adjustedEnd, distance = Scale.distance startVal adjustedEnd }

                    Nothing ->
                        config
    in
    PropertyBuilder.upsert (Builder.ScaleConfig adjustedConfig) builder


type alias ScaleConfig =
    Builder.AnimationConfig Scale


defaultConfig : ScaleConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        Scale.fromTriple ( 1, 1, 1 )


fromXYZ : Float -> Float -> Float -> ScaleBuilder -> ScaleBuilder
fromXYZ scaleX scaleY scaleZ (ScaleBuilder config builder) =
    ScaleBuilder
        { config
            | start =
                Just <|
                    Scale.fromTriple ( scaleX, scaleY, scaleZ )
        }
        builder


fromXY : Float -> Float -> ScaleBuilder -> ScaleBuilder
fromXY scaleX scaleY (ScaleBuilder config builder) =
    ScaleBuilder
        { config
            | start =
                Just <|
                    Scale.fromTuple ( scaleX, scaleY )
        }
        builder


fromXZ : Float -> Float -> ScaleBuilder -> ScaleBuilder
fromXZ scaleX scaleZ (ScaleBuilder config builder) =
    let
        startScale =
            case config.start of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTriple ( 1, 1, 1 )

        { y } =
            Scale.toRecord startScale
    in
    ScaleBuilder
        { config
            | start =
                Just <|
                    Scale.fromTriple ( scaleX, y, scaleZ )
        }
        builder


fromX : Float -> ScaleBuilder -> ScaleBuilder
fromX scaleX (ScaleBuilder config builder) =
    let
        startScale =
            case config.start of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTriple ( 1, 1, 1 )

        { y, z } =
            Scale.toRecord startScale
    in
    ScaleBuilder
        { config
            | start =
                Just <|
                    Scale.fromTriple ( scaleX, y, z )
        }
        builder


fromYZ : Float -> Float -> ScaleBuilder -> ScaleBuilder
fromYZ scaleY scaleZ (ScaleBuilder config builder) =
    let
        startScale =
            case config.start of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTriple ( 1, 1, 1 )

        { x } =
            Scale.toRecord startScale
    in
    ScaleBuilder
        { config
            | start =
                Just <|
                    Scale.fromTriple ( x, scaleY, scaleZ )
        }
        builder


fromY : Float -> ScaleBuilder -> ScaleBuilder
fromY scaleY (ScaleBuilder config builder) =
    let
        startScale =
            case config.start of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTriple ( 1, 1, 1 )

        { x, z } =
            Scale.toRecord startScale
    in
    ScaleBuilder
        { config
            | start =
                Just <|
                    Scale.fromTriple ( x, scaleY, z )
        }
        builder


fromZ : Float -> ScaleBuilder -> ScaleBuilder
fromZ scaleZ (ScaleBuilder config builder) =
    let
        startScale =
            case config.start of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTriple ( 1, 1, 1 )

        { x, y } =
            Scale.toRecord startScale
    in
    ScaleBuilder
        { config
            | start =
                Just <|
                    Scale.fromTriple ( x, y, scaleZ )
        }
        builder


toXYZ : Float -> Float -> Float -> ScaleBuilder -> ScaleBuilder
toXYZ scaleX scaleY scaleZ (ScaleBuilder config builder) =
    let
        startScale =
            case config.start of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTriple ( 1, 1, 1 )

        endScale =
            Scale.fromTriple ( scaleX, scaleY, scaleZ )
    in
    ScaleBuilder
        { config
            | start = Just startScale
            , end = endScale
            , distance = Scale.distance startScale endScale
        }
        builder


toXY : Float -> Float -> ScaleBuilder -> ScaleBuilder
toXY scaleX scaleY (ScaleBuilder config builder) =
    let
        startScale =
            case config.start of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTriple ( 1, 1, 1 )

        { z } =
            Scale.toRecord startScale

        endScale =
            Scale.fromTriple ( scaleX, scaleY, z )
    in
    ScaleBuilder
        { config
            | start = Just startScale
            , end = endScale
            , distance = Scale.distance startScale endScale
        }
        builder


toXZ : Float -> Float -> ScaleBuilder -> ScaleBuilder
toXZ scaleX scaleZ (ScaleBuilder config builder) =
    let
        startScale =
            case config.start of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTriple ( 1, 1, 1 )

        { y } =
            Scale.toRecord startScale

        endScale =
            Scale.fromTriple ( scaleX, y, scaleZ )
    in
    ScaleBuilder
        { config
            | start = Just startScale
            , end = endScale
            , distance = Scale.distance startScale endScale
        }
        builder


toX : Float -> ScaleBuilder -> ScaleBuilder
toX scaleX (ScaleBuilder config builder) =
    let
        startScale =
            case config.start of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTriple ( 1, 1, 1 )

        { y, z } =
            Scale.toRecord startScale

        endScale =
            Scale.fromTriple ( scaleX, y, z )
    in
    ScaleBuilder
        { config
            | start = Just startScale
            , end = endScale
            , distance = Scale.distance startScale endScale
        }
        builder


toYZ : Float -> Float -> ScaleBuilder -> ScaleBuilder
toYZ scaleY scaleZ (ScaleBuilder config builder) =
    let
        startScale =
            case config.start of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTriple ( 1, 1, 1 )

        { x } =
            Scale.toRecord startScale

        endScale =
            Scale.fromTriple ( x, scaleY, scaleZ )
    in
    ScaleBuilder
        { config
            | start = Just startScale
            , end = endScale
            , distance = Scale.distance startScale endScale
        }
        builder


toY : Float -> ScaleBuilder -> ScaleBuilder
toY scaleY (ScaleBuilder config builder) =
    let
        startScale =
            case config.start of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTriple ( 1, 1, 1 )

        { x, z } =
            Scale.toRecord startScale

        endScale =
            Scale.fromTriple ( x, scaleY, z )
    in
    ScaleBuilder
        { config
            | start = Just startScale
            , end = endScale
            , distance = Scale.distance startScale endScale
        }
        builder


toZ : Float -> ScaleBuilder -> ScaleBuilder
toZ scaleZ (ScaleBuilder config builder) =
    let
        startScale =
            case config.start of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.fromTriple ( 1, 1, 1 )

        { x, y } =
            Scale.toRecord startScale

        endScale =
            Scale.fromTriple ( x, y, scaleZ )
    in
    ScaleBuilder
        { config
            | start = Just startScale
            , end = endScale
            , distance = Scale.distance startScale endScale
        }
        builder


speed : Float -> ScaleBuilder -> ScaleBuilder
speed value (ScaleBuilder config builder) =
    ScaleBuilder (PropertyBuilder.withSpeed value config) builder


duration : Int -> ScaleBuilder -> ScaleBuilder
duration ms (ScaleBuilder config builder) =
    ScaleBuilder (PropertyBuilder.withDuration ms config) builder


easing : Easing -> ScaleBuilder -> ScaleBuilder
easing easing_ (ScaleBuilder config builder) =
    ScaleBuilder (PropertyBuilder.withEasing easing_ config) builder


delay : Int -> ScaleBuilder -> ScaleBuilder
delay delay_ (ScaleBuilder config builder) =
    ScaleBuilder (PropertyBuilder.withDelay delay_ config) builder
