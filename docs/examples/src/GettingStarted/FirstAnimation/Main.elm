module GettingStarted.FirstAnimation.Main exposing (main)

import Anim.Engine.CSS.Transitions as Transitions exposing (AnimBuilder)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (id, style)
import Html.Events exposing (onClick)



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
    | FadeOut


type alias Model =
    { state : State }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { state = Ready }
    , Cmd.none
    )



-- UPDATE


type Msg
    = TriggerFadeIn
    | TriggerFadeOut


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerFadeIn ->
            ( { model | state = FadeIn }, Cmd.none )

        TriggerFadeOut ->
            ( { model | state = FadeOut }, Cmd.none )



-- ANIMATION BUILDER
-- --8<-- [start:fadeIn]


animGroup : String
animGroup =
    "boxAnim"


fade : Float -> Float -> AnimBuilder -> AnimBuilder
fade from to =
    Opacity.for animGroup
        >> Opacity.from from
        >> Opacity.to to
        >> Opacity.duration 2500
        >> Opacity.easing CubicInOut
        >> Opacity.build


fadeIn : AnimBuilder -> AnimBuilder
fadeIn =
    fade 0 1


fadeOut : AnimBuilder -> AnimBuilder
fadeOut =
    fade 1 0



-- --8<-- [end:fadeIn]
-- VIEW


view : Model -> Html Msg
view model =
    -- --8<-- [start:fireAndForget]
    let
        animState =
            case model.state of
                Ready ->
                    Transitions.init
                        [ Opacity.init animGroup 0 ]

                FadeIn ->
                    Transitions.fireAndForget fadeIn

                FadeOut ->
                    Transitions.fireAndForget fadeOut
    in
    -- --8<-- [end:fireAndForget]
    div
        []
        [ button [ onClick TriggerFadeIn ] [ text "Fade In" ]
        , button [ onClick TriggerFadeOut ] [ text "Fade Out" ]
        , -- --8<-- [start:applyStyles]
          div
            (Transitions.attributes animGroup animState
                ++ [ style "width" "100px"
                   , style "height" "100px"
                   , style "background-color" "blue"
                   ]
            )
            []

        -- --8<-- [end:applyStyles]
        ]
