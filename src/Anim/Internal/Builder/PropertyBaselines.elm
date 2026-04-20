module Anim.Internal.Builder.PropertyBaselines exposing
    ( PropertyBaselines
    , empty
    , getBackgroundColor
    , getCustomColorProperty
    , getCustomProperty
    , getFontColor
    , getOpacity
    , getRotate
    , getScale
    , getSize
    , getTranslate
    , merge
    , setBackgroundColor
    , setCustomColorProperty
    , setCustomProperty
    , setFontColor
    , setOpacity
    , setRotate
    , setScale
    , setSize
    , setTranslate
    )

import Anim.Internal.Extra.Color exposing (Color)
import Anim.Internal.PropertyBuilder.Opacity exposing (Opacity)
import Anim.Internal.PropertyBuilder.Rotate exposing (Rotate)
import Anim.Internal.PropertyBuilder.Scale exposing (Scale)
import Anim.Internal.PropertyBuilder.Size exposing (Size)
import Anim.Internal.PropertyBuilder.Translate exposing (Translate)
import Dict exposing (Dict)



-- ============================================================
-- TYPES
-- ============================================================


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
    | CustomPropertyValue Float
    | CustomColorPropertyValue Color



-- ============================================================
-- INITIALIZE
-- ============================================================


empty : PropertyBaselines
empty =
    PropertyBaselines Dict.empty


{-| Merge two PropertyBaselines. The second argument takes precedence.
-}
merge : PropertyBaselines -> PropertyBaselines -> PropertyBaselines
merge (PropertyBaselines base) (PropertyBaselines override) =
    PropertyBaselines (Dict.union override base)



-- ============================================================
-- GETTERS
-- ============================================================


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



-- ============================================================
-- SETTERS
-- ============================================================


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


getCustomProperty : String -> PropertyBaselines -> Maybe Float
getCustomProperty cssPropertyName (PropertyBaselines dict) =
    Dict.get ("custom:" ++ cssPropertyName) dict
        |> Maybe.andThen
            (\v ->
                case v of
                    CustomPropertyValue f ->
                        Just f

                    _ ->
                        Nothing
            )


setCustomProperty : String -> Float -> PropertyBaselines -> PropertyBaselines
setCustomProperty cssPropertyName value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert ("custom:" ++ cssPropertyName) (CustomPropertyValue value) dict)


getCustomColorProperty : String -> PropertyBaselines -> Maybe Color
getCustomColorProperty cssPropertyName (PropertyBaselines dict) =
    Dict.get ("customColor:" ++ cssPropertyName) dict
        |> Maybe.andThen
            (\v ->
                case v of
                    CustomColorPropertyValue c ->
                        Just c

                    _ ->
                        Nothing
            )


setCustomColorProperty : String -> Color -> PropertyBaselines -> PropertyBaselines
setCustomColorProperty cssPropertyName value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert ("customColor:" ++ cssPropertyName) (CustomColorPropertyValue value) dict)
