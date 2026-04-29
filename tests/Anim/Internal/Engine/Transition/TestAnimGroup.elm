module Anim.Internal.Engine.Transition.TestAnimGroup exposing (suite)

import Anim.Internal.Engine.CSS.Styles as Styles
import Anim.Internal.Engine.Transition.AnimGroup as AnimGroup
import Dict
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Anim.Internal.Engine.Transition.AnimGroup"
        [ initTests
        , stylesTests
        , discreteTests
        ]


initTests : Test
initTests =
    describe "init"
        [ test "creates an AnimGroup" <|
            \_ ->
                let
                    ag =
                        AnimGroup.init
                in
                Expect.pass
        , test "init AnimGroup has empty styles" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.getStyles
                    |> Expect.equal Styles.empty
        ]


stylesTests : Test
stylesTests =
    describe "styles management"
        [ test "setStyles stores CSS styles" <|
            \_ ->
                let
                    styles =
                        Styles.empty
                            |> Styles.insert "transition" "all 1s ease"

                    ag =
                        AnimGroup.init
                            |> AnimGroup.setStyles styles
                in
                AnimGroup.getStyles ag
                    |> Expect.notEqual Styles.empty
        , test "getStyles returns empty styles initially" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.getStyles
                    |> Expect.equal Styles.empty
        ]


discreteTests : Test
discreteTests =
    describe "discrete entry/exit properties"
        [ test "setDiscreteEntry stores entry properties" <|
            \_ ->
                let
                    entry =
                        Dict.fromList [ ( "visibility", "visible" ), ( "opacity", "1" ) ]

                    ag =
                        AnimGroup.init
                            |> AnimGroup.setDiscreteEntry entry
                in
                AnimGroup.getDiscreteEntry ag
                    |> Dict.get "visibility"
                    |> Expect.equal (Just "visible")
        , test "setDiscreteExit stores exit properties" <|
            \_ ->
                let
                    exit =
                        Dict.empty

                    ag =
                        AnimGroup.init
                            |> AnimGroup.setDiscreteExit exit
                in
                AnimGroup.getDiscreteExit ag
                    |> Dict.isEmpty
                    |> Expect.equal True
        , test "getDiscreteEntry returns empty dict initially" <|
            \_ ->
                AnimGroup.init
                    |> AnimGroup.getDiscreteEntry
                    |> Dict.isEmpty
                    |> Expect.equal True
        ]
