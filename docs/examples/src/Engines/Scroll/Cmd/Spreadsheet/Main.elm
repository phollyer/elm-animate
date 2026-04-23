module Engines.Scroll.Cmd.Spreadsheet.Main exposing (main)

import Anim.Engine.Scroll.Builder as ScrollTo
import Anim.Engine.Scroll.Cmd as Scroll exposing (AnimBuilder)
import Anim.Extra.Easing exposing (Easing(..))
import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (id, style)
import Html.Events exposing (onClick)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( { status = Idle }, Cmd.none )
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL


type ScrollStatus
    = Idle
    | Scrolling
    | Arrived


type alias Model =
    { status : ScrollStatus }



-- UPDATE


type Msg
    = NavigateTo String
    | ScrollComplete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NavigateTo regionId ->
            ( { model | status = Scrolling }, Scroll.animate ScrollComplete <| scrollToRegion regionId )

        ScrollComplete ->
            ( { model | status = Arrived }, Cmd.none )



---8<-- [start:build]


scrollToRegion : String -> AnimBuilder -> AnimBuilder
scrollToRegion regionId =
    ScrollTo.forContainer "spreadsheet"
        >> ScrollTo.toElement regionId
        >> ScrollTo.withOffsetXY 48 32
        >> ScrollTo.speed 400
        >> ScrollTo.easing EaseInOut
        >> ScrollTo.build



---8<-- [end:build]
-- SPREADSHEET DATA


type alias Region =
    { id : String
    , label : String
    , col : Int
    , row : Int
    , color : String
    , emoji : String
    }


regions : List Region
regions =
    [ { id = "region-revenue", label = "Revenue", col = 4, row = 5, color = "#3b6fa0", emoji = "💰" }
    , { id = "region-expenses", label = "Expenses", col = 10, row = 13, color = "#a03b3b", emoji = "📉" }
    , { id = "region-forecast", label = "Forecast", col = 7, row = 22, color = "#3b8050", emoji = "📈" }
    , { id = "region-summary", label = "Summary", col = 13, row = 30, color = "#7a6b30", emoji = "📊" }
    , { id = "region-growth", label = "YoY Growth", col = 16, row = 35, color = "#6b3a8b", emoji = "🚀" }
    ]


numCols : Int
numCols =
    16


numRows : Int
numRows =
    35


colLabel : Int -> String
colLabel i =
    String.fromChar (Char.fromCode (64 + i))


findRegion : Int -> Int -> Maybe Region
findRegion col row =
    List.head (List.filter (\r -> r.col == col && r.row == row) regions)



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "gap" "16px"
        , style "padding" "20px"
        ]
        [ navButtons
        , statusBar model.status
        , spreadsheet
        ]


statusBar : ScrollStatus -> Html msg
statusBar status =
    let
        ( color, message ) =
            case status of
                Idle ->
                    ( "#94a3b8", "Click a region to navigate" )

                Scrolling ->
                    ( "#3b82f6", "Scrolling..." )

                Arrived ->
                    ( "#22c55e", "✓ Arrived" )
    in
    div
        [ style "padding" "8px 16px"
        , style "border-radius" "6px"
        , style "background-color" color
        , style "color" "white"
        , style "font-size" "14px"
        , style "font-weight" "500"
        , style "font-family" "monospace"
        ]
        [ text message ]


navButtons : Html Msg
navButtons =
    div
        [ style "display" "flex"
        , style "flex-wrap" "wrap"
        , style "gap" "8px"
        ]
        (List.map regionButton regions)


regionButton : Region -> Html Msg
regionButton region =
    button
        [ onClick (NavigateTo region.id)
        , style "padding" "8px 14px"
        , style "border" "none"
        , style "border-radius" "6px"
        , style "background-color" region.color
        , style "color" "white"
        , style "cursor" "pointer"
        , style "font-size" "13px"
        , style "font-weight" "600"
        ]
        [ text (region.emoji ++ " " ++ region.label) ]


spreadsheet : Html Msg
spreadsheet =
    div
        [ id "spreadsheet"
        , style "overflow" "auto"
        , style "height" "360px"
        , style "border" "1px solid #ccc"
        , style "border-radius" "8px"
        ]
        [ div
            [ style "display" "grid"
            , style "grid-template-columns"
                ("48px " ++ String.join " " (List.repeat numCols "96px"))
            , style "width" "max-content"
            ]
            (headerRow ++ List.concatMap dataRow (List.range 1 numRows))
        ]



---8<-- [start:grid]


headerRow : List (Html Msg)
headerRow =
    cornerCell :: List.map colHeaderCell (List.range 1 numCols)


cornerCell : Html Msg
cornerCell =
    div
        [ style "position" "sticky"
        , style "top" "0"
        , style "left" "0"
        , style "z-index" "3"
        , style "background-color" "#e8e8e8"
        , style "border-right" "2px solid #aaa"
        , style "border-bottom" "2px solid #aaa"
        , style "height" "32px"
        ]
        []


colHeaderCell : Int -> Html Msg
colHeaderCell col =
    div
        [ style "position" "sticky"
        , style "top" "0"
        , style "z-index" "2"
        , style "background-color" "#e8e8e8"
        , style "border-right" "1px solid #ccc"
        , style "border-bottom" "2px solid #aaa"
        , style "height" "32px"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "font-weight" "700"
        , style "font-size" "13px"
        , style "color" "#555"
        ]
        [ text (colLabel col) ]


dataRow : Int -> List (Html Msg)
dataRow row =
    rowNumCell row :: List.map (dataCell row) (List.range 1 numCols)


rowNumCell : Int -> Html Msg
rowNumCell row =
    div
        [ style "position" "sticky"
        , style "left" "0"
        , style "z-index" "1"
        , style "background-color" "#e8e8e8"
        , style "border-right" "2px solid #aaa"
        , style "border-bottom" "1px solid #ccc"
        , style "height" "32px"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "font-weight" "600"
        , style "font-size" "12px"
        , style "color" "#555"
        ]
        [ text (String.fromInt row) ]


dataCell : Int -> Int -> Html Msg
dataCell row col =
    case findRegion col row of
        Just region ->
            div
                [ id region.id
                , style "background-color" region.color
                , style "color" "white"
                , style "border-right" "1px solid rgba(255,255,255,0.3)"
                , style "border-bottom" "1px solid rgba(255,255,255,0.3)"
                , style "height" "32px"
                , style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , style "font-size" "11px"
                , style "font-weight" "700"
                , style "white-space" "nowrap"
                , style "padding" "0 6px"
                ]
                [ text (region.emoji ++ " " ++ region.label) ]

        Nothing ->
            div
                [ style "border-right" "1px solid #e8e8e8"
                , style "border-bottom" "1px solid #e8e8e8"
                , style "height" "32px"
                , style "background-color"
                    (if modBy 2 row == 0 then
                        "#fafafa"

                     else
                        "white"
                    )
                ]
                []



---8<-- [end:grid]
