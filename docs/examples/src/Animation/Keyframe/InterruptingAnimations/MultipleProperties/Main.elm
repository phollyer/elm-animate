module Animation.Keyframe.InterruptingAnimations.MultipleProperties.Main exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Keyframe as Keyframe
import Anim.Extra.Color as Color exposing (Color)
import Anim.Property.CustomColor as BgColor
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


type alias Model =
    { animState : Keyframe.AnimState
    , canvasW : Float
    , canvasH : Float
    , xPos : XPos
    }


type XPos
    = XLeft
    | XCenter
    | XRight


animGroupName : String
animGroupName =
    "movingBox"


canvasId : String
canvasId =
    "anim-canvas"


boxWidth : Float
boxWidth =
    100


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            Keyframe.init
                [ Translate.initXY animGroupName 0 0
                , BgColor.init animGroupName BgColor.BackgroundColor <| Color.rgb 118 118 118
                ]
      , canvasW = 0
      , canvasH = 0
      , xPos = XCenter
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


targetY : Float -> Float
targetY h =
    (h - boxWidth) / 2



-- COLORS


color1 : Color
color1 =
    Color.rgb 255 87 51


color2 : Color
color2 =
    Color.rgb 40 167 69


color3 : Color
color3 =
    Color.rgb 111 66 193


color4 : Color
color4 =
    Color.rgb 255 193 7



-- ANIMATIONS


moveBoxX : Float -> AnimBuilder mode -> AnimBuilder mode
moveBoxX x =
    Translate.for animGroupName
        >> Translate.toX x
        >> Translate.speed 100
        >> Translate.easing BounceOut
        >> Translate.build


snapBoxXY : Float -> Float -> AnimBuilder mode -> AnimBuilder mode
snapBoxXY x y =
    Translate.for animGroupName
        >> Translate.toXY x y
        >> Translate.build


changeColor : Color -> AnimBuilder mode -> AnimBuilder mode
changeColor color =
    BgColor.for animGroupName BgColor.BackgroundColor
        >> BgColor.to color
        >> BgColor.duration 3000
        >> BgColor.easing Linear
        >> BgColor.build



-- UPDATE


type Msg
    = GotAnimationUpdate Keyframe.AnimMsg
    | MoveLeft
    | MoveRight
    | ChangeColor Color
    | Resize
    | GotCanvas (Result Dom.Error Dom.Element)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimationUpdate animationMsg ->
            let
                ( newAnimState, _ ) =
                    Keyframe.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        MoveLeft ->
            ( { model
                | xPos = XLeft
                , animState =
                    Keyframe.animate model.animState <|
                        moveBoxX (targetX XLeft model.canvasW)
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | xPos = XRight
                , animState =
                    Keyframe.animate model.animState <|
                        moveBoxX (targetX XRight model.canvasW)
              }
            , Cmd.none
            )

        ChangeColor color ->
            ( { model
                | animState =
                    Keyframe.animate model.animState <|
                        changeColor color
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
                    Keyframe.animate model.animState <|
                        snapBoxXY (targetX model.xPos w) (targetY h)
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
        posButton bgColor label onClickMsg =
            Html.button
                [ onClick onClickMsg
                , class "ui-action-button"
                , style "background-color" bgColor
                ]
                [ text label ]

        colorButton color label =
            Html.button
                [ onClick (ChangeColor color)
                , class "ui-action-button"
                , style "background-color" (Color.toHex color)
                ]
                [ text label ]
    in
    div [ style "text-align" "center" ]
        [ Keyframe.styleNode model.animState
        , div [ class "example-controls" ]
            [ posButton "#333" "Move Left" MoveLeft
            , posButton "#333" "Move Right" MoveRight
            ]
        , div [ class "example-controls" ]
            [ colorButton color1 "Color 1"
            , colorButton color2 "Color 2"
            , colorButton color3 "Color 3"
            , colorButton color4 "Color 4"
            ]
        , div [ id canvasId, class "example-canvas--fluid" ]
            [ div
                (Keyframe.attributes animGroupName model.animState
                    ++ Keyframe.events GotAnimationUpdate
                    ++ [ style "width" (String.fromFloat boxWidth ++ "px")
                       , style "height" (String.fromFloat boxWidth ++ "px")
                       , style "position" "absolute"
                       , style "top" "0"
                       , style "left" "0"
                       ]
                )
                []
            ]
        ]
