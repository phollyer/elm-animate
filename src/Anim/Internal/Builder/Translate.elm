module Anim.Internal.Builder.Translate exposing
    ( TranslateBuilder
    , build
    , by
    , byX
    , byXY
    , byXYZ
    , byXZ
    , byY
    , byYZ
    , byZ
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
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Easing exposing (Easing(..))
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- MODEL
-- ============================================================


type TranslateBuilder
    = TranslateBuilder (Builder.AnimationConfig Translate) AnimBuilder


type alias TranslateConfig =
    Builder.AnimationConfig Translate


default : Float
default =
    0.0


defaultConfig : TranslateConfig
defaultConfig =
    PropertyBuilder.defaultConfig Translate.default



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder -> TranslateBuilder
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.TranslateConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName PropertyBaselines.getTranslate extractExisting defaultConfig builder
    in
    TranslateBuilder config <|
        Builder.for animGroupName builder


build : TranslateBuilder -> AnimBuilder
build (TranslateBuilder config builder) =
    PropertyBuilder.upsert
        (Builder.TranslateConfig
            (PropertyBuilder.applyFrozenAxes "translate"
                Translate.toRecord
                Translate.fromRecord
                Translate.distance
                builder
                config
            )
        )
        builder



-- ============================================================
-- FROM
-- ============================================================


from : Translate -> TranslateBuilder -> TranslateBuilder
from value (TranslateBuilder config builder) =
    TranslateBuilder { config | start = Just value } builder


fromXYZ : Float -> Float -> Float -> TranslateBuilder -> TranslateBuilder
fromXYZ x y z =
    from (Translate.fromTriple ( x, y, z ))


fromXY : Float -> Float -> TranslateBuilder -> TranslateBuilder
fromXY x y (TranslateBuilder config builder) =
    let
        z =
            config.start
                |> Maybe.map Translate.z
                |> Maybe.withDefault default
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromXZ : Float -> Float -> TranslateBuilder -> TranslateBuilder
fromXZ x z (TranslateBuilder config builder) =
    let
        y =
            config.start
                |> Maybe.map Translate.y
                |> Maybe.withDefault default
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromX : Float -> TranslateBuilder -> TranslateBuilder
fromX x (TranslateBuilder config builder) =
    let
        y =
            config.start
                |> Maybe.map Translate.y
                |> Maybe.withDefault default

        z =
            config.start
                |> Maybe.map Translate.z
                |> Maybe.withDefault default
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromYZ : Float -> Float -> TranslateBuilder -> TranslateBuilder
fromYZ y z (TranslateBuilder config builder) =
    let
        x =
            config.start
                |> Maybe.map Translate.x
                |> Maybe.withDefault default
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromY : Float -> TranslateBuilder -> TranslateBuilder
fromY y (TranslateBuilder config builder) =
    let
        x =
            config.start
                |> Maybe.map Translate.x
                |> Maybe.withDefault default

        z =
            config.start
                |> Maybe.map Translate.z
                |> Maybe.withDefault default
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromZ : Float -> TranslateBuilder -> TranslateBuilder
fromZ z (TranslateBuilder config builder) =
    let
        x =
            config.start
                |> Maybe.map Translate.x
                |> Maybe.withDefault default

        y =
            config.start
                |> Maybe.map Translate.y
                |> Maybe.withDefault default
    in
    fromXYZ x y z <|
        TranslateBuilder config builder



-- ============================================================
-- TO
-- ============================================================


to : Translate -> TranslateBuilder -> TranslateBuilder
to value (TranslateBuilder config builder) =
    let
        startVal =
            case config.start of
                Just s ->
                    s

                Nothing ->
                    Translate.default
    in
    TranslateBuilder
        { config
            | start = Just startVal
            , end = value
            , distance = Translate.distance startVal value
        }
        builder


toXYZ : Float -> Float -> Float -> TranslateBuilder -> TranslateBuilder
toXYZ x y z =
    to (Translate.fromTriple ( x, y, z ))


toXY : Float -> Float -> TranslateBuilder -> TranslateBuilder
toXY x y (TranslateBuilder config builder) =
    let
        z =
            Translate.z config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toXZ : Float -> Float -> TranslateBuilder -> TranslateBuilder
toXZ x z (TranslateBuilder config builder) =
    let
        y =
            Translate.y config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toX : Float -> TranslateBuilder -> TranslateBuilder
toX x (TranslateBuilder config builder) =
    let
        y =
            Translate.y config.end

        z =
            Translate.z config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toYZ : Float -> Float -> TranslateBuilder -> TranslateBuilder
toYZ y z (TranslateBuilder config builder) =
    let
        x =
            Translate.x config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toY : Float -> TranslateBuilder -> TranslateBuilder
toY y (TranslateBuilder config builder) =
    let
        x =
            Translate.x config.end

        z =
            Translate.z config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toZ : Float -> TranslateBuilder -> TranslateBuilder
toZ z (TranslateBuilder config builder) =
    let
        x =
            Translate.x config.end

        y =
            Translate.y config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder



-- ============================================================
-- BY
-- ============================================================


by : Translate -> TranslateBuilder -> TranslateBuilder
by delta (TranslateBuilder config builder) =
    let
        startVal =
            Maybe.withDefault Translate.default config.start

        endVal =
            Translate.fromTriple
                ( Translate.x startVal + Translate.x delta
                , Translate.y startVal + Translate.y delta
                , Translate.z startVal + Translate.z delta
                )
    in
    TranslateBuilder
        { config
            | start = Just startVal
            , end = endVal
            , distance = Translate.distance startVal endVal
        }
        builder


byXYZ : Float -> Float -> Float -> TranslateBuilder -> TranslateBuilder
byXYZ dx dy dz =
    by (Translate.fromTriple ( dx, dy, dz ))


byXY : Float -> Float -> TranslateBuilder -> TranslateBuilder
byXY dx dy =
    byXYZ dx dy 0


byXZ : Float -> Float -> TranslateBuilder -> TranslateBuilder
byXZ dx dz =
    byXYZ dx 0 dz


byX : Float -> TranslateBuilder -> TranslateBuilder
byX dx =
    byXYZ dx 0 0


byYZ : Float -> Float -> TranslateBuilder -> TranslateBuilder
byYZ dy dz =
    byXYZ 0 dy dz


byY : Float -> TranslateBuilder -> TranslateBuilder
byY dy =
    byXYZ 0 dy 0


byZ : Float -> TranslateBuilder -> TranslateBuilder
byZ dz =
    byXYZ 0 0 dz



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> TranslateBuilder -> TranslateBuilder
delay delay_ (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.delay delay_ config) builder


duration : Int -> TranslateBuilder -> TranslateBuilder
duration ms (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> TranslateBuilder -> TranslateBuilder
speed value (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.speed value config) builder


easing : Easing -> TranslateBuilder -> TranslateBuilder
easing easing_ (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.easing easing_ config) builder
