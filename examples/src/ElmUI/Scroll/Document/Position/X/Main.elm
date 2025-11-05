module ElmUI.Scroll.Document.Position.X.Main exposing (main)

import Browser exposing (Document)
import Browser.Dom
import Browser.Events
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, alignLeft, alignRight, centerX, centerY, column, el, explain, fill, height, htmlAttribute, layout, link, maximum, padding, paddingEach, paddingXY, paragraph, px, rgb255, row, scrollbarX, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Scroll exposing (Axis(..), defaultConfig)
import Scroll.Document.Cmd as Scroll
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
    { sectionCount : Int }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { sectionCount = 4 }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | ScrollToSection String
    | ScrollToStart
    | ScrollToEnd
    | AddSection
    | RemoveSection


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ScrollToSection id ->
            ( model
            , Scroll.scrollWithConfig id NoOp <|
                { defaultConfig | axis = XWithOffset 20 }
            )

        ScrollToStart ->
            ( model, Scroll.scrollToLeftEdge NoOp )

        ScrollToEnd ->
            ( model, Scroll.scrollToRightEdge NoOp )

        AddSection ->
            ( { model | sectionCount = model.sectionCount + 1 }, Cmd.none )

        RemoveSection ->
            ( { model | sectionCount = max 1 model.sectionCount - 1 }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


getButtonStyle : Int -> UI.ButtonStyle
getButtonStyle index =
    case modBy 4 index of
        0 ->
            UI.Success

        1 ->
            UI.Primary

        2 ->
            UI.Purple

        _ ->
            UI.Warning


getTitleColor : Int -> Element.Color
getTitleColor index =
    case modBy 4 index of
        0 ->
            Colors.success

        1 ->
            Colors.primary

        2 ->
            Colors.purple

        _ ->
            Colors.warning


generateSectionButtons : Int -> Int -> List ( UI.ButtonStyle, Msg, String )
generateSectionButtons currentSection totalSections =
    let
        startButton =
            [ ( UI.Primary, ScrollToStart, "Start" ) ]

        endButton =
            [ ( UI.Warning, ScrollToEnd, "End" ) ]

        sectionButtons =
            List.range 1 totalSections
                |> List.filter (\n -> n /= currentSection)
                --|> List.take 3  -- Limit to 3 other sections to avoid too many buttons
                |> List.map (\n -> ( getButtonStyle n, ScrollToSection ("section-" ++ String.fromInt n), "Section " ++ String.fromInt n ))
    in
    startButton ++ sectionButtons ++ endButton


generateSection : Int -> Int -> Element Msg
generateSection sectionNum totalSections =
    UI.contentSection
        { id = "section-" ++ String.fromInt sectionNum
        , title = "Section " ++ String.fromInt sectionNum
        , titleColor = Just (getTitleColor sectionNum)
        , content =
            [ "This is section " ++ String.fromInt sectionNum ++ " of our horizontal scrolling example."
            , "Use the add/remove buttons to change the number of sections dynamically."
            ]
        , buttons = generateSectionButtons sectionNum totalSections
        , width = Just 300
        , centerTitle = True
        }


generateStartSection : Int -> Element Msg
generateStartSection totalSections =
    let
        sectionButtons =
            List.range 1 totalSections
                |> List.map (\n -> ( getButtonStyle n, ScrollToSection ("section-" ++ String.fromInt n), "Section " ++ String.fromInt n ))

        endButton =
            [ ( UI.Warning, ScrollToEnd, "End" ) ]
    in
    UI.contentSection
        { id = "start"
        , title = "🚀 Start Here"
        , titleColor = Just Colors.primary
        , content =
            [ "Welcome to the horizontal scrolling demonstration!"
            , "This is the starting point of our X axis scrolling example."
            , "Current sections: " ++ String.fromInt totalSections
            , "Click the buttons below to begin the horizontal journey through the sections."
            ]
        , buttons = sectionButtons ++ endButton
        , width = Just 300
        , centerTitle = True
        }


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveScroll Horizontal ElmUI Example" UI.HorizontalContainer (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ -- Back Button
      UI.backButton
    , -- Header
      UI.pageHeader "Horizontal X Axis Scrolling"
    , -- Add/Remove Section Controls
      column
        [ spacing 8, centerX ]
        [ paragraph
            [ Font.center ]
            [ text "Add or remove sections to increase or decrease the page width." ]
        , el [ centerX ] <|
            UI.htmlActionButtons
                [ ( UI.Success, AddSection, "+ Add Section" )
                , ( UI.Warning, RemoveSection, "− Remove Section" )
                ]
        ]
    , -- Horizontal Content Container
      row
        [ spacing 40 ]
        ([ generateStartSection model.sectionCount ]
            ++ (List.range 1 model.sectionCount
                    |> List.map (\n -> generateSection n model.sectionCount)
               )
        )
    ]
