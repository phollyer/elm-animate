module Animation.Keyframe.BorderColor.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
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
    { animState : Keyframe.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Keyframe.init <|
                [ CustomColor.init animGroup
                    CustomColor.BorderColor
                    (Color.rgb 99 102 241)
                ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "boxAnim"


toRed : AnimBuilder mode -> AnimBuilder mode
toRed =
    CustomColor.for animGroup CustomColor.BorderColor
        >> CustomColor.to (Color.rgb 239 68 68)
        >> CustomColor.duration 800
        >> CustomColor.easing CubicInOut
        >> CustomColor.build


toBlue : AnimBuilder mode -> AnimBuilder mode
toBlue =
    CustomColor.for animGroup CustomColor.BorderColor
        >> CustomColor.to (Color.rgb 59 130 246)
        >> CustomColor.duration 800
        >> CustomColor.easing CubicInOut
        >> CustomColor.build



-- UPDATE


type Msg
    = TriggerRed
    | TriggerBlue


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerRed ->
            ( { model | animState = Keyframe.animate model.animState toRed }
            , Cmd.none
            )

        TriggerBlue ->
            ( { model | animState = Keyframe.animate model.animState toBlue }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "example-stage"
        , style "text-align" "center"
        ]
        [ Keyframe.styleNode model.animState
        , button
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
            [ style "width" "100%"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "padding-top" "10px"
            ]
            [ div
                (Keyframe.attributes animGroup model.animState
                    ++ [ class "example-box"
                       , style "background-color" "#f8fafc"
                       , style "border" "4px solid #6366f1"
                       , style "border-radius" "8px"
                       ]
                )
                []
            ]
        ]
