module Animation.Keyframe.ControllingAnimations.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
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
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    { animState : Keyframe.AnimState
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
            Keyframe.init <|
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
        >> Translate.speed 200
        >> Translate.easing BounceOut
        >> Translate.build



-- UPDATE


type Msg
    = Animate
    | Stop
    | Reset
    | Restart
    | Pause
    | Resume
    | GotAnimMsg Keyframe.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate ->
            ( { model
                | animState = Keyframe.animate model.animState dropBall
              }
            , Cmd.none
            )

        ---8<-- [start:stop]
        Stop ->
            ( { model | animState = Keyframe.stop animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:stop]
        ---8<-- [start:reset]
        Reset ->
            ( { model | animState = Keyframe.reset animGroup model.animState }
            , Cmd.none
            )

        ---8<-- [end:reset]
        ---8<-- [start:restart]
        Restart ->
            let
                ( newState, eventCmd ) =
                    Keyframe.restart animGroup GotAnimMsg model.animState
            in
            ( { model | animState = newState }, eventCmd )

        ---8<-- [end:restart]
        ---8<-- [start:pause]
        Pause ->
            let
                ( newState, eventCmd ) =
                    Keyframe.pause animGroup GotAnimMsg model.animState
            in
            ( { model | animState = newState }, eventCmd )

        ---8<-- [end:pause]
        ---8<-- [start:resume]
        Resume ->
            let
                ( newState, eventCmd ) =
                    Keyframe.resume animGroup GotAnimMsg model.animState
            in
            ( { model | animState = newState }, eventCmd )

        ---8<-- [end:resume]
        GotAnimMsg _ ->
            ( model, Cmd.none )



---8<-- [end:resume]
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
        [ Keyframe.styleNodeFor animGroup model.animState
        , div [ class "ui-wrapped-row" ]
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


animationArea : Keyframe.AnimState -> Html msg
animationArea animState =
    div
        [ class "example-canvas"
        , style "background" "white"
        , style "border-radius" "12px"
        , style "box-shadow" "0 4px 8px rgba(0, 0, 0, 0.1)"
        ]
        [ div
            (Keyframe.attributes animGroup animState
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
