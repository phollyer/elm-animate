module Anim.Internal.Builder.PropertyBaselines exposing
    ( PropertyBaselines
    , empty
    , getAllCustomColorProperties
    , getAllCustomProperties
    , getCustomColorProperty
    , getCustomProperty
    , getOpacity
    , getPerspectiveOrigin
    , getRotate
    , getScale
    , getSize
    , getSkew
    , getTranslate
    , merge
    , setCustomColorProperty
    , setCustomProperty
    , setOpacity
    , setPerspectiveOrigin
    , setRotate
    , setScale
    , setSize
    , setSkew
    , setTranslate
    , updateCustomColorProperties
    , updateCustomProperties
    )

import Anim.Internal.Extra.Color as Color exposing (Color)
import Anim.Internal.Property.Opacity exposing (Opacity)
import Anim.Internal.Property.PerspectiveOrigin exposing (PerspectiveOrigin)
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
    | PerspectiveOriginValue PerspectiveOrigin
    | RotateValue Rotate
    | ScaleValue Scale
    | SizeValue Size
    | SkewValue Skew
    | TranslateValue Translate



-- ============================================================
-- BUILD
-- ============================================================


empty : PropertyBaselines
empty =
    PropertyBaselines Dict.empty



-- ============================================================
-- TRANSFORM
-- ============================================================


{-| Merge two PropertyBaselines. The second argument takes precedence.
-}
merge : PropertyBaselines -> PropertyBaselines -> PropertyBaselines
merge (PropertyBaselines base) (PropertyBaselines override) =
    PropertyBaselines (Dict.union override base)



-- ============================================================
-- UPDATE
-- ============================================================


{-| Update custom properties from a dictionary of float values.
Preserves existing units for each property.
-}
updateCustomProperties : Dict String Float -> PropertyBaselines -> PropertyBaselines
updateCustomProperties customProperties baselines =
    Dict.foldl updateCustomProperty baselines customProperties


{-| Update a custom property from a float value.

Ignores properties with no existing unit.

-}
updateCustomProperty : String -> Float -> PropertyBaselines -> PropertyBaselines
updateCustomProperty cssPropertyName value baselines =
    case getUnit cssPropertyName baselines of
        Just existingUnit ->
            setCustomProperty ("custom:" ++ cssPropertyName) value existingUnit baselines

        Nothing ->
            baselines


{-| Update custom color properties from a dictionary of color strings.
-}
updateCustomColorProperties : Dict String String -> PropertyBaselines -> PropertyBaselines
updateCustomColorProperties customColorProperties baselines =
    Dict.foldl updateCustomColorProperty baselines customColorProperties


{-| Update a single custom color property from a color string.

Ignores invalid color strings.

-}
updateCustomColorProperty : String -> String -> PropertyBaselines -> PropertyBaselines
updateCustomColorProperty cssPropertyName colorString baselines =
    case Color.fromString colorString of
        Just colorValue ->
            setCustomColorProperty ("customColor:" ++ cssPropertyName) colorValue baselines

        Nothing ->
            baselines



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


getPerspectiveOrigin : PropertyBaselines -> Maybe PerspectiveOrigin
getPerspectiveOrigin (PropertyBaselines dict) =
    Dict.get "perspectiveOrigin" dict
        |> Maybe.andThen
            (\v ->
                case v of
                    PerspectiveOriginValue po ->
                        Just po

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


getUnit : String -> PropertyBaselines -> Maybe String
getUnit cssPropertyName (PropertyBaselines dict) =
    Dict.get ("custom:" ++ cssPropertyName) dict
        |> Maybe.andThen
            (\v ->
                case v of
                    CustomPropertyValue _ unit ->
                        Just unit

                    _ ->
                        Nothing
            )



-- ============================================================
-- SETTERS
-- ============================================================


setCustomProperty : String -> Float -> String -> PropertyBaselines -> PropertyBaselines
setCustomProperty cssPropertyName value unit (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert ("custom:" ++ cssPropertyName) (CustomPropertyValue value unit) dict)


setCustomColorProperty : String -> Color -> PropertyBaselines -> PropertyBaselines
setCustomColorProperty cssPropertyName value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert ("customColor:" ++ cssPropertyName) (CustomColorPropertyValue value) dict)


setOpacity : Opacity -> PropertyBaselines -> PropertyBaselines
setOpacity value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "opacity" (OpacityValue value) dict)


setPerspectiveOrigin : PerspectiveOrigin -> PropertyBaselines -> PropertyBaselines
setPerspectiveOrigin value (PropertyBaselines dict) =
    PropertyBaselines (Dict.insert "perspectiveOrigin" (PerspectiveOriginValue value) dict)


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
