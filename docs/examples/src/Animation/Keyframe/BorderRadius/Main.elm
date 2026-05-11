module Animation.Keyframe.BorderRadius.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Property.Custom as Property
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
                [ Property.init animGroup (Property.BorderRadius "px") 0 ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "boxAnim"


roundCorners : AnimBuilder mode -> AnimBuilder mode
roundCorners =
    Property.for animGroup (Property.BorderRadius "px")
        >> Property.to 48
        >> Property.duration 800
        >> Property.easing CubicInOut
        >> Property.build


squareCorners : AnimBuilder mode -> AnimBuilder mode
squareCorners =
    Property.for animGroup (Property.BorderRadius "px")
        >> Property.to 0
        >> Property.duration 800
        >> Property.easing CubicInOut
        >> Property.build



-- UPDATE


type Msg
    = TriggerRound
    | TriggerSquare


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerRound ->
            ( { model | animState = Keyframe.animate model.animState roundCorners }
            , Cmd.none
            )

        TriggerSquare ->
            ( { model | animState = Keyframe.animate model.animState squareCorners }
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
        , div [ class "example-controls" ]
            [ button
                [ onClick TriggerRound
                , class "ui-action-button primary"
                ]
                [ text "Round" ]
            , button
                [ onClick TriggerSquare
                , class "ui-action-button primary"
                ]
                [ text "Square" ]
            ]
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
                       , style "background-color" "#6366f1"
                       ]
                )
                []
            ]
        ]
