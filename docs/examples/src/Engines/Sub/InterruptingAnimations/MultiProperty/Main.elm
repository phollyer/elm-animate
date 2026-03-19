module Engines.Sub.InterruptingAnimations.MultiProperty.Main exposing (..)

import Anim.Engine.Sub as Sub
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
        , subscriptions = subscriptions
        }



-- MODEL


animGroupName : String
animGroupName =
    "movingBox"


type alias Model =
    { animState : Sub.AnimState
    , width : Float
    , height : Float
    , activeTransitions : Int
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
            Sub.init
                [ Translate.initXY animGroupName ((w - boxWidth) / 2) ((h - boxWidth) / 2)
                , Rotate.initZ animGroupName 0
                , BackgroundColor.init animGroupName startColor
                ]
      , width = w
      , height = h
      , activeTransitions = 0
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


moveBox : (Translate.Builder -> Translate.Builder) -> (Sub.AnimBuilder -> Sub.AnimBuilder)
moveBox moveFunc =
    let
        _ =
            Debug.log "moveBox" ()
    in
    Translate.for animGroupName
        >> moveFunc
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.build


moveBoxWithExtras : (Translate.Builder -> Translate.Builder) -> Color.Color -> (Sub.AnimBuilder -> Sub.AnimBuilder)
moveBoxWithExtras moveFunc color =
    let
        _ =
            Debug.log "moveBoxWithExtras" ()
    in
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
    = GotAnimationUpdate Sub.AnimMsg
    | MoveLeft
    | MoveRight
    | MoveUp
    | MoveDown


handleMove :
    (Translate.Builder -> Translate.Builder)
    -> Msg
    -> Model
    -> ( Model, Cmd Msg )
handleMove moveFunc direction model =
    let
        newAnimState =
            Sub.animate model.animState <|
                if model.activeTransitions > 0 then
                    moveBox moveFunc

                else
                    moveBoxWithExtras moveFunc <|
                        directionColor direction
    in
    ( { model | animState = newAnimState }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimationUpdate animationMsg ->
            let
                ( newAnimState, events ) =
                    Sub.update animationMsg model.animState

                activeTransitions =
                    List.foldl
                        (\event acc ->
                            case event |> Debug.log "event" of
                                Sub.Started _ _ ->
                                    1

                                Sub.Ended _ _ ->
                                    0

                                Sub.Cancelled _ _ ->
                                    0

                                _ ->
                                    acc
                        )
                        model.activeTransitions
                        events
            in
            ( { model
                | animState = newAnimState
                , activeTransitions = activeTransitions |> Debug.log "activeTransitions"
              }
            , Cmd.none
            )

        MoveLeft ->
            handleMove (Translate.toX 0) MoveLeft model

        MoveRight ->
            handleMove (Translate.toX (model.width - boxWidth)) MoveRight model

        MoveUp ->
            handleMove (Translate.toY 0) MoveUp model

        MoveDown ->
            handleMove (Translate.toY (model.height - boxWidth)) MoveDown model



-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    Sub.subscriptions GotAnimationUpdate model.animState



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
                (Sub.attributes animGroupName model.animState
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
