module Anim.Internal.Engine.Keyframe.TestGenerator exposing (suite)

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Keyframe.AnimGroup as KeyframeAnimGroup
import Anim.Internal.Engine.Keyframe.Animation as Animation
import Anim.Internal.Engine.Keyframe.Generator as Generator
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
    describe "Anim.Internal.Engine.Keyframe.Generator"
        [ initTests
        , keyframeContentTests
        , interpolationTests
        ]


initTests : Test
initTests =
    describe "init"
        [ test "empty properties produces AnimGroup with no animation" <|
            \_ ->
                Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "test" []
                    |> KeyframeAnimGroup.getAnimation
                    |> Expect.equal Nothing
        , test "non-empty properties produces AnimGroup with animation" <|
            \_ ->
                Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "myAnim" [ translateConfig ]
                    |> KeyframeAnimGroup.getAnimation
                    |> Expect.notEqual Nothing
        , test "init creates an AnimGroup that is not active" <|
            \_ ->
                Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "myAnim" [ translateConfig ]
                    |> KeyframeAnimGroup.isActive
                    |> Expect.equal False
        , test "init creates an AnimGroup that is complete" <|
            \_ ->
                Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "myAnim" [ translateConfig ]
                    |> KeyframeAnimGroup.isRunning
                    |> Expect.equal False
        ]


keyframeContentTests : Test
keyframeContentTests =
    describe "keyframe content"
        [ test "keyframes string begins with @keyframes" <|
            \_ ->
                Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "myAnim" [ translateConfig ]
                    |> KeyframeAnimGroup.getAnimation
                    |> Maybe.map Animation.getKeyframes
                    |> Maybe.withDefault ""
                    |> String.startsWith "@keyframes"
                    |> Expect.equal True
        , test "keyframes string contains 0% step" <|
            \_ ->
                Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "myAnim" [ translateConfig ]
                    |> KeyframeAnimGroup.getAnimation
                    |> Maybe.map Animation.getKeyframes
                    |> Maybe.withDefault ""
                    |> String.contains "0%"
                    |> Expect.equal True
        , test "keyframes string contains 100% step" <|
            \_ ->
                Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "myAnim" [ translateConfig ]
                    |> KeyframeAnimGroup.getAnimation
                    |> Maybe.map Animation.getKeyframes
                    |> Maybe.withDefault ""
                    |> String.contains "100%"
                    |> Expect.equal True
        , test "keyframes string contains translate3d for translate property" <|
            \_ ->
                Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "myAnim" [ translateConfig ]
                    |> KeyframeAnimGroup.getAnimation
                    |> Maybe.map Animation.getKeyframes
                    |> Maybe.withDefault ""
                    |> String.contains "translate3d"
                    |> Expect.equal True
        , test "keyframes string contains the animation name" <|
            \_ ->
                Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "uniqueAnimName" [ translateConfig ]
                    |> KeyframeAnimGroup.getAnimation
                    |> Maybe.map Animation.getKeyframes
                    |> Maybe.withDefault ""
                    |> String.contains "uniqueAnimName"
                    |> Expect.equal True
        , test "two different names produce distinct keyframe strings" <|
            \_ ->
                let
                    anim1 =
                        Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "firstAnim" [ translateConfig ]
                            |> KeyframeAnimGroup.getAnimation
                            |> Maybe.map Animation.getKeyframes

                    anim2 =
                        Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "secondAnim" [ translateConfig ]
                            |> KeyframeAnimGroup.getAnimation
                            |> Maybe.map Animation.getKeyframes
                in
                Expect.notEqual anim1 anim2
        ]


interpolationTests : Test
interpolationTests =
    describe "interpolation in keyframes"
        [ test "at 0% step, translate starts at origin" <|
            \_ ->
                Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "myAnim" [ translateConfig ]
                    |> KeyframeAnimGroup.getAnimation
                    |> Maybe.map Animation.getKeyframes
                    |> Maybe.withDefault ""
                    |> String.contains "translate3d(0px, 0px, 0px)"
                    |> Expect.equal True
        , test "at 100% step, translate reaches end value" <|
            \_ ->
                Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "myAnim" [ translateConfig ]
                    |> KeyframeAnimGroup.getAnimation
                    |> Maybe.map Animation.getKeyframes
                    |> Maybe.withDefault ""
                    |> String.contains "translate3d(100px, 0px, 0px)"
                    |> Expect.equal True
        , test "discrete entry config produces an animation" <|
            \_ ->
                let
                    discrete =
                        { entry = Dict.fromList [ ( "visibility", "visible" ) ]
                        , exit = Dict.empty
                        }
                in
                Generator.init Nothing Builder.Once Builder.Normal discrete "myAnim" [ translateConfig ]
                    |> KeyframeAnimGroup.getAnimation
                    |> Expect.notEqual Nothing
        , test "no-op translate (same start and end) still produces animation" <|
            \_ ->
                let
                    noOpTranslate =
                        Builder.TranslateConfig
                            { start = Just (Translate.fromTriple ( 50, 50, 0 ))
                            , end = Translate.fromTriple ( 50, 50, 0 )
                            , distance = 0
                            , timing = Just (Duration 1000)
                            , easing = Nothing
                            , delay = Nothing
                            }
                in
                Generator.init Nothing Builder.Once Builder.Normal Generator.emptyDiscreteConfig "noOp" [ noOpTranslate ]
                    |> KeyframeAnimGroup.getAnimation
                    |> Expect.notEqual Nothing
        ]
