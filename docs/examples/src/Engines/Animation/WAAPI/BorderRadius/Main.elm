port module Engines.Animation.WAAPI.BorderRadius.Main exposing (main)

import Anim.Engine.WAAPI as WAAPI exposing (AnimBuilder)
import Anim.Property.Custom as Property
import Browser
import Easing exposing (Easing(..))
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode



-- PORTS


port waapiCommand : Encode.Value -> Cmd msg


port waapiEvent : (Encode.Value -> msg) -> Sub msg



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
            WAAPI.init waapiCommand waapiEvent <|
                [ Property.init animGroup (BorderRadius "px") 0 ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "boxAnim"


roundCorners : AnimBuilder -> AnimBuilder
roundCorners =
    Property.for animGroup (BorderRadius "px")
        >> Property.to 48
        >> Property.duration 800
        >> Property.easing CubicInOut
        >> Property.build


squareCorners : AnimBuilder -> AnimBuilder
squareCorners =
    Property.for animGroup (BorderRadius "px")
        >> Property.to 0
        >> Property.duration 800
        >> Property.easing CubicInOut
        >> Property.build



-- UPDATE


type Msg
    = GotWaapiMsg WAAPI.AnimMsg
    | TriggerRound
    | TriggerSquare


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

        TriggerRound ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState roundCorners
            in
            ( { model | animState = newAnimState }
            , cmd
            )

        TriggerSquare ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState squareCorners
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
            [ onClick TriggerRound
            , class "ui-action-button primary"
            , style "margin-right" "10px"
            ]
            [ text "Round" ]
        , button
            [ onClick TriggerSquare
            , class "ui-action-button primary"
            ]
            [ text "Square" ]
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
                       , style "background-color" "#6366f1"
                       ]
                )
                []
            ]
        ]
