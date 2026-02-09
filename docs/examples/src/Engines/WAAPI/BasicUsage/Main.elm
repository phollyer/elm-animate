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


port waapiEvents : (Encode.Value -> msg) -> Sub msg



-- MODEL
-- Avoid typos from hardcoding element IDs in multiple places


elementId : String
elementId =
    "hello-text"


type alias Model =
    { animState : WAAPI.AnimState Msg }


init : ( Model, Cmd Msg )
init =
    let
        -- Initialize the starting state for our element
        ( initialAnimState, initCmd ) =
            WAAPI.init waapiCommand waapiEvents <|
                [ Opacity.init elementId 0 ]
    in
    ( { animState = initialAnimState }
    , Cmd.batch
        [ initCmd

        -- Simulate a user action to start the animation after a short delay
        --, Process.sleep 50 |> Task.perform (always StartAnimation)
        ]
    )



-- ANIMATION


fadeIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
fadeIn =
    Opacity.for elementId
        >> Opacity.to 1
        >> Opacity.duration 5000
        >> Opacity.build



-- UPDATE


type Msg
    = StartAnimation
    | GotWaapiMsg WAAPI.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartAnimation ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState fadeIn
            in
            ( { model | animState = newAnimState }, cmd )

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
            [ id elementId
            , style "opacity" "0"
            ]
            [ text "Hello World!" ]
        ]
