module Anim.Internal.Builder.PerspectiveOrigin exposing
    ( PerspectiveOriginBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , percent
    , px
    , speed
    , to
    , toX
    , toY
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin exposing (PerspectiveOrigin, Unit(..))
import Easing exposing (Easing)



-- ============================================================
-- MODEL
-- ============================================================


type PerspectiveOriginBuilder
    = PerspectiveOriginBuilder Unit (Builder.AnimationConfig PerspectiveOrigin) AnimBuilder


type alias PerspectiveOriginConfig =
    Builder.AnimationConfig PerspectiveOrigin


defaultConfig : PerspectiveOriginConfig
defaultConfig =
    PropertyBuilder.defaultConfig PerspectiveOrigin.default



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder -> PerspectiveOriginBuilder
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
    PerspectiveOriginBuilder PxUnit config <|
        Builder.for animGroupName builder


build : PerspectiveOriginBuilder -> AnimBuilder
build (PerspectiveOriginBuilder _ config builder) =
    PropertyBuilder.upsert (Builder.PerspectiveOriginConfig config) builder



-- ============================================================
-- UNIT
-- ============================================================


{-| Set all values in this animation to pixels (default).
-}
px : PerspectiveOriginBuilder -> PerspectiveOriginBuilder
px (PerspectiveOriginBuilder _ config builder) =
    PerspectiveOriginBuilder PxUnit config builder


{-| Set all values in this animation to percentages.
-}
percent : PerspectiveOriginBuilder -> PerspectiveOriginBuilder
percent (PerspectiveOriginBuilder _ config builder) =
    PerspectiveOriginBuilder PercentUnit config builder



-- ============================================================
-- FROM
-- ============================================================


from : Float -> Float -> PerspectiveOriginBuilder -> PerspectiveOriginBuilder
from x y (PerspectiveOriginBuilder unit config builder) =
    PerspectiveOriginBuilder unit
        { config | start = Just (PerspectiveOrigin.fromRecord unit { x = x, y = y }) }
        builder



-- ============================================================
-- TO
-- ============================================================


to : Float -> Float -> PerspectiveOriginBuilder -> PerspectiveOriginBuilder
to x y (PerspectiveOriginBuilder unit config builder) =
    let
        origin =
            PerspectiveOrigin.fromRecord unit { x = x, y = y }

        start =
            Maybe.withDefault PerspectiveOrigin.default config.start
    in
    PerspectiveOriginBuilder unit
        { config
            | start = Just start
            , end = origin
            , distance = PerspectiveOrigin.distance start origin
        }
        builder


toX : Float -> PerspectiveOriginBuilder -> PerspectiveOriginBuilder
toX x (PerspectiveOriginBuilder unit config builder) =
    let
        y =
            PerspectiveOrigin.getY config.end
    in
    to x y (PerspectiveOriginBuilder unit config builder)


toY : Float -> PerspectiveOriginBuilder -> PerspectiveOriginBuilder
toY y (PerspectiveOriginBuilder unit config builder) =
    let
        x =
            PerspectiveOrigin.getX config.end
    in
    to x y (PerspectiveOriginBuilder unit config builder)



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> PerspectiveOriginBuilder -> PerspectiveOriginBuilder
delay delay_ (PerspectiveOriginBuilder unit config builder) =
    PerspectiveOriginBuilder unit (PropertyBuilder.delay delay_ config) builder


duration : Int -> PerspectiveOriginBuilder -> PerspectiveOriginBuilder
duration ms (PerspectiveOriginBuilder unit config builder) =
    PerspectiveOriginBuilder unit (PropertyBuilder.duration ms config) builder


speed : Float -> PerspectiveOriginBuilder -> PerspectiveOriginBuilder
speed value (PerspectiveOriginBuilder unit config builder) =
    PerspectiveOriginBuilder unit (PropertyBuilder.speed value config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> PerspectiveOriginBuilder -> PerspectiveOriginBuilder
easing easing_ (PerspectiveOriginBuilder unit config builder) =
    PerspectiveOriginBuilder unit (PropertyBuilder.easing easing_ config) builder
