port module ElmUI.WAAPI.Rotate.Main exposing (main)

{-| Anim.Engine.CSS Rotate Example using ElmUI - Rotate transformation animations

This example demonstrates smooth rotate animations using browser-native CSS transforms.
Perfect for loading spinners, interactive elements, and dynamic orientation changes.

FEATURES:

  - ✅ Smooth rotate animations in degrees
  - ✅ Hardware-accelerated transform rotates
  - ✅ Multiple rotate directions and speeds
  - ✅ Continuous spinning and specific angle targeting
  - ✅ Battery efficient browser-native transforms

-}

import Anim.Easing as Easing
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Rotate as Rotate
import Browser exposing (Document)
import Common.Animations.Rotate as Animations
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


port animateElement : Encode.Value -> Cmd msg



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
    { animState : WAAPI.AnimState
    }


type Msg
    = Rotate45
    | Rotate90
    | Rotate180
    | RotateLeft
    | RotateRight
    | ResetRotation
    | NoOp



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Rotate45 ->
            let
                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState (Animations.rotate45 "box")
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        Rotate90 ->
            let
                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState (Animations.rotate90 "box")
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        Rotate180 ->
            let
                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState (Animations.rotate180 "box")
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        RotateLeft ->
            let
                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState (Animations.rotateLeft "box")
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        RotateRight ->
            let
                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState (Animations.rotateRight "box")
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        ResetRotation ->
            let
                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState (Animations.resetRotate "box")
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        NoOp ->
            ( model, Cmd.none )



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        ( initialAnimState, initCmd ) =
            WAAPI.animate WAAPI.init <|
                \b -> b |> Rotate.initXYZ "box" 0 0 0
    in
    ( { animState = initialAnimState }
    , animateElement initCmd
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.WAAPI Rotate ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Ports Rotate Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth rotate transformations using hardware-accelerated CSS transforms")
    , -- Rotation controls
      UI.wrappedButtonRow
        [ ( UI.Success, Rotate45, "45°" )
        , ( UI.Warning, Rotate90, "90°" )
        , ( UI.Primary, Rotate180, "180°" )
        , ( UI.Success, RotateLeft, "← 90°" )
        , ( UI.Purple, ResetRotation, "Reset" )
        ]
    , -- Animation area with boxes
      el
        [ width (fill |> maximum 600)
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
        , htmlAttribute (Html.Attributes.style "display" "flex")
        , htmlAttribute (Html.Attributes.style "flex-direction" "column")
        , htmlAttribute (Html.Attributes.style "align-items" "center")
        , htmlAttribute (Html.Attributes.style "justify-content" "space-around")
        , htmlAttribute (Html.Attributes.style "padding" "40px")
        ]
        (el
            [ centerX
            , Element.centerY
            , width (px 200)
            , height (px 200)
            ]
            (rotatingElement "box" "→" "Rotate Demo" Colors.primary model)
        )
    ]


rotatingElement : String -> String -> String -> Element.Color -> Model -> Element Msg
rotatingElement elementId symbol label color model =
    el
        [ width (px 150)
        , height (px 150)
        , Background.color color
        , Border.rounded 12
        , centerX
        , htmlAttribute (Html.Attributes.id elementId)
        , htmlAttribute (Html.Attributes.style "transform-origin" "center")
        , htmlAttribute (Html.Attributes.style "display" "flex")
        , htmlAttribute (Html.Attributes.style "align-items" "center")
        , htmlAttribute (Html.Attributes.style "justify-content" "center")
        ]
        (column
            [ centerX
            , Element.centerY
            , spacing 8
            ]
            [ el
                [ centerX
                , Font.color Colors.backgroundWhite
                , Font.bold
                , Font.size 32
                ]
                (text symbol)
            , el
                [ centerX
                , Font.color Colors.backgroundWhite
                , Font.size 14
                ]
                (text label)
            ]
        )
