module ElmUI.Scroll.Document.Position.Both.Main exposing (main)

import Anim.Engine.Scroll as Scroll
import Anim.Engine.Scroll.Builder as ScrollTo
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
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
    Scroll.toCmd (\_ -> NoOp) <|
        (Scroll.defaultSpeed 500
            >> ScrollTo.forDocument
            >> ScrollTo.toElement targetId
            >> ScrollTo.onBothAxes
            >> ScrollTo.withOffsetX 20
            >> ScrollTo.withOffsetY 20
            >> ScrollTo.build
        )



-- UPDATE


type Msg
    = NoOp
    | ScrollAnimationMsg Scroll.AnimationMsg
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

        ScrollAnimationMsg scrollMsg ->
            let
                ( newScrollState, scrollCmd ) =
                    Scroll.update ScrollAnimationMsg scrollMsg model.scrollAnimations
            in
            ( { model | scrollAnimations = newScrollState }
            , scrollCmd
            )

        ScrollToTopLeft ->
            ( model, scrollToElement "top-left" )

        ScrollToTopRight ->
            ( model, scrollToElement "top-right" )

        ScrollToBottomLeft ->
            ( model, scrollToElement "bottom-left" )

        ScrollToBottomRight ->
            ( model, scrollToElement "bottom-right" )

        ScrollToCenter ->
            ( model, scrollToElement "center" )


subscriptions : Model -> Sub Msg
subscriptions model =
    Scroll.subscriptions ScrollAnimationMsg model.scrollAnimations



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveScroll Diagonal Both Axis - ElmUI Example" UI.Diagonal (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ -- Back Button
      UI.backButtonWithPath "../../../../index.html"
    , -- Title
      UI.pageHeader "ElmUI & Scroll Document Both Example"
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
        , UI.wrappedButtonRow
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
                (List.map
                    (\( style, msg, label ) ->
                        UI.actionButton style msg label
                    )
                    (getNavigationButtons targetId)
                )
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
