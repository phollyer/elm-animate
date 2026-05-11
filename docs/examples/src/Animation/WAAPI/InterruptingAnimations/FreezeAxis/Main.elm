port module Animation.WAAPI.InterruptingAnimations.FreezeAxis.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Translate as Translate
import Browser
import Browser.Dom as Dom
import Browser.Events
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
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



-- PORTS


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



-- MODEL


animGroup : String
animGroup =
    "movingBox"


canvasId : String
canvasId =
    "anim-canvas"


type alias Model =
    { animState : WAAPI.AnimState Msg
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



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            WAAPI.init motionCmd motionMsg <|
                [ Translate.initXY animGroup 0 0 ]
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
    moveBox <|
        Translate.toX x


moveBoxY : Float -> AnimBuilder mode -> AnimBuilder mode
moveBoxY y =
    moveBox <|
        Translate.toY y


moveBox : (Translate.Builder mode -> Translate.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
moveBox moveFunc =
    Translate.for animGroup
        >> moveFunc
        >> Translate.speed 200
        >> Translate.easing BounceOut
        >> Translate.build


snapBoxXY : Float -> Float -> AnimBuilder mode -> AnimBuilder mode
snapBoxXY x y =
    Translate.for animGroup
        >> Translate.toXY x y
        >> Translate.build



-- UPDATE


type Msg
    = GotAnimationUpdate WAAPI.AnimMsg
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
                    WAAPI.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        ---8<-- [start:WithFreeze]
        MoveLeft ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        WAAPI.freezeY [ WAAPI.translate ]
                            >> moveBoxX (targetX XLeft model.canvasW)
            in
            ( { model | animState = newAnimState, xPos = XLeft }
            , cmd
            )

        MoveRight ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        WAAPI.freezeY [ WAAPI.translate ]
                            >> moveBoxX (targetX XRight model.canvasW)
            in
            ( { model | animState = newAnimState, xPos = XRight }
            , cmd
            )

        MoveUp ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        WAAPI.freezeX [ WAAPI.translate ]
                            >> moveBoxY (targetY YTop model.canvasH)
            in
            ( { model | animState = newAnimState, yPos = YTop }
            , cmd
            )

        MoveDown ->
            let
                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        WAAPI.freezeX [ WAAPI.translate ]
                            >> moveBoxY (targetY YBottom model.canvasH)
            in
            ( { model | animState = newAnimState, yPos = YBottom }
            , cmd
            )

        ---8<-- [end:WithFreeze]
        Resize ->
            ( model, measureCanvas )

        GotCanvas (Ok element) ->
            let
                w =
                    element.element.width

                h =
                    element.element.height

                ( newAnimState, cmd ) =
                    WAAPI.animate model.animState <|
                        snapBoxXY (targetX model.xPos w) (targetY model.yPos h)
            in
            ( { model | canvasW = w, canvasH = h, animState = newAnimState }
            , cmd
            )

        GotCanvas (Err _) ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    Sub.batch
        [ WAAPI.subscriptions GotAnimationUpdate model.animState
        , Browser.Events.onResize (\_ _ -> Resize)
        ]



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
