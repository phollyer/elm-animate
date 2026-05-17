module Anim.Property.PerspectiveOriginResizeSpec exposing (suite)

import Anim.Internal.Builder as Builder
import Anim.Internal.Resize.Builder as ResizeBuilder
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Resize as Resize
import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "PerspectiveOrigin resize"
        [ test "resizePolicy stores per-property policy on the builder" <|
            \_ ->
                Builder.init []
                    |> PerspectiveOrigin.resizePolicy "cube" Resize.retarget
                    |> Builder.getResizePolicy "cube" "perspectiveOrigin"
                    |> Expect.equal
                        { range = ResizeBuilder.Adaptive
                        , current = ResizeBuilder.Fixed
                        , timing = ResizeBuilder.SolveFromCurrent
                        }
        , test "bounds records per-property perspectiveOrigin bounds" <|
            \_ ->
                let
                    newBounds =
                        { x = Just { min = 0, max = 500 }
                        , y = Just { min = 0, max = 300 }
                        , z = Nothing
                        }
                in
                ResizeBuilder.build (PerspectiveOrigin.bounds "cube" newBounds)
                    |> ResizeBuilder.getPerspectiveOrigin "cube"
                    |> Expect.equal (Just { bounds = newBounds })
        , test "bounds falls back to group default when no perspectiveOrigin entry exists" <|
            \_ ->
                let
                    newBounds =
                        { x = Just { min = 10, max = 110 }
                        , y = Just { min = 20, max = 220 }
                        , z = Nothing
                        }
                in
                ResizeBuilder.build (Resize.bounds "cube" newBounds)
                    |> ResizeBuilder.getPerspectiveOrigin "cube"
                    |> Expect.equal (Just { bounds = newBounds })
        ]
