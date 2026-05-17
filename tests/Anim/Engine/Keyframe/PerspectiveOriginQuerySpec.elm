module Anim.Engine.Keyframe.PerspectiveOriginQuerySpec exposing (suite)

import Anim.Engine.Keyframe as Keyframe
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "card"


animatedState : Keyframe.AnimState
animatedState =
    Keyframe.init [ PerspectiveOrigin.initPercent groupName 50 50 ]
        |> (\state ->
                Keyframe.animate state <|
                    PerspectiveOrigin.for groupName
                        >> PerspectiveOrigin.percent
                        >> PerspectiveOrigin.toXY 90 10
                        >> PerspectiveOrigin.duration 1000
                        >> PerspectiveOrigin.easing Linear
                        >> PerspectiveOrigin.build
           )


suite : Test
suite =
    describe "Keyframe PerspectiveOrigin property queries"
        [ test "start/end/range are available after animate" <|
            \_ ->
                Expect.all
                    [ \_ ->
                        Keyframe.getPerspectiveOriginStart groupName animatedState
                            |> Expect.equal (Just { x = 50, y = 50 })
                    , \_ ->
                        Keyframe.getPerspectiveOriginEnd groupName animatedState
                            |> Expect.equal (Just { x = 90, y = 10 })
                    , \_ ->
                        Keyframe.getPerspectiveOriginRange groupName animatedState
                            |> Expect.equal
                                (Just
                                    { start = Just { x = 50, y = 50 }
                                    , end = { x = 90, y = 10 }
                                    }
                                )
                    ]
                    ()
        , test "queries are Nothing for unknown group" <|
            \_ ->
                Expect.all
                    [ \_ ->
                        Keyframe.getPerspectiveOriginStart "missing" animatedState
                            |> Expect.equal Nothing
                    , \_ ->
                        Keyframe.getPerspectiveOriginEnd "missing" animatedState
                            |> Expect.equal Nothing
                    , \_ ->
                        Keyframe.getPerspectiveOriginRange "missing" animatedState
                            |> Expect.equal Nothing
                    ]
                    ()
        ]
