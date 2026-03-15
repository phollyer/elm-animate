module Engines.Transitions.InterruptingAnimations.Main exposing (main)

import Anim.Engine.CSS.Transitions as Transitions
import Anim.Extra.Easing exposing (Easing(..))
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
    }


boxWidth : Float
boxWidth =
    100


init : { width : Float, height : Float } -> ( Model, Cmd Msg )
init { width, height } =
    ( { animState =
            Transitions.init
                [ Translate.initXY animGroupName 0 0 ]
      , width = width - 20 -- Account for some padding on the sides
      , height = height - 75 -- Account for buttons height
      }
    , Cmd.none
    )



-- ANIMATIONS


moveLeft : Transitions.AnimState -> Transitions.AnimState
moveLeft =
    moveToX 0


moveRight : Float -> Transitions.AnimState -> Transitions.AnimState
moveRight width =
    moveToX (width - boxWidth)


moveUp : Transitions.AnimState -> Transitions.AnimState
moveUp =
    moveToY 0


moveDown : Float -> Transitions.AnimState -> Transitions.AnimState
moveDown height =
    moveToY (height - boxWidth)


moveToX : Float -> Transitions.AnimState -> Transitions.AnimState
moveToX targetX =
    moveBox (Translate.toX targetX)


moveToY : Float -> Transitions.AnimState -> Transitions.AnimState
moveToY targetY =
    moveBox (Translate.toY targetY)


moveBox : (Translate.Builder -> Translate.Builder) -> Transitions.AnimState -> Transitions.AnimState
moveBox moveFunc animState =
    Transitions.animate animState <|
        Translate.for animGroupName
            >> moveFunc
            >> Translate.speed 100
            >> Translate.easing BounceOut
            >> Translate.build



-- UPDATE


type Msg
    = GotAnimationUpdate Transitions.AnimMsg
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
                    Transitions.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        MoveLeft ->
            ( { model | animState = moveLeft model.animState }
            , Cmd.none
            )

        MoveRight ->
            ( { model | animState = moveRight model.width model.animState }
            , Cmd.none
            )

        MoveUp ->
            ( { model | animState = moveUp model.animState }
            , Cmd.none
            )

        MoveDown ->
            ( { model | animState = moveDown model.height model.animState }
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
                    ++ [ Html.Attributes.style "width" (String.fromFloat boxWidth ++ "px")
                       , Html.Attributes.style "height" (String.fromFloat boxWidth ++ "px")
                       , Html.Attributes.style "background-color" "#FF5733"
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
