port module Engines.WAAPI.BasicUsage.Main exposing (main)

import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Opacity as Opacity
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (id, style)
import Json.Encode as Encode
import Process
import Task



-- Outgoing Port


port waapiCommand : Encode.Value -> Cmd msg



-- Incoming Port


port waapiEvent : (Encode.Value -> msg) -> Sub msg



-- Avoid typos from hardcoding element IDs in multiple places


elementId : String
elementId =
    "hello-text"


type alias Model =
    { animState : WAAPI.AnimState }


init : ( Model, Cmd Msg )
init =
    let
        -- Initialize the starting state for our element
        ( initialAnimState, initCmd ) =
            WAAPI.initProperties waapiCommand <|
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
        >> Opacity.duration 1000
        >> Opacity.build


slideIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
slideIn =
    Translate.for elementId
        >> Translate.toX 0
        >> Translate.duration 500
        >> Translate.build


type Msg
    = StartAnimation
    | GotWaapiUpdate ( WAAPI.AnimState, Maybe WAAPI.AnimationEvent )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartAnimation ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate waapiCommand model.animState <|
                        (fadeIn >> slideIn)
            in
            ( { model | animState = newAnimState }, cmd )

        GotWaapiUpdate ( newAnimState, maybeEvent ) ->
            handleEvent maybeEvent { model | animState = newAnimState }


handleEvent : Maybe WAAPI.AnimationEvent -> Model -> ( Model, Cmd Msg )
handleEvent maybeEvent model =
    -- Handle/react to events
    case maybeEvent of
        _ ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    waapiEvent (GotWaapiUpdate << WAAPI.decode model.animState)


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
