module Engines.Sub.BasicUsage.Main exposing (main)

import Anim.Engine.Sub as Sub
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, div, text)


type alias Model =
    { animState : Sub.AnimState }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            Sub.animate Sub.init slideIn
      }
    , Cmd.none
    )


slideIn : Sub.AnimBuilder -> Sub.AnimBuilder
slideIn =
    Translate.for "hello-text"
        >> Translate.fromX -100
        >> Translate.toX 0
        >> Translate.duration 500
        >> Translate.build


type Msg
    = GotAnimationUpdate Sub.AnimationMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimationUpdate animationMsg ->
            ( { model | animState = Sub.update animationMsg model.animState }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotAnimationUpdate model.animState


view : Model -> Html Msg
view model =
    div
        (Sub.htmlAttributes "hello-text" model.animState)
        [ text "Hello!" ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
