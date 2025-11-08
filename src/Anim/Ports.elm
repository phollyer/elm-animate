module Anim.Ports exposing (animate, animateBatch)

{-| Ports-based animation system for Anim.

This module converts AnimBuilder configurations to JavaScript Web Animations API calls
via Elm ports for maximum performance and browser compatibility.


# Animation Execution

@docs animate, animateBatch

-}

import Anim exposing (AnimBuilder)
import Anim.Internal.Builder as Builder
import Json.Encode as Encode


{-| Execute animations using JavaScript Web Animations API via ports.

    Anim.init "my-element"
        |> Anim.Properties.Position.to { x = 100, y = 200 }
        |> Anim.Properties.Position.speed 500
        |> Anim.Ports.animate sendAnimationCommand

The port function should have the signature:

    port sendAnimationCommand : Encode.Value -> Cmd msg

-}
animate : (Encode.Value -> Cmd msg) -> AnimBuilder -> Cmd msg
animate portFunction builder =
    let
        processedData =
            Builder.processAnimationData builder

        encodedData =
            Builder.encode processedData
    in
    portFunction encodedData


{-| Batch and send a List of animations in one go.

    createCircleAnimation index elementId =
        let
            angle =
                toFloat index * angleStep

            x =
                centerX + radius * cos angle

            y =
                centerY + radius * sin angle
        in
        Anim.init elementId
            |> Position.to { x = x, y = y }
            |> Position.duration 1000
            |> Position.easing Easing.easeInOut

    cmd1 =
        Anim.animateBatch animateElement <|
            [ createCircleAnimation 0 "element1"
            , createCircleAnimation 1 "element2"
            , createCircleAnimation 2 "element3"
            , createCircleAnimation 3 "element4"
            , createCircleAnimation 4 "element5"
            , createCircleAnimation 5 "element6"
            , createCircleAnimation 6 "element7"
            , createCircleAnimation 7 "element8"
            , createCircleAnimation 8 "element9"
            , createCircleAnimation 9 "element10"
            , createCircleAnimation 10 "element11"
            , createCircleAnimation 11 "element12"
            , createCircleAnimation 12 "element13"
            ]

-}
animateBatch : (Encode.Value -> Cmd msg) -> List AnimBuilder -> Cmd msg
animateBatch portFunction builders =
    builders
        |> List.map (animate portFunction)
        |> Cmd.batch
