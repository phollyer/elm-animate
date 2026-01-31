module ElmUI.CSS.Transitions.Color.Main exposing (main)

{-| Anim.Engine.CSS Color Example using ElmUI - Background color transition animations

This example demonstrates smooth color transitions using browser-native CSS animations.
Perfect for theme changes, state indicators, and dynamic color feedback.

FEATURES:

  - ✅ Smooth background color transitions
  - ✅ Hardware-accelerated color interpolation
  - ✅ Multiple color formats (hex, rgb, hsl)
  - ✅ Theme switching and state changes
  - ✅ Battery efficient browser-native transitions

-}

import Anim.Color
import Anim.Easing as Easing
import Anim.Engine.CSS as CSS
import Anim.Property.BackgroundColor as Color
import Browser exposing (Document)
import Common.Animations.BackgroundColor as Animations
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
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { animations : CSS.AnimState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations =
            CSS.animate CSS.init
                (Color.init "animated-box" (Anim.Color.fromRgba { r = 200, g = 200, b = 200, a = 1 }))
      }
    , Cmd.none
    )



-- UPDATE


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
                        (Animations.changeToBlue "box")
              }
            , Cmd.none
            )

        ChangeToGreen ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.changeToGreen "box")
              }
            , Cmd.none
            )

        ChangeToOrange ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.changeToOrange "box")
              }
            , Cmd.none
            )

        ChangeToRed ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.changeToRed "box")
              }
            , Cmd.none
            )

        ChangeToPurple ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.changeToPurple "box")
              }
            , Cmd.none
            )

        ResetColor ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.resetColor "box")
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.CSS Color ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & CSS Transitions Color Example"
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
             , htmlAttribute (CSS.onTransitionEnd AnimationComplete)
             ]
                -- Apply CSS styles for the animation
                ++ List.map htmlAttribute (CSS.htmlAttributes "box" model.animations)
            )
            (el [ centerX, centerY ] (text "Color"))
        )
    ]
