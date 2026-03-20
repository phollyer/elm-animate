port module Engines.WAAPI.InterruptingAnimations.MultiProperty.Main exposing (..)

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
    , state : State
    , rotation : Float
    }


type State
    = Idle
    | Animating


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
      , state = Idle
      , rotation = 0
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


changeColor : Color.Color -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
changeColor color =
    BackgroundColor.for animGroupName
        >> BackgroundColor.to color
        >> BackgroundColor.duration 3000
        >> BackgroundColor.easing EaseInOut
        >> BackgroundColor.build


rotateBox : Float -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
rotateBox rotateAmount =
    Rotate.for animGroupName
        >> Rotate.toZ rotateAmount
        >> Rotate.duration 3000
        >> Rotate.easing BounceOut
        >> Rotate.build


moveBox : (Translate.Builder -> Translate.Builder) -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveBox moveFunc =
    Translate.for animGroupName
        >> moveFunc
        >> Translate.speed 150
        >> Translate.easing Linear
        >> Translate.build


moveBoxWithExtras : Float -> (Translate.Builder -> Translate.Builder) -> Color.Color -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveBoxWithExtras rotateAmount moveFunc color =
    moveBox moveFunc
        >> rotateBox rotateAmount
        >> changeColor color


move : Direction -> Float -> State -> (Translate.Builder -> Translate.Builder) -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
move direction rotateAmount state moveFunc =
    case state of
        Animating ->
            moveBox moveFunc

        Idle ->
            moveBoxWithExtras rotateAmount moveFunc <|
                directionColor direction



-- UPDATE


type Msg
    = GotAnimationUpdate WAAPI.AnimMsg
    | MoveLeft
    | MoveRight
    | MoveUp
    | MoveDown


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimationUpdate animationMsg ->
            let
                ( newAnimState, event ) =
                    WAAPI.update animationMsg model.animState

                state =
                    case event of
                        WAAPI.Started _ _ ->
                            Animating

                        WAAPI.Ended _ _ ->
                            Idle

                        WAAPI.Cancelled _ _ _ ->
                            Idle

                        _ ->
                            model.state
            in
            ( { model
                | animState = newAnimState
                , state = state
              }
            , Cmd.none
            )

        MoveLeft ->
            let
                rotateAmount =
                    model.rotation + 90

                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        move Left rotateAmount model.state <|
                            Translate.toX 0
            in
            ( { model
                | animState = newAnimState
                , rotation = rotateAmount |> Debug.log "New rotation"
              }
            , cmd
            )

        MoveRight ->
            let
                rotateAmount =
                    model.rotation + 90

                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        move Right rotateAmount model.state <|
                            Translate.toX (model.width - boxWidth)
            in
            ( { model
                | animState = newAnimState
                , rotation = rotateAmount
              }
            , cmd
            )

        MoveUp ->
            let
                rotateAmount =
                    model.rotation + 90

                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        move Up rotateAmount model.state <|
                            Translate.toY 0
            in
            ( { model
                | animState = newAnimState
                , rotation = rotateAmount
              }
            , cmd
            )

        MoveDown ->
            let
                rotateAmount =
                    model.rotation + 90

                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        move Down rotateAmount model.state <|
                            Translate.toY (model.height - boxWidth)
            in
            ( { model
                | animState = newAnimState
                , rotation = rotateAmount
              }
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
