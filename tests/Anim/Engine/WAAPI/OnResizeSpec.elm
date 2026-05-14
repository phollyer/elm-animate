module Anim.Engine.WAAPI.OnResizeSpec exposing (suite)

{-| Tests for the WAAPI engine `onResize` plumbing.

Two layers are exercised here:

1.  `Anim.Internal.Engine.Shared.Resize.applyAxis` — the per-axis math
    that drives both the Sub and WAAPI engines.
2.  `Anim.Internal.Engine.WAAPI.Encoder.encodeResize` — the JSON shape
    sent over the `motionCmd` port to the JS handler.

The full pipeline (state → `WAAPI.onResize` → `Cmd msg`) cannot be
inspected directly because Elm `Cmd`s are opaque; instead the JS handler
exercises the consumer side via the Vitest suite.

-}

import Anim.Internal.Engine.WAAPI.Encoder as Encoder
import Anim.Internal.Resize.Builder as ResizeBuilder
import Anim.Resize exposing (Strategy(..))
import Expect
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "WAAPI onResize"
        [ resizeMathTests
        , encoderTests
        ]



-- ============================================================
-- SHARED RESIZE MATH
-- ============================================================


resizeMathTests : Test
resizeMathTests =
    describe "Resize.applyAxis"
        [ test "Nothing bounds leaves axis untouched" <|
            \_ ->
                ResizeBuilder.applyAxis ResizeBuilder.Proportional True Nothing 0 200 100
                    |> Expect.equal { start = 0, end = 200, current = 100 }
        , test "Proportional looping preserves normalized progress" <|
            \_ ->
                -- old leg [0, 200], current 100 → halfway
                -- new leg [0, 400], halfway → 200
                ResizeBuilder.applyAxis
                    ResizeBuilder.Proportional
                    True
                    (Just { min = 0, max = 400 })
                    0
                    200
                    100
                    |> Expect.equal { start = 0, end = 400, current = 200 }
        , test "Proportional reverse leg keeps direction" <|
            \_ ->
                -- old leg [200, 0] (reverse), current 50 → 75% to end
                -- new leg [400, 0] reverse → 75% → 100
                ResizeBuilder.applyAxis
                    ResizeBuilder.Proportional
                    True
                    (Just { min = 0, max = 400 })
                    200
                    0
                    50
                    |> Expect.equal { start = 400, end = 0, current = 100 }
        , test "Clamp looping keeps current and re-spans new bounds" <|
            \_ ->
                ResizeBuilder.applyAxis
                    ResizeBuilder.Clamp
                    True
                    (Just { min = 0, max = 400 })
                    0
                    200
                    150
                    |> Expect.equal { start = 0, end = 400, current = 150 }
        , test "Clamp clamps current outside new bounds" <|
            \_ ->
                ResizeBuilder.applyAxis
                    ResizeBuilder.Clamp
                    True
                    (Just { min = 0, max = 100 })
                    0
                    200
                    150
                    |> Expect.equal { start = 0, end = 100, current = 100 }
        , test "Proportional one-shot collapses to remaining leg" <|
            \_ ->
                -- not looping → start becomes current; end becomes new max
                ResizeBuilder.applyAxis
                    ResizeBuilder.Proportional
                    False
                    (Just { min = 0, max = 400 })
                    0
                    200
                    100
                    |> Expect.equal { start = 200, end = 400, current = 200 }
        , test "Proportional with zero old range preserves current (clamped into new bounds)" <|
            -- When start == end the leg has collapsed (e.g. a previous resize
            -- on a finished one-shot animation), so there is no proportional
            -- position to preserve. We must keep `current` in place rather
            -- than snap it to `b.min`, otherwise a settled box warps back to
            -- the start of the track on every subsequent resize. See the
            -- ControllingAnimations example regression.
            \_ ->
                ResizeBuilder.applyAxis
                    ResizeBuilder.Proportional
                    True
                    (Just { min = 50, max = 250 })
                    100
                    100
                    100
                    |> Expect.equal { start = 50, end = 250, current = 100 }
        , test "Proportional with zero old range clamps an out-of-range current into new bounds" <|
            \_ ->
                ResizeBuilder.applyAxis
                    ResizeBuilder.Proportional
                    False
                    (Just { min = 0, max = 100 })
                    300
                    300
                    300
                    |> Expect.equal { start = 100, end = 100, current = 100 }
        ]



