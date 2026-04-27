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
    , toX
    , toXY
    , toY
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.Skew as Skew exposing (Skew)
import Easing exposing (Easing)



-- ============================================================
-- TYPES
-- ============================================================


type SkewBuilder
    = SkewBuilder (Builder.AnimationConfig Skew) AnimBuilder



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder -> SkewBuilder
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


build : SkewBuilder -> AnimBuilder
build (SkewBuilder config builder) =
    PropertyBuilder.upsert (Builder.SkewConfig config) builder



-- ============================================================
-- FROM
-- ============================================================


type alias SkewConfig =
    Builder.AnimationConfig Skew


default : Float
default =
    0.0


defaultConfig : SkewConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        Skew.fromTuple ( default, default )


fromXY : Float -> Float -> SkewBuilder -> SkewBuilder
fromXY x y (SkewBuilder config builder) =
    SkewBuilder
        { config
            | start =
                Just <|
                    Skew.fromTuple ( x, y )
        }
        builder


fromX : Float -> SkewBuilder -> SkewBuilder
fromX x (SkewBuilder config builder) =
    let
        y =
            config.start
                |> Maybe.map Skew.getY
                |> Maybe.withDefault default
    in
    fromXY x y <|
        SkewBuilder config builder


fromY : Float -> SkewBuilder -> SkewBuilder
fromY y (SkewBuilder config builder) =
    let
        x =
            config.start
                |> Maybe.map Skew.getX
                |> Maybe.withDefault default
    in
    fromXY x y <|
        SkewBuilder config builder



-- ============================================================
-- TO
-- ============================================================


to : Skew -> SkewBuilder -> SkewBuilder
to skew (SkewBuilder config builder) =
    let
        start =
            case config.start of
                Just s ->
                    s

                Nothing ->
                    Skew.default
    in
    SkewBuilder
        { config
            | start = Just start
            , end = skew
            , distance = Skew.distance start skew
        }
        builder


toXY : Float -> Float -> SkewBuilder -> SkewBuilder
toXY x y =
    to (Skew.fromTuple ( x, y ))


toX : Float -> SkewBuilder -> SkewBuilder
toX x (SkewBuilder config builder) =
    let
        y =
            Skew.getY config.end
    in
    toXY x y <|
        SkewBuilder config builder


toY : Float -> SkewBuilder -> SkewBuilder
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


speed : Float -> SkewBuilder -> SkewBuilder
speed value (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.speed value config) builder


duration : Int -> SkewBuilder -> SkewBuilder
duration ms (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.duration ms config) builder


easing : Easing -> SkewBuilder -> SkewBuilder
easing easing_ (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.easing easing_ config) builder


delay : Int -> SkewBuilder -> SkewBuilder
delay delay_ (SkewBuilder config builder) =
    SkewBuilder (PropertyBuilder.delay delay_ config) builder
