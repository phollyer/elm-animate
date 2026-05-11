module Animation.Transition.InterruptingAnimations.MultipleProperties.Main exposing (..)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Transition as Transition
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
    { animState : Transition.AnimState
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
            Transition.init
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


{-| Re-anchor the translate to a new target. `Translate.continueFor`
inherits the in-flight `duration` / `easing` / `speed` from the previous
animation when the property is currently mid-animation, and
`Transition.retarget` flags the running animation group so that
inheritance kicks in. CSS itself takes care of the visual continuity -
when the transition target changes mid-flight, the browser interpolates
from the current rendered position to the new target, so no `fromX` is
needed and the box doesn't teleport.

When the property is idle (resize fires after the box has settled),
`continueFor` falls back to `for`-style behaviour and snaps to the new
position instead of animating, matching typical resize-handler
behaviour.

Granularity is per animation group, not per property, in the Transition
engine - every property in a running group is treated as in-flight
until the group's `transitionend` fires. That's a perfect fit here:
while the translate is mid-animation, the resize handler smoothly
retargets it; once it settles, the next resize snaps.

Note: unlike the WAAPI and Sub examples, the clamps used by those
engines are intentionally omitted here. The Transition engine has no
JavaScript-side runtime snapshot, so `continueFor`'s `start` value is
the _previous target_ rather than the current rendered position.
Clamping that previous target to the new (smaller) viewport bounds
would collapse it onto the new target, producing a zero-distance
animation and the engine emits `transition: none`. The new target is
already computed in-bounds (`w - boxWidth`), so the clamp is
unnecessary anyway.

-}
retargetBoxXY : Float -> Float -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
retargetBoxXY _ _ x y =
    Translate.continueFor animGroupName
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
    = GotAnimationUpdate Transition.AnimMsg
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

        ChangeColor color ->
            ( { model
                | animState =
                    Transition.animate model.animState <|
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

                newAnimState =
                    Transition.retarget model.animState <|
                        retargetBoxXY w h (targetX model.xPos w) (targetY h)
            in
            ( { model
                | canvasW = w
                , canvasH = h
                , animState = newAnimState
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
                (Transition.attributes animGroupName model.animState
                    ++ Transition.events GotAnimationUpdate
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
