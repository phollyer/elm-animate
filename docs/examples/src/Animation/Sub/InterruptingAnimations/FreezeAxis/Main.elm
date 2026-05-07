module Animation.Sub.InterruptingAnimations.FreezeAxis.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as Sub
import Anim.Property.Translate as Translate
import Browser
import Easing exposing (Easing(..))
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)



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
    }


boxWidth : Float
boxWidth =
    100


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
                [ Translate.initXY animGroupName ((w - boxWidth) / 2) ((h - boxWidth) / 2) ]
      , width = w
      , height = h
      }
    , Cmd.none
    )



-- ANIMATIONS


moveLeft : Sub.AnimBuilder -> Sub.AnimBuilder
moveLeft =
    moveBox <|
        Translate.toX 0


moveRight : Float -> Sub.AnimBuilder -> Sub.AnimBuilder
moveRight width =
    moveBox <|
        Translate.toX (width - boxWidth)


moveUp : Sub.AnimBuilder -> Sub.AnimBuilder
moveUp =
    moveBox <|
        Translate.toY 0


moveDown : Float -> Sub.AnimBuilder -> Sub.AnimBuilder
moveDown height =
    moveBox <|
        Translate.toY (height - boxWidth)


moveBox : (Translate.Builder mode -> Translate.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
moveBox moveFunc =
    Translate.for animGroupName
        >> moveFunc
        >> Translate.speed 200
        >> Translate.easing BounceOut
        >> Translate.build



-- UPDATE


type Msg
    = GotAnimationUpdate Sub.AnimMsg
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
                    Sub.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        ---8<-- [start:WithFreeze]
        MoveLeft ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        Sub.freezeY [ Sub.translate ]
                            >> moveLeft
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        Sub.freezeY [ Sub.translate ]
                            >> moveRight model.width
              }
            , Cmd.none
            )

        MoveUp ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        Sub.freezeX [ Sub.translate ]
                            >> moveUp
              }
            , Cmd.none
            )

        MoveDown ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
                        Sub.freezeX [ Sub.translate ]
                            >> moveDown model.height
              }
            , Cmd.none
            )



---8<-- [end:WithFreeze]
-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    Sub.subscriptions GotAnimationUpdate model.animState



-- VIEW


view : Model -> Html Msg
view model =
    let
        button bgColor label onClickMsg =
            div
                [ onClick onClickMsg
                , class "ui-action-button"
                , style "display" "inline-block"
                , style "margin-left" "10px"
                , style "margin-right" "10px"
                , style "padding" "10px"
                , style "background-color" bgColor
                , style "color" "white"
                , style "cursor" "pointer"
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
                    ++ [ style "width" (String.fromFloat boxWidth ++ "px")
                       , style "height" (String.fromFloat boxWidth ++ "px")
                       , style "background-color" "#FF5733"
                       , style "position" "relative"
                       , style "margin-top" "20px"
                       ]
                )
                []
    in
    div [ style "text-align" "center" ]
        [ moveLeftButton
        , moveRightButton
        , moveUpButton
        , moveDownButton
        , box
        ]
