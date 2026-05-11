module Animation.Sub.InterruptingAnimations.MultipleProperties.Main exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Sub as Sub
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
    { animState : Sub.AnimState
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
            Sub.init
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


{-| Snapshot-and-continue: re-anchor a mid-flight translate to a new
target without teleporting the box. Reads the current rendered X via
`Sub.getTranslateCurrent`, feeds it back as `Translate.fromX`, and
animates to the new target with the same easing and `speed` (px/sec).

Because `speed` is constant the perceived velocity stays the same -
only the remaining duration scales to match the new remaining
distance.

-}
continueBoxX : Float -> Float -> AnimBuilder mode -> AnimBuilder mode
continueBoxX currentX newTargetX =
    Translate.for animGroupName
        >> Translate.fromX currentX
        >> Translate.toX newTargetX
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
    = GotAnimationUpdate Sub.AnimMsg
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
                    Sub.update animationMsg model.animState
            in
            ( { model | animState = newAnimState }
            , Cmd.none
            )

        MoveLeft ->
            ( { model
                | xPos = XLeft
                , animState =
                    Sub.animate model.animState <|
                        moveBoxX (targetX XLeft model.canvasW)
              }
            , Cmd.none
            )

        MoveRight ->
            ( { model
                | xPos = XRight
                , animState =
                    Sub.animate model.animState <|
                        moveBoxX (targetX XRight model.canvasW)
              }
            , Cmd.none
            )

        ChangeColor color ->
            ( { model
                | animState =
                    Sub.animate model.animState <|
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

                newTargetX =
                    targetX model.xPos w

                -- Snapshot-and-continue when mid-flight; snap when at rest.
                -- Y always centres in this example, so the Y axis just snaps.
                retarget =
                    case
                        ( Sub.isRunning animGroupName model.animState
                        , Sub.getTranslateCurrent animGroupName model.animState
                        )
                    of
                        ( Just True, Just current ) ->
                            let
                                -- Clamp the snapshot to the new canvas bounds.
                                -- Without this, a landscape-to-portrait resize
                                -- mid-flight can leave the box off-screen and
                                -- have it slide back in from outside the
                                -- canvas. Clamping pins the start to the new
                                -- edge so the continuation stays in bounds.
                                maxX =
                                    max 0 (w - boxWidth)

                                clampedX =
                                    clamp 0 maxX current.x
                            in
                            continueBoxX clampedX newTargetX

                        _ ->
                            snapBoxXY newTargetX (targetY h)
            in
            ( { model
                | canvasW = w
                , canvasH = h
                , animState = Sub.animate model.animState retarget
              }
            , Cmd.none
            )

        GotCanvas (Err _) ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.subscriptions GotAnimationUpdate model.animState
        , Browser.Events.onResize (\_ _ -> Resize)
        ]



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
        [ div [ class "example-controls" ]
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
                (Sub.attributes animGroupName model.animState
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
