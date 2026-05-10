module Animation.Sub.ControllingAnimations.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as Sub
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, button, div, h1, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Motion.Easing as Easing exposing (Easing(..))
import Motion.Spring as Spring



-- MAIN


main : Program { window : { width : Int } } Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : Sub.AnimState
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
                |> Debug.log "Min Animation area width:"

        xPos =
            toFloat animAreaWidth
                / 2
                - 25
                |> Debug.log "xPos:"
    in
    ( { animState =
            Sub.init <|
                [ Translate.initXY animGroup xPos 50 ]
      }
    , Cmd.none
    )



-- ANIMATION


dropBall : AnimBuilder mode -> AnimBuilder mode
dropBall =
    Translate.for animGroup
        >> Translate.fromY 50
        >> Translate.toY 300
        >> Translate.speed 20
        >> Translate.spring (Spring.custom { stiffness = 400, damping = 10, mass = 10 })
        >> Translate.build



-- UPDATE


type Msg
    = Animate
    | Stop
    | Pause
    | Resume
    | Reset
    | Restart
    | GotSubMsg Sub.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSubMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    Sub.update subMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        Animate ->
            ( { model
                | animState = Sub.animate model.animState dropBall
              }
            , Cmd.none
            )

        ---8<-- [start:stop]
        Stop ->
            ( { model | animState = Sub.stop animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:stop]
        ---8<-- [start:pause]
        Pause ->
            ( { model | animState = Sub.pause animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:pause]
        ---8<-- [start:resume]
        Resume ->
            ( { model | animState = Sub.resume animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:resume]
        ---8<-- [start:reset]
        Reset ->
            ( { model | animState = Sub.reset animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:reset]
        ---8<-- [start:restart]
        Restart ->
            ( { model | animState = Sub.restart animGroup model.animState }
            , Cmd.none
            )



---8<-- [end:restart]
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



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
        [ div [ class "ui-wrapped-row" ]
            [ div
                [ style "display" "flex"
                , style "flex-direction" "column"
                , style "gap" "16px"
                ]
                [ button [ onClick Animate, class "ui-action-button primary" ] [ text "🏀 Animate" ]
                , button [ onClick Stop, class "ui-action-button warning" ] [ text "⏹️ Stop" ]
                ]
            , div
                [ style "display" "flex"
                , style "flex-direction" "column"
                , style "gap" "16px"
                ]
                [ button [ onClick Pause, class "ui-action-button success" ] [ text "⏸️ Pause" ]
                , button [ onClick Resume, class "ui-action-button success" ] [ text "▶️ Resume" ]
                ]
            , div
                [ style "display" "flex"
                , style "flex-direction" "column"
                , style "gap" "16px"
                ]
                [ button [ onClick Reset, class "ui-action-button purple" ] [ text "⏮️ Reset" ]
                , button [ onClick Restart, class "ui-action-button purple" ] [ text "🔄 Restart" ]
                ]
            ]
        , animationArea model.animState
        ]


animationArea : Sub.AnimState -> Html msg
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
            (Sub.attributes animGroup animState
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
