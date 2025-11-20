module ElmUI.CSS.Keyframes.Opacity.Main exposing (main)

{-| Anim.CSS Opacity Example using ElmUI - Element opacity animations with CSS keyframes

This example demonstrates smooth opacity animations using browser-native CSS keyframes.
Perfect for creating fade effects and visibility transitions with precise timing control.

FEATURES:

  - ✅ Smooth opacity transitions using CSS keyframes
  - ✅ Hardware-accelerated opacity animations
  - ✅ Multiple opacity levels and fade patterns
  - ✅ Keyframes provide precise control over animation timing and composition

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
import Html
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


elementId : String
elementId =
    "box"


anim : CSS.AnimationState -> Opacity.Builder
anim animations =
    animations
        |> CSS.builder
        |> Anim.duration 600
        |> Anim.easing Linear
        |> Opacity.for elementId


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
                        -- TODO: Fix bug -> Adding delay causes animation to jump to opacity == 1
                        --|> Opacity.delay 300
                        |> Opacity.easing Easing.bounceInOut
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
        "Anim.CSS Opacity Keyframes ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ Element.html (CSS.keyframesStyleNodeFor elementId model.animations)
    , UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "CSS Opacity Animations"
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
            (animatedBox "Opacity Demo" Colors.primary model)
        )
    ]


animatedBox : String -> Element.Color -> Model -> Element Msg
animatedBox label color model =
    el
        [ width (px 150)
        , height (px 150)
        , Background.color color
        , Border.rounded 12
        , centerX
        , htmlAttribute (Html.Attributes.id elementId)
        , htmlAttribute (Html.Attributes.style "display" "flex")
        , htmlAttribute (Html.Attributes.style "align-items" "center")
        , htmlAttribute (Html.Attributes.style "justify-content" "center")
        , htmlAttribute (CSS.animationStyleAttribute elementId model.animations)
        ]
        (el
            [ centerX
            , centerY
            , Font.color Colors.backgroundWhite
            , Font.bold
            , Font.size 16
            ]
            (text label)
        )
