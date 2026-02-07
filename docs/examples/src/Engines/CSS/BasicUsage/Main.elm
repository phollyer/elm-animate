module Engines.CSS.BasicUsage.Main exposing (main)

import Anim.Engine.CSS.Transitions as CSS
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, div, text)
import Process
import Task


type alias Model =
    { animState : CSS.AnimState }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState = initialState }
    , Process.sleep 50 |> Task.perform (always TriggerAnimation)
    )


initialState : CSS.AnimState
initialState =
    CSS.animate (CSS.init []) (Translate.initX "hello-text" -100)


slideIn : CSS.AnimBuilder -> CSS.AnimBuilder
slideIn builder =
    builder
        |> Translate.for "hello-text"
        |> Translate.fromX -100
        |> Translate.toX 0
        |> Translate.duration 500
        |> Translate.build


type Msg
    = TriggerAnimation


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerAnimation ->
            ( { model
                | animState =
                    CSS.animate model.animState slideIn
              }
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    div
        (CSS.transitionAttributes "hello-text" model.animState)
        [ text "Hello!" ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }
