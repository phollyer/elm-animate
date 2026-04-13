module Engines.Transition.ControllingAnimations.Main exposing (main)

import Anim.Engine.CSS.Transition as Transition exposing (AnimBuilder)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, button, div, h1, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)



-- MAIN


main : Program { window : { width : Int } } Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    { animState : Transition.AnimState
    }


animGroup : String
animGroup =
    "bouncingBall"



-- INIT


init : { window : { width : Int } } -> ( Model, Cmd Msg )
init { window } =
    let
        animAreaWidth =
            min 500 (window.width - 40)

        xPos =
            toFloat animAreaWidth / 2 - 25
    in
    ( { animState =
            Transition.init <|
                [ Translate.initXY animGroup xPos 50 ]
      }
    , Cmd.none
    )



-- ANIMATION


dropBall : AnimBuilder -> AnimBuilder
dropBall =
    Translate.for animGroup
        >> Translate.fromY 50
        >> Translate.toY 300
        >> Translate.speed 200
        >> Translate.easing BounceOut
        >> Translate.build



-- UPDATE


type Msg
    = Animate
    | Stop
    | Reset


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate ->
            ( { model
                | animState = Transition.animate model.animState dropBall
              }
            , Cmd.none
            )

        ---8<-- [start:stop]
        Stop ->
            ( { model | animState = Transition.stop animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:stop]
        ---8<-- [start:reset]
        Reset ->
            ( { model | animState = Transition.reset animGroup model.animState }
            , Cmd.none
            )



---8<-- [end:reset]
-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "gap" "24px"
        , style "padding" "20px"
        ]
        [ h1
            [ style "font-size" "28px"
            , style "font-weight" "600"
            , style "color" "#1e293b"
            , style "margin" "0"
            ]
            [ text "Transition Engine Controls" ]
        , div [ class "ui-wrapped-row" ]
            [ button [ onClick Animate, class "ui-action-button primary" ] [ text "🏀 Animate" ]
            , button [ onClick Stop, class "ui-action-button warning" ] [ text "⏹️ Stop" ]
            , button [ onClick Reset, class "ui-action-button purple" ] [ text "⏮️ Reset" ]
            ]
        , animationArea model.animState
        ]


animationArea : Transition.AnimState -> Html msg
animationArea animState =
    div
        [ style "width" "100%"
        , style "max-width" "500px"
        , style "height" "350px"
        , style "background" "white"
        , style "border-radius" "12px"
        , style "box-shadow" "0 4px 8px rgba(0, 0, 0, 0.1)"
        ]
        [ div
            (Transition.attributes animGroup animState
                ++ [ style "position" "relative"
                   , style "width" "50px"
                   , style "height" "50px"
                   , style "font-size" "50px"
                   , style "line-height" "50px"
                   , style "text-align" "center"
                   ]
            )
            [ text "🏀" ]
        ]
