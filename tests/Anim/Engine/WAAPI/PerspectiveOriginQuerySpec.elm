module Anim.Engine.WAAPI.PerspectiveOriginQuerySpec exposing (suite)

import Anim.Engine.WAAPI as WAAPI
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "card"


type Msg
    = NoOp


fakeCommandPort : Encode.Value -> Cmd Msg
fakeCommandPort _ =
    Cmd.none


fakeSubscriptionPort : (Decode.Value -> Msg) -> Sub Msg
fakeSubscriptionPort _ =
    Sub.none


initWith : List (WAAPI.EngineBuilder -> WAAPI.EngineBuilder) -> WAAPI.AnimState Msg
initWith =
    WAAPI.init fakeCommandPort fakeSubscriptionPort


animate : (WAAPI.EngineBuilder -> WAAPI.EngineBuilder) -> WAAPI.AnimState Msg -> WAAPI.AnimState Msg
animate config state =
    WAAPI.animate state config
        |> Tuple.first


animatedState : WAAPI.AnimState Msg
animatedState =
    initWith [ PerspectiveOrigin.initPercent groupName 50 50 ]
        |> animate
            (PerspectiveOrigin.for groupName
                >> PerspectiveOrigin.percent
                >> PerspectiveOrigin.toXY 90 10
                >> PerspectiveOrigin.duration 1000
                >> PerspectiveOrigin.easing Linear
                >> PerspectiveOrigin.build
            )


suite : Test
suite =
    describe "WAAPI PerspectiveOrigin property queries"
        [ test "start/end/range are available after animate" <|
            \_ ->
                Expect.all
                    [ \_ ->
                        WAAPI.getPerspectiveOriginStart groupName animatedState
                            |> Expect.equal (Just { x = 50, y = 50 })
                    , \_ ->
                        WAAPI.getPerspectiveOriginEnd groupName animatedState
                            |> Expect.equal (Just { x = 90, y = 10 })
                    , \_ ->
                        WAAPI.getPerspectiveOriginRange groupName animatedState
                            |> Expect.equal
                                (Just
                                    { start = Just { x = 50, y = 50 }
                                    , end = { x = 90, y = 10 }
                                    }
                                )
                    ]
                    ()
        , test "current reads from the latest snapshot" <|
            \_ ->
                initWith [ PerspectiveOrigin.initPercent groupName 40 60 ]
                    |> WAAPI.getPerspectiveOriginCurrent groupName
                    |> Expect.equal (Just { x = 40, y = 60 })
        , test "current is Nothing for unknown group" <|
            \_ ->
                initWith []
                    |> WAAPI.getPerspectiveOriginCurrent "missing"
                    |> Expect.equal Nothing
        ]
