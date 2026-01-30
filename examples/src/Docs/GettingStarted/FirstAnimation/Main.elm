module Docs.GettingStarted.FirstAnimation.Main exposing (main)

import Anim.Engine.CSS as CSS
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (id, style)
import Process
import Task


type alias Model =
    { state : State }


type State
    = Ready
    | FadeIn


init : () -> ( Model, Cmd Msg )
init _ =
    ( { state = Ready }
    , Process.sleep 50 |> Task.perform (always TriggerFadeIn)
    )


type Msg
    = TriggerFadeIn


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerFadeIn ->
            ( { model | state = FadeIn }, Cmd.none )



-- --8<-- [start:fadeIn]


fadeInBuilder : CSS.AnimBuilder -> CSS.AnimBuilder
fadeInBuilder builder =
    builder
        |> Opacity.for "my-box"
        |> Opacity.from 0
        |> Opacity.to 1
        |> Opacity.duration 2500
        |> Opacity.build



-- --8<-- [end:fadeIn]
-- --8<-- [start:animState]


fadeInAnimation : CSS.AnimState
fadeInAnimation =
    CSS.init
        |> CSS.builder
        |> fadeInBuilder
        |> CSS.animate



-- --8<-- [end:animState]
-- --8<-- [start:applyStyles]


view : Model -> Html Msg
view model =
    let
        fadeIn =
            case model.state of
                Ready ->
                    CSS.init

                FadeIn ->
                    fadeInAnimation
    in
    div []
        [ div
            ([ id "my-box"
             , style "opacity" "0"
             , style "width" "100px"
             , style "height" "100px"
             , style "background-color" "blue"
             ]
                ++ CSS.transitionAttributes "my-box" fadeIn
            )
            [ text "Hello!" ]
        ]



-- --8<-- [end:applyStyles]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }
