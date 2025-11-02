module ElmUI.Scroll.DocumentXY.Main exposing (main)

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Scroll exposing (Axis(..), ElementId, defaultConfig)
import Scroll.Document.Cmd as Scroll
import Task



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = (\_ -> Sub.none)
        }



-- MODEL


type alias Model =
    {}


init : () -> ( Model, Cmd Msg )
init _ =
    ( {}, Cmd.none )



scrollTo : ElementId -> Cmd Msg
scrollTo targetId =
    Scroll.scrollWithConfig targetId NoOp <|
        { defaultConfig
            | axis = Both
            , offsetY = 0
        }
        
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
            ( model , scrollTo "top-left" )

        ScrollToTopRight ->
            ( model, scrollTo "top-right" )

        ScrollToBottomLeft ->
            ( model, scrollTo "bottom-left" )

        ScrollToBottomRight ->
            ( model, scrollTo "bottom-right" )

        ScrollToCenter ->
            ( model, scrollTo "center" )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveScroll Diagonal Both Axis - ElmUI Example" UI.Diagonal (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ -- Back Button
      UI.backButton
    , -- Title
      UI.pageHeader "Diagonal Both Axis Scrolling"
    , -- Navigation Buttons
      column
        [ spacing 20
        , centerX
        ]
        [ el
            [ Font.size 18
            , Font.semiBold
            , Font.color Colors.textMedium
            , centerX
            ]
            (text "Navigate Diagonally:")
        , UI.htmlActionButtons
            [ ( UI.Primary, ScrollToTopLeft, "↖ Top Left" )
            , ( UI.Success, ScrollToTopRight, "↗ Top Right" )
            , ( UI.Purple, ScrollToCenter, "🎯 Center" )
            , ( UI.Warning, ScrollToBottomLeft, "↙ Bottom Left" )
            , ( UI.Warning, ScrollToBottomRight, "↘ Bottom Right" )
            ]
        ]
    , -- Simple 2x2 Grid Layout
      viewSimpleGrid
    ]


viewSimpleGrid : Element Msg
viewSimpleGrid =
    column
        [ width (px 1800)
        , spacing 100
        , paddingXY 40 80
        , htmlAttribute (Html.Attributes.class "simple-grid")
        ]
        [ -- Top Row
          row
            [ width fill
            , spacing 100
            ]
            [ viewCard "top-left"
                "↖ TOP LEFT"
                (rgb255 59 130 246)
                [ "This is the top-left corner of our diagonal scrolling demonstration."
                , "Click the '↖ Top Left' button to animate diagonally to this position."
                , "The Both axis scrolling moves smoothly in X and Y directions simultaneously."
                ]
            , el [ width (fill |> maximum 600) ] (text "") -- Spacer
            , viewCard "top-right"
                "↗ TOP RIGHT"
                (rgb255 16 185 129)
                [ "Welcome to the top-right corner!"
                , "Notice how the diagonal animation moves both horizontally and vertically."
                , "This demonstrates the power of Both axis configuration."
                ]
            ]
        , -- Center Row
          row
            [ width fill
            , spacing 100
            ]
            [ el [ width (fill |> maximum 600) ] (text "") -- Spacer (increased to match other rows)
            , viewCard "center"
                "🎯 CENTER"
                (rgb255 168 85 247)
                [ "This is the center position of our layout."
                , "From any corner, clicking 'Center' creates a perfect diagonal scroll."
                , "The center demonstrates Both axis interpolation at its finest."
                ]
            , el [ width (fill |> maximum 600) ] (text "") -- Spacer (increased to match other rows)
            ]
        , -- Bottom Row
          row
            [ width fill
            , spacing 100
            ]
            [ viewCard "bottom-left"
                "↙ BOTTOM LEFT"
                (rgb255 245 101 101)
                [ "You've reached the bottom-left corner."
                , "Try navigating to different corners to see diagonal movement."
                , "Each animation smoothly interpolates between start and end positions."
                ]
            , el [ width (fill |> maximum 600) ] (text "") -- Spacer
            , viewCard "bottom-right"
                "↘ BOTTOM RIGHT"
                (rgb255 251 146 60)
                [ "This is the bottom-right corner, the final destination."
                , "The diagonal scrolling works perfectly in all directions!"
                , "Both axis scrolling makes complex layouts easy to navigate."
                ]
            ]
        ]


viewCard : String -> String -> Element.Color -> List String -> Element Msg
viewCard targetId title color contentLines =
    column
        [ width (fill |> maximum 500)  
        , spacing 16
        , htmlAttribute (Html.Attributes.id targetId)
        , htmlAttribute (Html.Attributes.class "responsive-paragraph")
        , Background.color color
        , paddingXY 24 20
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 12
            , color = Element.rgba 0 0 0 0.15
            }
        ]
        [ -- Corner Title
          el
            [ Font.size 20
            , Font.semiBold
            , Font.color (rgb255 255 255 255)
            , centerX
            ]
            (text title)
        , -- Corner Content
          column
            [ spacing 12
            , width fill
            ]
            (List.map
                (\line ->
                    paragraph
                        [ Font.size 14
                        , Font.center
                        , Font.color (rgb255 255 255 255)
                        , width fill
                        ]
                        [ text line ]
                )
                contentLines
            )
        , -- Navigation Buttons
          column
            [ spacing 8
            , width fill
            , paddingXY 0 12
            ]
            [ el
                [ Font.size 12
                , Font.semiBold
                , Font.color (rgb255 255 255 255)
                , centerX
                ]
                (text "Navigate to:")
            , row
                [ spacing 12
                , width fill
                ]
                (List.map (\(style, msg, label) ->
                    UI.actionButton style msg label
                ) (getNavigationButtons targetId))
            ]
        ]


getNavigationButtons : String -> List ( UI.ButtonStyle, Msg, String )
getNavigationButtons currentId =
    case currentId of
        "top-left" ->
            [ ( UI.Success, ScrollToTopRight, "↗ TR" )
            , ( UI.Purple, ScrollToCenter, "🎯 C" )
            , ( UI.Warning, ScrollToBottomLeft, "↙ BL" )
            , ( UI.Primary, ScrollToBottomRight, "↘ BR" )
            ]
        
        "top-right" ->
            [ ( UI.Primary, ScrollToTopLeft, "↖ TL" )
            , ( UI.Purple, ScrollToCenter, "🎯 C" )
            , ( UI.Warning, ScrollToBottomLeft, "↙ BL" )
            , ( UI.Success, ScrollToBottomRight, "↘ BR" )
            ]
        
        "center" ->
            [ ( UI.Primary, ScrollToTopLeft, "↖ TL" )
            , ( UI.Success, ScrollToTopRight, "↗ TR" )
            , ( UI.Warning, ScrollToBottomLeft, "↙ BL" )
            , ( UI.Purple, ScrollToBottomRight, "↘ BR" )
            ]
        
        "bottom-left" ->
            [ ( UI.Primary, ScrollToTopLeft, "↖ TL" )
            , ( UI.Success, ScrollToTopRight, "↗ TR" )
            , ( UI.Purple, ScrollToCenter, "🎯 C" )
            , ( UI.Warning, ScrollToBottomRight, "↘ BR" )
            ]
        
        "bottom-right" ->
            [ ( UI.Primary, ScrollToTopLeft, "↖ TL" )
            , ( UI.Success, ScrollToTopRight, "↗ TR" )
            , ( UI.Purple, ScrollToCenter, "🎯 C" )
            , ( UI.Warning, ScrollToBottomLeft, "↙ BL" )
            ]
        
        _ ->
            []
