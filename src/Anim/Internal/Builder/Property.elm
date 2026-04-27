module Anim.Internal.Builder.Property exposing
    ( defaultConfig
    , for
    , getColorPropertyEnd
    , getColorPropertyRange
    , getColorPropertyStart
    , getOpacityEnd
    , getOpacityRange
    , getOpacityStart
    , getPropertyEnd
    , getPropertyRange
    , getPropertyStart
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
    , upsert
    , withDelay
    , withDuration
    , withEasing
    , withSpeed
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builder.PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Extra.Color as Color exposing (Color)
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Easing exposing (Easing)
import Shared.TimeSpec exposing (TimeSpec(..))



-- ============================================================
-- MODEL
-- ============================================================


type alias Config a =
    { start : Maybe a
    , end : a
    , easing : Maybe Easing
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
    }



-- ============================================================
-- INITIALIZE
-- ============================================================


for : AnimGroupName -> (PropertyBaselines -> Maybe a) -> (Builder.PropertyConfig -> Maybe (Config a)) -> Config a -> AnimBuilder -> Config a
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


upsert : Builder.PropertyConfig -> AnimBuilder -> AnimBuilder
upsert propertyConfig builder =
    case find (configsMatch propertyConfig) builder of
        Just _ ->
            replace propertyConfig builder

        Nothing ->
            add propertyConfig builder


add : Builder.PropertyConfig -> AnimBuilder -> AnimBuilder
add propertyConfig builder =
    let
        config =
            Builder.getCurrentAnimGroupConfig builder

        updatedElement =
            { config | properties = config.properties ++ [ propertyConfig ] }
    in
    Builder.updateCurrentConfig updatedElement builder


replace : Builder.PropertyConfig -> AnimBuilder -> AnimBuilder
replace propertyConfig builder =
    let
        config =
            Builder.getCurrentAnimGroupConfig builder

        updatedProperties =
            List.filter (not << configsMatch propertyConfig) config.properties
                ++ [ propertyConfig ]
    in
    Builder.updateCurrentConfig { config | properties = updatedProperties } builder


find : (Builder.PropertyConfig -> Bool) -> AnimBuilder -> Maybe Builder.PropertyConfig
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



-- ============================================================
-- GLOBAL DEFAULTS
-- ============================================================


applyGlobalDefaults :
    AnimBuilder
    -> { c | easing : Maybe Easing, delay : Maybe Int, timing : Maybe TimeSpec }
    -> { c | easing : Maybe Easing, delay : Maybe Int, timing : Maybe TimeSpec }
applyGlobalDefaults builder config =
    { config
        | easing =
            case config.easing of
                Just easing_ ->
                    Just easing_

                Nothing ->
                    Builder.getEasing builder
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


withSpeed :
    Float
    -> { config | timing : Maybe TimeSpec }
    -> { config | timing : Maybe TimeSpec }
withSpeed value config =
    { config | timing = Just <| Speed value }


withDuration :
    Int
    -> { config | timing : Maybe TimeSpec }
    -> { config | timing : Maybe TimeSpec }
withDuration ms config =
    { config | timing = Just <| Duration ms }


withEasing :
    Easing
    -> { config | easing : Maybe Easing }
    -> { config | easing : Maybe Easing }
withEasing easing_ config =
    { config | easing = Just easing_ }


withDelay :
    Int
    -> { config | delay : Maybe Int }
    -> { config | delay : Maybe Int }
withDelay delay_ config =
    { config | delay = Just delay_ }



-- ============================================================
-- PROPERTY GETTERS
-- ============================================================


type alias AnimGroupName =
    String


getRange :
    (Builder.ProcessedPropertyConfig -> Maybe { start : Maybe a, end : a })
    -> AnimGroupName
    -> AnimBuilder
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
    -> AnimBuilder
    -> Maybe a
getStart default extractor animGroupName =
    getRange extractor animGroupName
        >> Maybe.map
            (.start >> Maybe.withDefault default)


getEnd :
    (Builder.ProcessedPropertyConfig -> Maybe { start : Maybe a, end : a })
    -> AnimGroupName
    -> AnimBuilder
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


getPropertyRange : AnimGroupName -> String -> AnimBuilder -> Maybe { start : Maybe Float, end : Float }
getPropertyRange animGroupName cssName =
    getRange (customPropertyExtractor cssName) animGroupName


getPropertyStart : AnimGroupName -> String -> AnimBuilder -> Maybe Float
getPropertyStart animGroupName cssName =
    getStart 0 (customPropertyExtractor cssName) animGroupName


getPropertyEnd : AnimGroupName -> String -> AnimBuilder -> Maybe Float
getPropertyEnd animGroupName cssName =
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


getColorPropertyRange : AnimGroupName -> String -> AnimBuilder -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange animGroupName cssName =
    getRange (customColorPropertyExtractor cssName) animGroupName


getColorPropertyStart : AnimGroupName -> String -> AnimBuilder -> Maybe Color
getColorPropertyStart animGroupName cssName =
    getStart (Color.fromRGBA { r = 255, g = 255, b = 255, a = 0 }) (customColorPropertyExtractor cssName) animGroupName


getColorPropertyEnd : AnimGroupName -> String -> AnimBuilder -> Maybe Color
getColorPropertyEnd animGroupName cssName =
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


getOpacityRange : AnimGroupName -> AnimBuilder -> Maybe { start : Maybe Float, end : Float }
getOpacityRange =
    getRange opacityExtractor


getOpacityStart : AnimGroupName -> AnimBuilder -> Maybe Float
getOpacityStart =
    getStart (Opacity.toFloat Opacity.default) opacityExtractor


getOpacityEnd : AnimGroupName -> AnimBuilder -> Maybe Float
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


getRotateRange : AnimGroupName -> AnimBuilder -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange =
    getRange rotateExtractor


getRotateStart : AnimGroupName -> AnimBuilder -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    getStart (Rotate.toRecord Rotate.default) rotateExtractor


getRotateEnd : AnimGroupName -> AnimBuilder -> Maybe { x : Float, y : Float, z : Float }
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


getScaleRange : AnimGroupName -> AnimBuilder -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange =
    getRange scaleExtractor


getScaleStart : AnimGroupName -> AnimBuilder -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    getStart (Scale.toRecord Scale.default) scaleExtractor


getScaleEnd : AnimGroupName -> AnimBuilder -> Maybe { x : Float, y : Float, z : Float }
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


getSizeRange : AnimGroupName -> AnimBuilder -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange =
    getRange sizeExtractor


getSizeStart : AnimGroupName -> AnimBuilder -> Maybe { width : Float, height : Float }
getSizeStart =
    getStart (Size.toRecord Size.default) sizeExtractor


getSizeEnd : AnimGroupName -> AnimBuilder -> Maybe { width : Float, height : Float }
getSizeEnd =
    getEnd sizeExtractor



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


getSkewRange : AnimGroupName -> AnimBuilder -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange =
    getRange skewExtractor


getSkewStart : AnimGroupName -> AnimBuilder -> Maybe { x : Float, y : Float }
getSkewStart =
    getStart (Skew.toRecord Skew.default) skewExtractor


getSkewEnd : AnimGroupName -> AnimBuilder -> Maybe { x : Float, y : Float }
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


getTranslateRange : AnimGroupName -> AnimBuilder -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange =
    getRange translateExtractor


getTranslateStart : AnimGroupName -> AnimBuilder -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    getStart (Translate.toRecord Translate.default) translateExtractor


getTranslateEnd : AnimGroupName -> AnimBuilder -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    getEnd translateExtractor
