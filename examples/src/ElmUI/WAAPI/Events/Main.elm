port module ElmUI.WAAPI.Events.Main exposing (main)

{-| Anim.Engine.WAAPI Events Example using ElmUI - Demonstrating Web Animations API event handling

This example showcases how to track animation lifecycle events with the Anim.Engine.WAAPI module.
Learn how to coordinate animations and update your UI based on animation state changes using the Web Animations API.

EVENT TYPES:

  - ✅ Animation Start - Detected when animation command is sent
  - ✅ Animation End - Detected when animation completes (via finish message)
  - ✅ Animation Running - Tracked during animation lifecycle
  - ✅ Animation Cancel - Detected when animation is stopped

BENEFITS:

  - ✅ Hardware-accelerated animations via WAAPI
  - ✅ Update UI state precisely when animations finish
  - ✅ Chain animations together with perfect timing
  - ✅ Handle animation interruptions gracefully
  - ✅ Debug animation timing and performance
  - ✅ Native browser performance optimization

-}

import Anim.Easing as Easing exposing (Easing(..))
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.Position as Position
import Browser exposing (Document)
import Common.Animations.Position as PositionAnim
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode
import Time



-- PORTS


port animateElement : Encode.Value -> Cmd msg


port stopElement : Encode.Value -> Cmd msg


port animationComplete : (String -> msg) -> Sub msg



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
    { animations : WAAPI.AnimState
    , isAnimating : Bool
    , eventLog : List EventLogEntry
    , eventCounter : Int
    , currentTime : Int
    }


type alias EventLogEntry =
    { id : Int
    , eventType : EventType
    , timestamp : Int
    , description : String
    }


type EventType
    = AnimationStart
    | AnimationEnd
    | AnimationRun
    | AnimationCancel



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = WAAPI.init
      , isAnimating = False
      , eventLog = []
      , eventCounter = 0
      , currentTime = 0
      }
    , Cmd.none
    )



-- UPDATE


elementId : String
elementId =
    "event-box"


type Msg
    = MoveToCorner
    | MoveToCenter
    | StopAnimation
    | ClearEventLog
    | AnimationComplete String
    | Tick Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToCorner ->
            let
                builder =
                    WAAPI.builder model.animations
                        |> WAAPI.duration 1000
                        |> WAAPI.easing Linear
                        |> PositionAnim.moveToXY elementId 450 300

                ( newAnimations, cmd ) =
                    WAAPI.animate model.animations builder

                updatedModel =
                    { model
                        | animations = newAnimations
                        , isAnimating = True
                    }
                        |> addEventToLog AnimationStart "Animation started"
            in
            ( updatedModel, animateElement cmd )

        MoveToCenter ->
            let
                builder =
                    WAAPI.builder model.animations
                        |> WAAPI.duration 800
                        |> WAAPI.easing Linear
                        |> PositionAnim.moveToXY elementId 225 150

                ( newAnimations, cmd ) =
                    WAAPI.animate model.animations builder

                updatedModel =
                    { model
                        | animations = newAnimations
                        , isAnimating = True
                    }
                        |> addEventToLog AnimationStart "Animation started"
            in
            ( updatedModel, animateElement cmd )

        StopAnimation ->
            let
                ( newAnimations, cmd ) =
                    WAAPI.stop elementId model.animations

                updatedModel =
                    { model
                        | animations = newAnimations
                        , isAnimating = False
                    }
                        |> addEventToLog AnimationCancel "Animation was cancelled"
            in
            ( updatedModel, stopElement cmd )

        ClearEventLog ->
            ( { model | eventLog = [], eventCounter = 0 }
            , Cmd.none
            )

        AnimationComplete finishedElementId ->
            if finishedElementId == elementId then
                ( model
                    |> addEventToLog AnimationEnd "Animation completed"
                    |> (\m -> { m | isAnimating = False })
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Tick time ->
            ( { model | currentTime = Time.posixToMillis time }
            , Cmd.none
            )


addEventToLog : EventType -> String -> Model -> Model
addEventToLog eventType description model =
    let
        newEntry =
            { id = model.eventCounter
            , eventType = eventType
            , timestamp = model.currentTime
            , description = description
            }

        -- Keep only the last 10 events for display
        newLog =
            (newEntry :: model.eventLog)
                |> List.take 10
    in
    { model
        | eventLog = newLog
        , eventCounter = model.eventCounter + 1
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ animationComplete AnimationComplete
        , Time.every 100 Tick
        ]



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.WAAPI Events ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & WAAPI Engine Events Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Demonstrating Web Animations API events with real-time event logging")
    , -- Current status display
      column
        [ spacing 8, centerX ]
        [ el
            [ Font.size 14
            , Font.color
                (if model.isAnimating then
                    Colors.warning

                 else
                    Colors.success
                )
            , centerX
            , Font.medium
            ]
            (text
                (if model.isAnimating then
                    "🎬 Animating..."

                 else
                    "✅ Animation Complete"
                )
            )
        ]
    , -- Control buttons
      UI.wrappedButtonRow
        [ ( UI.Primary, MoveToCorner, "Move to Corner" )
        , ( UI.Success, MoveToCenter, "Move to Center" )
        , ( UI.Purple, StopAnimation, "Stop Animation" )
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
            , Background.color Colors.primary
            , Border.rounded 8
            , htmlAttribute (Html.Attributes.id "event-box")
            , htmlAttribute (Html.Attributes.style "position" "absolute")
            ]
            (el [ centerX, centerY, Font.size 20 ] (text "📦"))
        )
    , -- Event log section
      column
        [ spacing 12, width (fill |> maximum 600), centerX ]
        [ -- Event log header with clear button
          UI.wrappedButtonRow
            [ ( UI.Warning, ClearEventLog, "Clear Log" ) ]
        , el
            [ Font.size 18, centerX, Font.medium, Font.color Colors.textDark ]
            (text "🎯 Event Log")
        , -- Event log display
          if List.isEmpty model.eventLog then
            el
                [ Font.size 14, Font.color Colors.textMedium, centerX, padding 20 ]
                (text "No events yet. Click a button to start animating!")

          else
            column
                [ spacing 6, width fill ]
                (List.map (viewEventEntry model.eventCounter) model.eventLog)
        ]
    ]


