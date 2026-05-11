module Anim.Internal.Builder.Size exposing
    ( SizeBuilder
    , build
    , clampHeight
    , clampWidth
    , delay
    , duration
    , easing
    , for
    , from
    , fromH
    , fromHW
    , fromW
    , speed
    , spring
    , to
    , toH
    , toHW
    , toW
    , unclampHeight
    , unclampWidth
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.Property as PropertyBuilder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines
import Anim.Internal.Property.Size as Size exposing (Size)
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type SizeBuilder mode
    = SizeBuilder (Builder.AnimationConfig Size) (AnimBuilder mode)


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


for : String -> AnimBuilder mode -> SizeBuilder mode
for animGroupName builder =
    let
        extractExisting propertyConfig =
            case propertyConfig of
                Builder.SizeConfig cfg ->
                    Just cfg

                _ ->
                    Nothing

        config =
            PropertyBuilder.for animGroupName "size" PropertyBaselines.getSize extractExisting defaultConfig builder
    in
    SizeBuilder config <|
        Builder.for animGroupName builder


build : SizeBuilder mode -> AnimBuilder mode
build (SizeBuilder config builder) =
    PropertyBuilder.upsert (Builder.SizeConfig (applyClamps builder config)) builder


applyClamps : AnimBuilder mode -> SizeConfig -> SizeConfig
applyClamps builder config =
    case Builder.getCurrentAnimGroupName builder of
        Nothing ->
            config

        Just animGroupName ->
            let
                cw =
                    Builder.getClamp animGroupName "size" "width" builder

                ch =
                    Builder.getClamp animGroupName "size" "height" builder
            in
            if cw == Nothing && ch == Nothing then
                config

            else
                let
                    clampValue value =
                        let
                            r =
                                Size.toRecord value
                        in
                        Size.fromRecord
                            { width = clampAxis cw r.width
                            , height = clampAxis ch r.height
                            }

                    clampedStart =
                        Maybe.map clampValue config.start

                    clampedEnd =
                        clampValue config.end

                    startForDistance =
                        Maybe.withDefault Size.default clampedStart
                in
                { config
                    | start = clampedStart
                    , end = clampedEnd
                    , distance = Size.distance startForDistance clampedEnd
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


from : Size -> SizeBuilder mode -> SizeBuilder mode
from size (SizeBuilder config builder) =
    SizeBuilder
        { config | start = Just size }
        builder


fromHW : Float -> Float -> SizeBuilder mode -> SizeBuilder mode
fromHW height width (SizeBuilder config builder) =
    SizeBuilder
        { config
            | start =
                Just <|
                    Size.fromTuple ( width, height )
        }
        builder


fromH : Float -> SizeBuilder mode -> SizeBuilder mode
fromH h (SizeBuilder config builder) =
    let
        w =
            PropertyBuilder.getFloat Size.getW default config.start
    in
    fromHW h w (SizeBuilder config builder)


fromW : Float -> SizeBuilder mode -> SizeBuilder mode
fromW w (SizeBuilder config builder) =
    let
        h =
            PropertyBuilder.getFloat Size.getH default config.start
    in
    fromHW h w (SizeBuilder config builder)



-- ============================================================
-- TO
-- ============================================================


to : Size -> SizeBuilder mode -> SizeBuilder mode
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


toHW : Float -> Float -> SizeBuilder mode -> SizeBuilder mode
toHW height width =
    to (Size.fromTuple ( width, height ))


toH : Float -> SizeBuilder mode -> SizeBuilder mode
toH h (SizeBuilder config builder) =
    let
        w =
            Size.getW config.end
    in
    toHW h w (SizeBuilder config builder)


toW : Float -> SizeBuilder mode -> SizeBuilder mode
toW w (SizeBuilder config builder) =
    let
        h =
            Size.getH config.end
    in
    toHW h w (SizeBuilder config builder)



-- ============================================================
-- TIMING
-- ============================================================


delay : Int -> SizeBuilder mode -> SizeBuilder mode
delay ms (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.delay ms config) builder


duration : Int -> SizeBuilder mode -> SizeBuilder mode
duration ms (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.duration ms config) builder


speed : Float -> SizeBuilder mode -> SizeBuilder mode
speed pixelsPerSecond (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.speed pixelsPerSecond config) builder



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> SizeBuilder mode -> SizeBuilder mode
easing easingFunction (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.easing easingFunction config) builder



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> SizeBuilder mode -> SizeBuilder mode
spring s (SizeBuilder config builder) =
    SizeBuilder (PropertyBuilder.spring s config) builder



-- ============================================================
-- BOUNDS
-- ============================================================


clampWidth : Float -> Float -> SizeBuilder mode -> SizeBuilder mode
clampWidth lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "size" "width" lo hi)


clampHeight : Float -> Float -> SizeBuilder mode -> SizeBuilder mode
clampHeight lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "size" "height" lo hi)


unclampWidth : SizeBuilder mode -> SizeBuilder mode
unclampWidth =
    updateBuilderClamp (\name -> Builder.clearClamp name "size" "width")


unclampHeight : SizeBuilder mode -> SizeBuilder mode
unclampHeight =
    updateBuilderClamp (\name -> Builder.clearClamp name "size" "height")


updateBuilderClamp : (String -> AnimBuilder mode -> AnimBuilder mode) -> SizeBuilder mode -> SizeBuilder mode
updateBuilderClamp f (SizeBuilder config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            SizeBuilder config (f animGroupName builder)

        Nothing ->
            SizeBuilder config builder
