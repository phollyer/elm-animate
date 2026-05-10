module Anim.Engine.Transition.SpringSpec exposing (suite)

{-| End-to-end tests for spring-driven animation through the public
`Anim.Engine.Transition` API.

CSS `transition` cannot express true spring physics (only a single
cubic-bezier per property), so the Transition engine falls back to a
fixed overshoot bezier when a spring is set. Duration is still
overridden to the spring's settle time.

-}

import Anim.Engine.Transition as Transition
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.Transition.Generator as Generator
import Anim.Internal.Property.Opacity as InternalOpacity
import Anim.Property.Opacity as Opacity
import Expect
import Motion.Easing exposing (Easing(..))
import Motion.Spring as Spring
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Anim.Engine.Transition spring support"
        [ globalSpringTests
        , mutualExclusionTests
        , generatedCssTests
        ]



-- ============================================================
-- HELPERS
-- ============================================================


initBuilder : Transition.AnimBuilder mode
initBuilder =
    Builder.init []


animateOpacityTo : Float -> Transition.AnimBuilder mode -> Transition.AnimBuilder mode
animateOpacityTo target =
    Opacity.for "el"
        >> Opacity.to target
        >> Opacity.build


extractOpacitySpring : Builder.AnimBuilder mode -> Maybe (Maybe Spring.Spring)
extractOpacitySpring builder =
    Builder.process builder
        |> .groups
        |> firstGroupConfig
        |> Maybe.andThen firstOpacity
        |> Maybe.map .spring


extractOpacityEasing : Builder.AnimBuilder mode -> Maybe Easing
extractOpacityEasing builder =
    Builder.process builder
        |> .groups
        |> firstGroupConfig
        |> Maybe.andThen firstOpacity
        |> Maybe.map .easing


firstGroupConfig :
    AnimGroups.AnimGroups Builder.ProcessedAnimGroupConfig
    -> Maybe Builder.ProcessedAnimGroupConfig
firstGroupConfig groups =
    AnimGroups.toList groups
        |> List.head
        |> Maybe.map Tuple.second


firstOpacity :
    Builder.ProcessedAnimGroupConfig
    -> Maybe (Builder.ProcessedAnimationConfig InternalOpacity.Opacity)
firstOpacity group =
    group.properties
        |> List.filterMap
            (\p ->
                case p of
                    Builder.ProcessedOpacityConfig cfg ->
                        Just cfg

                    _ ->
                        Nothing
            )
        |> List.head


generatedTransition : Builder.AnimBuilder mode -> String
generatedTransition builder =
    let
        processed =
            Builder.process builder

        firstGroup =
            firstGroupConfig processed.groups
    in
    case firstGroup of
        Just group ->
            Generator.generate group.properties

        Nothing ->
            ""



-- ============================================================
-- GLOBAL SPRING DEFAULT
-- ============================================================


globalSpringTests : Test
globalSpringTests =
    describe "global Transition.spring default"
        [ test "is picked up by properties that don't set their own" <|
            \_ ->
                initBuilder
                    |> Transition.spring Spring.wobbly
                    |> animateOpacityTo 0.5
                    |> extractOpacitySpring
                    |> Expect.equal (Just (Just Spring.wobbly))
        , test "per-property spring overrides global" <|
            \_ ->
                initBuilder
                    |> Transition.spring Spring.wobbly
                    |> (Opacity.for "el"
                            >> Opacity.to 0.5
                            >> Opacity.spring Spring.stiff
                            >> Opacity.build
                       )
                    |> extractOpacitySpring
                    |> Expect.equal (Just (Just Spring.stiff))
        ]



-- ============================================================
-- MUTUAL EXCLUSION
-- ============================================================


mutualExclusionTests : Test
mutualExclusionTests =
    describe "spring vs easing mutual exclusion"
        [ test "Transition.spring after Transition.easing clears the easing" <|
            \_ ->
                initBuilder
                    |> Transition.easing BounceOut
                    |> Transition.spring Spring.wobbly
                    |> animateOpacityTo 0.5
                    |> extractOpacitySpring
                    |> Expect.equal (Just (Just Spring.wobbly))
        , test "Transition.easing after Transition.spring clears the spring" <|
            \_ ->
                let
                    result =
                        initBuilder
                            |> Transition.spring Spring.wobbly
                            |> Transition.easing BounceOut
                            |> animateOpacityTo 0.5
                in
                ( extractOpacitySpring result, extractOpacityEasing result )
                    |> Expect.equal ( Just Nothing, Just BounceOut )
        ]



-- ============================================================
-- GENERATED CSS
-- ============================================================


generatedCssTests : Test
generatedCssTests =
    describe "generated CSS transition string"
        [ test "spring config emits the overshoot cubic-bezier" <|
            \_ ->
                initBuilder
                    |> Transition.spring Spring.wobbly
                    |> animateOpacityTo 0.5
                    |> generatedTransition
                    |> String.contains "cubic-bezier(0.34, 1.56, 0.64, 1)"
                    |> Expect.equal True
        , test "no-spring + Linear easing emits 'linear'" <|
            \_ ->
                initBuilder
                    |> Transition.duration 500
                    |> Transition.easing Linear
                    |> animateOpacityTo 0.5
                    |> generatedTransition
                    |> String.contains "linear"
                    |> Expect.equal True
        , test "no-spring + Linear easing does NOT emit overshoot bezier" <|
            \_ ->
                initBuilder
                    |> Transition.duration 500
                    |> Transition.easing Linear
                    |> animateOpacityTo 0.5
                    |> generatedTransition
                    |> String.contains "0.34, 1.56"
                    |> Expect.equal False
        , test "spring config emits a non-zero duration" <|
            \_ ->
                let
                    css =
                        initBuilder
                            |> Transition.spring Spring.wobbly
                            |> animateOpacityTo 0.5
                            |> generatedTransition
                in
                -- The CSS string should not contain "0ms" for the
                -- transition duration (settle time should be > 0).
                css
                    |> String.startsWith "opacity 0ms"
                    |> Expect.equal False
        ]
