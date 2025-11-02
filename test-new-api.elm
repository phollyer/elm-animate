module TestNewAPI exposing (main)

{-| Simple test to verify the new clean API works correctly.
-}

import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes
import Html.Events exposing (onClick)
import SmoothMoveScroll exposing (Container(..), defaultConfig)
import SmoothMoveScroll.Cmd as ScrollCmd
import SmoothMoveScroll.Task as ScrollTask
import Task


type Msg
    = ScrollToTop
    | ScrollToElement
    | TaskScrollComplete (Result String ())


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScrollToTop ->
            -- Test the clean Cmd API
            ( model, ScrollCmd.scrollToTop DocumentBody ScrollToTop )

        ScrollToElement ->
            -- Test the clean Task API
            ( model
            , ScrollTask.scroll "target-element" DocumentBody
                |> Task.mapError (\_ -> "Scroll failed")
                |> Task.attempt TaskScrollComplete
            )

        TaskScrollComplete result ->
            case result of
                Ok _ ->
                    ( model, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick ScrollToTop ] [ text "Scroll to Top (Cmd API)" ]
        , button [ onClick ScrollToElement ] [ text "Scroll to Element (Task API)" ]
        , div [ Html.Attributes.id "target-element" ] [ text "Target Element" ]
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }