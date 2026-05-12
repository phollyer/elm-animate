module Anim.Engine.Sub.AlternateLoopTest exposing (suite)

{-| Regression tests for `Sub.alternate` combined with `Sub.loopForever`.

The engine implements `alternate` by physically swapping each
property's `start`/`end` at every iteration boundary. A previous
implementation only swapped on every other iteration boundary, which
caused the visible "double-leg + jump" ping-pong bug:

  - iteration 1 plays start -> end (left -> right)
  - iteration 2 plays end -> start (right -> left, smooth continuation)
  - iteration 3 was still in the swapped state but did NOT swap again,
    so it played end -> start a second time, producing a hard jump
    back to `end` (right) before re-running the leg

A correct ping-pong must swap on every iteration boundary so each leg
continues smoothly from the previous one and the box returns to its
original starting position after every two iterations.

The tests drive the engine by feeding `AnimationFrame` deltas through
`Sub.update` and reading the live interpolated value via
`Sub.getTranslateCurrent`, which reflects the actual rendered position
each frame.

-}

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Translate as Translate
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "pingPong"


initialState : Sub.AnimState
initialState =
    Sub.init [ Translate.initXY groupName 0 0 ]


pingPong : Sub.AnimBuilder mode -> Sub.AnimBuilder mode
pingPong =
    Sub.loopForever
        >> Sub.alternate
        >> Translate.for groupName
        >> Translate.toX 100
        >> Translate.duration 1000
        >> Translate.easing Linear
        >> Translate.build


step : Float -> Sub.AnimState -> Sub.AnimState
step deltaMs state =
    Sub.update (Internal.AnimationFrame deltaMs) state
        |> Tuple.first


stepN : Int -> Float -> Sub.AnimState -> Sub.AnimState
stepN n deltaMs state =
    if n <= 0 then
        state

    else
        stepN (n - 1) deltaMs (step deltaMs state)


currentX : Sub.AnimState -> Float
currentX state =
    Sub.getTranslateCurrent groupName state
        |> Maybe.map .x
        |> Maybe.withDefault -1


sample : Float -> Float -> Sub.AnimState -> List Float
sample deltaMs totalMs initial =
    let
        steps =
            ceiling (totalMs / deltaMs)

        go n state acc =
            if n <= 0 then
                List.reverse acc

            else
                let
                    next =
                        step deltaMs state
                in
                go (n - 1) next (currentX next :: acc)
    in
    go steps initial [ currentX initial ]


maxFrameDelta : List Float -> Float
maxFrameDelta xs =
    case xs of
        first :: rest ->
            List.foldl
                (\x ( prev, biggest ) ->
                    ( x, max biggest (abs (x - prev)) )
                )
                ( first, 0 )
                rest
                |> Tuple.second

        [] ->
            0


isWithin : Float -> Float -> Float -> Expect.Expectation
isWithin tolerance expected actual =
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
    describe "Sub.alternate + Sub.loopForever (ping-pong)"
        [ test "leg 1 progresses from 0 toward 100" <|
            \_ ->
                initialState
                    |> (\s -> Sub.animate s pingPong)
                    |> stepN 5 100
                    |> currentX
                    |> isWithin 5 50
        , test "after one full leg the box reaches the far end (~100)" <|
            \_ ->
                initialState
                    |> (\s -> Sub.animate s pingPong)
                    |> stepN 10 100
                    |> currentX
                    |> isWithin 5 100
        , test "after two legs the box returns to the start (~0)" <|
            \_ ->
                initialState
                    |> (\s -> Sub.animate s pingPong)
                    |> stepN 20 100
                    |> currentX
                    |> isWithin 5 0
        , test "after three legs the box is back at the far end (~100)" <|
            \_ ->
                initialState
                    |> (\s -> Sub.animate s pingPong)
                    |> stepN 30 100
                    |> currentX
                    |> isWithin 5 100
        , test "after four legs the box is back at the start (~0)" <|
            \_ ->
                initialState
                    |> (\s -> Sub.animate s pingPong)
                    |> stepN 40 100
                    |> currentX
                    |> isWithin 5 0
        , test "no hard snap occurs across any iteration boundary" <|
            \_ ->
                let
                    samples =
                        sample 50 4000 (Sub.animate initialState pingPong)
                in
                maxFrameDelta samples
                    |> Expect.lessThan 20
        ]
