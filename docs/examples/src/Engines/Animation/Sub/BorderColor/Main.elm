module Engines.Animation.Sub.BorderColor.Main exposing (main)

import Anim.Engine.Sub as Sub exposing (AnimBuilder)
import Anim.Extra.Color as Color
import Anim.PropertyColor as PropertyColor
import Browser
import Easing exposing (Easing(..))
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : Sub.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Sub.init <|
                [ PropertyColor.init animGroup
                    "border-color"
                    (Color.rgb 99 102 241)
                ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "boxAnim"


toRed : AnimBuilder -> AnimBuilder
toRed =
    PropertyColor.for animGroup "border-color"
        >> PropertyColor.to (Color.rgb 239 68 68)
        >> PropertyColor.duration 800
        >> PropertyColor.easing CubicInOut
        >> PropertyColor.build


toBlue : AnimBuilder -> AnimBuilder
toBlue =
    PropertyColor.for animGroup "border-color"
        >> PropertyColor.to (Color.rgb 59 130 246)
        >> PropertyColor.duration 800
        >> PropertyColor.easing CubicInOut
        >> PropertyColor.build



-- UPDATE


type Msg
    = GotSubMsg Sub.AnimMsg
    | TriggerRed
    | TriggerBlue


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSubMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    Sub.update subMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        TriggerRed ->
            ( { model | animState = Sub.animate model.animState toRed }
            , Cmd.none
            )

        TriggerBlue ->
            ( { model | animState = Sub.animate model.animState toBlue }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "text-align" "center"
        , style "height" "90vh"
        , style "width" "100%"
        , style "padding-top" "10px"
        ]
        [ button
            [ onClick TriggerRed
            , class "ui-action-button primary"
            , style "margin-right" "10px"
            ]
            [ text "Red Border" ]
        , button
            [ onClick TriggerBlue
            , class "ui-action-button primary"
            ]
            [ text "Blue Border" ]
        , div
            [ style "height" "80vh"
            , style "width" "100%"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "padding-top" "10px"
            ]
            [ div
                (Sub.attributes animGroup model.animState
                    ++ [ style "height" "200px"
                       , style "width" "200px"
                       , style "background-color" "#f8fafc"
                       , style "border" "4px solid #6366f1"
                       , style "border-radius" "8px"
                       ]
                )
                []
            ]
        ]
