module ElmUI.CSS.Keyframe.Controls.Main exposing (main)

{-| Anim.Engine.CSS Controls Example using ElmUI - Demonstrating CSS Keyframe animation controls

This example showcases all animation control functions available in the Anim.Engine.CSS module:

  - animate: Start keyframe-based animations
  - stop: Jump to end state and stop
  - pause: Pause all animations
  - resume: Resume paused animations
  - reset: Jump to start state and stop
  - restart: Reset to start then restart animation

All controls work with CSS keyframes for more complex animation sequences.

-}

import Anim.Engine.CSS.Keyframe as CSS
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
    { animations : CSS.AnimState
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
            CSS.animate (CSS.init [])
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
    "keyframes-controls-box"


type Msg
    = Animate
    | Stop
    | Pause
    | Resume
    | Reset
    | Restart


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate ->
            let
                newAnimations =
                    CSS.animate model.animations
                        (CSS.duration 3000
                            >> PositionAnim.moveRight elementId
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
                    CSS.stop elementId model.animations
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
                    CSS.pause elementId model.animations
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
                    CSS.resume elementId model.animations
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
                    CSS.reset elementId model.animations
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
                    CSS.restart elementId model.animations
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
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.CSS Keyframe Controls ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & CSS Keyframe Engine Controls"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Demonstrating all CSS keyframes animation controls with complex movement patterns")
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
            [ ( UI.Primary, Animate, "🌟 Animate Right" )
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
            ++ List.map htmlAttribute (CSS.attributes elementId model.animations)
        )
        (el
            [ width (px 50)
            , height (px 50)
            , Background.color Colors.purple
            , Border.rounded 25
            , htmlAttribute (Html.Attributes.id elementId)
            , htmlAttribute (Html.Attributes.style "position" "absolute")
            ]
            (el [ centerX, centerY, Font.size 20 ] (text "⚫"))
        )
    ]