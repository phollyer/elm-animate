module ElmUI.CSS.Transitions.Opacity.Main exposing (main)

{-| Anim.CSS Opacity Example using ElmUI - Fade animations with CSS transitions

This example demonstrates smooth opacity transitions using browser-native CSS animations.
Perfect for fade-in/fade-out effects, modal overlays, and visibility transitions.

FEATURES:

  - ✅ Smooth fade in/out animations
  - ✅ Hardware-accelerated opacity transitions
  - ✅ Multiple opacity values and transitions
  - ✅ Show/hide patterns with smooth transitions
  - ✅ Battery efficient browser-native animations

-}

import Anim
import Anim.CSS as CSS
import Anim.Properties.Opacity as Opacity
import Anim.Timing.Delay as Delay
import Anim.Timing.Easing as Easing exposing (Easing(..))
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { animations : CSS.AnimationState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = CSS.init }
    , Cmd.none
    )



-- UPDATE


anim : CSS.AnimationState -> Opacity.Builder
anim animations =
    animations
        |> CSS.builder
        |> Anim.duration 600
        |> Anim.easing Linear
        |> Opacity.for "box"


type Msg
    = FadeIn
    | FadeOut
    | FadeToHalf
    | FadeToQuarter
    | ShowFully
    | AnimationComplete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FadeIn ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Opacity.to 1.0
                        |> Opacity.easing Easing.QuadInOut
                        |> Opacity.speed 1
                        |> Opacity.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        FadeOut ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Opacity.to 0.0
                        |> Opacity.easing Easing.SineInOut
                        |> Opacity.speed 0.2
                        |> Opacity.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        FadeToHalf ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Opacity.to 0.5
                        |> Opacity.easing Easing.backInOut
                        |> Opacity.duration 800
                        |> Opacity.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        FadeToQuarter ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Opacity.to 0.25
                        |> Opacity.easing Easing.bounceInOut
                        |> Opacity.delay 300
                        |> Opacity.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        ShowFully ->
            ( { model
                | animations =
                    model.animations
                        |> anim
                        |> Opacity.to 1.0
                        |> Opacity.easing Easing.elasticInOut
                        |> Opacity.duration 1000
                        |> Opacity.build
                        |> CSS.animate
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( model
            , Cmd.none
            )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.CSS Opacity ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & CSS Transitions Opacity Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth fade-in and fade-out effects using browser-native CSS transitions")
    , -- Opacity controls
      UI.wrappedButtonRow
        [ ( UI.Success, FadeIn, "Fade In" )
        , ( UI.Warning, FadeOut, "Fade Out" )
        , ( UI.Primary, FadeToHalf, "50% Opacity" )
        , ( UI.Purple, FadeToQuarter, "25% Opacity" )
        , ( UI.Success, ShowFully, "Show Fully" )
        ]
    , -- Animation area with boxes
      el
        [ width (fill |> maximum 600)
        , height (px 400)
        , Background.color Colors.backgroundWhite
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }
        , centerX
        , htmlAttribute (Html.Attributes.style "position" "relative")
        , htmlAttribute (Html.Attributes.style "overflow" "visible")
        , htmlAttribute (Html.Attributes.style "display" "flex")
        , htmlAttribute (Html.Attributes.style "flex-direction" "column")
        , htmlAttribute (Html.Attributes.style "align-items" "center")
        , htmlAttribute (Html.Attributes.style "justify-content" "space-around")
        , htmlAttribute (Html.Attributes.style "padding" "40px")
        ]
        (el
            [ centerX
            , centerY
            , width (px 200)
            , height (px 200)
            ]
            (animatedBox "box" "Opacity Demo" Colors.primary model)
        )
    ]


animatedBox : String -> String -> Element.Color -> Model -> Element Msg
animatedBox elementId label color model =
    el
        ([ width (px 150)
         , height (px 150)
         , Background.color color
         , Border.rounded 12
         , centerX
         , htmlAttribute (Html.Attributes.id elementId)
         , htmlAttribute (Html.Attributes.style "display" "flex")
         , htmlAttribute (Html.Attributes.style "align-items" "center")
         , htmlAttribute (Html.Attributes.style "justify-content" "center")
         ]
            -- Add CSS animation attributes
            ++ List.map htmlAttribute (CSS.htmlAttributes elementId model.animations)
        )
        (el
            [ centerX
            , centerY
            , Font.color Colors.backgroundWhite
            , Font.bold
            , Font.size 16
            ]
            (text label)
        )
