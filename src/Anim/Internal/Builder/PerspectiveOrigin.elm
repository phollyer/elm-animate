module Anim.Internal.Builder.PerspectiveOrigin exposing
    ( PerspectiveOriginBuilder
    , build
    , clampX
    , clampY
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
    , unclampX
    , unclampY
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
            PropertyBuilder.for animGroupName "perspectiveOrigin" PropertyBaselines.getPerspectiveOrigin extractExisting defaultConfig builder
    in
    PerspectiveOriginBuilder PercentUnit config <|
        Builder.for animGroupName builder


build : PerspectiveOriginBuilder mode -> AnimBuilder mode
build (PerspectiveOriginBuilder _ config builder) =
    PropertyBuilder.upsert (Builder.PerspectiveOriginConfig (applyClamps builder config)) builder


applyClamps : AnimBuilder mode -> PerspectiveOriginConfig -> PerspectiveOriginConfig
applyClamps builder config =
    case Builder.getCurrentAnimGroupName builder of
        Nothing ->
            config

        Just animGroupName ->
            let
                cx =
                    Builder.getClamp animGroupName "perspectiveOrigin" "x" builder

                cy =
                    Builder.getClamp animGroupName "perspectiveOrigin" "y" builder
            in
            if cx == Nothing && cy == Nothing then
                config

            else
                let
                    clampValue value =
                        let
                            r =
                                PerspectiveOrigin.toRecord value
                        in
                        PerspectiveOrigin.fromRecord (PerspectiveOrigin.getUnit value)
                            { x = clampAxis cx r.x
                            , y = clampAxis cy r.y
                            }

                    clampedStart =
                        Maybe.map clampValue config.start

                    clampedEnd =
                        clampValue config.end

                    startForDistance =
                        Maybe.withDefault PerspectiveOrigin.default clampedStart
                in
                { config
                    | start = clampedStart
                    , end = clampedEnd
                    , distance = PerspectiveOrigin.distance startForDistance clampedEnd
                }


clampAxis : Maybe ( Float, Float ) -> Float -> Float
clampAxis range v =
    case range of
        Just ( lo, hi ) ->
            clamp lo hi v

        Nothing ->
            v



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



-- ============================================================
-- BOUNDS
-- ============================================================


clampX : Float -> Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
clampX lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "perspectiveOrigin" "x" lo hi)


clampY : Float -> Float -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
clampY lo hi =
    updateBuilderClamp (\name -> Builder.setClamp name "perspectiveOrigin" "y" lo hi)


unclampX : PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
unclampX =
    updateBuilderClamp (\name -> Builder.clearClamp name "perspectiveOrigin" "x")


unclampY : PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
unclampY =
    updateBuilderClamp (\name -> Builder.clearClamp name "perspectiveOrigin" "y")


updateBuilderClamp : (String -> AnimBuilder mode -> AnimBuilder mode) -> PerspectiveOriginBuilder mode -> PerspectiveOriginBuilder mode
updateBuilderClamp f (PerspectiveOriginBuilder unit config builder) =
    case Builder.getCurrentAnimGroupName builder of
        Just animGroupName ->
            PerspectiveOriginBuilder unit config (f animGroupName builder)

        Nothing ->
            PerspectiveOriginBuilder unit config builder
