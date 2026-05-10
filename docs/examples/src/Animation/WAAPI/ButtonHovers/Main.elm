port module Animation.WAAPI.ButtonHovers.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Extra.View3D as View3D
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Browser
import Browser.Events
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events.Extra.Pointer as Pointer
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))



-- MAIN


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
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


{-| Pick a base button size from the current viewport. The min axis drives
the scale so the buttons stay legible in landscape phones too.
-}
baseSize : Int -> Int -> { height : Float, width : Float }
baseSize windowWidth windowHeight =
    let
        ref =
            toFloat (min windowWidth windowHeight)

        width =
            clamp 130 200 (ref * 0.35)

        height =
            clamp 40 60 (width * 0.3)
    in
    { height = height, width = width }



--8<-- [start:model]


type alias Model =
    { animState : WAAPI.AnimState Msg
    , windowWidth : Int
    , windowHeight : Int
    }


type alias Flags =
    { width : Int
    , height : Int
    }


flagsDecoder : Decoder Flags
flagsDecoder =
    Decode.field "window"
        (Decode.map2 Flags
            (Decode.field "width" Decode.int)
            (Decode.field "height" Decode.int)
        )


init : Decode.Value -> ( Model, Cmd Msg )
init rawFlags =
    let
        flags =
            Decode.decodeValue flagsDecoder rawFlags
                |> Result.withDefault { width = 1024, height = 768 }

        size =
            baseSize flags.width flags.height

        animState =
            WAAPI.init motionCmd motionMsg <|
                [ Size.initHW sizeButton size.height size.width
                , Size.initHW scaleButton size.height size.width
                , Size.initHW zButton size.height size.width
                ]
    in
    ( { animState = animState
      , windowWidth = flags.width
      , windowHeight = flags.height
      }
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


growSize : { height : Float, width : Float } -> AnimBuilder mode -> AnimBuilder mode
growSize size =
    Size.for sizeButton
        >> Size.toHW (size.height + 6) (size.width + 20)
        >> Size.duration hoverDuration
        >> Size.easing hoverEasing
        >> Size.build


shrinkSize : { height : Float, width : Float } -> AnimBuilder mode -> AnimBuilder mode
shrinkSize size =
    Size.for sizeButton
        >> Size.toHW size.height size.width
        >> Size.duration hoverDuration
        >> Size.easing unhoverEasing
        >> Size.build


{-| Fast settle animation used after a viewport change so all three buttons
pick up the new resting size without snapping.
-}
resizeSettle : { height : Float, width : Float } -> AnimBuilder mode -> AnimBuilder mode
resizeSettle size =
    let
        toBase id_ =
            Size.for id_
                >> Size.toHW size.height size.width
                >> Size.duration 1
                >> Size.easing Linear
                >> Size.build
    in
    toBase sizeButton
        >> toBase scaleButton
        >> toBase zButton


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
    | WindowResized Int Int



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
                    WAAPI.animate model.animState
                        (growSize (baseSize model.windowWidth model.windowHeight))
            in
            ( { model | animState = animState }, cmd )

        SizeUnhover ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState
                        (shrinkSize (baseSize model.windowWidth model.windowHeight))
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

        WindowResized w h ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState
                        (resizeSettle (baseSize w h))
            in
            ( { model
                | animState = animState
                , windowWidth = w
                , windowHeight = h
              }
            , cmd
            )



---8<-- [start:subscriptions]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ WAAPI.subscriptions GotWaapiMsg model.animState
        , Browser.Events.onResize WindowResized
        ]



---8<-- [end:subscriptions]
---8<-- [end:trigger]
-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "example-stage"
        ]
        [ div
            [ style "padding" "7px"
            , style "border-radius" "12px"
            , style "border" "2px solid #041e53"
            , style "justify-content" "center"
            , style "gap" "clamp(12px, 3vmin, 24px)"
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
