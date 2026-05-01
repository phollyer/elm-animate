port module Animation.WAAPI.ScrollTimeline.Main exposing (main)

import Anim.Engine.WAAPI.ScrollTimeline as WAAPI
import Anim.Property.Scale as Scale
import Browser
import Easing exposing (Easing(..))
import Html exposing (Html, div, h2, p, section, text)
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


progressBarId : String
progressBarId =
    "scrollProgress"



---8<-- [start:build]


scrollProgress : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
scrollProgress =
    WAAPI.scrollSource "document"
        >> Scale.for progressBarId
        >> Scale.fromX 0
        >> Scale.toX 1
        >> Scale.build



---8<-- [end:build]
-- INIT


init : ( (), Cmd msg )
init =
    ---8<-- [start:trigger]
    ( ()
    , WAAPI.scroll waapiCommand scrollProgress
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
                [ id progressBarId
                , style "width" "100%"
                , style "height" "100%"
                , style "background" "linear-gradient(90deg, #6366f1, #8b5cf6)"
                , style "transform-origin" "left center"
                , style "transform" "scaleX(0)"
                ]
                []
            ]

        -- Page headline that fades in and slides up as you scroll
        , div
            [ style "text-align" "center"
            , style "padding" "80px 40px 40px"
            , style "background" "linear-gradient(135deg, #ede9fe, #ddd6fe)"
            ]
            [ div
                []
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
                    [ text "The progress bar animates in sync with the document scroll position." ]
                ]
            ]

        -- Scrollable content sections
        , div [ style "max-width" "700px", style "margin" "0 auto", style "padding" "0 40px" ] <|
            List.map contentSection
                [ ( "#6366f1", "Declarative", "Describe animations in Elm - the WAAPI engine takes care of the rest." )
                , ( "#8b5cf6", "Performant", "Animations run on the browser compositor thread for silky smooth motion." )
                , ( "#a78bfa", "Type Safe", "Phantom types ensure scroll, view and document timelines cannot be mixed up." )
                , ( "#7c3aed", "Composable", "Chain property builders with >> to build complex animations from simple pieces." )
                , ( "#5b21b6", "Scroll Driven", "Tie any animatable property to scroll position using ScrollTimeline." )
                ]
        ]


contentSection : ( String, String, String ) -> Html msg
contentSection ( color, title, body ) =
    section
        [ style "padding" "80px 0"
        , style "border-bottom" "1px solid #e5e7eb"
        ]
        [ div
            [ style "width" "48px"
            , style "height" "48px"
            , style "border-radius" "50%"
            , style "background" color
            , style "margin" "0 0 24px"
            ]
            []
        , h2
            [ style "font-size" "1.8rem"
            , style "font-weight" "700"
            , style "margin" "0 0 16px"
            ]
            [ text title ]
        , p
            [ style "font-size" "1.1rem"
            , style "line-height" "1.7"
            , style "color" "#6b7280"
            , style "margin" "0"
            ]
            [ text body ]
        ]
