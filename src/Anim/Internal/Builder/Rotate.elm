module Anim.Internal.Builder.Rotate exposing
    ( RotateBuilder
    , build
    , clampX
    , clampY
    , clampZ
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
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type RotateBuilder mode
    = RotateBuilder (Builder.AnimationConfig Rotate) (AnimBuilder mode)


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


for : String -> AnimBuilder mode -> RotateBuilder mode
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.RotateConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName "rotate" PropertyBaselines.getRotate extractExisting defaultConfig builder
    in
    RotateBuilder config <|
        Builder.for animGroupName builder


build : RotateBuilder mode -> AnimBuilder mode
build (RotateBuilder config builder) =
    let
        clampedConfig =
            applyClamps builder config
    in
    PropertyBuilder.upsert
        (Builder.RotateConfig
            (PropertyBuilder.applyFrozenAxes "rotate"
                Rotate.toRecord
                Rotate.fromRecord
                Rotate.distance
                builder
                clampedConfig
            )
        )
        builder


applyClamps : AnimBuilder mode -> RotateConfig -> RotateConfig
applyClamps builder config =
    case Builder.getCurrentAnimGroupName builder of
        Nothing ->
            config

        Just animGroupName ->
            let
                cx =
                    Builder.getClamp animGroupName "rotate" "x" builder

                cy =
                    Builder.getClamp animGroupName "rotate" "y" builder

                cz =
                    Builder.getClamp animGroupName "rotate" "z" builder
            in
            if cx == Nothing && cy == Nothing && cz == Nothing then
                config

            else
                let
                    clampValue value =
                        Rotate.fromTriple
                            ( clampAxis cx (Rotate.getX value)
                            , clampAxis cy (Rotate.getY value)
                            , clampAxis cz (Rotate.getZ value)
                            )

                    clampedStart =
                        Maybe.map clampValue config.start

                    clampedEnd =
                        clampValue config.end

                    startForDistance =
                        Maybe.withDefault Rotate.default clampedStart
                in
                { config
                    | start = clampedStart
                    , end = clampedEnd
                    , distance = Rotate.distance startForDistance clampedEnd
                }


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


from : Rotate -> RotateBuilder mode -> RotateBuilder mode
from rotate (RotateBuilder config builder) =
    RotateBuilder { config | start = Just rotate } builder


fromXYZ : Float -> Float -> Float -> RotateBuilder mode -> RotateBuilder mode
fromXYZ x y z =
    from (Rotate.fromTriple ( x, y, z ))


fromXY : Float -> Float -> RotateBuilder mode -> RotateBuilder mode
fromXY x y (RotateBuilder config builder) =
    let
        z =
            PropertyBuilder.getFloat Rotate.getZ default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromXZ : Float -> Float -> RotateBuilder mode -> RotateBuilder mode
fromXZ x z (RotateBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Rotate.getY default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromX : Float -> RotateBuilder mode -> RotateBuilder mode
fromX x (RotateBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Rotate.getY default config.start

        z =
            PropertyBuilder.getFloat Rotate.getZ default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromYZ : Float -> Float -> RotateBuilder mode -> RotateBuilder mode
fromYZ y z (RotateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Rotate.getX default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromY : Float -> RotateBuilder mode -> RotateBuilder mode
fromY y (RotateBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Rotate.getX default config.start

        z =
            PropertyBuilder.getFloat Rotate.getZ default config.start
    in
    fromXYZ x y z <|
        RotateBuilder config builder


fromZ : Float -> RotateBuilder mode -> RotateBuilder mode
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


to : Rotate -> RotateBuilder mode -> RotateBuilder mode
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


toXYZ : Float -> Float -> Float -> RotateBuilder mode -> RotateBuilder mode
toXYZ x y z =
    to (Rotate.fromTriple ( x, y, z ))


toXY : Float -> Float -> RotateBuilder mode -> RotateBuilder mode
toXY x y (RotateBuilder config builder) =
    let
        z =
            Rotate.getZ config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toXZ : Float -> Float -> RotateBuilder mode -> RotateBuilder mode
toXZ x z (RotateBuilder config builder) =
    let
        y =
            Rotate.getY config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toX : Float -> RotateBuilder mode -> RotateBuilder mode
toX x (RotateBuilder config builder) =
    let
        y =
            Rotate.getY config.end

        z =
            Rotate.getZ config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toYZ : Float -> Float -> RotateBuilder mode -> RotateBuilder mode
toYZ y z (RotateBuilder config builder) =
    let
        x =
            Rotate.getX config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toY : Float -> RotateBuilder mode -> RotateBuilder mode
toY y (RotateBuilder config builder) =
    let
        x =
            Rotate.getX config.end

        z =
            Rotate.getZ config.end
    in
    toXYZ x y z <|
        RotateBuilder config builder


toZ : Float -> RotateBuilder mode -> RotateBuilder mode
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


delay : Int -> RotateBuilder mode -> RotateBuilder mode
delay ms (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.delay ms config) builder


duration : Int -> RotateBuilder mode -> RotateBuilder mode
duration ms (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> RotateBuilder mode -> RotateBuilder mode
speed value (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.speed value config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> RotateBuilder mode -> RotateBuilder mode
easing easing_ (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.easing easing_ config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> RotateBuilder mode -> RotateBuilder mode
spring s (RotateBuilder config builder) =
    RotateBuilder (PropertyBuilder.spring s config) builder



-- ============================================================
-- BOUNDS
-- ============================================================


clampX : Float -> Float -> RotateBuilder mode -> RotateBuilder mode
clampX lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "rotate" "x" lo hi)


clampY : Float -> Float -> RotateBuilder mode -> RotateBuilder mode
clampY lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "rotate" "y" lo hi)


clampZ : Float -> Float -> RotateBuilder mode -> RotateBuilder mode
clampZ lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "rotate" "z" lo hi)


unclampX : RotateBuilder mode -> RotateBuilder mode
unclampX =
    updateBuilderClamp (\name -> Builder.clearClamp name "rotate" "x")


unclampY : RotateBuilder mode -> RotateBuilder mode
unclampY =
    updateBuilderClamp (\name -> Builder.clearClamp name "rotate" "y")


unclampZ : RotateBuilder mode -> RotateBuilder mode
unclampZ =
    updateBuilderClamp (\name -> Builder.clearClamp name "rotate" "z")


updateBuilderClamp : (String -> AnimBuilder mode -> AnimBuilder mode) -> RotateBuilder mode -> RotateBuilder mode
updateBuilderClamp f (RotateBuilder config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            RotateBuilder config (f animGroupName builder)

        Nothing ->
            RotateBuilder config builder
