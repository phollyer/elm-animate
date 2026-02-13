module Engines.Transitions.BasicUsage.Main exposing (main)

import Anim.Engine.CSS.Transitions as Transitions
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (style)
import Process
import Task



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL


type State
    = Idle
    | Animating


type alias Model =
    { state : State }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { state = Idle }
    , Process.sleep 50
        |> Task.perform (always TriggerAnimation)
    )



-- ANIMATION


fadeIn : Transitions.AnimBuilder -> Transitions.AnimBuilder
fadeIn =
    Opacity.for "hello-text"
        >> Opacity.to 1
        >> Opacity.duration 5000
        >> Opacity.build



-- UPDATE


type Msg
    = TriggerAnimation


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerAnimation ->
            ( { model | state = Animating }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    let
        animState =
            case model.state of
                Idle ->
                    Transitions.init
                        [ Opacity.init "hello-text" 0 ]

                Animating ->
                    Transitions.fireAndForget fadeIn
    in
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
            (Transitions.attributes "hello-text" animState)
            [ text "Hello World!" ]
        ]
