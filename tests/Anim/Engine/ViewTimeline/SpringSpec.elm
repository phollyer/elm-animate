module Anim.Engine.ViewTimeline.SpringSpec exposing (suite)

{-| End-to-end tests for spring-driven animation through the public
`Anim.Engine.ViewTimeline` API.

ViewTimeline reuses the WAAPI encoder, so spring-as-keyframes
playback already works once the spring propagates through to
`config.spring`. Here we verify the public `spring` setter does
propagate, and the encoded JSON contains the spring keyframes.

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.ViewTimeline as ViewTimelineInternal
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.Opacity as Opacity
import Motion.Easing as Easing exposing (Easing(..))
import Expect
import Json.Encode as Encode
import Motion.Spring as Spring
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Anim.Engine.ViewTimeline spring support"
        [ test "global spring propagates to per-property processed config" <|
            \_ ->
                builderWithSpring Spring.wobbly
                    |> extractOpacitySpring
                    |> Expect.equal (Just (Just Spring.wobbly))
        , test "encodeView output contains easingKeyframes when spring is set" <|
            \_ ->
                builderWithSpring Spring.wobbly
                    |> Encoder.encodeView
                    |> Encode.encode 0
                    |> String.contains "\"easingKeyframes\":["
                    |> Expect.equal True
        , test "encodeView output uses easing=\"linear\" when spring is set" <|
            \_ ->
                builderWithSpring Spring.wobbly
                    |> Encoder.encodeView
                    |> Encode.encode 0
                    |> String.contains "\"easing\":\"linear\""
                    |> Expect.equal True
        , test "spring vs easing mutual exclusion (spring after easing)" <|
            \_ ->
                Builder.init []
                    |> ViewTimelineInternal.easing BounceOut
                    |> ViewTimelineInternal.spring Spring.stiff
                    |> applyOpacity
                    |> extractOpacitySpring
                    |> Expect.equal (Just (Just Spring.stiff))
        ]



-- ============================================================
-- HELPERS
-- ============================================================


builderWithSpring : Spring.Spring -> ViewTimelineInternal.TimelineBuilder
builderWithSpring s =
    Builder.init []
        |> ViewTimelineInternal.spring s
        |> applyOpacity


applyOpacity : ViewTimelineInternal.TimelineBuilder -> ViewTimelineInternal.TimelineBuilder
applyOpacity =
    Opacity.for "el"
        >> Opacity.to 0.5
        >> Opacity.build


extractOpacitySpring : ViewTimelineInternal.TimelineBuilder -> Maybe (Maybe Spring.Spring)
extractOpacitySpring builder =
    Builder.process builder
        |> .groups
        |> AnimGroups.toList
        |> List.head
        |> Maybe.map Tuple.second
        |> Maybe.andThen
            (\group ->
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
            )
        |> Maybe.map .spring
