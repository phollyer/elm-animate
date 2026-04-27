module Anim.Internal.Engine.Transition.Styles exposing (fromProcessedProperties)

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate


fromProcessedProperties : List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedProperties baseStyles =
    Styles.fromProcessedProperties baseStyles extractTransformStyles


extractTransformStyles : List Builder.ProcessedPropertyConfig -> List ( String, String )
extractTransformStyles properties =
    let
        collected =
            List.foldl
                (\prop acc ->
                    case prop of
                        Builder.ProcessedTranslateConfig config ->
                            { acc | translate = Just ( "translate", Translate.toCssPropertyValue config.end ) }

                        Builder.ProcessedRotateConfig config ->
                            { acc | rotate = Rotate.toCssString config.end }

                        Builder.ProcessedSkewConfig config ->
                            { acc | skew = Skew.toCssString config.end }

                        Builder.ProcessedScaleConfig config ->
                            { acc | scale = Just ( "scale", Scale.toCssPropertyValue config.end ) }

                        _ ->
                            acc
                )
                { translate = Nothing, rotate = "", skew = "", scale = Nothing }
                properties

        transformPart =
            [ collected.rotate, collected.skew ]
                |> List.filter (String.isEmpty >> not)
                |> String.join " "

        transformStyle =
            if String.isEmpty transformPart then
                Nothing

            else
                Just ( "transform", transformPart )
    in
    List.filterMap identity
        [ collected.translate
        , transformStyle
        , collected.scale
        ]
