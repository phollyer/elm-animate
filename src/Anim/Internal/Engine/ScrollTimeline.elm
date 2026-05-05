module Anim.Internal.Engine.ScrollTimeline exposing
    ( AnimEvent(..)
    , AnimMsg(..)
    , ForScroll
    , alternate
    , animate
    , attributes
    , easing
    , horizontal
    , iterations
    , subscriptions
    , update
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Internal.Engine.WAAPI.Timeline as Timeline
import Easing exposing (Easing)
import Html
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode



-- ============================================================
-- TYPES
-- ============================================================


type AnimMsg
    = JavascriptUpdate Decode.Value
    | Ignored


type alias AnimGroupName =
    String


{-| Phantom mode for scroll-driven animations.
-}
type alias ForScroll =
    { isScrollBased : () }



-- ============================================================
-- TRIGGER
-- ============================================================


animate : (a -> String) -> (Encode.Value -> Cmd msg) -> a -> (AnimBuilder ForScroll -> AnimBuilder ForScroll) -> Cmd msg
animate containerToId sendToPort container pipeline =
    Builder.init [ pipeline ]
        |> Builder.setScrollSource (containerToId container)
        |> Encoder.encodeScroll
        |> sendToPort



-- ============================================================
-- EVENTS
-- ============================================================


type AnimEvent
    = Ended AnimGroupName
    | Cancelled AnimGroupName Float
    | Iteration AnimGroupName Int
    | AnimError String



-- ============================================================
-- UPDATE
-- ============================================================


update : (AnimEvent -> a) -> AnimMsg -> Maybe a
update toMsg msg =
    case msg of
        JavascriptUpdate jsonValue ->
            if Timeline.isAnimationUpdateFor Timeline.ScrollTimeline jsonValue then
                decodeScrollEvent jsonValue
                    |> Maybe.map toMsg

            else
                Nothing

        Ignored ->
            Nothing


decodeScrollEvent : Decode.Value -> Maybe AnimEvent
decodeScrollEvent jsonValue =
    let
        animGroupDecoder =
            Decode.oneOf
                [ Decode.at [ "payload", "animGroup" ] Decode.string
                , Decode.at [ "payload", "elementId" ] Decode.string
                ]

        statusDecoder =
            Decode.at [ "payload", "status" ] Decode.string

        progressDecoder =
            Decode.at [ "payload", "progress" ] Decode.float
    in
    case Decode.decodeValue (Decode.map3 scrollStatusToEvent animGroupDecoder statusDecoder progressDecoder) jsonValue of
        Ok event ->
            Just event

        Err err ->
            Just (AnimError (Decode.errorToString err))


scrollStatusToEvent : AnimGroupName -> String -> Float -> AnimEvent
scrollStatusToEvent animGroup status progress =
    case status of
        "completed" ->
            Ended animGroup

        "cancelled" ->
            Cancelled animGroup progress

        "iteration" ->
            Iteration animGroup (round progress)

        unknown ->
            AnimError ("Unknown scroll status: " ++ unknown)



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


subscriptions : (AnimMsg -> msg) -> ((Decode.Value -> msg) -> Sub msg) -> Sub msg
subscriptions toMsg portSubscription =
    portSubscription <|
        toMsg
            << Timeline.routeForEngine Timeline.ScrollTimeline JavascriptUpdate Ignored



-- ============================================================
-- VIEW
-- ============================================================


attributes : AnimGroupName -> List (Html.Attribute msg)
attributes animGroupName =
    [ Html.Attributes.attribute "data-anim-target" animGroupName ]



-- ============================================================
-- AXIS
-- ============================================================


horizontal : AnimBuilder ForScroll -> AnimBuilder ForScroll
horizontal =
    Builder.setScrollAxis "inline"



-- ============================================================
-- PLAYBACK
-- ============================================================


iterations : Int -> AnimBuilder ForScroll -> AnimBuilder ForScroll
iterations =
    Builder.iterations


alternate : AnimBuilder ForScroll -> AnimBuilder ForScroll
alternate builder =
    let
        withIterations =
            case Builder.getIterations builder of
                Builder.Once ->
                    Builder.iterations 2 builder

                _ ->
                    builder
    in
    Builder.alternate withIterations



-- ============================================================
-- EASING
-- ============================================================


easing : Easing -> AnimBuilder ForScroll -> AnimBuilder ForScroll
easing =
    Builder.easing
