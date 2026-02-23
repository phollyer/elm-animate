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



-- ANIMATION BUILDER
-- --8<-- [start:fadeIn]


animGroup : String
animGroup =
    "boxAnim"


fadeTo : Float -> AnimBuilder -> AnimBuilder
fadeTo to =
    Opacity.for animGroup
        >> Opacity.to to
        >> Opacity.duration 2500
        >> Opacity.easing CubicInOut
        >> Opacity.build


fadeIn : AnimBuilder -> AnimBuilder
fadeIn =
    fadeTo 1


fadeOut : AnimBuilder -> AnimBuilder
fadeOut =
    fadeTo 0



-- --8<-- [end:fadeIn]
-- MODEL


type alias Model =
    { animState : Transitions.AnimState }



-- --8<-- [start:initAnimationState]


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState = Transitions.init [ Opacity.init animGroup 0 ] }
    , Cmd.none
    )



-- --8<-- [end:initAnimationState]
-- UPDATE


type Msg
    = TriggerFadeIn
    | TriggerFadeOut



-- --8<-- [start:triggerAnimation]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerFadeIn ->
            ( { model | animState = Transitions.fireAndForget fadeIn }, Cmd.none )

        TriggerFadeOut ->
            ( { model | animState = Transitions.fireAndForget fadeOut }, Cmd.none )



-- --8<-- [end:triggerAnimation]
-- VIEW


view : Model -> Html Msg
view model =
    div
        []
        [ button [ onClick TriggerFadeIn ] [ text "Fade In" ]
        , button [ onClick TriggerFadeOut ] [ text "Fade Out" ]
        , -- --8<-- [start:applyStyles]
          div
            (Transitions.attributes animGroup model.animState
                ++ [ style "width" "100px"
                   , style "height" "100px"
                   , style "background-color" "blue"
                   ]
            )
            []

        -- --8<-- [end:applyStyles]
        ]
