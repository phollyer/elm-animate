module Anim.Internal.Builder.Rotate exposing
    ( RotateBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , fromX
    , fromXY
    , fromXYZ
    , fromXZ
    , fromY
    , fromYZ
    , fromZ
    , speed
    , to
    , toX
    , toXY
    , toXYZ
    , toXZ
    , toY
    , toYZ
    , toZ
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Easing exposing (Easing)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- MODEL
-- ============================================================


type RotateBuilder
    = RotateBuilder (Builder.AnimationConfig Rotate) AnimBuilder


type alias RotateConfig =
    Builder.AnimationConfig Rotate


default : Float
default =
    0.0


defaultConfig : RotateConfig
defaultConfig =
    PropertyBuilder.defaultConfig Rotate.default



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder -> RotateBuilder
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.RotateConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName PropertyBaselines.getRotate extractExisting defaultConfig builder
    in
    RotateBuilder config <|
        Builder.for animGroupName builder


build : RotateBuilder -> AnimBuilder
build (RotateBuilder config builder) =
    PropertyBuilder.upsert
        (Builder.RotateConfig
            (PropertyBuilder.applyFrozenAxes "rotate"
                Rotate.toRecord
                Rotate.fromRecord
                Rotate.distance
                builder
                config
            )
        )
        builder



-- ============================================================
-- FROM
-- ============================================================


from : Rotate -> RotateBuilder -> RotateBuilder
from rotate (RotateBuilder config builder) =
    RotateBuilder { config | start = Just rotate } builder


fromXYZ : Float -> Float -> Float -> RotateBuilder -> RotateBuilder
fromXYZ x y z =
    from (Rotate.fromTriple ( x, y, z ))


fromXY : Float -> Float -> RotateBuilder -> RotateBuilder
fromXY x y (RotateBuilder config builder) =
    let
        z =
            PropertyBuilder.getFloat Rotate.getZ default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromXZ : Float -> Float -> RotateBuilder -> RotateBuilder
fromXZ x z (RotateBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Rotate.getY default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromX : Float -> RotateBuilder -> RotateBuilder
fromX x (RotateBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Rotate.getY default config.start

        z =
            PropertyBuilder.getFloat Rotate.getZ default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromYZ : Float -> Float -> RotateBuilder -> RotateBuilder
fromYZ y z (RotateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Rotate.getX default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromY : Float -> RotateBuilder -> RotateBuilder
fromY y (RotateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Rotate.getX default config.start

        z =
            PropertyBuilder.getFloat Rotate.getZ default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromZ : Float -> RotateBuilder -> RotateBuilder
fromZ z (RotateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Rotate.getX default config.start

        y =
            PropertyBuilder.getFloat Rotate.getY default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder



-- ============================================================
-- TO
-- ============================================================


to : Rotate -> RotateBuilder -> RotateBuilder
to endRotate (RotateBuilder config builder) =
    let
        start =
            Maybe.withDefault Rotate.default config.start
    in
    RotateBuilder
        { config
            | start = Just start
            , end = endRotate
            , distance = Rotate.distance start endRotate
        }
        builder


toXYZ : Float -> Float -> Float -> RotateBuilder -> RotateBuilder
toXYZ x y z =
    to (Rotate.fromTriple ( x, y, z ))


toXY : Float -> Float -> RotateBuilder -> RotateBuilder
toXY x y (RotateBuilder config builder) =
    let
        z =
            Rotate.getZ config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toXZ : Float -> Float -> RotateBuilder -> RotateBuilder
toXZ x z (RotateBuilder config builder) =
    let
        y =
            Rotate.getY config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toX : Float -> RotateBuilder -> RotateBuilder
toX x (RotateBuilder config builder) =
    let
        y =
            Rotate.getY config.end

        z =
            Rotate.getZ config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toYZ : Float -> Float -> RotateBuilder -> RotateBuilder
toYZ y z (RotateBuilder config builder) =
    let
        x =
            Rotate.getX config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toY : Float -> RotateBuilder -> RotateBuilder
toY y (RotateBuilder config builder) =
    let
        x =
            Rotate.getX config.end

        z =
            Rotate.getZ config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toZ : Float -> RotateBuilder -> RotateBuilder
toZ z (RotateBuilder config builder) =
    let
        x =
            Rotate.getX config.end

        y =
            Rotate.getY config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> RotateBuilder -> RotateBuilder
delay ms (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.delay ms config) builder


duration : Int -> RotateBuilder -> RotateBuilder
duration ms (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> RotateBuilder -> RotateBuilder
speed value (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.speed value config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> RotateBuilder -> RotateBuilder
easing easing_ (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.easing easing_ config) builder
