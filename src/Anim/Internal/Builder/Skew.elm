module Anim.Internal.Builder.Skew exposing
    ( SkewBuilder
    , build
    , clampX
    , clampY
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
    , unclampX
    , unclampY
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.Skew as Skew exposing (Skew)
import Motion.Easing exposing (Easing)
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
            PropertyBuilder.for animGroupName "skew" PropertyBaselines.getSkew extractExisting defaultConfig builder
    in
    SkewBuilder config <|
        Builder.for animGroupName builder


build : SkewBuilder mode -> AnimBuilder mode
build (SkewBuilder config builder) =
    PropertyBuilder.upsert (Builder.SkewConfig (applyClamps builder config)) builder


applyClamps : AnimBuilder mode -> SkewConfig -> SkewConfig
applyClamps builder config =
    case Builder.getCurrentAnimGroupName builder of
        Nothing ->
            config

        Just animGroupName ->
            let
                cx =
                    Builder.getClamp animGroupName "skew" "x" builder

                cy =
                    Builder.getClamp animGroupName "skew" "y" builder
            in
            if cx == Nothing && cy == Nothing then
                config

            else
                let
                    clampValue value =
                        Skew.fromTuple
                            ( clampAxis cx (Skew.getX value)
                            , clampAxis cy (Skew.getY value)
                            )

                    clampedStart =
                        Maybe.map clampValue config.start

                    clampedEnd =
                        clampValue config.end

                    startForDistance =
                        Maybe.withDefault Skew.default clampedStart
                in
                { config
                    | start = clampedStart
                    , end = clampedEnd
                    , distance = Skew.distance startForDistance clampedEnd
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



-- ============================================================
-- BOUNDS
-- ============================================================


clampX : Float -> Float -> SkewBuilder mode -> SkewBuilder mode
clampX lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "skew" "x" lo hi)


clampY : Float -> Float -> SkewBuilder mode -> SkewBuilder mode
clampY lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "skew" "y" lo hi)


unclampX : SkewBuilder mode -> SkewBuilder mode
unclampX =
    updateBuilderClamp (\name -> Builder.clearClamp name "skew" "x")


unclampY : SkewBuilder mode -> SkewBuilder mode
unclampY =
    updateBuilderClamp (\name -> Builder.clearClamp name "skew" "y")


updateBuilderClamp : (String -> AnimBuilder mode -> AnimBuilder mode) -> SkewBuilder mode -> SkewBuilder mode
updateBuilderClamp f (SkewBuilder config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            SkewBuilder config (f animGroupName builder)

        Nothing ->
            SkewBuilder config builder
