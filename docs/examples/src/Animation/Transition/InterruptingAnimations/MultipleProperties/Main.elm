module Animation.Transition.InterruptingAnimations.MultipleProperties.Main exposing (..)

import Anim.Engine.Transition as Transition
import Anim.Extra.Color as Color exposing (Color)
import Anim.Property.CustomColor as BgColor
import Anim.Property.Translate as Translate
import Browser
import Easing exposing (Easing(..))
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)



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


type alias Model =
    { animState : Transition.AnimState
    , width : Float
    , height : Float
    }


animGroupName : String
animGroupName =
    "movingBox"


boxWidth : Float
boxWidth =
    100


init : { width : Float, height : Float } -> ( Model, Cmd Msg )
init { width, height } =
    let
        w =
            width - 20

        h =
            height - 75
    in
    ( { animState =
            Transition.init
                [ Translate.initXY animGroupName ((w - boxWidth) / 2) ((h - boxWidth) / 2)
                , BgColor.init animGroupName BgColor.BackgroundColor <| Color.rgb 118 118 118
                ]
      , width = w
      , height = h
      }
    , Cmd.none
    )



-- COLORS


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



-- ANIMATIONS


moveBox : (Translate.Builder {} -> Translate.Builder {}) -> Transition.AnimBuilder -> Transition.AnimBuilder
moveBox moveFunc =
    Translate.for animGroupName
        >> moveFunc
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.build


changeColor : Color -> Transition.AnimBuilder -> Transition.AnimBuilder
changeColor color =
    BgColor.for animGroupName BgColor.BackgroundColor
        >> BgColor.to color
        >> BgColor.duration 3000
        >> BgColor.easing Linear
        >> BgColor.build



-- UPDATE


type Msg
    = GotAnimationUpdate Transition.AnimMsg
    | MoveLeft
    | MoveRight
    | ChangeColor Color


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

        MoveLeft ->
            ( { model
                | animState =
                    Transition.animate model.animState <|
                        moveBox (Translate.toX 0)
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | animState =
                    Transition.animate model.animState <|
                        moveBox (Translate.toX (model.width - boxWidth))
              }
            , Cmd.none
            )

        ChangeColor color ->
            ( { model
                | animState =
                    Transition.animate model.animState <|
                        changeColor color
              }
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    let
        posButton bgColor label onClickMsg =
            div
                [ onClick onClickMsg
                , class "ui-action-button"
                , style "display" "inline-block"
                , style "margin-left" "10px"
                , style "margin-right" "10px"
                , style "padding" "10px"
                , style "background-color" bgColor
                , style "color" "white"
                , style "cursor" "pointer"
                ]
                [ text label ]

        colorButton color label =
            div
                [ onClick (ChangeColor color)
                , class "ui-action-button"
                , style "display" "inline-block"
                , style "margin-left" "10px"
                , style "margin-right" "10px"
                , style "padding" "10px"
                , style "background-color" (Color.toHex color)
                , style "color" "white"
                , style "cursor" "pointer"
                ]
                [ text label ]
    in
    div [ style "text-align" "center" ]
        [ div [ style "margin-bottom" "10px" ]
            [ posButton "#333" "Move Left" MoveLeft
            , posButton "#333" "Move Right" MoveRight
            ]
        , div []
            [ colorButton color1 "Color 1"
            , colorButton color2 "Color 2"
            , colorButton color3 "Color 3"
            , colorButton color4 "Color 4"
            ]
        , div
            (Transition.attributes animGroupName model.animState
                ++ Transition.events GotAnimationUpdate
                ++ [ style "width" (String.fromFloat boxWidth ++ "px")
                   , style "height" (String.fromFloat boxWidth ++ "px")
                   , style "position" "relative"
                   , style "margin-top" "20px"
                   ]
            )
            []
        ]
