port module Animation.ViewTimeline.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.ViewTimeline as ViewTimeline exposing (Range(..), Unit(..))
import Anim.Property.Opacity as Opacity
import Anim.Property.Translate as Translate
import Browser
import Easing exposing (Easing(..))
import Html exposing (Html, div, h2, p, span, text)
import Html.Attributes exposing (id, style)
import Json.Encode as Encode



-- PORTS


port motionCmd : Encode.Value -> Cmd msg



-- MAIN


main : Program () () msg
main =
    Browser.element
        { init = \_ -> init
        , view = view
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }



-- ANIMATION
---8<-- [start:build]


revealCard : String -> AnimBuilder mode -> AnimBuilder mode
revealCard animGroupName =
    Opacity.for animGroupName
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.build
        >> Translate.for animGroupName
        >> Translate.fromY 100
        >> Translate.toY 0
        >> Translate.build



---8<-- [end:build]
-- INIT


init : ( (), Cmd msg )
init =
    ---8<-- [start:trigger]
    ( ()
    , cards
        |> List.map
            (\card ->
                ViewTimeline.animate motionCmd <|
                    ViewTimeline.rangeStart (Entry 10 Perc)
                        >> ViewTimeline.rangeEnd (Cover 30 Perc)
                        >> ViewTimeline.easing BounceInOut
                        >> revealCard card.animGroupName
            )
        |> Cmd.batch
    )



---8<-- [end:trigger]
-- VIEW


view : () -> Html msg
view _ =
    div
        [ style "font-family" "system-ui, sans-serif"
        , style "color" "#1f2937"
        , style "background" "#f9fafb"
        ]
        [ -- Page header
          div
            [ style "text-align" "center"
            , style "padding" "80px 40px 60px"
            , style "background" "linear-gradient(135deg, #ede9fe, #ddd6fe)"
            ]
            [ h2
                [ style "font-size" "2.5rem"
                , style "font-weight" "700"
                , style "margin" "0 0 16px"
                , style "color" "#4c1d95"
                ]
                [ text "View Timeline" ]
            , p
                [ style "font-size" "1.1rem"
                , style "color" "#6d28d9"
                , style "margin" "0"
                ]
                [ text "Scroll down - each card animates as it enters the viewport." ]
            ]

        -- Cards
        , div
            [ style "max-width" "700px"
            , style "margin" "0 auto"
            , style "padding" "60px 40px"
            , style "display" "flex"
            , style "flex-direction" "column"
            , style "gap" "60px"
            ]
            (List.map cardView cards)
        ]


type alias CardData =
    { animGroupName : String
    , color : String
    , label : String
    , title : String
    , body : String
    }


cards : List CardData
cards =
    [ { animGroupName = "view-card-1"
      , color = "#6366f1"
      , label = "01"
      , title = "Enter from below"
      , body = "Each card uses a ViewTimeline tied to itself as the scroll subject. As the card enters the viewport, it fades in and slides upward."
      }
    , { animGroupName = "view-card-2"
      , color = "#8b5cf6"
      , label = "02"
      , title = "Independent timelines"
      , body = "Every card has its own ViewTimeline. Animations are fully independent - each one triggers only when that specific card enters the viewport."
      }
    , { animGroupName = "view-card-3"
      , color = "#a78bfa"
      , label = "03"
      , title = "Range control"
      , body = "The rangeStart and rangeEnd functions define exactly when during the card's lifecycle the animation plays - entry, cover, contain, or exit."
      }
    , { animGroupName = "view-card-4"
      , color = "#7c3aed"
      , label = "04"
      , title = "Fire and forget"
      , body = "View timeline animations are fire-and-forget. No AnimState required - just call ViewTimeline.animate in your init and the browser handles the rest."
      }
    , { animGroupName = "view-card-5"
      , color = "#5b21b6"
      , label = "05"
      , title = "Composable builders"
      , body = "Combine opacity and translate in a single pipeline to create polished reveal effects with minimal code."
      }
    , { animGroupName = "view-card-6"
      , color = "#4c1d95"
      , label = "06"
      , title = "WAAPI powered"
      , body = "All animations run via the Web Animations API on the compositor thread - no JavaScript timers, no Elm subscriptions, maximum performance."
      }
    ]


cardView : CardData -> Html msg
cardView card =
    div
        (ViewTimeline.attributes card.animGroupName
            ++ [ style "display" "flex"
               , style "gap" "24px"
               , style "align-items" "flex-start"
               , style "padding" "32px"
               , style "background" "white"
               , style "border-radius" "16px"
               , style "box-shadow" "0 4px 24px rgba(99,102,241,0.08)"
               , style "opacity" "0"
               ]
        )
        [ span
            [ style "font-size" "2rem"
            , style "font-weight" "800"
            , style "color" card.color
            , style "flex-shrink" "0"
            , style "line-height" "1"
            , style "padding-top" "4px"
            ]
            [ text card.label ]
        , div []
            [ h2
                [ style "font-size" "1.3rem"
                , style "font-weight" "700"
                , style "margin" "0 0 10px"
                , style "color" "#111827"
                ]
                [ text card.title ]
            , p
                [ style "font-size" "1rem"
                , style "line-height" "1.7"
                , style "color" "#6b7280"
                , style "margin" "0"
                ]
                [ text card.body ]
            ]
        ]
