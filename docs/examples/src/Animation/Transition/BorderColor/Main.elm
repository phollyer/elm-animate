module Animation.Transition.BorderColor.Main exposing (main)

import Anim.Engine.Transition as Transition exposing (EngineBuilder)
import Anim.Extra.Color as Color
import Anim.Property.CustomColor as CustomColor
import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Motion.Easing as Easing exposing (Easing(..))



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


type alias Model =
    { animState : Transition.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Transition.init
                [ CustomColor.init animGroup
                    CustomColor.BorderColor
                    (Color.rgb 99 102 241)
                ]
      }
    , Cmd.none
    )



-- ANIMATION
---8<-- [start:build]


animGroup : String
animGroup =
    "boxAnim"


toRed : EngineBuilder -> EngineBuilder
toRed =
    CustomColor.for animGroup CustomColor.BorderColor
        >> CustomColor.to (Color.rgb 239 68 68)
        >> CustomColor.duration 800
        >> CustomColor.easing CubicInOut
        >> CustomColor.build


toBlue : EngineBuilder -> EngineBuilder
toBlue =
    CustomColor.for animGroup CustomColor.BorderColor
        >> CustomColor.to (Color.rgb 59 130 246)
        >> CustomColor.duration 800
        >> CustomColor.easing CubicInOut
        >> CustomColor.build



---8<-- [end:build]
-- UPDATE


type Msg
    = TriggerRed
    | TriggerBlue


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerRed ->
            ( { model | animState = Transition.animate model.animState toRed }
            , Cmd.none
            )

        TriggerBlue ->
            ( { model | animState = Transition.animate model.animState toBlue }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "example-stage"
        , style "text-align" "center"
        ]
        [ div [ class "example-controls" ]
            [ button
                [ onClick TriggerRed
                , class "ui-action-button primary"
                ]
                [ text "Red Border" ]
            , button
                [ onClick TriggerBlue
                , class "ui-action-button primary"
                ]
                [ text "Blue Border" ]
            ]
        , div
            [ style "width" "100%"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "padding-top" "10px"
            ]
            [ div
                (Transition.attributes animGroup model.animState
                    ++ [ class "example-box"
                       , style "background-color" "#f8fafc"
                       , style "border" "4px solid #6366f1"
                       , style "border-radius" "8px"
                       ]
                )
                []
            ]
        ]
