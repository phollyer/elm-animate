module Engines.Scroll.FirstScrollCmd.Main exposing (main)

import Anim.Engine.Scroll as Scroll exposing (AnimBuilder)
import Anim.Engine.Scroll.Builder as ScrollTo
import Anim.Extra.Easing exposing (Easing(..))
import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (id, style)
import Html.Events exposing (onClick)
import Task
import Time



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



---8<-- [start:model]


type alias Model =
    { startTime : Maybe Int
    , elapsedMs : Maybe Int
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { startTime = Nothing, elapsedMs = Nothing }, Cmd.none )



---8<-- [end:model]
-- UPDATE


type Msg
    = StartScroll String
    | GotStartTime String Time.Posix
    | ScrollComplete
    | GotEndTime Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartScroll targetId ->
            ( model
            , Time.now |> Task.perform (GotStartTime targetId)
            )

        ---8<-- [start:trigger]
        GotStartTime targetId posix ->
            ( { model | startTime = Just (Time.posixToMillis posix), elapsedMs = Nothing }
            , Scroll.toCmd ScrollComplete <| scrollToElement targetId
            )

        ---8<-- [end:trigger]
        ScrollComplete ->
            ( model
            , Time.now |> Task.perform GotEndTime
            )

        GotEndTime posix ->
            let
                endMs =
                    Time.posixToMillis posix

                elapsed =
                    Maybe.map (\s -> endMs - s) model.startTime
            in
            ( { model | elapsedMs = elapsed }, Cmd.none )



---8<-- [start:build]


scrollToElement : String -> AnimBuilder -> AnimBuilder
scrollToElement targetId =
    ScrollTo.forContainer "scroll-container"
        >> ScrollTo.toElement targetId
        >> ScrollTo.speed 250
        >> ScrollTo.easing BounceOut
        >> ScrollTo.build



---8<-- [end:build]
-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "gap" "20px"
        , style "padding" "20px"
        ]
        [ div [ style "display" "flex", style "gap" "10px" ]
            [ styledButton (StartScroll "top-element") "Scroll to Top"
            , styledButton (StartScroll "middle-element") "Scroll to Middle"
            , styledButton (StartScroll "bottom-element") "Scroll to Bottom"
            ]
        , timingBar model.elapsedMs
        , ---8<-- [start:container]
          div
            [ id "scroll-container"
            , style "height" "300px"
            , style "overflow-y" "auto"
            , style "border" "2px solid #333"
            , style "border-radius" "8px"
            ]
            [ scrollContent ]

        ---8<-- [end:container]
        ]


timingBar : Maybe Int -> Html msg
timingBar maybeMs =
    let
        ( color, message ) =
            case maybeMs of
                Nothing ->
                    ( "#94a3b8", "Click a button to scroll" )

                Just ms ->
                    ( "#22c55e", "Scroll took " ++ String.fromInt ms ++ "ms" )
    in
    div
        [ style "padding" "8px 16px"
        , style "border-radius" "6px"
        , style "background-color" color
        , style "color" "white"
        , style "font-size" "14px"
        , style "font-weight" "500"
        ]
        [ text message ]


styledButton : Msg -> String -> Html Msg
styledButton msg label =
    button
        [ onClick msg
        , style "padding" "10px 20px"
        , style "border" "none"
        , style "border-radius" "6px"
        , style "background-color" "#6366f1"
        , style "color" "white"
        , style "cursor" "pointer"
        , style "font-size" "14px"
        , style "font-weight" "600"
        , style "box-shadow" "0 2px 4px rgba(0,0,0,0.2)"
        ]
        [ text label ]


scrollContent : Html Msg
scrollContent =
    div
        [ style "padding" "20px" ]
        [ targetElement "top-element" "Top Section" "#4CAF50"
        , spacer
        , targetElement "middle-element" "Middle Section" "#2196F3"
        , spacer
        , targetElement "bottom-element" "Bottom Section" "#9C27B0"
        ]


targetElement : String -> String -> String -> Html Msg
targetElement elementId label color =
    div
        [ id elementId
        , style "padding" "40px"
        , style "background-color" color
        , style "color" "white"
        , style "border-radius" "8px"
        , style "text-align" "center"
        , style "font-size" "24px"
        ]
        [ text label ]


spacer : Html Msg
spacer =
    div [ style "height" "400px" ] []
