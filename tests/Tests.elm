module Tests exposing (suite)

import Anim exposing (AnimationTarget(..), ColorValue(..), EasePreset(..), Easing(..), Timing(..), getAnimationData, getDelay, getEasing, getElementId, getTarget, getTiming)
import Anim.Internal exposing (animationToMilliseconds)
import Ease
import Expect
import Internal.AnimationCore exposing (animationSteps)
import Test exposing (..)


suite : Test
suite =
    describe "Smooth Move Animation Tests"
        [ describe "Internal Animation Steps"
            [ test "start < stop" <|
                \_ ->
                    let
                        steps =
                            animationSteps 100 Ease.linear 0 100000
                    in
                    Expect.equal (List.sort steps) steps
            , test "stop < start" <|
                \_ ->
                    let
                        steps =
                            animationSteps 100 Ease.linear 100000 0
                    in
                    Expect.equal (List.reverse (List.sort steps)) steps
            , test "negative speed is no steps" <|
                \_ ->
                    let
                        steps =
                            animationSteps -100 Ease.linear 100000 0
                    in
                    Expect.equal steps []
            , test "zero speed is no steps" <|
                \_ ->
                    let
                        steps =
                            animationSteps 0 Ease.linear 100000 0
                    in
                    Expect.equal steps []
            , test "start == stop is no steps" <|
                \_ ->
                    let
                        steps =
                            animationSteps 100 Ease.linear 0 0
                    in
                    Expect.equal steps []
            ]
        , describe "Builder Pattern API"
            [ test "position animation with pixelsPerSecond timing" <|
                \_ ->
                    let
                        animation =
                            Anim.position "test-element" { x = 100, y = 200 }
                                |> Anim.pixelsPerSecond 300.0
                                |> Anim.easeOut

                        animData =
                            getAnimationData animation
                    in
                    Expect.all
                        [ \_ -> Expect.equal animData.elementId "test-element"
                        , \_ -> Expect.equal animData.target (ToPosition { x = 100, y = 200 })
                        , \_ -> Expect.equal animData.timing (PixelsPerSecond 300.0)
                        , \_ -> Expect.equal animData.easing (EasePreset EaseOut)
                        , \_ -> Expect.equal animData.delayMs 0
                        ]
                        ()
            , test "opacity animation with duration timing" <|
                \_ ->
                    let
                        animation =
                            Anim.opacity "my-div" 0.5
                                |> Anim.opacityDuration 500
                                |> Anim.easeInOut

                        animData =
                            getAnimationData animation
                    in
                    Expect.all
                        [ \_ -> Expect.equal animData.elementId "my-div"
                        , \_ -> Expect.equal animData.target (ToOpacity 0.5)
                        , \_ -> Expect.equal animData.timing (Duration 500)
                        , \_ -> Expect.equal animData.easing (EasePreset EaseInOut)
                        ]
                        ()
            , test "scale animation with delay" <|
                \_ ->
                    let
                        animation =
                            Anim.scale "scale-element" { x = 2.0, y = 2.0 }
                                |> Anim.scalePerSecond 1.5
                                |> Anim.linear
                                |> Anim.delay 200

                        animData =
                            getAnimationData animation
                    in
                    Expect.all
                        [ \_ -> Expect.equal animData.elementId "scale-element"
                        , \_ -> Expect.equal animData.target (ToScale { x = 2.0, y = 2.0 })
                        , \_ -> Expect.equal animData.timing (ScalePerSecond 1.5)
                        , \_ -> Expect.equal animData.easing (EasePreset Linear)
                        , \_ -> Expect.equal animData.delayMs 200
                        ]
                        ()
            , test "background color animation with colorStepsPerSecond" <|
                \_ ->
                    let
                        animation =
                            Anim.backgroundColor "color-div" (Hex "#ff0000")
                                |> Anim.colorStepsPerSecond 30.0
                                |> Anim.easeIn

                        animData =
                            getAnimationData animation
                    in
                    Expect.all
                        [ \_ -> Expect.equal animData.elementId "color-div"
                        , \_ -> Expect.equal animData.target (ToBackgroundColor (Hex "#ff0000"))
                        , \_ -> Expect.equal animData.timing (ColorStepsPerSecond 30.0)
                        , \_ -> Expect.equal animData.easing (EasePreset EaseIn)
                        ]
                        ()
            , test "rotation animation with degreesPerSecond" <|
                \_ ->
                    let
                        animation =
                            Anim.rotation "spinner" 360.0
                                |> Anim.degreesPerSecond 90.0
                                |> Anim.easeOut

                        animData =
                            getAnimationData animation
                    in
                    Expect.all
                        [ \_ -> Expect.equal animData.elementId "spinner"
                        , \_ -> Expect.equal animData.target (ToRotation 360.0)
                        , \_ -> Expect.equal animData.timing (DegreesPerSecond 90.0)
                        , \_ -> Expect.equal animData.easing (EasePreset EaseOut)
                        ]
                        ()
            ]
        , describe "Animation Duration Calculation"
            [ test "duration timing returns exact milliseconds" <|
                \_ ->
                    let
                        animation =
                            Anim.opacity "test" 0.5
                                |> Anim.opacityDuration 1000

                        calculatedDuration =
                            animationToMilliseconds animation 50.0
                    in
                    Expect.equal calculatedDuration 1000.0
            , test "pixelsPerSecond timing calculates based on distance" <|
                \_ ->
                    let
                        animation =
                            Anim.position "test" { x = 100, y = 0 }
                                |> Anim.pixelsPerSecond 100.0

                        -- Distance of 100 pixels at 100 pixels/second = 1 second = 1000ms
                        calculatedDuration =
                            animationToMilliseconds animation 100.0
                    in
                    Expect.equal calculatedDuration 1000.0
            ]
        , describe "Accessor Functions"
            [ test "getElementId extracts element ID" <|
                \_ ->
                    let
                        animation =
                            Anim.position "my-element" { x = 0, y = 0 }
                                |> Anim.duration 500
                    in
                    Expect.equal (getElementId animation) "my-element"
            , test "getTarget extracts animation target" <|
                \_ ->
                    let
                        animation =
                            Anim.opacity "test" 0.7
                                |> Anim.opacityDuration 300
                    in
                    Expect.equal (getTarget animation) (ToOpacity 0.7)
            , test "getTiming extracts timing configuration" <|
                \_ ->
                    let
                        animation =
                            Anim.scale "test" { x = 1.5, y = 1.5 }
                                |> Anim.scalePerSecond 2.0
                    in
                    Expect.equal (getTiming animation) (ScalePerSecond 2.0)
            , test "getEasing extracts easing configuration" <|
                \_ ->
                    let
                        animation =
                            Anim.rotation "test" 45.0
                                |> Anim.rotationDuration 400
                                |> Anim.easeInOut
                    in
                    Expect.equal (getEasing animation) (EasePreset EaseInOut)
            , test "getDelay extracts delay value" <|
                \_ ->
                    let
                        animation =
                            Anim.position "test" { x = 50, y = 50 }
                                |> Anim.duration 600
                                |> Anim.delay 150
                    in
                    Expect.equal (getDelay animation) 150
            ]
        ]
