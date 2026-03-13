module Engines.Scroll.FirstScroll.Main exposing (main)

import Anim.Engine.Scroll as Scroll
import Anim.Engine.Scroll.Builder as ScrollTo
import Anim.Extra.Easing exposing (Easing(..))
import Browser
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (id, style)
import Html.Events exposing (onClick)



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


type State
    = Ready
    | Ticking


type alias Model =
    {}


init : () -> ( Model, Cmd Msg )
init _ =
    ( {}, Cmd.none )



-- UPDATE


type Msg
    = ScrollToTop
    | ScrollToMiddle
    | ScrollToBottom
    | ScrollComplete String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:scrollToTop]
        ScrollToTop ->
            ( model
            , scrollToElement "top-element"
            )

        ---8<-- [end:scrollToTop]
        ScrollToMiddle ->
            ( model
            , scrollToElement "middle-element"
            )

        ScrollToBottom ->
            ( model
            , scrollToElement "bottom-element"
            )

        ScrollComplete _ ->
            ( model, Cmd.none )



-- SCROLL BUILDER
---8<-- [start:scrollBuilder]


scrollToElement : String -> Cmd Msg
scrollToElement targetId =
    Scroll.toCmd ScrollComplete <|
        ScrollTo.forContainer "scroll-container"
            >> ScrollTo.toElement targetId
            >> ScrollTo.duration 2000
            >> ScrollTo.easing CubicOut
            >> ScrollTo.build



---8<-- [end:scrollBuilder]
-- VIEW


view : Model -> Html Msg
view model =
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "gap" "20px"
        , style "padding" "20px"
        ]
        [ ---8<-- [start:buttons]
          div [ style "display" "flex", style "gap" "10px" ]
            [ button [ onClick ScrollToTop ] [ text "Scroll to Top" ]
            , button [ onClick ScrollToMiddle ] [ text "Scroll to Middle" ]
            , button [ onClick ScrollToBottom ] [ text "Scroll to Bottom" ]
            ]

        ---8<-- [end:buttons]
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
