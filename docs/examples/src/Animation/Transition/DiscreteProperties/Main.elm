module Animation.Transition.DiscreteProperties.Main exposing (main)

import Anim.Engine.Transition as Transition exposing (AnimBuilder)
import Anim.Property.Opacity as Opacity
import Browser
import Easing exposing (Easing(..))
import Html exposing (Html, button, div, p, text)
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
    { animState : Transition.AnimState
    }


init : ( Model, Cmd Msg )
init =
    ( { animState = Transition.init [ Opacity.init animGroup 1 ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "boxAnim"


fadeIn : AnimBuilder -> AnimBuilder
fadeIn =
    Transition.discreteEntry "display" "flex"
        >> Opacity.for animGroup
        >> Opacity.to 1
        >> Opacity.duration 800
        >> Opacity.easing QuartIn
        >> Opacity.build


fadeOut : AnimBuilder -> AnimBuilder
fadeOut =
    Transition.discreteExit "display" "flex" "none"
        >> Opacity.for animGroup
        >> Opacity.to 0
        >> Opacity.duration 800
        >> Opacity.easing CubicIn
        >> Opacity.build



-- UPDATE


type Msg
    = Show
    | Hide
    | GotAnimMsg Transition.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Show ->
            ( { model
                | animState = Transition.animate model.animState fadeIn
              }
            , Cmd.none
            )

        Hide ->
            ( { model
                | animState = Transition.animate model.animState fadeOut
              }
            , Cmd.none
            )

        GotAnimMsg animMsg ->
            let
                ( newAnimState, _ ) =
                    Transition.update animMsg model.animState
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
        [ Transition.startingStyleNode model.animState
        , div
            [ style "display" "flex"
            , style "gap" "10px"
            , style "justify-content" "center"
            , style "margin-bottom" "20px"
            ]
            [ button
                [ onClick Show
                , class "ui-action-button primary"
                , style "padding" "8px 16px"
                , style "font-size" "14px"
                , style "margin-right" "10px"
                ]
                [ text "Show" ]
            , button
                [ onClick Hide
                , class "ui-action-button primary"
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
            [ text "Uses discreteEntry/discreteExit to flip display on first/last frames." ]
        , div
            [ style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "height" "220px"
            ]
            [ div
                (Transition.attributes animGroup model.animState
                    ++ Transition.events GotAnimMsg
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
