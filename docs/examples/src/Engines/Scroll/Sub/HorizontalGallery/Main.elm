module Engines.Scroll.Sub.HorizontalGallery.Main exposing (main)

import Browser
import Easing exposing (Easing(..))
import Html exposing (Html, button, div, text)
import Html.Attributes exposing (id, style)
import Html.Events exposing (onClick)
import Scroll.Builder as ScrollTo
import Scroll.Engine.Sub as Scroll exposing (AnimBuilder)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( init, Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type ScrollStatus
    = Idle
    | Scrolling Float Float
    | Arrived


type alias Model =
    { scrollState : Scroll.AnimState
    , status : ScrollStatus
    }


init : Model
init =
    { scrollState = Scroll.init
    , status = Idle
    }



-- UPDATE


type Msg
    = ScrollTo String
    | GotScrollMsg Scroll.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScrollTo cardId ->
            let
                ( newScrollState, scrollCmd ) =
                    Scroll.animate GotScrollMsg model.scrollState <|
                        scrollToCard cardId
            in
            ( { model | scrollState = newScrollState }, scrollCmd )

        GotScrollMsg scrollMsg ->
            let
                ( newScrollState, events, scrollCmd ) =
                    Scroll.update GotScrollMsg scrollMsg model.scrollState
            in
            ( { model
                | scrollState = newScrollState
                , status = List.foldl applyEvent model.status events
              }
            , scrollCmd
            )


applyEvent : Scroll.AnimEvent -> ScrollStatus -> ScrollStatus
applyEvent event _ =
    case event of
        Scroll.Progress _ pos progress ->
            Scrolling pos.x progress

        Scroll.Ended _ ->
            Arrived

        _ ->
            Idle



---8<-- [start:build]


scrollToCard : String -> AnimBuilder -> AnimBuilder
scrollToCard cardId =
    ScrollTo.forContainer "gallery"
        >> ScrollTo.toElement cardId
        >> ScrollTo.onXAxis
        >> ScrollTo.speed 500
        >> ScrollTo.easing EaseInOut
        >> ScrollTo.build



---8<-- [end:build]
---8<-- [start:subscriptions]


subscriptions : Model -> Sub Msg
subscriptions model =
    Scroll.subscriptions GotScrollMsg model.scrollState



---8<-- [end:subscriptions]
-- VIEW


photos : List { id : String, label : String, color : String, emoji : String }
photos =
    [ { id = "photo-mountains", label = "Mountains", color = "#4a6f8a", emoji = "🏔️" }
    , { id = "photo-ocean", label = "Ocean", color = "#1a7a6e", emoji = "🌊" }
    , { id = "photo-desert", label = "Desert", color = "#c47b3a", emoji = "🏜️" }
    , { id = "photo-forest", label = "Forest", color = "#3a7a45", emoji = "🌲" }
    , { id = "photo-arctic", label = "Arctic", color = "#5b7fa6", emoji = "🧊" }
    , { id = "photo-volcano", label = "Volcano", color = "#8b3a3a", emoji = "🌋" }
    , { id = "photo-savanna", label = "Savanna", color = "#8b7a3a", emoji = "🦁" }
    , { id = "photo-reef", label = "Reef", color = "#2a7a8b", emoji = "🐠" }
    ]


view : Model -> Html Msg
view model =
    div
        [ style "display" "flex"
        , style "flex-direction" "column"
        , style "gap" "16px"
        , style "padding" "20px"
        ]
        [ buttonRow
        , statusBar model.status
        , filmStrip
        ]


statusBar : ScrollStatus -> Html msg
statusBar status =
    let
        ( color, message ) =
            case status of
                Idle ->
                    ( "#94a3b8", "Click a photo to navigate" )

                Scrolling xPos progress ->
                    ( "#3b82f6"
                    , "x = "
                        ++ String.fromInt (round xPos)
                        ++ "px  ("
                        ++ String.fromInt (round (progress * 100))
                        ++ "%)"
                    )

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


buttonRow : Html Msg
buttonRow =
    div
        [ style "display" "flex"
        , style "flex-wrap" "wrap"
        , style "gap" "8px"
        ]
        (List.map navButton photos)


navButton : { id : String, label : String, color : String, emoji : String } -> Html Msg
navButton photo =
    button
        [ onClick (ScrollTo photo.id)
        , style "padding" "8px 14px"
        , style "border" "none"
        , style "border-radius" "6px"
        , style "background-color" photo.color
        , style "color" "white"
        , style "cursor" "pointer"
        , style "font-size" "13px"
        , style "font-weight" "600"
        ]
        [ text (photo.emoji ++ " " ++ photo.label) ]


filmStrip : Html Msg
filmStrip =
    div
        [ id "gallery"
        , style "display" "flex"
        , style "overflow-x" "auto"
        , style "overflow-y" "hidden"
        , style "gap" "12px"
        , style "padding" "12px"
        , style "border" "2px solid #333"
        , style "border-radius" "8px"
        ]
        (List.map photoCard photos)


photoCard : { id : String, label : String, color : String, emoji : String } -> Html Msg
photoCard photo =
    div
        [ id photo.id
        , style "min-width" "220px"
        , style "height" "260px"
        , style "background-color" photo.color
        , style "border-radius" "8px"
        , style "display" "flex"
        , style "flex-direction" "column"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "color" "white"
        , style "flex-shrink" "0"
        ]
        [ div [ style "font-size" "64px" ] [ text photo.emoji ]
        , div
            [ style "font-size" "18px"
            , style "font-weight" "700"
            , style "margin-top" "12px"
            , style "letter-spacing" "0.5px"
            ]
            [ text photo.label ]
        ]
