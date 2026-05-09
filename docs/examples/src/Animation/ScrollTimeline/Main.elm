port module Animation.ScrollTimeline.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.ScrollTimeline as ScrollTimeline exposing (Container(..))
import Anim.Extra.Color as Color exposing (Color)
import Anim.Property.CustomColor as CustomColor exposing (Property(..))
import Anim.Property.Scale as Scale
import Browser
import Easing exposing (Easing(..))
import Html exposing (Html, div, h2, p, span, text)
import Html.Attributes exposing (id, style)
import Json.Encode as Encode



-- PORTS


port waapiCommand : Encode.Value -> Cmd msg



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


progressBarAnim : String
progressBarAnim =
    "scrollProgress"



---8<-- [start:build]


scrollProgress : AnimBuilder mode -> AnimBuilder mode
scrollProgress =
    Scale.for progressBarAnim
        >> Scale.fromX 0
        >> Scale.toX 1
        >> Scale.build
        >> CustomColor.for progressBarAnim BackgroundColor
        >> CustomColor.from Color.red
        >> CustomColor.to Color.green
        >> CustomColor.build



---8<-- [end:build]
-- INIT


init : ( (), Cmd msg )
init =
    ---8<-- [start:trigger]
    ( ()
    , ScrollTimeline.animate waapiCommand Document scrollProgress
    )



---8<-- [end:trigger]
-- VIEW


view : () -> Html msg
view _ =
    div
        [ style "font-family" "system-ui, sans-serif"
        , style "color" "#1f2937"
        ]
        [ -- Fixed progress bar at top of page
          div
            [ style "position" "fixed"
            , style "top" "0"
            , style "left" "0"
            , style "width" "100%"
            , style "height" "5px"
            , style "background" "#e5e7eb"
            , style "z-index" "100"
            ]
            [ div
                (ScrollTimeline.attributes progressBarAnim
                    ++ [ style "width" "100%"
                       , style "height" "100%"
                       , style "transform-origin" "left center"
                       , style "transform" "scaleX(0)"
                       ]
                )
                []
            ]
        , div
            [ style "text-align" "center"
            , style "padding" "80px 40px 40px"
            , style "background" "linear-gradient(135deg, #ede9fe, #ddd6fe)"
            ]
            [ h2
                [ style "font-size" "2.5rem"
                , style "font-weight" "700"
                , style "margin" "0 0 16px"
                , style "color" "#4c1d95"
                ]
                [ text "Scroll Timeline" ]
            , p
                [ style "font-size" "1.1rem"
                , style "color" "#6d28d9"
                , style "margin" "0"
                ]
                [ text "Scroll down and watch the bar fill as the page moves from top to bottom." ]
            ]

        -- Scrollable content cards
        , div
            [ style "max-width" "700px"
            , style "margin" "0 auto"
            , style "padding" "60px 40px"
            , style "display" "flex"
            , style "flex-direction" "column"
            , style "gap" "60px"
            ]
            (List.map contentCard cards)
        ]


type alias CardData =
    { label : String
    , color : String
    , title : String
    , body : String
    }


cards : List CardData
cards =
    [ { label = "01"
      , color = "#6366f1"
      , title = "Top to bottom"
      , body = "The timeline starts at 0% at the top of the page and reaches 100% at the bottom."
      }
    , { label = "02"
      , color = "#8b5cf6"
      , title = "One scroll, two effects"
      , body = "The same timeline drives both size and color, so one scroll gesture controls the whole bar."
      }
    , { label = "03"
      , color = "#a78bfa"
      , title = "Read progress at a glance"
      , body = "Short red bar means early in the page, long green bar means you are near the end."
      }
    , { label = "04"
      , color = "#7c3aed"
      , title = "Simple trigger"
      , body = "Call ScrollTimeline.animate once in init, then the browser keeps everything in sync while you scroll."
      }
    , { label = "05"
      , color = "#5b21b6"
      , title = "Easy to reuse"
      , body = "Attach ScrollTimeline.attributes to any element and map scroll progress to the properties you want."
      }
    ]


contentCard : CardData -> Html msg
contentCard card =
    div
        [ style "display" "flex"
        , style "gap" "24px"
        , style "align-items" "flex-start"
        , style "padding" "32px"
        , style "background" "white"
        , style "border-radius" "16px"
        , style "box-shadow" "0 4px 24px rgba(99,102,241,0.08)"
        ]
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
