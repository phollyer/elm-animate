module Anim.Internal.Engine.Animation.KeyMatch exposing
    ( getMatchingKeys
    , normalizeKey
    )

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


{-| Get all keys that match a given key. Direct Dict.member check.
-}
getMatchingKeys : String -> Dict String a -> List String
getMatchingKeys key dict =
    if Dict.member key dict then
        [ key ]

    else
        []
