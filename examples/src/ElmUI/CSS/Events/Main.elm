module ElmUI.CSS.Events.Main exposing (main)

{-| SmoothMoveCSS Events Example using ElmUI - Demonstrating CSS transition event handling

This example showcases all CSS transition events available in the SmoothMoveCSS module.
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

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Move exposing (defaultConfig)
import Move.CSS exposing (Position, Model, init, setPosition, animateTo, getPosition, transformElement, transition, onTransitionStart, onTransitionEnd, onTransitionRun, onTransitionCancel)



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
    { animations : Move.CSS.Model
    , isAnimating : Bool
    , eventLog : List EventLogEntry
    , eventCounter : Int
    }


type alias EventLogEntry =
    { id : Int
    , eventType : EventType
    , timestamp : Int
    , position : Position
    }


type EventType
    = TransitionStart
    | TransitionEnd  
    | TransitionRun
    | TransitionCancel



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        initialAnimations =
            Move.CSS.init
                |> setPosition "box" (Position 0 0)
    in
    ( { animations = initialAnimations
      , isAnimating = False
      , eventLog = []
      , eventCounter = 0
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = MoveToCorner
    | MoveToCenter
    | MoveToOpposite
    | StopAnimation
    | ClearEventLog
    | OnTransitionStart
    | OnTransitionEnd
    | OnTransitionRun
    | OnTransitionCancel


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToCorner ->
            ( { model 
                | animations = animateTo "box" (Position 100 100) model.animations
                , isAnimating = True
              }
            , Cmd.none
            )

        MoveToCenter ->
            ( { model 
                | animations = animateTo "box" (Position 300 200) model.animations
                , isAnimating = True
              }
            , Cmd.none
            )

        MoveToOpposite ->
            ( { model 
                | animations = animateTo "box" (Position 400 50) model.animations
                , isAnimating = True
              }
            , Cmd.none
            )

        StopAnimation ->
            ( { model 
                | animations = animateTo "box" (Position 0 0) model.animations
                , isAnimating = True
              }
            , Cmd.none
            )

        ClearEventLog ->
            ( { model | eventLog = [] }
            , Cmd.none
            )

        OnTransitionStart ->
            ( addEventToLog TransitionStart model
            , Cmd.none
            )

        OnTransitionEnd ->
            ( model
                |> addEventToLog TransitionEnd
                |> (\m -> { m | isAnimating = False })
            , Cmd.none
            )

        OnTransitionRun ->
            ( addEventToLog TransitionRun model
            , Cmd.none
            )

        OnTransitionCancel ->
            ( model
                |> addEventToLog TransitionCancel
                |> (\m -> { m | isAnimating = False })
            , Cmd.none
            )


addEventToLog : EventType -> Model -> Model
addEventToLog eventType model =
    let
        currentPosition =
            getPosition "box" model.animations 
                |> Maybe.withDefault (Position 0 0)
        
        newEntry =
            { id = model.eventCounter
            , eventType = eventType
            , timestamp = model.eventCounter  -- Simple counter for demo
            , position = currentPosition
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
    Sub.none  -- No subscriptions needed - CSS events handle everything!


-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveCSS Events ElmUI Example" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "SmoothMoveCSS Events Example"
    , -- Current status display
      column 
        [ spacing 8, centerX ]
        [ el
            [ Font.size 14
            , Font.color Colors.textMedium
            , centerX
            ]
            (case getPosition "box" model.animations of
                Just pos -> 
                    text ("Position: (" ++ String.fromInt (round pos.x) ++ ", " ++ String.fromInt (round pos.y) ++ ")")
                Nothing ->
                    text "Position: (0, 0)"
            )
        , el
            [ Font.size 14
            , Font.color (if model.isAnimating then Colors.warning else Colors.success)
            , centerX
            , Font.medium
            ]
            (text (if model.isAnimating then "🎬 Animating..." else "✅ Animation Complete"))
        ]
    , -- Control buttons
      UI.htmlActionButtons
        [ ( UI.Primary, MoveToCorner, "Move to (100, 100)" )
        , ( UI.Success, MoveToCenter, "Move to (300, 200)" )
        , ( UI.Warning, MoveToOpposite, "Move to (400, 50)" )
        , ( UI.Purple, StopAnimation, "Return to Origin" )
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
            , htmlAttribute (Html.Attributes.id "moving-box")
            , htmlAttribute (Html.Attributes.style "position" "absolute")

            -- Apply CSS transition styles with all event handlers
            , htmlAttribute (Html.Attributes.style "transform" (transformElement "box" model.animations))
            , htmlAttribute (Html.Attributes.style "transition" 
                (if model.isAnimating then
                    transition defaultConfig
                 else
                    "none"
                ))
            
            -- All CSS transition event handlers
            , htmlAttribute (onTransitionStart OnTransitionStart)
            , htmlAttribute (onTransitionEnd OnTransitionEnd)
            , htmlAttribute (onTransitionRun OnTransitionRun)
            , htmlAttribute (onTransitionCancel OnTransitionCancel)
            ]
            (text "📦")
        )
    , -- Event log section
      column 
        [ spacing 12, width (fill |> maximum 600), centerX ]
        [ -- Event log header with clear button
        UI.htmlActionButtons
                [ ( UI.Primary, ClearEventLog, "Clear Log" )]
          ,el 
                [ Font.size 18, Element.centerX, Font.medium, Font.color Colors.textDark ]
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
        eventTypeInfo = getEventTypeInfo entry.eventType
        isRecent = (currentCounter - entry.id) <= 1
    in
    el
        [ width fill
        , padding 8
        , Background.color (if isRecent then eventTypeInfo.bgColor else Colors.backgroundLight)
        , Border.rounded 6
        , Border.width (if isRecent then 2 else 1)
        , Border.color (if isRecent then eventTypeInfo.borderColor else Colors.borderLight)
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
                    (text ("Position: (" ++ String.fromInt (round entry.position.x) ++ ", " ++ String.fromInt (round entry.position.y) ++ ")"))
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