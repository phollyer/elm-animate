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


type alias Model =
    { animState : Transitions.AnimState }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState = Transitions.init [ Opacity.init "helloTextAnim" 0 ] }
    , Process.sleep 50
        |> Task.perform (always TriggerAnimation)
    )



-- ANIMATION


fadeIn : Transitions.AnimBuilder -> Transitions.AnimBuilder
fadeIn =
    Opacity.for "helloTextAnim"
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
            ( { model | animState = Transitions.fireAndForget fadeIn }
            , Cmd.none
            )



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
            (Transitions.attributes "helloTextAnim" model.animState)
            [ text "Hello World!" ]
        ]
