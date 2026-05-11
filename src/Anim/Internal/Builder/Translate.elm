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
    , clampX
    , clampY
    , clampZ
    , delay
    , duration
    , easing
    , for
    , forContinuing
    , from
    , fromX
    , fromXY
    , fromXYZ
    , fromXZ
    , fromY
    , fromYZ
    , fromZ
    , speed
    , spring
    , to
    , toX
    , toXY
    , toXYZ
    , toXZ
    , toY
    , toYZ
    , toZ
    , unclampX
    , unclampY
    , unclampZ
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Motion.Easing exposing (Easing(..))
import Motion.Spring exposing (Spring)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
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
            PropertyBuilder.for animGroupName "translate" PropertyBaselines.getTranslate extractExisting defaultConfig builder
    in
    TranslateBuilder config <|
        Builder.for animGroupName builder


forContinuing : String -> AnimBuilder mode -> TranslateBuilder mode
forContinuing animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.TranslateConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        extractProcessedTiming processed =
            case processed of
                Builder.ProcessedTranslateConfig p ->
                    Just
                        { timing = Just p.timing
                        , easing = Just p.easing
                        , spring = p.spring
                        , delay = Just p.delay
                        }

                _ ->
                    Nothing

        config =
            PropertyBuilder.forContinuing animGroupName "translate" PropertyBaselines.getTranslate extractExisting extractProcessedTiming defaultConfig builder
    in
    TranslateBuilder config <|
        Builder.for animGroupName builder


build : TranslateBuilder mode -> AnimBuilder mode
build (TranslateBuilder config builder) =
    let
        clampSpec =
            case Builder.getCurrentAnimGroupName builder of
                Just animGroupName ->
                    Builder.getTranslateClampSpec animGroupName builder

                Nothing ->
                    Builder.emptyTranslateClampSpec

        clampedConfig =
            applyClamps clampSpec config
    in
    PropertyBuilder.upsert
        (Builder.TranslateConfig
            (PropertyBuilder.applyFrozenAxes "translate"
                Translate.toRecord
                Translate.fromRecord
                Translate.distance
                builder
                clampedConfig
            )
        )
        builder


applyClamps : Builder.TranslateClampSpec -> TranslateConfig -> TranslateConfig
applyClamps spec config =
    if spec == Builder.emptyTranslateClampSpec then
        config

    else
        let
            clampedStart =
                Maybe.map (clampTranslate spec) config.start

            clampedEnd =
                clampTranslate spec config.end

            startForDistance =
                Maybe.withDefault Translate.default clampedStart
        in
        { config
            | start = clampedStart
            , end = clampedEnd
            , distance = Translate.distance startForDistance clampedEnd
        }


clampTranslate : Builder.TranslateClampSpec -> Translate -> Translate
clampTranslate spec value =
    Translate.fromTriple
        ( clampAxis spec.x (Translate.getX value)
        , clampAxis spec.y (Translate.getY value)
        , clampAxis spec.z (Translate.getZ value)
        )


clampAxis : Maybe ( Float, Float ) -> Float -> Float
clampAxis range v =
    case range of
        Just ( lo, hi ) ->
            clamp lo hi v

        Nothing ->
            v



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



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> TranslateBuilder mode -> TranslateBuilder mode
spring s (TranslateBuilder config builder) =
    TranslateBuilder (PropertyBuilder.spring s config) builder



-- ============================================================
-- BOUNDS
-- ============================================================


clampX : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
clampX lo hi =
    updateBuilderClamp (\name -> Builder.setTranslateClampX name lo hi)


clampY : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
clampY lo hi =
    updateBuilderClamp (\name -> Builder.setTranslateClampY name lo hi)


clampZ : Float -> Float -> TranslateBuilder mode -> TranslateBuilder mode
clampZ lo hi =
    updateBuilderClamp (\name -> Builder.setTranslateClampZ name lo hi)


unclampX : TranslateBuilder mode -> TranslateBuilder mode
unclampX =
    updateBuilderClamp Builder.clearTranslateClampX


unclampY : TranslateBuilder mode -> TranslateBuilder mode
unclampY =
    updateBuilderClamp Builder.clearTranslateClampY


unclampZ : TranslateBuilder mode -> TranslateBuilder mode
unclampZ =
    updateBuilderClamp Builder.clearTranslateClampZ


updateBuilderClamp : (String -> AnimBuilder mode -> AnimBuilder mode) -> TranslateBuilder mode -> TranslateBuilder mode
updateBuilderClamp f (TranslateBuilder config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            TranslateBuilder config (f animGroupName builder)

        Nothing ->
            TranslateBuilder config builder
