module Engines.Scroll.FirstScrollCmd.Main exposing (main)

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
        { init = \_ -> ( {}, Cmd.none )
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    {}



-- UPDATE


type Msg
    = ScrollTo String
    | ScrollComplete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:trigger]
        ScrollTo targetId ->
            ( model, Scroll.animate ScrollComplete <| scrollToElement targetId )

        ---8<-- [end:trigger]
        ScrollComplete ->
            ( model, Cmd.none )



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
view _ =
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "gap" "20px"
        , style "padding" "20px"
        ]
        [ div [ style "display" "flex", style "gap" "10px" ]
            [ styledButton (ScrollTo "top-element") "Scroll to Top"
            , styledButton (ScrollTo "middle-element") "Scroll to Middle"
            , styledButton (ScrollTo "bottom-element") "Scroll to Bottom"
            ]
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
