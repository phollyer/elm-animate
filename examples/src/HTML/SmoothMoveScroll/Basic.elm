module HTML.SmoothMoveScroll.Basic exposing (main)

import Browser exposing (Document)
import Browser.Dom as Dom
import Dict exposing (Dict)
import Ease
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import SmoothMoveScroll exposing (scrollCmd)
import Task exposing (Task)


main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { foo = "bar" }, Cmd.none )


type alias Model =
    { foo : String }


type Msg
    = NoOp
    | SmoothScroll String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        SmoothScroll id ->
            ( model, scrollCmd NoOp id )


view : Model -> Document Msg
view model =
    { title = "SmoothMoveScroll Document Example"
    , body =
        [ a [ href "index.html", style "position" "fixed", style "top" "10px", style "left" "10px", style "background" "#666", style "color" "white", style "padding" "10px 15px", style "text-decoration" "none", style "border-radius" "5px", style "font-size" "14px", style "z-index" "1000" ] [ text "← Back" ]
        ]
            ++ [ div [ style "padding-top" "60px" ]
                    [ p
                        [ id "p-one"
                        , onClick (SmoothScroll "p-two")
                        ]
                        [ text "p one" ]
                    , p
                        [ id "p-two"
                        , style "margin-top" "2500px"
                        , onClick (SmoothScroll "p-one")
                        ]
                        [ text "p two" ]
                    ]
               ]
    }
