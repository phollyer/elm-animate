module Anim.Engine.Transition.PerspectiveOriginQuerySpec exposing (suite)

import Anim.Engine.Transition as Transition
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Expect
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "card"


animatedState : Transition.AnimState
animatedState =
    Transition.init [ PerspectiveOrigin.initPercent groupName 50 50 ]
        |> (\state ->
                Transition.animate state <|
                    PerspectiveOrigin.for groupName
                        >> PerspectiveOrigin.percent
                        >> PerspectiveOrigin.toXY 90 10
                        >> PerspectiveOrigin.duration 1000
                        >> PerspectiveOrigin.build
           )


suite : Test
suite =
    describe "Transition PerspectiveOrigin property queries"
        [ test "getPerspectiveOriginEnd returns the configured end value" <|
            \_ ->
                Transition.getPerspectiveOriginEnd groupName animatedState
                    |> Expect.equal (Just { x = 90, y = 10 })
        , test "getPerspectiveOriginEnd is Nothing for unknown group" <|
            \_ ->
                Transition.getPerspectiveOriginEnd "missing" animatedState
                    |> Expect.equal Nothing
        ]
