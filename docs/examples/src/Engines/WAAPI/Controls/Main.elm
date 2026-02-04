port module Engines.WAAPI.Controls.Main exposing (main)

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
import Browser.Events exposing (onResize)
import Common.Animations.Controls as Controls exposing (elementId)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, explain, fill, height, html, htmlAttribute, inFront, maximum, none, padding, paddingEach, paragraph, px, row, spacing, text, width)
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
port waapiSubscriptions : (Encode.Value -> msg) -> Sub msg



-- MODEL


type AnimationStatus
    = Idle
    | Running
    | Paused


type alias Model =
    { animState : WAAPI.AnimState Msg
    , status : AnimationStatus
    , animAreaSize : { width : Int, height : Int }
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
        animAreaWidth =
            min 500 (window.width - 40)

        ( initialAnimState, initCmd ) =
            WAAPI.init waapiCommand waapiSubscriptions <|
                [ Controls.init animAreaWidth ]
    in
    ( { animState = initialAnimState
      , status = Idle
      , animAreaSize =
            { width = animAreaWidth
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
    | GotWaapiMsg WAAPI.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotWaapiMsg subMsg ->
            let
                ( newAnimState, events ) =
                    WAAPI.update subMsg model.animState
            in
            handleAnimationEvents events { model | animState = newAnimState }

        Animate ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate model.animState Controls.animate
            in
            ( { model | animState = newAnimState }
            , animCmd
            )

        -- --8<-- [start:stop]
        Stop ->
            let
                ( newAnimState, stopCmd ) =
                    WAAPI.stop elementId model.animState
            in
            ( { model | animState = newAnimState }
            , stopCmd
            )

        -- --8<-- [end:stop]
        -- --8<-- [start:pause]
        Pause ->
            let
                ( newAnimState, pauseCmd ) =
                    WAAPI.pause elementId model.animState
            in
            ( { model | animState = newAnimState }
            , pauseCmd
            )

        -- --8<-- [end:pause]
        -- --8<-- [start:resume]
        Resume ->
            let
                ( newAnimState, resumeCmd ) =
                    WAAPI.resume elementId model.animState
            in
            ( { model | animState = newAnimState }
            , resumeCmd
            )

        -- --8<-- [end:resume]
        -- --8<-- [start:reset]
        Reset ->
            let
                ( newAnimState, resetCmd ) =
                    WAAPI.reset elementId model.animState
            in
            ( { model | animState = newAnimState }
            , resetCmd
            )

        -- --8<-- [end:reset]
        -- --8<-- [start:restart]
        Restart ->
            let
                ( newAnimState, restartCmd ) =
                    WAAPI.restart elementId model.animState
            in
            ( { model | animState = newAnimState }
            , restartCmd
            )



-- --8<-- [end:restart]
-- --8<-- [start:handleAnimationEvent]


handleAnimationEvents : List WAAPI.AnimationEvent -> Model -> ( Model, Cmd Msg )
handleAnimationEvents events model =
    List.foldl handleSingleEvent ( model, Cmd.none ) events


handleSingleEvent : WAAPI.AnimationEvent -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
handleSingleEvent event ( model, cmd ) =
    case event of
        WAAPI.Started _ ->
            ( { model | status = Running }, cmd )

        WAAPI.Restarted _ ->
            ( { model | status = Running }, cmd )

        WAAPI.Canceled _ ->
            ( { model | status = Idle }, cmd )

        WAAPI.Completed _ ->
            ( { model | status = Idle }, cmd )

        WAAPI.Paused _ ->
            ( { model | status = Paused }, cmd )

        WAAPI.Resumed _ ->
            ( { model | status = Running }, cmd )



-- --8<-- [end:handleAnimationEvent]
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.WAAPI Controls ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.pageHeader "WAAPI Engine Controls"
    , paragraph
        [ width fill
        , Font.size 16
        , Font.color Colors.textMedium
        , Font.center
        ]
        [ text "Demonstrating all available Engine Controls" ]
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
        [ width <|
            px model.animAreaSize.width
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
        ]
        (el
            [ width (px 50)
            , height (px 50)
            , htmlAttribute (Html.Attributes.id elementId)
            , htmlAttribute (Html.Attributes.style "position" "relative")
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
    UI.htmlButton
        >> html
        >> el [ centerX ]


statusToString : AnimationStatus -> String
statusToString status =
    case status of
        Idle ->
            "Idle"

        Running ->
            "Running"

        Paused ->
            "Paused"
