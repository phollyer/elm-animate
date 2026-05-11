module Animation.Transition.InterruptingAnimations.MultipleAxes.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Transition as Transition
import Anim.Property.Translate as Translate
import Browser
import Browser.Dom as Dom
import Browser.Events
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import Motion.Easing as Easing exposing (Easing(..))
import Task



-- MAIN


main : Program () Model Msg
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


canvasId : String
canvasId =
    "anim-canvas"


type alias Model =
    { animState : Transition.AnimState
    , canvasW : Float
    , canvasH : Float
    , xPos : XPos
    , yPos : YPos
    }


type XPos
    = XLeft
    | XCenter
    | XRight


type YPos
    = YTop
    | YCenter
    | YBottom


boxWidth : Float
boxWidth =
    100


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            Transition.init
                [ Translate.initXY animGroupName 0 0 ]
      , canvasW = 0
      , canvasH = 0
      , xPos = XCenter
      , yPos = YCenter
      }
    , measureCanvas
    )


measureCanvas : Cmd Msg
measureCanvas =
    Task.attempt GotCanvas (Dom.getElement canvasId)



-- POSITION HELPERS


targetX : XPos -> Float -> Float
targetX pos w =
    case pos of
        XLeft ->
            0

        XCenter ->
            (w - boxWidth) / 2

        XRight ->
            w - boxWidth


targetY : YPos -> Float -> Float
targetY pos h =
    case pos of
        YTop ->
            0

        YCenter ->
            (h - boxWidth) / 2

        YBottom ->
            h - boxWidth



-- ANIMATIONS


moveBoxX : Float -> AnimBuilder mode -> AnimBuilder mode
moveBoxX x =
    moveBox (Translate.toX x)


moveBoxY : Float -> AnimBuilder mode -> AnimBuilder mode
moveBoxY y =
    moveBox (Translate.toY y)


moveBox : (Translate.Builder mode -> Translate.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
moveBox moveFunc =
    Translate.for animGroupName
        >> moveFunc
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.build


snapBoxXY : Float -> Float -> AnimBuilder mode -> AnimBuilder mode
snapBoxXY x y =
    Translate.for animGroupName
        >> Translate.toXY x y
        >> Translate.build



-- UPDATE


type Msg
    = GotAnimationUpdate Transition.AnimMsg
    | MoveLeft
    | MoveRight
    | MoveUp
    | MoveDown
    | Resize
    | GotCanvas (Result Dom.Error Dom.Element)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimationUpdate animationMsg ->
            let
                ( newAnimState, _ ) =
                    Transition.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        MoveLeft ->
            ( { model
                | xPos = XLeft
                , animState =
                    Transition.animate model.animState <|
                        moveBoxX (targetX XLeft model.canvasW)
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | xPos = XRight
                , animState =
                    Transition.animate model.animState <|
                        moveBoxX (targetX XRight model.canvasW)
              }
            , Cmd.none
            )

        MoveUp ->
            ( { model
                | yPos = YTop
                , animState =
                    Transition.animate model.animState <|
                        moveBoxY (targetY YTop model.canvasH)
              }
            , Cmd.none
            )

        MoveDown ->
            ( { model
                | yPos = YBottom
                , animState =
                    Transition.animate model.animState <|
                        moveBoxY (targetY YBottom model.canvasH)
              }
            , Cmd.none
            )

        Resize ->
            ( model, measureCanvas )

        GotCanvas (Ok element) ->
            let
                w =
                    element.element.width

                h =
                    element.element.height
            in
            ( { model
                | canvasW = w
                , canvasH = h
                , animState =
                    Transition.animate model.animState <|
                        snapBoxXY (targetX model.xPos w) (targetY model.yPos h)
              }
            , Cmd.none
            )

        GotCanvas (Err _) ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onResize (\_ _ -> Resize)



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
                (Transition.attributes animGroupName model.animState
                    ++ Transition.events GotAnimationUpdate
                    ++ [ style "width" (String.fromFloat boxWidth ++ "px")
                       , style "height" (String.fromFloat boxWidth ++ "px")
                       , style "background-color" "#FF5733"
                       , style "position" "absolute"
                       , style "top" "0"
                       , style "left" "0"
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
        , div [ id canvasId, class "example-canvas--fluid" ]
            [ box ]
        ]
