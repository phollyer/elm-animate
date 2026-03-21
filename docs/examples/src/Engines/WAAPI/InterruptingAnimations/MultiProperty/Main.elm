port module Engines.WAAPI.InterruptingAnimations.MultiProperty.Main exposing (..)

import Anim.Engine.WAAPI as WAAPI
import Anim.Extra.Color as Color exposing (Color)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.BackgroundColor as BgColor
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, div, text)
import Html.Attributes
import Html.Events
import Json.Encode as Encode



-- MAIN


main : Program { width : Float, height : Float } Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- PORTS


port waapiCommand : Encode.Value -> Cmd msg


port waapiEvent : (Encode.Value -> msg) -> Sub msg



-- MODEL


type alias Model =
    { animState : WAAPI.AnimState Msg
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
            WAAPI.init waapiCommand waapiEvent <|
                [ Translate.initXY animGroupName ((w - boxWidth) / 2) ((h - boxWidth) / 2)
                , BgColor.init animGroupName <| Color.rgb 118 118 118
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


moveBox : (Translate.Builder -> Translate.Builder) -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveBox moveFunc =
    Translate.for animGroupName
        >> moveFunc
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.build


changeColor : Color -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
changeColor color =
    BgColor.for animGroupName
        >> BgColor.to color
        >> BgColor.duration 3000
        >> BgColor.easing Linear
        >> BgColor.build



-- UPDATE


type Msg
    = GotAnimationUpdate WAAPI.AnimMsg
    | MoveLeft
    | MoveRight
    | ChangeColor Color


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimationUpdate animationMsg ->
            let
                ( newAnimState, _ ) =
                    WAAPI.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        MoveLeft ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        moveBox (Translate.toX 0)
            in
            ( { model | animState = newAnimState }
            , cmd
            )

        MoveRight ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        moveBox (Translate.toX (model.width - boxWidth))
            in
            ( { model | animState = newAnimState }
            , cmd
            )

        ChangeColor color ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        changeColor color
            in
            ( { model | animState = newAnimState }
            , cmd
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    WAAPI.subscriptions GotAnimationUpdate model.animState



-- VIEW


view : Model -> Html Msg
view model =
    let
        posButton bgColor label onClick =
            div
                [ Html.Events.onClick onClick
                , Html.Attributes.style "display" "inline-block"
                , Html.Attributes.style "margin-left" "10px"
                , Html.Attributes.style "margin-right" "10px"
                , Html.Attributes.style "padding" "10px"
                , Html.Attributes.style "background-color" bgColor
                , Html.Attributes.style "color" "white"
                , Html.Attributes.style "cursor" "pointer"
                ]
                [ text label ]

        colorButton color label =
            div
                [ Html.Events.onClick (ChangeColor color)
                , Html.Attributes.style "display" "inline-block"
                , Html.Attributes.style "margin-left" "10px"
                , Html.Attributes.style "margin-right" "10px"
                , Html.Attributes.style "padding" "10px"
                , Html.Attributes.style "background-color" (Color.toHex color)
                , Html.Attributes.style "color" "white"
                , Html.Attributes.style "cursor" "pointer"
                ]
                [ text label ]
    in
    div [ Html.Attributes.style "text-align" "center" ]
        [ div [ Html.Attributes.style "margin-bottom" "10px" ]
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
            (WAAPI.attributes animGroupName model.animState
                ++ [ Html.Attributes.style "width" (String.fromFloat boxWidth ++ "px")
                   , Html.Attributes.style "height" (String.fromFloat boxWidth ++ "px")
                   , Html.Attributes.style "position" "relative"
                   , Html.Attributes.style "margin-top" "20px"
                   ]
            )
            []
        ]
