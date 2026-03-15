port module Engines.WAAPI.FadeInOut.Main exposing (main)

import Anim.Engine.WAAPI as WAAPI exposing (AnimBuilder)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (id, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode



-- PORTS


port waapiCommand : Encode.Value -> Cmd msg


port waapiEvent : (Encode.Value -> msg) -> Sub msg



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- ANIMATION BUILDER
---8<-- [start:fadeIn]


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



---8<-- [end:fadeIn]
-- MODEL


type alias Model =
    { animState : WAAPI.AnimState Msg }



---8<-- [start:initAnimationState]


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            WAAPI.init waapiCommand waapiEvent <|
                [ Opacity.init animGroup 0 ]
      }
    , Cmd.none
    )



---8<-- [end:initAnimationState]
-- UPDATE


type Msg
    = GotWaapiMsg WAAPI.AnimMsg
    | TriggerFadeIn
    | TriggerFadeOut


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotWaapiMsg waapiMsg ->
            let
                ( newAnimState, _ ) =
                    WAAPI.update waapiMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        ---8<-- [start:triggerAnimation]
        TriggerFadeIn ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState fadeIn
            in
            ( { model | animState = newAnimState }, cmd )

        TriggerFadeOut ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState fadeOut
            in
            ( { model | animState = newAnimState }, cmd )



---8<-- [end:triggerAnimation]
-- WAAPISCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "text-align" "center" ]
        [ button [ onClick TriggerFadeIn ] [ text "Fade In" ]
        , button [ onClick TriggerFadeOut ] [ text "Fade Out" ]
        , ---8<-- [start:applyStyles]
          div
            (WAAPI.attributes animGroup model.animState
                ++ [ style "width" "100px"
                   , style "height" "100px"
                   , style "background-color" "blue"
                   ]
            )
            []

        ---8<-- [end:applyStyles]
        ]
