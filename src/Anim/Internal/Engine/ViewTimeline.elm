module Anim.Internal.Engine.ViewTimeline exposing
    ( AnimEvent(..)
    , AnimMsg(..)
    , TimelineBuilder
    , alternate
    , animate
    , attributes
    , discreteEntry
    , discreteExit
    , easing
    , horizontal
    , iterations
    , rangeEnd
    , rangeStart
    , spring
    , subscriptions
    , transformOrder
    , update
    )

import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Internal.Engine.WAAPI.Timeline as Timeline
import Easing exposing (Easing)
import Html
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


type AnimMsg
    = JavascriptUpdate Decode.Value
    | Ignored


type alias AnimGroupName =
    String


type alias TimelineBuilder =
    Builder.AnimBuilder Builder.ForViewTimeline



-- ============================================================
-- TRIGGER
-- ============================================================


animate : (Encode.Value -> Cmd msg) -> (TimelineBuilder -> TimelineBuilder) -> Cmd msg
animate sendToPort pipeline =
    Builder.init [ pipeline ]
        |> Encoder.encodeView
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
            if Timeline.isAnimationUpdateFor Timeline.ViewTimeline jsonValue then
                decodeViewEvent jsonValue |> Maybe.map toMsg

            else
                Nothing

        Ignored ->
            Nothing


decodeViewEvent : Decode.Value -> Maybe AnimEvent
decodeViewEvent jsonValue =
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
    case Decode.decodeValue (Decode.map3 viewStatusToEvent animGroupDecoder statusDecoder progressDecoder) jsonValue of
        Ok event ->
            Just event

        Err err ->
            Just (AnimError (Decode.errorToString err))


viewStatusToEvent : AnimGroupName -> String -> Float -> AnimEvent
viewStatusToEvent animGroup status progress =
    case status of
        "completed" ->
            Ended animGroup

        "cancelled" ->
            Cancelled animGroup progress

        "iteration" ->
            Iteration animGroup (round progress)

        unknown ->
            AnimError ("Unknown view status: " ++ unknown)



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


subscriptions : (AnimMsg -> msg) -> ((Decode.Value -> msg) -> Sub msg) -> Sub msg
subscriptions toMsg portSubscription =
    portSubscription <|
        toMsg
            << Timeline.routeForEngine Timeline.ViewTimeline JavascriptUpdate Ignored



-- ============================================================
-- VIEW
-- ============================================================


attributes : AnimGroupName -> List (Html.Attribute msg)
attributes animGroupName =
    [ Html.Attributes.attribute "data-anim-target" animGroupName ]



-- ============================================================
-- RANGE
-- ============================================================


rangeStart : String -> TimelineBuilder -> TimelineBuilder
rangeStart =
    Builder.setViewRangeStart


rangeEnd : String -> TimelineBuilder -> TimelineBuilder
rangeEnd =
    Builder.setViewRangeEnd



-- ============================================================
-- AXIS
-- ============================================================


horizontal : TimelineBuilder -> TimelineBuilder
horizontal =
    Builder.setScrollAxis "inline"



-- ============================================================
-- PLAYBACK
-- ============================================================


iterations : Int -> TimelineBuilder -> TimelineBuilder
iterations =
    Builder.iterations


alternate : TimelineBuilder -> TimelineBuilder
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


easing : Easing -> TimelineBuilder -> TimelineBuilder
easing =
    Builder.easing



-- ============================================================
-- SPRING
-- ============================================================


spring : Spring -> TimelineBuilder -> TimelineBuilder
spring =
    Builder.spring



-- ============================================================
-- PROPERTIES
-- ============================================================


transformOrder : List TransformProperty -> TimelineBuilder -> TimelineBuilder
transformOrder =
    Builder.transformOrder


discreteEntry : String -> String -> TimelineBuilder -> TimelineBuilder
discreteEntry =
    Builder.discreteEntry


discreteExit : String -> String -> String -> TimelineBuilder -> TimelineBuilder
discreteExit =
    Builder.discreteExit
