module HTML.SmoothMoveCSS.Basic exposing (main)

import Browser
import Html exposing (Html, button, div, h1, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import SmoothMoveCSS


type alias Model =
    { animations : SmoothMoveCSS.Model
    }


type Msg
    = MoveToCorner
    | MoveToCenter
    | StopAnimation


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with starting position to prevent jump to (0,0)
        initialAnimations =
            SmoothMoveCSS.init
                |> SmoothMoveCSS.setPosition "box" 50 50
    in
    ( { animations = initialAnimations
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToCorner ->
            ( { model | animations = SmoothMoveCSS.animateTo "box" 300 200 model.animations }
            , Cmd.none
            )

        MoveToCenter ->
            ( { model | animations = SmoothMoveCSS.animateTo "box" 150 100 model.animations }
            , Cmd.none
            )

        StopAnimation ->
            ( { model | animations = SmoothMoveCSS.stopAnimation "box" model.animations }
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    let
        position =
            SmoothMoveCSS.getPosition "box" model.animations
                |> Maybe.withDefault { x = 150, y = 100 }

        animatingText =
            if SmoothMoveCSS.isAnimating model.animations then
                "Animating with CSS transitions..."

            else
                "Idle"
    in
    div [ style "padding" "20px" ]
        [ h1 [] [ text "SmoothMoveCSS Example - Native CSS Transitions" ]
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
            , style "background-color" "#f9f9f9"
            ]
            [ div
                [ style "position" "absolute"
                , style "width" "50px"
                , style "height" "50px"
                , style "background-color" "#FF5722"
                , style "border-radius" "8px"
                , style "transform" (SmoothMoveCSS.transformElement "box" model.animations)
                , style "transition" (SmoothMoveCSS.cssTransitionStyle "box" model.animations)
                , style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "color" "white"
                , style "font-weight" "bold"
                ]
                [ text "CSS" ]
            ]
        , div [ style "margin-top" "20px", style "font-size" "14px", style "color" "#666" ]
            [ text "This example uses native CSS transitions instead of JavaScript animation frames."
            , Html.br [] []
            , text "The browser handles all the smooth interpolation automatically!"
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    -- CSS transitions don't require animation frame subscriptions!
    -- The browser handles everything automatically
    Sub.none


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
