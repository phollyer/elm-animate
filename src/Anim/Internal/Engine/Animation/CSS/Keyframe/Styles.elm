module Anim.Internal.Engine.Animation.CSS.Keyframe.Styles exposing (..)

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Animation.CSS.Styles as Styles exposing (Styles)


fromProcessedProperties : List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedProperties baseStyles processedProps =
    baseStyles
        ++ Styles.extractNonTransformStyles processedProps
        |> List.filter (\( _, value ) -> not (String.isEmpty value))
        |> Styles.fromList
