module Anim.Internal.Engine.Animation.CSS.AnimGroups exposing
    ( AnimGroups
    , foldl
    , fromDict
    , fromList
    , get
    , init
    , insert
    , isEmpty
    , map
    , member
    , merge
    , names
    , remove
    , singleton
    , toDict
    , toList
    , union
    , update
    , values
    )

import Dict exposing (Dict)


type alias AnimGroupName =
    String


type AnimGroups a
    = AnimGroups (Dict AnimGroupName a)


init : AnimGroups a
init =
    AnimGroups Dict.empty


foldl : (AnimGroupName -> a -> v -> v) -> v -> AnimGroups a -> v
foldl f acc (AnimGroups dict) =
    Dict.foldl f acc dict


fromDict : Dict AnimGroupName a -> AnimGroups a
fromDict =
    AnimGroups


fromList : List ( AnimGroupName, a ) -> AnimGroups a
fromList =
    Dict.fromList >> AnimGroups


get : AnimGroupName -> AnimGroups a -> Maybe a
get name (AnimGroups dict) =
    Dict.get name dict


insert : AnimGroupName -> a -> AnimGroups a -> AnimGroups a
insert name value (AnimGroups dict) =
    AnimGroups (Dict.insert name value dict)


isEmpty : AnimGroups a -> Bool
isEmpty (AnimGroups dict) =
    Dict.isEmpty dict


map : (AnimGroupName -> a -> v) -> AnimGroups a -> AnimGroups v
map f (AnimGroups dict) =
    AnimGroups (Dict.map f dict)


member : AnimGroupName -> AnimGroups a -> Bool
member name (AnimGroups dict) =
    Dict.member name dict


merge : (AnimGroupName -> b -> AnimGroups a -> AnimGroups a) -> (AnimGroupName -> b -> c -> AnimGroups a -> AnimGroups a) -> (AnimGroupName -> c -> AnimGroups a -> AnimGroups a) -> Dict AnimGroupName b -> Dict AnimGroupName c -> AnimGroups a -> AnimGroups a
merge leftStep bothStep rightStep dictB dictC (AnimGroups dictA) =
    AnimGroups
        (Dict.merge
            (\k b acc -> leftStep k b (AnimGroups acc) |> toDict)
            (\k b c acc -> bothStep k b c (AnimGroups acc) |> toDict)
            (\k c acc -> rightStep k c (AnimGroups acc) |> toDict)
            dictB
            dictC
            dictA
        )


names : AnimGroups a -> List AnimGroupName
names (AnimGroups dict) =
    Dict.keys dict


remove : AnimGroupName -> AnimGroups a -> AnimGroups a
remove name (AnimGroups dict) =
    AnimGroups (Dict.remove name dict)


singleton : AnimGroupName -> a -> AnimGroups a
singleton name value =
    AnimGroups (Dict.singleton name value)


toDict : AnimGroups a -> Dict AnimGroupName a
toDict (AnimGroups dict) =
    dict


toList : AnimGroups a -> List ( AnimGroupName, a )
toList (AnimGroups dict) =
    Dict.toList dict


update : AnimGroupName -> (Maybe a -> Maybe a) -> AnimGroups a -> AnimGroups a
update name fn (AnimGroups dict) =
    AnimGroups (Dict.update name fn dict)


union : AnimGroups a -> AnimGroups a -> AnimGroups a
union (AnimGroups a) (AnimGroups b) =
    AnimGroups (Dict.union a b)


values : AnimGroups a -> List a
values (AnimGroups dict) =
    Dict.values dict
