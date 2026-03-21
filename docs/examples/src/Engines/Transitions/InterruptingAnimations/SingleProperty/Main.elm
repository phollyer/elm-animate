module Engines.Transitions.InterruptingAnimations.SingleProperty.Main exposing (main)

import Anim.Engine.CSS.Transitions as Transitions
import Anim.Extra.Color as Color exposing (Color)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.BackgroundColor as BgColor
import Browser
import Html exposing (Html, div, text)
import Html.Attributes
import Html.Events



-- MAIN


main : Program { width : Float, height : Float } Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }



-- MODEL


animGroupName : String
animGroupName =
    "movingBox"


type alias Model =
    { animState : Transitions.AnimState
    , width : Float
    , height : Float
    }


init : { width : Float, height : Float } -> ( Model, Cmd Msg )
init { width, height } =
    let
        w =
            width - 20

        h =
            height - 75
    in
    ( { animState =
            Transitions.init
                [ BgColor.init animGroupName <|
                    Color.rgb 118 118 118
                ]
      , width = w
      , height = h
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


toColor1 : Transitions.AnimBuilder -> Transitions.AnimBuilder
toColor1 =
    colorBox (BgColor.to color1)


toColor2 : Transitions.AnimBuilder -> Transitions.AnimBuilder
toColor2 =
    colorBox (BgColor.to color2)


toColor3 : Transitions.AnimBuilder -> Transitions.AnimBuilder
toColor3 =
    colorBox (BgColor.to color3)


toColor4 : Transitions.AnimBuilder -> Transitions.AnimBuilder
toColor4 =
    colorBox (BgColor.to color4)


colorBox : (BgColor.Builder -> BgColor.Builder) -> (Transitions.AnimBuilder -> Transitions.AnimBuilder)
colorBox moveFunc =
    BgColor.for animGroupName
        >> moveFunc
        >> BgColor.duration 3000
        >> BgColor.easing Linear
        >> BgColor.build



-- UPDATE


type Msg
    = GotAnimationUpdate Transitions.AnimMsg
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
                    Transitions.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        Color1 ->
            ( { model | animState = Transitions.animate model.animState toColor1 }
            , Cmd.none
            )

        Color2 ->
            ( { model | animState = Transitions.animate model.animState toColor2 }
            , Cmd.none
            )

        Color3 ->
            ( { model | animState = Transitions.animate model.animState toColor3 }
            , Cmd.none
            )

        Color4 ->
            ( { model | animState = Transitions.animate model.animState toColor4 }
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
            (Transitions.attributes animGroupName model.animState
                ++ [ Html.Attributes.style "width" (String.fromFloat model.width ++ "px")
                   , Html.Attributes.style "height" (String.fromFloat model.height ++ "px")
                   , Html.Attributes.style "margin-top" "20px"
                   ]
            )
            []
        ]
