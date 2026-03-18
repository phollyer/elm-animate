port module Engines.WAAPI.InterruptingAnimations.Color.Main exposing (main)

import Anim.Engine.WAAPI as WAAPI
import Anim.Extra.Color as Color exposing (Color)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.BackgroundColor as BgColor
import Browser
import Html exposing (Html, div, text)
import Html.Attributes
import Html.Events
import Json.Encode as Encode



-- PORTS


port waapiCommand : Encode.Value -> Cmd msg


port waapiEvent : (Encode.Value -> msg) -> Sub msg



-- MAIN


main : Program { width : Float, height : Float } Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


animGroupName : String
animGroupName =
    "movingBox"


type alias Model =
    { animState : WAAPI.AnimState Msg
    , width : Float
    , height : Float
    }


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


toColor1 : WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
toColor1 =
    colorBox (BgColor.to color1)


toColor2 : WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
toColor2 =
    colorBox (BgColor.to color2)


toColor3 : WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
toColor3 =
    colorBox (BgColor.to color3)


toColor4 : WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
toColor4 =
    colorBox (BgColor.to color4)


colorBox : (BgColor.Builder -> BgColor.Builder) -> WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
colorBox moveFunc animState =
    WAAPI.animate animState <|
        BgColor.for animGroupName
            >> moveFunc
            >> BgColor.duration 3000
            >> BgColor.easing Linear
            >> BgColor.build



-- UPDATE


type Msg
    = GotAnimationUpdate WAAPI.AnimMsg
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
                    WAAPI.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        Color1 ->
            let
                ( animState, cmd ) =
                    toColor1 model.animState
            in
            ( { model | animState = animState }
            , cmd
            )

        Color2 ->
            let
                ( animState, cmd ) =
                    toColor2 model.animState
            in
            ( { model | animState = animState }
            , cmd
            )

        Color3 ->
            let
                ( animState, cmd ) =
                    toColor3 model.animState
            in
            ( { model | animState = animState }
            , cmd
            )

        Color4 ->
            let
                ( animState, cmd ) =
                    toColor4 model.animState
            in
            ( { model | animState = animState }
            , cmd
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotAnimationUpdate model.animState



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

        box =
            div
                (WAAPI.attributes animGroupName model.animState
                    ++ [ Html.Attributes.style "width" (String.fromFloat boxWidth ++ "px")
                       , Html.Attributes.style "height" (String.fromFloat boxWidth ++ "px")
                       , Html.Attributes.style "position" "relative"
                       , Html.Attributes.style "margin-top" "20px"
                       ]
                )
                []
    in
    div [ Html.Attributes.style "text-align" "center" ]
        [ color1Button
        , color2Button
        , color3Button
        , color4Button
        , box
        ]
