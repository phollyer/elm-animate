module Engines.Keyframes.HelloText.Main exposing (main)

import Anim.Engine.CSS.Keyframes as Keyframes exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (style)



-- MAIN


main : Program () Model msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }



-- MODEL
-- Avoid typos from hardcoding strings in multiple places


groupName : String
groupName =
    "helloText"



---8<-- [start:model]


type alias Model =
    { animState : Keyframes.AnimState }


init : ( Model, Cmd msg )
init =
    ---8<-- [start:trigger]
    let
        animState =
            Keyframes.init
                [ Opacity.init groupName 0 ]
    in
    ( { animState = Keyframes.animate animState fadeIn }
      ---8<-- [end:trigger]
      ---8<-- [end:model]
    , Cmd.none
    )



-- ANIMATION
---8<-- [start:build]


fadeIn : AnimBuilder -> AnimBuilder
fadeIn =
    Opacity.for groupName
        >> Opacity.to 1
        >> Opacity.duration 5000
        >> Opacity.build



---8<-- [end:build]
-- VIEW


view : Model -> Html msg
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
        ---8<-- [start:render]
        [ Keyframes.styleNode model.animState
        , div
            (Keyframes.attributes groupName model.animState)
            [ text "Hello World!" ]
        ]



---8<-- [end:render]
