module ElmUI.Sub.Controls.Main exposing (main)

{-| Anim.Engine.Sub Controls Example using ElmUI - Demonstrating subscription-based animation controls

This example showcases all animation control functions available in the Anim.Engine.Sub module:

  - animate: Start subscription-based animations
  - stop: Jump to end state and stop
  - pause: Pause all animations
  - resume: Resume paused animations
  - reset: Jump to start state and stop
  - restart: Reset to start then restart animation

All controls work with frame-rate independent subscription-based animations.

-}

import Anim.Engine.Sub as Sub
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.Animations.Translate as PositionAnim
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, htmlAttribute, maximum, padding, px, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Time



-- MODEL


type alias Model =
    { animations : Sub.AnimState
    , isAnimating : Bool
    , isPaused : Bool
    }



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        initialAnimations =
            Sub.animate Sub.init
                (Translate.initXY elementId 50 50)
    in
    ( { animations = initialAnimations
      , isAnimating = False
      , isPaused = False
      }
    , Cmd.none
    )



-- UPDATE


elementId : String
elementId =
    "sub-controls-box"


type Msg
    = Animate
    | Stop
    | Pause
    | Resume
    | Reset
    | Restart
    | AnimationMsg Sub.AnimationMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimationMsg subMsg ->
            ( { model | animations = Sub.update subMsg model.animations }
            , Cmd.none
            )

        Animate ->
            let
                newAnimations =
                    Sub.animate model.animations
                        (Sub.duration 2000
                            >> PositionAnim.moveDown elementId
                        )
            in
            ( { model
                | animations = newAnimations
                , isAnimating = True
                , isPaused = False
              }
            , Cmd.none
            )

        Stop ->
            let
                newAnimations =
                    Sub.stop elementId model.animations
            in
            ( { model
                | animations = newAnimations
                , isAnimating = False
                , isPaused = False
              }
            , Cmd.none
            )

        Pause ->
            let
                newAnimations =
                    Sub.pause elementId model.animations
            in
            ( { model
                | animations = newAnimations
                , isPaused = True
              }
            , Cmd.none
            )

        Resume ->
            let
                newAnimations =
                    Sub.resume elementId model.animations
            in
            ( { model
                | animations = newAnimations
                , isPaused = False
              }
            , Cmd.none
            )

        Reset ->
            let
                newAnimations =
                    Sub.reset elementId model.animations
            in
            ( { model
                | animations = newAnimations
                , isAnimating = False
                , isPaused = False
              }
            , Cmd.none
            )

        Restart ->
            let
                newAnimations =
                    Sub.restart elementId model.animations
            in
            ( { model
                | animations = newAnimations
                , isAnimating = True
                , isPaused = False
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions AnimationMsg model.animations



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.Sub Controls ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & Subscription Engine Controls"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Demonstrating all subscription-based animation controls with frame-rate independence")
    , -- Current status display
      column
        [ spacing 8, centerX ]
        [ el
            [ Font.size 14
            , Font.color
                (if model.isPaused then
                    Colors.warning

                 else if model.isAnimating then
                    Colors.primary

                 else
                    Colors.success
                )
            , centerX
            , Font.medium
            ]
            (text
                (if model.isPaused then
                    "⏸️ Paused"

                 else if model.isAnimating then
                    "🎬 Animating..."

                 else
                    "✅ Idle"
                )
            )
        ]
    , -- Control buttons
      column
        [ spacing 12, centerX ]
        [ UI.wrappedButtonRow
            [ ( UI.Primary, Animate, "🌪️ Animate Down" )
            , ( UI.Warning, Stop, "⏹️ Stop" )
            ]
        , UI.wrappedButtonRow
            [ ( UI.Success, Pause, "⏸️ Pause" )
            , ( UI.Success, Resume, "▶️ Resume" )
            ]
        , UI.wrappedButtonRow
            [ ( UI.Purple, Reset, "⏮️ Reset" )
            , ( UI.Purple, Restart, "🔄 Restart" )
            ]
        ]
    , -- Animation area with moving box
      el
        ([ width (fill |> maximum 500)
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
            ++ List.map htmlAttribute (Sub.htmlAttributes elementId model.animations)
        )
        (el
            [ width (px 50)
            , height (px 50)
            , Background.color Colors.warning
            , Border.rounded 8
            , htmlAttribute (Html.Attributes.id elementId)
            , htmlAttribute (Html.Attributes.style "position" "absolute")
            ]
            (el [ centerX, centerY, Font.size 20 ] (text "🌟"))
        )
    , -- Controls explanation
      column
        [ spacing 8, width (fill |> maximum 600), centerX ]
        [ el
            [ Font.size 18, centerX, Font.medium, Font.color Colors.textDark ]
            (text "🎮 Control Functions")
        , column
            [ spacing 4, width fill ]
            [ viewControlDescription "🌪️ Animate Down" "Start smooth downward movement animation"
            , viewControlDescription "⏹️ Stop" "Jump instantly to end state and stop"
            , viewControlDescription "⏸️ Pause" "Pause animation at current position"
            , viewControlDescription "▶️ Resume" "Continue paused animation"
            , viewControlDescription "⏮️ Reset" "Jump instantly to start state and stop"
            , viewControlDescription "🔄 Restart" "Reset to start, then begin animation again"
            ]
        , el
            [ Font.size 12, Font.color Colors.textLight, centerX ]
            (text "💡 Subscription-based animations are frame-rate independent")
        ]
    ]


viewControlDescription : String -> String -> Element Msg
viewControlDescription control description =
    Element.row
        [ spacing 8, width fill ]
        [ el
            [ Font.size 14, Font.medium, Font.color Colors.primary, width (px 120) ]
            (text control)
        , el
            [ Font.size 14, Font.color Colors.textMedium ]
            (text description)
        ]
