module Anim.Internal.Engine.Sub.TestGenerator exposing (suite)

import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Sub.AnimGroup as SubAnimGroup
import Anim.Internal.Engine.Sub.Generator as SubGenerator
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


processedConfigs : List Builder.ProcessedPropertyConfig
processedConfigs =
    Builder.processProperties Builder.initDefaults [ translateConfig ]


suite : Test
suite =
    describe "Anim.Internal.Engine.Sub.Generator"
        [ initTests
        , generateAnimationTests
        ]


initTests : Test
initTests =
    describe "init"
        [ test "init with no properties creates a Complete AnimGroup" <|
            \_ ->
                SubGenerator.init Dict.empty Dict.empty []
                    |> SubAnimGroup.isComplete
                    |> Expect.equal True
        , test "init is not Running" <|
            \_ ->
                SubGenerator.init Dict.empty Dict.empty []
                    |> SubAnimGroup.isRunning
                    |> Expect.equal False
        , test "init with translate property creates a Complete AnimGroup" <|
            \_ ->
                SubGenerator.init Dict.empty Dict.empty [ translateConfig ]
                    |> SubAnimGroup.isComplete
                    |> Expect.equal True
        , test "init with translate property is not Running" <|
            \_ ->
                SubGenerator.init Dict.empty Dict.empty [ translateConfig ]
                    |> SubAnimGroup.isRunning
                    |> Expect.equal False
        , test "default transform order is set on init" <|
            \_ ->
                SubGenerator.init Dict.empty Dict.empty []
                    |> SubAnimGroup.getTransformOrder
                    |> List.isEmpty
                    |> Expect.equal False
        ]


generateAnimationTests : Test
generateAnimationTests =
    describe "generateAnimation"
        [ test "creates a Running AnimGroup" <|
            \_ ->
                SubGenerator.generateAnimation Builder.Once Builder.Normal Nothing Dict.empty Dict.empty Nothing processedConfigs
                    |> SubAnimGroup.isRunning
                    |> Expect.equal True
        , test "is not Complete when Running" <|
            \_ ->
                SubGenerator.generateAnimation Builder.Once Builder.Normal Nothing Dict.empty Dict.empty Nothing processedConfigs
                    |> SubAnimGroup.isComplete
                    |> Expect.equal False
        , test "default transform order is set when maybeOrder is Nothing" <|
            \_ ->
                SubGenerator.generateAnimation Builder.Once Builder.Normal Nothing Dict.empty Dict.empty Nothing processedConfigs
                    |> SubAnimGroup.getTransformOrder
                    |> List.isEmpty
                    |> Expect.equal False
        , test "custom transform order is applied when provided" <|
            \_ ->
                let
                    customOrder =
                        [ Scale, Translate, Rotate ]
                in
                SubGenerator.generateAnimation Builder.Once Builder.Normal (Just customOrder) Dict.empty Dict.empty Nothing processedConfigs
                    |> SubAnimGroup.getTransformOrder
                    |> Expect.equal customOrder
        , test "Infinite iterations is preserved in the AnimGroup" <|
            \_ ->
                SubGenerator.generateAnimation Builder.Infinite Builder.Normal Nothing Dict.empty Dict.empty Nothing processedConfigs
                    |> SubAnimGroup.getIterations
                    |> Expect.equal Builder.Infinite
        , test "Reverse direction is preserved in the AnimGroup" <|
            \_ ->
                SubGenerator.generateAnimation Builder.Once Builder.Alternate Nothing Dict.empty Dict.empty Nothing processedConfigs
                    |> SubAnimGroup.getAnimationDirection
                    |> Expect.equal Builder.Alternate
        ]
