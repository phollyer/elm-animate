module SmoothMoveScrollUI.HorizontalBasic exposing (main)

import Browser exposing (Document)
import Browser.Dom
import Browser.Events
import Common.Colors as Colors
import Common.Styles as Styles
import Common.UI as UI
import Element exposing (Element, alignLeft, alignRight, scrollbarX, centerX, centerY, column, el, explain, fill, height, htmlAttribute, layout, link, maximum, padding, paddingEach, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import SmoothMoveScroll exposing (Axis(..), animateToCmd, animateToCmdWithConfig, animateToTask, defaultConfig)
import Task



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
    { contentWidth : Maybe Float
    , hasAttemptedMeasure : Bool
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { contentWidth = Nothing
    , hasAttemptedMeasure = False }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | ScrollToSectionOne
    | ScrollToSectionTwo
    | ScrollToSectionThree
    | ScrollToStart
    | MeasureContent
    | GotContentWidth (Result Browser.Dom.Error Browser.Dom.Element)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        MeasureContent ->
            ( { model | hasAttemptedMeasure = True }
            , Task.attempt GotContentWidth (Browser.Dom.getElement "horizontal-content")
            )

        GotContentWidth result ->
            case result of
                Ok element ->
                    ( { model | contentWidth = Just element.element.width }, Cmd.none )

                Err _ ->
                    -- Fallback to calculated width if measurement fails
                    ( { model | contentWidth = Just 1440 }, Cmd.none )

        ScrollToSectionOne ->
            ( model, animateToCmdWithConfig NoOp { defaultConfig | speed = 30, axis = X, offsetX = 20 } "section-one" )

        ScrollToSectionTwo ->
            ( model, animateToCmdWithConfig NoOp { defaultConfig | speed = 30, axis = X, offsetX = 20 } "section-two" )

        ScrollToSectionThree ->
            ( model, animateToCmdWithConfig NoOp { defaultConfig | speed = 30, axis = X, offsetX = 20 } "section-three" )

        ScrollToStart ->
            ( model, animateToCmdWithConfig NoOp { defaultConfig | speed = 30, axis = X, offsetX = 20 } "start" )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    if not model.hasAttemptedMeasure && model.contentWidth == Nothing then
        Browser.Events.onAnimationFrame (\_ -> MeasureContent)
    else
        Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    let
        layoutType =
            case model.contentWidth of
                Just width ->
                    UI.HorizontalCustomWidth width

                Nothing ->
                    UI.Horizontal  -- Fallback to default calculated width while measuring
    in
    UI.createDocument "SmoothMoveScroll Horizontal ElmUI Example" layoutType (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ -- Header Section
      column
        [ width fill
        --, spacing 20
        ]
        [ UI.backButton
        , -- Header
          UI.pageHeader "Horizontal X Axis Scrolling"
        ]
    , -- Navigation Buttons
      el [alignRight
      , paddingXY 20 0] <|
      UI.htmlActionButtons
        [ ( UI.Primary, ScrollToStart, "Start" )
        , ( UI.Success, ScrollToSectionOne, "Section 1" )
        , ( UI.Purple, ScrollToSectionTwo, "Section 2" )
        , ( UI.Warning, ScrollToSectionThree, "Section 3" )
        ]
    , -- Horizontal Content Container
      row
        [ spacing 40
        , paddingXY 20 0
        , htmlAttribute (Html.Attributes.id "horizontal-content")
        ]
        [ -- Start Section
          viewSection "start"
            "🚀 Start Here"
            Colors.primary
            ScrollToSectionOne
            "Begin Journey →"
            [ "Welcome to the horizontal scrolling demonstration!"
            , "This is the starting point of our X axis scrolling example."
            , "Click the button below to begin the horizontal journey through the sections."
            ]
        , -- Section One
          viewSection "section-one"
            "Section One"
            Colors.primary
            ScrollToSectionTwo
            "Continue to Section Two →"
            [ "This is the first section of our horizontal scrolling example."
            , "Notice how the scroll animation moves left-to-right instead of up-and-down."
            , "The X axis configuration makes this possible with smooth horizontal movement."
            ]
        , -- Section Two
          viewSection "section-two"
            "Section Two"
            Colors.success
            ScrollToSectionThree
            "Continue to Section Three →"
            [ "Welcome to the second section! The horizontal scrolling continues smoothly."
            , "Each section is positioned side-by-side in a horizontal layout."
            , "The animation automatically calculates the correct X position for each target."
            ]
        , -- Section Three
          viewSection "section-three"
            "Section Three"
            Colors.purple
            ScrollToStart
            "Back to Start ←"
            [ "This is the final section of our horizontal scrolling demonstration."
            , "You can navigate back to any previous section using the buttons above."
            , "The SmoothMoveScroll module handles all the complex scroll calculations automatically."
            ]
        ]
    ]


viewSection : String -> String -> Element.Color -> Msg -> String -> List String -> Element Msg
viewSection sectionId title color nextAction buttonText contentLines =
    column
        [ width (px 300)
        , height (px 300)
        , spacing 20
        , htmlAttribute (Html.Attributes.id sectionId)
        , htmlAttribute (Html.Attributes.class "responsive-paragraph")
        , Background.color Colors.backgroundWhite
        , paddingXY 32 24
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }
        ]
        [ -- Section Title
          el
            [ Font.size 24
            , Font.semiBold
            , Font.color color
            , centerX
            ]
            (text title)
        , -- Content
          column
            [ spacing 16
            , width fill
            ]
            (List.map
                (\line ->
                    paragraph
                        [ Font.size 16
                        , Font.color Colors.textMedium
                        , width fill
                        ]
                        [ text line ]
                )
                contentLines
            )
        , -- Navigation Button
          UI.smallActionButton UI.Primary nextAction buttonText
        ]
