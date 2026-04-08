module Anim.Internal.Engine.Animation.WAAPI.Generator exposing (..)

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Animation.WAAPI.AnimGroup as AnimGroup exposing (AnimGroup, PropertySnapshot)


init : List Builder.PropertyConfig -> AnimGroup
init properties =
    let
        processedProps =
            Builder.processProperties Builder.initDefaults properties
    in
    AnimGroup.init
        |> AnimGroup.setSnpashot (endBounds processedProps)


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
