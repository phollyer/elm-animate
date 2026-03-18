port module Engines.WAAPI.InterruptingAnimations.AddingProperties.Main exposing (..)

import Anim.Engine.WAAPI as WAAPI
import Anim.Extra.Color as Color
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.BackgroundColor as BackgroundColor
import Anim.Property.Rotate as Rotate
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
    , clickCount : Int
    , lastDirection : Maybe Direction
    }


type Direction
    = Left
    | Right
    | Up
    | Down


animGroupName : String
animGroupName =
    "movingBox"


boxWidth : Float
boxWidth =
    100


startColor : Color.Color
startColor =
    Color.fromRgba { r = 255, g = 87, b = 51, a = 1 }


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
                , Rotate.initZ animGroupName 0
                , BackgroundColor.init animGroupName startColor
                ]
      , width = w
      , height = h
      , clickCount = 0
      , lastDirection = Nothing
      }
    , Cmd.none
    )



-- COLORS


directionColor : Direction -> Color.Color
directionColor direction =
    case direction of
        Left ->
            Color.fromRgba { r = 0, g = 123, b = 255, a = 1 }

        Right ->
            Color.fromRgba { r = 40, g = 167, b = 69, a = 1 }

        Up ->
            Color.fromRgba { r = 111, g = 66, b = 193, a = 1 }

        Down ->
            Color.fromRgba { r = 255, g = 193, b = 7, a = 1 }



-- ANIMATIONS


moveBox : (Translate.Builder -> Translate.Builder) -> (WAAPI.AnimBuilder -> WAAPI.AnimBuilder)
moveBox moveFunc =
    Translate.for animGroupName
        >> moveFunc
        >> Translate.speed 200
        >> Translate.easing BounceOut
        >> Translate.build


addExtras : Color.Color -> (WAAPI.AnimBuilder -> WAAPI.AnimBuilder)
addExtras color =
    Rotate.for animGroupName
        >> Rotate.byZ 90
        >> Rotate.duration 1600
        >> Rotate.easing EaseInOut
        >> Rotate.build
        >> BackgroundColor.for animGroupName
        >> BackgroundColor.to color
        >> BackgroundColor.duration 1600
        >> BackgroundColor.easing EaseInOut
        >> BackgroundColor.build


directionMoveFunc : Direction -> Model -> (Translate.Builder -> Translate.Builder)
directionMoveFunc direction model =
    case direction of
        Left ->
            Translate.toX 0

        Right ->
            Translate.toX (model.width - boxWidth)

        Up ->
            Translate.toY 0

        Down ->
            Translate.toY (model.height - boxWidth)



-- UPDATE


type Msg
    = GotAnimationUpdate WAAPI.AnimMsg
    | MoveLeft
    | MoveRight
    | MoveUp
    | MoveDown


handleMove :
    (Translate.Builder -> Translate.Builder)
    -> Direction
    -> Model
    -> ( Model, Cmd Msg )
handleMove moveFunc direction model =
    let
        newClickCount =
            if model.lastDirection == Just direction then
                model.clickCount + 1

            else
                0

        builder =
            if newClickCount > 0 then
                addExtras (directionColor direction)

            else
                case model.lastDirection of
                    Just lastDir ->
                        moveBox (directionMoveFunc lastDir model >> moveFunc)

                    Nothing ->
                        moveBox moveFunc

        ( newAnimState, cmd ) =
            WAAPI.animate model.animState builder
    in
    ( { model
        | animState = newAnimState
        , clickCount = newClickCount
        , lastDirection = Just direction
      }
    , cmd
    )


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
            handleMove (Translate.toX 0) Left model

        MoveRight ->
            handleMove (Translate.toX (model.width - boxWidth)) Right model

        MoveUp ->
            handleMove (Translate.toY 0) Up model

        MoveDown ->
            handleMove (Translate.toY (model.height - boxWidth)) Down model



-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
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
                , Html.Attributes.style "background-color" bgColor
                , Html.Attributes.style "color" "white"
                , Html.Attributes.style "cursor" "pointer"
                ]
                [ text label ]

        moveLeftButton =
            button "#007BFF" "Move Left" MoveLeft

        moveRightButton =
            button "#28A745" "Move Right" MoveRight

        moveUpButton =
            button "#6F42C1" "Move Up" MoveUp

        moveDownButton =
            button "#FFC107" "Move Down" MoveDown

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
        [ moveLeftButton
        , moveRightButton
        , moveUpButton
        , moveDownButton
        , box
        ]
