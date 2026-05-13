module Anim.Engine.Sub.OnResizeTest exposing (suite)

{-| Tests for `Sub.onResize`, which mutates an in-flight translate
animation to match a new bounding range. Two strategies:

  - `Proportional` preserves normalized progress within the old/new range.
  - `Clamp` keeps the current value but re-clamps it (and the target) into
    the new range.

Animations are stepped via `Sub.update` with `Internal.AnimationFrame` and
queried via `Sub.getTranslateCurrent` / `getTranslateEnd`.

-}

import Anim.Engine.Sub as Sub
import Anim.Internal.Engine.Sub as Internal
import Anim.Property.Opacity as Opacity
import Anim.Property.Translate as Translate
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "box"


initialState : Sub.AnimState
initialState =
    Sub.init [ Translate.initXY groupName 0 0 ]


moveX : Float -> Sub.AnimBuilder mode -> Sub.AnimBuilder mode
moveX target =
    Translate.for groupName
        >> Translate.toX target
        >> Translate.duration 1000
        >> Translate.easing Linear
        >> Translate.build


step : Float -> Sub.AnimState -> Sub.AnimState
step deltaMs state =
    Sub.update (Internal.AnimationFrame deltaMs) state
        |> Tuple.first


currentX : Sub.AnimState -> Float
currentX state =
    Sub.getTranslateCurrent groupName state
        |> Maybe.map .x
        |> Maybe.withDefault -1


endX : Sub.AnimState -> Float
endX state =
    Sub.getTranslateEnd groupName state
        |> Maybe.map .x
        |> Maybe.withDefault -1


