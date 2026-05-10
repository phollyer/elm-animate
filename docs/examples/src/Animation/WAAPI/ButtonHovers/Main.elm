port module Animation.WAAPI.ButtonHovers.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Extra.View3D as View3D
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Browser
import Html exposing (Html, div, text)
import Html.Attributes exposing (style)
import Html.Events.Extra.Pointer as Pointer
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- PORTS


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



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
    { animState : WAAPI.AnimState Msg }


init : ( Model, Cmd Msg )
init =
    let
        animState =
            WAAPI.init motionCmd motionMsg <|
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


scaleUp : AnimBuilder mode -> AnimBuilder mode
scaleUp =
    Scale.for scaleButton
        >> Scale.to 1.1
        >> Scale.duration hoverDuration
        >> Scale.easing hoverEasing
        >> Scale.build


scaleDown : AnimBuilder mode -> AnimBuilder mode
scaleDown =
    Scale.for scaleButton
        >> Scale.to 1
        >> Scale.duration hoverDuration
        >> Scale.easing unhoverEasing
        >> Scale.build


growSize : AnimBuilder mode -> AnimBuilder mode
growSize =
    Size.for sizeButton
        >> Size.toHW (buttonHeight + 6) (buttonWidth + 20)
        >> Size.duration hoverDuration
        >> Size.easing hoverEasing
        >> Size.build


shrinkSize : AnimBuilder mode -> AnimBuilder mode
shrinkSize =
    Size.for sizeButton
        >> Size.toHW buttonHeight buttonWidth
        >> Size.duration hoverDuration
        >> Size.easing unhoverEasing
        >> Size.build


liftUp : AnimBuilder mode -> AnimBuilder mode
liftUp =
    Translate.for zButton
        >> Translate.toZ 60
        >> Translate.duration hoverDuration
        >> Translate.easing hoverEasing
        >> Translate.build


setDown : AnimBuilder mode -> AnimBuilder mode
setDown =
    Translate.for zButton
        >> Translate.toZ 0
        >> Translate.duration hoverDuration
        >> Translate.easing unhoverEasing
        >> Translate.build



---8<-- [end:build]
---8<-- [start:Msg]


type Msg
    = GotWaapiMsg WAAPI.AnimMsg
      ---8<-- [end:Msg]
    | ScaleHover
    | ScaleUnhover
    | SizeHover
    | SizeUnhover
    | ZHover
    | ZUnhover



---8<-- [start:update]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotWaapiMsg waapiMsg ->
            let
                ( animState, _ ) =
                    WAAPI.update waapiMsg model.animState
            in
            ( { model | animState = animState }
            , Cmd.none
            )

        ---8<-- [end:update]
        ---8<-- [start:trigger]
        ScaleHover ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState scaleUp
            in
            ( { model | animState = animState }, cmd )

        ScaleUnhover ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState scaleDown
            in
            ( { model | animState = animState }, cmd )

        SizeHover ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState growSize
            in
            ( { model | animState = animState }, cmd )

        SizeUnhover ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState shrinkSize
            in
            ( { model | animState = animState }, cmd )

        ZHover ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState liftUp
            in
            ( { model | animState = animState }, cmd )

        ZUnhover ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState setDown
            in
            ( { model | animState = animState }, cmd )



---8<-- [start:subscriptions]


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



---8<-- [end:subscriptions]
---8<-- [end:trigger]
-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "height" "100%"
        , style "width" "100%"
        , style "padding-top" "14px"
        , style "padding-bottom" "14px"
        ]
        [ div
            [ style "padding" "7px"
            , style "border-radius" "12px"
            , style "border" "2px solid #041e53"
            , style "justify-content" "center"
            , style "gap" "24px"
            , style "display" "flex"
            , style "flex-direction" "column"
            , style "align-items" "center"
            ]
            [ button "Scale" ScaleHover ScaleUnhover scaleButton model.animState
            , button "Size" SizeHover SizeUnhover sizeButton model.animState
            , div
                [ View3D.perspective 600 ]
                [ button "Translate Z" ZHover ZUnhover zButton model.animState ]
            ]
        ]



---8<-- [start:render]


button : String -> Msg -> Msg -> String -> WAAPI.AnimState Msg -> Html Msg
button label hoverMsg unhoverMsg groupName animState =
    div
        (WAAPI.attributes groupName animState
            ++ [ Pointer.onEnter (\_ -> hoverMsg)
               , Pointer.onLeave (\_ -> unhoverMsg)
               , style "display" "flex"
               , style "align-items" "center"
               , style "justify-content" "center"
               , style "background-color" "#3b82f6"
               , style "color" "white"
               , style "font-size" "16px"
               , style "font-weight" "600"
               , style "border-radius" "8px"
               , style "cursor" "pointer"
               , style "touch-action" "manipulation"
               , style "-webkit-tap-highlight-color" "transparent"
               , style "user-select" "none"
               , style "box-sizing" "border-box"
               , style "box-shadow" "0 3px 5px rgba(0, 0, 0, 0.5), 0 1px 3px rgba(0, 0, 0, 0.4)"
               ]
        )
        [ text label ]



---8<-- [end:render]
