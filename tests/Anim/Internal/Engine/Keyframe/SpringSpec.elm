module Anim.Internal.Engine.Keyframe.SpringSpec exposing (suite)

{-| Verifies that the Keyframe engine generator samples a spring
when `config.spring` is set.

The Keyframe engine emits CSS `@keyframes` by sampling the
property's progress function at N evenly-spaced time points. For
spring-driven motion, we expect the generated keyframes string to
contain interpolated values that overshoot the target position
(under-damped spring) or otherwise differ from a linear / standard
easing curve.

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Keyframe.AnimGroup as KeyframeAnimGroup
import Anim.Internal.Engine.Keyframe.Animation as Animation
import Anim.Internal.Engine.Keyframe.Generator as Generator
import Anim.Internal.Property.Translate as Translate
import Expect
import Motion.Easing exposing (Easing(..))
import Motion.Spring as Spring
import Shared.TimeSpec exposing (TimeSpec(..))
import Test exposing (Test, describe, test)



-- ============================================================
-- HELPERS
-- ============================================================


springTranslateConfig : Spring.Spring -> Builder.PropertyConfig
springTranslateConfig spring =
    Builder.TranslateConfig
        { start = Just (Translate.fromTriple ( 0, 0, 0 ))
        , end = Translate.fromTriple ( 100, 0, 0 )
        , distance = 100
        , timing = Just (Duration 1000)
        , easing = Nothing
        , spring = Just spring
        , delay = Nothing
        }


easingTranslateConfig : Easing -> Builder.PropertyConfig
easingTranslateConfig easing =
    Builder.TranslateConfig
        { start = Just (Translate.fromTriple ( 0, 0, 0 ))
        , end = Translate.fromTriple ( 100, 0, 0 )
        , distance = 100
        , timing = Just (Duration 1000)
        , easing = Just easing
        , spring = Nothing
        , delay = Nothing
        }


keyframesFor : List Builder.PropertyConfig -> String
keyframesFor properties =
    let
        processed =
            Builder.processProperties Builder.initDefaults properties
    in
    Generator.generateAnimation Nothing
        Builder.Once
        Builder.Normal
        Nothing
        Generator.emptyDiscreteConfig
        "test"
        processed
        |> KeyframeAnimGroup.getAnimation
        |> Maybe.map Animation.getKeyframes
        |> Maybe.withDefault ""



-- ============================================================
-- SUITE
-- ============================================================


suite : Test
suite =
    describe "Anim.Internal.Engine.Keyframe.Generator spring support"
        [ test "spring config produces a non-empty @keyframes block" <|
            \_ ->
                keyframesFor [ springTranslateConfig Spring.wobbly ]
                    |> String.startsWith "@keyframes"
                    |> Expect.equal True
        , test "spring config produces a 0% keyframe step" <|
            \_ ->
                keyframesFor [ springTranslateConfig Spring.wobbly ]
                    |> String.contains "0%"
                    |> Expect.equal True
        , test "wobbly spring keyframes differ from linear-easing keyframes" <|
            \_ ->
                let
                    springKeyframes =
                        keyframesFor [ springTranslateConfig Spring.wobbly ]

                    linearKeyframes =
                        keyframesFor [ easingTranslateConfig Linear ]
                in
                springKeyframes
                    |> Expect.notEqual linearKeyframes
        , test "noWobble spring keyframes differ from linear-easing keyframes" <|
            \_ ->
                let
                    springKeyframes =
                        keyframesFor [ springTranslateConfig Spring.noWobble ]

                    linearKeyframes =
                        keyframesFor [ easingTranslateConfig Linear ]
                in
                springKeyframes
                    |> Expect.notEqual linearKeyframes
        , test "different springs produce different keyframes" <|
            \_ ->
                let
                    wobblyKeyframes =
                        keyframesFor [ springTranslateConfig Spring.wobbly ]

                    stiffKeyframes =
                        keyframesFor [ springTranslateConfig Spring.stiff ]
                in
                wobblyKeyframes
                    |> Expect.notEqual stiffKeyframes
        ]
