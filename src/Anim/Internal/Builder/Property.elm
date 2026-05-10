module Anim.Internal.Builder.Property exposing
    ( applyFrozenAxes
    , defaultConfig
    , delay
    , duration
    , easing
    , for
    , getCustomColorPropertyEnd
    , getCustomColorPropertyRange
    , getCustomColorPropertyStart
    , getCustomPropertyEnd
    , getCustomPropertyRange
    , getCustomPropertyStart
    , getFloat
    , getOpacityEnd
    , getOpacityRange
    , getOpacityStart
    , getPerspectiveOriginEnd
    , getPerspectiveOriginRange
    , getPerspectiveOriginStart
    , getRotateEnd
    , getRotateRange
    , getRotateStart
    , getScaleEnd
    , getScaleRange
    , getScaleStart
    , getSizeEnd
    , getSizeRange
    , getSizeStart
    , getSkewEnd
    , getSkewRange
    , getSkewStart
    , getTranslateEnd
    , getTranslateRange
    , getTranslateStart
    , speed
    , spring
    , upsert
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Extra.Color as Color exposing (Color)
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Motion.Easing as Easing exposing (Easing)
import Motion.Internal.Spring exposing (Spring)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- TYPES
-- ============================================================


type alias Config a =
    { start : Maybe a
    , end : a
    , easing : Maybe Easing
    , spring : Maybe Spring
    , delay : Maybe Int
    , timing : Maybe TimeSpec
    , distance : Float
    }


defaultConfig : a -> Config a
defaultConfig defaultEnd =
    { start = Nothing
    , end = defaultEnd
    , distance = 0
    , timing = Nothing
    , delay = Nothing
    , easing = Nothing
    , spring = Nothing
    }



-- ============================================================
-- BUILD
-- ============================================================


for : AnimGroupName -> (PropertyBaselines -> Maybe a) -> (Builder.PropertyConfig -> Maybe (Config a)) -> Config a -> AnimBuilder mode -> Config a
for animGroupName extractBaseline extractExisting defaultConfig_ builder =
    let
        -- Stored baseline: previous animation's end values (where the animation WAS GOING).
        -- Used for `end` so that non-targeted axes continue to their original targets.
        baselineValue =
            builder
                |> Builder.getBaseline animGroupName
                |> Maybe.andThen extractBaseline

        -- Runtime baseline: current mid-flight position (where the animation IS NOW).
        -- Used for `start` so new animations begin from the actual visual position.
        runtimeValue =
            builder
                |> Builder.getRuntimeBaseline animGroupName
                |> Maybe.andThen extractBaseline

        existingConfig =
            builder
                |> Builder.getAnimGroupConfig animGroupName
                |> Maybe.andThen
                    (.properties
                        >> List.filterMap extractExisting
                        >> List.head
                    )
    in
    case existingConfig of
        Just config ->
            applyGlobalDefaults builder
                { config
                    | start =
                        [ runtimeValue, baselineValue, Just config.end ]
                            |> List.filterMap identity
                            |> List.head
                    , end = config.end
                    , easing = Nothing
                    , spring = Nothing
                    , delay = Nothing
                    , timing = Nothing
                    , distance = 0
                }

        Nothing ->
            case ( runtimeValue, baselineValue ) of
                ( Just runtime, Just baseline ) ->
                    applyGlobalDefaults builder <|
                        { defaultConfig_
                            | start = Just runtime
                            , end = baseline
                        }

                ( Just runtime, Nothing ) ->
                    applyGlobalDefaults builder <|
                        { defaultConfig_
                            | start = Just runtime
                            , end = runtime
                        }

                ( Nothing, Just baseline ) ->
                    applyGlobalDefaults builder <|
                        { defaultConfig_
                            | start = Just baseline
                            , end = baseline
                        }

                ( Nothing, Nothing ) ->
                    applyGlobalDefaults builder defaultConfig_



-- ============================================================
-- UPDATE
-- ============================================================


upsert : Builder.PropertyConfig -> AnimBuilder mode -> AnimBuilder mode
upsert propertyConfig builder =
    case find (configsMatch propertyConfig) builder of
        Just _ ->
            replace propertyConfig builder

        Nothing ->
            add propertyConfig builder


add : Builder.PropertyConfig -> AnimBuilder mode -> AnimBuilder mode
add propertyConfig builder =
    let
        config =
            Builder.getCurrentAnimGroupConfig builder
    in
    Builder.updateCurrentConfig { config | properties = config.properties ++ [ propertyConfig ] } builder


replace : Builder.PropertyConfig -> AnimBuilder mode -> AnimBuilder mode
replace propertyConfig builder =
    let
        config =
            Builder.getCurrentAnimGroupConfig builder

        properties =
            List.filter (not << configsMatch propertyConfig) config.properties
                ++ [ propertyConfig ]
    in
    Builder.updateCurrentConfig { config | properties = properties } builder


find : (Builder.PropertyConfig -> Bool) -> AnimBuilder mode -> Maybe Builder.PropertyConfig
find predicate =
    Builder.getCurrentAnimGroupConfig
        >> .properties
        >> List.filter predicate
        >> List.head


configsMatch : Builder.PropertyConfig -> Builder.PropertyConfig -> Bool
configsMatch prop1 prop2 =
    case ( prop1, prop2 ) of
        ( Builder.CustomPropertyConfig name1 _ _, Builder.CustomPropertyConfig name2 _ _ ) ->
            name1 == name2

        ( Builder.CustomColorPropertyConfig name1 _, Builder.CustomColorPropertyConfig name2 _ ) ->
            name1 == name2

        ( Builder.OpacityConfig _, Builder.OpacityConfig _ ) ->
            True

        ( Builder.PerspectiveOriginConfig _, Builder.PerspectiveOriginConfig _ ) ->
            True

        ( Builder.RotateConfig _, Builder.RotateConfig _ ) ->
            True

        ( Builder.ScaleConfig _, Builder.ScaleConfig _ ) ->
            True

        ( Builder.SizeConfig _, Builder.SizeConfig _ ) ->
            True

        ( Builder.SkewConfig _, Builder.SkewConfig _ ) ->
            True

        ( Builder.TranslateConfig _, Builder.TranslateConfig _ ) ->
            True

        _ ->
            False


applyFrozenAxes :
    String
    -> (a -> { x : Float, y : Float, z : Float })
    -> ({ x : Float, y : Float, z : Float } -> a)
    -> (a -> a -> Float)
    -> AnimBuilder mode
    -> Config a
    -> Config a
applyFrozenAxes propertyName toRec fromRec calcDistance builder config =
    let
        frozenAxes =
            Builder.getFrozenAxes propertyName builder
    in
    if List.isEmpty frozenAxes then
        config

    else
        case config.start of
            Nothing ->
                config

            Just startVal ->
                let
                    startRecord =
                        toRec startVal

                    endRecord =
                        toRec config.end

                    end =
                        fromRec
                            { x =
                                if List.member "x" frozenAxes then
                                    startRecord.x

                                else
                                    endRecord.x
                            , y =
                                if List.member "y" frozenAxes then
                                    startRecord.y

                                else
                                    endRecord.y
                            , z =
                                if List.member "z" frozenAxes then
                                    startRecord.z

                                else
                                    endRecord.z
                            }
                in
                { config
                    | end = end
                    , distance = calcDistance startVal end
                }



-- ============================================================
-- GLOBAL DEFAULTS
-- ============================================================


applyGlobalDefaults :
    AnimBuilder mode
    -> { c | easing : Maybe Easing, spring : Maybe Spring, delay : Maybe Int, timing : Maybe TimeSpec }
    -> { c | easing : Maybe Easing, spring : Maybe Spring, delay : Maybe Int, timing : Maybe TimeSpec }
applyGlobalDefaults builder config =
    { config
        | easing =
            case config.easing of
                Just easing_ ->
                    Just easing_

                Nothing ->
                    Builder.getEasing builder
        , spring =
            case config.spring of
                Just spring_ ->
                    Just spring_

                Nothing ->
                    Builder.getSpring builder
        , delay =
            case config.delay of
                Just delay_ ->
                    Just delay_

                Nothing ->
                    Builder.getDelay builder
        , timing =
            case config.timing of
                Just timing_ ->
                    Just timing_

                Nothing ->
                    Builder.getTimeSpec builder
    }



-- ============================================================
-- TIMING
-- ============================================================


speed :
    Float
    -> { config | timing : Maybe TimeSpec }
    -> { config | timing : Maybe TimeSpec }
speed value config =
    { config | timing = Just <| Speed value }


duration :
    Int
    -> { config | timing : Maybe TimeSpec }
    -> { config | timing : Maybe TimeSpec }
duration ms config =
    { config | timing = Just <| Duration ms }


delay :
    Int
    -> { config | delay : Maybe Int }
    -> { config | delay : Maybe Int }
delay delay_ config =
    { config | delay = Just delay_ }



-- ============================================================
-- EASING
-- ============================================================


easing :
    Easing
    -> { config | easing : Maybe Easing, spring : Maybe Spring }
    -> { config | easing : Maybe Easing, spring : Maybe Spring }
easing easing_ config =
    { config | easing = Just easing_, spring = Nothing }



-- ============================================================
-- SPRING
-- ============================================================


spring :
    Spring
    -> { config | easing : Maybe Easing, spring : Maybe Spring }
    -> { config | easing : Maybe Easing, spring : Maybe Spring }
spring spring_ config =
    { config | spring = Just spring_, easing = Nothing }



-- ============================================================
-- GETTERS
-- ============================================================


getFloat : (t -> Float) -> Float -> Maybe t -> Float
getFloat getAxis default =
    Maybe.map getAxis
        >> Maybe.withDefault default


type alias AnimGroupName =
    String


getRange :
    (Builder.ProcessedPropertyConfig -> Maybe { start : Maybe a, end : a })
    -> AnimGroupName
    -> AnimBuilder mode
    -> Maybe { start : Maybe a, end : a }
getRange extractor animGroupName =
    Builder.getCurrentAnimationConfig animGroupName
        >> Maybe.andThen
            (.properties
                >> List.filterMap extractor
                >> List.head
            )


getStart :
    a
    -> (Builder.ProcessedPropertyConfig -> Maybe { start : Maybe a, end : a })
    -> AnimGroupName
    -> AnimBuilder mode
    -> Maybe a
getStart default extractor animGroupName =
    getRange extractor animGroupName
        >> Maybe.map
            (.start >> Maybe.withDefault default)


getEnd :
    (Builder.ProcessedPropertyConfig -> Maybe { start : Maybe a, end : a })
    -> AnimGroupName
    -> AnimBuilder mode
    -> Maybe a
getEnd extractor animGroupName =
    getRange extractor animGroupName
        >> Maybe.map .end



-- ============================
-- Custom Property
-- ============================


customPropertyExtractor : String -> Builder.ProcessedPropertyConfig -> Maybe { start : Maybe Float, end : Float }
customPropertyExtractor cssName prop =
    case prop of
        Builder.ProcessedCustomPropertyConfig name _ config ->
            if name == cssName then
                Just
                    { start = config.start
                    , end = config.end
                    }

            else
                Nothing

        _ ->
            Nothing


getCustomPropertyRange : AnimGroupName -> String -> AnimBuilder mode -> Maybe { start : Maybe Float, end : Float }
getCustomPropertyRange animGroupName cssName =
    getRange (customPropertyExtractor cssName) animGroupName


getCustomPropertyStart : AnimGroupName -> String -> AnimBuilder mode -> Maybe Float
getCustomPropertyStart animGroupName cssName =
    getStart 0 (customPropertyExtractor cssName) animGroupName


getCustomPropertyEnd : AnimGroupName -> String -> AnimBuilder mode -> Maybe Float
getCustomPropertyEnd animGroupName cssName =
    getEnd (customPropertyExtractor cssName) animGroupName



-- ============================
-- Custom Color Property
-- ============================


customColorPropertyExtractor : String -> Builder.ProcessedPropertyConfig -> Maybe { start : Maybe Color, end : Color }
customColorPropertyExtractor cssName prop =
    case prop of
        Builder.ProcessedCustomColorPropertyConfig name config ->
            if name == cssName then
                Just { start = config.start, end = config.end }

            else
                Nothing

        _ ->
            Nothing


getCustomColorPropertyRange : AnimGroupName -> String -> AnimBuilder mode -> Maybe { start : Maybe Color, end : Color }
getCustomColorPropertyRange animGroupName cssName =
    getRange (customColorPropertyExtractor cssName) animGroupName


getCustomColorPropertyStart : AnimGroupName -> String -> AnimBuilder mode -> Maybe Color
getCustomColorPropertyStart animGroupName cssName =
    getStart (Color.fromRGBA { r = 255, g = 255, b = 255, a = 0 }) (customColorPropertyExtractor cssName) animGroupName


getCustomColorPropertyEnd : AnimGroupName -> String -> AnimBuilder mode -> Maybe Color
getCustomColorPropertyEnd animGroupName cssName =
    getEnd (customColorPropertyExtractor cssName) animGroupName



-- ============================
-- Opacity
-- ============================


opacityExtractor : Builder.ProcessedPropertyConfig -> Maybe { start : Maybe Float, end : Float }
opacityExtractor prop =
    case prop of
        Builder.ProcessedOpacityConfig config ->
            Just
                { start = Maybe.map Opacity.toFloat config.start
                , end = Opacity.toFloat config.end
                }

        _ ->
            Nothing


getOpacityRange : AnimGroupName -> AnimBuilder mode -> Maybe { start : Maybe Float, end : Float }
getOpacityRange =
    getRange opacityExtractor


getOpacityStart : AnimGroupName -> AnimBuilder mode -> Maybe Float
getOpacityStart =
    getStart (Opacity.toFloat Opacity.default) opacityExtractor


getOpacityEnd : AnimGroupName -> AnimBuilder mode -> Maybe Float
getOpacityEnd =
    getEnd opacityExtractor



-- ============================
-- Rotate
-- ============================


rotateExtractor : Builder.ProcessedPropertyConfig -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
rotateExtractor prop =
    case prop of
        Builder.ProcessedRotateConfig config ->
            Just
                { start = Maybe.map Rotate.toRecord config.start
                , end = Rotate.toRecord config.end
                }

        _ ->
            Nothing


getRotateRange : AnimGroupName -> AnimBuilder mode -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange =
    getRange rotateExtractor


getRotateStart : AnimGroupName -> AnimBuilder mode -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    getStart (Rotate.toRecord Rotate.default) rotateExtractor


getRotateEnd : AnimGroupName -> AnimBuilder mode -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    getEnd rotateExtractor



-- ============================
-- Scale
-- ============================


scaleExtractor : Builder.ProcessedPropertyConfig -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
scaleExtractor prop =
    case prop of
        Builder.ProcessedScaleConfig config ->
            Just
                { start = Maybe.map Scale.toRecord config.start
                , end = Scale.toRecord config.end
                }

        _ ->
            Nothing


getScaleRange : AnimGroupName -> AnimBuilder mode -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange =
    getRange scaleExtractor


getScaleStart : AnimGroupName -> AnimBuilder mode -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    getStart (Scale.toRecord Scale.default) scaleExtractor


getScaleEnd : AnimGroupName -> AnimBuilder mode -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    getEnd scaleExtractor



-- ============================
-- Size
-- ============================


sizeExtractor : Builder.ProcessedPropertyConfig -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
sizeExtractor prop =
    case prop of
        Builder.ProcessedSizeConfig config ->
            Just
                { start = Maybe.map Size.toRecord config.start
                , end = Size.toRecord config.end
                }

        _ ->
            Nothing


getSizeRange : AnimGroupName -> AnimBuilder mode -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange =
    getRange sizeExtractor


getSizeStart : AnimGroupName -> AnimBuilder mode -> Maybe { width : Float, height : Float }
getSizeStart =
    getStart (Size.toRecord Size.default) sizeExtractor


getSizeEnd : AnimGroupName -> AnimBuilder mode -> Maybe { width : Float, height : Float }
getSizeEnd =
    getEnd sizeExtractor



-- ============================
-- PerspectiveOrigin
-- ============================


perspectiveOriginExtractor : Builder.ProcessedPropertyConfig -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
perspectiveOriginExtractor prop =
    case prop of
        Builder.ProcessedPerspectiveOriginConfig config ->
            Just
                { start = Maybe.map PerspectiveOrigin.toRecord config.start
                , end = PerspectiveOrigin.toRecord config.end
                }

        _ ->
            Nothing


getPerspectiveOriginRange : AnimGroupName -> AnimBuilder mode -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getPerspectiveOriginRange =
    getRange perspectiveOriginExtractor


getPerspectiveOriginStart : AnimGroupName -> AnimBuilder mode -> Maybe { x : Float, y : Float }
getPerspectiveOriginStart =
    getStart (PerspectiveOrigin.toRecord PerspectiveOrigin.default) perspectiveOriginExtractor


getPerspectiveOriginEnd : AnimGroupName -> AnimBuilder mode -> Maybe { x : Float, y : Float }
getPerspectiveOriginEnd =
    getEnd perspectiveOriginExtractor



-- ============================
-- Skew
-- ============================


skewExtractor : Builder.ProcessedPropertyConfig -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
skewExtractor prop =
    case prop of
        Builder.ProcessedSkewConfig config ->
            Just
                { start = Maybe.map Skew.toRecord config.start
                , end = Skew.toRecord config.end
                }

        _ ->
            Nothing


getSkewRange : AnimGroupName -> AnimBuilder mode -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange =
    getRange skewExtractor


getSkewStart : AnimGroupName -> AnimBuilder mode -> Maybe { x : Float, y : Float }
getSkewStart =
    getStart (Skew.toRecord Skew.default) skewExtractor


getSkewEnd : AnimGroupName -> AnimBuilder mode -> Maybe { x : Float, y : Float }
getSkewEnd =
    getEnd skewExtractor



-- ============================
-- Translate
-- ============================


translateExtractor : Builder.ProcessedPropertyConfig -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
translateExtractor prop =
    case prop of
        Builder.ProcessedTranslateConfig config ->
            Just
                { start = Maybe.map Translate.toRecord config.start
                , end = Translate.toRecord config.end
                }

        _ ->
            Nothing


getTranslateRange : AnimGroupName -> AnimBuilder mode -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange =
    getRange translateExtractor


getTranslateStart : AnimGroupName -> AnimBuilder mode -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    getStart (Translate.toRecord Translate.default) translateExtractor


getTranslateEnd : AnimGroupName -> AnimBuilder mode -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    getEnd translateExtractor
