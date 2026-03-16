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


startColor : Color.Color
startColor =
    Color.fromRgba { r = 255, g = 87, b = 51, a = 1 }


init : { width : Float, height : Float } -> ( Model, Cmd Msg )
init { width, height } =
    ( { animState =
            WAAPI.init waapiCommand waapiEvent <|
                [ Translate.initXY animGroupName 0 0
                , Rotate.initZ animGroupName 0
                , BackgroundColor.init animGroupName startColor
                ]
      , width = width - 20
      , height = height - 75
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


directionRotation : Msg -> Float
directionRotation msg =
    case msg of
        MoveLeft ->
            -90

        MoveRight ->
            90

        MoveUp ->
            0

        MoveDown ->
            180

        _ ->
            0



-- ANIMATIONS


moveBox : (Translate.Builder -> Translate.Builder) -> WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
moveBox moveFunc animState =
    WAAPI.animate animState <|
        Translate.for animGroupName
            >> moveFunc
            >> Translate.speed 200
            >> Translate.easing BounceOut
            >> Translate.build


moveBoxWithExtras : (Translate.Builder -> Translate.Builder) -> Float -> Color.Color -> WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
moveBoxWithExtras moveFunc rotation color animState =
    WAAPI.animate animState <|
        Translate.for animGroupName
            >> moveFunc
            >> Translate.speed 200
            >> Translate.easing BounceOut
            >> Translate.build
            >> Rotate.for animGroupName
            >> Rotate.toZ rotation
            >> Rotate.duration 1600
            >> Rotate.easing EaseInOut
            >> Rotate.build
            >> BackgroundColor.for animGroupName
            >> BackgroundColor.to color
            >> BackgroundColor.duration 1600
            >> BackgroundColor.easing EaseInOut
            >> BackgroundColor.build



-- UPDATE


type Msg
    = GotAnimationUpdate WAAPI.AnimMsg
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
        isRunning =
            WAAPI.isRunning animGroupName model.animState
                |> Maybe.withDefault False

        ( newAnimState, cmd ) =
            if isRunning then
                moveBox moveFunc model.animState

            else
                moveBoxWithExtras moveFunc
                    (directionRotation direction)
                    (directionColor direction)
                    model.animState
    in
    ( { model | animState = newAnimState }
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
