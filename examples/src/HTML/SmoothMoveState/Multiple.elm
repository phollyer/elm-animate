module HTML.SmoothMoveState.Multiple exposing (main)

import Browser
import Ease
import Html exposing (Html, button, div, h1, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import SmoothMoveState


type alias Model =
    { animationState : SmoothMoveState.State
    }


type Msg
    = AnimationFrame Float
    | ScatterElements
    | ResetPositions
    | CircleFormation
    | StopAll


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with starting positions to prevent jump to (0,0)
        initialState =
            SmoothMoveState.init
                |> SmoothMoveState.setInitialPosition "element-a" 150 100
                |> SmoothMoveState.setInitialPosition "element-b" 200 150
                |> SmoothMoveState.setInitialPosition "element-c" 100 200
    in
    ( { animationState = initialState
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimationFrame deltaMs ->
            ( { model | animationState = SmoothMoveState.step deltaMs model.animationState }
            , Cmd.none
            )

        ScatterElements ->
            let
                newState =
                    model.animationState
                        |> SmoothMoveState.animateTo "box1" 50 50
                        |> SmoothMoveState.animateTo "box2" 250 80
                        |> SmoothMoveState.animateTo "box3" 320 180
                        |> SmoothMoveState.animateTo "box4" 80 220
            in
            ( { model | animationState = newState }, Cmd.none )

        ResetPositions ->
            let
                newState =
                    model.animationState
                        |> SmoothMoveState.animateTo "box1" 150 100
                        |> SmoothMoveState.animateTo "box2" 200 100
                        |> SmoothMoveState.animateTo "box3" 150 150
                        |> SmoothMoveState.animateTo "box4" 200 150
            in
            ( { model | animationState = newState }, Cmd.none )

        CircleFormation ->
            let
                defaultCfg =
                    SmoothMoveState.defaultConfig

                config =
                    { defaultCfg | easing = Ease.outElastic, speed = 300.0 }

                center =
                    { x = 175, y = 125 }

                radius =
                    60

                newState =
                    model.animationState
                        |> SmoothMoveState.animateToWithConfig config "box1" (center.x + radius) center.y
                        |> SmoothMoveState.animateToWithConfig config "box2" center.x (center.y - radius)
                        |> SmoothMoveState.animateToWithConfig config "box3" (center.x - radius) center.y
                        |> SmoothMoveState.animateToWithConfig config "box4" center.x (center.y + radius)
            in
            ( { model | animationState = newState }, Cmd.none )

        StopAll ->
            let
                newState =
                    model.animationState
                        |> SmoothMoveState.stopAnimation "box1"
                        |> SmoothMoveState.stopAnimation "box2"
                        |> SmoothMoveState.stopAnimation "box3"
                        |> SmoothMoveState.stopAnimation "box4"
            in
            ( { model | animationState = newState }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    SmoothMoveState.subscriptions model.animationState AnimationFrame


viewBox : String -> String -> SmoothMoveState.State -> Html Msg
viewBox elementId emoji state =
    div
        [ style "position" "absolute"
        , style "width" "40px"
        , style "height" "40px"
        , style "background-color" "#4CAF50"
        , style "border-radius" "8px"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "font-size" "20px"
        , style "transform" (SmoothMoveState.transformElement elementId state)
        , style "box-shadow" "0 2px 4px rgba(0,0,0,0.2)"
        ]
        [ text emoji ]


view : Model -> Html Msg
view model =
    let
        animatingText =
            if SmoothMoveState.isAnimating model.animationState then
                "Animating..."

            else
                "All animations complete"
    in
    div [ style "padding" "20px" ]
        [ h1 [] [ text "Multiple Animations with SmoothMoveState" ]
        , div [] [ text ("Status: " ++ animatingText) ]
        , div [ style "margin" "20px 0" ]
            [ button [ onClick ScatterElements ] [ text "Scatter" ]
            , button [ onClick ResetPositions, style "margin-left" "10px" ] [ text "Reset" ]
            , button [ onClick CircleFormation, style "margin-left" "10px" ] [ text "Circle (Elastic)" ]
            , button [ onClick StopAll, style "margin-left" "10px" ] [ text "Stop All" ]
            ]
        , div
            [ style "position" "relative"
            , style "width" "400px"
            , style "height" "300px"
            , style "border" "2px solid #ccc"
            , style "margin-top" "20px"
            , style "background-color" "#f9f9f9"
            ]
            [ viewBox "box1" "📦" model.animationState
            , viewBox "box2" "🎯" model.animationState
            , viewBox "box3" "⭐" model.animationState
            , viewBox "box4" "🚀" model.animationState
            ]
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
