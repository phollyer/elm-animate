module Anim.Engine.WAAPI.SpringSpec exposing (suite)

{-| End-to-end tests for spring-driven animation through the public
`Anim.Engine.WAAPI` API.

The plumbing is exercised top-down: a user-style builder pipeline is
fed into `Builder.process`, the resulting `ProcessedAnimationConfig`
is inspected for the spring field, and the JSON payload emitted by
`Encoder.encodeProcessedData` is checked for the expected
`easing: "linear"` + `easingKeyframes: [...]` shape.

-}

import Anim.Engine.WAAPI as WAAPI
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Internal.Property.Opacity as InternalOpacity
import Anim.Property.Opacity as Opacity
import Expect
import Json.Encode as Encode
import Motion.Easing exposing (Easing(..))
import Motion.Spring as Spring
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Anim.Engine.WAAPI spring support"
        [ globalSpringTests
        , mutualExclusionTests
        , encoderTests
        ]



-- ============================================================
-- HELPERS
-- ============================================================


initBuilder : WAAPI.AnimBuilder mode
initBuilder =
    Builder.init []


animateOpacityTo : Float -> WAAPI.AnimBuilder mode -> WAAPI.AnimBuilder mode
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


encodedJsonString : Builder.AnimBuilder mode -> String
encodedJsonString builder =
    Builder.process builder
        |> Encoder.encodeProcessedData
        |> Encode.encode 0



-- ============================================================
-- GLOBAL SPRING DEFAULT
-- ============================================================


globalSpringTests : Test
globalSpringTests =
    describe "global WAAPI.spring default"
        [ test "is picked up by properties that don't set their own" <|
            \_ ->
                initBuilder
                    |> WAAPI.spring Spring.wobbly
                    |> animateOpacityTo 0.5
                    |> extractOpacitySpring
                    |> Expect.equal (Just (Just Spring.wobbly))
        , test "per-property spring overrides global" <|
            \_ ->
                initBuilder
                    |> WAAPI.spring Spring.wobbly
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
        [ test "WAAPI.spring after WAAPI.easing clears the easing" <|
            \_ ->
                initBuilder
                    |> WAAPI.easing BounceOut
                    |> WAAPI.spring Spring.wobbly
                    |> animateOpacityTo 0.5
                    |> extractOpacitySpring
                    |> Expect.equal (Just (Just Spring.wobbly))
        , test "WAAPI.easing after WAAPI.spring clears the spring" <|
            \_ ->
                let
                    result =
                        initBuilder
                            |> WAAPI.spring Spring.wobbly
                            |> WAAPI.easing BounceOut
                            |> animateOpacityTo 0.5
                in
                ( extractOpacitySpring result, extractOpacityEasing result )
                    |> Expect.equal ( Just Nothing, Just BounceOut )
        ]



-- ============================================================
-- ENCODER OUTPUT
-- ============================================================


encoderTests : Test
encoderTests =
    describe "Encoder spring output"
        [ test "spring config emits easing=\"linear\"" <|
            \_ ->
                initBuilder
                    |> WAAPI.spring Spring.wobbly
                    |> animateOpacityTo 0.5
                    |> encodedJsonString
                    |> String.contains "\"easing\":\"linear\""
                    |> Expect.equal True
        , test "spring config emits an easingKeyframes array" <|
            \_ ->
                initBuilder
                    |> WAAPI.spring Spring.wobbly
                    |> animateOpacityTo 0.5
                    |> encodedJsonString
                    |> String.contains "\"easingKeyframes\":["
                    |> Expect.equal True
        , test "no-spring + simple easing does NOT emit easingKeyframes" <|
            \_ ->
                initBuilder
                    |> WAAPI.easing Linear
                    |> animateOpacityTo 0.5
                    |> encodedJsonString
                    |> String.contains "easingKeyframes"
                    |> Expect.equal False
        , test "different springs produce different JSON" <|
            \_ ->
                let
                    wobblyJson =
                        initBuilder
                            |> WAAPI.spring Spring.wobbly
                            |> animateOpacityTo 0.5
                            |> encodedJsonString

                    stiffJson =
                        initBuilder
                            |> WAAPI.spring Spring.stiff
                            |> animateOpacityTo 0.5
                            |> encodedJsonString
                in
                wobblyJson
                    |> Expect.notEqual stiffJson
        ]
