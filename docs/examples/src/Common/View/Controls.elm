module Common.View.Controls exposing
    ( animationArea
    , buttons
    , header
    , table
    )

import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, html, htmlAttribute, maximum, padding, px, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes exposing (style)


animationArea : Element msg -> Element msg
animationArea =
    el
        [ width <|
            (fill |> maximum 500)
        , height <|
            px 350
        , Background.color Colors.backgroundWhite
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }
        , centerX
        ]


animatedBall : List (Element.Attribute msg) -> Element msg
animatedBall animationAttrs =
    el
        (animationAttrs
            ++ [ width (px 50)
               , height (px 50)
               , htmlAttribute (style "position" "relative")
               ]
        )
        (el [ centerX, centerY, Font.size 50 ] (text "🏀"))



-- Header


header : List String -> Element msg
header =
    column
        [ centerX
        , spacing 8
        ]
        << List.map UI.pageHeader



-- Table


table : List ( Int, String, String ) -> Element msg
table descriptions =
    column
        [ centerX
        , Border.width 1
        , Border.color Colors.borderMedium
        , Border.shadow
            { offset = ( 0, 2 )
            , size = 2
            , blur = 4
            , color = Element.rgba 0 0 0 0.1
            }
        , Background.color Colors.backgroundLight
        , Border.rounded 8
        ]
        [ el
            [ width fill
            , Border.widthEach
                { top = 0
                , right = 0
                , bottom = 1
                , left = 0
                }
            ]
          <|
            el
                [ Font.size 18
                , padding 8
                , centerX
                , Font.medium
                , Font.color Colors.textDark
                ]
                (text "🎮 Control Functions")
        , column
            [ width fill ]
          <|
            List.map
                (\( borderWidth, control, desc ) ->
                    description borderWidth control desc
                )
                descriptions
        ]


description : Int -> String -> String -> Element msg
description borderWidth control description_ =
    row
        [ width fill
        , Border.widthEach
            { top = borderWidth
            , right = 0
            , bottom = 0
            , left = 0
            }
        , padding 4
        ]
        [ el
            [ Font.size 14
            , Font.medium
            , Font.color Colors.primary
            , width (px 80)
            ]
            (text control)
        , el
            [ Font.size 14
            , Font.color Colors.textMedium
            ]
            (text description_)
        ]



-- Buttons


buttons : List (List ( UI.ButtonStyle, msg, String )) -> Element msg
buttons =
    row
        [ spacing 12, centerX ]
        << List.map buttons_


buttons_ : List ( UI.ButtonStyle, msg, String ) -> Element msg
buttons_ =
    column [ spacing 12 ] << List.map button


button : ( UI.ButtonStyle, msg, String ) -> Element msg
button =
    UI.htmlButton
        >> html
        >> el [ centerX ]
