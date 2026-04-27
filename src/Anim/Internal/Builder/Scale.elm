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
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Easing exposing (Easing)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- MODEL
-- ============================================================


type ScaleBuilder
    = ScaleBuilder (Builder.AnimationConfig Scale) AnimBuilder



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder -> ScaleBuilder
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.ScaleConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName PropertyBaselines.getScale extractExisting defaultConfig builder
    in
    ScaleBuilder config <|
        Builder.for animGroupName builder


build : ScaleBuilder -> AnimBuilder
build (ScaleBuilder config builder) =
    PropertyBuilder.upsert
        (Builder.ScaleConfig
            (PropertyBuilder.applyFrozenAxes "scale"
                Scale.toRecord
                Scale.fromRecord
                Scale.distance
                builder
                config
            )
        )
        builder



-- ============================================================
-- FROM
-- ============================================================


type alias ScaleConfig =
    Builder.AnimationConfig Scale


default : Float
default =
    1.0


defaultConfig : ScaleConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        Scale.fromTriple ( default, default, default )


from : Scale -> ScaleBuilder -> ScaleBuilder
from scale (ScaleBuilder config builder) =
    ScaleBuilder { config | start = Just scale } builder


fromXYZ : Float -> Float -> Float -> ScaleBuilder -> ScaleBuilder
fromXYZ x y z =
    from (Scale.fromTriple ( x, y, z ))


fromXY : Float -> Float -> ScaleBuilder -> ScaleBuilder
fromXY x y (ScaleBuilder config builder) =
    let
        z =
            config.start
                |> Maybe.map Scale.getZ
                |> Maybe.withDefault default
    in
    fromXYZ x y z <|
        ScaleBuilder config builder


fromXZ : Float -> Float -> ScaleBuilder -> ScaleBuilder
fromXZ x z (ScaleBuilder config builder) =
    let
        y =
            config.start
                |> Maybe.map Scale.getY
                |> Maybe.withDefault default
    in
    fromXYZ x y z <|
        ScaleBuilder config builder


fromX : Float -> ScaleBuilder -> ScaleBuilder
fromX scaleX (ScaleBuilder config builder) =
    let
        y =
            config.start
                |> Maybe.map Scale.getY
                |> Maybe.withDefault default

        z =
            config.start
                |> Maybe.map Scale.getZ
                |> Maybe.withDefault default
    in
    fromXYZ scaleX y z <|
        ScaleBuilder config builder


fromYZ : Float -> Float -> ScaleBuilder -> ScaleBuilder
fromYZ scaleY scaleZ (ScaleBuilder config builder) =
    let
        x =
            config.start
                |> Maybe.map Scale.getX
                |> Maybe.withDefault default
    in
    fromXYZ x scaleY scaleZ <|
        ScaleBuilder config builder


fromY : Float -> ScaleBuilder -> ScaleBuilder
fromY scaleY (ScaleBuilder config builder) =
    let
        x =
            config.start
                |> Maybe.map Scale.getX
                |> Maybe.withDefault default

        z =
            config.start
                |> Maybe.map Scale.getZ
                |> Maybe.withDefault default
    in
    fromXYZ x scaleY z <|
        ScaleBuilder config builder


fromZ : Float -> ScaleBuilder -> ScaleBuilder
fromZ scaleZ (ScaleBuilder config builder) =
    let
        x =
            config.start
                |> Maybe.map Scale.getX
                |> Maybe.withDefault default

        y =
            config.start
                |> Maybe.map Scale.getY
                |> Maybe.withDefault default
    in
    fromXYZ x y scaleZ <|
        ScaleBuilder config builder



-- ============================================================
-- TO
-- ============================================================


to : Scale -> ScaleBuilder -> ScaleBuilder
to endPos (ScaleBuilder config builder) =
    let
        startPos =
            case config.start of
                Just scale_ ->
                    scale_

                Nothing ->
                    Scale.default
    in
    ScaleBuilder
        { config
            | start = Just startPos
            , end = endPos
            , distance = Scale.distance startPos endPos
        }
        builder


toXYZ : Float -> Float -> Float -> ScaleBuilder -> ScaleBuilder
toXYZ x y z =
    to (Scale.fromTriple ( x, y, z ))


toXY : Float -> Float -> ScaleBuilder -> ScaleBuilder
toXY x y (ScaleBuilder config builder) =
    let
        z =
            Scale.getZ config.end
    in
    toXYZ x y z <|
        ScaleBuilder config builder


toXZ : Float -> Float -> ScaleBuilder -> ScaleBuilder
toXZ x z (ScaleBuilder config builder) =
    let
        y =
            Scale.getY config.end
    in
    toXYZ x y z <|
        ScaleBuilder config builder


toX : Float -> ScaleBuilder -> ScaleBuilder
toX x (ScaleBuilder config builder) =
    let
        y =
            Scale.getY config.end

        z =
            Scale.getZ config.end
    in
    toXYZ x y z <|
        ScaleBuilder config builder


toYZ : Float -> Float -> ScaleBuilder -> ScaleBuilder
toYZ y z (ScaleBuilder config builder) =
    let
        x =
            Scale.getX config.end
    in
    toXYZ x y z <|
        ScaleBuilder config builder


toY : Float -> ScaleBuilder -> ScaleBuilder
toY y (ScaleBuilder config builder) =
    let
        x =
            Scale.getX config.end

        z =
            Scale.getZ config.end
    in
    toXYZ x y z <|
        ScaleBuilder config builder


toZ : Float -> ScaleBuilder -> ScaleBuilder
toZ z (ScaleBuilder config builder) =
    let
        x =
            Scale.getX config.end

        y =
            Scale.getY config.end
    in
    toXYZ x y z <|
        ScaleBuilder config builder



-- ============================================================
-- TIMING
-- ============================================================


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
