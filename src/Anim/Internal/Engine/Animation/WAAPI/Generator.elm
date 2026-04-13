module Anim.Internal.Engine.Animation.WAAPI.Generator exposing (..)

import Anim.Extra.TransformOrder as TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups
import Anim.Internal.Engine.Animation.WAAPI.AnimGroup as AnimGroup exposing (AnimGroup, AnimationStatus(..), PropertySnapshot)
import Dict exposing (Dict)


init : Dict String String -> Dict String Builder.DiscreteKeyframeProperty -> List Builder.PropertyConfig -> AnimGroup
init discreteEntryProps discreteExitProps properties =
    let
        processedProps =
            Builder.processProperties Builder.initDefaults properties
    in
    AnimGroup.init
        |> AnimGroup.setSnpashot (endBounds processedProps)
        |> AnimGroup.setDiscreteEntry discreteEntryProps
        |> AnimGroup.setDiscreteExit discreteExitProps


generateAnimation :
    Maybe (List TransformProperty)
    -> Dict String String
    -> Dict String Builder.DiscreteKeyframeProperty
    -> Maybe AnimGroup
    -> List Builder.ProcessedPropertyConfig
    -> AnimGroup
generateAnimation globalTransformOrder discreteEntryProps discreteExitProps existingAnimation properties =
    let
        animationEndStates =
            (propertyBounds properties).end

        snapshot =
            case existingAnimation of
                Just existing ->
                    mergeSnapshots existing.propertySnapshot animationEndStates

                Nothing ->
                    animationEndStates

        existingPropertyVersions =
            existingAnimation
                |> Maybe.map .properties
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
                        |> Maybe.withDefault TransformOrder.default
    in
    { propertySnapshot = snapshot
    , properties = mergedPropertyVersions
    , transformOrder = transformOrder
    , progress = 0
    , discreteEntry = discreteEntryProps
    , discreteExit = discreteExitProps
    }


mergeSnapshots : PropertySnapshot -> PropertySnapshot -> PropertySnapshot
mergeSnapshots old new =
    let
        orElse newer older =
            case newer of
                Just _ ->
                    newer

                Nothing ->
                    older
    in
    { translate = orElse new.translate old.translate
    , rotate = orElse new.rotate old.rotate
    , scale = orElse new.scale old.scale
    , backgroundColor = orElse new.backgroundColor old.backgroundColor
    , fontColor = orElse new.fontColor old.fontColor
    , opacity = orElse new.opacity old.opacity
    , size = orElse new.size old.size
    }


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


propertyBounds : List Builder.ProcessedPropertyConfig -> { start : PropertySnapshot, end : PropertySnapshot }
propertyBounds properties =
    let
        setBounds : Builder.ProcessedPropertyConfig -> { start : PropertySnapshot, end : PropertySnapshot } -> { start : PropertySnapshot, end : PropertySnapshot }
        setBounds property { start, end } =
            case property of
                Builder.ProcessedTranslateConfig config ->
                    { start = { start | translate = config.start }, end = { end | translate = Just config.end } }

                Builder.ProcessedRotateConfig config ->
                    { start = { start | rotate = config.start }, end = { end | rotate = Just config.end } }

                Builder.ProcessedScaleConfig config ->
                    { start = { start | scale = config.start }, end = { end | scale = Just config.end } }

                Builder.ProcessedBackgroundColorConfig config ->
                    { start = { start | backgroundColor = config.start }, end = { end | backgroundColor = Just config.end } }

                Builder.ProcessedFontColorConfig config ->
                    { start = { start | fontColor = config.start }, end = { end | fontColor = Just config.end } }

                Builder.ProcessedOpacityConfig config ->
                    { start = { start | opacity = config.start }, end = { end | opacity = Just config.end } }

                Builder.ProcessedSizeConfig config ->
                    { start = { start | size = config.start }, end = { end | size = Just config.end } }
    in
    List.foldl setBounds { start = AnimGroup.emptySnapshot, end = AnimGroup.emptySnapshot } properties


endBounds : List Builder.ProcessedPropertyConfig -> PropertySnapshot
endBounds properties =
    let
        setBounds : Builder.ProcessedPropertyConfig -> PropertySnapshot -> PropertySnapshot
        setBounds property end =
            case property of
                Builder.ProcessedTranslateConfig config ->
                    { end | translate = Just config.end }

                Builder.ProcessedRotateConfig config ->
                    { end | rotate = Just config.end }

                Builder.ProcessedScaleConfig config ->
                    { end | scale = Just config.end }

                Builder.ProcessedBackgroundColorConfig config ->
                    { end | backgroundColor = Just config.end }

                Builder.ProcessedFontColorConfig config ->
                    { end | fontColor = Just config.end }

                Builder.ProcessedOpacityConfig config ->
                    { end | opacity = Just config.end }

                Builder.ProcessedSizeConfig config ->
                    { end | size = Just config.end }
    in
    List.foldl setBounds AnimGroup.emptySnapshot properties
