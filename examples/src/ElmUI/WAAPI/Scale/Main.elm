port module ElmUI.WAAPI.Scale.Main exposing (main)

{-| Anim.Engine.CSS Scale Example using ElmUI - Size transformation animations

This example demonstrates smooth scaling animations using browser-native CSS transforms.
Perfect for hover effects, emphasis animations, and dynamic sizing.

FEATURES:

  - ✅ Smooth scale up/down animations
  - ✅ Hardware-accelerated transform scaling
  - ✅ Multiple scale factors and timing
  - ✅ Bounce and emphasis effects
  - ✅ Battery efficient browser-native transforms

-}

import Anim.Engine.WAAPI as WAAPI
import Anim.Properties.Scale as Scale
import Anim.Timing.Easing as Easing
import Browser exposing (Document)
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



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState = WAAPI.init
      }
    , Cmd.none
    )


type Msg
    = ScaleUp
    | ScaleDown
    | ScaleReset
    | ScaleWide
    | ScaleTall
    | NoOp



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScaleUp ->
            let
                builder =
                    WAAPI.builder model.animState
                        |> WAAPI.duration 500
                        |> WAAPI.easing Easing.EaseOut
                        |> Scale.for "box"
                        |> Scale.toXY 1.3 1.3
                        |> Scale.build

                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState builder
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        ScaleDown ->
            let
                builder =
                    WAAPI.builder model.animState
                        |> WAAPI.duration 333
                        |> WAAPI.easing Easing.EaseIn
                        |> Scale.for "box"
                        |> Scale.toXY 0.7 0.7
                        |> Scale.build

                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState builder
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        ScaleReset ->
            let
                builder =
                    WAAPI.builder model.animState
                        |> WAAPI.duration 800
                        |> WAAPI.easing Easing.EaseInOut
                        |> Scale.for "box"
                        |> Scale.toXY 1.0 1.0
                        |> Scale.build

                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState builder
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        ScaleWide ->
            let
                builder =
                    WAAPI.builder model.animState
                        |> WAAPI.duration 1200
                        |> WAAPI.easing Easing.EaseOut
                        |> Scale.for "box"
                        |> Scale.toXY 2.0 0.8
                        |> Scale.build

                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState builder
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        ScaleTall ->
            let
                builder =
                    WAAPI.builder model.animState
                        |> WAAPI.duration 667
                        |> WAAPI.easing Easing.EaseInOut
                        |> Scale.for "box"
                        |> Scale.toXY 0.6 1.8
                        |> Scale.build

                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState builder
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.WAAPI Scale ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Ports Scale Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth size transformations using browser-native CSS transitions")
    , -- Scale controls
      UI.wrappedButtonRow
        [ ( UI.Primary, ScaleUp, "Scale Up" )
        , ( UI.Warning, ScaleDown, "Scale Down" )
        , ( UI.Success, ScaleWide, "Wide" )
        , ( UI.Success, ScaleTall, "Tall" )
        , ( UI.Purple, ScaleReset, "Reset" )
        ]
    , -- Animation area with box
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
            (animatedBox "box" "Scale Demo" Colors.primary model)
        )
    ]


animatedBox : String -> String -> Element.Color -> Model -> Element Msg
animatedBox elementId label color model =
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
        (el
            [ centerX
            , Element.centerY
            , Font.color Colors.backgroundWhite
            , Font.bold
            , Font.size 16
            ]
            (text label)
        )
