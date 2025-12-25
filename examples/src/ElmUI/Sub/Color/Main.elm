module ElmUI.Sub.Color.Main exposing (main)

{-| Anim.Engine.Sub Color Example using ElmUI - Background color transition animations

This example demonstrates smooth color transitions using browser-native Subscription-Based animations.
Perfect for theme changes, state indicators, and dynamic color feedback.

FEATURES:

  - ✅ Smooth background color transitions
  - ✅ Hardware-accelerated color interpolation
  - ✅ Multiple color formats (hex, rgb, hsl)
  - ✅ Theme switching and state changes
  - ✅ Battery efficient browser-native transitions

-}

import Anim.Engine.Sub as Sub
import Anim.Properties.BackgroundColor as ColorBuilder exposing (Color(..))
import Anim.Timing.Easing as Easing exposing (Easing(..))
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
    { animations : Sub.AnimState
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations =
            Sub.init
                |> Sub.builder
                |> ColorBuilder.for "box"
                |> ColorBuilder.to (Rgb { r = 149, g = 165, b = 166 })
                -- Default gray
                |> ColorBuilder.duration 0
                |> ColorBuilder.easing Easing.EaseInOut
                |> ColorBuilder.build
                |> Sub.animate
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
    | AnimationMsg Sub.AnimationMsg



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeToBlue ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> ColorBuilder.for "box"
                        |> ColorBuilder.to (Rgb { r = 52, g = 152, b = 219 })
                        |> ColorBuilder.duration 1000
                        |> ColorBuilder.easing Easing.EaseInOut
                        |> ColorBuilder.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        ChangeToGreen ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> ColorBuilder.for "box"
                        |> ColorBuilder.to (Rgb { r = 46, g = 204, b = 113 })
                        |> ColorBuilder.duration 1000
                        |> ColorBuilder.easing Easing.EaseInOut
                        |> ColorBuilder.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        ChangeToOrange ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> ColorBuilder.for "box"
                        |> ColorBuilder.to (Rgb { r = 243, g = 156, b = 18 })
                        |> ColorBuilder.duration 1000
                        |> ColorBuilder.easing Easing.EaseInOut
                        |> ColorBuilder.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        ChangeToRed ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> ColorBuilder.for "box"
                        |> ColorBuilder.to (Rgb { r = 231, g = 76, b = 60 })
                        |> ColorBuilder.duration 1000
                        |> ColorBuilder.easing Easing.EaseInOut
                        |> ColorBuilder.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        ChangeToPurple ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> ColorBuilder.for "box"
                        |> ColorBuilder.to (Rgb { r = 155, g = 89, b = 182 })
                        |> ColorBuilder.duration 1000
                        |> ColorBuilder.easing Easing.EaseInOut
                        |> ColorBuilder.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        ResetColor ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> ColorBuilder.for "box"
                        |> ColorBuilder.to (Rgb { r = 149, g = 165, b = 166 })
                        |> ColorBuilder.duration 1000
                        |> ColorBuilder.easing Easing.EaseInOut
                        |> ColorBuilder.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        AnimationMsg animMsg ->
            ( { model | animations = Sub.update animMsg model.animations }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map AnimationMsg (Sub.subscriptions model.animations)



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.Sub Color ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Subscription Color Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth color transitions using browser-native Subscription-Based animations")
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
                ++ (Sub.htmlAttributes "box" model.animations
                        |> List.map htmlAttribute
                   )
            )
            (el [ centerX, centerY ] (text "Color"))
        )
    ]
