module Anim.Internal.Builder.Skew exposing
    ( SkewBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , fromX
    , fromXY
    , fromY
    , speed
    , spring
    , toX
    , toXY
    , toY
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.Skew as Skew exposing (Skew)
import Motion.Easing as Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


type SkewBuilder mode
    = SkewBuilder (Builder.AnimationConfig Skew) (AnimBuilder mode)


type alias SkewConfig =
    Builder.AnimationConfig Skew


default : Float
default =
    0.0


defaultConfig : SkewConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        Skew.fromTuple ( default, default )



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder mode -> SkewBuilder mode
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.SkewConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName PropertyBaselines.getSkew extractExisting defaultConfig builder
    in
    SkewBuilder config <|
        Builder.for animGroupName builder


build : SkewBuilder mode -> AnimBuilder mode
build (SkewBuilder config builder) =
    PropertyBuilder.upsert (Builder.SkewConfig config) builder



-- ============================================================
-- FROM
-- ============================================================


fromXY : Float -> Float -> SkewBuilder mode -> SkewBuilder mode
fromXY x y (SkewBuilder config builder) =
    SkewBuilder
        { config
            | start =
                Just <|
                    Skew.fromTuple ( x, y )
        }
        builder


fromX : Float -> SkewBuilder mode -> SkewBuilder mode
fromX x (SkewBuilder config builder) =
    let
        y =
            PropertyBuilder.getFloat Skew.getY default config.start
    in
    fromXY x y <|
        SkewBuilder config builder


fromY : Float -> SkewBuilder mode -> SkewBuilder mode
fromY y (SkewBuilder config builder) =
    let
        x =
            PropertyBuilder.getFloat Skew.getX default config.start
    in
    fromXY x y <|
        SkewBuilder config builder



-- ============================================================
-- TO
-- ============================================================


to : Skew -> SkewBuilder mode -> SkewBuilder mode
to skew (SkewBuilder config builder) =
    let
        start =
            Maybe.withDefault Skew.default config.start
    in
    SkewBuilder
        { config
            | start = Just start
            , end = skew
            , distance = Skew.distance start skew
        }
        builder


toXY : Float -> Float -> SkewBuilder mode -> SkewBuilder mode
toXY x y =
    to (Skew.fromTuple ( x, y ))


toX : Float -> SkewBuilder mode -> SkewBuilder mode
toX x (SkewBuilder config builder) =
    let
        y =
            Skew.getY config.end
    in
    toXY x y <|
        SkewBuilder config builder


toY : Float -> SkewBuilder mode -> SkewBuilder mode
toY y (SkewBuilder config builder) =
    let
        x =
            Skew.getX config.end
    in
    toXY x y <|
        SkewBuilder config builder



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> SkewBuilder mode -> SkewBuilder mode
delay delay_ (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.delay delay_ config) builder


duration : Int -> SkewBuilder mode -> SkewBuilder mode
duration ms (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> SkewBuilder mode -> SkewBuilder mode
speed value (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.speed value config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> SkewBuilder mode -> SkewBuilder mode
easing easing_ (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.easing easing_ config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> SkewBuilder mode -> SkewBuilder mode
spring s (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.spring s config) builder
