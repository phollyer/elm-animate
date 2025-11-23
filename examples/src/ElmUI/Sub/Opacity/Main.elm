module ElmUI.Sub.Opacity.Main exposing (main)

{-| Anim.Sub Opacity Example using ElmUI - Opacity fade transitions with subscription-based animations

This example demonstrates smooth opacity transitions using browser-native CSS animations.
Perfect for fade-in/fade-out effects, modal overlays, and visibility transitions.

FEATURES:

  - ✅ Smooth fade in/out animations
  - ✅ Hardware-accelerated opacity transitions
  - ✅ Multiple elements with different timing
  - ✅ Show/hide patterns with smooth transitions
  - ✅ Battery efficient browser-native animations

-}

import Anim
import Anim.Properties.Opacity as Opacity
import Anim.Sub as Sub
import Anim.Timing.Easing as Easing exposing (Easing(..))
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
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
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animations : Sub.AnimationState
    , isVisible : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Sub.init
      , isVisible = True
      }
    , Cmd.none
    )


type Msg
    = FadeIn
    | FadeOut
    | FadeToggle
    | AnimationMsg Sub.AnimationMsg



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FadeIn ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Opacity.for "box"
                        |> Opacity.to 1.0
                        |> Opacity.duration 2000
                        |> Opacity.easing Easing.EaseOut
                        |> Opacity.build
                        |> Sub.animate
                , isVisible = True
              }
            , Cmd.none
            )

        FadeOut ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Opacity.for "box"
                        |> Opacity.to 0.0
                        |> Opacity.duration 2000
                        |> Opacity.easing Easing.EaseOut
                        |> Opacity.build
                        |> Sub.animate
                , isVisible = False
              }
            , Cmd.none
            )

        FadeToggle ->
            -- Toggle between fully visible (1.0) and fully invisible (0.0)
            let
                newOpacity =
                    if model.isVisible then
                        0.0

                    else
                        1.0

                newVisible =
                    not model.isVisible
            in
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Opacity.for "box"
                        |> Opacity.to newOpacity
                        |> Opacity.speed 3.0
                        |> Opacity.easing Easing.EaseInOut
                        |> Opacity.build
                        |> Sub.animate
                , isVisible = newVisible
              }
            , Cmd.none
            )

        AnimationMsg animMsg ->
            ( { model
                | animations = Sub.update animMsg model.animations
              }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map AnimationMsg (Sub.subscriptions model.animations)



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Sub Opacity ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Subscription Opacity Example"
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
        , ( UI.Primary, FadeToggle, "Toggle Visibility" )
        ]
    , -- Animation area with boxes
      el
        [ width (fill |> maximum 600)
        , height (px 300)
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
        , htmlAttribute (Html.Attributes.style "overflow" "hidden")
        ]
        (el
            [ centerX
            , Element.centerY
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
            ++ (Sub.htmlAttributes elementId model.animations
                    |> List.map htmlAttribute
               )
        )
        (el
            [ centerX
            , Element.centerY
            , Font.color Colors.backgroundWhite
            , Font.bold
            , Font.size 16
            ]
            (text label)
        )
