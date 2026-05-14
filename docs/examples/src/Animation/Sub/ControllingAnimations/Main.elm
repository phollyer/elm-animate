module Animation.Sub.ControllingAnimations.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as Sub
import Anim.Property.Translate as Translate
import Anim.Resize as Resize
import Browser
import Browser.Dom as Dom
import Browser.Events
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import Motion.Easing as Easing exposing (Easing(..))
import Process
import Task



-- MAIN


main : Program () Model Msg
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
    , canvasH : Float
    , animPlayState : AnimPlayState
    }


type AnimPlayState
    = NotStarted
    | Started


animGroup : String
animGroup =
    "bouncingBall"


canvasId : String
canvasId =
    "anim-canvas"


ballSize : Float
ballSize =
    50


topY : Float
topY =
    25



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            Sub.init
                [ Translate.initY animGroup topY ]
      , canvasH = 0
      , animPlayState = NotStarted
      }
    , Process.sleep 100
        |> Task.perform (\_ -> OnResize)
    )


measureCanvas : Cmd Msg
measureCanvas =
    Task.attempt GotCanvas (Dom.getElement canvasId)



-- POSITION HELPERS


bottomY : Float -> Float
bottomY h =
    h - ballSize



-- ANIMATION


dropBall : Float -> AnimBuilder mode -> AnimBuilder mode
dropBall toBottomY =
    Translate.for animGroup
        >> Translate.fromY topY
        >> Translate.toY toBottomY
        >> Translate.speed 200
        >> Translate.easing BounceOut
        >> Translate.build



-- UPDATE


type Msg
    = Animate
    | Stop
    | Pause
    | Resume
    | Reset
    | Restart
    | OnResize
    | GotCanvas (Result Dom.Error Dom.Element)
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
                | animPlayState = Started
                , animState =
                    Sub.animate model.animState <|
                        dropBall (bottomY model.canvasH)
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
        OnResize ->
            ( model, measureCanvas )

        GotCanvas (Ok element) ->
            ( handleResize { model | canvasH = element.element.height }
            , Cmd.none
            )

        GotCanvas (Err _) ->
            ( model, Cmd.none )


handleResize : Model -> Model
handleResize model =
    case model.animPlayState of
        NotStarted ->
            model

        Started ->
            let
                bounds =
                    { x = Nothing
                    , y = Just { min = topY, max = bottomY model.canvasH }
                    , z = Nothing
                    }
            in
            { model
                | animState =
                    Sub.onResize model.animState <|
                        Resize.onResize animGroup Resize.Proportional bounds
            }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.subscriptions GotSubMsg model.animState
        , Browser.Events.onResize (\_ _ -> OnResize)
        ]



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
        [ id canvasId
        , class "example-canvas--fluid"
        , style "background" "white"
        , style "border-radius" "12px"
        , style "box-shadow" "0 4px 8px rgba(0, 0, 0, 0.1)"
        ]
        [ div
            (Sub.attributes animGroup animState
                ++ [ style "position" "absolute"
                   , style "top" "0"
                   , style "left" "calc(50% - 25px)"
                   , style "width" "50px"
                   , style "height" "50px"
                   , style "font-size" "50px"
                   , style "line-height" "50px"
                   , style "text-align" "center"
                   ]
            )
            [ text "🏀" ]
        ]
