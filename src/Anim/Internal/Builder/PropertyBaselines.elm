module Anim.Internal.Builder.PropertyBaselines exposing
    ( PropertyBaselines
    , empty
    , getBackgroundColor
    , getFontColor
    , getOpacity
    , getRotate
    , getScale
    , getSize
    , getTranslate
    , merge
    , setBackgroundColor
    , setFontColor
    , setOpacity
    , setRotate
    , setScale
    , setSize
    , setTranslate
    )

import Anim.Internal.Extra.Color exposing (Color)
import Anim.Internal.Property.Opacity exposing (Opacity)
import Anim.Internal.Property.Rotate exposing (Rotate)
import Anim.Internal.Property.Scale exposing (Scale)
import Anim.Internal.Property.Size exposing (Size)
import Anim.Internal.Property.Translate exposing (Translate)
import Dict exposing (Dict)


type PropertyBaselines
    = PropertyBaselines (Dict String PropertyValue)


type PropertyValue
    = TranslateValue Translate
    | RotateValue Rotate
    | ScaleValue Scale
    | BackgroundColorValue Color
    | FontColorValue Color
    | OpacityValue Opacity
    | SizeValue Size


empty : PropertyBaselines
empty =
    PropertyBaselines Dict.empty


{-| Merge two PropertyBaselines. The second argument takes precedence.
-}
merge : PropertyBaselines -> PropertyBaselines -> PropertyBaselines
merge (PropertyBaselines base) (PropertyBaselines override) =
    PropertyBaselines (Dict.union override base)



-- Getters


getTranslate : PropertyBaselines -> Maybe Translate
getTranslate (PropertyBaselines dict) =
    Dict.get "translate" dict
        |> Maybe.andThen
            (\v ->
                case v of
                    TranslateValue t ->
                        Just t

                    _ ->
                        Nothing
            )


getRotate : PropertyBaselines -> Maybe Rotate
getRotate (PropertyBaselines dict) =
    Dict.get "rotate" dict
        |> Maybe.andThen
            (\v ->
                case v of
                    RotateValue r ->
                        Just r

                    _ ->
                        Nothing
            )


getScale : PropertyBaselines -> Maybe Scale
getScale (PropertyBaselines dict) =
    Dict.get "scale" dict
        |> Maybe.andThen
            (\v ->
                case v of
                    ScaleValue s ->
                        Just s

                    _ ->
                        Nothing
            )


getBackgroundColor : PropertyBaselines -> Maybe Color
getBackgroundColor (PropertyBaselines dict) =
    Dict.get "backgroundColor" dict
        |> Maybe.andThen
            (\v ->
                case v of
                    BackgroundColorValue c ->
                        Just c

                    _ ->
                        Nothing
            )


getFontColor : PropertyBaselines -> Maybe Color
getFontColor (PropertyBaselines dict) =
    Dict.get "fontColor" dict
        |> Maybe.andThen
            (\v ->
                case v of
                    FontColorValue c ->
                        Just c

                    _ ->
                        Nothing
            )


getOpacity : PropertyBaselines -> Maybe Opacity
getOpacity (PropertyBaselines dict) =
    Dict.get "opacity" dict
        |> Maybe.andThen
            (\v ->
                case v of
                    OpacityValue o ->
                        Just o

                    _ ->
                        Nothing
            )


getSize : PropertyBaselines -> Maybe Size
getSize (PropertyBaselines dict) =
    Dict.get "size" dict
        |> Maybe.andThen
            (\v ->
                case v of
                    SizeValue s ->
                        Just s

                    _ ->
                        Nothing
            )



-- Setters


setTranslate : Translate -> PropertyBaselines -> PropertyBaselines
setTranslate value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "translate" (TranslateValue value) dict)


setRotate : Rotate -> PropertyBaselines -> PropertyBaselines
setRotate value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "rotate" (RotateValue value) dict)


setScale : Scale -> PropertyBaselines -> PropertyBaselines
setScale value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "scale" (ScaleValue value) dict)


setBackgroundColor : Color -> PropertyBaselines -> PropertyBaselines
setBackgroundColor value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "backgroundColor" (BackgroundColorValue value) dict)


setFontColor : Color -> PropertyBaselines -> PropertyBaselines
setFontColor value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "fontColor" (FontColorValue value) dict)


setOpacity : Opacity -> PropertyBaselines -> PropertyBaselines
setOpacity value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "opacity" (OpacityValue value) dict)


setSize : Size -> PropertyBaselines -> PropertyBaselines
setSize value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "size" (SizeValue value) dict)
