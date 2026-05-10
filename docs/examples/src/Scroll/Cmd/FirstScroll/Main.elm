module Scroll.Cmd.FirstScroll.Main exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (id, style)
import Html.Events exposing (onClick)
import Motion.Easing as Easing exposing (Easing(..))
import Scroll.Builder as ScrollTo
import Scroll.Engine.Cmd as Scroll exposing (ScrollBuilder)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    { status : ScrollStatus }


type ScrollStatus
    = Idle
    | Scrolling
    | Arrived


init : () -> ( Model, Cmd Msg )
init _ =
    ( { status = Idle }, Cmd.none )



-- UPDATE


type Msg
    = ScrollTo String
    | ScrollComplete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:trigger]
        ScrollTo targetId ->
            ( { model | status = Scrolling }
            , Scroll.scroll ScrollComplete <| scrollToElement targetId
            )

        ---8<-- [end:trigger]
        ScrollComplete ->
            ( { model | status = Arrived }, Cmd.none )



---8<-- [start:build]


scrollToElement : String -> ScrollBuilder -> ScrollBuilder
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
        [ div [ style "display" "flex", style "gap" "10px", style "flex-wrap" "wrap" ]
            [ styledButton (ScrollTo "top-element") "Scroll to Top"
            , styledButton (ScrollTo "middle-element") "Scroll to Middle"
            , styledButton (ScrollTo "bottom-element") "Scroll to Bottom"
            ]
        , statusBar model.status
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


statusBar : ScrollStatus -> Html msg
statusBar status =
    let
        ( color, message ) =
            case status of
                Idle ->
                    ( "#94a3b8", "Click a button to scroll" )

                Scrolling ->
                    ( "#f59e0b", "Scrolling..." )

                Arrived ->
                    ( "#22c55e", "✓ Scroll complete" )
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