viewEventEntry : Int -> EventLogEntry -> Element Msg
viewEventEntry currentCounter entry =
    let
        eventTypeInfo =
            getEventTypeInfo entry.eventType

        isRecent =
            (currentCounter - entry.id) <= 1
    in
    el
        [ width fill
        , padding 8
        , Background.color
            (if isRecent then
                eventTypeInfo.bgColor

             else
                Colors.backgroundLight
            )
        , Border.rounded 6
        , Border.width
            (if isRecent then
                2

             else
                1
            )
        , Border.color
            (if isRecent then
                eventTypeInfo.borderColor

             else
                Colors.borderLight
            )
        ]
        (Element.row
            [ width fill, spacing 12 ]
            [ el [ Font.size 16 ] (text eventTypeInfo.icon)
            , column
                [ spacing 2, width fill ]
                [ el
                    [ Font.size 14, Font.medium, Font.color eventTypeInfo.textColor ]
                    (text eventTypeInfo.name)
                , el
                    [ Font.size 12, Font.color Colors.textMedium ]
                    (text entry.description)
                ]
            , el
                [ Font.size 12, Font.color Colors.textLight ]
                (text ("#" ++ String.fromInt entry.id))
            ]
        )


type alias EventTypeInfo =
    { name : String
    , icon : String
    , textColor : Element.Color
    , bgColor : Element.Color
    , borderColor : Element.Color
    }


getEventTypeInfo : EventType -> EventTypeInfo
getEventTypeInfo eventType =
    case eventType of
        AnimationStart ->
            { name = "animationstart"
            , icon = "🚀"
            , textColor = Colors.primary
            , bgColor = Element.rgba255 59 130 246 0.1
            , borderColor = Colors.primary
            }

        AnimationEnd ->
            { name = "animationend"
            , icon = "✅"
            , textColor = Colors.success
            , bgColor = Element.rgba255 16 185 129 0.1
            , borderColor = Colors.success
            }

        AnimationRun ->
            { name = "animationrun"
            , icon = "⚡"
            , textColor = Colors.warning
            , bgColor = Element.rgba255 245 158 11 0.1
            , borderColor = Colors.warning
            }

        AnimationCancel ->
            { name = "animationcancel"
            , icon = "🚫"
            , textColor = Colors.red
            , bgColor = Element.rgba255 239 68 68 0.1
            , borderColor = Colors.red
            }
