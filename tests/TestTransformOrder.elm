module TestTransformOrder exposing (suite)

import Anim
import Anim.CSS as CSS
import Anim.Properties.Position as Position
import Anim.Properties.Rotate as Rotate
import Anim.Properties.Scale as Scale
import Anim.Timing.Easing as Easing
import Expect
import Test exposing (..)


suite : Test
suite =
    describe "Transform Order in Keyframes"
        [ test "should respect pipeline order: Position -> Scale -> Rotate" <|
            \_ ->
                let
                    animations =
                        CSS.init
                            |> CSS.builder
                            |> Anim.duration 1000
                            |> Anim.easing Easing.Linear
                            -- First: Position
                            |> Position.for "test-element"
                            |> Position.toXY 100 50
                            |> Position.build
                            -- Second: Scale
                            |> Scale.for "test-element"
                            |> Scale.fromXY 1.0 1.0
                            |> Scale.toXY 1.5 1.2
                            |> Scale.build
                            -- Third: Rotate
                            |> Rotate.for "test-element"
                            |> Rotate.to 45
                            |> Rotate.build
                            |> CSS.animate

                    keyframes =
                        CSS.getElementKeyframes "test-element" animations
                            |> Maybe.withDefault ""
                            |> Debug.log "Generated keyframes for test-element"
                in
                Expect.all
                    [ \_ -> keyframes |> String.contains "translate(" |> Expect.equal True
                    , \_ -> keyframes |> String.contains "scale(" |> Expect.equal True
                    , \_ -> keyframes |> String.contains "rotate(" |> Expect.equal True
                    , \_ ->
                        let
                            translateIndex =
                                String.indexes "translate(" keyframes |> List.head |> Maybe.withDefault -1

                            scaleIndex =
                                String.indexes "scale(" keyframes |> List.head |> Maybe.withDefault -1

                            rotateIndex =
                                String.indexes "rotate(" keyframes |> List.head |> Maybe.withDefault -1
                        in
                        Expect.all
                            [ \_ ->
                                if translateIndex >= 0 && scaleIndex >= 0 then
                                    Expect.equal True (translateIndex < scaleIndex)

                                else
                                    Expect.fail "Could not find both translate and scale functions"
                            , \_ ->
                                if scaleIndex >= 0 && rotateIndex >= 0 then
                                    Expect.equal True (scaleIndex < rotateIndex)

                                else
                                    Expect.fail "Could not find both scale and rotate functions"
                            ]
                            keyframes

                    -- Verify that translate comes before scale in the string
                    , \_ ->
                        let
                            translateIndex =
                                String.indexes "translate(" keyframes |> List.head |> Maybe.withDefault -1

                            scaleIndex =
                                String.indexes "scale(" keyframes |> List.head |> Maybe.withDefault -1
                        in
                        if translateIndex >= 0 && scaleIndex >= 0 then
                            Expect.equal True (translateIndex < scaleIndex)

                        else
                            Expect.fail "Could not find both translate and scale functions"

                    -- Verify that scale comes before rotate in the string
                    , \_ ->
                        let
                            scaleIndex =
                                String.indexes "scale(" keyframes |> List.head |> Maybe.withDefault -1

                            rotateIndex =
                                String.indexes "rotate(" keyframes |> List.head |> Maybe.withDefault -1
                        in
                        if scaleIndex >= 0 && rotateIndex >= 0 then
                            Expect.equal True (scaleIndex < rotateIndex)

                        else
                            Expect.fail "Could not find both scale and rotate functions"
                    ]
                    keyframes
        ]
