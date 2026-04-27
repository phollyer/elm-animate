module Anim.Internal.Builder.PropertyBaselines exposing
    ( PropertyBaselines
    , empty
    , getAllCustomColorProperties
    , getAllCustomProperties
    , getCustomColorProperty
    , getCustomProperty
    , getOpacity
    , getRotate
    , getScale
    , getSize
    , getSkew
    , getTranslate
    , merge
    , setCustomColorProperty
    , setCustomProperty
    , setOpacity
    , setRotate
    , setScale
    , setSize
    , setSkew
    , setTranslate
    , updateCustomProperty
    )

import Anim.Internal.Extra.Color exposing (Color)
import Anim.Internal.Property.Opacity exposing (Opacity)
import Anim.Internal.Property.Rotate exposing (Rotate)
import Anim.Internal.Property.Scale exposing (Scale)
import Anim.Internal.Property.Size exposing (Size)
import Anim.Internal.Property.Skew exposing (Skew)
import Anim.Internal.Property.Translate exposing (Translate)
import Dict exposing (Dict)



-- ============================================================
-- TYPES
-- ============================================================


type PropertyBaselines
    = PropertyBaselines (Dict String PropertyValue)


type PropertyValue
    = CustomPropertyValue Float String
    | CustomColorPropertyValue Color
    | OpacityValue Opacity
    | RotateValue Rotate
    | ScaleValue Scale
    | SizeValue Size
    | SkewValue Skew
    | TranslateValue Translate



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


getCustomProperty : String -> PropertyBaselines -> Maybe Float
getCustomProperty cssPropertyName (PropertyBaselines dict) =
    Dict.get ("custom:" ++ cssPropertyName) dict
        |> Maybe.andThen
            (\v ->
                case v of
                    CustomPropertyValue f _ ->
                        Just f

                    _ ->
                        Nothing
            )


getAllCustomProperties : PropertyBaselines -> List ( String, String )
getAllCustomProperties (PropertyBaselines dict) =
    Dict.toList dict
        |> List.filterMap
            (\( key, value ) ->
                case value of
                    CustomPropertyValue f unit ->
                        Just ( String.dropLeft 7 key, String.fromFloat f ++ unit )

                    _ ->
                        Nothing
            )


getAllCustomColorProperties : PropertyBaselines -> List ( String, Color )
getAllCustomColorProperties (PropertyBaselines dict) =
    Dict.toList dict
        |> List.filterMap
            (\( key, value ) ->
                case value of
                    CustomColorPropertyValue color ->
                        Just ( String.dropLeft 12 key, color )

                    _ ->
                        Nothing
            )


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


getSkew : PropertyBaselines -> Maybe Skew
getSkew (PropertyBaselines dict) =
    Dict.get "skew" dict
        |> Maybe.andThen
            (\v ->
                case v of
                    SkewValue s ->
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


setCustomProperty : String -> Float -> String -> PropertyBaselines -> PropertyBaselines
setCustomProperty cssPropertyName value unit (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert ("custom:" ++ cssPropertyName) (CustomPropertyValue value unit) dict)


updateCustomProperty : String -> Float -> PropertyBaselines -> PropertyBaselines
updateCustomProperty cssPropertyName value (PropertyBaselines dict) =
    let
        existingUnit =
            Dict.get ("custom:" ++ cssPropertyName) dict
                |> Maybe.andThen
                    (\v ->
                        case v of
                            CustomPropertyValue _ u ->
                                Just u

                            _ ->
                                Nothing
                    )
                |> Maybe.withDefault ""
    in
    PropertyBaselines (Dict.insert ("custom:" ++ cssPropertyName) (CustomPropertyValue value existingUnit) dict)


setCustomColorProperty : String -> Color -> PropertyBaselines -> PropertyBaselines
setCustomColorProperty cssPropertyName value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert ("customColor:" ++ cssPropertyName) (CustomColorPropertyValue value) dict)


setOpacity : Opacity -> PropertyBaselines -> PropertyBaselines
setOpacity value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "opacity" (OpacityValue value) dict)


setRotate : Rotate -> PropertyBaselines -> PropertyBaselines
setRotate value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "rotate" (RotateValue value) dict)


setScale : Scale -> PropertyBaselines -> PropertyBaselines
setScale value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "scale" (ScaleValue value) dict)


setSize : Size -> PropertyBaselines -> PropertyBaselines
setSize value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "size" (SizeValue value) dict)


setSkew : Skew -> PropertyBaselines -> PropertyBaselines
setSkew value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "skew" (SkewValue value) dict)


setTranslate : Translate -> PropertyBaselines -> PropertyBaselines
setTranslate value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "translate" (TranslateValue value) dict)
