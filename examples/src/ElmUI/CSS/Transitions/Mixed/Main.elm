module ElmUI.CSS.Transitions.Mixed.Main exposing (main)

{-| Anim.Engine.CSS Mixed Properties Example using ElmUI - Combined animation effects

This example demonstrates combining multiple CSS properties in single animations.
Shows how to create rich, complex effects by mixing position, scale, rotate, opacity, and color.

ANIMATION COMBINATIONS:

  - ✅ Complex Transform: Position + Scale + Rotate
  - ✅ Fade & Move: Opacity + Position
  - ✅ Spin & Scale: Rotate + Scale with synchronized timing
  - ✅ Color Morph: Background Color + Scale coordination
  - ✅ Full Transform: All properties animated simultaneously
  - ✅ Coordinated Timing: Different durations and easing per property

BENEFITS:

  - ✅ Smooth multi-property transitions
  - ✅ Hardware-accelerated transforms
  - ✅ Independent property timing control
  - ✅ Rich interaction feedback patterns
  - ✅ Consistent global easing application

-}

import Anim.Easing as Easing exposing (Easing(..))
import Anim.Engine.CSS as CSS
import Anim.Property.BackgroundColor as Color
import Anim.Property.Opacity as Opacity
import Anim.Property.Position as Position
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, row, spacing, text, width)
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
    { animations : CSS.AnimState
    , isAnimating : Bool
    , activeAnimation : Maybe AnimationType
    }


