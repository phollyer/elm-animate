module Anim.Engine.WAAPI.ScrollTimeline.TestEvents exposing (suite)

import Anim.Engine.WAAPI.ScrollTimeline as ScrollTimeline
import Anim.Internal.Engine.WAAPI.ScrollTimeline as ScrollTimelineInternal
import Expect
import Json.Encode as Encode
import Test exposing (..)


suite : Test
suite =
    describe "Anim.Engine.WAAPI.ScrollTimeline events"
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
                buildScrollEvent "scrollTimeline" "myGroup" "completed" 1.0
                    |> ScrollTimeline.update
                    |> Expect.equal (ScrollTimeline.Ended "myGroup")
        , test "falls back to payload.elementId when animGroup is absent" <|
            \_ ->
                buildScrollEventWithElementId "scrollTimeline" "el123" "completed" 1.0
                    |> ScrollTimeline.update
                    |> Expect.equal (ScrollTimeline.Ended "el123")
        ]


cancelledStatusTests : Test
cancelledStatusTests =
    describe "cancelled status"
        [ test "returns Cancelled with animGroup and progress" <|
            \_ ->
                buildScrollEvent "scrollTimeline" "myGroup" "cancelled" 0.5
                    |> ScrollTimeline.update
                    |> Expect.equal (ScrollTimeline.Cancelled "myGroup" 0.5)
        , test "returns Cancelled with zero progress" <|
            \_ ->
                buildScrollEvent "scrollTimeline" "myGroup" "cancelled" 0.0
                    |> ScrollTimeline.update
                    |> Expect.equal (ScrollTimeline.Cancelled "myGroup" 0.0)
        ]


iterationStatusTests : Test
iterationStatusTests =
    describe "iteration status"
        [ test "returns Iteration with rounded count" <|
            \_ ->
                buildScrollEvent "scrollTimeline" "myGroup" "iteration" 3.0
                    |> ScrollTimeline.update
                    |> Expect.equal (ScrollTimeline.Iteration "myGroup" 3)
        , test "rounds iteration count" <|
            \_ ->
                buildScrollEvent "scrollTimeline" "myGroup" "iteration" 2.7
                    |> ScrollTimeline.update
                    |> Expect.equal (ScrollTimeline.Iteration "myGroup" 3)
        ]


wrongEngineTests : Test
wrongEngineTests =
    describe "wrong engine field"
        [ test "returns NoEvent for waapi engine" <|
            \_ ->
                buildScrollEvent "waapi" "myGroup" "completed" 1.0
                    |> ScrollTimeline.update
                    |> Expect.equal ScrollTimeline.NoEvent
        , test "returns NoEvent for viewTimeline engine" <|
            \_ ->
                buildScrollEvent "viewTimeline" "myGroup" "completed" 1.0
                    |> ScrollTimeline.update
                    |> Expect.equal ScrollTimeline.NoEvent
        , test "returns NoEvent for unknown engine" <|
            \_ ->
                buildScrollEvent "other" "myGroup" "completed" 1.0
                    |> ScrollTimeline.update
                    |> Expect.equal ScrollTimeline.NoEvent
        ]


missingTypeTests : Test
missingTypeTests =
    describe "missing type field"
        [ test "returns NoEvent when type field is absent" <|
            \_ ->
                ScrollTimelineInternal.JavascriptUpdate
                    (Encode.object
                        [ ( "engine", Encode.string "scrollTimeline" )
                        , ( "payload"
                          , Encode.object
                                [ ( "animGroup", Encode.string "myGroup" )
                                , ( "status", Encode.string "completed" )
                                , ( "progress", Encode.float 1.0 )
                                ]
                          )
                        ]
                    )
                    |> ScrollTimeline.update
                    |> Expect.equal ScrollTimeline.NoEvent
        , test "returns NoEvent for unrecognised type" <|
            \_ ->
                ScrollTimelineInternal.JavascriptUpdate
                    (Encode.object
                        [ ( "type", Encode.string "somethingElse" )
                        , ( "engine", Encode.string "scrollTimeline" )
                        ]
                    )
                    |> ScrollTimeline.update
                    |> Expect.equal ScrollTimeline.NoEvent
        ]


malformedPayloadTests : Test
malformedPayloadTests =
    describe "malformed payload"
        [ test "returns AnimError when status is unrecognised" <|
            \_ ->
                buildScrollEvent "scrollTimeline" "myGroup" "unknown" 0.5
                    |> ScrollTimeline.update
                    |> isAnimError
        , test "returns AnimError when progress field is missing" <|
            \_ ->
                ScrollTimelineInternal.JavascriptUpdate
                    (Encode.object
                        [ ( "type", Encode.string "animationUpdate" )
                        , ( "engine", Encode.string "scrollTimeline" )
                        , ( "payload"
                          , Encode.object
                                [ ( "animGroup", Encode.string "myGroup" )
                                , ( "status", Encode.string "completed" )
                                ]
                          )
                        ]
                    )
                    |> ScrollTimeline.update
                    |> isAnimError
        ]



-- Helpers


buildScrollEvent : String -> String -> String -> Float -> ScrollTimeline.AnimMsg
buildScrollEvent engine animGroup status progress =
    ScrollTimelineInternal.JavascriptUpdate
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


buildScrollEventWithElementId : String -> String -> String -> Float -> ScrollTimeline.AnimMsg
buildScrollEventWithElementId engine elementId status progress =
    ScrollTimelineInternal.JavascriptUpdate
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


isAnimError : ScrollTimeline.AnimEvent -> Expect.Expectation
isAnimError event =
    case event of
        ScrollTimeline.AnimError _ ->
            Expect.pass

        other ->
            Expect.fail ("Expected AnimError but got: " ++ Debug.toString other)
