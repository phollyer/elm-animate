module Anim.Internal.Engine.CSS.Styles exposing
    ( Styles
    , empty
    , filter
    , fromList
    , fromProcessedProperties
    , get
    , insert
    , insertList
    , member
    , merge
    , remove
    , toAttrs
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.Extra.Color as Color
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Internal.Property.Size as Size
import Dict exposing (Dict)
import Html
import Html.Attributes



-- ============================================================
-- TYPES
-- ============================================================


type Styles
    = Styles (Dict String String)


type alias AnimGroupName =
    String



-- ============================================================
-- BUILD
-- ============================================================


empty : Styles
empty =
    Styles Dict.empty


fromList : List ( String, String ) -> Styles
fromList =
    Dict.fromList >> Styles


fromProcessedProperties : List ( String, String ) -> (List Builder.ProcessedPropertyConfig -> List ( String, String )) -> List Builder.ProcessedPropertyConfig -> Styles
fromProcessedProperties baseStyles extractTransformStyles processedProps =
    baseStyles
        ++ extractTransformStyles processedProps
        ++ extractNonTransformStyles processedProps
        |> List.filter (Tuple.second >> String.isEmpty >> not)
        |> fromList


extractNonTransformStyles : List Builder.ProcessedPropertyConfig -> List ( String, String )
extractNonTransformStyles =
    List.concatMap
        (\prop ->
            case prop of
                Builder.ProcessedRotateConfig _ ->
                    []

                Builder.ProcessedScaleConfig _ ->
                    []

                Builder.ProcessedSkewConfig _ ->
                    []

                Builder.ProcessedTranslateConfig _ ->
                    []

                Builder.ProcessedCustomPropertyConfig cssName unit config ->
                    [ ( cssName, String.fromFloat config.end ++ unit ) ]

                Builder.ProcessedCustomColorPropertyConfig cssName config ->
                    [ ( cssName, Color.toCssString config.end ) ]

                Builder.ProcessedOpacityConfig config ->
                    [ ( "opacity", Opacity.toCssString config.end ) ]

                Builder.ProcessedPerspectiveOriginConfig config ->
                    [ ( "perspective-origin", PerspectiveOrigin.toCssString config.end ) ]

                Builder.ProcessedSizeConfig config ->
                    let
                        ( w, h ) =
                            Size.toTuple config.end
                    in
                    [ ( "width", String.fromFloat w ++ "px" )
                    , ( "height", String.fromFloat h ++ "px" )
                    ]
        )



-- ============================================================
-- QUERY
-- ============================================================


get : String -> Styles -> Maybe String
get key (Styles dict) =
    Dict.get key dict


member : String -> Styles -> Bool
member key (Styles dict) =
    Dict.member key dict



-- ============================================================
-- TRANSFORM
-- ============================================================


merge : Styles -> Styles -> Styles
merge (Styles a) (Styles b) =
    Styles (Dict.union a b)


filter : (String -> String -> Bool) -> Styles -> Styles
filter pred (Styles dict) =
    Styles (Dict.filter pred dict)


insert : String -> String -> Styles -> Styles
insert key value (Styles dict) =
    Styles (Dict.insert key value dict)


insertList : List ( String, String ) -> Styles -> Styles
insertList styles (Styles dict) =
    Styles (Dict.union (Dict.fromList styles) dict)


remove : String -> Styles -> Styles
remove key (Styles dict) =
    Styles (Dict.remove key dict)



-- ============================================================
-- VIEW
-- ============================================================


toAttrs : AnimGroupName -> Styles -> List (Html.Attribute msg)
toAttrs animGroupName (Styles dict) =
    let
        dataAttr =
            Html.Attributes.attribute "data-anim-group-name" animGroupName
    in
    dataAttr
        :: (Dict.toList dict
                |> List.map
                    (\( key, value ) ->
                        Html.Attributes.style key value
                    )
           )
