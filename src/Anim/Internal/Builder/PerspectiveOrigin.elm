module Anim.Internal.Builder.PerspectiveOrigin exposing
    ( PerspectiveOriginBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , fromX
    , fromXY
    , fromY
    , percent
    , px
    , speed
    , spring
    , to
    , toX
    , toXY
    , toY
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin exposing (PerspectiveOrigin, Unit(..))
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


type PerspectiveOriginBuilder mode
    = PerspectiveOriginBuilder Unit (Builder.AnimationConfig PerspectiveOrigin) (AnimBuilder mode)


type alias PerspectiveOriginConfig =
    Builder.AnimationConfig PerspectiveOrigin


default : Float
default =
    0.5


defaultConfig : PerspectiveOriginConfig
defaultConfig =
    PropertyBuilder.defaultConfig PerspectiveOrigin.default



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder mode -> PerspectiveOriginBuilder mode
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.PerspectiveOriginConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName PropertyBaselines.getPerspectiveOrigin extractExisting defaultConfig builder
    in
    PerspectiveOriginBuilder PercentUnit config <|
        Builder.for animGroupName builder


build : PerspectiveOriginBuilder mode -> AnimBuilder mode
build (PerspectiveOriginBuilder _ config builder) =
    PropertyBuilder.upsert (Builder.PerspectiveOriginConfig config) builder



-- ============================================================
-- UNIT
-- ============================================================


{-| Set all values in this animation to pixels (default).
-}
px : PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
px (PerspectiveOriginBuilder _ config builder) =
    PerspectiveOriginBuilder PxUnit config builder


{-| Set all values in this animation to percentages.
-}
percent : PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
percent (PerspectiveOriginBuilder _ config builder) =
    PerspectiveOriginBuilder PercentUnit config builder



-- ============================================================
-- FROM
-- ============================================================


from : PerspectiveOrigin -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
from perspectiveOrigin (PerspectiveOriginBuilder unit config builder) =
    PerspectiveOriginBuilder unit
        { config | start = Just perspectiveOrigin }
        builder


fromXY : Float -> Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
fromXY x y (PerspectiveOriginBuilder unit config builder) =
    from (PerspectiveOrigin.fromRecord unit { x = x, y = y }) <|
        PerspectiveOriginBuilder unit config builder


fromX : Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
fromX x (PerspectiveOriginBuilder unit config builder) =
    let
        y =
            PropertyBuilder.getFloat PerspectiveOrigin.getY default config.start
    in
    fromXY x y <|
        PerspectiveOriginBuilder unit config builder


fromY : Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
fromY y (PerspectiveOriginBuilder unit config builder) =
    let
        x =
            PropertyBuilder.getFloat PerspectiveOrigin.getX default config.start
    in
    fromXY x y <|
        PerspectiveOriginBuilder unit config builder



-- ============================================================
-- TO
-- ============================================================


to : PerspectiveOrigin -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
to perspectiveOrigin (PerspectiveOriginBuilder unit config builder) =
    let
        start =
            Maybe.withDefault PerspectiveOrigin.default config.start
    in
    PerspectiveOriginBuilder unit
        { config
            | start = Just start
            , end = perspectiveOrigin
            , distance = PerspectiveOrigin.distance start perspectiveOrigin
        }
        builder


toXY : Float -> Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
toXY x y (PerspectiveOriginBuilder unit config builder) =
    to (PerspectiveOrigin.fromRecord unit { x = x, y = y }) <|
        PerspectiveOriginBuilder unit config builder


toX : Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
toX x (PerspectiveOriginBuilder unit config builder) =
    let
        y =
            PerspectiveOrigin.getY config.end
    in
    toXY x y (PerspectiveOriginBuilder unit config builder)


toY : Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
toY y (PerspectiveOriginBuilder unit config builder) =
    let
        x =
            PerspectiveOrigin.getX config.end
    in
    toXY x y (PerspectiveOriginBuilder unit config builder)



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
delay delay_ (PerspectiveOriginBuilder unit config builder) =
    PerspectiveOriginBuilder unit (PropertyBuilder.delay delay_ config) builder


duration : Int -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
duration ms (PerspectiveOriginBuilder unit config builder) =
    PerspectiveOriginBuilder unit (PropertyBuilder.duration ms config) builder


speed : Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
speed value (PerspectiveOriginBuilder unit config builder) =
    PerspectiveOriginBuilder unit (PropertyBuilder.speed value config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
easing easing_ (PerspectiveOriginBuilder unit config builder) =
    PerspectiveOriginBuilder unit (PropertyBuilder.easing easing_ config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
spring s (PerspectiveOriginBuilder unit config builder) =
    PerspectiveOriginBuilder unit (PropertyBuilder.spring s config) builder
