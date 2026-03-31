module Engines.Keyframes.FadeInOut.Main exposing (main)

import Anim.Engine.CSS.Keyframe as Keyframes exposing (AnimBuilder)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.Opacity as Opacity
import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (id, style)
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
---8<-- [start:model]


type alias Model =
    { animState : Keyframes.AnimState }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Keyframes.init <|
                [ Opacity.init animGroup 0 ]
      }
    , Cmd.none
    )



---8<-- [end:model]
-- ANIMATION
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
-- UPDATE


type Msg
    = TriggerFadeIn
    | TriggerFadeOut


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:trigger]
        TriggerFadeIn ->
            ( { model | animState = Keyframes.animate model.animState fadeIn }
            , Cmd.none
            )

        TriggerFadeOut ->
            ( { model | animState = Keyframes.animate model.animState fadeOut }
            , Cmd.none
            )



---8<-- [end:trigger]
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
        [ Keyframes.styleNode model.animState
        , button [ onClick TriggerFadeIn ] [ text "Fade In" ]
        , button [ onClick TriggerFadeOut ] [ text "Fade Out" ]
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
                (Keyframes.attributes animGroup model.animState
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
