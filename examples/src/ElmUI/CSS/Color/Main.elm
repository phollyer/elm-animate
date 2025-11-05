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

import Anim exposing (ColorValue(..))
import Anim.CSS exposing (Model, animate, init, onTransitionEnd, styleProperties, transitionStyles)
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
    { animations : Anim.CSS.Model
    , activeAnimation : Maybe Anim.Animation
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.CSS.init
      , activeAnimation = Nothing
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
                animation =
                    Anim.backgroundColor "box" (Hex "#3498db")
                        |> Anim.backgroundColorDuration 600
                        |> Anim.easeInOut
            in
            ( { model
                | animations = animate animation model.animations
                , activeAnimation = Just animation
              }
            , Cmd.none
            )

        ChangeToGreen ->
            let
                animation =
                    Anim.backgroundColor "box" (Hex "#2ecc71")
                        |> Anim.backgroundColorDuration 600
                        |> Anim.easeInOut
            in
            ( { model
                | animations = animate animation model.animations
                , activeAnimation = Just animation
              }
            , Cmd.none
            )

        ChangeToOrange ->
            let
                animation =
                    Anim.backgroundColor "box" (Hex "#f39c12")
                        |> Anim.backgroundColorDuration 600
                        |> Anim.easeInOut
            in
            ( { model
                | animations = animate animation model.animations
                , activeAnimation = Just animation
              }
            , Cmd.none
            )

        ChangeToRed ->
            let
                animation =
                    Anim.backgroundColor "box" (Hex "#e74c3c")
                        |> Anim.backgroundColorDuration 600
                        |> Anim.easeInOut
            in
            ( { model
                | animations = animate animation model.animations
                , activeAnimation = Just animation
              }
            , Cmd.none
            )

        ChangeToPurple ->
            let
                animation =
                    Anim.backgroundColor "box" (Hex "#9b59b6")
                        |> Anim.backgroundColorDuration 600
                        |> Anim.easeInOut
            in
            ( { model
                | animations = animate animation model.animations
                , activeAnimation = Just animation
              }
            , Cmd.none
            )

        ResetColor ->
            let
                animation =
                    Anim.backgroundColor "box" (Hex "#95a5a6")
                        |> Anim.backgroundColorDuration 600
                        |> Anim.easeInOut
            in
            ( { model
                | animations = animate animation model.animations
                , activeAnimation = Just animation
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( { model | activeAnimation = Nothing }, Cmd.none )



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
                ++ (styleProperties "box" model.animations
                        |> List.map (\( prop, value ) -> htmlAttribute (Html.Attributes.style prop value))
                   )
                ++ [ htmlAttribute
                        (Html.Attributes.style "transition"
                            (case model.activeAnimation of
                                Just animation ->
                                    transitionStyles animation

                                Nothing ->
                                    "none"
                            )
                        )
                   , htmlAttribute (onTransitionEnd AnimationComplete)
                   ]
            )
            (el [ centerX, centerY ] (text "Color"))
        )
    ]
