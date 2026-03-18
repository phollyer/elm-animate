module TestColorScale exposing (suite)

import Anim.Engine.CSS.Keyframes as CSS
import Anim.Extra.Color as Color
import Anim.Extra.Easing as Easing
import Anim.Property.BackgroundColor as BackgroundColor
import Anim.Property.Scale as Scale
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Color and Scale Keyframes"
        [ test "should not generate NaN values for color morph" <|
            \_ ->
                let
                    animations =
                        CSS.animate (CSS.init []) <|
                            (CSS.duration 900
                                >> CSS.easing Easing.QuartInOut
                                >> BackgroundColor.for "box"
                                >> BackgroundColor.from (Color.fromRgb { r = 59, g = 130, b = 246 })
                                >> BackgroundColor.to (Color.fromRgb { r = 255, g = 100, b = 150 })
                                >> BackgroundColor.duration 900
                                >> BackgroundColor.build
                                >> Scale.for "box"
                                >> Scale.fromXY 1.0 1.0
                                >> Scale.toXY 1.3 1.3
                                >> Scale.duration 900
                                >> Scale.build
                            )

                    keyframes =
                        CSS.getElementKeyframes "box" animations
                            |> Maybe.withDefault ""
                in
                Expect.all
                    [ \_ -> keyframes |> String.contains "NaN" |> Expect.equal False
                    , \_ -> keyframes |> String.contains "scale3d(1,1,1)" |> Expect.equal True
                    , \_ -> keyframes |> String.contains "scaleX(1.3) scaleY(1.3)" |> Expect.equal True
                    , \_ -> keyframes |> String.contains "rgb(59, 130, 246)" |> Expect.equal True
                    , \_ -> keyframes |> String.contains "rgb(255, 100, 150)" |> Expect.equal True
                    , \_ -> keyframes |> String.contains "box-anim-" |> Expect.equal True
                    ]
                    keyframes
        ]
