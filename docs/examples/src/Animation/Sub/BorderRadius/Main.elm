module Animation.Sub.BorderRadius.Main exposing (main)

import Anim.Engine.Sub as Sub exposing (AnimBuilder)
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
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : Sub.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Sub.init <|
                [ Property.init animGroup (Property.BorderRadius "px") 0 ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "boxAnim"


roundCorners : AnimBuilder -> AnimBuilder
roundCorners =
    Property.for animGroup (Property.BorderRadius "px")
        >> Property.to 48
        >> Property.duration 800
        >> Property.easing CubicInOut
        >> Property.build


squareCorners : AnimBuilder -> AnimBuilder
squareCorners =
    Property.for animGroup (Property.BorderRadius "px")
        >> Property.to 0
        >> Property.duration 800
        >> Property.easing CubicInOut
        >> Property.build



-- UPDATE


type Msg
    = GotSubMsg Sub.AnimMsg
    | TriggerRound
    | TriggerSquare


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

        TriggerRound ->
            ( { model | animState = Sub.animate model.animState roundCorners }
            , Cmd.none
            )

        TriggerSquare ->
            ( { model | animState = Sub.animate model.animState squareCorners }
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
                (Sub.attributes animGroup model.animState
                    ++ [ style "height" "200px"
                       , style "width" "200px"
                       , style "background-color" "#6366f1"
                       ]
                )
                []
            ]
        ]
