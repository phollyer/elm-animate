module ElmUI.Scroll.HorizontalBasic.Main exposing (main)

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
        [ width fill ]
        [ el
            [alignLeft
            , paddingXY 20 10]
            <|
            UI.backButton
        , -- Header
          el
            [alignLeft
            , paddingXY 20 10]
            <|
                UI.pageHeader "Horizontal X Axis Scrolling"
        ]
    , -- Horizontal Content Container
      row
        [ spacing 40
        , paddingXY 20 0
        , htmlAttribute (Html.Attributes.id "horizontal-content")
        ]
        [ -- Start Section
          UI.contentSection 
            { id = "start"
            , title = "🚀 Start Here"
            , titleColor = Just Colors.primary
            , content = 
                [ "Welcome to the horizontal scrolling demonstration!"
                , "This is the starting point of our X axis scrolling example."
                , "Click the buttons below to begin the horizontal journey through the sections."
                ]
            , buttons = 
                [ ( UI.Success, ScrollToSectionOne, "Section 1" )
                , ( UI.Purple, ScrollToSectionTwo, "Section 2" )
                , ( UI.Warning, ScrollToSectionThree, "Section 3" )
                ]
            , width = Just 300
            , centerTitle = True
            }
        , -- Section One
          UI.contentSection 
            { id = "section-one"
            , title = "Section One"
            , titleColor = Just Colors.primary
            , content = 
                [ "This is the first section of our horizontal scrolling example."
                , "Notice how the scroll animation moves left-to-right instead of up-and-down."
                , "The X axis configuration makes this possible with smooth horizontal movement."
                ]
            , buttons = 
                [ ( UI.Primary, ScrollToStart, "Start" )
                , ( UI.Purple, ScrollToSectionTwo, "Section 2" )
                , ( UI.Warning, ScrollToSectionThree, "Section 3" )
                ]
            , width = Just 300
            , centerTitle = True
            }
        , -- Section Two
          UI.contentSection 
            { id = "section-two"
            , title = "Section Two"
            , titleColor = Just Colors.success
            , content = 
                [ "Welcome to the second section! The horizontal scrolling continues smoothly."
                , "Each section is positioned side-by-side in a horizontal layout."
                , "The animation automatically calculates the correct X position for each target."
                ]
            , buttons = 
                [ ( UI.Primary, ScrollToStart, "Start" )
                , ( UI.Success, ScrollToSectionOne, "Section 1" )
                , ( UI.Warning, ScrollToSectionThree, "Section 3" )
                ]
            , width = Just 300
            , centerTitle = True
            }
        , -- Section Three
          UI.contentSection 
            { id = "section-three"
            , title = "Section Three"
            , titleColor = Just Colors.purple
            , content = 
                [ "This is the final section of our horizontal scrolling demonstration."
                , "You can navigate back to any previous section using the buttons above."
                , "The SmoothMoveScroll module handles all the complex scroll calculations automatically."
                ]
            , buttons = 
                [ ( UI.Primary, ScrollToStart, "Start" )
                , ( UI.Success, ScrollToSectionOne, "Section 1" )
                , ( UI.Purple, ScrollToSectionTwo, "Section 2" )
                ]
            , width = Just 300
            , centerTitle = True
            }
        ]
    ]
