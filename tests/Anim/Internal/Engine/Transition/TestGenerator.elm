module Anim.Internal.Engine.Transition.TestGenerator exposing (suite)

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.Styles as Styles
import Anim.Internal.Engine.Transition.AnimGroup as TransitionAnimGroup
import Anim.Internal.Engine.Transition.Generator as Generator
import Anim.Internal.Property.Translate as Translate
import Dict
import Expect
import Shared.TimeSpec exposing (TimeSpec(..))
import Test exposing (..)


translateConfig : Builder.PropertyConfig
translateConfig =
    Builder.TranslateConfig
        { start = Just (Translate.fromTriple ( 0, 0, 0 ))
        , end = Translate.fromTriple ( 100, 0, 0 )
        , distance = 100
        , timing = Just (Duration 1000)
        , easing = Nothing
        , delay = Nothing
        }


suite : Test
suite =
    describe "Anim.Internal.Engine.Transition.Generator"
        [ initTests
        , generateAnimationTests
        , discreteTransitionTests
        ]


initTests : Test
initTests =
    describe "init"
        [ test "creates an AnimGroup" <|
            \_ ->
                let
                    ag =
                        Generator.init False Dict.empty Dict.empty [ translateConfig ]
                in
                Expect.pass
        , test "init with no properties creates AnimGroup with transition styles" <|
            \_ ->
                Generator.init False Dict.empty Dict.empty []
                    |> (\animGroup ->
                            TransitionAnimGroup.getStyles animGroup
                                |> Expect.notEqual Styles.empty
                       )
        , test "init with translate produces animation with non-empty styles" <|
            \_ ->
                Generator.init False Dict.empty Dict.empty [ translateConfig ]
                    |> (\animGroup ->
                            TransitionAnimGroup.getStyles animGroup
                                |> Expect.notEqual Styles.empty
                       )
        , test "init preserves discrete entry properties" <|
            \_ ->
                let
                    entry =
                        Dict.fromList [ ( "visibility", "visible" ) ]
                in
                Generator.init False entry Dict.empty [ translateConfig ]
                    |> (\animGroup ->
                            TransitionAnimGroup.getDiscreteEntry animGroup
                                |> Dict.get "visibility"
                                |> Expect.equal (Just "visible")
                       )
        ]


generateAnimationTests : Test
generateAnimationTests =
    describe "generateAnimation"
        [ test "generates animation from properties" <|
            \_ ->
                let
                    processedProps =
                        Builder.processProperties Builder.initDefaults [ translateConfig ]

                    ag =
                        Generator.generateAnimation False Dict.empty Dict.empty processedProps
                in
                Expect.pass
        , test "generated animation has non-empty styles" <|
            \_ ->
                let
                    processedProps =
                        Builder.processProperties Builder.initDefaults [ translateConfig ]
                in
                Generator.generateAnimation False Dict.empty Dict.empty processedProps
                    |> (\animGroup ->
                            TransitionAnimGroup.getStyles animGroup
                                |> Expect.notEqual Styles.empty
                       )
        ]


discreteTransitionTests : Test
discreteTransitionTests =
    describe "discrete transitions"
        [ test "init with discreteTransitions=False produces animation" <|
            \_ ->
                let
                    ag =
                        Generator.init False Dict.empty Dict.empty [ translateConfig ]
                in
                Expect.pass
        , test "init with discreteTransitions=True produces discrete transition" <|
            \_ ->
                let
                    ag =
                        Generator.init True Dict.empty Dict.empty [ translateConfig ]
                in
                Expect.pass
        ]
