port module Animation.WAAPI.ControllingAnimations.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, button, div, h1, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))



-- PORTS


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



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
    { animState : WAAPI.AnimState Msg
    }


{-| Animation group name for tracking animation state
-}
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

        initialAnimState =
            WAAPI.init motionCmd motionMsg <|
                [ Translate.initXY animGroup xPos 50 ]
    in
    ( { animState = initialAnimState
      }
    , Cmd.none
    )



-- ANIMATION


dropBall : AnimBuilder mode -> AnimBuilder mode
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
    | Pause
    | Resume
    | Reset
    | Restart
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
                    WAAPI.animate model.animState dropBall
            in
            ( { model | animState = newAnimState }
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
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



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
        [ class "example-canvas"
        , style "background" "white"
        , style "border-radius" "12px"
        , style "box-shadow" "0 4px 8px rgba(0, 0, 0, 0.1)"
        ]
        [ div
            (WAAPI.attributes animGroup animState
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
