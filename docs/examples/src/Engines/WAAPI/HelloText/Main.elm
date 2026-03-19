port module Engines.WAAPI.HelloText.Main exposing (main)

import Anim.Engine.WAAPI as WAAPI exposing (AnimBuilder)
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
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }



-- PORTS
-- Outgoing Port


port waapiCommand : Encode.Value -> Cmd msg



-- Incoming Port


port waapiEvent : (Encode.Value -> msg) -> Sub msg



-- MODEL
-- Avoid typos from hardcoding strings in multiple places


groupName : String
groupName =
    "helloText"



---8<-- [start:model]


type alias Model =
    { animState : WAAPI.AnimState Msg }


init : ( Model, Cmd Msg )
init =
    ---8<-- [start:trigger]
    let
        animState =
            WAAPI.init waapiCommand waapiEvent <|
                [ Opacity.init groupName 0 ]

        ( newAnimState, cmd ) =
            WAAPI.animate animState fadeIn
    in
    ( { animState = newAnimState }
    , cmd
    )



---8<-- [end:trigger]
---8<-- [end:model]


type Msg
    = NoOp



-- ANIMATION
---8<-- [start:build]


fadeIn : AnimBuilder -> AnimBuilder
fadeIn =
    Opacity.for groupName
        >> Opacity.to 1
        >> Opacity.duration 5000
        >> Opacity.build



---8<-- [end:build]
---8<-- [end:trigger]
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
        [ ---8<-- [start:render]
          div
            (WAAPI.attributes groupName model.animState)
            [ text "Hello World!" ]

        ---8<-- [end:render]
        ]
