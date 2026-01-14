port module ElmUI.WAAPI.Controls.Main exposing (main)

{-| Anim.Engine.WAAPI Controls Example using ElmUI - Demonstrating Animation controls

This example showcases all animation control functions available in the Anim.Engine.WAAPI module:

  - animate: Start Web Animations API-based animations
  - stop: Jump to end state and stop
  - pause: Pause animations
  - resume: Resume paused animations
  - reset: Jump to start state and stop
  - restart: Reset to start then play animation

-}

import Anim.Engine.WAAPI as WAAPI
import Browser exposing (Document)
import Common.Animations.AnimationControls as ControlsAnim exposing (elementId)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, html, htmlAttribute, maximum, padding, paddingEach, paragraph, px, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Json.Encode as Encode
import Time



-- PORTS


{-| Outgoing port for sending animation commands to JavaScript
-}
port waapiCommand : Encode.Value -> Cmd msg


{-| Incoming port for receiving events from JavaScript
-}
port waapiEvent : (Encode.Value -> msg) -> Sub msg



-- MODEL


type alias Model =
    { animationState : WAAPI.AnimState
    , isAnimating : Bool
    , isPaused : Bool
    , window : { width : Int, height : Int }
    , animationAreaSize : { width : Int, height : Int }
    }



-- MAIN


main : Program { window : { width : Int, height : Int } } Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- INIT


init : { window : { width : Int, height : Int } } -> ( Model, Cmd Msg )
init { window } =
    let
        animationAreaWidth =
            min 500 (window.width - 40)

        ( initialAnimState, initCmd ) =
            WAAPI.animate waapiCommand WAAPI.init <|
                ControlsAnim.init animationAreaWidth
    in
    ( { animationState = initialAnimState
      , isAnimating = False
      , isPaused = False
      , window = window
      , animationAreaSize =
            { width = animationAreaWidth
            , height = 350
            }
      }
    , initCmd
    )



-- UPDATE


type Msg
    = Animate
    | Stop
    | Pause
    | Resume
    | Reset
    | Restart
    | WaapiEventReceived WAAPI.EventType WAAPI.AnimState


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate waapiCommand model.animationState ControlsAnim.animate
            in
            ( { model | animationState = newAnimState }
            , animCmd
            )

        WaapiEventReceived eventType newAnimState ->
            let
                newModel =
                    { model | animationState = newAnimState }
            in
            case eventType of
                WAAPI.PropertyUpdate _ ->
                    -- Property data automatically applied to newAnimState
                    -- If you don't need to react to property updates, you can ignore this event
                    ( newModel, Cmd.none )

                WAAPI.AnimationUpdate animationStatus ->
                    -- Animation status with automatically updated AnimState
                    -- This is only required to update isAnimating / isPaused flags in the model
                    -- If you don't need to react to animation status changes, you can ignore this event
                    handleAnimationUpdate animationStatus newModel

        Stop ->
            ( model
            , WAAPI.stopAnimation elementId waapiCommand
            )

        Pause ->
            ( model
            , WAAPI.pauseAnimation elementId waapiCommand
            )

        Resume ->
            ( model
            , WAAPI.resumeAnimation elementId waapiCommand
            )

        Reset ->
            let
                ( newAnimState, resetCmd ) =
                    WAAPI.resetAnimation elementId waapiCommand model.animationState
            in
            ( { model | animationState = newAnimState }
            , resetCmd
            )

        Restart ->
            let
                ( newAnimState, restartCmd ) =
                    WAAPI.restartAnimation elementId waapiCommand model.animationState
            in
            ( { model | animationState = newAnimState }
            , restartCmd
            )


