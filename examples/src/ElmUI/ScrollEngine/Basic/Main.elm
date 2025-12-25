module ElmUI.ScrollEngine.Basic.Main exposing (main)

import Anim.Engine.Scroll as Scroll
import Anim.Timing.Easing exposing (Easing(..))
import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes


-- MODEL


type alias Model =
    { scrollAnimations : Scroll.AnimState
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { scrollAnimations = Scroll.init
      }
    , Cmd.none
    )


-- UPDATE


type Msg
    = ScrollToSection String
    | ScrollAnimationMsg Scroll.AnimationMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScrollToSection sectionId ->
            let
                newScrollAnimations =
                    Scroll.init
                        |> Scroll.builder
                        |> Scroll.document
                        |> Scroll.toElement sectionId
                        |> Scroll.speed 500
                        |> Scroll.easing QuadInOut
                        |> Scroll.animate
            in
            ( { model | scrollAnimations = newScrollAnimations }
            , Cmd.none
            )

        ScrollAnimationMsg scrollMsg ->
            ( { model | scrollAnimations = Scroll.update scrollMsg model.scrollAnimations }
            , Cmd.none
            )


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Scroll.subscriptions ScrollAnimationMsg model.scrollAnimations


-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Scroll Engine - Basic Example"
    , body =
        [ Element.layout
            [ width fill
            , height fill
            ]
          <|
            column
                [ width fill
                , height fill
                , spacing 0
                ]
                [ -- Navigation Bar
                  row
                    [ width fill
                    , padding 20
                    , Background.color (rgb255 50 50 100)
                    , spacing 20
                    ]
                    [ text "Scroll Engine Demo"
                        |> el [ Font.color (rgb255 255 255 255), Font.size 24 ]
                    , row [ spacing 10, alignRight ]
                        [ button "Section 1" (ScrollToSection "section1")
                        , button "Section 2" (ScrollToSection "section2")
                        , button "Section 3" (ScrollToSection "section3")
                        , button "Section 4" (ScrollToSection "section4")
                        ]
                    ]
                
                , -- Content Sections
                  column
                    [ width fill
                    , spacing 0
                    ]
                    [ section "section1" "Section 1" (rgb255 200 100 100)
                    , section "section2" "Section 2" (rgb255 100 200 100)
                    , section "section3" "Section 3" (rgb255 100 100 200)
                    , section "section4" "Section 4" (rgb255 200 200 100)
                    ]
                ]
        ]
    }


button : String -> Msg -> Element Msg
button label msg =
    Input.button
        [ Background.color (rgb255 70 70 120)
        , Font.color (rgb255 255 255 255)
        , paddingXY 15 8
        , Border.rounded 4
        , Border.width 0
        , mouseOver [ Background.color (rgb255 90 90 140) ]
        ]
        { onPress = Just msg
        , label = text label
        }


section : String -> String -> Color -> Element Msg
section id title color =
    Element.el
        [ width fill
        , height (px 800)
        , Background.color color
        , Border.widthEach { top = 2, bottom = 0, left = 0, right = 0 }
        , Border.color (rgb255 255 255 255)
        , Element.htmlAttribute (Html.Attributes.id id)
        ]
    <|
        Element.el
            [ centerX
            , centerY
            , Font.size 48
            , Font.color (rgb255 255 255 255)
            ]
        <|
            text title


-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }