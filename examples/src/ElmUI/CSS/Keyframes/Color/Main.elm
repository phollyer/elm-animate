module ElmUI.CSS.Keyframes.Color.Main exposing (main)

{-| Anim.Engine.CSS Color Example using ElmUI - Element color animations with CSS keyframes

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

import Anim.Extra.Color
import Anim.Extra.Easing as Easing
import Anim.Engine.CSS.Keyframes as CSS
import Anim.Property.BackgroundColor as Color
import Browser exposing (Document)
import Common.Animations.BackgroundColor as Animations
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
    { animations : CSS.AnimState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations =
            CSS.animate (CSS.init [])
                (Color.init elementId (Anim.Extra.Color.fromRgba { r = 149, g = 165, b = 166, a = 1 }))
      }
    , Cmd.none
    )



-- UPDATE


elementId : String
elementId =
    "box"


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
                    CSS.animate model.animations
                        (Animations.changeToBlue elementId)
              }
            , Cmd.none
            )

        ChangeToGreen ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.changeToGreen elementId)
              }
            , Cmd.none
            )

        ChangeToOrange ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.changeToOrange elementId)
              }
            , Cmd.none
            )

        ChangeToRed ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.changeToRed elementId)
              }
            , Cmd.none
            )

        ChangeToPurple ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.changeToPurple elementId)
              }
            , Cmd.none
            )

        ResetColor ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.resetColor elementId)
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.CSS Color Keyframes ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ Element.html (CSS.keyframesStyleNodeFor elementId model.animations)
    , UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & CSS Keyframes Color Example"
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
            , Border.rounded 8
            , htmlAttribute (Html.Attributes.id elementId)
            , htmlAttribute (CSS.keyframeAttribute elementId model.animations)
            ]
            (el [ centerX, centerY ] (text "Color"))
        )
    ]
