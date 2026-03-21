module Engines.Keyframes.InterruptingAnimations.MultipleAxes.Main exposing (main)

import Anim.Engine.CSS.Keyframes as Keyframes
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
    { animState : Keyframes.AnimState
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
            Keyframes.init
                [ Translate.initXY animGroupName ((w - boxWidth) / 2) ((h - boxWidth) / 2) ]
      , width = w
      , height = h
      }
    , Cmd.none
    )



-- ANIMATIONS


moveLeft : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveLeft =
    moveBox (Translate.toX 0)


moveRight : Float -> (Keyframes.AnimBuilder -> Keyframes.AnimBuilder)
moveRight width =
    moveBox (Translate.toX (width - boxWidth))


moveUp : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveUp =
    moveBox (Translate.toY 0)


moveDown : Float -> (Keyframes.AnimBuilder -> Keyframes.AnimBuilder)
moveDown height =
    moveBox (Translate.toY (height - boxWidth))


moveBox : (Translate.Builder -> Translate.Builder) -> (Keyframes.AnimBuilder -> Keyframes.AnimBuilder)
moveBox moveFunc =
    Translate.for animGroupName
        >> moveFunc
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.build



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
                ( newAnimState, _ ) =
                    Keyframes.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        MoveLeft ->
            ( { model | animState = Keyframes.animate model.animState moveLeft }
            , Cmd.none
            )

        MoveRight ->
            ( { model | animState = Keyframes.animate model.animState <| moveRight model.width }
            , Cmd.none
            )

        MoveUp ->
            ( { model | animState = Keyframes.animate model.animState moveUp }
            , Cmd.none
            )

        MoveDown ->
            ( { model | animState = Keyframes.animate model.animState <| moveDown model.height }
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
        [ Keyframes.styleNode model.animState
        , moveLeftButton
        , moveRightButton
        , moveUpButton
        , moveDownButton
        , box
        ]
