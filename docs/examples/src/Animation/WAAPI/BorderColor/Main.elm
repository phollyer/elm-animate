port module Animation.WAAPI.BorderColor.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Extra.Color as Color
import Anim.Property.CustomColor as CustomColor
import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))



-- PORTS


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : WAAPI.AnimState Msg }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            WAAPI.init motionCmd motionMsg <|
                [ CustomColor.init animGroup
                    CustomColor.BorderColor
                    (Color.rgb 99 102 241)
                ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "boxAnim"


toRed : AnimBuilder mode -> AnimBuilder mode
toRed =
    CustomColor.for animGroup CustomColor.BorderColor
        >> CustomColor.to (Color.rgb 239 68 68)
        >> CustomColor.duration 800
        >> CustomColor.easing CubicInOut
        >> CustomColor.build


toBlue : AnimBuilder mode -> AnimBuilder mode
toBlue =
    CustomColor.for animGroup CustomColor.BorderColor
        >> CustomColor.to (Color.rgb 59 130 246)
        >> CustomColor.duration 800
        >> CustomColor.easing CubicInOut
        >> CustomColor.build



-- UPDATE


type Msg
    = GotWaapiMsg WAAPI.AnimMsg
    | TriggerRed
    | TriggerBlue


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotWaapiMsg waapiMsg ->
            let
                ( newAnimState, _ ) =
                    WAAPI.update waapiMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        TriggerRed ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState toRed
            in
            ( { model | animState = newAnimState }
            , cmd
            )

        TriggerBlue ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState toBlue
            in
            ( { model | animState = newAnimState }
            , cmd
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "text-align" "center"
        , style "height" "90vh"
        , style "width" "100%"
        , style "padding-top" "10px"
        ]
        [ button
            [ onClick TriggerRed
            , class "ui-action-button primary"
            , style "margin-right" "10px"
            ]
            [ text "Red Border" ]
        , button
            [ onClick TriggerBlue
            , class "ui-action-button primary"
            ]
            [ text "Blue Border" ]
        , div
            [ style "height" "80vh"
            , style "width" "100%"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "padding-top" "10px"
            ]
            [ div
                (WAAPI.attributes animGroup model.animState
                    ++ [ style "height" "200px"
                       , style "width" "200px"
                       , style "background-color" "#f8fafc"
                       , style "border" "4px solid #6366f1"
                       , style "border-radius" "8px"
                       ]
                )
                []
            ]
        ]
