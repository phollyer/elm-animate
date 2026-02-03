port module Engines.WAAPI.BasicUsage.Main exposing (main)

import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Opacity as Opacity
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (id)
import Json.Encode as Encode
import Process
import Task



-- Outgoing Port


port waapiCommand : Encode.Value -> Cmd msg



-- Incoming Port


port waapiSubscriptions : (Encode.Value -> msg) -> Sub msg



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
            WAAPI.init waapiCommand waapiSubscriptions <|
                [ Translate.initX elementId -100
                , Opacity.init elementId 0
                ]
    in
    ( { animState = initialAnimState }
    , Cmd.batch
        [ initCmd

        -- Simulate a user action to start the animation after a short delay
        , Process.sleep 50 |> Task.perform (always StartAnimation)
        ]
    )


fadeIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
fadeIn =
    Opacity.for elementId
        >> Opacity.to 1
        >> Opacity.duration 2000
        >> Opacity.build


slideIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
slideIn =
    Translate.for elementId
        >> Translate.toX 0
        >> Translate.duration 500
        >> Translate.build


type Msg
    = StartAnimation
    | GotWaapiMsg WAAPI.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartAnimation ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        (fadeIn >> slideIn)
            in
            ( { model | animState = newAnimState }, cmd )

        GotWaapiMsg subMsg ->
            let
                ( newAnimState, events ) =
                    WAAPI.update subMsg model.animState
            in
            handleEvents events { model | animState = newAnimState }


handleEvents : List WAAPI.AnimationEvent -> Model -> ( Model, Cmd Msg )
handleEvents events model =
    -- Handle/react to events
    List.foldl handleSingleEvent ( model, Cmd.none ) events


handleSingleEvent : WAAPI.AnimationEvent -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
handleSingleEvent event ( model, cmd ) =
    case event of
        _ ->
            ( model, cmd )


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState


view : Model -> Html Msg
view model =
    div
        [ id elementId ]
        [ text "Hello!" ]


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
