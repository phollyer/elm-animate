module Engines.Transition.InterruptingAnimations.SingleProperty.Main exposing (main)

import Anim.Engine.CSS.Transition as Transition
import Anim.Extra.Color as Color exposing (Color)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.BackgroundColor as BgColor
import Browser
import Html exposing (Html, div, text)
import Html.Attributes
import Html.Events



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
                [ BgColor.init animGroupName <|
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


toColor1 : Transition.AnimBuilder -> Transition.AnimBuilder
toColor1 =
    colorBox (BgColor.to color1)


toColor2 : Transition.AnimBuilder -> Transition.AnimBuilder
toColor2 =
    colorBox (BgColor.to color2)


toColor3 : Transition.AnimBuilder -> Transition.AnimBuilder
toColor3 =
    colorBox (BgColor.to color3)


toColor4 : Transition.AnimBuilder -> Transition.AnimBuilder
toColor4 =
    colorBox (BgColor.to color4)


colorBox : (BgColor.Builder -> BgColor.Builder) -> (Transition.AnimBuilder -> Transition.AnimBuilder)
colorBox moveFunc =
    BgColor.for animGroupName
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
        button bgColor label onClick =
            div
                [ Html.Events.onClick onClick
                , Html.Attributes.style "display" "inline-block"
                , Html.Attributes.style "margin-left" "10px"
                , Html.Attributes.style "margin-right" "10px"
                , Html.Attributes.style "padding" "10px"
                , Html.Attributes.style "background-color" <|
                    Color.toHex bgColor
                , Html.Attributes.style "color" "white"
                , Html.Attributes.style "cursor" "pointer"
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
        [ Html.Attributes.style "text-align" "center"
        ]
        [ color1Button
        , color2Button
        , color3Button
        , color4Button
        , div
            (Transition.attributes animGroupName model.animState
                ++ [ Html.Attributes.style "width" "calc(100vw - 20px)"
                   , Html.Attributes.style "height" "calc(100vh - 75px)"
                   , Html.Attributes.style "margin-top" "20px"
                   ]
            )
            []
        ]
