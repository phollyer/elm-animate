module ElmUI.Scroll.Container.Position.Y.Main exposing (main)

import Anim.Engine.Scroll as Scroll
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes



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
    { scrollAnimations : Scroll.AnimState
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { scrollAnimations = Scroll.init }, Cmd.none )


scrollToElement : String -> Cmd Msg
scrollToElement targetId =
    Scroll.init
        |> Scroll.builder
        |> Scroll.container "scroll-container"
        |> Scroll.toElement targetId
        |> Scroll.speed 500
        |> Scroll.toCmd NoOp



-- UPDATE


type Msg
    = NoOp
    | ScrollAnimationMsg Scroll.AnimationMsg
    | ScrollToTop
    | ScrollToMiddle
    | ScrollToBottom


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ScrollAnimationMsg scrollMsg ->
            let
                ( newScrollState, scrollCmd ) =
                    Scroll.update ScrollAnimationMsg scrollMsg model.scrollAnimations
            in
            ( { model | scrollAnimations = newScrollState }
            , scrollCmd
            )

        ScrollToTop ->
            ( model, scrollToElement "top-element" )

        ScrollToMiddle ->
            ( model, scrollToElement "middle-element" )

        ScrollToBottom ->
            ( model, scrollToElement "bottom-element" )


subscriptions : Model -> Sub Msg
subscriptions model =
    Scroll.subscriptions ScrollAnimationMsg model.scrollAnimations



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveScroll - Container Scrolling (ElmUI)" UI.Container (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButtonWithPath "../../../../index.html"
    , UI.pageHeader "ElmUI & Scroll Container Y Example"
    , UI.wrappedButtonRow
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

            --, clipY
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
                , UI.contentBlock 1 "This is content block 1. Each block adds to the scrollable height and demonstrates ElmUI styling."
                , UI.contentBlock 2 "Content block 2 continues the gradient transition from white to dark with ElmUI elements."
                , UI.contentBlock 3 "Content block 3 shows the middle section of our scrollable content using ElmUI layout."

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
                            [ UI.bulletPoint "This block serves as the middle anchor point"
                            , UI.bulletPoint "The gradient background shows scroll position"
                            , UI.bulletPoint "Smooth scrolling animates between positions"
                            ]
                        ]
                    )

                -- Content blocks 5-8
                , UI.contentBlock 5 "Content block 5 continues toward the bottom of the container with ElmUI."
                , UI.contentBlock 6 "Content block 6 shows we're getting closer to the bottom using ElmUI layout."
                , UI.contentBlock 7 "Content block 7 is near the end with darker background colors in ElmUI."
                , UI.contentBlock 8 "Content block 8 is almost at the bottom of the scrollable ElmUI content."

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
