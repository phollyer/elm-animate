module ElmUI.Scroll.ScrollToTop.Main exposing (main)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Html exposing (Html)
import Html.Attributes as Attr
import SmoothMoveScroll


-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
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
    = ScrollToTop
    | ScrollContainerToTop
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScrollToTop ->
            ( model, SmoothMoveScroll.scrollToTop NoOp "" )

        ScrollContainerToTop ->
            ( model, SmoothMoveScroll.scrollToTop NoOp "content-container" )

        NoOp ->
            ( model, Cmd.none )


-- VIEW


view : Model -> Html Msg
view model =
    layout
        [ width fill
        , height fill
        ]
    <|
        column
            [ width fill
            , height fill
            , spacing 20
            , padding 20
            ]
            [ -- Fixed header with buttons
              row
                [ width fill
                , spacing 20
                , padding 20
                , Background.color (rgb 0.9 0.9 0.9)
                , Border.width 2
                , Border.color (rgb 0.8 0.8 0.8)
                ]
                [ el [ Font.size 24, Font.bold ] (text "ScrollToTop Demo")
                , el [ alignRight ] <|
                    row [ spacing 10 ]
                        [ button "Document Top" ScrollToTop
                        , button "Container Top" ScrollContainerToTop
                        ]
                ]

            -- Scrollable content container
            , el
                [ width fill
                , height (px 400)
                , Background.color (rgb 0.95 0.95 0.95)
                , Border.width 1
                , Border.color (rgb 0.7 0.7 0.7)
                , scrollbars
                , htmlAttribute (Attr.id "content-container")
                ]
              <|
                column
                    [ width fill
                    , spacing 20
                    , padding 20
                    ]
                    (generateContent 50)

            -- Additional content to make document scrollable
            , column [ width fill, spacing 20 ]
                (List.map
                    (\i ->
                        el
                            [ width fill
                            , padding 20
                            , Background.color (rgb 0.98 0.98 0.98)
                            , Border.width 1
                            , Border.color (rgb 0.9 0.9 0.9)
                            ]
                            (text ("Document Section " ++ String.fromInt i))
                    )
                    (List.range 1 20)
                )
            ]


button : String -> Msg -> Element Msg
button label msg =
    el
        [ padding 12
        , Background.color (rgb 0.2 0.6 0.8)
        , Font.color (rgb 1 1 1)
        , Border.rounded 4
        , Events.onClick msg
        , mouseOver [ Background.color (rgb 0.1 0.5 0.7) ]
        , pointer
        ]
        (text label)


generateContent : Int -> List (Element Msg)
generateContent count =
    List.range 1 count
        |> List.map
            (\i ->
                el
                    [ width fill
                    , padding 15
                    , Background.color
                        (if modBy 2 i == 0 then
                            rgb 1 1 1
                         else
                            rgb 0.95 0.95 1
                        )
                    , Border.width 1
                    , Border.color (rgb 0.8 0.8 0.8)
                    ]
                    (text ("Container Item " ++ String.fromInt i ++ " - Scroll down to test the back-to-top buttons"))
            )