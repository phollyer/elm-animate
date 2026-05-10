module Animation.Transition.InterruptingAnimations.SingleProperty.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Transition as Transition
import Anim.Extra.Color as Color exposing (Color)
import Anim.Property.CustomColor as BgColor
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Motion.Easing as Easing exposing (Easing(..))



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = always init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }



-- MODEL


animGroupName : String
animGroupName =
    "movingBox"


type alias Model =
    { animState : Transition.AnimState
    }


init : ( Model, Cmd Msg )
init =
    ( { animState =
            Transition.init
                [ BgColor.init animGroupName BgColor.BackgroundColor <|
                    Color.rgb 118 118 118
                ]
      }
    , Cmd.none
    )



-- ANIMATIONS


color1 : Color
color1 =
    Color.rgb 255 87 51


color2 : Color
color2 =
    Color.rgb 40 167 69


color3 : Color
color3 =
    Color.rgb 111 66 193


color4 : Color
color4 =
    Color.rgb 255 193 7


toColor1 : AnimBuilder mode -> AnimBuilder mode
toColor1 =
    colorBox (BgColor.to color1)


toColor2 : AnimBuilder mode -> AnimBuilder mode
toColor2 =
    colorBox (BgColor.to color2)


toColor3 : AnimBuilder mode -> AnimBuilder mode
toColor3 =
    colorBox (BgColor.to color3)


toColor4 : AnimBuilder mode -> AnimBuilder mode
toColor4 =
    colorBox (BgColor.to color4)


colorBox : (BgColor.Builder mode -> BgColor.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
colorBox moveFunc =
    BgColor.for animGroupName BgColor.BackgroundColor
        >> moveFunc
        >> BgColor.duration 3000
        >> BgColor.easing Linear
        >> BgColor.build



-- UPDATE


type Msg
    = GotAnimationUpdate Transition.AnimMsg
    | Color1
    | Color2
    | Color3
    | Color4


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimationUpdate animationMsg ->
            let
                ( newAnimState, _ ) =
                    Transition.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        Color1 ->
            ( { model | animState = Transition.animate model.animState toColor1 }
            , Cmd.none
            )

        Color2 ->
            ( { model | animState = Transition.animate model.animState toColor2 }
            , Cmd.none
            )

        Color3 ->
            ( { model | animState = Transition.animate model.animState toColor3 }
            , Cmd.none
            )

        Color4 ->
            ( { model | animState = Transition.animate model.animState toColor4 }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    let
        button bgColor label onClickMsg =
            div
                [ onClick onClickMsg
                , class "ui-action-button"
                , style "display" "inline-block"
                , style "margin-left" "10px"
                , style "margin-right" "10px"
                , style "padding" "10px"
                , style "background-color" <|
                    Color.toHex bgColor
                , style "color" "white"
                , style "cursor" "pointer"
                ]
                [ text label ]

        color1Button =
            button color1 "Color 1" Color1

        color2Button =
            button color2 "Color 2" Color2

        color3Button =
            button color3 "Color 3" Color3

        color4Button =
            button color4 "Color 4" Color4
    in
    div
        [ style "text-align" "center"
        ]
        [ color1Button
        , color2Button
        , color3Button
        , color4Button
        , div
            (Transition.attributes animGroupName model.animState
                ++ [ style "width" "calc(100vw - 20px)"
                   , style "height" "calc(100vh - 75px)"
                   , style "margin-top" "20px"
                   , style "margin-left" "auto"
                   , style "margin-right" "auto"
                   ]
            )
            []
        ]
