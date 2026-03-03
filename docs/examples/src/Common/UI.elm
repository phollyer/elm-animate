module Common.UI exposing
    ( ButtonStyle(..)
    , LayoutType(..)
    , actionButton
    , backButton
    , backButtonWithPath
    , bulletPoint
    , contentBlock
    , contentSection
    , createDocument
    , getCardColor
    , highlight
    , htmlButton
    , pageHeader
    , techInfo
    , techParagraph
    , wrappedButtonRow
    )

import Browser exposing (Document)
import Common.Colors as Colors
import Element exposing (Element, alignLeft, alignTop, centerX, column, el, fill, height, htmlAttribute, layout, link, maximum, padding, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Html.Events



-- LAYOUT TYPES


type LayoutType
    = Basic
    | Diagonal
    | Container
    | HorizontalContainer



-- DOCUMENT HELPERS


createDocument : String -> LayoutType -> List (Element msg) -> Document msg
createDocument title layoutType content =
    { title = title
    , body = [ layout (getLayoutAttributes layoutType) (mainContent content) ]
    }


getLayoutAttributes : LayoutType -> List (Element.Attribute msg)
getLayoutAttributes layoutType =
    let
        baseAttributes =
            [ Background.gradient
                { angle = 0
                , steps =
                    [ Colors.backgroundLight
                    , Colors.backgroundMedium
                    ]
                }
            , paddingXY 40 20
            ]

        specificAttributes =
            case layoutType of
                Basic ->
                    [ htmlAttribute (Html.Attributes.class "responsive-layout") ]

                Diagonal ->
                    [ width fill
                    , height fill
                    , htmlAttribute (Html.Attributes.class "diagonal-layout responsive-layout")
                    ]

                Container ->
                    [ htmlAttribute (Html.Attributes.class "container-layout responsive-layout") ]

                HorizontalContainer ->
                    [ htmlAttribute (Html.Attributes.class "container-layout responsive-layout") ]
    in
    baseAttributes ++ specificAttributes



-- BACK BUTTON


backButton : Element msg
backButton =
    backButtonWithPath "../../index.html"


backButtonWithPath : String -> Element msg
backButtonWithPath path =
    link
        [ alignLeft
        , padding 12
        , Background.gradient
            { angle = 0
            , steps = [ Colors.primary, Colors.primaryLight ]
            }
        , Font.color Colors.backgroundWhite
        , Font.semiBold
        , Border.rounded 8
        ]
        { url = path
        , label = text "← Back to Examples"
        }



-- PAGE HEADER


pageHeader : String -> Element msg
pageHeader title =
    paragraph
        [ Font.size 28
        , Font.semiBold
        , Font.color Colors.textDark
        , Font.center
        ]
        [ text title ]



-- TECHNICAL INFO CONTAINER


techInfo : List (Element msg) -> Element msg
techInfo content =
    column
        [ spacing 16
        , width (maximum 1200 fill)
        , centerX
        , paddingXY 32 24
        , Background.color Colors.backgroundLight
        , Border.rounded 8
        , Border.solid
        , Border.width 1
        , Border.color Colors.borderLight
        , htmlAttribute (Html.Attributes.class "responsive-tech-info")
        ]
        content



-- STANDARD PARAGRAPH


techParagraph : List (Element msg) -> Element msg
techParagraph content =
    Element.paragraph
        [ Font.size 16
        , Font.color Colors.textMedium
        , width fill
        ]
        content



-- HIGHLIGHTED TEXT


highlight : String -> Element msg
highlight text =
    el [ Font.semiBold ] (Element.text text)



-- MAIN CONTENT CONTAINER


mainContent : List (Element msg) -> Element msg
mainContent content =
    column
        [ width fill
        , spacing 40
        , centerX
        , htmlAttribute (Html.Attributes.class "responsive-container")
        ]
        content



-- BUTTON CONTAINER


buttonContainer : List (Element msg) -> Element msg
buttonContainer buttons =
    column
        [ spacing 20
        , centerX
        , htmlAttribute (Html.Attributes.class "responsive-buttons")
        ]
        buttons



-- ACTION BUTTON


type ButtonStyle
    = Primary
    | Success
    | Purple
    | Warning


actionButton : ButtonStyle -> msg -> String -> Element msg
actionButton style onPress label =
    let
        ( startColor, endColor ) =
            case style of
                Primary ->
                    ( Colors.primary, Element.rgb255 37 99 235 )

                Success ->
                    ( Colors.success, Colors.successDark )

                Purple ->
                    ( Colors.purple, Colors.purpleDark )

                Warning ->
                    ( Colors.warning, Colors.warningDark )
    in
    Input.button
        [ Background.gradient
            { angle = 0
            , steps = [ startColor, endColor ]
            }
        , Font.color Colors.backgroundWhite
        , Font.medium
        , paddingXY 24 12
        , Border.rounded 8
        , centerX
        ]
        { onPress = Just onPress
        , label = text label
        }



-- CONTENT SECTION


{-| Flexible content section that works for all use cases
-}
contentSection :
    { id : String
    , title : String
    , titleColor : Maybe Element.Color
    , content : List String
    , buttons : List ( ButtonStyle, msg, String )
    , width : Maybe Int -- Nothing for full width, Just px for fixed width
    , centerTitle : Bool
    }
    -> Element msg
contentSection config =
    let
        widthAttr =
            case config.width of
                Nothing ->
                    [ width fill
                    , centerX
                    ]

                Just px ->
                    [ width (Element.px px)
                    , height fill
                    ]

        titleColor =
            Maybe.withDefault Colors.textDark config.titleColor

        titleAlignment =
            if config.centerTitle then
                [ centerX ]

            else
                []
    in
    column
        ([ spacing 20
         , htmlAttribute (Html.Attributes.id config.id)
         , htmlAttribute (Html.Attributes.class "responsive-paragraph")
         , Background.color Colors.backgroundWhite
         , paddingXY 32 24
         , Border.rounded 12
         , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }
         ]
            ++ widthAttr
        )
        ([ el
            ([ Font.size 24
             , Font.semiBold
             , Font.color titleColor
             ]
                ++ titleAlignment
            )
            (text config.title)
         , case config.width of
            Nothing ->
                Element.paragraph
                    [ spacing 16
                    , Font.size 16
                    , Font.color Colors.textMedium
                    , width (maximum 1200 fill)
                    ]
                    (List.map (\line -> text line) config.content)

            Just _ ->
                column
                    [ spacing 16
                    , width fill
                    ]
                    (List.map
                        (\line ->
                            paragraph
                                [ Font.size 16
                                , Font.color Colors.textMedium
                                , width fill
                                ]
                                [ text line ]
                        )
                        config.content
                    )
         ]
            ++ [ wrappedButtonRow config.buttons ]
        )



