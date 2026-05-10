port module Animation.WAAPI.FadeInOut.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))



-- PORTS


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



---8<-- [start:model]


type alias Model =
    { animState : WAAPI.AnimState Msg }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            WAAPI.init motionCmd motionMsg <|
                [ Opacity.init animGroup 0 ]
      }
    , Cmd.none
    )



---8<-- [end:model]
---8<-- [start:build]


animGroup : String
animGroup =
    "boxAnim"


fadeTo : Float -> AnimBuilder mode -> AnimBuilder mode
fadeTo to =
    Opacity.for animGroup
        >> Opacity.to to
        >> Opacity.duration 2500
        >> Opacity.easing CubicInOut
        >> Opacity.build


fadeIn : AnimBuilder mode -> AnimBuilder mode
fadeIn =
    fadeTo 1


fadeOut : AnimBuilder mode -> AnimBuilder mode
fadeOut =
    fadeTo 0



---8<-- [end:build]
--8<-- [start:Msg]


type Msg
    = GotWaapiMsg WAAPI.AnimMsg
      ---8<-- [end:Msg]
    | TriggerFadeIn
    | TriggerFadeOut



--8<-- [start:update]


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

        ---8<-- [end:update]
        ---8<-- [start:trigger]
        TriggerFadeIn ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState fadeIn
            in
            ( { model | animState = newAnimState }
            , cmd
            )

        TriggerFadeOut ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState fadeOut
            in
            ( { model | animState = newAnimState }
            , cmd
            )



---8<-- [end:trigger]
---8<-- [start:subscriptions]


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



---8<-- [end:subscriptions]
-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "example-stage"
        ]
        [ div
            [ class "ui-wrapped-row" ]
            [ button
                [ onClick TriggerFadeIn
                , class "ui-action-button primary"
                ]
                [ text "Fade In" ]
            , button
                [ onClick TriggerFadeOut
                , class "ui-action-button primary"
                ]
                [ text "Fade Out" ]
            ]
        , ---8<-- [start:render]
          div
            (WAAPI.attributes animGroup model.animState
                ++ [ class "example-square"
                   , style "background-color" "red"
                   ]
            )
            []

        ---8<-- [end:render]
        ]