handleAnimationUpdate : WAAPI.AnimationStatus -> Model -> ( Model, Cmd Msg )
handleAnimationUpdate status model =
    case status of
        WAAPI.Started ->
            ( { model | isAnimating = True, isPaused = False }, Cmd.none )

        WAAPI.Restarted ->
            ( { model | isAnimating = True, isPaused = False }, Cmd.none )

        WAAPI.Canceled ->
            ( { model | isAnimating = False, isPaused = False }, Cmd.none )

        WAAPI.Completed ->
            ( { model | isAnimating = False, isPaused = False }, Cmd.none )

        WAAPI.Paused ->
            ( { model | isPaused = True }, Cmd.none )

        WAAPI.Resumed ->
            ( { model | isPaused = False }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    waapiEvent (WAAPI.handleEventWithState WaapiEventReceived model.animationState)



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.WAAPI Controls ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        currentPosition =
            WAAPI.getCurrentPosition elementId model.animationState
    in
    [ UI.backButton
    , UI.pageHeader "ElmUI & WAAPI Engine Controls"
    , paragraph
        [ width fill
        , Font.size 14
        , Font.color Colors.textMedium
        , Font.center
        ]
        [ text <|
            case currentPosition of
                Just { x, y, z } ->
                    "Current Position: x="
                        ++ String.fromFloat x
                        ++ ", y="
                        ++ String.fromFloat y
                        ++ ", z="
                        ++ String.fromFloat z

                Nothing ->
                    "Current Position: Unknown"
        ]
    , paragraph
        [ width fill
        , Font.size 16
        , Font.color Colors.textMedium
        , Font.center
        ]
        [ text "Demonstrating all Web Animations API controls with JavaScript port integration" ]
    , -- Controls explanation
      column
        [ centerX
        , Border.width 1
        , Border.color Colors.borderMedium
        , Border.shadow
            { offset = ( 0, 2 )
            , size = 2
            , blur = 4
            , color = Element.rgba 0 0 0 0.1
            }
        , Background.color Colors.backgroundLight
        , Border.rounded 8
        ]
        [ el
            [ width fill
            , Border.widthEach
                { top = 0
                , right = 0
                , bottom = 1
                , left = 0
                }
            ]
          <|
            el
                [ Font.size 18
                , padding 8
                , centerX
                , Font.medium
                , Font.color Colors.textDark
                ]
                (text "🎮 Control Functions")
        , column
            [ width fill ]
            [ viewControlDescription 0 "🏀 Animate" "Drop the ball"
            , viewControlDescription 1 "⏹️ Stop" "Jump instantly to end state and stop"
            , viewControlDescription 1 "⏸️ Pause" "Pause animation at current position"
            , viewControlDescription 1 "▶️ Resume" "Continue paused animation"
            , viewControlDescription 1 "⏮️ Reset" "Jump instantly to start state and stop"
            , viewControlDescription 1 "🔄 Restart" "Reset to start, then begin animation again"
            ]
        ]
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
      row
        [ spacing 12, centerX ]
        [ buttons
            [ ( UI.Primary, Animate, "🏀 Animate" )
            , ( UI.Warning, Stop, "⏹️ Stop" )
            ]
        , buttons
            [ ( UI.Success, Pause, "⏸️ Pause" )
            , ( UI.Success, Resume, "▶️ Resume" )
            ]
        , buttons
            [ ( UI.Purple, Reset, "⏮️ Reset" )
            , ( UI.Purple, Restart, "🔄 Restart" )
            ]
        ]
    , -- Animation area
      el
        [ width (fill |> maximum 500)
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
            [ width (px 50)
            , height (px 50)
            , htmlAttribute (Html.Attributes.id elementId)
            , htmlAttribute (Html.Attributes.style "position" "absolute")
            ]
            (el [ centerX, centerY, Font.size 50 ] (text "🏀"))
        )
    ]


viewControlDescription : Int -> String -> String -> Element Msg
viewControlDescription borderWidth control description =
    row
        [ width fill
        , Border.widthEach
            { top = borderWidth
            , right = 0
            , bottom = 0
            , left = 0
            }
        , padding 4
        ]
        [ el
            [ Font.size 14
            , Font.medium
            , Font.color Colors.primary
            , width (px 80)
            ]
            (text control)
        , el
            [ Font.size 14
            , Font.color Colors.textMedium
            ]
            (text description)
        ]


buttons : List ( UI.ButtonStyle, Msg, String ) -> Element Msg
buttons =
    column [ spacing 12 ] << List.map button


button : ( UI.ButtonStyle, msg, String ) -> Element msg
button =
    el [ centerX ]
        << html
        << UI.htmlButton
