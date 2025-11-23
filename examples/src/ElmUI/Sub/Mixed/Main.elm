module ElmUI.Sub.Mixed.Main exposing (main)

{-| Anim.Sub Mixed Properties Example using ElmUI - Combined animation effects

This example demonstrates combining multiple Subscription-Based properties in single animations.
Shows how to create rich, complex effects by mixing position, scale, rotation, opacity, and color.

FEATURES:

  - ✅ Multiple simultaneous property animations
  - ✅ Coordinated transform combinations (position + scale + rotation)
  - ✅ Fade + move effects (opacity + position)
  - ✅ Color morphing with size changes (background + scale)
  - ✅ Complex interaction patterns with smooth transitions

-}

import Anim
import Anim.Properties.Color as Color
import Anim.Properties.Opacity as Opacity
import Anim.Properties.Position as Position
import Anim.Properties.Rotate as Rotate
import Anim.Properties.Scale as Scale
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
    { animations : Sub.AnimationState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Sub.init }
    , Cmd.none
    )



-- UPDATE


type Msg
    = StartComplexAnimation String
    | StartFadeMove String
    | StartSpinScale String
    | StartColorMorph String
    | StartFullTransform String
    | ResetAll
    | AnimationMsg Sub.AnimationMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartComplexAnimation elementId ->
            -- Combine position + scale + rotation
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Position.for elementId
                        |> Position.toXY 200 100
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseOut
                        |> Position.build
                        |> Scale.for elementId
                        |> Scale.toXY 1.5 1.9
                        |> Scale.speed 2.0
                        |> Scale.easing Easing.EaseOut
                        |> Scale.build
                        |> Rotate.for elementId
                        |> Rotate.to 90
                        |> Rotate.speed 120.0
                        |> Rotate.easing Easing.EaseInOut
                        |> Rotate.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        StartFadeMove elementId ->
            -- Combine opacity + position
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Opacity.for elementId
                        |> Opacity.to 0.3
                        |> Opacity.speed 2.0
                        |> Opacity.easing Easing.EaseOut
                        |> Opacity.build
                        |> Position.for elementId
                        |> Position.toXY 250 80
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseOut
                        |> Position.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        StartSpinScale elementId ->
            -- Combine rotation + scale + color
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Rotate.for elementId
                        |> Rotate.to 180
                        |> Rotate.speed 180.0
                        |> Rotate.easing Easing.EaseInOut
                        |> Rotate.build
                        |> Scale.for elementId
                        |> Scale.toXY 0.8 0.8
                        |> Scale.speed 1.5
                        |> Scale.easing Easing.EaseInOut
                        |> Scale.build
                        |> Color.for elementId
                        |> Color.to (Color.Hsl { h = 351, s = 83, l = 61 })
                        |> Color.speed 300.0
                        |> Color.easing Easing.EaseOut
                        |> Color.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        StartColorMorph elementId ->
            -- Combine color + scale + opacity
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Color.for elementId
                        |> Color.to (Color.Hsl { h = 142, s = 71, l = 45 })
                        |> Color.speed 300.0
                        |> Color.easing Easing.EaseInOut
                        |> Color.build
                        |> Scale.for elementId
                        |> Scale.toXY 2.0 0.5
                        |> Scale.speed 2.0
                        |> Scale.easing Easing.EaseOut
                        |> Scale.build
                        |> Opacity.for elementId
                        |> Opacity.to 0.8
                        |> Opacity.speed 1.5
                        |> Opacity.easing Easing.EaseOut
                        |> Opacity.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        StartFullTransform elementId ->
            -- All properties at once!
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Position.for elementId
                        |> Position.toXY 200 200
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Scale.for elementId
                        |> Scale.toXY 1.3 1.3
                        |> Scale.speed 1.5
                        |> Scale.easing Easing.EaseOut
                        |> Scale.build
                        |> Rotate.for elementId
                        |> Rotate.to 270
                        |> Rotate.speed 180.0
                        |> Rotate.easing Easing.EaseInOut
                        |> Rotate.build
                        |> Opacity.for elementId
                        |> Opacity.to 0.7
                        |> Opacity.speed 1.0
                        |> Opacity.easing Easing.EaseOut
                        |> Opacity.build
                        |> Color.for elementId
                        |> Color.to (Color.Hsl { h = 351, s = 83, l = 61 })
                        |> Color.speed 300.0
                        |> Color.easing Easing.EaseOut
                        |> Color.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        ResetAll ->
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> Position.for "mixed-box"
                        |> Position.toXY 0 0
                        |> Position.speed 200.0
                        |> Position.easing Easing.EaseInOut
                        |> Position.build
                        |> Scale.for "mixed-box"
                        |> Scale.toXY 1.0 1.0
                        |> Scale.speed 1.5
                        |> Scale.easing Easing.EaseInOut
                        |> Scale.build
                        |> Rotate.for "mixed-box"
                        |> Rotate.to 0
                        |> Rotate.speed 180.0
                        |> Rotate.easing Easing.EaseInOut
                        |> Rotate.build
                        |> Opacity.for "mixed-box"
                        |> Opacity.to 1.0
                        |> Opacity.speed 1.5
                        |> Opacity.easing Easing.EaseInOut
                        |> Opacity.build
                        |> Color.for "mixed-box"
                        |> Color.to (Color.Hsl { h = 207, s = 90, l = 54 })
                        |> Color.speed 300.0
                        |> Color.easing Easing.EaseOut
                        |> Color.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        AnimationMsg subMsg ->
            ( { model | animations = Sub.update subMsg model.animations }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map AnimationMsg <|
        Sub.subscriptions model.animations



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Sub Mixed Properties ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Subscription Mixed Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Combining multiple Subscription-Based properties in single animations for complex transformations")
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
            ++ List.map htmlAttribute (Sub.htmlAttributes "mixed-box" model.animations |> Debug.log "Attrs")
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
