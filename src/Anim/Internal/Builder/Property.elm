module Anim.Internal.Builder.Property exposing
    ( applyGlobalDefaults
    , defaultConfig
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
import Anim.Internal.PropertyBuilder.Opacity as Opacity
import Anim.Internal.PropertyBuilder.Rotate as Rotate
import Anim.Internal.PropertyBuilder.Scale as Scale
import Anim.Internal.PropertyBuilder.Size as Size
import Anim.Internal.PropertyBuilder.Translate as Translate
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Easing exposing (Easing)



-- ============================================================
-- TYPE
-- ============================================================


type alias Config a =
    { start : Maybe a
    , end : a
    , easing : Maybe Easing
    , delay : Maybe Int
    , timing : Maybe TimeSpec
    , distance : Float
    }



-- ============================================================
-- INITIALIZE
-- ============================================================


defaultConfig : a -> Config a
defaultConfig defaultEnd =
    { start = Nothing
    , end = defaultEnd
    , distance = 0
    , timing = Nothing
    , delay = Nothing
    , easing = Nothing
    }


for : AnimGroupName -> (PropertyBaselines -> Maybe a) -> (Builder.PropertyConfig -> Maybe (Config a)) -> Config a -> AnimBuilder -> Config a
for animGroupName extractBaseline extractExisting defaultConfig_ builder =
    let
        -- Stored baseline: previous animation's end values (where the element WAS GOING).
        -- Used for `end` so that non-targeted axes continue to their original targets.
        baselineValue =
            builder
                |> Builder.getBaseline animGroupName
                |> Maybe.andThen extractBaseline

        -- Runtime baseline: current mid-flight position (where the element IS NOW).
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
                    applyGlobalDefaults builder { defaultConfig_ | start = Just runtime, end = baseline }

                ( Just runtime, Nothing ) ->
                    applyGlobalDefaults builder { defaultConfig_ | start = Just runtime, end = runtime }

                ( Nothing, Just baseline ) ->
                    applyGlobalDefaults builder { defaultConfig_ | start = Just baseline, end = baseline }

                ( Nothing, Nothing ) ->
                    applyGlobalDefaults builder defaultConfig_



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
-- PROPERTY LIST OPERATIONS
-- ============================================================


add : Builder.PropertyConfig -> AnimBuilder -> AnimBuilder
add propertyConfig builder =
    let
        currentElement =
            Builder.getCurrentElementConfig builder

        updatedElement =
            { currentElement | properties = currentElement.properties ++ [ propertyConfig ] }
    in
    Builder.updateCurrentElement updatedElement builder


replace : Builder.PropertyConfig -> AnimBuilder -> AnimBuilder
replace propertyConfig builder =
    let
        currentElement =
            Builder.getCurrentElementConfig builder

        updatedProperties =
            List.filter (not << configsMatch propertyConfig) currentElement.properties
                ++ [ propertyConfig ]

        updatedElement =
            { currentElement | properties = updatedProperties }
    in
    Builder.updateCurrentElement updatedElement builder


upsert : Builder.PropertyConfig -> AnimBuilder -> AnimBuilder
upsert propertyConfig builder =
    case find (configsMatch propertyConfig) builder of
        Just _ ->
            replace propertyConfig builder

        Nothing ->
            add propertyConfig builder


find : (Builder.PropertyConfig -> Bool) -> AnimBuilder -> Maybe Builder.PropertyConfig
find predicate builder =
    let
        currentElement =
            Builder.getCurrentElementConfig builder
    in
    List.head (List.filter predicate currentElement.properties)


configsMatch : Builder.PropertyConfig -> Builder.PropertyConfig -> Bool
configsMatch prop1 prop2 =
    case ( prop1, prop2 ) of
        ( Builder.TranslateConfig _, Builder.TranslateConfig _ ) ->
            True

        ( Builder.RotateConfig _, Builder.RotateConfig _ ) ->
            True

        ( Builder.ScaleConfig _, Builder.ScaleConfig _ ) ->
            True

        ( Builder.SkewConfig _, Builder.SkewConfig _ ) ->
            True

        ( Builder.BackgroundColorConfig _, Builder.BackgroundColorConfig _ ) ->
            True

        ( Builder.OpacityConfig _, Builder.OpacityConfig _ ) ->
            True

        ( Builder.SizeConfig _, Builder.SizeConfig _ ) ->
            True

        ( Builder.CustomPropertyConfig name1 _ _, Builder.CustomPropertyConfig name2 _ _ ) ->
            name1 == name2

        ( Builder.CustomColorPropertyConfig name1 _, Builder.CustomColorPropertyConfig name2 _ ) ->
            name1 == name2

        _ ->
            False



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
getRange extractor animGroupName builder =
    Builder.getCurrentAnimationConfig animGroupName builder
        |> Maybe.andThen
            (\{ properties } ->
                properties
                    |> List.filterMap extractor
                    |> List.head
            )


getStart :
    a
    -> (Builder.ProcessedPropertyConfig -> Maybe { start : Maybe a, end : a })
    -> AnimGroupName
    -> AnimBuilder
    -> Maybe a
getStart default extractor animGroupName builder =
    getRange extractor animGroupName builder
        |> Maybe.map
            (\{ start } ->
                Maybe.withDefault default start
            )


getEnd :
    (Builder.ProcessedPropertyConfig -> Maybe { start : Maybe a, end : a })
    -> AnimGroupName
    -> AnimBuilder
    -> Maybe a
getEnd extractor animGroupName builder =
    getRange extractor animGroupName builder
        |> Maybe.map .end



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
