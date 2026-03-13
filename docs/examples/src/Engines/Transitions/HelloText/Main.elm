module Engines.Transitions.HelloText.Main exposing (main)

import Anim.Engine.CSS.Transitions as Transitions exposing (AnimBuilder)
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



-- MODEL
-- Avoid typos from hardcoding strings in multiple places


groupName : String
groupName =
    "helloText"



---8<-- [start:model]


type alias Model =
    { animState : Transitions.AnimState }


init : ( Model, Cmd Msg )
init =
    let
        animState =
            Transitions.init
                [ Opacity.init groupName 0 ]
    in
    ( { animState = animState }
    , Process.sleep 50
        |> Task.perform (always TriggerAnimation)
    )



---8<-- [end:model]
-- ANIMATION
---8<-- [start:build]


fadeIn : AnimBuilder -> AnimBuilder
fadeIn =
    Opacity.for groupName
        >> Opacity.to 1
        >> Opacity.duration 5000
        >> Opacity.build



---8<-- [end:build]
-- UPDATE
---8<-- [start:update]


type Msg
    = TriggerAnimation
    | GotTransitionMsg Transitions.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTransitionMsg animMsg ->
            let
                ( animState, _ ) =
                    Transitions.update animMsg model.animState
            in
            ( { model | animState = animState }
            , Cmd.none
            )

        ---8<-- [end:update]
        ---8<-- [start:trigger]
        TriggerAnimation ->
            ( { model | animState = Transitions.animate (Transitions.init []) fadeIn }
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
        [ ---8<-- [start:render]
          div
            (Transitions.attributes groupName model.animState)
            [ text "Hello World!" ]

        ---8<-- [end:render]
        ]
