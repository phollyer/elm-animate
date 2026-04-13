port module ElmUI.WAAPI.Mixed.Main exposing (main)

{-| Anim.Engine.Animation.WAAPI Mixed Properties Example using ElmUI - Combined animation effects

This example demonstrates combining multiple animation properties in single animations.
Shows how to create rich, complex effects by mixing position, scale, rotation, opacity, and color.

FEATURES:

  - ✅ Multiple simultaneous property animations
  - ✅ Coordinated transform combinations (position + scale + rotation)
  - ✅ Fade + move effects (opacity + position)
  - ✅ Color morphing with size changes (background + scale)
  - ✅ Complex interaction patterns with smooth transitions

-}

import Anim.Extra.Color
import Anim.Extra.Easing as Easing exposing (Easing(..))
import Anim.Extra.View3D as View3D
import Anim.Engine.Animation.WAAPI as WAAPI
import Anim.Property.BackgroundColor as Color
import Anim.Property.Opacity as Opacity
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.Animations.Mixed as Mixed exposing (elementId)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode



-- PORTS


port waapiCommand : Encode.Value -> Cmd msg


port waapiEvent : (Decode.Value -> msg) -> Sub msg



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : WAAPI.AnimState Msg
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            WAAPI.init waapiCommand waapiEvent
                [ Mixed.init
                ]
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = MoveScaleRotate
    | FadeMove
    | SpinScaleColor
    | ColorSizeOpacity
    | AllProperties
    | ResetAll
    | GotWaapiMsg WAAPI.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotWaapiMsg subMsg ->
            let
                ( newAnimState, _ ) =
                    WAAPI.update subMsg model.animState
            in
            ( { model | animState = newAnimState }, Cmd.none )

        MoveScaleRotate ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate model.animState Mixed.moveScaleRotate
            in
            ( { model | animState = newAnimState }, animCmd )

        FadeMove ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate model.animState Mixed.fadeMove
            in
            ( { model | animState = newAnimState }, animCmd )

        SpinScaleColor ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate model.animState Mixed.spinScaleColor
            in
            ( { model | animState = newAnimState }, animCmd )

        ColorSizeOpacity ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate model.animState Mixed.colorSizeOpacity
            in
            ( { model | animState = newAnimState }, animCmd )

        AllProperties ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate model.animState Mixed.allProperties
            in
            ( { model | animState = newAnimState }, animCmd )

        ResetAll ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate model.animState Mixed.resetAll
            in
            ( { model | animState = newAnimState }, animCmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.Animation.WAAPI Mixed Properties ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Ports Mixed Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Combining multiple CSS properties in single animations for complex transformations")
    , -- Mixed property animation controls
      UI.wrappedButtonRow
        [ ( UI.Primary, MoveScaleRotate, "Move + Scale + Rotate" )
        , ( UI.Success, FadeMove, "Fade + Move" )
        , ( UI.Warning, SpinScaleColor, "Spin + Scale + Color" )
        , ( UI.Purple, ColorSizeOpacity, "Color + Size + Opacity" )
        , ( UI.Primary, AllProperties, "ALL Properties!" )
        , ( UI.Success, ResetAll, "Reset" )
        ]
    , -- Animation area
      el
        ([ htmlAttribute <|
            Html.Attributes.id "animation-container"
         , width (fill |> maximum 600)
         , height (px 400)
         , Background.color Colors.backgroundWhite
         , Border.rounded 12
         , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }
         , centerX
         , htmlAttribute (Html.Attributes.style "position" "relative")
         , htmlAttribute (Html.Attributes.style "overflow" "visible")
         ]
            ++ [ htmlAttribute (View3D.perspective 1000) ]
        )
        (mixedAnimationBox model)
    ]


mixedAnimationBox : Model -> Element Msg
mixedAnimationBox model =
    el
        ([ width (px 80)
         , height (px 80)
         , Border.rounded 12
         , htmlAttribute (Html.Attributes.style "position" "absolute")
         , htmlAttribute (Html.Attributes.style "background-color" "#3498db") -- Default blue
         , htmlAttribute (Html.Attributes.style "transform-origin" "center")
         , htmlAttribute (Html.Attributes.style "display" "flex")
         , htmlAttribute (Html.Attributes.style "align-items" "center")
         , htmlAttribute (Html.Attributes.style "justify-content" "center")
         ]
            ++ List.map htmlAttribute (WAAPI.attributes elementId model.animState)
        )
        (el
            [ centerX
            , Element.centerY
            , Font.color Colors.backgroundWhite
            , Font.bold
            , Font.size 14
            , htmlAttribute (Html.Attributes.style "text-shadow" "0 1px 2px rgba(0,0,0,0.5)")
            ]
            (text "MIX")
        )