-- CONTENT BLOCK (for numbered sections)


{-| Numbered content block for container examples
-}
contentBlock : Int -> String -> Element msg
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



-- SMALL ACTION BUTTON (for continue buttons)
-- CARD COLORS FOR HORIZONTAL CONTAINER


getCardColor : Int -> Element.Color
getCardColor cardNum =
    case modBy 8 cardNum + 1 of
        1 ->
            Colors.primary

        -- Blue
        2 ->
            Colors.success

        -- Green
        3 ->
            Colors.purple

        -- Purple
        4 ->
            Colors.warning

        -- Red/Orange
        5 ->
            Colors.warning

        -- Orange
        6 ->
            Colors.primaryLight

        -- Sky Blue
        7 ->
            Colors.purple

        -- Violet
        _ ->
            Colors.success



-- HTML-BASED BUTTON GROUPS


htmlButton : ( ButtonStyle, msg, String ) -> Html.Html msg
htmlButton ( style, onPress, label ) =
    let
        getButtonStyleClass =
            case style of
                Primary ->
                    "primary"

                Success ->
                    "success"

                Purple ->
                    "purple"

                Warning ->
                    "warning"
    in
    Html.button
        [ Html.Events.onClick onPress
        , Html.Attributes.class ("ui-action-button " ++ getButtonStyleClass)
        ]
        [ Html.text label ]


{-| Create a button group using pure CSS classes
All styling is handled by the ui-components.css file

ElmUI's built-in `wrappedRow` is tricky to style responsively, so using HTML here is simpler.
These will wrap correctly so that all buttons are centered horizontally, wrapped or not.

-}
wrappedButtonRow : List ( ButtonStyle, msg, String ) -> Element msg
wrappedButtonRow buttons =
    let
        htmlButtons =
            List.map htmlButton buttons
    in
    Element.el [ centerX ] <|
        Element.html
            (Html.div
                [ Html.Attributes.class "ui-wrapped-row" ]
                htmlButtons
            )
