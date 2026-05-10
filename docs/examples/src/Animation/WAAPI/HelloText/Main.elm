port module Animation.WAAPI.HelloText.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, id, style)
import Json.Encode as Encode
import Process
import Task



-- PORTS
-- Outgoing Port


port motionCmd : Encode.Value -> Cmd msg



-- Incoming Port


port motionMsg : (Encode.Value -> msg) -> Sub msg



-- MAIN


main : Program () (Model msg) msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }



-- ANIMATION
---8<-- [start:build]
-- Avoid typos from hardcoding strings in multiple places


groupName : String
groupName =
    "helloText"


fadeIn : AnimBuilder mode -> AnimBuilder mode
fadeIn =
    Opacity.for groupName
        >> Opacity.to 1
        >> Opacity.duration 5000
        >> Opacity.build



---8<-- [end:build]
---8<-- [start:model]


type alias Model msg =
    { animState : WAAPI.AnimState msg }



---8<-- [start:trigger]


init : ( Model msg, Cmd msg )
init =
    let
        animState =
            WAAPI.init motionCmd motionMsg <|
                [ Opacity.init groupName 0 ]

        ( newAnimState, cmd ) =
            WAAPI.animate animState fadeIn
    in
    ( { animState = newAnimState }
    , cmd
    )



---8<-- [end:trigger]
---8<-- [end:model]
-- VIEW


view : Model msg -> Html msg
view model =
    div
        [ class "example-stage"
        , style "font-size" "48px"
        , style "font-weight" "bold"
        ]
        ---8<-- [start:render]
        [ div
            (WAAPI.attributes groupName model.animState)
            [ text "Hello World!" ]
        ]



---8<-- [end:render]
