module Anim.Internal.Engine.Animation.CSS.Transition.Styles exposing (..)

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Animation.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Translate as Translate


fromProcessedProperties : List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedProperties baseStyles processedProps =
    baseStyles
        ++ extractTransformPropertyStyles processedProps
        ++ Styles.extractNonTransformStyles processedProps
        |> List.filter (\( _, value ) -> not (String.isEmpty value))
        |> Styles.fromList


fromStaticProperties : List Builder.ProcessedPropertyConfig -> Styles
fromStaticProperties processedProps =
    ( "transition", "none" )
        :: extractTransformPropertyStyles processedProps
        ++ Styles.extractNonTransformStyles processedProps
        |> List.filter (\( key, value ) -> key == "transition" || not (String.isEmpty value))
        |> Styles.fromList


extractTransformPropertyStyles : List Builder.ProcessedPropertyConfig -> List ( String, String )
extractTransformPropertyStyles =
    List.filterMap
        (\prop ->
            case prop of
                Builder.ProcessedTranslateConfig config ->
                    Just ( "translate", Translate.toCssPropertyValue config.end )

                Builder.ProcessedRotateConfig config ->
                    Just ( "transform", Rotate.toCssString config.end )

                Builder.ProcessedScaleConfig config ->
                    Just ( "scale", Scale.toCssPropertyValue config.end )

                _ ->
                    Nothing
        )
