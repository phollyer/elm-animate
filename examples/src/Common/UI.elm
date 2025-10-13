module Common.UI exposing 
    ( LayoutType(..)
    , ButtonStyle(..)
    , createDocument
    , backButton
    , pageHeader
    , techInfo
    , techParagraph
    , highlight
    , actionButton
    , contentSection
    , contentSectionSimple
    , contentBlock
    , contentBlockHtml
    , bulletPoint
    , getCardColor
    , htmlActionButtons
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
        [ layout (getLayoutAttributes layoutType) (mainContent content)
        ]
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
        { url = "../../index.html"
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


{-| Flexible content section that works for all use cases
-}
contentSection : 
    { id : String
    , title : String
    , titleColor : Maybe Element.Color
    , content : List String
    , buttons : List (( ButtonStyle, msg, String ))
    , width : Maybe Int  -- Nothing for full width, Just px for fixed width
    , centerTitle : Bool
    }
    -> Element msg
contentSection config =
    let
        widthAttr = 
            case config.width of
                Nothing -> [ width fill, centerX ]
                Just px -> [ width (Element.px px), height fill ]
                
        titleColor = 
            Maybe.withDefault Colors.textDark config.titleColor
            
        titleAlignment =
            if config.centerTitle then [ centerX ] else []
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
        ] ++ widthAttr)
        ([ el
            ([ Font.size 24
            , Font.semiBold
            , Font.color titleColor
            ] ++ titleAlignment)
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
            ++ [ htmlActionButtons config.buttons]
        )


{-| Simple wrapper for backward compatibility and basic usage
-}
contentSectionSimple : String -> String -> List String -> List (( ButtonStyle, msg, String )) -> Element msg
contentSectionSimple id title content buttons =
    contentSection
        { id = id
        , title = title
        , titleColor = Nothing
        , content = content
        , buttons = buttons
        , width = Nothing
        , centerTitle = False
        }



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


{-| HTML version of content block for HTML examples
-}
contentBlockHtml : Int -> String -> Html.Html msg
contentBlockHtml num description =
    Html.div [ Html.Attributes.class "content-block" ]
        [ Html.h3 [] [ Html.text ("Content Block " ++ String.fromInt num) ]
        , Html.p [] [ Html.text description ]
        , Html.ul []
            [ Html.li [] [ Html.text "Each block adds to the scrollable height" ]
            , Html.li [] [ Html.text "The gradient background shows scroll position" ]
            , Html.li [] [ Html.text "Smooth scrolling animates between positions" ]
            ]
        ]


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



-- Emerald






-- HTML-BASED BUTTON GROUPS


{-| Create a button group with proper flexbox wrapping
This renders each button as HTML and wraps them in a flexbox container
-}
htmlActionButtons : List ( ButtonStyle, msg, String ) -> Element msg
htmlActionButtons buttons =
    let
        -- Create HTML buttons that match the Elm UI actionButton styling
        createHtmlButton (style, onPress, label) =
            let
                (startColor, endColor) = getButtonColors style
            in
            Html.button
                [ Html.Events.onClick onPress
                , Html.Attributes.style "background" ("linear-gradient(135deg, " ++ startColor ++ ", " ++ endColor ++ ")")
                , Html.Attributes.style "color" "white"
                , Html.Attributes.style "font-weight" "500"
                , Html.Attributes.style "padding" "12px 24px"
                , Html.Attributes.style "border" "none"
                , Html.Attributes.style "border-radius" "8px"
                , Html.Attributes.style "cursor" "pointer"
                , Html.Attributes.style "font-size" "14px"
                , Html.Attributes.style "transition" "transform 0.2s, box-shadow 0.2s"
                , Html.Attributes.style "box-shadow" "0 2px 4px rgba(0, 0, 0, 0.1)"
                , Html.Attributes.class "ui-action-button"
                ]
                [ Html.text label ]

        getButtonColors style =
            case style of
                Primary -> ("#4299e1", "#3182ce")
                Success -> ("#48bb78", "#38a169") 
                Purple -> ("#9f7aea", "#805ad5")
                Warning -> ("#ed8936", "#dd6b20")
                
        htmlButtons = List.map createHtmlButton buttons
    in
    Element.el [ centerX ] <| 
    Element.html
        (Html.div
            [ Html.Attributes.style "display" "flex"
            , Html.Attributes.style "gap" "12px"
            , Html.Attributes.style "flex-wrap" "wrap"
            , Html.Attributes.style "justify-content" "center"
            , Html.Attributes.style "align-items" "center"
            , Html.Attributes.style "margin" "16px 0"
            ]
            htmlButtons
        )
