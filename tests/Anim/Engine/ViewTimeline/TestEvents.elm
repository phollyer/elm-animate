module Anim.Engine.ViewTimeline.TestEvents exposing (suite)

import Anim.Engine.ViewTimeline as ViewTimeline
import Anim.Internal.Engine.ViewTimeline as ViewTimelineInternal
import Expect
import Json.Encode as Encode
import Test exposing (..)


suite : Test
suite =
    describe "Anim.Engine.ViewTimeline events"
        [ completedStatusTests
        , cancelledStatusTests
        , iterationStatusTests
        , wrongEngineTests
        , missingTypeTests
        , malformedPayloadTests
        ]


completedStatusTests : Test
completedStatusTests =
    describe "completed status"
        [ test "returns Ended with animGroup from payload.animGroup" <|
            \_ ->
                buildViewEvent "viewTimeline" "heroCard" "completed" 1.0
                    |> ViewTimeline.update
                    |> Expect.equal (Just (ViewTimeline.Ended "heroCard"))
        , test "falls back to payload.elementId when animGroup is absent" <|
            \_ ->
                buildViewEventWithElementId "viewTimeline" "el456" "completed" 1.0
                    |> ViewTimeline.update
                    |> Expect.equal (Just (ViewTimeline.Ended "el456"))
        ]


cancelledStatusTests : Test
cancelledStatusTests =
    describe "cancelled status"
        [ test "returns Cancelled with animGroup and progress" <|
            \_ ->
                buildViewEvent "viewTimeline" "heroCard" "cancelled" 0.5
                    |> ViewTimeline.update
                    |> Expect.equal (Just (ViewTimeline.Cancelled "heroCard" 0.5))
        , test "returns Cancelled with zero progress" <|
            \_ ->
                buildViewEvent "viewTimeline" "heroCard" "cancelled" 0.0
                    |> ViewTimeline.update
                    |> Expect.equal (Just (ViewTimeline.Cancelled "heroCard" 0.0))
        ]


iterationStatusTests : Test
iterationStatusTests =
    describe "iteration status"
        [ test "returns Iteration with rounded count" <|
            \_ ->
                buildViewEvent "viewTimeline" "heroCard" "iteration" 3.0
                    |> ViewTimeline.update
                    |> Expect.equal (Just (ViewTimeline.Iteration "heroCard" 3))
        , test "rounds iteration count" <|
            \_ ->
                buildViewEvent "viewTimeline" "heroCard" "iteration" 2.7
                    |> ViewTimeline.update
                    |> Expect.equal (Just (ViewTimeline.Iteration "heroCard" 3))
        ]


wrongEngineTests : Test
wrongEngineTests =
    describe "wrong engine field"
        [ test "returns Nothing for waapi engine" <|
            \_ ->
                buildViewEvent "waapi" "heroCard" "completed" 1.0
                    |> ViewTimeline.update
                    |> Expect.equal Nothing
        , test "returns Nothing for scrollTimeline engine" <|
            \_ ->
                buildViewEvent "scrollTimeline" "heroCard" "completed" 1.0
                    |> ViewTimeline.update
                    |> Expect.equal Nothing
        , test "returns Nothing for unknown engine" <|
            \_ ->
                buildViewEvent "other" "heroCard" "completed" 1.0
                    |> ViewTimeline.update
                    |> Expect.equal Nothing
        ]


missingTypeTests : Test
missingTypeTests =
    describe "missing type field"
        [ test "returns Nothing when type field is absent" <|
            \_ ->
                ViewTimelineInternal.JavascriptUpdate
                    (Encode.object
                        [ ( "engine", Encode.string "viewTimeline" )
                        , ( "payload"
                          , Encode.object
                                [ ( "animGroup", Encode.string "heroCard" )
                                , ( "status", Encode.string "completed" )
                                , ( "progress", Encode.float 1.0 )
                                ]
                          )
                        ]
                    )
                    |> ViewTimeline.update
                    |> Expect.equal Nothing
        , test "returns Nothing for unrecognised type" <|
            \_ ->
                ViewTimelineInternal.JavascriptUpdate
                    (Encode.object
                        [ ( "type", Encode.string "somethingElse" )
                        , ( "engine", Encode.string "viewTimeline" )
                        ]
                    )
                    |> ViewTimeline.update
                    |> Expect.equal Nothing
        ]


malformedPayloadTests : Test
malformedPayloadTests =
    describe "malformed payload"
        [ test "returns AnimError when status is unrecognised" <|
            \_ ->
                buildViewEvent "viewTimeline" "heroCard" "unknown" 0.5
                    |> ViewTimeline.update
                    |> isAnimError
        , test "returns AnimError when progress field is missing" <|
            \_ ->
                ViewTimelineInternal.JavascriptUpdate
                    (Encode.object
                        [ ( "type", Encode.string "animationUpdate" )
                        , ( "engine", Encode.string "viewTimeline" )
                        , ( "payload"
                          , Encode.object
                                [ ( "animGroup", Encode.string "heroCard" )
                                , ( "status", Encode.string "completed" )
                                ]
                          )
                        ]
                    )
                    |> ViewTimeline.update
                    |> isAnimError
        ]



-- Helpers


buildViewEvent : String -> String -> String -> Float -> ViewTimeline.AnimMsg
buildViewEvent engine animGroup status progress =
    ViewTimelineInternal.JavascriptUpdate
        (Encode.object
            [ ( "type", Encode.string "animationUpdate" )
            , ( "engine", Encode.string engine )
            , ( "payload"
              , Encode.object
                    [ ( "animGroup", Encode.string animGroup )
                    , ( "status", Encode.string status )
                    , ( "progress", Encode.float progress )
                    ]
              )
            ]
        )


buildViewEventWithElementId : String -> String -> String -> Float -> ViewTimeline.AnimMsg
buildViewEventWithElementId engine elementId status progress =
    ViewTimelineInternal.JavascriptUpdate
        (Encode.object
            [ ( "type", Encode.string "animationUpdate" )
            , ( "engine", Encode.string engine )
            , ( "payload"
              , Encode.object
                    [ ( "elementId", Encode.string elementId )
                    , ( "status", Encode.string status )
                    , ( "progress", Encode.float progress )
                    ]
              )
            ]
        )


isAnimError : Maybe ViewTimeline.AnimEvent -> Expect.Expectation
isAnimError maybeEvent =
    case maybeEvent of
        Just (ViewTimeline.AnimError _) ->
            Expect.pass

        other ->
            Expect.fail ("Expected AnimError but got: " ++ Debug.toString other)
