port module Animation.WAAPI.ControllingAnimations.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Translate as Translate
import Anim.Resize as Resize
import Anim.Resize.Builder as ResizeBuilder
import Browser
import Browser.Dom as Dom
import Browser.Events
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))
import Process
import Task



-- PORTS


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



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
    { animState : WAAPI.AnimState Msg
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
            WAAPI.init motionCmd motionMsg <|
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
    | GotWaapiMsg WAAPI.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotWaapiMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    WAAPI.update subMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        Animate ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate model.animState <|
                        dropBall (bottomY model.canvasH)
            in
            ( { model | animPlayState = Started, animState = newAnimState }
            , animCmd
            )

        ---8<-- [start:stop]
        Stop ->
            let
                ( newAnimState, stopCmd ) =
                    WAAPI.stop animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , stopCmd
            )

        ---8<-- [end:stop]
        ---8<-- [start:pause]
        Pause ->
            let
                ( newAnimState, pauseCmd ) =
                    WAAPI.pause animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , pauseCmd
            )

        ---8<-- [end:pause]
        ---8<-- [start:resume]
        Resume ->
            let
                ( newAnimState, resumeCmd ) =
                    WAAPI.resume animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , resumeCmd
            )

        ---8<-- [end:resume]
        ---8<-- [start:reset]
        Reset ->
            let
                ( newAnimState, resetCmd ) =
                    WAAPI.reset animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , resetCmd
            )

        ---8<-- [end:reset]
        ---8<-- [start:restart]
        Restart ->
            let
                ( newAnimState, restartCmd ) =
                    WAAPI.restart animGroup model.animState
            in
            ( { model | animState = newAnimState }
            , restartCmd
            )

        ---8<-- [end:restart]
        OnResize ->
            ( model, measureCanvas )

        GotCanvas (Ok element) ->
            handleResize { model | canvasH = element.element.height }

        GotCanvas (Err _) ->
            ( model, Cmd.none )


handleResize : Model -> ( Model, Cmd Msg )
handleResize model =
    case model.animPlayState of
        NotStarted ->
            ( model, Cmd.none )

        Started ->
            let
                bounds =
                    { x = Nothing
                    , y = Just { min = topY, max = bottomY model.canvasH }
                    , z = Nothing
                    }

                ( newAnimState, cmd ) =
                    WAAPI.onResize model.animState <|
                        ResizeBuilder.onResize animGroup Resize.Proportional bounds
            in
            ( { model | animState = newAnimState }, cmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ WAAPI.subscriptions GotWaapiMsg model.animState
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


animationArea : WAAPI.AnimState msg -> Html msg
animationArea animState =
    div
        [ id canvasId
        , class "example-canvas--fluid"
        , style "background" "white"
        , style "border-radius" "12px"
        , style "box-shadow" "0 4px 8px rgba(0, 0, 0, 0.1)"
        ]
        [ div
            (WAAPI.attributes animGroup animState
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
