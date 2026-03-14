module Engines.Scroll.FirstScrollSub.Main exposing (main)

import Anim.Engine.Scroll as Scroll exposing (AnimBuilder)
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
        , subscriptions = subscriptions
        }



---8<-- [start:model]


type alias Model =
    { scrollState : Scroll.AnimState
    , status : ScrollStatus
    }


type ScrollStatus
    = Idle
    | Scrolling
    | Completed String
    | Failed String


init : () -> ( Model, Cmd Msg )
init _ =
    ( { scrollState = Scroll.init
      , status = Idle
      }
    , Cmd.none
    )



---8<-- [end:model]
-- UPDATE


type Msg
    = ScrollToTop
    | ScrollToMiddle
    | ScrollToBottom
    | GotScrollMsg Scroll.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ---8<-- [start:updateScroll]
        GotScrollMsg scrollMsg ->
            let
                ( newScrollState, scrollCmd ) =
                    Scroll.update GotScrollMsg scrollMsg model.scrollState
            in
            ( { model | scrollState = newScrollState }
            , scrollCmd
            )

        ---8<-- [end:updateScroll]
        ---8<-- [start:trigger]
        ScrollToTop ->
            let
                ( newScrollState, scrollCmd ) =
                    Scroll.animate GotScrollMsg model.scrollState <|
                        scrollToElement "top-element"
            in
            ( { model
                | scrollState = newScrollState
                , status = Scrolling
              }
            , scrollCmd
            )

        ---8<-- [end:trigger]
        ScrollToMiddle ->
            let
                ( newScrollState, scrollCmd ) =
                    Scroll.animate GotScrollMsg model.scrollState <|
                        scrollToElement "middle-element"
            in
            ( { model
                | scrollState = newScrollState
                , status = Scrolling
              }
            , scrollCmd
            )

        ScrollToBottom ->
            let
                ( newScrollState, scrollCmd ) =
                    Scroll.animate GotScrollMsg model.scrollState <|
                        scrollToElement "bottom-element"
            in
            ( { model
                | scrollState = newScrollState
                , status = Scrolling
              }
            , scrollCmd
            )



---8<-- [start:build]


scrollToElement : String -> AnimBuilder -> AnimBuilder
scrollToElement targetId =
    ScrollTo.forContainer "scroll-container"
        >> ScrollTo.toElement targetId
        >> ScrollTo.speed 250
        >> ScrollTo.easing BounceOut
        >> ScrollTo.build



---8<-- [end:build]
---8<-- [start:subscriptions]


subscriptions : Model -> Sub Msg
subscriptions model =
    Scroll.subscriptions GotScrollMsg model.scrollState



---8<-- [end:subscriptions]
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
            [ styledButton ScrollToTop "Scroll to Top"
            , styledButton ScrollToMiddle "Scroll to Middle"
            , styledButton ScrollToBottom "Scroll to Bottom"
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

                Completed desc ->
                    ( "#22c55e", "✓ Scrolled to " ++ desc )

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
