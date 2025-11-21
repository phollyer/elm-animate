module TestColorScale exposing (suite)

import Anim
import Anim.CSS as CSS
import Anim.Properties.Color as Color
import Anim.Properties.Scale as Scale
import Anim.Timing.Easing as Easing
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Color and Scale Keyframes"
        [ test "should not generate NaN values for color morph" <|
            \_ ->
                let
                    animations =
                        CSS.init
                            |> CSS.builder
                            |> Anim.duration 900
                            |> Anim.easing Easing.QuartInOut
                            |> Color.for "box"
                            |> Color.to (Color.Rgb { r = 255, g = 100, b = 150 })
                            |> Color.duration 900
                            |> Color.build
                            |> Scale.for "box"
                            |> Scale.toXY 1.3 1.3
                            |> Scale.duration 900
                            |> Scale.build
                            |> CSS.animate

                    keyframes =
                        CSS.getElementKeyframes "box" animations
                            |> Maybe.withDefault ""
                in
                Expect.all
                    [ \_ -> keyframes |> String.contains "NaN" |> Expect.equal False
                    , \_ -> keyframes |> String.contains "scale(1,1)" |> Expect.equal True -- Should start with scale(1,1)
                    , \_ -> keyframes |> String.contains "scale(1.3,1.3)" |> Expect.equal True -- Should end with scale(1.3,1.3)
                    , \_ -> keyframes |> String.contains "rgb(59, 130, 246)" |> Expect.equal True -- Should start with blue color
                    , \_ -> keyframes |> String.contains "rgb(255, 100, 150)" |> Expect.equal True -- Should end with target color
                    ]
                    ()
        ]
