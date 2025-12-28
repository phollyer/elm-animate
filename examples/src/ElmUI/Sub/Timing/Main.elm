module ElmUI.Sub.Timing.Main exposing (main)

{-| Anim.Engine.Sub Timing Analysis Example using ElmUI - Animation timing verification and comparison

This example demonstrates animation timing accuracy by comparing calculated vs actual animation durations.
It tests both speed-based and duration-based animations with real-time timing measurements.

FEATURES:

  - ✅ Speed-based animation timing (Position.speed)
  - ✅ Duration-based animation timing (Position.duration)
  - ✅ Real-time timing measurement using Time.now
  - ✅ Comparison between calculated and actual durations
  - ✅ Visual timing indicators and accuracy metrics
  - ✅ Frame-rate independent timing verification

TIMING TESTS:

  - Speed: 200px/s over 400px = expected 2000ms
  - Duration: explicit 3000ms duration test
  - Accuracy measurement with percentage difference
  - Real browser timing vs calculated timing

-}

import Anim.Engine.Sub as Sub
import Anim.Properties.Position as Position
import Anim.Timing.Easing as Easing exposing (Easing(..))
import Browser exposing (Document)
import Browser.Events
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Task
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
    { animations : Sub.AnimState
    , currentTest : Maybe TimingTest
    , completedTests : List CompletedTest
    , startTime : Maybe Time.Posix
    }


type alias TimingTest =
    { name : String
    , expectedDuration : Int -- in milliseconds
    , animationBuilder : Sub.AnimState -> Sub.AnimState
    }


