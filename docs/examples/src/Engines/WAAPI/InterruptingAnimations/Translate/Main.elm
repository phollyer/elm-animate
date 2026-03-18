port module Engines.WAAPI.InterruptingAnimations.Translate.Main exposing (main)

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


port waapiCommand : Encode.Value -> Cmd msg


port waapiEvent : (Encode.Value -> msg) -> Sub msg



-- MODEL


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
    let
        w =
            width - 20

        h =
            height - 75
    in
    ( { animState =
            WAAPI.init waapiCommand waapiEvent <|
                [ Translate.initXY animGroup ((w - boxWidth) / 2) ((h - boxWidth) / 2) ]
      , width = w
      , height = h
      }
    , Cmd.none
    )



-- ANIMATIONS


moveLeft : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveLeft =
    moveBox <|
        Translate.toX 0


moveRight : Float -> (WAAPI.AnimBuilder -> WAAPI.AnimBuilder)
moveRight width =
    moveBox <|
        Translate.toX (width - boxWidth)


moveUp : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveUp =
    moveBox <|
        Translate.toY 0


moveDown : Float -> (WAAPI.AnimBuilder -> WAAPI.AnimBuilder)
moveDown height =
    moveBox <|
        Translate.toY (height - boxWidth)


moveBox : (Translate.Builder -> Translate.Builder) -> (WAAPI.AnimBuilder -> WAAPI.AnimBuilder)
moveBox moveFunc =
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

        ---8<-- [start:WithoutFreeze]
        MoveLeft ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState moveLeft
            in
            ( { model | animState = newAnimState }
            , cmd
            )

        MoveRight ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        moveRight model.width
            in
            ( { model | animState = newAnimState }
            , cmd
            )

        MoveUp ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState moveUp
            in
            ( { model | animState = newAnimState }
            , cmd
            )

        MoveDown ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        moveDown model.height
            in
            ( { model | animState = newAnimState }
            , cmd
            )



---8<-- [end:WithoutFreeze]
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
