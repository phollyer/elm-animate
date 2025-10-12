module HTML.SmoothMoveState.Basic exposing (main)

import Browser
import Html exposing (Html, button, div, h1, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import SmoothMoveState


type alias Model =
    { animationState : SmoothMoveState.State
    }


type Msg
    = AnimationFrame Float
    | MoveToCorner
    | MoveToCenter
    | StopAnimation


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with starting position to prevent jump to (0,0)
        initialState =
            SmoothMoveState.init
                |> SmoothMoveState.setInitialPosition "box" 50 50
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

        MoveToCorner ->
            ( { model | animationState = SmoothMoveState.animateTo "box" 300 200 model.animationState }
            , Cmd.none
            )

        MoveToCenter ->
            ( { model | animationState = SmoothMoveState.animateTo "box" 150 100 model.animationState }
            , Cmd.none
            )

        StopAnimation ->
            ( { model | animationState = SmoothMoveState.stopAnimation "box" model.animationState }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    SmoothMoveState.subscriptions model.animationState AnimationFrame


view : Model -> Html Msg
view model =
    let
        position =
            SmoothMoveState.getPosition "box" model.animationState
                |> Maybe.withDefault { x = 150, y = 100 }

        animatingText =
            if SmoothMoveState.isAnimating model.animationState then
                "Animating..."

            else
                "Idle"
    in
    div [ style "padding" "20px" ]
        [ h1 [] [ text "SmoothMoveState Example" ]
        , div []
            [ text ("Status: " ++ animatingText)
            , text (" | Position: (" ++ String.fromFloat position.x ++ ", " ++ String.fromFloat position.y ++ ")")
            ]
        , div [ style "margin" "20px 0" ]
            [ button [ onClick MoveToCorner ] [ text "Move to Corner (300, 200)" ]
            , button [ onClick MoveToCenter, style "margin-left" "10px" ] [ text "Move to Center (150, 100)" ]
            , button [ onClick StopAnimation, style "margin-left" "10px" ] [ text "Stop Animation" ]
            ]
        , div
            [ style "position" "relative"
            , style "width" "400px"
            , style "height" "300px"
            , style "border" "2px solid #ccc"
            , style "margin-top" "20px"
            ]
            [ div
                [ style "position" "absolute"
                , style "width" "50px"
                , style "height" "50px"
                , style "background-color" "#4CAF50"
                , style "border-radius" "8px"
                , style "transform" (SmoothMoveState.transformElement "box" model.animationState)
                , style "transition" "none" -- Disable CSS transitions
                ]
                [ text "📦" ]
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
