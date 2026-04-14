module Anim.Internal.Engine.Animation.Sub.Animations exposing
    ( Animations
    , add
    , foldl
    , fromList
    , get
    , init
    , list
    , map
    )

import Anim.Internal.Engine.Animation.Sub.Animation exposing (Animation)
import Dict exposing (Dict)


type alias PropertyName =
    String


type Animations
    = Animations (Dict PropertyName Animation)


init : Animations
init =
    Animations Dict.empty


add : Animations -> Animations -> Animations
add (Animations additional) (Animations existing) =
    Animations (Dict.union existing additional)


foldl : (PropertyName -> Animation -> v -> v) -> v -> Animations -> v
foldl f acc (Animations dict) =
    Dict.foldl f acc dict


fromList : List ( PropertyName, Animation ) -> Animations
fromList =
    Dict.fromList >> Animations


get : PropertyName -> Animations -> Maybe Animation
get key (Animations dict) =
    Dict.get key dict


map : (PropertyName -> Animation -> Animation) -> Animations -> Animations
map f (Animations dict) =
    Animations (Dict.map f dict)


list : Animations -> List Animation
list (Animations dict) =
    Dict.values dict
