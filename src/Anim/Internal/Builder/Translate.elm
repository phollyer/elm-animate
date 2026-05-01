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


type TranslateBuilder mode
    = TranslateBuilder (Builder.AnimationConfig Translate) (AnimBuilder mode)


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


for : String -> AnimBuilder mode -> TranslateBuilder mode
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


build : TranslateBuilder mode -> AnimBuilder mode
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


from : Translate -> TranslateBuilder mode -> TranslateBuilder mode
from value (TranslateBuilder config builder) =
    TranslateBuilder { config | start = Just value } builder


fromXYZ : Float -> Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
fromXYZ x y z =
    from (Translate.fromTriple ( x, y, z ))


fromXY : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
fromXY x y (TranslateBuilder config builder) =
    let
        z =
            PropertyBuilder.getFloat Translate.getZ default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromXZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
fromXZ x z (TranslateBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Translate.getY default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromX : Float -> TranslateBuilder mode -> TranslateBuilder mode
fromX x (TranslateBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Translate.getY default config.start

        z =
            PropertyBuilder.getFloat Translate.getZ default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromYZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
fromYZ y z (TranslateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Translate.getX default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromY : Float -> TranslateBuilder mode -> TranslateBuilder mode
fromY y (TranslateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Translate.getX default config.start

        z =
            PropertyBuilder.getFloat Translate.getZ default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder


fromZ : Float -> TranslateBuilder mode -> TranslateBuilder mode
fromZ z (TranslateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Translate.getX default config.start

        y =
            PropertyBuilder.getFloat Translate.getY default config.start
    in
    fromXYZ x y z <|
        TranslateBuilder config builder



-- ============================================================
-- TO
-- ============================================================


to : Translate -> TranslateBuilder mode -> TranslateBuilder mode
to value (TranslateBuilder config builder) =
    let
        startVal =
            Maybe.withDefault Translate.default config.start
    in
    TranslateBuilder
        { config
            | start = Just startVal
            , end = value
            , distance = Translate.distance startVal value
        }
        builder


toXYZ : Float -> Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
toXYZ x y z =
    to (Translate.fromTriple ( x, y, z ))


toXY : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
toXY x y (TranslateBuilder config builder) =
    let
        z =
            Translate.getZ config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toXZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
toXZ x z (TranslateBuilder config builder) =
    let
        y =
            Translate.getY config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toX : Float -> TranslateBuilder mode -> TranslateBuilder mode
toX x (TranslateBuilder config builder) =
    let
        y =
            Translate.getY config.end

        z =
            Translate.getZ config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toYZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
toYZ y z (TranslateBuilder config builder) =
    let
        x =
            Translate.getX config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toY : Float -> TranslateBuilder mode -> TranslateBuilder mode
toY y (TranslateBuilder config builder) =
    let
        x =
            Translate.getX config.end

        z =
            Translate.getZ config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder


toZ : Float -> TranslateBuilder mode -> TranslateBuilder mode
toZ z (TranslateBuilder config builder) =
    let
        x =
            Translate.getX config.end

        y =
            Translate.getY config.end
    in
    toXYZ x y z <|
        TranslateBuilder config builder



-- ============================================================
-- BY
-- ============================================================


by : Translate -> TranslateBuilder mode -> TranslateBuilder mode
by delta (TranslateBuilder config builder) =
    let
        startVal =
            Maybe.withDefault Translate.default config.start

        endVal =
            Translate.fromTriple
                ( Translate.getX startVal + Translate.getX delta
                , Translate.getY startVal + Translate.getY delta
                , Translate.getZ startVal + Translate.getZ delta
                )
    in
    TranslateBuilder
        { config
            | start = Just startVal
            , end = endVal
            , distance = Translate.distance startVal endVal
        }
        builder


byXYZ : Float -> Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
byXYZ dx dy dz =
    by (Translate.fromTriple ( dx, dy, dz ))


byXY : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
byXY dx dy =
    byXYZ dx dy 0


byXZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
byXZ dx dz =
    byXYZ dx 0 dz


byX : Float -> TranslateBuilder mode -> TranslateBuilder mode
byX dx =
    byXYZ dx 0 0


byYZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
byYZ dy dz =
    byXYZ 0 dy dz


byY : Float -> TranslateBuilder mode -> TranslateBuilder mode
byY dy =
    byXYZ 0 dy 0


byZ : Float -> TranslateBuilder mode -> TranslateBuilder mode
byZ dz =
    byXYZ 0 0 dz



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> TranslateBuilder mode -> TranslateBuilder mode
delay delay_ (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.delay delay_ config) builder


duration : Int -> TranslateBuilder mode -> TranslateBuilder mode
duration ms (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> TranslateBuilder mode -> TranslateBuilder mode
speed value (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.speed value config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> TranslateBuilder mode -> TranslateBuilder mode
easing easing_ (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.easing easing_ config) builder
