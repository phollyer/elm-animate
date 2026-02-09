module Engines.Transitions.BasicUsage.Main exposing (main)

import Anim.Engine.CSS.Transitions as CSS
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (style)
import Process
import Task


type alias Model =
    { animState : CSS.AnimState }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState = CSS.init [ Opacity.init "hello-text" 0 ] }
    , Process.sleep 50 |> Task.perform (always TriggerAnimation)
    )


fadeIn : CSS.AnimBuilder -> CSS.AnimBuilder
fadeIn =
    Opacity.for "hello-text"
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.duration 5000
        >> Opacity.build


type Msg
    = TriggerAnimation


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerAnimation ->
            ( { model
                | animState =
                    CSS.animate model.animState fadeIn
              }
            , Cmd.none
            )


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
            (CSS.attributes "hello-text" model.animState)
            [ text "Hello World!" ]
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }
