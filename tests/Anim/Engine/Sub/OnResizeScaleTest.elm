module Anim.Engine.Sub.OnResizeScaleTest exposing (suite)

{-| Tests for the scale path of `Sub.onResize`. The math reuses the same
property-agnostic `Resize.applyAxis` helper as Translate, so this suite
focuses on verifying the wiring (group-wide default, per-property entry,
group-wide default override, and the strategy semantics for a settled
one-shot scale).
-}

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Scale as Scale
import Anim.Property.Translate as Translate
import Anim.Resize as Resize
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "box"


initialState : Sub.AnimState
initialState =
    Sub.init
        [ Translate.initXY groupName 0 0
        , Scale.initX groupName 1
        ]


scaleX : Float -> Sub.AnimBuilder mode -> Sub.AnimBuilder mode
scaleX target =
    Scale.for groupName
        >> Scale.toX target
        >> Scale.duration 1000
        >> Scale.easing Linear
        >> Scale.build


step : Float -> Sub.AnimState -> Sub.AnimState
step deltaMs state =
    Sub.update (Internal.AnimationFrame deltaMs) state
        |> Tuple.first


{-| Run many small frames to get past `durationMs` so the animation
genuinely settles. A single large `step 1500` does NOT advance the engine
the way you might expect.
-}
runPast : Float -> Sub.AnimState -> Sub.AnimState
runPast durationMs initial =
    List.foldl (\_ acc -> step 50 acc) initial (List.range 1 (ceiling (durationMs / 50)))


currentX : Sub.AnimState -> Float
currentX state =
    Sub.getScaleCurrent groupName state
        |> Maybe.map .x
        |> Maybe.withDefault -1


endX : Sub.AnimState -> Float
endX state =
    Sub.getScaleEnd groupName state
        |> Maybe.map .x
        |> Maybe.withDefault -1


within : Float -> Float -> Float -> Expect.Expectation
within tolerance expected actual =
    if abs (actual - expected) <= tolerance then
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
    describe "Anim.Engine.Sub.onResize - scale"
        [ test "Clamp re-clamps a settled one-shot scale into the new range" <|
            \_ ->
                let
                    state =
                        initialState
                            |> (\s -> Sub.animate s (scaleX 5))
                            |> runPast 1500

                    bounds =
                        { x = Just { min = 1, max = 2 }
                        , y = Nothing
                        , z = Nothing
                        }

                    resized =
                        Sub.onResize state <|
                            Scale.onResize groupName Resize.Clamp bounds
                in
                Expect.all
                    [ \st -> currentX st |> within 0.001 2
                    , \st -> endX st |> within 0.001 2
                    ]
                    resized
        , test "Proportional remaps a settled one-shot scale into the new range" <|
            \_ ->
                let
                    state =
                        initialState
                            |> (\s -> Sub.animate s (scaleX 4))
                            |> step 500

                    -- After 500ms of a 1000ms linear scaleX 1 -> 4: current = 2.5.
                    bounds =
                        { x = Just { min = 0, max = 8 }
                        , y = Nothing
                        , z = Nothing
                        }

                    resized =
                        Sub.onResize state <|
                            Scale.onResize groupName Resize.Proportional bounds
                in
                -- Old leg [1..4], current=2.5, ratio=(2.5-1)/3=0.5; new leg
                -- [0..8] -> 0 + 0.5 * 8 = 4.
                currentX resized |> within 0.001 4
        , test "Empty bounds (all axes Nothing) is a no-op" <|
            \_ ->
                let
                    state =
                        initialState
                            |> (\s -> Sub.animate s (scaleX 3))
                            |> step 500

                    before =
                        currentX state

                    resized =
                        Sub.onResize state <|
                            Scale.onResize groupName
                                Resize.Proportional
                                { x = Nothing, y = Nothing, z = Nothing }
                in
                currentX resized |> within 0.001 before
        , test "group-wide default is used when no per-property entry" <|
            \_ ->
                let
                    state =
                        initialState
                            |> (\s -> Sub.animate s (scaleX 5))
                            |> runPast 1500

                    bounds =
                        { x = Just { min = 1, max = 2 }
                        , y = Nothing
                        , z = Nothing
                        }

                    resized =
                        Sub.onResize state <|
                            Resize.onResize groupName Resize.Clamp bounds
                in
                currentX resized |> within 0.001 2
        , test "per-property Scale.onResize overrides the group-wide default" <|
            \_ ->
                let
                    state =
                        initialState
                            |> (\s -> Sub.animate s (scaleX 5))
                            |> runPast 1500

                    defaultBounds =
                        { x = Just { min = 1, max = 2 }
                        , y = Nothing
                        , z = Nothing
                        }

                    scaleBounds =
                        { x = Just { min = 1, max = 3 }
                        , y = Nothing
                        , z = Nothing
                        }

                    resized =
                        Sub.onResize state <|
                            Resize.onResize groupName Resize.Clamp defaultBounds
                                >> Scale.onResize groupName Resize.Clamp scaleBounds
                in
                currentX resized |> within 0.001 3
        , test "Translate and Scale resize independently in the same call" <|
            \_ ->
                let
                    state =
                        initialState
                            |> (\s ->
                                    Sub.animate s
                                        (Translate.for groupName
                                            >> Translate.toX 100
                                            >> Translate.duration 1000
                                            >> Translate.easing Linear
                                            >> Translate.build
                                            >> Scale.for groupName
                                            >> Scale.toX 4
                                            >> Scale.duration 1000
                                            >> Scale.easing Linear
                                            >> Scale.build
                                        )
                               )
                            |> runPast 1500

                    translateBounds =
                        { x = Just { min = 0, max = 50 }
                        , y = Nothing
                        , z = Nothing
                        }

                    scaleBounds =
                        { x = Just { min = 1, max = 2 }
                        , y = Nothing
                        , z = Nothing
                        }

                    resized =
                        Sub.onResize state <|
                            Translate.onResize groupName Resize.Clamp translateBounds
                                >> Scale.onResize groupName Resize.Clamp scaleBounds

                    translateX =
                        Sub.getTranslateCurrent groupName resized
                            |> Maybe.map .x
                            |> Maybe.withDefault -1
                in
                Expect.all
                    [ \_ -> translateX |> within 0.001 50
                    , \_ -> currentX resized |> within 0.001 2
                    ]
                    ()
        , test "single onResize call updates two anim groups independently" <|
            \_ ->
                let
                    secondGroup =
                        "card"

                    state =
                        Sub.init
                            [ Scale.initX groupName 1
                            , Scale.initX secondGroup 1
                            ]
                            |> (\s ->
                                    Sub.animate s
                                        (Scale.for groupName
                                            >> Scale.toX 5
                                            >> Scale.duration 1000
                                            >> Scale.easing Linear
                                            >> Scale.build
                                            >> Scale.for secondGroup
                                            >> Scale.toX 5
                                            >> Scale.duration 1000
                                            >> Scale.easing Linear
                                            >> Scale.build
                                        )
                               )
                            |> runPast 1500

                    boxBounds =
                        { x = Just { min = 1, max = 2 }
                        , y = Nothing
                        , z = Nothing
                        }

                    cardBounds =
                        { x = Just { min = 1, max = 3 }
                        , y = Nothing
                        , z = Nothing
                        }

                    resized =
                        Sub.onResize state <|
                            Scale.onResize groupName Resize.Clamp boxBounds
                                >> Scale.onResize secondGroup Resize.Clamp cardBounds

                    boxX =
                        Sub.getScaleCurrent groupName resized
                            |> Maybe.map .x
                            |> Maybe.withDefault -1

                    cardX =
                        Sub.getScaleCurrent secondGroup resized
                            |> Maybe.map .x
                            |> Maybe.withDefault -1
                in
                Expect.all
                    [ \_ -> boxX |> within 0.001 2
                    , \_ -> cardX |> within 0.001 3
                    ]
                    ()
        ]
