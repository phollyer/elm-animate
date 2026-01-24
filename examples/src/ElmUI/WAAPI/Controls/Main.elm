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
port waapiEvent : (Encode.Value -> msg) -> Sub msg



-- MODEL


type AnimationStatus
    = Idle
    | Running
    | Paused


type alias Model =
    { animationState : WAAPI.AnimState
    , status : AnimationStatus
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
            WAAPI.initProperties waapiCommand <|
                [ Controls.init animationAreaWidth ]
    in
    ( { animationState = initialAnimState
      , status = Idle
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
    | WaapiEventReceived ( WAAPI.AnimState, Maybe WAAPI.AnimationEvent )
    | OnResize Int Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnResize newWidth newHeight ->
            let
                newAnimationAreaWidth =
                    min 500 (newWidth - 40)

                oldAnimationAreaWidth =
                    model.animationAreaSize.width

                -- Use WAAPI.onResize to handle repositioning
                ( newAnimState, resizeCmd ) =
                    WAAPI.onResize
                        [ { elementId = elementId
                          , elementSize = { width = 50, height = 50 }
                          , oldContainerSize =
                                { width = oldAnimationAreaWidth
                                , height = 350
                                }
                          , newContainerSize =
                                { width = newAnimationAreaWidth
                                , height = 350
                                }
                          }
                        ]
                        waapiCommand
                        model.animationState
            in
            ( { model
                | window = { width = newWidth, height = newHeight }
                , animationAreaSize =
                    { width = newAnimationAreaWidth |> Debug.log "New animation area width"
                    , height = 350
                    }
                , animationState = newAnimState
              }
            , resizeCmd
            )

        WaapiEventReceived ( newAnimState, maybeEvent ) ->
            let
                newModel =
                    { model | animationState = newAnimState }
            in
            case maybeEvent of
                Just event ->
                    -- Animation lifecycle event - update local status flags
                    handleAnimationEvent event newModel

                Nothing ->
                    ( newModel, Cmd.none )

        Animate ->
            let
                ( newAnimState, animCmd ) =
                    WAAPI.animate waapiCommand model.animationState Controls.animate
            in
            ( { model | animationState = newAnimState }
            , animCmd
            )

        Stop ->
            ( model
            , WAAPI.stop elementId waapiCommand
            )

        Pause ->
            ( model
            , WAAPI.pause elementId waapiCommand
            )

        Resume ->
            ( model
            , WAAPI.resume elementId waapiCommand
            )

        Reset ->
            let
                ( newAnimState, resetCmd ) =
                    WAAPI.reset elementId waapiCommand model.animationState
            in
            ( { model | animationState = newAnimState }
            , resetCmd
            )

        Restart ->
            let
                ( newAnimState, restartCmd ) =
                    WAAPI.restart elementId waapiCommand model.animationState
            in
            ( { model | animationState = newAnimState }
            , restartCmd
            )


handleAnimationEvent : WAAPI.AnimationEvent -> Model -> ( Model, Cmd Msg )
handleAnimationEvent event model =
    case event of
        WAAPI.Started ->
            ( { model | status = Running }, Cmd.none )

        WAAPI.Restarted ->
            ( { model | status = Running }, Cmd.none )

        WAAPI.Canceled ->
            ( { model | status = Idle }, Cmd.none )

        WAAPI.Completed ->
            ( { model | status = Idle }, Cmd.none )

        WAAPI.Paused ->
            ( { model | status = Paused }, Cmd.none )

        WAAPI.Resumed ->
            ( { model | status = Running }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ waapiEvent (WaapiEventReceived << WAAPI.decode model.animationState)
        , onResize OnResize
        ]



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
        currentTranslate =
            WAAPI.getCurrentTranslate elementId model.animationState

        centerX_expected =
            toFloat model.animationAreaSize.width / 2 - 25

        translateText =
            case currentTranslate of
                Just pos ->
                    "x=" ++ String.fromFloat pos.x ++ ", y=" ++ String.fromFloat pos.y

                Nothing ->
                    "Not found!"
    in
    [ UI.backButton
    , UI.pageHeader "WAAPI Engine Controls"
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
            px model.animationAreaSize.width
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
        , inFront <|
            el
                [ width (px 1)
                , height fill
                , Border.width 1
                , Border.color Colors.borderLight
                , centerX
                ]
            <|
                el
                    [ centerX ]
                    (text <|
                        ((toFloat model.animationAreaSize.width / 2)
                            |> String.fromFloat
                        )
                    )
        ]
        (el
            [ width (px 50)
            , height (px 50)
            , htmlAttribute (Html.Attributes.style "transform" ("translateX(" ++ String.fromFloat ((toFloat model.animationAreaSize.width / 2) - 25) ++ "px) translateY(50px)"))
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
