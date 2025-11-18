module ElmUI.CSS.Keyframes.Color.Main exposing (main)

{-| Anim.CSS Color Example using ElmUI - Element color animations with CSS keyframes

This example demonstrates smooth color animations using browser-native CSS keyframes.
Perfect for changing element colors with hardware acceleration and precise timing control.

FEATURES:

  - ✅ Smooth color transitions using CSS keyframes
  - ✅ Multiple predefined color targets
  - ✅ Hardware-accelerated CSS color animations
  - ✅ Instant visual feedback and state tracking
  - ✅ Complex animation composition and timing

USAGE:

  - Use animateToColor for color changes
  - Colors are defined using standard CSS color values
  - Keyframes provide precise control over animation timing and composition
  - Browser handles all color interpolation automatically

-}

import Anim exposing (AnimBuilder)
import Anim.CSS as CSS
import Anim.Properties.Color as Color exposing (Color(..))
import Anim.Timing.Easing as Easing
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
import Html.Attributes



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { animations : CSS.AnimationState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = CSS.init }
    , Cmd.none
    )



-- UPDATE


toColorBuilderWithDefaults : CSS.AnimationState -> Color.Builder
toColorBuilderWithDefaults =
    CSS.builder
        -- Set default animation parameters
        >> Anim.duration 1000
        >> Anim.easing Easing.Linear
        -- Start configuring color animation for the element
        >> Color.for "box"


type Msg
    = ChangeToBlue
    | ChangeToGreen
    | ChangeToOrange
    | ChangeToRed
    | ChangeToPurple
    | ResetColor
    | AnimationComplete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeToBlue ->
            ( { model
                | animations =
                    model.animations
                        |> toColorBuilderWithDefaults
                        |> Color.to (Color.Hex "#3498db")
                        |> Color.duration 2000
                        |> Color.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        ChangeToGreen ->
            ( { model
                | animations =
                    model.animations
                        |> toColorBuilderWithDefaults
                        |> Color.to (Color.Hex "#2ecc71")
                        |> Color.speed 25
                        --|> Color.easing Easing.BackInOut
                        |> Color.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        ChangeToOrange ->
            ( { model
                | animations =
                    model.animations
                        |> toColorBuilderWithDefaults
                        |> Color.to (Color.Hex "#f39c12")
                        |> Color.easing Easing.ElasticOut
                        |> Color.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        ChangeToRed ->
            ( { model
                | animations =
                    model.animations
                        |> toColorBuilderWithDefaults
                        |> Color.to (Color.Hex "#e74c3c")
                        |> Color.easing Easing.BounceOut
                        |> Color.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        ChangeToPurple ->
            ( { model
                | animations =
                    model.animations
                        |> toColorBuilderWithDefaults
                        |> Color.to (Color.Hex "#9b59b6")
                        |> Color.easing Easing.CubicInOut
                        |> Color.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        ResetColor ->
            ( { model
                | animations =
                    model.animations
                        |> toColorBuilderWithDefaults
                        |> Color.to (Color.Hex "#95a5a6")
                        |> Color.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.CSS Color Keyframes ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ Element.html (CSS.keyframesStyleNodeFor "box" model.animations)
    , UI.backButtonWithPath "../../../index.html"
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
            [ centerX
            , centerY
            , width (px 150)
            , height (px 150)
            , Background.color (rgb 0.8 0.8 0.8)
            , Border.rounded 8
            , htmlAttribute (Html.Attributes.id "colorBox")
            ]
            (el [ centerX, centerY ] (text "Color"))
        )
    ]
