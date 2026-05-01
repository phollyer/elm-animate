port module Animation.WAAPI.ColorTest.Main exposing (..)

import Anim.Engine.WAAPI as WAAPI
import Anim.Extra.Color as Color exposing (Color)
import Anim.Property.CustomColor as BackgroundColor
import Browser
import Easing exposing (Easing(..))
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Json.Encode as Encode



-- PORTS


port waapiCommand : Encode.Value -> Cmd msg


port waapiEvent : (Encode.Value -> msg) -> Sub msg



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : WAAPI.AnimState Msg
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState = WAAPI.init waapiCommand waapiEvent []
      }
    , Cmd.none
    )


animGroup1 : String
animGroup1 =
    "box1Color"


animGroup2 : String
animGroup2 =
    "box2Color"


animGroup3 : String
animGroup3 =
    "box3Color"


red : Color
red =
    Color.fromRgb { r = 239, g = 76, b = 60 }


green : Color
green =
    Color.fromRgb { r = 15, g = 158, b = 30 }


blue : Color
blue =
    Color.fromRgb { r = 88, g = 17, b = 186 }


white : Color
white =
    Color.fromRgb { r = 255, g = 255, b = 255 }



-- UPDATE


type Msg
    = ClickedRed
    | ClickedGreen
    | ClickedBlue
    | GotWaapiMsg WAAPI.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedRed ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState animateRed
            in
            ( { model | animState = animState }, cmd )

        ClickedGreen ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState animateGreen
            in
            ( { model | animState = animState }, cmd )

        ClickedBlue ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState animateBlue
            in
            ( { model | animState = animState }, cmd )

        GotWaapiMsg animMsg ->
            let
                ( animState, _ ) =
                    WAAPI.update animMsg model.animState
            in
            ( { model | animState = animState }, Cmd.none )



-- ANIMATIONS


animateRed : WAAPI.AnimBuilder {} -> WAAPI.AnimBuilder {}
animateRed =
    BackgroundColor.for animGroup1 BackgroundColor.BackgroundColor
        >> BackgroundColor.from white
        >> BackgroundColor.to red
        >> BackgroundColor.duration 1000
        >> BackgroundColor.build


animateGreen : WAAPI.AnimBuilder {} -> WAAPI.AnimBuilder {}
animateGreen =
    BackgroundColor.for animGroup2 BackgroundColor.BackgroundColor
        >> BackgroundColor.from white
        >> BackgroundColor.to green
        >> BackgroundColor.duration 1000
        >> BackgroundColor.build


animateBlue : WAAPI.AnimBuilder {} -> WAAPI.AnimBuilder {}
animateBlue =
    BackgroundColor.for animGroup3 BackgroundColor.BackgroundColor
        >> BackgroundColor.from white
        >> BackgroundColor.to blue
        >> BackgroundColor.duration 1000
        >> BackgroundColor.build



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "font-family" "system-ui, sans-serif"
        , style "padding" "40px"
        , style "max-width" "600px"
        , style "margin" "0 auto"
        ]
        [ viewButtons
        , viewBoxes model
        ]


viewButtons : Html Msg
viewButtons =
    div
        [ style "display" "flex"
        , style "gap" "12px"
        , style "margin-bottom" "30px"
        ]
        [ colorButton "Red" "#e74c3c" ClickedRed
        , colorButton "Green" "#2ecc71" ClickedGreen
        , colorButton "Blue" "#3498db" ClickedBlue
        ]


colorButton : String -> String -> Msg -> Html Msg
colorButton label color msg =
    button
        [ onClick msg
        , style "padding" "10px 24px"
        , style "border" "none"
        , style "border-radius" "6px"
        , style "background-color" color
        , style "color" "#fff"
        , style "font-size" "14px"
        , style "font-weight" "bold"
        , style "cursor" "pointer"
        ]
        [ text label ]


viewBoxes : Model -> Html Msg
viewBoxes model =
    div
        [ style "display" "flex"
        , style "gap" "20px"
        ]
        [ div
            (WAAPI.attributes animGroup1 model.animState
                ++ [ style "width" "120px"
                   , style "height" "120px"
                   , style "background-color" "#ecf0f1"
                   , style "border-radius" "8px"
                   , style "display" "flex"
                   , style "justify-content" "center"
                   , style "align-items" "center"
                   , style "font-weight" "bold"
                   , style "color" "#333"
                   ]
            )
            [ text "Box 1" ]
        , div
            (WAAPI.attributes animGroup2 model.animState
                ++ [ style "width" "120px"
                   , style "height" "120px"
                   , style "background-color" "#ecf0f1"
                   , style "border-radius" "8px"
                   , style "display" "flex"
                   , style "justify-content" "center"
                   , style "align-items" "center"
                   , style "font-weight" "bold"
                   , style "color" "#333"
                   ]
            )
            [ text "Box 2" ]
        , div
            (WAAPI.attributes animGroup3 model.animState
                ++ [ style "width" "120px"
                   , style "height" "120px"
                   , style "background-color" "#ecf0f1"
                   , style "border-radius" "8px"
                   , style "display" "flex"
                   , style "justify-content" "center"
                   , style "align-items" "center"
                   , style "font-weight" "bold"
                   , style "color" "#333"
                   ]
            )
            [ text "Box 3" ]
        ]
