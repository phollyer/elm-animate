port module ElmUI.WAAPI.Controls.Main exposing (main)

{-| Anim.Engine.WAAPI Controls Example using ElmUI - Demonstrating Web Animations API controls

This example showcases all animation control functions available in the Anim.Engine.WAAPI module:

  - animate: Start Web Animations API-based animations
  - stop: Jump to end state and stop
  - pause: Pause all animations
  - resume: Resume paused animations
  - reset: Jump to start state and stop
  - restart: Reset to start then restart animation

All controls work through JavaScript ports with the Web Animations API for native browser performance.

-}

import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Position as Position
import Browser exposing (Document)
import Common.Animations.Position as PositionAnim
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, htmlAttribute, maximum, padding, px, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Json.Decode
import Json.Encode as Encode
import Time



-- MODEL


type alias Model =
    { animationState : WAAPI.AnimState
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
        ( initialAnimState, initCmd ) =
            WAAPI.builder WAAPI.init
                |> Position.initXY elementId 50 50
                |> WAAPI.animate WAAPI.init
    in
    ( { animationState = initialAnimState
      , isAnimating = False
      , isPaused = False
      }
    , WAAPI.sendCommand waapiCommand initCmd
    )



-- UPDATE


elementId : String
elementId =
    "waapi-controls-box"


type Msg
    = Animate
    | Stop
    | Pause
    | Resume
    | Reset
    | Restart
    | WaapiEventReceived (Result String ( WAAPI.EventType, String, Encode.Value ))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WaapiEventReceived result ->
            case result of
                Ok ( WAAPI.PropertyUpdate, _, _ ) ->
                    -- Handle property updates from JavaScript if needed
                    ( model, Cmd.none )

                Ok ( WAAPI.AnimationUpdate, _, payload ) ->
                    -- Handle animation lifecycle updates
                    case Json.Decode.decodeValue (Json.Decode.field "status" Json.Decode.string) payload of
                        Ok "started" ->
                            ( { model | isAnimating = True, isPaused = False }
                            , Cmd.none
                            )

                        Ok "paused" ->
                            ( { model | isPaused = True }
                            , Cmd.none
                            )

                        Ok "resumed" ->
                            ( { model | isPaused = False }
                            , Cmd.none
                            )

                        Ok "completed" ->
                            ( { model | isAnimating = False, isPaused = False }
                            , Cmd.none
                            )

                        Ok "canceled" ->
                            ( { model | isAnimating = False, isPaused = False }
                            , Cmd.none
                            )

                        Ok "restarted" ->
                            ( { model | isAnimating = True, isPaused = False }
                            , Cmd.none
                            )

                        _ ->
                            ( model, Cmd.none )

                Err error ->
                    -- Log error but don't crash
                    let
                        _ =
                            Debug.log "WAAPI Event Decode Error" error
                    in
                    ( model, Cmd.none )

        Animate ->
            let
                ( newAnimState, animationData ) =
                    WAAPI.builder model.animationState
                        |> WAAPI.duration 2500
                        |> PositionAnim.moveToXY elementId 300 300
                        |> WAAPI.animate model.animationState
            in
            ( { model
                | animationState = newAnimState
                , isAnimating = True
                , isPaused = False
              }
            , WAAPI.sendCommand waapiCommand animationData
            )

        Stop ->
            ( { model | isAnimating = False, isPaused = False }
            , WAAPI.sendCommand waapiCommand (WAAPI.stopAnimation elementId)
            )

        Pause ->
            ( { model | isPaused = True }
            , WAAPI.sendCommand waapiCommand (WAAPI.pauseAnimation elementId)
            )

        Resume ->
            ( { model | isPaused = False }
            , WAAPI.sendCommand waapiCommand (WAAPI.resumeAnimation elementId)
            )

        Reset ->
            ( { model | isAnimating = False, isPaused = False }
            , WAAPI.sendCommand waapiCommand (WAAPI.resetAnimation elementId)
            )

        Restart ->
            let
                ( newAnimState, animationData ) =
                    WAAPI.builder model.animationState
                        |> WAAPI.duration 2500
                        |> PositionAnim.moveUp elementId
                        |> WAAPI.animate model.animationState
            in
            ( { model
                | animationState = newAnimState
                , isAnimating = True
                , isPaused = False
              }
            , WAAPI.sendCommand waapiCommand (WAAPI.restartAnimation elementId animationData)
            )



-- PORTS


{-| Outgoing port for sending animation commands to JavaScript -}
port waapiCommand : Encode.Value -> Cmd msg


{-| Incoming port for receiving events from JavaScript -}
port waapiEvent : (Encode.Value -> msg) -> Sub msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    waapiEvent (WAAPI.handleEvent WaapiEventReceived)



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.WAAPI Controls ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & WAAPI Engine Controls"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Demonstrating all Web Animations API controls with JavaScript port integration")
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
            [ ( UI.Primary, Animate, "🏀 Animate Up" )
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
            , Background.color Colors.success
            , Border.rounded 25
            , htmlAttribute (Html.Attributes.id elementId)
            , htmlAttribute (Html.Attributes.style "position" "absolute")
            ]
            (el [ centerX, centerY, Font.size 20 ] (text "🏀"))
        )
    , -- Controls explanation
      column
        [ spacing 8, width (fill |> maximum 600), centerX ]
        [ el
            [ Font.size 18, centerX, Font.medium, Font.color Colors.textDark ]
            (text "🎮 Control Functions")
        , column
            [ spacing 4, width fill ]
            [ viewControlDescription "🏀 Animate Up" "Start smooth upward movement animation"
            , viewControlDescription "⏹️ Stop" "Jump instantly to end state and stop"
            , viewControlDescription "⏸️ Pause" "Pause animation at current position"
            , viewControlDescription "▶️ Resume" "Continue paused animation"
            , viewControlDescription "⏮️ Reset" "Jump instantly to start state and stop"
            , viewControlDescription "🔄 Restart" "Reset to start, then begin animation again"
            ]
        , el
            [ Font.size 12, Font.color Colors.textLight, centerX ]
            (text "💡 WAAPI uses native browser animation performance")
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
