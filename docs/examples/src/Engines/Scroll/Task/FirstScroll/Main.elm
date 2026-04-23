module Engines.Scroll.Task.FirstScroll.Main exposing (main)

import Anim.Engine.Scroll.Builder as ScrollTo
import Anim.Engine.Scroll.Task as Scroll exposing (AnimBuilder)
import Anim.Extra.Easing exposing (Easing(..))
import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (id, style)
import Html.Events exposing (onClick)
import Task



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
    { status : ScrollStatus }


type ScrollStatus
    = Idle
    | Scrolling
    | Arrived
    | Failed String


init : () -> ( Model, Cmd Msg )
init _ =
    ( { status = Idle }, Cmd.none )



---8<-- [end:model]
-- UPDATE


type Msg
    = ScrollTo String
    | ScrollResult (Result Scroll.ScrollError Scroll.ScrollOk)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:trigger]
        ScrollTo targetId ->
            ( { model | status = Scrolling }
            , Task.attempt ScrollResult <|
                Scroll.animate <|
                    scrollToElement targetId
            )

        ---8<-- [end:trigger]
        ---8<-- [start:result]
        ScrollResult (Ok _) ->
            ( { model | status = Arrived }, Cmd.none )

        ScrollResult (Err (Scroll.ScrollError err)) ->
            ( { model | status = Failed ("Scroll failed for container: " ++ err.containerId) }
            , Cmd.none
            )



---8<-- [end:result]
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
        [ div [ style "display" "flex", style "gap" "10px", style "flex-wrap" "wrap" ]
            [ styledButton (ScrollTo "top-element") "Scroll to Top"
            , styledButton (ScrollTo "middle-element") "Scroll to Middle"
            , styledButton (ScrollTo "bottom-element") "Scroll to Bottom"
            ]
        , statusBar model.status
        , div
            [ id "scroll-container"
            , style "height" "300px"
            , style "overflow-y" "auto"
            , style "border" "2px solid #333"
            , style "border-radius" "8px"
            ]
            [ scrollContent ]
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

                Failed err ->
                    ( "#ef4444", "✗ " ++ err )
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
