module Animation.Keyframe.HelloText.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)



-- MAIN


main : Program () Model msg
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


type alias Model =
    { animState : Keyframe.AnimState }



---8<-- [start:trigger]


init : ( Model, Cmd msg )
init =
    let
        animState =
            Keyframe.init
                [ Opacity.init groupName 0 ]
    in
    ( { animState = Keyframe.animate animState fadeIn }
    , Cmd.none
    )



---8<-- [end:trigger]
---8<-- [end:model]
-- VIEW


view : Model -> Html msg
view model =
    div
        [ class "example-stage"
        , style "font-size" "48px"
        , style "font-weight" "bold"
        ]
        ---8<-- [start:render]
        [ Keyframe.styleNode model.animState
        , div
            (Keyframe.attributes groupName model.animState)
            [ text "Hello World!" ]
        ]



---8<-- [end:render]
