module Engines.Transitions.InterruptingAnimations.MultiProperty.Main exposing (..)

import Anim.Engine.CSS.Transitions as Transitions
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


animGroupName : String
animGroupName =
    "movingBox"


type alias Model =
    { animState : Transitions.AnimState
    , width : Float
    , height : Float
    , activeCount : Int
    }


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
            Transitions.init
                [ Translate.initXY animGroupName ((w - boxWidth) / 2) ((h - boxWidth) / 2)
                , Rotate.initZ animGroupName 0
                , BackgroundColor.init animGroupName startColor
                ]
      , width = w
      , height = h
      , activeCount = 0
      }
    , Cmd.none
    )



-- COLORS


directionColor : Msg -> Color.Color
directionColor msg =
    case msg of
        MoveLeft ->
            Color.fromRgba { r = 0, g = 123, b = 255, a = 1 }

        MoveRight ->
            Color.fromRgba { r = 40, g = 167, b = 69, a = 1 }

        MoveUp ->
            Color.fromRgba { r = 111, g = 66, b = 193, a = 1 }

        MoveDown ->
            Color.fromRgba { r = 255, g = 193, b = 7, a = 1 }

        _ ->
            startColor



-- ANIMATIONS


moveBox : (Translate.Builder -> Translate.Builder) -> (Transitions.AnimBuilder -> Transitions.AnimBuilder)
moveBox moveFunc =
    Translate.for animGroupName
        >> moveFunc
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.build


moveBoxWithExtras : (Translate.Builder -> Translate.Builder) -> Color.Color -> (Transitions.AnimBuilder -> Transitions.AnimBuilder)
moveBoxWithExtras moveFunc color =
    moveBox moveFunc
        >> Rotate.for animGroupName
        >> Rotate.byZ 90
        >> Rotate.duration 6000
        >> Rotate.easing EaseInOut
        >> Rotate.build
        >> BackgroundColor.for animGroupName
        >> BackgroundColor.to color
        >> BackgroundColor.duration 6000
        >> BackgroundColor.easing EaseInOut
        >> BackgroundColor.build



-- UPDATE


type Msg
    = GotAnimationUpdate Transitions.AnimMsg
    | MoveLeft
    | MoveRight
    | MoveUp
    | MoveDown


handleMove :
    Msg
    -> Model
    -> (Translate.Builder -> Translate.Builder)
    -> Model
handleMove direction model moveFunc =
    let
        newAnimState =
            Transitions.animate model.animState <|
                if model.activeCount > 0 then
                    moveBox moveFunc

                else
                    moveBoxWithExtras moveFunc <|
                        directionColor direction
    in
    { model | animState = newAnimState }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimationUpdate animationMsg ->
            let
                ( newAnimState, event ) =
                    Transitions.update animationMsg model.animState

                activeCount =
                    case event |> Debug.log "event" of
                        Transitions.Started _ _ _ ->
                            model.activeCount + 1

                        Transitions.Ended _ _ _ ->
                            max 0 (model.activeCount - 1)

                        Transitions.Cancelled _ _ _ ->
                            max 0 (model.activeCount - 1)

                        _ ->
                            model.activeCount
            in
            ( { model
                | animState = newAnimState
                , activeCount = activeCount |> Debug.log "activeCount"
              }
            , Cmd.none
            )

        MoveLeft ->
            ( handleMove MoveLeft model <|
                Translate.toX 0
            , Cmd.none
            )

        MoveRight ->
            ( handleMove MoveRight model <|
                Translate.toX (model.width - boxWidth)
            , Cmd.none
            )

        MoveUp ->
            ( handleMove MoveUp model <|
                Translate.toY 0
            , Cmd.none
            )

        MoveDown ->
            ( handleMove MoveDown model <|
                Translate.toY (model.height - boxWidth)
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
                (Transitions.attributes animGroupName model.animState
                    ++ Transitions.events animGroupName GotAnimationUpdate
                    ++ [ Html.Attributes.id "box"
                       , Html.Attributes.style "width" (String.fromFloat boxWidth ++ "px")
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
