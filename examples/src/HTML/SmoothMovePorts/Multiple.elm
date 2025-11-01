port module HTML.SmoothMovePorts.Multiple exposing (main)

import Browser
import Dict
import Html exposing (Html, button, div, h1, h2, text)
import Html.Attributes exposing (id, style)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import SmoothMovePorts exposing (Timing(..))



-- PORTS --


port animateElement : String -> Cmd msg


port stopElementAnimation : String -> Cmd msg


port positionUpdates : (Decode.Value -> msg) -> Sub msg



-- MODEL --


type alias Model =
    { animations : SmoothMovePorts.Model
    }


type Msg
    = AnimateToCorners
    | AnimateToCenter
    | AnimateInSequence
    | StopAll
    | PositionUpdateMsg Decode.Value
    | AnimationCompleteMsg Decode.Value


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with starting positions to prevent jump to (0,0)
        initialAnimations =
            SmoothMovePorts.init
                |> SmoothMovePorts.setPosition "element-a" 100 100
                |> SmoothMovePorts.setPosition "element-b" 200 150
                |> SmoothMovePorts.setPosition "element-c" 150 200
    in
    ( { animations = initialAnimations
      }
    , Cmd.none
    )



-- UPDATE --


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimateToCorners ->
            let
                -- Animate multiple boxes to different corners using batch animation
                animationSpecs =
                    [ { elementId = "box1", targetX = 50, targetY = 50, config = { timing = Duration 800, easing = "ease-in-out" } }
                    , { elementId = "box2", targetX = 450, targetY = 50, config = { timing = Duration 600, easing = "cubic-bezier(0.68, -0.55, 0.265, 1.55)" } }
                    , { elementId = "box3", targetX = 450, targetY = 350, config = { timing = Duration 1000, easing = "ease-out" } }
                    , { elementId = "box4", targetX = 50, targetY = 350, config = { timing = Duration 700, easing = "ease-in-out" } }
                    ]

                ( newAnimations, cmd ) =
                    SmoothMovePorts.animateBatchWithPort animateElement animationSpecs model.animations
            in
            ( { model | animations = newAnimations }, cmd )

        AnimateToCenter ->
            let
                -- Simple 2x2 grid using batch animation - much cleaner!
                animationSpecs =
                    [ { elementId = "box1", targetX = 237, targetY = 137, config = { timing = Duration 500, easing = "ease-out" } }
                    , { elementId = "box2", targetX = 317, targetY = 137, config = { timing = Duration 750, easing = "ease-out" } }
                    , { elementId = "box3", targetX = 237, targetY = 217, config = { timing = Duration 600, easing = "ease-out" } }
                    , { elementId = "box4", targetX = 317, targetY = 217, config = { timing = Duration 900, easing = "ease-out" } }
                    ]

                ( newAnimations, cmd ) =
                    SmoothMovePorts.animateBatchWithPort animateElement animationSpecs model.animations
            in
            ( { model | animations = newAnimations }, cmd )

        AnimateInSequence ->
            let
                -- Sequential animation with staggered delays using different durations
                animationSpecs =
                    [ { elementId = "box1", targetX = 100, targetY = 100, config = { timing = Duration 400, easing = "ease-in-out" } }
                    , { elementId = "box2", targetX = 200, targetY = 150, config = { timing = Duration 600, easing = "ease-in-out" } }
                    , { elementId = "box3", targetX = 300, targetY = 200, config = { timing = Duration 800, easing = "ease-in-out" } }
                    , { elementId = "box4", targetX = 400, targetY = 250, config = { timing = Duration 1000, easing = "ease-in-out" } }
                    ]

                ( newAnimations, cmd ) =
                    SmoothMovePorts.animateBatchWithPort animateElement animationSpecs model.animations
            in
            ( { model | animations = newAnimations }, cmd )

        StopAll ->
            let
                ( newAnimations, cmd ) =
                    SmoothMovePorts.stopBatchWithPort stopElementAnimation [ "box1", "box2", "box3", "box4" ] model.animations
            in
            ( { model | animations = newAnimations }, cmd )

        PositionUpdateMsg _ ->
            -- For simplicity, not handling position updates in this example
            ( model, Cmd.none )

        AnimationCompleteMsg _ ->
            -- For simplicity, not handling animation completion in this example
            ( model, Cmd.none )



-- SUBSCRIPTIONS --


subscriptions : Model -> Sub Msg
subscriptions _ =
    positionUpdates PositionUpdateMsg



-- VIEW --


