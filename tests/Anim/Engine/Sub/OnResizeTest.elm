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
            , test "completed one-shot tracks the new endpoint across successive resizes (regression)" <|
                -- Reproduces the ControllingAnimations bug: animate to the floor,
                -- finish, resize repeatedly. A completed one-shot is "settled at
                -- the endpoint" - the right semantic is to snap `current` to the
                -- new endpoint and preserve the full leg, not collapse `start`
                -- to `current` (which degenerates the Proportional formula on
                -- the next resize and teleports the box back to `b.min`).
                \_ ->
                    let
                        finished =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                -- Run well past the 1000ms duration to settle at 500.
                                |> (\s -> List.foldl (\_ acc -> step 50 acc) s (List.range 1 60))

                        afterResize1 =
                            Sub.onResize groupName
                                Sub.Proportional
                                { x = Just { min = 0, max = 300 }
                                , y = Nothing
                                }
                                finished

                        afterResize2 =
                            Sub.onResize groupName
                                Sub.Proportional
                                { x = Just { min = 0, max = 350 }
                                , y = Nothing
                                }
                                afterResize1
                    in
                    Expect.all
                        [ \_ -> currentX afterResize1 |> within 0.5 300
                        , \_ -> endX afterResize1 |> within 0.001 300
                        , -- Tracks the new endpoint, doesn't warp to b.min.
                          \_ -> currentX afterResize2 |> within 0.5 350
                        , \_ -> endX afterResize2 |> within 0.001 350
                        ]
                        ()
            ]
        , describe "paused one-shot"
            [ test "preserves the visual position across a resize" <|
                -- Pause mid-flight, resize the bounds (same range), and the
                -- proportional position along the leg must be unchanged.
                \_ ->
                    let
                        paused =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 400
                                |> Sub.pause groupName

                        before =
                            currentX paused

                        resized =
                            Sub.onResize groupName
                                Sub.Proportional
                                { x = Just { min = 0, max = 500 }
                                , y = Nothing
                                }
                                paused
                    in
                    currentX resized
                        |> within 0.001 before
            , test "does not creep across many sub-pixel resizes (regression)" <|
                -- The bug: when paused, repeatedly resizing by sub-pixel
                -- amounts caused `current` to drift toward `end`. Reproduces
                -- the ControllingAnimations 560px-clamp wobble.
                \_ ->
                    let
                        paused =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 400
                                |> Sub.pause groupName

                        before =
                            currentX paused

                        -- Apply 20 identical resizes; current must not drift.
                        resized =
                            List.foldl
                                (\_ s ->
                                    Sub.onResize groupName
                                        Sub.Proportional
                                        { x = Just { min = 0, max = 500 }
                                        , y = Nothing
                                        }
                                        s
                                )
                                paused
                                (List.range 1 20)
                    in
                    currentX resized
                        |> within 0.001 before
            , test "scales current proportionally when the leg grows" <|
                \_ ->
                    let
                        paused =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 400
                                |> Sub.pause groupName

                        beforeRatio =
                            -- progress along old leg (0..500)
                            currentX paused / 500

                        resized =
                            Sub.onResize groupName
                                Sub.Proportional
                                { x = Just { min = 0, max = 1000 }
                                , y = Nothing
                                }
                                paused
                    in
                    -- Same ratio along the new leg (0..1000).
                    currentX resized
                        |> within 0.5 (beforeRatio * 1000)
            , test "resume after resize completes at the new endpoint" <|
                \_ ->
                    let
                        finished =
                            initialState
                                |> (\s -> Sub.animate s (moveX 500))
                                |> step 400
                                |> Sub.pause groupName
                                |> Sub.onResize groupName
                                    Sub.Proportional
                                    { x = Just { min = 0, max = 1000 }
                                    , y = Nothing
                                    }
                                |> Sub.resume groupName
                                |> (\s -> List.foldl (\_ acc -> step 50 acc) s (List.range 1 200))
                    in
                    Expect.all
                        [ \_ -> currentX finished |> within 0.5 1000
                        , \_ -> endX finished |> within 0.001 1000
                        ]
                        ()
            , test "preserves eased visual position with non-linear easing (regression)" <|
                -- The previous implementation derived elapsedMs by *linearly*
                -- inverting the leg progress, then the engine re-applied the
                -- easing curve - producing a mismatched current that drifted
                -- across resizes for any non-linear easing.
                \_ ->
                    let
                        easedMove : Sub.AnimBuilder mode -> Sub.AnimBuilder mode
                        easedMove =
                            Translate.for groupName
                                >> Translate.toX 500
                                >> Translate.duration 1000
                                >> Translate.easing CubicOut
                                >> Translate.build

                        paused =
                            initialState
                                |> (\s -> Sub.animate s easedMove)
                                |> step 300
                                |> Sub.pause groupName

                        before =
                            currentX paused

                        -- 10 identical resizes; eased current must not drift.
                        resized =
                            List.foldl
                                (\_ s ->
                                    Sub.onResize groupName
                                        Sub.Proportional
                                        { x = Just { min = 0, max = 500 }
                                        , y = Nothing
                                        }
                                        s
                                )
                                paused
                                (List.range 1 10)
                    in
                    currentX resized
                        |> within 0.001 before
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
                , test "Proportional preserves eased visual position with non-linear easing (regression)" <|
                    -- The previous implementation derived elapsedMs by
                    -- *linearly* inverting the leg progress; the engine then
                    -- re-applied the easing curve, producing a mismatched
                    -- current that drifted across resizes for any non-linear
                    -- easing. Temporal-ratio preservation fixes this for
                    -- the Proportional strategy.
                    \_ ->
                        let
                            easedPingPong : Sub.AnimBuilder mode -> Sub.AnimBuilder mode
                            easedPingPong =
                                Sub.loopForever
                                    >> Sub.alternate
                                    >> Translate.for groupName
                                    >> Translate.toX 500
                                    >> Translate.duration 1000
                                    >> Translate.easing CubicOut
                                    >> Translate.build

                            running =
                                initialState
                                    |> (\s -> Sub.animate s easedPingPong)
                                    |> step 300

                            before =
                                currentX running

                            -- 10 identical Proportional resizes; the eased
                            -- current must not drift between them (no
                            -- step 0 between resizes -> no time passes).
                            resized =
                                List.foldl
                                    (\_ s ->
                                        Sub.onResize groupName
                                            Sub.Proportional
                                            { x = Just { min = 0, max = 500 }
                                            , y = Nothing
                                            }
                                            s
                                    )
                                    running
                                    (List.range 1 10)
                        in
                        currentX resized
                            |> within 0.001 before
                ]
            ]
        ]
