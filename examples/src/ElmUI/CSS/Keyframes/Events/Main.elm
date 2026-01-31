module ElmUI.CSS.Keyframes.Events.Main exposing (main)

{-| Anim.Engine.CSS Events Example using ElmUI - Demonstrating CSS transition event handling

This example showcases CSS transition events available in the Anim.Engine.CSS module.
Learn how to coordinate animations and update your UI based on transition lifecycle events.

EVENT TYPES:

  - ✅ transitionstart - Fired when a transition starts
  - ✅ transitionend - Fired when a transition completes
  - ✅ transitionrun - Fired when a transition is created (even if delayed)
  - ✅ transitioncancel - Fired when a transition is interrupted

BENEFITS:

  - ✅ Coordinate multiple animations seamlessly
  - ✅ Update UI state precisely when animations finish
  - ✅ Chain animations together with perfect timing
  - ✅ Handle animation interruptions gracefully
  - ✅ Debug animation timing and performance
  - ✅ Native browser events - zero JavaScript overhead

-}

import Anim.Easing as Easing exposing (Easing(..))
import Anim.Engine.CSS as CSS
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.Animations.Translate as PositionAnim
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
import Html.Attributes
import Time



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
    { animations : CSS.AnimState
    , isAnimating : Bool
    , eventLog : List EventLogEntry
    , eventCounter : Int
    }


type alias EventLogEntry =
    { id : Int
    , eventType : EventType
    , timestamp : Int
    , description : String
    }


type EventType
    = TransitionStart
    | TransitionEnd
    | TransitionRun
    | TransitionCancel



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations =
            CSS.animate CSS.init
                (Translate.initXY elementId 0 0)
      , isAnimating = False
      , eventLog = []
      , eventCounter = 0
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
    | OnAnimationStart
    | OnAnimationEnd
    | OnAnimationIteration
    | OnAnimationCancel


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToCorner ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (CSS.duration 1000
                            >> CSS.easing Linear
                            >> PositionAnim.moveToXY elementId 450 300
                        )
                , isAnimating = True
              }
            , Cmd.none
            )

        MoveToCenter ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (CSS.duration 800
                            >> CSS.easing Linear
                            >> PositionAnim.moveToXY elementId 225 150
                        )
                , isAnimating = True
              }
            , Cmd.none
            )

        StopAnimation ->
            ( { model
                | animations = CSS.stop elementId model.animations
                , isAnimating = False
              }
            , Cmd.none
            )

        ClearEventLog ->
            ( { model | eventLog = [], eventCounter = 0 }
            , Cmd.none
            )

        OnAnimationStart ->
            ( addEventToLog TransitionStart "Animation started" model
            , Cmd.none
            )

        OnAnimationEnd ->
            ( model
                |> addEventToLog TransitionEnd "Animation completed"
                |> (\m -> { m | isAnimating = False })
            , Cmd.none
            )

        OnAnimationIteration ->
            ( addEventToLog TransitionRun "Animation is running" model
            , Cmd.none
            )

        OnAnimationCancel ->
            ( model
                |> addEventToLog TransitionCancel "Animation was cancelled"
                |> (\m -> { m | isAnimating = False })
            , Cmd.none
            )


addEventToLog : EventType -> String -> Model -> Model
addEventToLog eventType description model =
    let
        newEntry =
            { id = model.eventCounter
            , eventType = eventType
            , timestamp = 0 -- Not displayed, so not needed
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
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.CSS Events Keyframes ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ Element.html (CSS.keyframesStyleNodeFor elementId model.animations)
    , UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & CSS Keyframes Events Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Demonstrating CSS transition events with real-time event logging")
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
            , htmlAttribute (CSS.animationStyleAttribute elementId model.animations)
            , htmlAttribute (CSS.onAnimationStart OnAnimationStart)
            , htmlAttribute (CSS.onAnimationEnd OnAnimationEnd)
            , htmlAttribute (CSS.onAnimationIteration OnAnimationIteration)
            , htmlAttribute (CSS.onAnimationCancel OnAnimationCancel)
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
        TransitionStart ->
            { name = "transitionstart"
            , icon = "🚀"
            , textColor = Colors.primary
            , bgColor = Element.rgba255 59 130 246 0.1
            , borderColor = Colors.primary
            }

        TransitionEnd ->
            { name = "transitionend"
            , icon = "✅"
            , textColor = Colors.success
            , bgColor = Element.rgba255 16 185 129 0.1
            , borderColor = Colors.success
            }

        TransitionRun ->
            { name = "transitionrun"
            , icon = "⚡"
            , textColor = Colors.warning
            , bgColor = Element.rgba255 245 158 11 0.1
            , borderColor = Colors.warning
            }

        TransitionCancel ->
            { name = "transitioncancel"
            , icon = "🚫"
            , textColor = Colors.red
            , bgColor = Element.rgba255 239 68 68 0.1
            , borderColor = Colors.red
            }
