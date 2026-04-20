module Anim.Internal.Engine.Animation.WAAPI.Generator exposing (..)

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups
import Anim.Internal.Engine.Animation.WAAPI.AnimGroup as AnimGroup exposing (AnimGroup, AnimationStatus(..))
import Dict exposing (Dict)



-- ============================================================
-- INITIALIZE
-- ============================================================


init : Dict String String -> Dict String Builder.DiscreteExitProperty -> List Builder.PropertyConfig -> AnimGroup
init discreteEntryProps discreteExitProps properties =
    let
        processedProps =
            Builder.processProperties Builder.initDefaults properties
    in
    AnimGroup.init
        |> AnimGroup.setSnapshot (endBounds processedProps)
        |> AnimGroup.setDiscreteEntry discreteEntryProps
        |> AnimGroup.setDiscreteExit discreteExitProps



-- ============================================================
-- GENERATORS
-- ============================================================


generateAnimation :
    Builder.Iterations
    -> Builder.AnimationDirection
    -> Maybe (List TransformProperty)
    -> Dict String String
    -> Dict String Builder.DiscreteExitProperty
    -> Maybe AnimGroup
    -> List Builder.ProcessedPropertyConfig
    -> AnimGroup
generateAnimation iterations animationDirection globalTransformOrder discreteEntryProps discreteExitProps existingAnimation properties =
    let
        animationEndStates =
            (propertyBounds properties).end

        snapshot =
            case existingAnimation of
                Just existing ->
                    PropertyBaselines.merge existing.propertySnapshot animationEndStates

                Nothing ->
                    animationEndStates

        existingPropertyVersions =
            existingAnimation
                |> Maybe.map .propertyStates
                |> Maybe.withDefault AnimGroups.init

        newPropertyVersions =
            properties
                |> List.map
                    (\property ->
                        let
                            propType =
                                propertyTypeString property

                            newVersion =
                                AnimGroups.get propType existingPropertyVersions
                                    |> Maybe.map .version
                                    |> Maybe.map ((+) 1)
                                    |> Maybe.withDefault 1
                        in
                        ( propType
                        , { version = newVersion
                          , status = NotStarted
                          }
                        )
                    )
                |> AnimGroups.fromList

        mergedPropertyVersions =
            AnimGroups.union newPropertyVersions existingPropertyVersions

        transformOrder =
            case globalTransformOrder of
                Just order ->
                    order

                Nothing ->
                    existingAnimation
                        |> Maybe.map .transformOrder
                        |> Maybe.withDefault TransformProperty.default
    in
    { propertySnapshot = snapshot
    , propertyStates = mergedPropertyVersions
    , transformOrder = transformOrder
    , progress = 0
    , iterations = iterations
    , animationDirection = animationDirection
    , discreteEntry = discreteEntryProps
    , discreteExit = discreteExitProps
    }



-- ============================================================
-- HELPERS
-- ============================================================


propertyTypeString : Builder.ProcessedPropertyConfig -> String
propertyTypeString property =
    case property of
        Builder.ProcessedTranslateConfig _ ->
            "translate"

        Builder.ProcessedRotateConfig _ ->
            "rotate"

        Builder.ProcessedScaleConfig _ ->
            "scale"

        Builder.ProcessedBackgroundColorConfig _ ->
            "backgroundColor"

        Builder.ProcessedFontColorConfig _ ->
            "fontColor"

        Builder.ProcessedOpacityConfig _ ->
            "opacity"

        Builder.ProcessedSizeConfig _ ->
            "size"

        Builder.ProcessedCustomPropertyConfig cssName _ _ ->
            "custom:" ++ cssName

        Builder.ProcessedCustomColorPropertyConfig cssName _ ->
            "customColor:" ++ cssName



-- ============================================================
-- PROPERTY BOUNDS
-- ============================================================


propertyBounds : List Builder.ProcessedPropertyConfig -> { start : PropertyBaselines, end : PropertyBaselines }
propertyBounds properties =
    let
        setBounds : Builder.ProcessedPropertyConfig -> { start : PropertyBaselines, end : PropertyBaselines } -> { start : PropertyBaselines, end : PropertyBaselines }
        setBounds property { start, end } =
            case property of
                Builder.ProcessedTranslateConfig config ->
                    { start = maybeSet PropertyBaselines.setTranslate config.start start, end = PropertyBaselines.setTranslate config.end end }

                Builder.ProcessedRotateConfig config ->
                    { start = maybeSet PropertyBaselines.setRotate config.start start, end = PropertyBaselines.setRotate config.end end }

                Builder.ProcessedScaleConfig config ->
                    { start = maybeSet PropertyBaselines.setScale config.start start, end = PropertyBaselines.setScale config.end end }

                Builder.ProcessedBackgroundColorConfig config ->
                    { start = maybeSet PropertyBaselines.setBackgroundColor config.start start, end = PropertyBaselines.setBackgroundColor config.end end }

                Builder.ProcessedFontColorConfig config ->
                    { start = maybeSet PropertyBaselines.setFontColor config.start start, end = PropertyBaselines.setFontColor config.end end }

                Builder.ProcessedOpacityConfig config ->
                    { start = maybeSet PropertyBaselines.setOpacity config.start start, end = PropertyBaselines.setOpacity config.end end }

                Builder.ProcessedSizeConfig config ->
                    { start = maybeSet PropertyBaselines.setSize config.start start, end = PropertyBaselines.setSize config.end end }

                Builder.ProcessedCustomPropertyConfig cssName _ config ->
                    { start = maybeSet (PropertyBaselines.setCustomProperty cssName) config.start start, end = PropertyBaselines.setCustomProperty cssName config.end end }

                Builder.ProcessedCustomColorPropertyConfig cssName config ->
                    { start = maybeSet (PropertyBaselines.setCustomColorProperty cssName) config.start start, end = PropertyBaselines.setCustomColorProperty cssName config.end end }
    in
    List.foldl setBounds { start = PropertyBaselines.empty, end = PropertyBaselines.empty } properties


maybeSet : (a -> PropertyBaselines -> PropertyBaselines) -> Maybe a -> PropertyBaselines -> PropertyBaselines
maybeSet setter maybeValue baselines =
    case maybeValue of
        Just value ->
            setter value baselines

        Nothing ->
            baselines


endBounds : List Builder.ProcessedPropertyConfig -> PropertyBaselines
endBounds properties =
    let
        setBounds : Builder.ProcessedPropertyConfig -> PropertyBaselines -> PropertyBaselines
        setBounds property end =
            case property of
                Builder.ProcessedTranslateConfig config ->
                    PropertyBaselines.setTranslate config.end end

                Builder.ProcessedRotateConfig config ->
                    PropertyBaselines.setRotate config.end end

                Builder.ProcessedScaleConfig config ->
                    PropertyBaselines.setScale config.end end

                Builder.ProcessedBackgroundColorConfig config ->
                    PropertyBaselines.setBackgroundColor config.end end

                Builder.ProcessedFontColorConfig config ->
                    PropertyBaselines.setFontColor config.end end

                Builder.ProcessedOpacityConfig config ->
                    PropertyBaselines.setOpacity config.end end

                Builder.ProcessedSizeConfig config ->
                    PropertyBaselines.setSize config.end end

                Builder.ProcessedCustomPropertyConfig cssName _ config ->
                    PropertyBaselines.setCustomProperty cssName config.end end

                Builder.ProcessedCustomColorPropertyConfig cssName config ->
                    PropertyBaselines.setCustomColorProperty cssName config.end end
    in
    List.foldl setBounds PropertyBaselines.empty properties
