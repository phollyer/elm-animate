port module Animation.WAAPI.FadeInOut.Main exposing (main)

import Anim.Engine.WAAPI as WAAPI exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Browser
import Easing exposing (Easing(..))
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode



-- PORTS


port waapiCommand : Encode.Value -> Cmd msg


port waapiEvent : (Encode.Value -> msg) -> Sub msg



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
            WAAPI.init waapiCommand waapiEvent <|
                [ Opacity.init animGroup 0 ]
      }
    , Cmd.none
    )



---8<-- [end:model]
---8<-- [start:build]


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
        [ style "text-align" "center"
        , style "height" "90vh"
        , style "width" "100%"
        , style "align" "center"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "padding-top" "10px"
        ]
        [ button
            [ onClick TriggerFadeIn
            , class "ui-action-button primary"
            , style "margin-right" "10px"
            ]
            [ text "Fade In" ]
        , button
            [ onClick TriggerFadeOut
            , class "ui-action-button primary"
            ]
            [ text "Fade Out" ]
        , div
            [ style "height" "80vh"
            , style "width" "100%"
            , style "display" "flex"
            , style "align" "center"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "padding-top" "10px"
            ]
            ---8<-- [start:render]
            [ div
                (WAAPI.attributes animGroup model.animState
                    ++ [ style "height" "80vh"
                       , style "width" "80vw"
                       , style "margin" "0 auto"
                       , style "background-color" "red"
                       ]
                )
                []
            ]

        ---8<-- [end:render]
        ]
