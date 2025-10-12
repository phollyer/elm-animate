module ElmUI.SmoothMoveScroll.Container exposing (main)

import Browser exposing (Document)
import Common.Colors as Colors
import Common.Styles as Styles
import Common.UI as UI
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import SmoothMoveScroll exposing (animateToCmdWithConfig, containerElement, defaultConfig, setContainer)



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
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
    | ScrollToTop
    | ScrollToMiddle
    | ScrollToBottom


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ScrollToTop ->
            ( model
            , animateToCmdWithConfig NoOp (setContainer "scroll-container" { defaultConfig | speed = 20 }) "top-element"
            )

        ScrollToMiddle ->
            ( model
            , animateToCmdWithConfig NoOp { defaultConfig | container = containerElement "scroll-container", speed = 20 } "middle-element"
            )

        ScrollToBottom ->
            ( model
            , animateToCmdWithConfig NoOp (setContainer "scroll-container" { defaultConfig | speed = 20 }) "bottom-element"
            )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveScroll - Container Scrolling (ElmUI)" UI.Container (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "SmoothMoveScroll - Container Example"
    , UI.techInfo
        [ UI.techParagraph
            [ text "This example demonstrates the SmoothMoveScroll module handling "
            , UI.highlight "container-specific scrolling"
            , text " with boundary detection and viewport calculations. It provides "
            , UI.highlight "precise element positioning"
            , text " within scrollable containers while respecting container bounds and scroll limits."
            ]
        , UI.techParagraph
            [ text "Perfect for applications with "
            , UI.highlight "nested scrollable content"
            , text " requiring smooth navigation within constrained viewport areas and complex layout hierarchies."
            ]
        ]
    , UI.htmlActionButtons
        [ ( UI.Primary, ScrollToTop, "Scroll to Top" )
        , ( UI.Success, ScrollToMiddle, "Scroll to Middle" )
        , ( UI.Purple, ScrollToBottom, "Scroll to Bottom" )
        ]
    , -- The scrollable container
      el [ width fill, htmlAttribute (Html.Attributes.class "scroll-container-wrapper") ] <|
        el
            [ htmlAttribute (Html.Attributes.id "scroll-container")
            , width fill
            , height (px 600)
            , Border.width 2
            , Border.color Colors.borderMedium
            , Border.rounded 12
            , Background.color Colors.backgroundWhite
            , Border.shadow
                { offset = ( 0, 4 )
                , size = 0
                , blur = 20
                , color = rgba255 0 0 0 0.1
                }
            , scrollbarY
            , clipY
            ]
            (Element.column
                [ width fill
                , spacing 30
                , paddingXY 30 30
                ]
                [ -- Top element
                  el
                    [ htmlAttribute (Html.Attributes.id "top-element")
                    , width fill
                    , Background.gradient
                        { angle = 180
                        , steps =
                            [ Colors.backgroundWhite
                            , Colors.primaryLight
                            ]
                        }
                    , Border.color Colors.primary
                    , Border.width 2
                    , Border.rounded 12
                    , padding 25
                    , spacing 15
                    ]
                    (Element.column
                        [ spacing 15 ]
                        [ el
                            [ Font.size 24
                            , Font.bold
                            , Font.color Colors.primary
                            , htmlAttribute (Html.Attributes.class "responsive-content-title")
                            ]
                            (text "🔝 Top of Container")
                        , paragraph
                            [ Font.size 16
                            , Font.color Colors.primary
                            , spacing 6
                            , width fill
                            , htmlAttribute (Html.Attributes.class "responsive-content-description")
                            ]
                            [ text "This is the top of the scrollable container content. The background gradient helps visualize scroll position." ]
                        , paragraph
                            [ Font.size 16
                            , Font.color Colors.primary
                            , spacing 6
                            , width fill
                            , htmlAttribute (Html.Attributes.class "responsive-content-description")
                            ]
                            [ text "Click 'Scroll to Top' to smoothly scroll to this position using ElmUI." ]
                        ]
                    )

                -- Content blocks 1-3
                , contentBlock 1 "This is content block 1. Each block adds to the scrollable height and demonstrates ElmUI styling."
                , contentBlock 2 "Content block 2 continues the gradient transition from white to dark with ElmUI elements."
                , contentBlock 3 "Content block 3 shows the middle section of our scrollable content using ElmUI layout."

                -- Middle element
                , el
                    [ htmlAttribute (Html.Attributes.id "middle-element")
                    , width fill
                    , Background.gradient
                        { angle = 180
                        , steps =
                            [ Colors.backgroundWhite
                            , Colors.primaryLight
                            ]
                        }
                    , Border.color Colors.success
                    , Border.width 2
                    , Border.rounded 12
                    , padding 25
                    , spacing 15
                    ]
                    (Element.column
                        [ spacing 15 ]
                        [ el
                            [ Font.size 24
                            , Font.bold
                            , Font.color Colors.successDark
                            , htmlAttribute (Html.Attributes.class "responsive-content-title")
                            ]
                            (text "🎯 Content Block 4 - Middle Target")
                        , paragraph
                            [ Font.size 16
                            , Font.color Colors.successDark
                            , spacing 6
                            , width fill
                            , htmlAttribute (Html.Attributes.class "responsive-content-description")
                            ]
                            [ text "This is the middle target of our scrollable content - Content block 4 demonstrates the progression through the gradient with ElmUI styling." ]
                        , paragraph
                            [ Font.size 16
                            , Font.color Colors.successDark
                            , spacing 6
                            , width fill
                            , htmlAttribute (Html.Attributes.class "responsive-content-description")
                            ]
                            [ text "Click 'Scroll to Middle' to smoothly scroll to this position." ]
                        , Element.column
                            [ spacing 8 ]
                            [ bulletPoint "This block serves as the middle anchor point"
                            , bulletPoint "The gradient background shows scroll position"
                            , bulletPoint "Smooth scrolling animates between positions"
                            ]
                        ]
                    )

                -- Content blocks 5-8
                , contentBlock 5 "Content block 5 continues toward the bottom of the container with ElmUI."
                , contentBlock 6 "Content block 6 shows we're getting closer to the bottom using ElmUI layout."
                , contentBlock 7 "Content block 7 is near the end with darker background colors in ElmUI."
                , contentBlock 8 "Content block 8 is almost at the bottom of the scrollable ElmUI content."

                -- Bottom element
                , el
                    [ htmlAttribute (Html.Attributes.id "bottom-element")
                    , width fill
                    , Background.gradient
                        { angle = 180
                        , steps =
                            [ Colors.backgroundWhite
                            , Colors.warning
                            ]
                        }
                    , Border.color Colors.warningDark
                    , Border.width 2
                    , Border.rounded 12
                    , padding 25
                    , spacing 15
                    ]
                    (Element.column
                        [ spacing 15 ]
                        [ el
                            [ Font.size 24
                            , Font.bold
                            , Font.color Colors.warningDark
                            , htmlAttribute (Html.Attributes.class "responsive-content-title")
                            ]
                            (text "🔻 Bottom of Container")
                        , paragraph
                            [ Font.size 16
                            , Font.color Colors.warningDark
                            , spacing 6
                            , width fill
                            , htmlAttribute (Html.Attributes.class "responsive-content-description")
                            ]
                            [ text "This is the bottom of the scrollable container content. Notice the dark background created with ElmUI gradients." ]
                        , paragraph
                            [ Font.size 16
                            , Font.color Colors.warningDark
                            , spacing 6
                            , width fill
                            , htmlAttribute (Html.Attributes.class "responsive-content-description")
                            ]
                            [ text "Click 'Scroll to Bottom' to smoothly scroll to this position." ]
                        , paragraph
                            [ Font.size 16
                            , Font.color (rgb255 153 27 27)
                            , spacing 6
                            , width fill
                            , htmlAttribute (Html.Attributes.class "responsive-content-description")
                            ]
                            [ text "The smooth animation works reliably using the new SmoothMoveScroll API with ElmUI." ]
                        ]
                    )
                ]
            )
    ]