view : Model -> Html Msg
view model =
    div
        [ style "padding" "20px"
        , style "font-family" "Arial, sans-serif"
        ]
        [ h1 [] [ text "SmoothMovePorts - Multiple Animations" ]
        , h2 [] [ text "JavaScript Web Animations API Integration" ]
        , div
            [ style "margin" "20px 0" ]
            [ button
                [ onClick AnimateToCorners
                , style "margin-right" "10px"
                , style "padding" "10px 15px"
                , style "background-color" "#4CAF50"
                , style "color" "white"
                , style "border" "none"
                , style "border-radius" "4px"
                , style "cursor" "pointer"
                ]
                [ text "Animate to Corners" ]
            , button
                [ onClick AnimateToCenter
                , style "margin-right" "10px"
                , style "padding" "10px 15px"
                , style "background-color" "#2196F3"
                , style "color" "white"
                , style "border" "none"
                , style "border-radius" "4px"
                , style "cursor" "pointer"
                ]
                [ text "Animate to Center" ]
            , button
                [ onClick AnimateInSequence
                , style "margin-right" "10px"
                , style "padding" "10px 15px"
                , style "background-color" "#FF9800"
                , style "color" "white"
                , style "border" "none"
                , style "border-radius" "4px"
                , style "cursor" "pointer"
                ]
                [ text "Sequential Animation" ]
            , button
                [ onClick StopAll
                , style "padding" "10px 15px"
                , style "background-color" "#f44336"
                , style "color" "white"
                , style "border" "none"
                , style "border-radius" "4px"
                , style "cursor" "pointer"
                ]
                [ text "Stop All" ]
            ]
        , div
            [ style "position" "relative"
            , style "width" "600px"
            , style "height" "400px"
            , style "border" "2px solid #ddd"
            , style "margin" "20px 0"
            , style "background-color" "#f9f9f9"
            ]
            [ -- Center guidelines (temporary for debugging)
              div
                [ style "position" "absolute"
                , style "left" "299px" -- Vertical center line
                , style "top" "0"
                , style "width" "2px"
                , style "height" "100%"
                , style "background-color" "rgba(255, 0, 0, 0.3)"
                , style "pointer-events" "none"
                ]
                []
            , div
                [ style "position" "absolute"
                , style "left" "0"
                , style "top" "199px" -- Horizontal center line
                , style "width" "100%"
                , style "height" "2px"
                , style "background-color" "rgba(255, 0, 0, 0.3)"
                , style "pointer-events" "none"
                ]
                []

            -- Grid target area (where the 2x2 should be centered)
            , div
                [ style "position" "absolute"
                , style "left" "220px" -- Grid start X
                , style "top" "120px" -- Grid start Y
                , style "width" "160px" -- Grid total width (50+60+50)
                , style "height" "160px" -- Grid total height (50+60+50)
                , style "border" "2px dashed rgba(0, 0, 255, 0.5)"
                , style "background-color" "rgba(0, 0, 255, 0.1)"
                , style "pointer-events" "none"
                ]
                []

            -- Individual box target positions (centered within each 80x80 quadrant)
            , div
                [ style "position" "absolute"
                , style "left" "235px" -- box1 target: 220 + (80-50)/2 = 235
                , style "top" "135px" -- 120 + (80-50)/2 = 135
                , style "width" "50px"
                , style "height" "50px"
                , style "border" "1px solid rgba(255, 0, 0, 0.7)"
                , style "background-color" "rgba(255, 0, 0, 0.1)"
                , style "pointer-events" "none"
                ]
                []
            , div
                [ style "position" "absolute"
                , style "left" "315px" -- box2 target: 220 + 80 + (80-50)/2 = 315
                , style "top" "135px"
                , style "width" "50px"
                , style "height" "50px"
                , style "border" "1px solid rgba(0, 255, 0, 0.7)"
                , style "background-color" "rgba(0, 255, 0, 0.1)"
                , style "pointer-events" "none"
                ]
                []
            , div
                [ style "position" "absolute"
                , style "left" "235px" -- box3 target: 220 + (80-50)/2 = 235
                , style "top" "215px" -- 120 + 80 + (80-50)/2 = 215
                , style "width" "50px"
                , style "height" "50px"
                , style "border" "1px solid rgba(0, 0, 255, 0.7)"
                , style "background-color" "rgba(0, 0, 255, 0.1)"
                , style "pointer-events" "none"
                ]
                []
            , div
                [ style "position" "absolute"
                , style "left" "315px" -- box4 target: 220 + 80 + (80-50)/2 = 315
                , style "top" "215px" -- 120 + 80 + (80-50)/2 = 215
                , style "width" "50px"
                , style "height" "50px"
                , style "border" "1px solid rgba(255, 165, 0, 0.7)"
                , style "background-color" "rgba(255, 165, 0, 0.1)"
                , style "pointer-events" "none"
                ]
                []

            -- The actual animated boxes
            , animatedBox "box1" "#FF6B6B" model.animations -- Red
            , animatedBox "box2" "#4ECDC4" model.animations -- Teal
            , animatedBox "box3" "#45B7D1" model.animations -- Blue
            , animatedBox "box4" "#96CEB4" model.animations -- Green
            ]
        , div
            [ style "margin-top" "20px"
            , style "font-size" "14px"
            , style "color" "#666"
            ]
            [ text "This example demonstrates multiple simultaneous animations using the Web Animations API."
            , div [] [ text "• Different easing functions and durations for each element" ]
            , div [] [ text "• Hardware-accelerated performance via JavaScript" ]
            , div [] [ text "• Requires smooth-move-ports.js to be included in your HTML" ]
            ]
        ]


animatedBox : String -> String -> SmoothMovePorts.Model -> Html Msg
animatedBox elementId color animations =
    let
        position =
            SmoothMovePorts.getPosition elementId animations

        isAnimating =
            SmoothMovePorts.isAnimating animations

        borderStyle =
            if isAnimating then
                "3px solid #FFD700"
                -- Gold border when animating

            else
                "2px solid " ++ color
    in
    div
        [ id elementId
        , style "position" "absolute"
        , style "width" "40px"
        , style "height" "40px"
        , style "background-color" color
        , style "border" borderStyle
        , style "border-radius" "8px"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "color" "white"
        , style "font-weight" "bold"
        , style "font-size" "12px"
        , style "box-shadow" "0 2px 4px rgba(0,0,0,0.2)"
        , style "transform" (SmoothMovePorts.transformElement elementId animations)
        ]
        [ text (String.right 1 elementId) ]



-- Show box number
-- MAIN --


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
