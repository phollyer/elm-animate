module Engines.Sub.InterruptingAnimations.Main exposing (main)

import Anim.Engine.Sub as Sub
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, div, text)
import Html.Attributes
import Html.Events


type alias Model =
    { animState : Sub.AnimState
    , width : Float
    }


boxWidth : Float
boxWidth =
    100


init : { width : Float } -> ( Model, Cmd Msg )
init { width } =
    ( { animState =
            Sub.animate Sub.init (Translate.initX "moving-box" (width / 2 - boxWidth / 2))
      , width = width
      }
    , Cmd.none
    )


type Msg
    = GotAnimationUpdate Sub.AnimMsg
    | MoveLeft
    | MoveRight


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

        MoveLeft ->
            ( { model | animState = moveLeft model.animState }
            , Cmd.none
            )

        MoveRight ->
            ( { model | animState = moveRight model.width model.animState }
            , Cmd.none
            )


moveLeft : Sub.AnimState -> Sub.AnimState
moveLeft =
    moveTo 0


moveRight : Float -> Sub.AnimState -> Sub.AnimState
moveRight width =
    moveTo (width - boxWidth)


moveTo : Float -> Sub.AnimState -> Sub.AnimState
moveTo targetX animState =
    Sub.animate animState
        (Translate.for "moving-box"
            >> Translate.toX targetX
            >> Translate.speed 200
            >> Translate.easing BounceOut
            >> Translate.build
        )


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    Sub.subscriptions GotAnimationUpdate model.animState


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

        box =
            div
                (Sub.htmlAttributes "moving-box" model.animState
                    ++ [ Html.Attributes.style "width" (String.fromFloat boxWidth ++ "px")
                       , Html.Attributes.style "height" (String.fromFloat boxWidth ++ "px")
                       , Html.Attributes.style "background-color" "#FF5733"
                       , Html.Attributes.style "position" "relative"
                       , Html.Attributes.style "margin-top" "20px"
                       ]
                )
                []
    in
    div []
        [ moveLeftButton
        , moveRightButton
        , box
        ]


main : Program { width : Float } Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
