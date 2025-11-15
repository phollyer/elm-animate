module ElmUI.CSS.Color.Main exposing (main)

{-| Anim.CSS Color Example using ElmUI - Background color transition animations

This example demonstrates smooth color transitions using browser-native CSS animations.
Perfect for theme changes, state indicators, and dynamic color feedback.

FEATURES:

  - ✅ Smooth background color transitions
  - ✅ Hardware-accelerated color interpolation
  - ✅ Multiple color formats (hex, rgb, hsl)
  - ✅ Theme switching and state changes
  - ✅ Battery efficient browser-native transitions

-}

import Anim
import Anim.CSS as CSS exposing (AnimationState)
import Anim.Properties.Color as Color
import Anim.Timing.Easing as Easing
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes



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
    { animations : Maybe AnimationState
    , isAnimating : Bool
    , currentColor : String -- Current color as hex string
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Nothing
      , isAnimating = False
      , currentColor = "#e74c3c" -- Starting with red color
      }
    , Cmd.none
    )


type Msg
    = ChangeToBlue
    | ChangeToGreen
    | ChangeToOrange
    | ChangeToRed
    | ChangeToPurple
    | ResetColor
    | AnimationComplete



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeToBlue ->
            let
                animationResult =
                    Anim.init "box"
                        |> Color.to (Hex "#3498db")
                        |> Anim.duration 600
                        |> Anim.easing Easing.easeInOutQuad
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
                , currentColor = "#3498db"
              }
            , Cmd.none
            )

        ChangeToGreen ->
            let
                animationResult =
                    Anim.init "box"
                        |> Color.to (Hex "#2ecc71")
                        |> Anim.duration 600
                        |> Anim.easing Easing.easeInOutQuad
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
                , currentColor = "#2ecc71"
              }
            , Cmd.none
            )

        ChangeToOrange ->
            let
                animationResult =
                    Anim.init "box"
                        |> Color.to (Hex "#f39c12")
                        |> Anim.duration 600
                        |> Anim.easing Easing.easeInOutQuad
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
                , currentColor = "#f39c12"
              }
            , Cmd.none
            )

        ChangeToRed ->
            let
                animationResult =
                    Anim.init "box"
                        |> Color.to (Hex "#e74c3c")
                        |> Anim.duration 600
                        |> Anim.easing Easing.easeInOutQuad
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
                , currentColor = "#e74c3c"
              }
            , Cmd.none
            )

        ChangeToPurple ->
            let
                animationResult =
                    Anim.init "box"
                        |> Color.to (Hex "#9b59b6")
                        |> Anim.duration 600
                        |> Anim.easing Easing.easeInOutQuad
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
                , currentColor = "#9b59b6"
              }
            , Cmd.none
            )

        ResetColor ->
            let
                animationResult =
                    Anim.init "box"
                        |> Color.to (Hex "#95a5a6")
                        |> Anim.duration 600
                        |> Anim.easing Easing.easeInOutQuad
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isAnimating = True
                , currentColor = "#95a5a6"
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( { model
                | isAnimating = False
                , animations = Nothing
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.CSS Color ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "CSS Color Animations"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth color transitions using browser-native CSS animations")
    , -- Color controls
      UI.wrappedButtonRow
        [ ( UI.Primary, ChangeToBlue, "Blue" )
        , ( UI.Success, ChangeToGreen, "Green" )
        , ( UI.Warning, ChangeToOrange, "Orange" )
        , ( UI.Warning, ChangeToRed, "Red" )
        , ( UI.Purple, ChangeToPurple, "Purple" )
        , ( UI.Primary, ResetColor, "Reset" )
        ]
    , -- Animation area with single colored box
      el
        [ width (fill |> maximum 600)
        , height (px 350)
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
            ([ centerX
             , centerY
             , width (px 150)
             , height (px 150)
             , Background.color (rgb 0.8 0.8 0.8)
             , Border.rounded 8
             , htmlAttribute (Html.Attributes.id "box")
             , htmlAttribute (Html.Attributes.style "background-color" "#95a5a6") -- Default gray
             ]
                ++ (case model.animations of
                        Just animationResult ->
                            CSS.getElementStyles "box" animationResult
                                |> List.map (\( prop, value ) -> htmlAttribute (Html.Attributes.style prop value))

                        Nothing ->
                            []
                   )
                ++ [ htmlAttribute
                        (Html.Attributes.style "transition"
                            (case model.animations of
                                Just _ ->
                                    "background-color 0.6s ease-in-out"

                                -- Default transition
                                Nothing ->
                                    "none"
                            )
                        )
                   , htmlAttribute (CSS.onTransitionEnd AnimationComplete)
                   ]
            )
            (el [ centerX, centerY ] (text "Color"))
        )
    ]
