module Anim.Internal.Engine.TestAnimGroups exposing (suite)

import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Anim.Internal.Engine.AnimGroups"
        [ initTests
        , insertRemoveTests
        , getTests
        , conversionTests
        , operationTests
        ]


initTests : Test
initTests =
    describe "init"
        [ test "init creates an empty AnimGroups" <|
            \_ ->
                AnimGroups.init
                    |> AnimGroups.isEmpty
                    |> Expect.equal True
        , test "init has no groups" <|
            \_ ->
                AnimGroups.init
                    |> AnimGroups.groups
                    |> List.isEmpty
                    |> Expect.equal True
        ]


insertRemoveTests : Test
insertRemoveTests =
    describe "insert / remove"
        [ test "insert adds a new group" <|
            \_ ->
                AnimGroups.init
                    |> AnimGroups.insert "animation1" 100
                    |> AnimGroups.member "animation1"
                    |> Expect.equal True
        , test "inserted value can be retrieved" <|
            \_ ->
                AnimGroups.init
                    |> AnimGroups.insert "animation1" 42
                    |> AnimGroups.get "animation1"
                    |> Expect.equal (Just 42)
        , test "remove removes a group" <|
            \_ ->
                AnimGroups.init
                    |> AnimGroups.insert "animation1" 100
                    |> AnimGroups.remove "animation1"
                    |> AnimGroups.member "animation1"
                    |> Expect.equal False
        , test "removing non-existent group does nothing" <|
            \_ ->
                AnimGroups.init
                    |> AnimGroups.remove "nonexistent"
                    |> AnimGroups.isEmpty
                    |> Expect.equal True
        , test "insert overwrites existing value" <|
            \_ ->
                AnimGroups.init
                    |> AnimGroups.insert "anim" 1
                    |> AnimGroups.insert "anim" 2
                    |> AnimGroups.get "anim"
                    |> Expect.equal (Just 2)
        ]


getTests : Test
getTests =
    describe "get / member"
        [ test "get returns Nothing for non-existent key" <|
            \_ ->
                AnimGroups.init
                    |> AnimGroups.get "nonexistent"
                    |> Expect.equal Nothing
        , test "member returns False for non-existent key" <|
            \_ ->
                AnimGroups.init
                    |> AnimGroups.member "nonexistent"
                    |> Expect.equal False
        , test "get returns Just value after insert" <|
            \_ ->
                AnimGroups.init
                    |> AnimGroups.insert "key" 99
                    |> AnimGroups.get "key"
                    |> Expect.equal (Just 99)
        , test "member returns True after insert" <|
            \_ ->
                AnimGroups.init
                    |> AnimGroups.insert "key" 99
                    |> AnimGroups.member "key"
                    |> Expect.equal True
        ]


conversionTests : Test
conversionTests =
    describe "conversions (fromList, toList, toDict, names)"
        [ test "fromList creates AnimGroups with all elements" <|
            \_ ->
                AnimGroups.fromList [ ( "a", 1 ), ( "b", 2 ) ]
                    |> AnimGroups.groups
                    |> List.length
                    |> Expect.equal 2
        , test "toList converts back to original list" <|
            \_ ->
                let
                    list =
                        [ ( "x", 10 ), ( "y", 20 ) ]
                in
                AnimGroups.fromList list
                    |> AnimGroups.toList
                    |> List.sort
                    |> Expect.equal (List.sort list)
        , test "names returns all group names" <|
            \_ ->
                AnimGroups.fromList [ ( "anim1", 1 ), ( "anim2", 2 ), ( "anim3", 3 ) ]
                    |> AnimGroups.names
                    |> List.sort
                    |> Expect.equal [ "anim1", "anim2", "anim3" ]
        , test "groups returns all values" <|
            \_ ->
                AnimGroups.fromList [ ( "a", 10 ), ( "b", 20 ), ( "c", 30 ) ]
                    |> AnimGroups.groups
                    |> List.sort
                    |> Expect.equal [ 10, 20, 30 ]
        , test "singleton creates single-element AnimGroups" <|
            \_ ->
                AnimGroups.singleton "solo" 42
                    |> AnimGroups.get "solo"
                    |> Expect.equal (Just 42)
        ]


operationTests : Test
operationTests =
    describe "operations (map, foldl)"
        [ test "map transforms all values" <|
            \_ ->
                AnimGroups.fromList [ ( "a", 1 ), ( "b", 2 ), ( "c", 3 ) ]
                    |> AnimGroups.map (\_ v -> v * 2)
                    |> AnimGroups.groups
                    |> List.sort
                    |> Expect.equal [ 2, 4, 6 ]
        , test "map receives both name and value" <|
            \_ ->
                AnimGroups.fromList [ ( "x", 10 ), ( "y", 20 ) ]
                    |> AnimGroups.map (\name v -> String.length name + v)
                    |> AnimGroups.groups
                    |> List.sort
                    |> Expect.equal [ 11, 21 ]
        , test "foldl accumulates all values" <|
            \_ ->
                AnimGroups.fromList [ ( "a", 1 ), ( "b", 2 ), ( "c", 3 ) ]
                    |> AnimGroups.foldl (\_ v acc -> acc + v) 0
                    |> Expect.equal 6
        , test "foldl respects accumulator type" <|
            \_ ->
                AnimGroups.fromList [ ( "a", "x" ), ( "b", "y" ) ]
                    |> AnimGroups.foldl (\name v acc -> acc ++ name ++ v) ""
                    |> String.length
                    |> Expect.equal 4
        , test "update modifies a specific group" <|
            \_ ->
                AnimGroups.fromList [ ( "a", 1 ), ( "b", 2 ) ]
                    |> AnimGroups.update "a" (always (Just 99))
                    |> AnimGroups.get "a"
                    |> Expect.equal (Just 99)
        ]
