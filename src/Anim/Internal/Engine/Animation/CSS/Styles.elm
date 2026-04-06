module Anim.Internal.Engine.Animation.CSS.Styles exposing
    ( Styles
    , empty
    , filter
    , fromList
    , fromProcessedProperties
    , fromStaticProperties
    , fromTransitionProperties
    , get
    , insert
    , member
    , remove
    , toAttrs
    , union
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.Extra.Color as Color
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Translate as Translate
import Dict exposing (Dict)
import Html
import Html.Attributes


type Styles
    = Styles (Dict String String)


empty : Styles
empty =
    Styles Dict.empty


fromList : List ( String, String ) -> Styles
fromList =
    Dict.fromList >> Styles


{-| Generate styles for the keyframe engine.

Takes base styles (like transform, animation, transition) and processed properties,
extracts non-transform property styles (background-color, color, opacity, size),
merges them with the base styles, and filters out empty values.

-}
fromProcessedProperties : List ( String, String ) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedProperties baseStyles processedProps =
    baseStyles
        ++ extractNonTransformStyles processedProps
        |> List.filter (\( _, value ) -> not (String.isEmpty value))
        |> fromList


{-| Generate styles for the transition engine.

Takes a CSS transition string, whether discrete transitions are enabled, and processed properties.
Extracts all property end states as individual CSS properties with transitions.

-}
fromTransitionProperties : String -> Bool -> List Builder.ProcessedPropertyConfig -> Styles
fromTransitionProperties transitionValue discreteTransitions processedProps =
    let
        transitionBehaviorStyle =
            if discreteTransitions then
                [ ( "transition-behavior", "allow-discrete" ) ]

            else
                []
    in
    ( "transition", transitionValue )
        :: extractTransformPropertyStyles processedProps
        ++ extractNonTransformStyles processedProps
        ++ transitionBehaviorStyle
        |> List.filter (\( _, value ) -> not (String.isEmpty value))
        |> fromList


{-| Generate static styles for the transition engine (stop/reset).

Extracts all property end states without transitions (transition: none).

-}
fromStaticProperties : List Builder.ProcessedPropertyConfig -> Styles
fromStaticProperties processedProps =
    ( "transition", "none" )
        :: extractTransformPropertyStyles processedProps
        ++ extractNonTransformStyles processedProps
        |> List.filter (\( key, value ) -> key == "transition" || not (String.isEmpty value))
        |> fromList


toAttrs : Styles -> List (Html.Attribute msg)
toAttrs (Styles dict) =
    Dict.toList dict
        |> List.map
            (\( key, value ) ->
                Html.Attributes.style key value
            )


insert : String -> String -> Styles -> Styles
insert key value (Styles dict) =
    Styles (Dict.insert key value dict)


get : String -> Styles -> Maybe String
get key (Styles dict) =
    Dict.get key dict


remove : String -> Styles -> Styles
remove key (Styles dict) =
    Styles (Dict.remove key dict)


union : Styles -> Styles -> Styles
union (Styles a) (Styles b) =
    Styles (Dict.union a b)


filter : (String -> String -> Bool) -> Styles -> Styles
filter pred (Styles dict) =
    Styles (Dict.filter pred dict)


member : String -> Styles -> Bool
member key (Styles dict) =
    Dict.member key dict



-- INTERNAL


{-| Extract transform-related styles as individual CSS properties (for transition engine).
Maps translate/rotate/scale to their individual CSS property equivalents.
-}
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


{-| Extract non-transform property styles (shared between keyframe and transition engines).
Maps background-color, font-color, opacity, and size to CSS styles.
-}
extractNonTransformStyles : List Builder.ProcessedPropertyConfig -> List ( String, String )
extractNonTransformStyles =
    List.concatMap
        (\prop ->
            case prop of
                Builder.ProcessedTranslateConfig _ ->
                    []

                Builder.ProcessedRotateConfig _ ->
                    []

                Builder.ProcessedScaleConfig _ ->
                    []

                Builder.ProcessedBackgroundColorConfig config ->
                    [ ( "background-color", Color.toCssString config.end ) ]

                Builder.ProcessedFontColorConfig config ->
                    [ ( "color", Color.toCssString config.end ) ]

                Builder.ProcessedOpacityConfig config ->
                    [ ( "opacity", Opacity.toCssString config.end ) ]

                Builder.ProcessedSizeConfig config ->
                    let
                        ( w, h ) =
                            Size.toTuple config.end
                    in
                    [ ( "width", String.fromFloat w ++ "px" )
                    , ( "height", String.fromFloat h ++ "px" )
                    ]
        )
