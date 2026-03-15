port module Engines.WAAPI.InterruptingAnimations.Main exposing (main)

import Anim.Engine.WAAPI as WAAPI
import Anim.Extra.Easing exposing (Easing(..))
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
-- Outgoing Port


port waapiCommand : Encode.Value -> Cmd msg



-- Incoming Port


port waapiEvent : (Encode.Value -> msg) -> Sub msg



-- MODEL
-- Avoid typos from hardcoding string element IDs in multiple places


animGroup : String
animGroup =
    "movingBox"


type alias Model =
    { animState : WAAPI.AnimState Msg
    , width : Float
    , height : Float
    }


boxWidth : Float
boxWidth =
    100



-- INIT


init : { width : Float, height : Float } -> ( Model, Cmd Msg )
init { width, height } =
    ( { animState =
            WAAPI.init waapiCommand waapiEvent <|
                [ Translate.initXY animGroup 0 0 ]
      , width = width - 20 -- Account for some padding on the sides
      , height = height - 75 -- Account for buttons height
      }
    , Cmd.none
    )



-- ANIMATIONS


moveLeft : WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
moveLeft =
    moveToX 0


moveRight : Float -> WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
moveRight width =
    moveToX (width - boxWidth)


moveUp : WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
moveUp =
    moveToY 0


moveDown : Float -> WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
moveDown height =
    moveToY (height - boxWidth)


moveToX : Float -> WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
moveToX =
    moveBox
        << Translate.toX


moveToY : Float -> WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
moveToY =
    moveBox
        << Translate.toY


moveBox : (Translate.Builder -> Translate.Builder) -> WAAPI.AnimState Msg -> ( WAAPI.AnimState Msg, Cmd Msg )
moveBox moveFunc animState =
    WAAPI.animate animState <|
        Translate.for animGroup
            >> moveFunc
            >> Translate.speed 200
            >> Translate.easing BounceOut
            >> Translate.build



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
                ( newAnimState, _ ) =
                    WAAPI.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        MoveLeft ->
            let
                ( newAnimState, cmd ) =
                    moveLeft model.animState
            in
            ( { model | animState = newAnimState }
            , cmd
            )

        MoveRight ->
            let
                ( newAnimState, cmd ) =
                    moveRight model.width model.animState
            in
            ( { model | animState = newAnimState }
            , cmd
            )

        MoveUp ->
            let
                ( newAnimState, cmd ) =
                    moveUp model.animState
            in
            ( { model | animState = newAnimState }
            , cmd
            )

        MoveDown ->
            let
                ( newAnimState, cmd ) =
                    moveDown model.height model.animState
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
                (WAAPI.attributes animGroup model.animState
                    ++ [ Html.Attributes.style "width" (String.fromFloat boxWidth ++ "px")
                       , Html.Attributes.style "height" (String.fromFloat boxWidth ++ "px")
                       , Html.Attributes.style "background-color" "#FF5733"
                       , Html.Attributes.style "position" "absolute"
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