{-| Step the animation `n` times by `deltaMs` and return the (min, max)
range of `currentX` values seen across all steps (inclusive of the start).
-}
trackExtrema : Int -> Float -> Sub.AnimState -> ( Float, Float )
trackExtrema n deltaMs initial =
    let
        x0 =
            currentX initial

        go i state acc =
            if i <= 0 then
                acc

            else
                let
                    next =
                        step deltaMs state

                    x =
                        currentX next

                    ( lo, hi ) =
                        acc
                in
                go (i - 1) next ( Basics.min lo x, Basics.max hi x )
    in
    go n initial ( x0, x0 )


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
    describe "Anim.Engine.Sub.onResize"
        [ describe "no-op cases"
            [ test "no axes specified leaves state untouched" <|
                \_ ->
                    let
                        before =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250

                        after =
                            Sub.onResize groupName
                                Sub.Proportional
                                { x = Nothing, y = Nothing }
                                before
                    in
                    currentX after
                        |> within 0.001 (currentX before)
            , test "unknown group is a no-op" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250

                        after =
                            Sub.onResize "doesNotExist"
                                Sub.Clamp
                                { x = Just { min = 0, max = 100 }
                                , y = Nothing
                                }
                                state
                    in
                    currentX after
                        |> within 0.001 (currentX state)
            ]
        , describe "Clamp strategy"
            [ test "current value is clamped into new bounds when out of range" <|
                \_ ->
                    let
                        -- Move 0 -> 500, step halfway -> current ~250
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 500

                        resized =
                            Sub.onResize groupName
                                Sub.Clamp
                                { x = Just { min = 0, max = 100 }
                                , y = Nothing
                                }
                                state
                    in
                    currentX resized
                        |> within 0.001 100
            , test "current value left alone when already inside new bounds" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 200

                        before =
                            currentX state

                        resized =
                            Sub.onResize groupName
                                Sub.Clamp
                                { x = Just { min = 0, max = 400 }
                                , y = Nothing
                                }
                                state
                    in
                    currentX resized
                        |> within 0.001 before
            , test "runtime target lands at the clamped boundary after time elapses" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 100
                                |> Sub.onResize groupName
                                    Sub.Clamp
                                    { x = Just { min = 0, max = 300 }
                                    , y = Nothing
                                    }

                        finished =
                            List.foldl (\_ s -> step 50 s) state (List.range 1 200)
                    in
                    currentX finished
                        |> within 0.5 300
            , test "getTranslateEnd reflects the clamped target immediately" <|
                \_ ->
                    let
                        resized =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 100
                                |> Sub.onResize groupName
                                    Sub.Clamp
                                    { x = Just { min = 0, max = 300 }
                                    , y = Nothing
                                    }
                    in
                    endX resized
                        |> within 0.001 300
            ]
        , describe "Proportional strategy"
            [ test "halfway through 0->500 becomes halfway through 0->300" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 500

                        -- current is ~250 (halfway)
                        resized =
                            Sub.onResize groupName
                                Sub.Proportional
                                { x = Just { min = 0, max = 300 }
                                , y = Nothing
                                }
                                state
                    in
                    currentX resized
                        |> within 0.5 150
            , test "runtime target maps to new max when traveling forward" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250
                                |> Sub.onResize groupName
                                    Sub.Proportional
                                    { x = Just { min = 0, max = 300 }
                                    , y = Nothing
                                    }

                        finished =
                            List.foldl (\_ s -> step 50 s) state (List.range 1 200)
                    in
                    currentX finished
                        |> within 0.5 300
            , test "getTranslateEnd reflects the new max immediately" <|
                \_ ->
                    let
                        resized =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250
                                |> Sub.onResize groupName
                                    Sub.Proportional
                                    { x = Just { min = 0, max = 300 }
                                    , y = Nothing
                                    }
                    in
                    endX resized
                        |> within 0.001 300
            , test "rescaled animation continues to new target over time" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 500
                                |> Sub.onResize groupName
                                    Sub.Proportional
                                    { x = Just { min = 0, max = 300 }
                                    , y = Nothing
                                    }

                        finished =
                            -- Step generously past any reasonable remaining duration.
                            List.foldl (\_ s -> step 50 s) state (List.range 1 200)
                    in
                    currentX finished
                        |> within 0.5 300
            ]
        , describe "axis selectivity"
            [ test "Y bounds do not affect X" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 250

                        before =
                            currentX state

                        resized =
                            Sub.onResize groupName
                                Sub.Clamp
                                { x = Nothing
                                , y = Just { min = 0, max = 50 }
                                }
                                state
                    in
                    currentX resized
                        |> within 0.001 before
            ]
        , describe "non-translate properties are untouched"
            [ test "opacity in the same group is left alone" <|
                \_ ->
                    let
                        state =
                            Sub.init [ Translate.initXY groupName 0 0 ]
                                |> (\s ->
                                        Sub.animate s
                                            (Translate.for groupName
                                                >> Translate.toX 500
                                                >> Translate.duration 1000
                                                >> Translate.build
                                                >> Opacity.for groupName
                                                >> Opacity.to 0.5
                                                >> Opacity.duration 1000
                                                >> Opacity.build
                                            )
                                   )
                                |> step 500

                        opacityBefore =
                            Sub.getOpacityCurrent groupName state

                        resized =
                            Sub.onResize groupName
                                Sub.Clamp
                                { x = Just { min = 0, max = 100 }
                                , y = Nothing
                                }
                                state

                        opacityAfter =
                            Sub.getOpacityCurrent groupName resized
                    in
                    opacityAfter
                        |> Expect.equal opacityBefore
            ]
        , describe "ping-pong (loopForever + alternate)"
            [ let
                pingPong : Float -> Sub.AnimBuilder mode -> Sub.AnimBuilder mode
                pingPong target =
                    Sub.loopForever
                        >> Sub.alternate
                        >> Translate.for groupName
                        >> Translate.toX target
                        >> Translate.duration 1000
                        >> Translate.easing Linear
                        >> Translate.build
              in
              describe "Proportional preserves the full new range across leg boundaries"
                [ test "after resize, the box reaches both new extremes" <|
                    \_ ->
                        let
                            -- Mid-forward leg, ~halfway through 0->500.
                            state =
                                initialState
                                    |> (\s -> Sub.animate s (pingPong 500))
                                    |> step 500

                            resized =
                                Sub.onResize groupName
                                    Sub.Proportional
                                    { x = Just { min = 0, max = 1000 }
                                    , y = Nothing
                                    }
                                    state

                            ( minSeen, maxSeen ) =
                                trackExtrema 200 20 resized
                        in
                        Expect.all
                            [ \_ -> maxSeen |> within 5 1000
                            , \_ -> minSeen |> within 5 0
                            ]
                            ()
                , test "after resize, leg duration scales with the new range" <|
                    \_ ->
                        let
                            state =
                                initialState
                                    |> (\s -> Sub.animate s (pingPong 500))
                                    |> step 500
                                    |> Sub.onResize groupName
                                        Sub.Proportional
                                        { x = Just { min = 0, max = 1000 }
                                        , y = Nothing
                                        }
                        in
                        -- Old leg = 1000ms over 500px = 500px/sec. New leg should
                        -- preserve speed: 1000px / 500px/sec = 2000ms total.
                        Sub.getTranslateRange groupName state
                            |> Maybe.map .end
                            |> Maybe.map .x
                            |> Maybe.withDefault -1
                            |> within 0.001 1000
                , test "Clamp keeps current value and preserves full range on next leg" <|
                    \_ ->
                        let
                            state =
                                initialState
                                    |> (\s -> Sub.animate s (pingPong 500))
                                    |> step 500

                            beforeCurrent =
                                currentX state

                            resized =
                                Sub.onResize groupName
                                    Sub.Clamp
                                    { x = Just { min = 0, max = 1000 }
                                    , y = Nothing
                                    }
                                    state

                            currentPreserved =
                                currentX resized

                            ( minSeen, maxSeen ) =
                                trackExtrema 400 20 resized
                        in
                        Expect.all
                            [ \_ -> currentPreserved |> within 0.5 beforeCurrent
                            , \_ -> maxSeen |> within 5 1000
                            , \_ -> minSeen |> within 5 0
                            ]
                            ()
                ]
            ]
        ]
