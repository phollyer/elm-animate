module ElmUI.Scroll.PageX.Main exposing (main)

import Browser exposing (Document)
import Browser.Dom
import Browser.Events
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, alignLeft, alignRight, scrollbarX, centerX, centerY, column, el, explain, fill, height, htmlAttribute, layout, link, maximum, padding, paddingEach, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import SmoothMoveScroll exposing (Axis(..), scrollCmd, scrollCmdWithConfig, scrollTask, defaultConfig)
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
    { }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | ScrollToSectionOne
    | ScrollToSectionTwo
    | ScrollToSectionThree
    | ScrollToStart


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ScrollToSectionOne ->
            ( model, scrollCmdWithConfig NoOp "section-one" { defaultConfig | axis = X, offsetX = 20 } )

        ScrollToSectionTwo ->
            ( model, scrollCmdWithConfig NoOp "section-two" { defaultConfig | axis = X, offsetX = 20 } )

        ScrollToSectionThree ->
            ( model, scrollCmdWithConfig NoOp "section-three" { defaultConfig | axis = X, offsetX = 20 } )

        ScrollToStart ->
            ( model, scrollCmdWithConfig NoOp "start" { defaultConfig | axis = X, offsetX = 20 } )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveScroll Horizontal ElmUI Example" UI.Horizontal  (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ -- Back Button
      UI.backButton
        , -- Header
          UI.pageHeader "Horizontal X Axis Scrolling"
        
    , -- Horizontal Content Container
      row
        [ spacing 40 ]
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
