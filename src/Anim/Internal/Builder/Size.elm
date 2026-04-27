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
-- TYPES
-- ============================================================


type SizeBuilder
    = SizeBuilder (Builder.AnimationConfig Size) AnimBuilder



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


type alias SizeConfig =
    Builder.AnimationConfig Size


defaultConfig : SizeConfig
defaultConfig =
    PropertyBuilder.defaultConfig <|
        Size.fromTuple ( 0, 0 )


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
fromH height (SizeBuilder config builder) =
    let
        currentSize =
            config.start
                |> Maybe.withDefault (Size.fromTuple ( 0, 0 ))

        ( currentWidth, _ ) =
            Size.toTuple currentSize
    in
    SizeBuilder
        { config
            | start =
                Just <|
                    Size.fromTuple ( currentWidth, height )
        }
        builder


fromW : Float -> SizeBuilder -> SizeBuilder
fromW width (SizeBuilder config builder) =
    let
        currentSize =
            config.start
                |> Maybe.withDefault (Size.fromTuple ( 0, 0 ))

        ( _, currentHeight ) =
            Size.toTuple currentSize
    in
    SizeBuilder
        { config
            | start =
                Just <|
                    Size.fromTuple ( width, currentHeight )
        }
        builder



-- ============================================================
-- TO
-- ============================================================


to : Size -> SizeBuilder -> SizeBuilder
to size (SizeBuilder config builder) =
    let
        startVal =
            case config.start of
                Just s ->
                    s

                Nothing ->
                    Size.default
    in
    SizeBuilder
        { config
            | start = Just startVal
            , end = size
            , distance = Size.distance startVal size
        }
        builder


toHW : Float -> Float -> SizeBuilder -> SizeBuilder
toHW height width =
    to (Size.fromTuple ( width, height ))


toH : Float -> SizeBuilder -> SizeBuilder
toH height (SizeBuilder config builder) =
    let
        ( currentTargetWidth, _ ) =
            Size.toTuple config.end
    in
    to (Size.fromTuple ( currentTargetWidth, height )) (SizeBuilder config builder)


toW : Float -> SizeBuilder -> SizeBuilder
toW width (SizeBuilder config builder) =
    let
        ( _, currentTargetHeight ) =
            Size.toTuple config.end
    in
    to (Size.fromTuple ( width, currentTargetHeight )) (SizeBuilder config builder)



-- ============================================================
-- TIMING
-- ============================================================


speed : Float -> SizeBuilder -> SizeBuilder
speed pixelsPerSecond (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.withSpeed pixelsPerSecond config) builder


duration : Int -> SizeBuilder -> SizeBuilder
duration ms (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.withDuration ms config) builder


easing : Easing -> SizeBuilder -> SizeBuilder
easing easingFunction (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.withEasing easingFunction config) builder


delay : Int -> SizeBuilder -> SizeBuilder
delay ms (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.withDelay ms config) builder
