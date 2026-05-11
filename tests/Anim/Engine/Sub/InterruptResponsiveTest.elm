module Anim.Engine.Sub.InterruptResponsiveTest exposing (suite)

{-| Behavioural contract test for the snapshot-and-continue responsive
pattern used by the resize-aware translate examples.

The pattern relies on one guarantee from the public `Anim.Engine.Sub`
API:

  - Calling `Sub.animate` with an explicit `Translate.fromX` /
    `Translate.fromY` sets the next animation's start to that supplied
    value, regardless of any prior animation state for the same group.

The example uses this guarantee on resize: it reads the current
rendered translate via `Sub.getTranslateCurrent`, feeds it back as
`Translate.fromX`, and supplies the new logical target as
`Translate.toX`. The result is a fresh animation that continues from
exactly where the box visually is.

-}

import Anim.Engine.Sub as Sub
import Anim.Property.Translate as Translate
import Expect
import Motion.Easing exposing (Easing(..))
import Test exposing (Test, describe, test)


groupName : String
groupName =
    "movingBox"


initialState : Sub.AnimState
initialState =
    Sub.init [ Translate.initXY groupName 0 0 ]



-- ANIMATIONS


moveX : Float -> Float -> Sub.AnimBuilder mode -> Sub.AnimBuilder mode
moveX from to_ =
    Translate.for groupName
        >> Translate.fromX from
        >> Translate.toX to_
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.build



-- SUITE


suite : Test
suite =
    describe "Anim.Engine.Sub responsive interrupt contract"
        [ describe "explicit `from` re-anchors the next animation"
            [ test "first call sets start = from and end = to" <|
                \_ ->
                    let
                        state =
                            Sub.animate initialState (moveX 0 500)
                    in
                    ( Sub.getTranslateStart groupName state |> Maybe.map .x
                    , Sub.getTranslateEnd groupName state |> Maybe.map .x
                    )
                        |> Expect.equal ( Just 0, Just 500 )
            , test "second call with explicit from overrides any prior state" <|
                \_ ->
                    let
                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 0 500))
                                |> (\s -> Sub.animate s (moveX 100 1000))
                    in
                    ( Sub.getTranslateStart groupName state |> Maybe.map .x
                    , Sub.getTranslateEnd groupName state |> Maybe.map .x
                    )
                        |> Expect.equal ( Just 100, Just 1000 )
            , test "explicit from at the snapshot value pins start exactly there" <|
                \_ ->
                    -- This is the pattern the example uses on resize:
                    -- read the current rendered X via `getTranslateCurrent`
                    -- and feed it back as `fromX` so the new run continues
                    -- from where the box visually is.
                    let
                        snapshotX =
                            137.5

                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 0 500))
                                |> (\s -> Sub.animate s (moveX snapshotX 1000))
                    in
                    Sub.getTranslateStart groupName state
                        |> Maybe.map .x
                        |> Expect.equal (Just snapshotX)
            , test "clamped snapshot survives Sub.animate (resize out-of-bounds pattern)" <|
                \_ ->
                    -- Resize-clamp pattern: when the canvas shrinks beneath
                    -- the box's current X, the example clamps the snapshot
                    -- to the new bounds before passing it as `fromX`. The
                    -- new run must start at the clamp boundary, not the
                    -- pre-clamp overshoot.
                    let
                        snapshotX =
                            350

                        newCanvasW =
                            300

                        boxW =
                            100

                        clampedX =
                            clamp 0 (max 0 (newCanvasW - boxW)) snapshotX

                        state =
                            initialState
                                |> (\s -> Sub.animate s (moveX 0 500))
                                |> (\s -> Sub.animate s (moveX clampedX 0))
                    in
                    ( clampedX
                    , Sub.getTranslateStart groupName state |> Maybe.map .x
                    )
                        |> Expect.equal ( 200, Just 200 )
            ]
        ]
