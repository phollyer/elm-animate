module Common.UI exposing (..)

import Browser exposing (Document)
import Common.Colors as Colors
import Common.Styles as Styles
import Element exposing (Element, alignLeft, centerX, column, el, fill, height, htmlAttribute, layout, link, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
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
    | Horizontal
    | HorizontalCustomWidth Float
    | Diagonal
    | Container
    | HorizontalContainer



-- LAYOUT WIDTH CALCULATIONS


{-| Calculate the total width needed for horizontal layouts based on content dimensions
-}
calculateHorizontalWidth : { sectionCount : Int, sectionWidth : Int, spacing : Int, containerPaddingX : Int, layoutPaddingX : Int } -> Int
calculateHorizontalWidth { sectionCount, sectionWidth, spacing, containerPaddingX, layoutPaddingX } =
    let
        totalSectionWidth = sectionCount * sectionWidth
        totalSpacingWidth = (sectionCount - 1) * spacing  -- gaps between sections
        totalPaddingWidth = containerPaddingX + layoutPaddingX
    in
    totalSectionWidth + totalSpacingWidth + totalPaddingWidth


-- DOCUMENT HELPERS


createDocument : String -> LayoutType -> List (Element msg) -> Document msg
createDocument title layoutType content =
    { title = title
    , body =
        [ Html.node "style" [] [ Html.text (getLayoutCSS layoutType) ]
        , layout (getLayoutAttributes layoutType) (mainContent content)
        ]
    }


getLayoutCSS : LayoutType -> String
getLayoutCSS layoutType =
    let
        -- Base CSS that all layouts need
        baseCSS =
            Styles.responsiveCSS ++ "\n" ++ Styles.buttonGroupCSS ++ "\n" ++ Styles.responsiveContentCSS
    in
    case layoutType of
        Basic ->
            baseCSS

        Horizontal ->
            baseCSS ++ "\n" ++ Styles.horizontalCSS

        HorizontalCustomWidth _ ->
            baseCSS ++ "\n" ++ Styles.horizontalCSS

        Diagonal ->
            baseCSS ++ "\n" ++ Styles.diagonalCSS

        Container ->
            baseCSS ++ "\n" ++ Styles.containerCSS

        HorizontalContainer ->
            baseCSS ++ "\n" ++ Styles.horizontalContainerCSS


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

                Horizontal ->
                    let
                        -- HorizontalBasic example: 4 sections × 300px + spacing 40px + container padding 40px + layout padding 80px
                        calculatedWidth = calculateHorizontalWidth
                            { sectionCount = 4
                            , sectionWidth = 300
                            , spacing = 40
                            , containerPaddingX = 40  -- paddingXY 20 20 = 20px left + 20px right
                            , layoutPaddingX = 80     -- paddingXY 40 20 = 40px left + 40px right
                            }
                    in
                    [ width (px calculatedWidth)
                    , height fill
                    , htmlAttribute (Html.Attributes.class "horizontal-layout responsive-layout")
                    ]

                HorizontalCustomWidth customWidth ->
                    [ width (px (round customWidth))
                    , height fill
                    , htmlAttribute (Html.Attributes.class "horizontal-layout responsive-layout")
                    ]

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
        , htmlAttribute (Html.Attributes.id "top")
        ]
        { url = "../index.html"
        , label = text "← Back to Examples"
        }



-- PAGE HEADER


pageHeader : String -> Element msg
pageHeader title =
    paragraph
        [ Font.semiBold
        , Font.color Colors.textDark
        , centerX
        , htmlAttribute (Html.Attributes.class "responsive-header")
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


contentSection : String -> String -> List String -> Maybe (Element msg) -> Element msg
contentSection sectionId title content maybeButton =
    column
        [ spacing 20
        , htmlAttribute (Html.Attributes.id sectionId)
        , htmlAttribute (Html.Attributes.class "responsive-paragraph")
        , Background.color Colors.backgroundWhite
        , centerX
        , paddingXY 32 24
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }
        ]
        ([ el
            [ Font.size 24
            , Font.semiBold
            , Font.color Colors.textDark
            ]
            (text title)
         , Element.paragraph
            [ spacing 16
            , Font.size 16
            , Font.color Colors.textMedium
            , width (maximum 1200 fill)
            ]
            (List.map (\line -> text line) content)
         ]
            ++ (case maybeButton of
                    Just button ->
                        [ button ]

                    Nothing ->
                        []
               )
        )



-- SMALL ACTION BUTTON (for continue buttons)


smallActionButton : ButtonStyle -> msg -> String -> Element msg
smallActionButton style onPress label =
    let
        buttonColor =
            case style of
                Primary ->
                    Colors.primary

                Success ->
                    Colors.success

                Purple ->
                    Colors.purple

                Warning ->
                    Colors.warning

        backgroundColor =
            case style of
                Primary ->
                    Element.rgb255 239 246 255

                Success ->
                    Element.rgb255 240 253 244

                Purple ->
                    Element.rgb255 250 245 255

                Warning ->
                    Element.rgb255 255 251 235

        borderColor =
            case style of
                Primary ->
                    Element.rgb255 191 219 254

                Success ->
                    Element.rgb255 209 250 229

                Purple ->
                    Element.rgb255 233 213 255

                Warning ->
                    Element.rgb255 254 240 138
    in
    Input.button
        [ Font.size 14
        , Font.color buttonColor
        , Font.medium
        , paddingXY 12 8
        , Border.rounded 6
        , Background.color backgroundColor
        , Border.width 1
        , Border.color borderColor
        ]
        { onPress = Just onPress
        , label = text label
        }



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



-- Emerald


darkenColor : Element.Color -> Element.Color
darkenColor color =
    let
        rgb =
            Element.toRgb color
    in
    rgb255
        (round (rgb.red * 255 * 0.8))
        (round (rgb.green * 255 * 0.8))
        (round (rgb.blue * 255 * 0.8))



-- HTML-BASED BUTTON GROUPS


{-| Create an HTML-based button group that properly wraps and centers
This uses native HTML with .example-links class to avoid ElmUI row limitations
-}
htmlActionButtons : List ( ButtonStyle, msg, String ) -> Element msg
htmlActionButtons buttons =
    let
        createButton ( style, onPress, label ) =
            Html.button
                [ Html.Attributes.class "example-link"
                , Html.Events.onClick onPress
                , Html.Attributes.style "background" (getButtonGradient style)
                ]
                [ Html.text label ]

        getButtonGradient style =
            case style of
                Primary ->
                    "linear-gradient(135deg, #4299e1, #3182ce)"

                Success ->
                    "linear-gradient(135deg, #48bb78, #38a169)"

                Purple ->
                    "linear-gradient(135deg, #9f7aea, #805ad5)"

                Warning ->
                    "linear-gradient(135deg, #ed8936, #dd6b20)"
    in
    el
        [ centerX ]
    <|
        Element.html
            (Html.div
                [ Html.Attributes.class "example-links" ]
                (List.map createButton buttons)
            )
