port module ElmUI.Ports.Opacity.Main exposing (main)

{-| Anim.Ports Opacity Example using ElmUI - Fade animations with Web Animations API

This example demonstrates smooth opacity transitions using port-based JavaScript integration with Web Animations API.
Perfect for fade-in/fade-out effects, modal overlays, and visibility transitions.

FEATURES:

  - ✅ Smooth opacity animations via JavaScript ports
  - ✅ Web Animations API integration for optimal performance
  - ✅ Fade in, fade out, and partial opacity transitions
  - ✅ Real-time opacity display with port-based updates

-}

import Anim
import Anim.Easing as Easing
import Anim.Ports as Ports
import Anim.Properties.Opacity as Opacity
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
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
    {}



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( {}
    , Cmd.none
    )


type Msg
    = FadeIn
    | FadeOut
    | ResetOpacity


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FadeIn ->
            let
                animation =
                    Anim.init "box"
                        |> Opacity.to 1.0
                        |> Anim.duration 1000
                        |> Anim.easing Easing.easeInOut
            in
            ( model, Ports.animate animateElement animation )

        FadeOut ->
            let
                animation =
                    Anim.init "box"
                        |> Opacity.to 0.0
                        |> Anim.duration 1000
                        |> Anim.easing Easing.easeInOut
            in
            ( model, Ports.animate animateElement animation )

        ResetOpacity ->
            let
                animation =
                    Anim.init "box"
                        |> Opacity.to 0.5
                        |> Anim.duration 1000
                        |> Anim.easing Easing.easeInOut
            in
            ( model, Ports.animate animateElement animation )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Ports Opacity ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Ports Opacity Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth fade-in and fade-out effects using JavaScript Web Animations API")
    , -- Opacity controls
      UI.wrappedButtonRow
        [ ( UI.Success, FadeIn, "Fade In (100%)" )
        , ( UI.Warning, FadeOut, "Fade Out (0%)" )
        , ( UI.Purple, ResetOpacity, "Reset (50%)" )
        ]
    , -- Animation area with boxes
      el
        [ width (fill |> maximum 600)
        , height (px 300)
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
        , htmlAttribute (Html.Attributes.style "overflow" "hidden")
        ]
        (el
            [ centerX
            , Element.centerY
            , width (px 200)
            , height (px 200)
            ]
            (animatedBox "box" "Opacity Demo" Colors.primary)
        )
    ]


animatedBox : String -> String -> Element.Color -> Element Msg
animatedBox elementId label color =
    el
        [ width (px 150)
        , height (px 150)
        , Background.color color
        , Border.rounded 12
        , centerX
        , htmlAttribute (Html.Attributes.id elementId)
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
