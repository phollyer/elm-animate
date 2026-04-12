module Engines.Sub.DiscreteProperties.Main exposing (main)

import Anim.Engine.Sub as Sub exposing (AnimBuilder)
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
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : Sub.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Sub.init
                [ Sub.discreteEntry "display" "flex"
                    >> Opacity.init animGroup 1
                ]
      }
    , Cmd.none
    )



-- ANIMATION


animGroup : String
animGroup =
    "boxAnim"


fadeIn : AnimBuilder -> AnimBuilder
fadeIn =
    Sub.discreteEntry "display" "flex"
        >> Opacity.for animGroup
        >> Opacity.to 1
        >> Opacity.duration 800
        >> Opacity.easing Linear
        >> Opacity.build


fadeOut : AnimBuilder -> AnimBuilder
fadeOut =
    Sub.discreteExit "display" "flex" "none"
        >> Opacity.for animGroup
        >> Opacity.to 0
        >> Opacity.duration 800
        >> Opacity.easing Linear
        >> Opacity.build



-- UPDATE


type Msg
    = Show
    | Hide
    | GotSubMsg Sub.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Show ->
            ( { model
                | animState = Sub.animate model.animState fadeIn
              }
            , Cmd.none
            )

        Hide ->
            ( { model
                | animState = Sub.animate model.animState fadeOut
              }
            , Cmd.none
            )

        GotSubMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    Sub.update subMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "text-align" "center"
        , style "padding-top" "20px"
        , style "font-family" "sans-serif"
        ]
        [ div
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
            [ text "Uses discreteEntry/discreteExit to flip display on first/last frames." ]
        , div
            [ style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "height" "300px"
            ]
            [ div
                (Sub.attributes animGroup model.animState
                    ++ [ style "width" "200px"
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
