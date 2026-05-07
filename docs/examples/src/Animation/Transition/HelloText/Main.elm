module Animation.Transition.HelloText.Main exposing (main)

import Anim.Engine.Transition as Transition exposing (EngineBuilder)
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
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- ANIMATION
---8<-- [start:build]
-- Avoid typos from hardcoding strings in multiple places


groupName : String
groupName =
    "helloText"


fadeIn : EngineBuilder -> EngineBuilder
fadeIn =
    Opacity.for groupName
        >> Opacity.to 1
        >> Opacity.duration 5000
        >> Opacity.build



---8<-- [end:build]
---8<-- [start:model]


type alias Model =
    { animState : Transition.AnimState }



---8<-- [start:trigger-cmd]


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Transition.init
                [ Opacity.init groupName 0 ]
      }
    , Process.sleep 0
        |> Task.perform (always TriggerAnimation)
    )



---8<-- [end:model]
---8<-- [end:trigger-cmd]
-- UPDATE


type Msg
    = TriggerAnimation


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:trigger]
        TriggerAnimation ->
            ( { model | animState = Transition.animate model.animState fadeIn }
            , Cmd.none
            )



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
        ---8<-- [start:render]
        [ div
            (Transition.attributes groupName model.animState)
            [ text "Hello World!" ]
        ]



---8<-- [end:render]
