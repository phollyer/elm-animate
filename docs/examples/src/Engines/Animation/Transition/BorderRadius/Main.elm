module Engines.Animation.Transition.BorderRadius.Main exposing (main)

import Anim.Engine.CSS.Transition as Transition exposing (AnimBuilder)
import Anim.Property.Custom as Property
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
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    { animState : Transition.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Transition.init
                [ Property.init animGroup (BorderRadius "px") 0 ]
      }
    , Cmd.none
    )



-- ANIMATION
---8<-- [start:build]


animGroup : String
animGroup =
    "boxAnim"


roundCorners : AnimBuilder -> AnimBuilder
roundCorners =
    Property.for animGroup (BorderRadius "px")
        >> Property.to 48
        >> Property.duration 800
        >> Property.easing CubicInOut
        >> Property.build


squareCorners : AnimBuilder -> AnimBuilder
squareCorners =
    Property.for animGroup (BorderRadius "px")
        >> Property.to 0
        >> Property.duration 800
        >> Property.easing CubicInOut
        >> Property.build



---8<-- [end:build]
-- UPDATE


type Msg
    = TriggerRound
    | TriggerSquare


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TriggerRound ->
            ( { model | animState = Transition.animate model.animState roundCorners }
            , Cmd.none
            )

        TriggerSquare ->
            ( { model | animState = Transition.animate model.animState squareCorners }
            , Cmd.none
            )



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
            [ onClick TriggerRound
            , class "ui-action-button primary"
            , style "margin-right" "10px"
            ]
            [ text "Round" ]
        , button
            [ onClick TriggerSquare
            , class "ui-action-button primary"
            ]
            [ text "Square" ]
        , div
            [ style "height" "80vh"
            , style "width" "100%"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "padding-top" "10px"
            ]
            [ div
                (Transition.attributes animGroup model.animState
                    ++ [ style "height" "200px"
                       , style "width" "200px"
                       , style "background-color" "#6366f1"
                       ]
                )
                []
            ]
        ]
