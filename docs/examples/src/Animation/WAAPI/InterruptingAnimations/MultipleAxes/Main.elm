port module Animation.WAAPI.InterruptingAnimations.MultipleAxes.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))



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


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



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
            width

        h =
            height - 75
    in
    ( { animState =
            WAAPI.init motionCmd motionMsg <|
                [ Translate.initXY animGroup ((w - boxWidth) / 2) ((h - boxWidth) / 2) ]
      , width = w
      , height = h
      }
    , Cmd.none
    )



-- ANIMATIONS


moveLeft : AnimBuilder mode -> AnimBuilder mode
moveLeft =
    moveBox <|
        Translate.toX 0


moveRight : Float -> AnimBuilder mode -> AnimBuilder mode
moveRight width =
    moveBox <|
        Translate.toX (width - boxWidth)


moveUp : AnimBuilder mode -> AnimBuilder mode
moveUp =
    moveBox <|
        Translate.toY 0


moveDown : Float -> AnimBuilder mode -> AnimBuilder mode
moveDown height =
    moveBox <|
        Translate.toY (height - boxWidth)


moveBox : (Translate.Builder mode -> Translate.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
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
        button bgColor label onClickMsg =
            Html.button
                [ onClick onClickMsg
                , class "ui-action-button"
                , style "background-color" bgColor
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
                    ++ [ style "width" (String.fromFloat boxWidth ++ "px")
                       , style "height" (String.fromFloat boxWidth ++ "px")
                       , style "background-color" "#FF5733"
                       , style "position" "absolute"
                       , style "margin-top" "20px"
                       ]
                )
                []
    in
    div [ style "text-align" "center" ]
        [ div [ class "example-controls" ]
            [ moveLeftButton
            , moveRightButton
            , moveUpButton
            , moveDownButton
            ]
        , box
        ]
