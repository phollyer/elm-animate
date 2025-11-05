module ElmUI.Scroll.Document.Position.Y.Main exposing (main)

import Browser exposing (Document)
import Browser.Dom
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, alignLeft, centerX, column, el, fill, height, htmlAttribute, layout, link, maximum, padding, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Scroll exposing (defaultConfig)
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
    {}


init : () -> ( Model, Cmd Msg )
init _ =
    ( {}, Cmd.none )



-- UPDATE


type Msg
    = NoOp
    | ScrollToParagraphOne
    | ScrollToParagraphTwo
    | ScrollToParagraphThree
    | ScrollToTop
    | ScrollToBottom


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ScrollToParagraphOne ->
            ( model, Scroll.scrollWithConfig "paragraph-one" NoOp defaultConfig )

        ScrollToParagraphTwo ->
            ( model, Scroll.scrollWithConfig "paragraph-two" NoOp defaultConfig )

        ScrollToParagraphThree ->
            ( model, Scroll.scrollWithConfig "paragraph-three" NoOp defaultConfig )

        ScrollToTop ->
            ( model, Scroll.scrollToTop NoOp )

        ScrollToBottom ->
            ( model, Scroll.scrollToBottom NoOp )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveScroll Basic ElmUI Example" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        contentSectionSimple : String -> String -> List String -> List ( UI.ButtonStyle, msg, String ) -> Element msg
        contentSectionSimple id title content buttons =
            UI.contentSection
                { id = id
                , title = title
                , titleColor = Nothing
                , content = content
                , buttons = buttons
                , width = Nothing
                , centerTitle = False
                }
    in
    [ -- Back Button
      UI.backButton
    , -- Header
      UI.pageHeader "SmoothMoveScroll Document Example"

    -- Buttons
    , el [ centerX ] <|
        UI.htmlActionButtons
            [ ( UI.Primary, ScrollToParagraphOne, "Scroll to Paragraph One ↓" )
            , ( UI.Success, ScrollToParagraphTwo, "Scroll to Paragraph Two ↓" )
            , ( UI.Purple, ScrollToParagraphThree, "Scroll to Paragraph Three ↓" )
            , ( UI.Warning, ScrollToBottom, "Scroll to Bottom ↓" )
            ]
    , -- Add some space before content
      el [ height (px 100) ] (text "")
    , -- Paragraph One
      contentSectionSimple "paragraph-one"
        "Paragraph One"
        [ "This is the first paragraph of our example. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
        , "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. "
        , "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium."
        ]
        [ ( UI.Purple, ScrollToTop, "Scroll to Top ↑" )
        , ( UI.Success, ScrollToParagraphTwo, "Scroll to Paragraph Two ↓" )
        , ( UI.Purple, ScrollToParagraphThree, "Scroll to Paragraph Three ↓" )
        , ( UI.Warning, ScrollToBottom, "Scroll to Bottom ↓" )
        ]
    , -- Add space between paragraphs
      el [ height (px 200) ] (text "")
    , -- Paragraph Two
      contentSectionSimple "paragraph-two"
        "Paragraph Two"
        [ "This is the second paragraph. Totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo."
        , "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt."
        , "Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem."
        ]
        [ ( UI.Purple, ScrollToTop, "Scroll to Top ↑" )
        , ( UI.Primary, ScrollToParagraphOne, "Scroll to Paragraph One ↑" )
        , ( UI.Purple, ScrollToParagraphThree, "Scroll to Paragraph Three ↓" )
        , ( UI.Warning, ScrollToBottom, "Scroll to Bottom ↓" )
        ]
    , -- Add space between paragraphs
      el [ height (px 100) ] (text "")
    , -- Paragraph Three
      contentSectionSimple "paragraph-three"
        "Paragraph Three"
        [ "This is the third and final paragraph. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam."
        , "Nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur."
        , "Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti."
        ]
        [ ( UI.Purple, ScrollToTop, "Scroll to Top ↑" )
        , ( UI.Primary, ScrollToParagraphOne, "Scroll to Paragraph One ↑" )
        , ( UI.Success, ScrollToParagraphTwo, "Scroll to Paragraph Two ↑" )
        , ( UI.Warning, ScrollToBottom, "Scroll to Bottom ↓" )
        ]
    , -- Add some space after content
      el
        [ height (px 500)
        , centerX
        ]
        (text "...")
    ]
