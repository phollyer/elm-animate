module Engines.Transitions.DiscreteProperties.Main exposing (main)

import Anim.Engine.CSS.Transition as Transitions exposing (AnimBuilder)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, button, div, p, text)
import Html.Attributes exposing (style)
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
    { animState : Transitions.AnimState
    }


init : ( Model, Cmd Msg )
init =
    ( { animState = Transitions.init [ Opacity.init animGroup 1 ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "boxAnim"


fadeIn : AnimBuilder -> AnimBuilder
fadeIn =
    Transitions.discreteEntry "display" "flex"
        >> Opacity.for animGroup
        >> Opacity.to 1
        >> Opacity.duration 800
        >> Opacity.easing Linear
        >> Opacity.build


fadeOut : AnimBuilder -> AnimBuilder
fadeOut =
    Transitions.discreteExit "display" "flex" "none"
        >> Opacity.for animGroup
        >> Opacity.to 0
        >> Opacity.duration 800
        >> Opacity.easing Linear
        >> Opacity.build



-- UPDATE


type Msg
    = Show
    | Hide
    | GotAnimMsg Transitions.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Show ->
            ( { model
                | animState = Transitions.animate model.animState fadeIn
              }
            , Cmd.none
            )

        Hide ->
            ( { model
                | animState = Transitions.animate model.animState fadeOut
              }
            , Cmd.none
            )

        GotAnimMsg animMsg ->
            let
                ( newAnimState, _ ) =
                    Transitions.update animMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "text-align" "center"
        , style "padding-top" "20px"
        , style "font-family" "sans-serif"
        ]
        [ Transitions.startingStyleNode model.animState
        , div
            [ style "display" "flex"
            , style "gap" "10px"
            , style "justify-content" "center"
            , style "margin-bottom" "20px"
            ]
            [ button
                [ onClick Show
                , style "padding" "8px 16px"
                , style "font-size" "14px"
                ]
                [ text "Show" ]
            , button
                [ onClick Hide
                , style "padding" "8px 16px"
                , style "font-size" "14px"
                ]
                [ text "Hide" ]
            ]
        , p
            [ style "color" "#666"
            , style "font-size" "13px"
            , style "margin-bottom" "20px"
            ]
            [ text "The box uses discreteEntry and discreteExit for discrete CSS transitions." ]
        , div
            [ style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "height" "300px"
            ]
            [ div
                (Transitions.attributes animGroup model.animState
                    ++ Transitions.events GotAnimMsg
                    ++ [ style "display" "flex"
                       , style "width" "200px"
                       , style "height" "200px"
                       , style "background-color" "#4a90d9"
                       , style "border-radius" "12px"
                       , style "align-items" "center"
                       , style "justify-content" "center"
                       , style "color" "white"
                       , style "font-size" "18px"
                       , style "font-weight" "bold"
                       ]
                )
                [ text "Hello!" ]
            ]
        ]
