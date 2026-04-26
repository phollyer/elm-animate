module Animation.Sub.ButtonHovers.Main exposing (main)

import Anim.Engine.Sub as Sub exposing (AnimBuilder)
import Anim.Extra.View3D as View3D
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Browser
import Easing exposing (Easing(..))
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
        , subscriptions = subscriptions
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
    { animState : Sub.AnimState }


init : ( Model, Cmd Msg )
init =
    let
        animState =
            Sub.init
                [ Size.initHW sizeButton buttonHeight buttonWidth
                , Size.initHW scaleButton buttonHeight buttonWidth
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
--8<-- [start:Msg]


type Msg
    = GotSubMsg Sub.AnimMsg
      --8<-- [end:Msg]
    | ScaleHover
    | ScaleUnhover
    | SizeHover
    | SizeUnhover
    | ZHover
    | ZUnhover



--8<-- [start:update]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotSubMsg animMsg ->
            let
                ( animState, _ ) =
                    Sub.update animMsg model.animState
            in
            ( { model | animState = animState }
            , Cmd.none
            )

        ---8<-- [end:update]
        ---8<-- [start:trigger]
        ScaleHover ->
            ( { model | animState = Sub.animate model.animState scaleUp }
            , Cmd.none
            )

        ScaleUnhover ->
            ( { model | animState = Sub.animate model.animState scaleDown }
            , Cmd.none
            )

        SizeHover ->
            ( { model | animState = Sub.animate model.animState growSize }
            , Cmd.none
            )

        SizeUnhover ->
            ( { model | animState = Sub.animate model.animState shrinkSize }
            , Cmd.none
            )

        ZHover ->
            ( { model | animState = Sub.animate model.animState liftUp }
            , Cmd.none
            )

        ZUnhover ->
            ( { model | animState = Sub.animate model.animState setDown }
            , Cmd.none
            )



---8<-- [end:trigger]
-- SUBSCRIPTIONS


subscriptions : Model -> Sub.Sub Msg
subscriptions model =
    Sub.subscriptions GotSubMsg model.animState



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
        , style "padding-top" "14px"
        ]
        [ button "Scale" ScaleHover ScaleUnhover scaleButton model.animState
        , button "Size" SizeHover SizeUnhover sizeButton model.animState
        , div
            [ View3D.perspective 600 ]
            [ button "Translate Z" ZHover ZUnhover zButton model.animState ]
        ]



---8<-- [start:render]


button : String -> Msg -> Msg -> String -> Sub.AnimState -> Html Msg
button label hoverMsg unhoverMsg groupName animState =
    div
        (Sub.attributes groupName animState
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