type AnimationType
    = ComplexTransform
    | FadeMove
    | SpinScale
    | ColorMorph
    | FullTransform



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = CSS.init
      , isAnimating = False
      , activeAnimation = Nothing
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = StartComplexTransform
    | StartFadeMove
    | StartSpinScale
    | StartColorMorph
    | StartFullTransform
    | ResetAll


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartComplexTransform ->
            -- Combine position + scale + rotate with different easing
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        -- Global Defaults
                        |> CSS.duration 800
                        |> CSS.easing QuadInOut
                        -- Position
                        |> Position.for "mixed-box"
                        |> Position.toXY 200 100
                        |> Position.easing SineInOut
                        |> Position.build
                        -- Scale
                        |> Scale.for "mixed-box"
                        |> Scale.toXY 1.5 1.2
                        |> Scale.easing BackInOut
                        |> Scale.duration 1000
                        |> Scale.build
                        -- Rotate
                        |> Rotate.for "mixed-box"
                        |> Rotate.toZ 45
                        |> Rotate.easing ElasticOut
                        |> Rotate.duration 1200
                        |> Rotate.build
                        |> CSS.animate
                , isAnimating = True
                , activeAnimation = Just ComplexTransform
              }
            , Cmd.none
            )

        StartFadeMove ->
            -- Combine opacity + position with synchronized timing
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        -- Global Defaults
                        |> CSS.duration 800
                        |> CSS.easing CubicInOut
                        -- Opacity
                        |> Opacity.for "mixed-box"
                        |> Opacity.to 0.3
                        |> Opacity.build
                        -- Position
                        |> Position.for "mixed-box"
                        |> Position.toXY 250 150
                        |> Position.build
                        |> CSS.animate
                , isAnimating = True
                , activeAnimation = Just FadeMove
              }
            , Cmd.none
            )

        StartSpinScale ->
            -- Rotate + scale with delayed start
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        -- Global Defaults
                        |> CSS.duration 1000
                        |> CSS.easing BounceOut
                        -- Rotate
                        |> Rotate.for "mixed-box"
                        |> Rotate.toZ 180
                        |> Rotate.build
                        -- Scale
                        |> Scale.for "mixed-box"
                        |> Scale.toXY 0.8 0.8
                        |> Scale.delay 200
                        |> Scale.build
                        |> CSS.animate
                , isAnimating = True
                , activeAnimation = Just SpinScale
              }
            , Cmd.none
            )

        StartColorMorph ->
            -- Color + scale with smooth coordination
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        -- Global Defaults
                        |> CSS.duration 900
                        |> CSS.easing QuartInOut
                        -- Color
                        |> Color.for "mixed-box"
                        |> Color.to (Color.Rgb { r = 255, g = 100, b = 150 })
                        |> Color.build
                        -- Scale
                        |> Scale.for "mixed-box"
                        |> Scale.toXY 1.3 1.3
                        |> Scale.build
                        |> CSS.animate
                , isAnimating = True
                , activeAnimation = Just ColorMorph
              }
            , Cmd.none
            )

        StartFullTransform ->
            -- All properties with staggered timing - API handles transform order automatically
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        -- Position
                        |> Position.for "mixed-box"
                        |> Position.toXY 150 200
                        |> Position.easing ExpoInOut
                        |> Position.duration 1200
                        |> Position.build
                        -- Rotate
                        |> Rotate.for "mixed-box"
                        |> Rotate.toZ 135
                        |> Rotate.easing ElasticInOut
                        |> Rotate.duration 1400
                        |> Rotate.delay 300
                        |> Rotate.build
                        -- Scale
                        |> Scale.for "mixed-box"
                        |> Scale.toXY 1.4 0.9
                        |> Scale.easing CircInOut
                        |> Scale.duration 1000
                        |> Scale.delay 2000
                        |> Scale.build
                        -- Opacity
                        |> Opacity.for "mixed-box"
                        |> Opacity.to 0.7
                        |> Opacity.easing Linear
                        |> Opacity.duration 800
                        |> Opacity.delay 100
                        |> Opacity.build
                        -- Color
                        |> Color.for "mixed-box"
                        |> Color.to (Color.Rgb { r = 100, g = 255, b = 200 })
                        |> Color.easing QuintInOut
                        |> Color.duration 1100
                        |> Color.delay 400
                        |> Color.build
                        |> CSS.animate
                , isAnimating = True
                , activeAnimation = Just FullTransform
              }
            , Cmd.none
            )

        ResetAll ->
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        -- Global Defaults
                        |> CSS.duration 800
                        |> CSS.easing QuadInOut
                        -- Position
                        |> Position.for "mixed-box"
                        |> Position.toXY 0 0
                        |> Position.build
                        -- Opacity
                        |> Opacity.for "mixed-box"
                        |> Opacity.to 1.0
                        |> Opacity.build
                        -- Scale
                        |> Scale.for "mixed-box"
                        |> Scale.toXY 1.0 1.0
                        |> Scale.build
                        -- Rotate
                        |> Rotate.for "mixed-box"
                        |> Rotate.toZ 0
                        |> Rotate.build
                        -- Color
                        |> Color.for "mixed-box"
                        |> Color.to (Color.Rgb { r = 59, g = 130, b = 246 })
                        |> Color.build
                        |> CSS.animate
                , isAnimating = True
                , activeAnimation = Nothing
              }
            , Cmd.none
            )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.CSS Mixed Properties ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & CSS Transitions Mixed Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        , width (fill |> maximum 600)
        ]
        (paragraph []
            [ text "Combining multiple CSS properties creates rich, complex animations. Each property can have independent timing and easing for sophisticated effects."
            ]
        )
    , -- Current animation status
      column
        [ spacing 8, centerX ]
        [ el
            [ Font.size 14
            , Font.color
                (if model.isAnimating then
                    Colors.warning

                 else
                    Colors.success
                )
            , centerX
            , Font.medium
            ]
            (text
                (if model.isAnimating then
                    case model.activeAnimation of
                        Just ComplexTransform ->
                            "🎬 Complex Transform: Position + Scale + Rotate"

                        Just FadeMove ->
                            "🎬 Fade & Move: Opacity + Position"

                        Just SpinScale ->
                            "🎬 Spin & Scale: Rotate + Scale (Delayed)"

                        Just ColorMorph ->
                            "🎬 Color Morph: Background + Scale"

                        Just FullTransform ->
                            "🎬 Full Transform: All Properties (Staggered)"

                        Nothing ->
                            "🎬 Resetting All Properties..."

                 else
                    "✅ Animation Complete"
                )
            )
        ]
    , -- Control buttons
      column
        [ spacing 12, centerX ]
        [ UI.wrappedButtonRow
            [ ( UI.Primary, StartComplexTransform, "Complex Transform" )
            , ( UI.Success, StartFadeMove, "Fade & Move" )
            ]
        , UI.wrappedButtonRow
            [ ( UI.Warning, StartSpinScale, "Spin & Scale" )
            , ( UI.Purple, StartColorMorph, "Color Morph" )
            ]
        , UI.wrappedButtonRow
            [ ( UI.Warning, StartFullTransform, "Full Transform" )
            , ( UI.Purple, ResetAll, "Reset All" )
            ]
        ]
    , -- Animation area
      el
        [ width (fill |> maximum 400)
        , height (px 350)
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
            ([ width (px 60)
             , height (px 60)
             , Background.color Colors.primary
             , Border.rounded 12
             , htmlAttribute (Html.Attributes.id "mixed-box")
             , htmlAttribute (Html.Attributes.style "position" "absolute")
             , htmlAttribute (Html.Attributes.style "display" "flex")
             , htmlAttribute (Html.Attributes.style "align-items" "center")
             , htmlAttribute (Html.Attributes.style "justify-content" "center")
             ]
                ++ List.map htmlAttribute (CSS.htmlAttributes "mixed-box" model.animations)
            )
            (el [ centerX, centerY, Font.size 24, Font.color Colors.backgroundWhite ]
                (text "🎨")
            )
        )
    , -- Animation details
      column
        [ spacing 16, width (fill |> maximum 700), centerX ]
        [ el
            [ Font.size 18, centerX, Font.medium, Font.color Colors.textDark ]
            (text "🎭 Animation Combinations")
        , column
            [ spacing 12, width fill ]
            [ viewAnimationDetail
                "🔄 Complex Transform"
                "Position + Scale + Rotate with different easing functions"
                [ "Position: SineInOut (800ms)"
                , "Scale: BackInOut (1000ms)"
                , "Rotate: ElasticOut (1200ms)"
                ]
            , viewAnimationDetail
                "👻 Fade & Move"
                "Synchronized opacity and position changes"
                [ "Opacity: CubicInOut (800ms)"
                , "Position: CubicInOut (800ms)"
                ]
            , viewAnimationDetail
                "🌪️ Spin & Scale"
                "Rotate with delayed scale animation"
                [ "Rotation: BounceOut (1000ms)"
                , "Scale: BounceOut (1000ms, 200ms delay)"
                ]
            , viewAnimationDetail
                "🎨 Color Morph"
                "Color transition with coordinated scaling"
                [ "Background: QuartInOut (900ms)"
                , "Scale: QuartInOut (900ms)"
                ]
            , viewAnimationDetail
                "⭐ Full Transform"
                "All properties with staggered timing (transform order handled automatically by API)"
                [ "Position: ExpoInOut (1200ms, 0ms delay)"
                , "Opacity: Linear (800ms, 100ms delay)"
                , "Scale: CircInOut (1000ms, 200ms delay)"
                , "Rotation: ElasticInOut (1400ms, 300ms delay)"
                , "Color: QuintInOut (1100ms, 400ms delay)"
                ]
            ]
        ]
    ]


viewAnimationDetail : String -> String -> List String -> Element Msg
viewAnimationDetail title description properties =
    column
        [ spacing 8
        , width fill
        , padding 16
        , Background.color Colors.backgroundLight
        , Border.rounded 8
        ]
        [ el
            [ Font.size 16, Font.medium, Font.color Colors.textDark ]
            (text title)
        , el
            [ Font.size 14, Font.color Colors.textMedium ]
            (text description)
        , column
            [ spacing 4, paddingXY 12 8 ]
            (List.map
                (\property ->
                    el
                        [ Font.size 13
                        , Font.color Colors.textLight
                        , Font.family [ Font.monospace ]
                        ]
                        (text ("• " ++ property))
                )
                properties
            )
        ]