-- ============================================================
-- ENCODER
-- ============================================================


encoderTests : Test
encoderTests =
    describe "Encoder.encodeResize"
        [ test "emits the expected JSON shape with explicit currentTimeMs" <|
            \_ ->
                Encoder.encodeResize
                    { animGroupName = "box"
                    , property = "translate"
                    , start = { x = 0, y = 0, z = 0 }
                    , end = { x = 400, y = 0, z = 0 }
                    , current = { x = 100, y = 0, z = 0 }
                    , durationMs = 1000
                    , currentTimeMs = Just 250
                    , hasAnimationBaseline = True
                    }
                    |> Encode.encode 0
                    |> Expect.equal
                        ("{\"type\":\"resize\""
                            ++ ",\"elementId\":\"box\""
                            ++ ",\"animGroup\":\"box\""
                            ++ ",\"property\":\"translate\""
                            ++ ",\"startX\":0,\"startY\":0,\"startZ\":0"
                            ++ ",\"endX\":400,\"endY\":0,\"endZ\":0"
                            ++ ",\"currentX\":100,\"currentY\":0,\"currentZ\":0"
                            ++ ",\"duration\":1000"
                            ++ ",\"hasAnimationBaseline\":true"
                            ++ ",\"currentTimeMs\":250}"
                        )
        , test "encodes non-zero start/end on all three axes and null currentTimeMs" <|
            \_ ->
                Encoder.encodeResize
                    { animGroupName = "el"
                    , property = "translate"
                    , start = { x = 1, y = 2, z = 3 }
                    , end = { x = 4, y = 5, z = 6 }
                    , current = { x = 7, y = 8, z = 9 }
                    , durationMs = 250
                    , currentTimeMs = Nothing
                    , hasAnimationBaseline = True
                    }
                    |> Encode.encode 0
                    |> Expect.equal
                        ("{\"type\":\"resize\""
                            ++ ",\"elementId\":\"el\""
                            ++ ",\"animGroup\":\"el\""
                            ++ ",\"property\":\"translate\""
                            ++ ",\"startX\":1,\"startY\":2,\"startZ\":3"
                            ++ ",\"endX\":4,\"endY\":5,\"endZ\":6"
                            ++ ",\"currentX\":7,\"currentY\":8,\"currentZ\":9"
                            ++ ",\"duration\":250"
                            ++ ",\"hasAnimationBaseline\":true"
                            ++ ",\"currentTimeMs\":null}"
                        )
        , test "emits property=scale when targeting the scale slot" <|
            \_ ->
                Encoder.encodeResize
                    { animGroupName = "cube"
                    , property = "scale"
                    , start = { x = 1, y = 1, z = 1 }
                    , end = { x = 2, y = 1, z = 1 }
                    , current = { x = 1.25, y = 1, z = 1 }
                    , durationMs = 1000
                    , currentTimeMs = Just 250
                    , hasAnimationBaseline = False
                    }
                    |> Encode.encode 0
                    |> Expect.equal
                        ("{\"type\":\"resize\""
                            ++ ",\"elementId\":\"cube\""
                            ++ ",\"animGroup\":\"cube\""
                            ++ ",\"property\":\"scale\""
                            ++ ",\"startX\":1,\"startY\":1,\"startZ\":1"
                            ++ ",\"endX\":2,\"endY\":1,\"endZ\":1"
                            ++ ",\"currentX\":1.25,\"currentY\":1,\"currentZ\":1"
                            ++ ",\"duration\":1000"
                            ++ ",\"hasAnimationBaseline\":false"
                            ++ ",\"currentTimeMs\":250}"
                        )
        ]
