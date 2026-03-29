module Anim.Internal.Engine.Animation.KeyMatch exposing
    ( findMatchingEntries
    , getMatchingKeys
    , normalizeKey
    )

import Anim.Internal.Builder as Builder
import Dict exposing (Dict)


{-| Normalize a key by stripping a trailing ":\*" wildcard suffix.
This allows users to write `"box:*"` to explicitly target all animation groups
for an element, which is equivalent to just passing `"box"`.
-}
normalizeKey : String -> String
normalizeKey key =
    if String.endsWith ":*" key then
        String.dropRight 2 key

    else
        key


{-| Find all entries in a Dict that match a given key.

1.  Exact match (for keys that are just the animation group name)
2.  Prefix match - composite keys starting with "key:" (when key is an element ID,
    e.g. "box" matches "box:fade", "box:slide")

Returns a list of (key, value) pairs.

-}
findMatchingEntries : String -> Dict String a -> List ( String, a )
findMatchingEntries key dict =
    let
        prefix =
            key ++ ":"

        prefixMatches =
            Dict.toList dict
                |> List.filter (\( k, _ ) -> String.startsWith prefix k)

        exactMatch =
            Dict.get key dict
                |> Maybe.map (\val -> [ ( key, val ) ])
                |> Maybe.withDefault []

        allMatches =
            exactMatch ++ prefixMatches

        uniqueKeys =
            allMatches
                |> List.foldl
                    (\( k, val ) acc ->
                        if Dict.member k acc then
                            acc

                        else
                            Dict.insert k val acc
                    )
                    Dict.empty
    in
    Dict.toList uniqueKeys


{-| Get all keys that match a given key.

If the key is already a composite key, returns it as a singleton list (if it exists).
If the key is just an element ID, returns all composite keys starting with "elementId:".

-}
getMatchingKeys : String -> Dict String a -> List String
getMatchingKeys key dict =
    if Builder.isCompositeKey key then
        if Dict.member key dict then
            [ key ]

        else
            []

    else
        findMatchingEntries key dict
            |> List.map Tuple.first
