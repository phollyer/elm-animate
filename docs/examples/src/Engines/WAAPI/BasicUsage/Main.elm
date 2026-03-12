port module Engines.WAAPI.BasicUsage.Main exposing (main)

import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (id, style)
import Json.Encode as Encode
import Process
import Task



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- PORTS
-- Outgoing Port


port waapiCommand : Encode.Value -> Cmd msg



-- Incoming Port


port waapiEvent : (Encode.Value -> msg) -> Sub msg



-- MODEL
-- Avoid typos from hardcoding strings in multiple places


groupName : String
groupName =
    "helloText"


elementId : String
elementId =
    "hello-text"


type alias Model =
    { animState : WAAPI.AnimState Msg }


init : ( Model, Cmd Msg )
init =
    let
        animState =
            WAAPI.init waapiCommand waapiEvent <|
                [ WAAPI.forElement elementId
                    >> Opacity.init groupName 0
                ]
    in
    ( { animState = animState }
    , Process.sleep 50
        |> Task.perform (always TriggerAnimation)
    )



-- ANIMATION


fadeIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
fadeIn =
    Opacity.for groupName
        >> Opacity.to 1
        >> Opacity.duration 5000
        >> Opacity.build



-- UPDATE


type Msg
    = TriggerAnimation
    | GotWaapiMsg WAAPI.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerAnimation ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        WAAPI.forElement elementId
                            >> fadeIn
            in
            ( { model | animState = newAnimState }
            , cmd
            )

        GotWaapiMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    WAAPI.update subMsg model.animState
            in
            ( { model | animState = newAnimState }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "font-size" "48px"
        , style "font-weight" "bold"
        , style "height" "100vh"
        , style "width" "100vw"
        ]
        [ div
            (WAAPI.attributes groupName model.animState
                ++ [ id elementId ]
            )
            [ text "Hello World!" ]
        ]
