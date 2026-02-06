module GettingStarted.FirstAnimation.Main exposing (main)

import Anim.Easing exposing (Easing(..))
import Anim.Engine.CSS as CSS
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (id, style)
import Process
import Task


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


type State
    = Ready
    | FadeIn


type alias Model =
    { state : State }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { state = Ready }
    , Process.sleep 50 |> Task.perform (always TriggerFadeIn)
    )


-- UPDATE


type Msg
    = TriggerFadeIn


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerFadeIn ->
            ( { model | state = FadeIn }, Cmd.none )


-- ANIMATION BUILDER
-- --8<-- [start:fadeIn]


fadeInBuilder : CSS.AnimBuilder -> CSS.AnimBuilder
fadeInBuilder =
    Opacity.for "my-box"
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.duration 2500
        >> Opacity.easing CubicIn
        >> Opacity.build



-- --8<-- [end:fadeIn]
-- VIEW


view : Model -> Html Msg
view model =
    -- --8<-- [start:fireAndForget]
    let
        animState =
            case model.state of
                Ready ->
                    CSS.init
                        [ Opacity.init "my-box" 0 ]

                FadeIn ->
                    CSS.fireAndForget fadeInBuilder
    in
    -- --8<-- [end:fireAndForget]
    -- --8<-- [start:applyStyles]
    div
        ([ style "width" "100px"
         , style "height" "100px"
         , style "background-color" "blue"
         ]
            ++ CSS.transitionAttributes "my-box" animState
        )
        []



-- --8<-- [end:applyStyles]
