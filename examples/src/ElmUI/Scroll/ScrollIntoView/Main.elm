module ElmUI.Scroll.ScrollIntoView.Main exposing (main)

{-| Example demonstrating scrollIntoView functionality for bringing elements into view with minimal movement.

This example shows:
- Scrolling various sized elements into view
- Elements that are larger than the viewport (positioned at top-left)
- Elements that are smaller than viewport (minimal movement to make fully visible)
- Both smooth scrolling and instant jumping

-}

import Browser exposing (Document)
import Browser.Events as Event
import Common.UI as UI
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (onClick)
import Element.Font as Font
import Html exposing (Html)
import Html.Attributes
import Scroll.Document.Task as DocumentTask
import Task


-- MODEL


type alias Flags =
    { windowWidth : Int
    , windowHeight : Int
    }


type alias Model =
    { status : String
    , windowWidth : Int
    , windowHeight : Int
    }


initialModel : Flags -> Model
initialModel flags =
    { status = "Ready to scroll elements into view"
    , windowWidth = flags.windowWidth
    , windowHeight = flags.windowHeight
    }


-- UPDATE


type Msg
    = ScrollToElement String
    | JumpToElement String
    | TaskCompleted
    | TaskFailed
    | OnResize Int Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScrollToElement elementId ->
            ( { model | status = "Scrolling to " ++ elementId ++ "..." }
            , DocumentTask.scrollIntoView elementId
                |> Task.attempt (\_ -> TaskCompleted)
            )

        JumpToElement elementId ->
            ( { model | status = "Jumping to " ++ elementId ++ "..." }
            , DocumentTask.jumpIntoView elementId
                |> Task.attempt (\_ -> TaskCompleted)
            )

        TaskCompleted ->
            ( { model | status = "Scroll completed!" }
            , Cmd.none
            )

        TaskFailed ->
            ( { model | status = "Scroll failed!" }
            , Cmd.none
            )

        OnResize newWidth newHeight ->
            ( { model | windowWidth = newWidth, windowHeight = newHeight }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Event.onResize OnResize

-- VIEW


view : Model -> Document Msg
view model =
    { title = "ScrollIntoView Example"
    , body = 
        [ layout 
            [] 
            (column [ width fill, height fill, paddingXY 40 20, spacing 20 ]
                (viewContent model)
            )
        ]
    }


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        -- Calculate container dimensions much larger than viewport
        containerWidth = model.windowWidth * 3
        containerHeight = model.windowHeight * 4
    in
    [ -- Back Button
      UI.backButton
    , -- Header
      UI.pageHeader "ScrollIntoView Example"
    , -- Navigation buttons
      el []
        <|
            UI.htmlActionButtons
                [ ( UI.Primary, ScrollToElement "top-element", "→ Top" )
                , ( UI.Success, ScrollToElement "left-element", "→ Left" )
                , ( UI.Purple, ScrollToElement "center-element", "→ Center" )
                , ( UI.Warning, ScrollToElement "wide-element", "→ Wide" )
                , ( UI.Primary, ScrollToElement "tall-element", "→ Tall" )
                , ( UI.Success, ScrollToElement "right-element", "→ Right" )
                , ( UI.Purple, ScrollToElement "bottom-element", "→ Bottom" )
                ]
    , -- Status info
      row [ width fill, spacing 20, centerX ]
        [ el [ Font.size 16, Font.color (rgb 0.5 0.5 0.5) ] 
            (text ("Window: " ++ String.fromInt model.windowWidth ++ "x" ++ String.fromInt model.windowHeight))
        , el [ Font.size 16, Font.color (rgb 0.5 0.5 0.5) ] (text model.status)
        ]
    , -- Large scrollable content area
      el 
        [ width fill
        , height (px containerHeight)
        ]
        (column [ width (px containerWidth), height fill, spacing 0 ]
                    [ -- Top section
                      contentPanel 
                        "Top Section"
                        (model.windowHeight)
                        (rgb 1.0 0.95 0.95)
                        [ targetElementWithButtons "top-element" "Top Element" 400 200 (rgb 1.0 0.9 0.9)
                            [ ( UI.Primary, ScrollToElement "left-element", "→ Left" )
                            , ( UI.Success, ScrollToElement "center-element", "→ Center" )
                            , ( UI.Purple, ScrollToElement "wide-element", "→ Wide" )
                            , ( UI.Warning, ScrollToElement "tall-element", "→ Tall" )
                            , ( UI.Primary, ScrollToElement "right-element", "→ Right" )
                            , ( UI.Success, ScrollToElement "bottom-element", "→ Bottom" )
                            ]
                        ]
                        []
                    
                    -- Middle horizontal section
                    , el [ height (px (model.windowHeight * 2)), width fill ]
                        (row [ width fill, height fill ]
                            [ -- Left panel
                              contentPanel
                                "Left Panel" 
                                (model.windowHeight * 2)
                                (rgb 0.95 1.0 0.95)
                                [ targetElementWithButtons "left-element" "Left Element" 350 250 (rgb 0.8 1.0 0.8)
                                    [ ( UI.Primary, ScrollToElement "top-element", "→ Top" )
                                    , ( UI.Success, ScrollToElement "center-element", "→ Center" )
                                    , ( UI.Purple, ScrollToElement "wide-element", "→ Wide" )
                                    , ( UI.Warning, ScrollToElement "tall-element", "→ Tall" )
                                    , ( UI.Primary, ScrollToElement "right-element", "→ Right" )
                                    , ( UI.Success, ScrollToElement "bottom-element", "→ Bottom" )
                                    ]
                                ]
                                []
                            
                            -- Center panel
                            , contentPanel
                                "Center Panel"
                                (model.windowHeight * 2) 
                                (rgb 0.95 0.95 1.0)
                                [ targetElementWithButtons "center-element" "Center Element" 300 300 (rgb 0.8 0.9 1.0)
                                    [ ( UI.Primary, ScrollToElement "top-element", "→ Top" )
                                    , ( UI.Success, ScrollToElement "left-element", "→ Left" )
                                    , ( UI.Purple, ScrollToElement "wide-element", "→ Wide" )
                                    , ( UI.Warning, ScrollToElement "tall-element", "→ Tall" )
                                    , ( UI.Primary, ScrollToElement "right-element", "→ Right" )
                                    , ( UI.Success, ScrollToElement "bottom-element", "→ Bottom" )
                                    ]
                                , el [ height (px 100) ] none
                                , targetElementWithButtons "wide-element" "Wide Element" (model.windowWidth + 400) 200 (rgb 1.0 0.9 0.8)
                                    [ ( UI.Primary, ScrollToElement "top-element", "→ Top" )
                                    , ( UI.Success, ScrollToElement "left-element", "→ Left" )
                                    , ( UI.Purple, ScrollToElement "center-element", "→ Center" )
                                    , ( UI.Warning, ScrollToElement "tall-element", "→ Tall" )
                                    , ( UI.Primary, ScrollToElement "right-element", "→ Right" )
                                    , ( UI.Success, ScrollToElement "bottom-element", "→ Bottom" )
                                    ]
                                , el [ height (px 100) ] none
                                , targetElementWithButtons "tall-element" "Tall Element" 400 (model.windowHeight + 200) (rgb 0.9 1.0 0.8)
                                    [ ( UI.Primary, ScrollToElement "top-element", "→ Top" )
                                    , ( UI.Success, ScrollToElement "left-element", "→ Left" )
                                    , ( UI.Purple, ScrollToElement "center-element", "→ Center" )
                                    , ( UI.Warning, ScrollToElement "wide-element", "→ Wide" )
                                    , ( UI.Primary, ScrollToElement "right-element", "→ Right" )
                                    , ( UI.Success, ScrollToElement "bottom-element", "→ Bottom" )
                                    ]
                                ]
                                []
                            
                            -- Right panel
                            , contentPanel
                                "Right Panel"
                                (model.windowHeight * 2)
                                (rgb 1.0 0.95 1.0)
                                [ targetElementWithButtons "right-element" "Right Element" 350 250 (rgb 1.0 0.8 0.8)
                                    [ ( UI.Primary, ScrollToElement "top-element", "→ Top" )
                                    , ( UI.Success, ScrollToElement "left-element", "→ Left" )
                                    , ( UI.Purple, ScrollToElement "center-element", "→ Center" )
                                    , ( UI.Warning, ScrollToElement "wide-element", "→ Wide" )
                                    , ( UI.Primary, ScrollToElement "tall-element", "→ Tall" )
                                    , ( UI.Success, ScrollToElement "bottom-element", "→ Bottom" )
                                    ]
                                ]
                                []
                            ]
                        )
                    
                    -- Bottom section
                    , contentPanel
                        "Bottom Section"
                        (model.windowHeight)
                        (rgb 0.98 0.95 1.0)
                        [ targetElementWithButtons "bottom-element" "Bottom Element" 500 200 (rgb 0.9 0.8 1.0)
                            [ ( UI.Primary, ScrollToElement "top-element", "→ Top" )
                            , ( UI.Success, ScrollToElement "left-element", "→ Left" )
                            , ( UI.Purple, ScrollToElement "center-element", "→ Center" )
                            , ( UI.Warning, ScrollToElement "wide-element", "→ Wide" )
                            , ( UI.Primary, ScrollToElement "tall-element", "→ Tall" )
                            , ( UI.Success, ScrollToElement "right-element", "→ Right" )
                            ]
                        ]
                        []
                    ]
                )
    ]


contentPanel : String -> Int -> Color -> List (Element Msg) -> List (Element Msg) -> Element Msg
contentPanel _ panelHeight bgColor elements _ =
    el 
        [ width fill
        , height (px panelHeight)
        , Background.color bgColor
        , Border.width 2
        , Border.color (rgb 0.7 0.7 0.7)
        ]
        (el [ width fill, height fill, padding 30 ]
            (column [ centerX, centerY, spacing 50 ] elements)
        )


targetElement : String -> String -> Int -> Int -> Color -> Element Msg
targetElement elementId label w h color =
    el
        [ htmlAttribute (Html.Attributes.id elementId)
        , width (px w)
        , height (px h)
        , Background.color color
        , Border.width 2
        , Border.color (rgb 0.3 0.3 0.3)
        , Border.dashed
        ]
        (el [ centerX, centerY, Font.size 16, Font.bold ] (text label))


targetElementWithButtons : String -> String -> Int -> Int -> Color -> List ( UI.ButtonStyle, Msg, String ) -> Element Msg
targetElementWithButtons elementId label w h color buttons =
    el
        [ htmlAttribute (Html.Attributes.id elementId)
        , width (px w)
        , height (px h)
        , Background.color color
        , Border.width 3
        , Border.color (rgb 0.2 0.2 0.2)
        , Border.dashed
        ]
        (column [ centerX, centerY, spacing 15 ]
            [ el [ Font.size 16, Font.bold, centerX ] (text label)
            , column [ spacing 8, centerX ]
                [ el [ Font.size 12, Font.bold, Font.color (rgb 0.4 0.4 0.4), centerX ] (text "Navigate to:")
                , UI.htmlActionButtons buttons
                ]
            ]
        )





-- MAIN


main : Program Flags Model Msg
main =
    Browser.document
        { init = \flags -> ( initialModel flags, Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }