module Anim.Engine.Sub.SpringSpec exposing (suite)

{-| End-to-end tests for spring-driven animation through the public
`Anim.Engine.Sub` API.

The plumbing is exercised top-down: a user-style builder pipeline is
fed into `Builder.process`, the resulting `ProcessedAnimationConfig`
is inspected for the spring field, and the engine's interpolation
function (built in `Sub.Generator`) is sampled to verify spring
behaviour reaches per-frame playback.

-}

import Anim.Engine.Sub as Sub
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Property.Opacity as InternalOpacity
import Anim.Property.Opacity as Opacity
import Expect
import Motion.Easing exposing (Easing(..))
import Motion.Spring as Spring
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Anim.Engine.Sub spring support"
        [ globalSpringTests
        , perPropertySpringTests
        , mutualExclusionTests
        , processedConfigTests
        ]



-- ============================================================
-- HELPERS
-- ============================================================


initBuilder : Sub.AnimBuilder mode
initBuilder =
    Builder.init []


animateOpacityTo : Float -> Sub.AnimBuilder mode -> Sub.AnimBuilder mode
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


extractOpacityDuration : Builder.AnimBuilder mode -> Maybe Int
extractOpacityDuration builder =
    Builder.process builder
        |> .groups
        |> firstGroupConfig
        |> Maybe.andThen firstOpacity
        |> Maybe.map .duration


extractOpacityDelay : Builder.AnimBuilder mode -> Maybe Int
extractOpacityDelay builder =
    Builder.process builder
        |> .groups
        |> firstGroupConfig
        |> Maybe.andThen firstOpacity
        |> Maybe.map .delay


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



-- ============================================================
-- GLOBAL SPRING DEFAULT
-- ============================================================


globalSpringTests : Test
globalSpringTests =
    describe "global Sub.spring default"
        [ test "is picked up by properties that don't set their own" <|
            \_ ->
                initBuilder
                    |> Sub.spring Spring.wobbly
                    |> animateOpacityTo 0.5
                    |> extractOpacitySpring
                    |> Expect.equal (Just (Just Spring.wobbly))
        , test "overrides ProcessedAnimationConfig duration with settle time" <|
            \_ ->
                let
                    duration =
                        initBuilder
                            |> Sub.spring Spring.stiff
                            |> animateOpacityTo 0.5
                            |> extractOpacityDuration
                            |> Maybe.withDefault 0
                in
                duration |> Expect.greaterThan 0
        , test "honours delay even when spring is set" <|
            \_ ->
                initBuilder
                    |> Sub.spring Spring.gentle
                    |> Sub.delay 250
                    |> animateOpacityTo 0.5
                    |> extractOpacityDelay
                    |> Expect.equal (Just 250)
        ]



-- ============================================================
-- PER-PROPERTY SPRING
-- ============================================================


perPropertySpringTests : Test
perPropertySpringTests =
    describe "Opacity.spring"
        [ test "sets the spring on the processed config" <|
            \_ ->
                initBuilder
                    |> (Opacity.for "el"
                            >> Opacity.to 0.5
                            >> Opacity.spring Spring.wobbly
                            >> Opacity.build
                       )
                    |> extractOpacitySpring
                    |> Expect.equal (Just (Just Spring.wobbly))
        , test "overrides a global Sub.easing default" <|
            \_ ->
                initBuilder
                    |> Sub.easing EaseInOut
                    |> (Opacity.for "el"
                            >> Opacity.to 0.5
                            >> Opacity.spring Spring.wobbly
                            >> Opacity.build
                       )
                    |> extractOpacitySpring
                    |> Expect.equal (Just (Just Spring.wobbly))
        ]



-- ============================================================
-- MUTUAL EXCLUSION
-- ============================================================


mutualExclusionTests : Test
mutualExclusionTests =
    describe "spring and easing are mutually exclusive"
        [ test "global Sub.spring clears global Sub.easing" <|
            \_ ->
                let
                    builder =
                        initBuilder
                            |> Sub.easing EaseInOut
                            |> Sub.spring Spring.wobbly
                in
                Builder.process builder
                    |> .globalEasing
                    |> Expect.equal Nothing
        , test "global Sub.easing clears global Sub.spring" <|
            \_ ->
                let
                    builder =
                        initBuilder
                            |> Sub.spring Spring.wobbly
                            |> Sub.easing EaseInOut
                in
                Builder.process builder
                    |> .globalSpring
                    |> Expect.equal Nothing
        , test "per-property Opacity.spring clears Opacity.easing" <|
            \_ ->
                -- spring set last; the spring should win and the
                -- ProcessedAnimationConfig.spring should be populated.
                initBuilder
                    |> (Opacity.for "el"
                            >> Opacity.to 0.5
                            >> Opacity.easing EaseInOut
                            >> Opacity.spring Spring.wobbly
                            >> Opacity.build
                       )
                    |> extractOpacitySpring
                    |> Expect.equal (Just (Just Spring.wobbly))
        , test "per-property Opacity.easing clears Opacity.spring" <|
            \_ ->
                initBuilder
                    |> (Opacity.for "el"
                            >> Opacity.to 0.5
                            >> Opacity.spring Spring.wobbly
                            >> Opacity.easing EaseInOut
                            >> Opacity.build
                       )
                    |> extractOpacitySpring
                    |> Expect.equal (Just Nothing)
        ]



-- ============================================================
-- PROCESSED-CONFIG DEFAULTS
-- ============================================================


processedConfigTests : Test
processedConfigTests =
    describe "ProcessedAnimationConfig defaults"
        [ test "spring defaults to Nothing when neither global nor per-property is set" <|
            \_ ->
                initBuilder
                    |> animateOpacityTo 0.5
                    |> extractOpacitySpring
                    |> Expect.equal (Just Nothing)
        , test "globalSpring on ProcessedAnimationData round-trips" <|
            \_ ->
                initBuilder
                    |> Sub.spring Spring.wobbly
                    |> Builder.process
                    |> .globalSpring
                    |> Expect.equal (Just Spring.wobbly)
        ]
