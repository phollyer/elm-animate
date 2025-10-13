module ElmUI.Scroll.Basic.Main exposing (main)

import Browser exposing (Document)
import Browser.Dom
import Common.Colors as Colors
import Common.Styles as Styles
import Common.UI as UI
import Element exposing (Element, alignLeft, centerX, column, el, fill, height, htmlAttribute, layout, link, maximum, padding, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import SmoothMoveScroll exposing (animateToCmd, animateToCmdWithConfig, animateToTask, defaultConfig)
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ScrollToParagraphOne ->
            ( model, animateToCmdWithConfig NoOp { defaultConfig | speed = 20 } "paragraph-one" )

        ScrollToParagraphTwo ->
            ( model, animateToCmdWithConfig NoOp { defaultConfig | speed = 20 } "paragraph-two" )

        ScrollToParagraphThree ->
            ( model, animateToCmdWithConfig NoOp { defaultConfig | speed = 20 } "paragraph-three" )

        ScrollToTop ->
            ( model, animateToCmdWithConfig NoOp { defaultConfig | speed = 20 } "top" )



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
    [ -- Back Button
      UI.backButton
    , -- Header
      UI.pageHeader "SmoothMoveScroll Document Example"
    , -- Technical information
      UI.techInfo
        [ UI.techParagraph
            [ text "This example demonstrates the SmoothMoveScroll module, which provides "
            , UI.highlight "task-based scrolling animations"
            , text " with composable error handling. It offers "
            , UI.highlight "smooth document navigation"
            , text " using the browser's native scrolling capabilities with customizable easing and timing controls."
            ]
        , UI.techParagraph
            [ text "Perfect for applications requiring "
            , UI.highlight "sequential animations"
            , text " and reliable scrolling operations with comprehensive error handling and task composition."
            ]
        , UI.techParagraph
            [ text "For beginners, this module provides an easy-to-use, fully managed approach that returns "
            , UI.highlight "Cmds"
            , text " rather than "
            , UI.highlight "Tasks"
            , text "."
            ]
        ]
        -- Buttons
    , el [ centerX ] <| 
      UI.htmlActionButtons
        [ ( UI.Primary, ScrollToParagraphOne, "Scroll to Paragraph One ↓" )
        , ( UI.Success, ScrollToParagraphTwo, "Scroll to Paragraph Two ↓" )
        , ( UI.Purple, ScrollToParagraphThree, "Scroll to Paragraph Three ↓" )
        ]
    , -- Add some space before content
      el [ height (px 100) ] (text "")
    , -- Paragraph One
      UI.contentSectionSimple "paragraph-one"
        "Paragraph One"
        [ "This is the first paragraph of our example. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
        , "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. "
        , "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium."
        ]
        [ ( UI.Purple, ScrollToTop, "Scroll to Top ↑" )
        
        , ( UI.Success, ScrollToParagraphTwo, "Scroll to Paragraph Two ↓" )
        , ( UI.Purple, ScrollToParagraphThree, "Scroll to Paragraph Three ↓" )
        ]
    , -- Add space between paragraphs
      el [ height (px 200) ] (text "")
    , -- Paragraph Two
      UI.contentSectionSimple "paragraph-two"
        "Paragraph Two"
        [ "This is the second paragraph. Totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo."
        , "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt."
        , "Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem."
        ] 
        [ ( UI.Purple, ScrollToTop, "Scroll to Top ↑" )
        ,( UI.Primary, ScrollToParagraphOne, "Scroll to Paragraph One ↑" )
        , ( UI.Purple, ScrollToParagraphThree, "Scroll to Paragraph Three ↓" )
        ]
    , -- Add space between paragraphs
      el [ height (px 100) ] (text "")
    , -- Paragraph Three
      UI.contentSectionSimple "paragraph-three"
        "Paragraph Three"
        [ "This is the third and final paragraph. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam."
        , "Nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur."
        , "Vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti."
        ] 
        [ ( UI.Purple, ScrollToTop, "Scroll to Top ↑" )
        ,( UI.Primary, ScrollToParagraphOne, "Scroll to Paragraph One ↑" )
        , ( UI.Success, ScrollToParagraphTwo, "Scroll to Paragraph Two ↑" )
        
        ]
    , -- Add some space after content
      el
        [ height (px 500)
        , centerX
        ]
        (text "...")
    ]