-- HELPER FUNCTIONS


contentBlock : Int -> String -> Element Msg
contentBlock num description =
    el
        [ width fill
        , Background.gradient
            { angle = 180
            , steps =
                [ Colors.backgroundWhite
                , Colors.backgroundLight
                ]
            }
        , Border.color Colors.borderMedium
        , Border.width 1
        , Border.rounded 8
        , padding 20
        , spacing 15
        ]
        (Element.column
            [ spacing 12
            , width fill
            , htmlAttribute (Html.Attributes.class "responsive-content-block")
            ]
            [ el
                [ Font.size 20
                , Font.semiBold
                , Font.color Colors.textDark
                , htmlAttribute (Html.Attributes.class "responsive-content-title")
                ]
                (text ("Content Block " ++ String.fromInt num))
            , paragraph
                [ Font.size 16
                , Font.color Colors.textMedium
                , spacing 6
                , width fill
                , htmlAttribute (Html.Attributes.class "responsive-content-description")
                ]
                [ text description ]
            , Element.column
                [ spacing 6
                , width fill
                , htmlAttribute (Html.Attributes.class "responsive-bullet-list")
                ]
                [ bulletPoint "Each block adds to the scrollable height"
                , bulletPoint "The gradient background shows scroll position"
                , bulletPoint "Smooth scrolling animates between positions"
                ]
            ]
        )


bulletPoint : String -> Element msg
bulletPoint text_ =
    row
        [ spacing 8
        , width fill
        , htmlAttribute (Html.Attributes.class "responsive-bullet-point")
        ]
        [ el
            [ Font.size 16
            , Font.color Colors.warning
            , alignTop
            ]
            (text "•")
        , paragraph
            [ Font.size 16
            , Font.color Colors.textMedium
            , width fill
            ]
            [ text text_ ]
        ]
