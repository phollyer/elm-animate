module Anim.Engine.ScrollTimeline.SpringSpec exposing (suite)

{-| End-to-end tests for spring-driven animation through the public
`Anim.Engine.ScrollTimeline` API.

ScrollTimeline reuses the WAAPI encoder, so spring-as-keyframes
playback already works once the spring propagates through to
`config.spring`. Here we verify the public `spring` setter does
propagate, and the encoded JSON contains the spring keyframes.

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.ScrollTimeline as ScrollTimelineInternal
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Property.Opacity as Opacity
import Easing exposing (Easing(..))
import Expect
import Json.Encode as Encode
import Motion.Spring as Spring
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Anim.Engine.ScrollTimeline spring support"
        [ test "global spring propagates to per-property processed config" <|
            \_ ->
                builderWithSpring Spring.wobbly
                    |> extractOpacitySpring
                    |> Expect.equal (Just (Just Spring.wobbly))
        , test "encodeScroll output contains easingKeyframes when spring is set" <|
            \_ ->
                builderWithSpring Spring.wobbly
                    |> Builder.setScrollSource "document"
                    |> Encoder.encodeScroll
                    |> Encode.encode 0
                    |> String.contains "\"easingKeyframes\":["
                    |> Expect.equal True
        , test "encodeScroll output uses easing=\"linear\" when spring is set" <|
            \_ ->
                builderWithSpring Spring.wobbly
                    |> Builder.setScrollSource "document"
                    |> Encoder.encodeScroll
                    |> Encode.encode 0
                    |> String.contains "\"easing\":\"linear\""
                    |> Expect.equal True
        , test "spring vs easing mutual exclusion (spring after easing)" <|
            \_ ->
                Builder.init []
                    |> ScrollTimelineInternal.easing BounceOut
                    |> ScrollTimelineInternal.spring Spring.stiff
                    |> applyOpacity
                    |> extractOpacitySpring
                    |> Expect.equal (Just (Just Spring.stiff))
        ]



-- ============================================================
-- HELPERS
-- ============================================================


builderWithSpring : Spring.Spring -> ScrollTimelineInternal.TimelineBuilder
builderWithSpring s =
    Builder.init []
        |> ScrollTimelineInternal.spring s
        |> applyOpacity


applyOpacity : ScrollTimelineInternal.TimelineBuilder -> ScrollTimelineInternal.TimelineBuilder
applyOpacity =
    Opacity.for "el"
        >> Opacity.to 0.5
        >> Opacity.build


extractOpacitySpring : ScrollTimelineInternal.TimelineBuilder -> Maybe (Maybe Spring.Spring)
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
