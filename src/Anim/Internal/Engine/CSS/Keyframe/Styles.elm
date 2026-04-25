module Anim.Internal.Engine.CSS.Keyframe.Styles exposing
    ( baselineTransformParts
    , fromProcessedProperties
    , generateTransformComponents
    )

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.PropertyBuilder.Rotate as Rotate
import Anim.Internal.PropertyBuilder.Scale as Scale
import Anim.Internal.PropertyBuilder.Skew as Skew
import Anim.Internal.PropertyBuilder.Translate as Translate



-- ============================================================
-- GENERATORS
-- ============================================================


fromProcessedProperties : Maybe (List TransformProperty) -> Maybe PropertyBaselines -> List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedProperties maybeOrder maybeTargetValues baseStyles =
    Styles.fromProcessedProperties baseStyles <|
        extractTransformStyles maybeOrder maybeTargetValues


extractTransformStyles : Maybe (List TransformProperty) -> Maybe PropertyBaselines -> List Builder.ProcessedPropertyConfig -> List ( String, String )
extractTransformStyles maybeOrder maybeTargetValues processedProps =
    let
        transforms =
            processedProps
                |> Builder.extractTransformsFromProcessed
                |> mergeWithBaselines maybeTargetValues processedProps
                |> generateTransformComponents maybeOrder
                |> String.join " "
    in
    if String.isEmpty transforms then
        []

    else
        [ ( "transform", transforms ) ]



-- ============================================================
-- BASELINES
-- ============================================================


mergeWithBaselines : Maybe PropertyBaselines -> List Builder.ProcessedPropertyConfig -> Builder.TransformParts -> Builder.TransformParts
mergeWithBaselines maybeTargetValues processedProps animated =
    let
        baselines =
            baselineTransformParts maybeTargetValues processedProps

        selectOrBaseline accessor =
            if accessor animated /= "" then
                accessor animated

            else
                accessor baselines
    in
    { translate = selectOrBaseline .translate
    , rotate = selectOrBaseline .rotate
    , skew = selectOrBaseline .skew
    , scale = selectOrBaseline .scale
    }


baselineTransformParts : Maybe PropertyBaselines -> List Builder.ProcessedPropertyConfig -> Builder.TransformParts
baselineTransformParts maybeTargetValues processedProps =
    case maybeTargetValues of
        Nothing ->
            Builder.emptyTransformParts

        Just targets ->
            let
                baseline isAnimated maybeValue toCssString =
                    if List.any isAnimated processedProps then
                        ""

                    else
                        maybeValue
                            |> Maybe.map toCssString
                            |> Maybe.withDefault ""

                isTranslate p =
                    case p of
                        Builder.ProcessedTranslateConfig _ ->
                            True

                        _ ->
                            False

                isRotate p =
                    case p of
                        Builder.ProcessedRotateConfig _ ->
                            True

                        _ ->
                            False

                isScale p =
                    case p of
                        Builder.ProcessedScaleConfig _ ->
                            True

                        _ ->
                            False

                isSkew p =
                    case p of
                        Builder.ProcessedSkewConfig _ ->
                            True

                        _ ->
                            False
            in
            { translate = baseline isTranslate (PropertyBaselines.getTranslate targets) Translate.toCssString
            , rotate = baseline isRotate (PropertyBaselines.getRotate targets) Rotate.toCssString
            , skew = baseline isSkew (PropertyBaselines.getSkew targets) Skew.toCssString
            , scale = baseline isScale (PropertyBaselines.getScale targets) Scale.toCssString
            }



-- ============================================================
-- HELPERS
-- ============================================================


generateTransformComponents : Maybe (List TransformProperty) -> Builder.TransformParts -> List String
generateTransformComponents maybeOrder transformParts =
    List.filter (String.isEmpty >> not) <|
        case maybeOrder of
            Nothing ->
                [ transformParts.translate, transformParts.rotate, transformParts.skew, transformParts.scale ]

            Just order ->
                List.filterMap
                    (\o ->
                        let
                            part =
                                case o of
                                    Translate ->
                                        transformParts.translate

                                    Rotate ->
                                        transformParts.rotate

                                    Skew ->
                                        transformParts.skew

                                    Scale ->
                                        transformParts.scale
                        in
                        if part /= "" then
                            Just part

                        else
                            Nothing
                    )
                    order
