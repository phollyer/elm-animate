module Engines.Keyframes.InterruptingAnimations.MultiProperty.Main exposing (..)

import Anim.Engine.CSS.Keyframes as Keyframes
import Anim.Extra.Color as Color
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.BackgroundColor as BackgroundColor
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
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


type alias Model =
    { animState : Keyframes.AnimState
    , width : Float
    , height : Float
    , state : State
    }


type State
    = Idle
    | Animating Int


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
            Keyframes.init
                [ Translate.initXY animGroupName ((w - boxWidth) / 2) ((h - boxWidth) / 2)
                , Rotate.initZ animGroupName 0
                , BackgroundColor.init animGroupName startColor
                ]
      , width = w
      , height = h
      , state = Idle
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


changeColor : Color.Color -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
changeColor color =
    BackgroundColor.for animGroupName
        >> BackgroundColor.to color
        >> BackgroundColor.duration 3000
        >> BackgroundColor.easing EaseInOut
        >> BackgroundColor.build


rotateBox : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
rotateBox =
    Rotate.for animGroupName
        >> Rotate.byZ 90
        >> Rotate.duration 3000
        >> Rotate.easing BounceOut
        >> Rotate.build


moveBox : (Translate.Builder -> Translate.Builder) -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveBox moveFunc =
    Translate.for animGroupName
        >> moveFunc
        >> Translate.speed 150
        >> Translate.easing Linear
        >> Translate.build


moveBoxWithExtras : (Translate.Builder -> Translate.Builder) -> Color.Color -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveBoxWithExtras moveFunc color =
    moveBox moveFunc
        >> rotateBox
        >> changeColor color


move : Direction -> State -> (Translate.Builder -> Translate.Builder) -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
move direction state moveFunc =
    case state of
        Animating _ ->
            moveBox moveFunc

        Idle ->
            moveBoxWithExtras moveFunc <|
                directionColor direction



-- UPDATE


type Msg
    = GotAnimationUpdate Keyframes.AnimMsg
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
                    Keyframes.update animationMsg model.animState

                state =
                    case ( event, model.state ) of
                        ( Keyframes.Started _ _ _, Idle ) ->
                            Animating 1

                        ( Keyframes.Started _ _ _, Animating n ) ->
                            Animating (n + 1)

                        ( Keyframes.Ended _ _ _, Animating n ) ->
                            if n <= 1 then
                                Idle

                            else
                                Animating (n - 1)

                        ( Keyframes.Cancelled _ _ _, Animating n ) ->
                            if n <= 1 then
                                Idle

                            else
                                Animating (n - 1)

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
            ( { model
                | animState =
                    Keyframes.animate model.animState <|
                        move Left model.state <|
                            Translate.toX 0
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | animState =
                    Keyframes.animate model.animState <|
                        move Right model.state <|
                            Translate.toX (model.width - boxWidth)
              }
            , Cmd.none
            )

        MoveUp ->
            ( { model
                | animState =
                    Keyframes.animate model.animState <|
                        move Up model.state <|
                            Translate.toY 0
              }
            , Cmd.none
            )

        MoveDown ->
            ( { model
                | animState =
                    Keyframes.animate model.animState <|
                        move Down model.state <|
                            Translate.toY (model.height - boxWidth)
              }
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
                (Keyframes.attributes animGroupName model.animState
                    ++ Keyframes.events GotAnimationUpdate
                    ++ [ Html.Attributes.style "width" (String.fromFloat boxWidth ++ "px")
                       , Html.Attributes.style "height" (String.fromFloat boxWidth ++ "px")
                       , Html.Attributes.style "position" "relative"
                       , Html.Attributes.style "margin-top" "20px"
                       ]
                )
                []
    in
    div [ Html.Attributes.style "text-align" "center" ]
        [ Keyframes.styleNode model.animState
        , moveLeftButton
        , moveRightButton
        , moveUpButton
        , moveDownButton
        , box
        ]
