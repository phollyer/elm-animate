module ElmUI.CSS.Mixed.Main exposing (main)

{-| Anim.CSS Mixed Properties Example using ElmUI - Combined animation effects

This example demonstrates combining multiple CSS properties in single animations.
Shows how to create rich, complex effects by mixing position, scale, rotation, opacity, and color.

FEATURES:

  - ✅ Multiple simultaneous property animations
  - ✅ Coordinated transform combinations (position + scale + rotation)
  - ✅ Fade + move effects (opacity + position)
  - ✅ Color morphing with size changes (background + scale)
  - ✅ Complex interaction patterns with smooth transitions

-}

import Anim
import Anim.CSS as CSS exposing (AnimationResult)
import Anim.Easing as Easing
import Anim.Internal exposing (ColorValue(..))
import Anim.Properties.Color as Color
import Anim.Properties.Opacity as Opacity
import Anim.Properties.Position as Position
import Anim.Properties.Rotate as Rotate
import Anim.Properties.Scale as Scale
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
    , isAnimating : Bool
    }


type Msg
    = StartComplexAnimation String
    | StartFadeMove String
    | StartSpinScale String
    | StartColorMorph String
    | StartFullTransform String
    | ResetAll
    | AnimationComplete



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartComplexAnimation elementId ->
            -- Combine position + scale + rotation
            let
                animationResult =
                    Anim.init elementId
                        |> Position.to { x = 200, y = 100 }
                        |> Scale.to { x = 1.5, y = 1.9 }
                        |> Rotate.to 90
                        |> Anim.duration 800
                        |> Anim.easing Easing.easeInOutQuad
                        |> CSS.animate
            in
            ( { model | animations = Just animationResult, isAnimating = True }, Cmd.none )

        StartFadeMove elementId ->
            -- Combine opacity + position
            let
                animationResult =
                    Anim.init elementId
                        |> Opacity.to 0.3
                        |> Position.to { x = 250, y = 80 }
                        |> Anim.duration 600
                        |> Anim.easing Easing.easeOutQuad
                        |> CSS.animate
            in
            ( { model | animations = Just animationResult, isAnimating = True }, Cmd.none )

        StartSpinScale elementId ->
            -- Combine rotation + scale + color
            let
                animationResult =
                    Anim.init elementId
                        |> Rotate.to 180
                        |> Scale.to { x = 0.8, y = 0.8 }
                        |> Color.to (Hex "#e74c3c")
                        |> Anim.duration 700
                        |> Anim.easing Easing.easeInOutBack
                        |> CSS.animate
            in
            ( { model | animations = Just animationResult, isAnimating = True }, Cmd.none )

        StartColorMorph elementId ->
            -- Combine color + scale + opacity
            let
                animationResult =
                    Anim.init elementId
                        |> Color.to (Hsl { h = 142, s = 71, l = 45 })
                        |> Scale.to { x = 2.0, y = 0.5 }
                        |> Opacity.to 0.8
                        |> Anim.duration 900
                        |> Anim.easing Easing.easeInOutCubic
                        |> CSS.animate
            in
            ( { model | animations = Just animationResult, isAnimating = True }, Cmd.none )

        StartFullTransform elementId ->
            -- All properties at once!
            let
                animationResult =
                    Anim.init elementId
                        |> Position.to { x = 200, y = 200 }
                        |> Scale.to { x = 1.3, y = 1.3 }
                        |> Rotate.to 270
                        |> Opacity.to 0.7
                        |> Color.to (Hex "#9b59b6")
                        |> Anim.duration 1000
                        |> Anim.easing Easing.easeInOutElastic
                        |> CSS.animate
            in
            ( { model | animations = Just animationResult, isAnimating = True }, Cmd.none )

        ResetAll ->
            let
                animationResult =
                    Anim.init "mixed-box"
                        |> Position.to { x = 0, y = 0 }
                        |> Scale.to { x = 1.0, y = 1.0 }
                        |> Rotate.to 0
                        |> Opacity.to 1.0
                        |> Color.to (Hex "#3498db")
                        |> Anim.duration 500
                        |> Anim.easing Easing.easeInOutQuad
                        |> CSS.animate
            in
            ( { model | animations = Just animationResult, isAnimating = True }, Cmd.none )

        AnimationComplete ->
            ( { model | isAnimating = False, animations = Nothing }, Cmd.none )



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Nothing
      , isAnimating = False
      }
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.CSS Mixed Properties ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "CSS Mixed Property Animations"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Combining multiple CSS properties in single animations for complex transformations")
    , -- Mixed property animation controls
      UI.wrappedButtonRow
        [ ( UI.Primary, StartComplexAnimation "mixed-box", "Move + Scale + Rotate" )
        , ( UI.Success, StartFadeMove "mixed-box", "Fade + Move" )
        , ( UI.Warning, StartSpinScale "mixed-box", "Spin + Scale + Color" )
        , ( UI.Purple, StartColorMorph "mixed-box", "Color + Shape + Opacity" )
        , ( UI.Primary, StartFullTransform "mixed-box", "ALL Properties!" )
        , ( UI.Success, ResetAll, "Reset" )
        ]
    , -- Animation area
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
        ]
        (mixedAnimationBox model)
    ]


mixedAnimationBox : Model -> Element Msg
mixedAnimationBox model =
    el
        ([ width (px 80)
         , height (px 80)
         , Border.rounded 12
         , htmlAttribute (Html.Attributes.id "mixed-box")
         , htmlAttribute (Html.Attributes.style "position" "absolute")
         , htmlAttribute (Html.Attributes.style "background-color" "#3498db") -- Default blue
         , htmlAttribute (Html.Attributes.style "transform-origin" "center")
         , htmlAttribute (Html.Attributes.style "display" "flex")
         , htmlAttribute (Html.Attributes.style "align-items" "center")
         , htmlAttribute (Html.Attributes.style "justify-content" "center")
         ]
            ++ List.map htmlAttribute (CSS.htmlAttributes "mixed-box" model.animations AnimationComplete)
        )
        (el
            [ centerX
            , Element.centerY
            , Font.color Colors.backgroundWhite
            , Font.bold
            , Font.size 14
            , htmlAttribute (Html.Attributes.style "text-shadow" "0 1px 2px rgba(0,0,0,0.5)")
            ]
            (text "MIX")
        )
