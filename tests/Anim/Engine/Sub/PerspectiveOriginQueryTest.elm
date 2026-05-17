module Anim.Engine.Sub.PerspectiveOriginQueryTest exposing (suite)

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "card"


baseState : Sub.AnimState
baseState =
    Sub.init [ PerspectiveOrigin.initPercent groupName 50 50 ]


animatedState : Sub.AnimState
animatedState =
    Sub.animate baseState <|
        PerspectiveOrigin.for groupName
            >> PerspectiveOrigin.percent
            >> PerspectiveOrigin.toXY 90 10
            >> PerspectiveOrigin.duration 1000
            >> PerspectiveOrigin.easing Linear
            >> PerspectiveOrigin.build


step : Float -> Sub.AnimState -> Sub.AnimState
step deltaMs state =
    Sub.update (Internal.AnimationFrame deltaMs) state
        |> Tuple.first


within : Float -> Float -> Float -> Expect.Expectation
within tolerance expected actual =
    if abs (expected - actual) <= tolerance then
        Expect.pass

    else
        Expect.fail
            ("Expected "
                ++ String.fromFloat actual
                ++ " to be within "
                ++ String.fromFloat tolerance
                ++ " of "
                ++ String.fromFloat expected
            )


suite : Test
suite =
    describe "Sub PerspectiveOrigin property queries"
        [ test "start/end/range are available after animate" <|
            \_ ->
                Expect.all
                    [ \_ ->
                        Sub.getPerspectiveOriginStart groupName animatedState
                            |> Expect.equal (Just { x = 50, y = 50 })
                    , \_ ->
                        Sub.getPerspectiveOriginEnd groupName animatedState
                            |> Expect.equal (Just { x = 90, y = 10 })
                    , \_ ->
                        Sub.getPerspectiveOriginRange groupName animatedState
                            |> Expect.equal
                                (Just
                                    { start = Just { x = 50, y = 50 }
                                    , end = { x = 90, y = 10 }
                                    }
                                )
                    ]
                    ()
        , test "current interpolates while running" <|
            \_ ->
                let
                    mid =
                        animatedState |> step 500
                in
                case Sub.getPerspectiveOriginCurrent groupName mid of
                    Just current ->
                        Expect.all
                            [ \_ -> within 0.001 70 current.x
                            , \_ -> within 0.001 30 current.y
                            ]
                            ()

                    Nothing ->
                        Expect.fail "Expected a current perspective origin value"
        ]
