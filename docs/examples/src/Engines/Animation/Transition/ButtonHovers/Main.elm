module Engines.Animation.Transition.ButtonHovers.Main exposing (main)

import Anim.Engine.CSS.Transition as Transition exposing (AnimBuilder)
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Extra.View3D as View3D
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onMouseEnter, onMouseLeave)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL
-- Avoid typos from hardcoding strings in multiple places


scaleButton : String
scaleButton =
    "scaleButton"


sizeButton : String
sizeButton =
    "sizeButton"


zButton : String
zButton =
    "zButton"


buttonWidth : Float
buttonWidth =
    160


buttonHeight : Float
buttonHeight =
    50



--8<-- [start:model]


type alias Model =
    { animState : Transition.AnimState }


init : ( Model, Cmd Msg )
init =
    let
        animState =
            Transition.init
                [ Size.initHW scaleButton buttonHeight buttonWidth
                , Size.initHW sizeButton buttonHeight buttonWidth
                , Size.initHW zButton buttonHeight buttonWidth
                ]
    in
    ( { animState = animState }
    , Cmd.none
    )



--8<-- [end:model]
-- ANIMATIONS


hoverDuration : Int
hoverDuration =
    200


hoverEasing : Easing
hoverEasing =
    CubicOut


unhoverEasing : Easing
unhoverEasing =
    CubicIn



---8<-- [start:build]


scaleUp : AnimBuilder -> AnimBuilder
scaleUp =
    Scale.for scaleButton
        >> Scale.to 1.1
        >> Scale.duration hoverDuration
        >> Scale.easing hoverEasing
        >> Scale.build


scaleDown : AnimBuilder -> AnimBuilder
scaleDown =
    Scale.for scaleButton
        >> Scale.to 1
        >> Scale.duration hoverDuration
        >> Scale.easing unhoverEasing
        >> Scale.build


growSize : AnimBuilder -> AnimBuilder
growSize =
    Size.for sizeButton
        >> Size.toHW (buttonHeight + 6) (buttonWidth + 20)
        >> Size.duration hoverDuration
        >> Size.easing hoverEasing
        >> Size.build


shrinkSize : AnimBuilder -> AnimBuilder
shrinkSize =
    Size.for sizeButton
        >> Size.toHW buttonHeight buttonWidth
        >> Size.duration hoverDuration
        >> Size.easing unhoverEasing
        >> Size.build


liftUp : AnimBuilder -> AnimBuilder
liftUp =
    Translate.for zButton
        >> Translate.toZ 60
        >> Translate.duration hoverDuration
        >> Translate.easing hoverEasing
        >> Translate.build


setDown : AnimBuilder -> AnimBuilder
setDown =
    Translate.for zButton
        >> Translate.toZ 0
        >> Translate.duration hoverDuration
        >> Translate.easing unhoverEasing
        >> Translate.build



---8<-- [end:build]
-- UPDATE


type Msg
    = ScaleHover
    | ScaleUnhover
    | SizeHover
    | SizeUnhover
    | ZHover
    | ZUnhover


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:trigger]
        ScaleHover ->
            ( { model | animState = Transition.animate model.animState scaleUp }
            , Cmd.none
            )

        ScaleUnhover ->
            ( { model | animState = Transition.animate model.animState scaleDown }
            , Cmd.none
            )

        SizeHover ->
            ( { model | animState = Transition.animate model.animState growSize }
            , Cmd.none
            )

        SizeUnhover ->
            ( { model | animState = Transition.animate model.animState shrinkSize }
            , Cmd.none
            )

        ZHover ->
            ( { model | animState = Transition.animate model.animState liftUp }
            , Cmd.none
            )

        ZUnhover ->
            ( { model | animState = Transition.animate model.animState setDown }
            , Cmd.none
            )



---8<-- [end:trigger]
-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "gap" "24px"
        , style "height" "100%"
        , style "width" "100%"
        ]
        [ styledButton "Scale" ScaleHover ScaleUnhover scaleButton model.animState
        , styledButton "Size" SizeHover SizeUnhover sizeButton model.animState
        , div
            [ View3D.perspective 600 ]
            [ styledButton "Translate Z" ZHover ZUnhover zButton model.animState ]
        ]



---8<-- [start:render]


styledButton : String -> Msg -> Msg -> String -> Transition.AnimState -> Html Msg
styledButton label hoverMsg unhoverMsg groupName animState =
    div
        (Transition.attributes groupName animState
            ++ [ onMouseEnter hoverMsg
               , onMouseLeave unhoverMsg
               , style "display" "flex"
               , style "align-items" "center"
               , style "justify-content" "center"
               , style "background-color" "#3b82f6"
               , style "color" "white"
               , style "font-size" "16px"
               , style "font-weight" "600"
               , style "border-radius" "8px"
               , style "cursor" "pointer"
               , style "user-select" "none"
               , style "box-sizing" "border-box"
               , style "box-shadow" "0 3px 5px rgba(0, 0, 0, 0.5), 0 1px 3px rgba(0, 0, 0, 0.4)"
               ]
        )
        [ text label ]



---8<-- [end:render]
