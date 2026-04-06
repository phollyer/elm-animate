module Anim.Internal.Styles exposing (..)

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


toAttrs : Styles -> List (Html.Attribute msg)
toAttrs (Styles dict) =
    Dict.toList dict
        |> List.map (\( key, value ) -> Html.Attributes.style key value)


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
