module TestTransformOrder exposing (suite)

import Anim.Engine.CSS as CSS
import Anim.Properties.Position as Position
import Anim.Properties.Rotate as Rotate
import Anim.Properties.Scale as Scale
import Anim.Timing.Easing as Easing
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Transform Order in Keyframes"
        [ test "should respect canonical CSS order: Position -> Rotate -> Scale" <|
            \_ ->
                let
                    animations =
                        CSS.init
                            |> CSS.builder
                            |> CSS.duration 1000
                            |> CSS.easing Easing.Linear
                            -- First: Position
                            |> Position.for "test-element"
                            |> Position.toXY 100 50
                            |> Position.build
                            -- Second: Rotate
                            |> Rotate.for "test-element"
                            |> Rotate.to 45
                            |> Rotate.build
                            -- Third: Scale
                            |> Scale.for "test-element"
                            |> Scale.fromXY 1.0 1.0
                            |> Scale.toXY 1.5 1.2
                            |> Scale.build
                            |> CSS.animate

                    keyframes =
                        CSS.getElementKeyframes "test-element" animations
                            |> Maybe.withDefault ""
                in
                Expect.all
                    [ \_ -> keyframes |> String.contains "translate3d(" |> Expect.equal True
                    , \_ -> keyframes |> String.contains "scale(" |> Expect.equal True
                    , \_ -> keyframes |> String.contains "rotateZ(" |> Expect.equal True
                    , \_ ->
                        let
                            translateIndex =
                                String.indexes "translate3d(" keyframes |> List.head |> Maybe.withDefault -1

                            scaleIndex =
                                String.indexes "scale(" keyframes |> List.head |> Maybe.withDefault -1

                            rotateIndex =
                                String.indexes "rotateZ(" keyframes |> List.head |> Maybe.withDefault -1
                        in
                        Expect.all
                            [ \_ ->
                                if translateIndex >= 0 && rotateIndex >= 0 then
                                    Expect.equal True (translateIndex < rotateIndex)

                                else
                                    Expect.fail "Could not find both translate3d and rotateZ functions"
                            , \_ ->
                                if rotateIndex >= 0 && scaleIndex >= 0 then
                                    Expect.equal True (rotateIndex < scaleIndex)

                                else
                                    Expect.fail "Could not find both rotateZ and scale functions"
                            ]
                            keyframes

                    -- Verify that translate3d comes before rotateZ in the string
                    , \_ ->
                        let
                            translateIndex =
                                String.indexes "translate3d(" keyframes |> List.head |> Maybe.withDefault -1

                            rotateIndex =
                                String.indexes "rotateZ(" keyframes |> List.head |> Maybe.withDefault -1
                        in
                        if translateIndex >= 0 && rotateIndex >= 0 then
                            Expect.equal True (translateIndex < rotateIndex)

                        else
                            Expect.fail "Could not find both translate3d and rotateZ functions"

                    -- Verify that rotateZ comes before scale in the string
                    , \_ ->
                        let
                            rotateIndex =
                                String.indexes "rotateZ(" keyframes |> List.head |> Maybe.withDefault -1

                            scaleIndex =
                                String.indexes "scale(" keyframes |> List.head |> Maybe.withDefault -1
                        in
                        if rotateIndex >= 0 && scaleIndex >= 0 then
                            Expect.equal True (rotateIndex < scaleIndex)

                        else
                            Expect.fail "Could not find both rotateZ and scale functions"
                    ]
                    keyframes
        ]
