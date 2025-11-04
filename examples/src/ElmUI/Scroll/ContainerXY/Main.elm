module ElmUI.Scroll.ContainerXY.Main exposing (main)

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
import Scroll exposing (Axis(..), defaultConfig)
import Scroll.Container.Cmd as Scroll



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
    | ScrollToTopLeft
    | ScrollToTopRight
    | ScrollToBottomLeft
    | ScrollToBottomRight
    | ScrollToCenter


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ScrollToTopLeft ->
            ( model
            , Scroll.scrollWithConfig
                "scroll-container"
                "top-left-element"
                NoOp
                { defaultConfig | axis = BothWithOffset 20 20 }
            )

        ScrollToTopRight ->
            ( model
            , Scroll.scrollWithConfig
                "scroll-container"
                "top-right-element"
                NoOp
                { defaultConfig | axis = BothWithOffset 20 20 }
            )

        ScrollToBottomLeft ->
            ( model
            , Scroll.scrollWithConfig
                "scroll-container"
                "bottom-left-element"
                NoOp
                { defaultConfig | axis = BothWithOffset 20 20 }
            )

        ScrollToBottomRight ->
            ( model
            , Scroll.scrollWithConfig
                "scroll-container"
                "bottom-right-element"
                NoOp
                { defaultConfig | axis = BothWithOffset 20 20 }
            )

        ScrollToCenter ->
            ( model
            , Scroll.scrollWithConfig
                "scroll-container"
                "center-element"
                NoOp
                { defaultConfig | axis = BothWithOffset 20 20 }
            )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveScroll Container XY - ElmUI Example" UI.Container (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "Container Both Axis Scrolling"
    , UI.htmlActionButtons
        [ ( UI.Primary, ScrollToTopLeft, "Top Left" )
        , ( UI.Success, ScrollToTopRight, "Top Right" )
        , ( UI.Purple, ScrollToBottomLeft, "Bottom Left" )
        , ( UI.Warning, ScrollToBottomRight, "Bottom Right" )
        , ( UI.Primary, ScrollToCenter, "Center" )
        ]
    , -- Container with scrollable content
      el [ width fill, htmlAttribute (Html.Attributes.class "scroll-container-wrapper") ] <|
        column
            [ htmlAttribute (Html.Attributes.id "scroll-container")
            , width fill
            , height (px 400)
            , scrollbars
            , Border.width 2
            , Border.color Colors.borderLight
            , Border.rounded 8
            , Background.color (rgb255 248 250 252)
            ]
            [ -- Large scrollable grid content
              column
                [ width (px 2000)
                , height (px 2000)
                , padding 40
                , spacing 200
                ]
                [ -- Top row
                  row
                    [ width fill
                    , spacing 400
                    ]
                    [ viewCornerElement "top-left-element" "🔵 Top Left" Colors.primary
                    , el [ width fill ] none
                    , viewCornerElement "top-right-element" "🟢 Top Right" Colors.success
                    ]
                , -- Middle row with center
                  row
                    [ width fill
                    , spacing 400
                    ]
                    [ el [ width (px 300) ] none
                    , viewCornerElement "center-element" "🟡 Center" Colors.warning
                    , el [ width fill ] none
                    ]
                , -- Bottom row
                  row
                    [ width fill
                    , spacing 400
                    ]
                    [ viewCornerElement "bottom-left-element" "🟣 Bottom Left" Colors.purple
                    , el [ width fill ] none
                    , viewCornerElement "bottom-right-element" "🔴 Bottom Right" Colors.red
                    ]
                ]
            ]
    ]


viewCornerElement : String -> String -> Color -> Element Msg
viewCornerElement elementId labelText color =
    column
        [ htmlAttribute (Html.Attributes.id elementId)
        , width (px 300)
        , height (px 200)
        , Background.color color
        , Border.rounded 12
        , padding 20
        , spacing 16
        ]
        [ el
            [ Font.size 24
            , Font.bold
            , Font.color (rgb255 255 255 255)
            , centerX
            ]
            (text labelText)
        , paragraph
            [ Font.size 14
            , Font.color (rgb255 255 255 255)
            , Font.center
            , htmlAttribute (Html.Attributes.class "responsive-content-description")
            ]
            [ text "This element demonstrates container-based scrolling on both X and Y axes. The scroll animation is constrained to the container above, not the entire document." ]
        , el
            [ Background.color (rgba 255 255 255 0.2)
            , Border.rounded 6
            , padding 8
            , centerX
            ]
            (el
                [ Font.size 12
                , Font.color (rgb255 255 255 255)
                , Font.bold
                ]
                (text ("ID: " ++ elementId))
            )
        ]