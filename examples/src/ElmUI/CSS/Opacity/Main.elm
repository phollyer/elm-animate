module ElmUI.CSS.Opacity.Main exposing (main)

{-| Anim.CSS Opacity Example using ElmUI - Fade animations with CSS transitions

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
import Anim.CSS as CSS exposing (AnimationResult)
import Anim.Easing as Easing
import Anim.Properties.Opacity as Opacity
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
    { animations : Maybe AnimationResult
    , isVisible : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Nothing
      , isVisible = True
      }
    , Cmd.none
    )


type Msg
    = FadeIn
    | FadeOut
    | FadeToggle
    | AnimationComplete



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FadeIn ->
            let
                animationResult =
                    Anim.init "box"
                        |> Opacity.to 1.0
                        |> Anim.duration 600
                        |> Anim.easing Easing.easeOut
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isVisible = True
              }
            , Cmd.none
            )

        FadeOut ->
            let
                animationResult =
                    Anim.init "box"
                        |> Opacity.to 0.0
                        |> Anim.duration 400
                        |> Anim.easing Easing.easeIn
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
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

                animationResult =
                    Anim.init "box"
                        |> Opacity.to newOpacity
                        |> Anim.duration 500
                        |> Anim.easing Easing.easeInOut
                        |> CSS.animate
            in
            ( { model
                | animations = Just animationResult
                , isVisible = newVisible
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.CSS Opacity ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
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
            ++ (case model.animations of
                    Just animationResult ->
                        CSS.getElementStyles elementId animationResult
                            |> List.map (\( prop, value ) -> htmlAttribute (Html.Attributes.style prop value))

                    Nothing ->
                        []
               )
            ++ [ htmlAttribute
                    (Html.Attributes.style "transition"
                        (case model.animations of
                            Just _ ->
                                "opacity 500ms ease-in-out"

                            Nothing ->
                                "none"
                        )
                    )
               , htmlAttribute (CSS.onTransitionEnd AnimationComplete)
               ]
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
