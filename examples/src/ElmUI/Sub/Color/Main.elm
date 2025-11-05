module ElmUI.Sub.Color.Main exposing (main)

{-| Anim.Sub Color Example using ElmUI - Background color transition animations

This example demonstrates smooth color transitions using browser-native Subscription-Based animations.
Perfect for theme changes, state indicators, and dynamic color feedback.

FEATURES:

  - ✅ Smooth background color transitions
  - ✅ Hardware-accelerated color interpolation
  - ✅ Multiple color formats (hex, rgb, hsl)
  - ✅ Theme switching and state changes
  - ✅ Battery efficient browser-native transitions

-}

import Anim exposing (ColorValue(..), defaultConfig)
import Anim.Sub exposing (Model, animateBackgroundColor, init, step, styleProperties, subscriptions)
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
    { animations : Anim.Sub.Model
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.Sub.init
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
    | AnimationFrame Float



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeToBlue ->
            ( { model
                | animations = animateBackgroundColor "box" (Hex "#3498db") model.animations
              }
            , Cmd.none
            )

        ChangeToGreen ->
            ( { model
                | animations = animateBackgroundColor "box" (Hex "#2ecc71") model.animations
              }
            , Cmd.none
            )

        ChangeToOrange ->
            ( { model
                | animations = animateBackgroundColor "box" (Hex "#f39c12") model.animations
              }
            , Cmd.none
            )

        ChangeToRed ->
            ( { model
                | animations = animateBackgroundColor "box" (Hex "#e74c3c") model.animations
              }
            , Cmd.none
            )

        ChangeToPurple ->
            ( { model
                | animations = animateBackgroundColor "box" (Hex "#9b59b6") model.animations
              }
            , Cmd.none
            )

        ResetColor ->
            ( { model
                | animations = animateBackgroundColor "box" (Hex "#95a5a6") model.animations
              }
            , Cmd.none
            )

        AnimationFrame deltaTime ->
            ( { model | animations = step deltaTime model.animations }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Anim.Sub.subscriptions AnimationFrame model.animations



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Sub Color ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "Subscription-Based Color Animations"
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
                ++ (styleProperties "box" model.animations
                        |> List.map (\( prop, value ) -> htmlAttribute (Html.Attributes.style prop value))
                   )
            )
            (el [ centerX, centerY ] (text "Color"))
        )
    ]
