module Anim.Internal.Builder.Size exposing
    ( SizeBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , fromH
    , fromHW
    , fromW
    , speed
    , to
    , toH
    , toHW
    , toW
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.Size as Size exposing (Size)
import Easing exposing (Easing)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- MODEL
-- ============================================================


type SizeBuilder
    = SizeBuilder (Builder.AnimationConfig Size) AnimBuilder


type alias SizeConfig =
    Builder.AnimationConfig Size


default : Float
default =
    0.0


defaultConfig : SizeConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        Size.fromTuple ( default, default )



-- ============================================================
-- BUILD
-- ============================================================


for : String -> AnimBuilder -> SizeBuilder
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.SizeConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName PropertyBaselines.getSize extractExisting defaultConfig builder
    in
    SizeBuilder config <|
        Builder.for animGroupName builder


build : SizeBuilder -> AnimBuilder
build (SizeBuilder config builder) =
    PropertyBuilder.upsert (Builder.SizeConfig config) builder



-- ============================================================
-- FROM
-- ============================================================


from : Size -> SizeBuilder -> SizeBuilder
from size (SizeBuilder config builder) =
    SizeBuilder
        { config | start = Just size }
        builder


fromHW : Float -> Float -> SizeBuilder -> SizeBuilder
fromHW height width (SizeBuilder config builder) =
    SizeBuilder
        { config
            | start =
                Just <|
                    Size.fromTuple ( width, height )
        }
        builder


fromH : Float -> SizeBuilder -> SizeBuilder
fromH h (SizeBuilder config builder) =
    let
        w =
            PropertyBuilder.getFloat Size.getW default config.start
    in
    fromHW h w (SizeBuilder config builder)


fromW : Float -> SizeBuilder -> SizeBuilder
fromW w (SizeBuilder config builder) =
    let
        h =
            PropertyBuilder.getFloat Size.getH default config.start
    in
    fromHW h w (SizeBuilder config builder)



-- ============================================================
-- TO
-- ============================================================


to : Size -> SizeBuilder -> SizeBuilder
to size (SizeBuilder config builder) =
    let
        start =
            Maybe.withDefault Size.default config.start
    in
    SizeBuilder
        { config
            | start = Just start
            , end = size
            , distance = Size.distance start size
        }
        builder


toHW : Float -> Float -> SizeBuilder -> SizeBuilder
toHW height width =
    to (Size.fromTuple ( width, height ))


toH : Float -> SizeBuilder -> SizeBuilder
toH h (SizeBuilder config builder) =
    let
        w =
            Size.getW config.end
    in
    toHW h w (SizeBuilder config builder)


toW : Float -> SizeBuilder -> SizeBuilder
toW w (SizeBuilder config builder) =
    let
        h =
            Size.getH config.end
    in
    toHW h w (SizeBuilder config builder)



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> SizeBuilder -> SizeBuilder
delay ms (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.delay ms config) builder


duration : Int -> SizeBuilder -> SizeBuilder
duration ms (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> SizeBuilder -> SizeBuilder
speed pixelsPerSecond (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.speed pixelsPerSecond config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> SizeBuilder -> SizeBuilder
easing easingFunction (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.easing easingFunction config) builder