type alias CompletedTest =
    { name : String
    , expectedDuration : Int
    , actualDuration : Int
    , accuracy : Float -- percentage accuracy
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Sub.init
      , currentTest = Nothing
      , completedTests = []
      , startTime = Nothing
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = StartSpeedTest
    | StartDurationTest
    | StartCustomTest Int -- duration in ms
    | AnimationMsg Sub.AnimationMsg
    | RecordStartTime Time.Posix
    | RecordEndTime Time.Posix
    | ResetTests


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartSpeedTest ->
            let
                test =
                    createSpeedTest 400 200

                -- 400px distance at 200px/s = 2000ms expected
            in
            startTimingTest test model

        StartDurationTest ->
            let
                test =
                    createDurationTest 3000

                -- explicit 3000ms duration
            in
            startTimingTest test model

        StartCustomTest duration ->
            let
                test =
                    createDurationTest duration
            in
            startTimingTest test model

        RecordStartTime time ->
            case model.currentTest of
                Just test ->
                    let
                        newAnimations =
                            test.animationBuilder model.animations
                    in
                    ( { model
                        | animations = newAnimations
                        , startTime = Just time
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        RecordEndTime time ->
            case ( model.startTime, model.currentTest ) of
                ( Just startTime, Just test ) ->
                    let
                        actualDuration =
                            Time.posixToMillis time - Time.posixToMillis startTime

                        accuracy =
                            calculateAccuracy test.expectedDuration actualDuration

                        completedTest =
                            { name = test.name
                            , expectedDuration = test.expectedDuration
                            , actualDuration = actualDuration
                            , accuracy = accuracy
                            }
                    in
                    ( { model
                        | currentTest = Nothing
                        , completedTests = model.completedTests ++ [ completedTest ]
                        , startTime = Nothing
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        AnimationMsg animMsg ->
            let
                oldAnimations =
                    model.animations

                newAnimations =
                    Sub.update animMsg model.animations

                -- Check if animation just completed using the new API function
                wasRunning =
                    case model.currentTest of
                        Just _ ->
                            Sub.isRunning "timing-box" oldAnimations

                        Nothing ->
                            False

                isStillRunning =
                    Sub.isRunning "timing-box" newAnimations

                cmd =
                    case model.currentTest of
                        Just test ->
                            if wasRunning && not isStillRunning then
                                -- Animation just completed - record the end time
                                Task.perform RecordEndTime Time.now

                            else
                                Cmd.none

                        Nothing ->
                            Cmd.none
            in
            ( { model | animations = newAnimations }, cmd )

        ResetTests ->
            ( { model
                | completedTests = []
                , currentTest = Nothing
                , startTime = Nothing
                , animations = Sub.init
              }
            , Cmd.none
            )


startTimingTest : TimingTest -> Model -> ( Model, Cmd Msg )
startTimingTest test model =
    ( { model | currentTest = Just test }
    , Task.perform RecordStartTime Time.now
    )


createSpeedTest : Float -> Float -> TimingTest
createSpeedTest distance speed =
    let
        expectedMs =
            round (distance / speed * 1000)
    in
    { name = "Speed Test (" ++ String.fromFloat distance ++ "px at " ++ String.fromFloat speed ++ "px/s)"
    , expectedDuration = expectedMs
    , animationBuilder =
        \animations ->
            animations
                |> Sub.builder
                |> Position.for "timing-box"
                |> Position.fromXY 0 100
                |> Position.toX distance
                |> Position.speed speed
                |> Position.easing Linear
                |> Position.build
                |> Sub.animate
    }


createDurationTest : Int -> TimingTest
createDurationTest durationMs =
    { name = "Duration Test (" ++ String.fromInt durationMs ++ "ms)"
    , expectedDuration = durationMs
    , animationBuilder =
        \animations ->
            animations
                |> Sub.builder
                |> Position.for "timing-box"
                |> Position.fromXY 0 100
                |> Position.toX 400
                |> Position.duration durationMs
                |> Position.easing Linear
                |> Position.build
                |> Sub.animate
    }


calculateAccuracy : Int -> Int -> Float
calculateAccuracy expected actual =
    let
        difference =
            abs (expected - actual)

        accuracy =
            (1.0 - (toFloat difference / toFloat expected)) * 100.0
    in
    max 0.0 accuracy



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.subscriptions model.animations
            |> Sub.map AnimationMsg
        ]



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "Anim.Engine.Sub Timing Analysis Example" UI.Basic [ viewContent model ]


viewContent : Model -> Element Msg
viewContent model =
    column [ spacing 30, padding 20 ]
        [ UI.pageHeader "Timing Analysis Example"
        , paragraph [ Font.size 16 ]
            [ text "This example demonstrates animation timing accuracy by comparing calculated vs actual animation durations." ]
        , animationView model
        , controlsView model
        , resultsView model
        ]


animationView : Model -> Element Msg
animationView model =
    let
        currentPosition =
            Sub.getCurrentPosition "timing-box" model.animations

        positionText =
            case currentPosition of
                Just pos ->
                    "Position: (" ++ String.fromFloat pos.x ++ ", " ++ String.fromFloat pos.y ++ ")"

                Nothing ->
                    "Position: (0, 0)"

        statusText =
            case model.currentTest of
                Just test ->
                    "Running: " ++ test.name

                Nothing ->
                    "Ready for next test"
    in
    column [ spacing 20 ]
        [ -- Animation container
          el
            [ width (px 500)
            , height (px 300)
            , Background.color (rgb255 240 240 240)
            , Border.rounded 8
            , Border.width 2
            , Border.color (rgb255 200 200 200)
            , htmlAttribute (Html.Attributes.style "position" "relative")
            , htmlAttribute (Html.Attributes.style "overflow" "hidden")
            ]
            (el
                ([ width (px 50)
                 , height (px 50)
                 , Background.color Colors.primary
                 , Border.rounded 4
                 , htmlAttribute (Html.Attributes.style "position" "absolute")
                 ]
                    ++ (Sub.htmlAttributes "timing-box" model.animations |> List.map htmlAttribute)
                )
                Element.none
            )
        , -- Status information
          column [ spacing 8 ]
            [ text ("Status: " ++ statusText)
            , text positionText
            , text ("Completed Tests: " ++ String.fromInt (List.length model.completedTests))
            , text
                ("Start Time: "
                    ++ (case model.startTime of
                            Just _ ->
                                "Set"

                            Nothing ->
                                "Not set"
                       )
                )
            , text
                ("Current Test: "
                    ++ (case model.currentTest of
                            Just test ->
                                test.name

                            Nothing ->
                                "None"
                       )
                )
            ]
        ]


controlsView : Model -> Element Msg
controlsView model =
    let
        isRunning =
            case model.currentTest of
                Just _ ->
                    True

                Nothing ->
                    False

        buttonType =
            if isRunning then
                UI.Warning

            else
                UI.Primary
    in
    column [ spacing 20 ]
        [ el [ Font.bold, Font.size 18 ] (text "Timing Tests")
        , paragraph [ Font.size 16 ]
            [ text "Run timing tests to compare calculated vs actual animation durations:" ]
        , UI.wrappedButtonRow
            [ ( buttonType, StartSpeedTest, "Speed Test (400px @ 200px/s = 2000ms)" )
            , ( buttonType, StartDurationTest, "Duration Test (3000ms explicit)" )
            ]
        , UI.wrappedButtonRow
            [ ( buttonType, StartCustomTest 1000, "Custom: 1000ms" )
            , ( buttonType, StartCustomTest 2992, "Custom: 2992ms" )
            , ( buttonType, StartCustomTest 5000, "Custom: 5000ms" )
            ]
        , UI.wrappedButtonRow
            [ ( UI.Warning, ResetTests, "Reset All Tests" )
            ]
        ]


resultsView : Model -> Element Msg
resultsView model =
    column [ spacing 15 ]
        [ paragraph [ Font.size 16 ]
            [ text ("Results section - Found " ++ String.fromInt (List.length model.completedTests) ++ " completed tests:") ]
        , if List.isEmpty model.completedTests then
            paragraph [ Font.size 16, Font.color (rgb255 150 150 150) ]
                [ text "No tests completed yet. Run some timing tests to see results." ]

          else
            column [ spacing 10 ] (List.map testResultView model.completedTests)
        ]


testResultView : CompletedTest -> Element Msg
testResultView test =
    let
        accuracyColor =
            if test.accuracy >= 95 then
                Colors.success

            else if test.accuracy >= 90 then
                Colors.warning

            else
                Colors.red

        difference =
            test.actualDuration - test.expectedDuration

        differenceText =
            if difference > 0 then
                "+" ++ String.fromInt difference ++ "ms"

            else
                String.fromInt difference ++ "ms"
    in
    el
        [ width fill
        , padding 15
        , Background.color (rgb255 250 250 250)
        , Border.rounded 6
        , Border.width 1
        , Border.color (rgb255 230 230 230)
        ]
        (column [ spacing 8 ]
            [ el [ Font.bold ] (text test.name)
            , row [ spacing 20 ]
                [ text ("Expected: " ++ String.fromInt test.expectedDuration ++ "ms")
                , text ("Actual: " ++ String.fromInt test.actualDuration ++ "ms")
                , text ("Difference: " ++ differenceText)
                ]
            , el
                [ Font.color accuracyColor
                , Font.bold
                ]
                (text ("Accuracy: " ++ String.fromFloat (toFloat (round (test.accuracy * 100)) / 100) ++ "%"))
            ]
        )
