module Engines.Keyframes.BasicUsage.Main exposing (main)

import Anim.Engine.CSS.Keyframes as Keyframes
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (style)



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
    { animState : Keyframes.AnimState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        initialAnimState =
            Keyframes.init
                [ Opacity.init "hello-text" 0 ]
    in
    ( { animState = Keyframes.animate initialAnimState fadeIn }
    , Cmd.none
    )



-- ANIMATION


fadeIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
fadeIn =
    Opacity.for "hello-text"
        >> Opacity.to 1
        >> Opacity.duration 5000
        >> Opacity.build



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )



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
        [ Keyframes.styleNode model.animState
        , div
            (Keyframes.attributes "hello-text" model.animState)
            [ text "Hello World!" ]
        ]
