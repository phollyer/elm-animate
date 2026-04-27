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
-- TYPES
-- ============================================================


type RotateBuilder
    = RotateBuilder (Builder.AnimationConfig Rotate) AnimBuilder



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
    let
        frozenAxes =
            Builder.getFrozenAxes "rotate" builder

        adjustedConfig =
            if List.isEmpty frozenAxes then
                config

            else
                case config.start of
                    Just startVal ->
                        let
                            endX =
                                if List.member "x" frozenAxes then
                                    Rotate.rotateX startVal

                                else
                                    Rotate.rotateX config.end

                            endY =
                                if List.member "y" frozenAxes then
                                    Rotate.rotateY startVal

                                else
                                    Rotate.rotateY config.end

                            endZ =
                                if List.member "z" frozenAxes then
                                    Rotate.rotateZ startVal

                                else
                                    Rotate.rotateZ config.end

                            adjustedEnd =
                                Rotate.fromTriple ( endX, endY, endZ )
                        in
                        { config | end = adjustedEnd, distance = Rotate.distance startVal adjustedEnd }

                    Nothing ->
                        config
    in
    PropertyBuilder.upsert (Builder.RotateConfig adjustedConfig) builder



-- ============================================================
-- FROM
-- ============================================================


type alias RotateConfig =
    Builder.AnimationConfig Rotate


defaultConfig : RotateConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        Rotate.fromTriple ( 0.0, 0.0, 0.0 )


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
            config.start
                |> Maybe.map Rotate.rotateZ
                |> Maybe.withDefault 0
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromXZ : Float -> Float -> RotateBuilder -> RotateBuilder
fromXZ x z (RotateBuilder config builder) =
    let
        y =
            config.start
                |> Maybe.map Rotate.rotateY
                |> Maybe.withDefault 0
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromX : Float -> RotateBuilder -> RotateBuilder
fromX x (RotateBuilder config builder) =
    let
        y =
            config.start
                |> Maybe.map Rotate.rotateY
                |> Maybe.withDefault 0

        z =
            config.start
                |> Maybe.map Rotate.rotateZ
                |> Maybe.withDefault 0
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromYZ : Float -> Float -> RotateBuilder -> RotateBuilder
fromYZ y z (RotateBuilder config builder) =
    let
        x =
            config.start
                |> Maybe.map Rotate.rotateX
                |> Maybe.withDefault 0
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromY : Float -> RotateBuilder -> RotateBuilder
fromY y (RotateBuilder config builder) =
    let
        x =
            config.start
                |> Maybe.map Rotate.rotateX
                |> Maybe.withDefault 0

        z =
            config.start
                |> Maybe.map Rotate.rotateZ
                |> Maybe.withDefault 0
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromZ : Float -> RotateBuilder -> RotateBuilder
fromZ z (RotateBuilder config builder) =
    let
        x =
            config.start
                |> Maybe.map Rotate.rotateX
                |> Maybe.withDefault 0

        y =
            config.start
                |> Maybe.map Rotate.rotateY
                |> Maybe.withDefault 0
    in
    fromXYZ x y z <|
        RotateBuilder config builder



-- ============================================================
-- TO
-- ============================================================


to : Rotate -> RotateBuilder -> RotateBuilder
to endRotate (RotateBuilder config builder) =
    let
        startRotate =
            case config.start of
                Just s ->
                    s

                Nothing ->
                    Rotate.fromTriple ( 0, 0, 0 )
    in
    RotateBuilder
        { config
            | start = Just startRotate
            , end = endRotate
            , distance = Rotate.distance startRotate endRotate
        }
        builder


toXYZ : Float -> Float -> Float -> RotateBuilder -> RotateBuilder
toXYZ x y z =
    to (Rotate.fromTriple ( x, y, z ))


toXY : Float -> Float -> RotateBuilder -> RotateBuilder
toXY x y (RotateBuilder config builder) =
    let
        z =
            Rotate.rotateZ config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toXZ : Float -> Float -> RotateBuilder -> RotateBuilder
toXZ x z (RotateBuilder config builder) =
    let
        y =
            Rotate.rotateY config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toX : Float -> RotateBuilder -> RotateBuilder
toX x (RotateBuilder config builder) =
    let
        y =
            Rotate.rotateY config.end

        z =
            Rotate.rotateZ config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toYZ : Float -> Float -> RotateBuilder -> RotateBuilder
toYZ y z (RotateBuilder config builder) =
    let
        x =
            Rotate.rotateX config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toY : Float -> RotateBuilder -> RotateBuilder
toY y (RotateBuilder config builder) =
    let
        x =
            Rotate.rotateX config.end

        z =
            Rotate.rotateZ config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toZ : Float -> RotateBuilder -> RotateBuilder
toZ z (RotateBuilder config builder) =
    let
        x =
            Rotate.rotateX config.end

        y =
            Rotate.rotateY config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> RotateBuilder -> RotateBuilder
delay delay_ (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withDelay delay_ config) builder


duration : Int -> RotateBuilder -> RotateBuilder
duration ms (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withDuration ms config) builder


speed : Float -> RotateBuilder -> RotateBuilder
speed value (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withSpeed value config) builder


easing : Easing -> RotateBuilder -> RotateBuilder
easing easing_ (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.withEasing easing_ config) builder
