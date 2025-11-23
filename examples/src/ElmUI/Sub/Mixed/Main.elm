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
import Anim.Properties.Color as ColorBuilder exposing (Color(..))
import Anim.Properties.Opacity as OpacityBuilder
import Anim.Properties.Position as PositionBuilder
import Anim.Properties.Rotate as RotationBuilder
import Anim.Properties.Scale as ScaleBuilder
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


type Msg
    = StartComplexAnimation String
    | StartFadeMove String
    | StartSpinScale String
    | StartColorMorph String
    | StartFullTransform String
    | ResetAll
    | AnimationMsg Sub.AnimationMsg



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartComplexAnimation elementId ->
            -- Combine position + scale + rotation
            ( { model
                | animations =
                    model.animations
                        |> Sub.builder
                        |> PositionBuilder.for elementId
                        |> PositionBuilder.toXY 200 100
                        |> PositionBuilder.speed 200.0
                        |> PositionBuilder.easing Easing.EaseOut
                        |> PositionBuilder.build
                        |> Sub.animate
                        |> Sub.builder
                        |> ScaleBuilder.for elementId
                        |> ScaleBuilder.toXY 1.5 1.9
                        |> ScaleBuilder.speed 2.0
                        |> ScaleBuilder.easing Easing.EaseOut
                        |> ScaleBuilder.build
                        |> Sub.animate
                        |> Sub.builder
                        |> RotationBuilder.for elementId
                        |> RotationBuilder.to 90
                        |> RotationBuilder.speed 120.0
                        |> RotationBuilder.easing Easing.EaseInOut
                        |> RotationBuilder.build
                        |> Sub.animate
              }
            , Cmd.none
            )

        StartFadeMove elementId ->
            -- Combine opacity + position
            let
                opacityConfig =
                    Sub.builder
                        |> OpacityBuilder.for elementId
                        |> OpacityBuilder.to 0.3
                        |> OpacityBuilder.speed 2.0
                        |> OpacityBuilder.easing Easing.EaseOut
                        |> OpacityBuilder.build

                positionConfig =
                    Sub.builder
                        |> PositionBuilder.for elementId
                        |> PositionBuilder.toXY 250 80
                        |> PositionBuilder.speed 200.0
                        |> PositionBuilder.easing Easing.EaseOut
                        |> PositionBuilder.build

                animations =
                    model.animations
                        |> Sub.animate opacityConfig
                        |> Sub.animate positionConfig
            in
            ( { model | animations = animations }, Cmd.none )

        StartSpinScale elementId ->
            -- Combine rotation + scale + color
            let
                rotationConfig =
                    Sub.builder
                        |> RotationBuilder.for elementId
                        |> RotationBuilder.to 180
                        |> RotationBuilder.speed 180.0
                        |> RotationBuilder.easing Easing.EaseInOut
                        |> RotationBuilder.build

                scaleConfig =
                    Sub.builder
                        |> ScaleBuilder.for elementId
                        |> ScaleBuilder.toXY 0.8 0.8
                        |> ScaleBuilder.speed 1.5
                        |> ScaleBuilder.easing Easing.EaseInOut
                        |> ScaleBuilder.build

                colorConfig =
                    Sub.builder
                        |> ColorBuilder.for elementId
                        |> ColorBuilder.to (Hex "#e74c3c")
                        |> ColorBuilder.speed 300.0
                        |> ColorBuilder.easing Easing.EaseOut
                        |> ColorBuilder.build

                animations =
                    model.animations
                        |> Sub.animate rotationConfig
                        |> Sub.animate scaleConfig
                        |> Sub.animate colorConfig
            in
            ( { model | animations = animations }, Cmd.none )

        StartColorMorph elementId ->
            -- Combine color + scale + opacity
            let
                colorConfig =
                    Sub.builder
                        |> ColorBuilder.for elementId
                        |> ColorBuilder.to (Hsl { h = 142, s = 71, l = 45 })
                        |> ColorBuilder.speed 300.0
                        |> ColorBuilder.easing Easing.EaseInOut
                        |> ColorBuilder.build

                scaleConfig =
                    Sub.builder
                        |> ScaleBuilder.for elementId
                        |> ScaleBuilder.toXY 2.0 0.5
                        |> ScaleBuilder.speed 2.0
                        |> ScaleBuilder.easing Easing.EaseOut
                        |> ScaleBuilder.build

                opacityConfig =
                    Sub.builder
                        |> OpacityBuilder.for elementId
                        |> OpacityBuilder.to 0.8
                        |> OpacityBuilder.speed 1.5
                        |> OpacityBuilder.easing Easing.EaseOut
                        |> OpacityBuilder.build

                animations =
                    model.animations
                        |> Sub.animate colorConfig
                        |> Sub.animate scaleConfig
                        |> Sub.animate opacityConfig
            in
            ( { model | animations = animations }, Cmd.none )

        StartFullTransform elementId ->
            -- All properties at once!
            let
                positionConfig =
                    Sub.builder
                        |> PositionBuilder.for elementId
                        |> PositionBuilder.toXY 200 200
                        |> PositionBuilder.speed 200.0
                        |> PositionBuilder.easing Easing.EaseInOut
                        |> PositionBuilder.build

                scaleConfig =
                    Sub.builder
                        |> ScaleBuilder.for elementId
                        |> ScaleBuilder.toXY 1.3 1.3
                        |> ScaleBuilder.speed 1.5
                        |> ScaleBuilder.easing Easing.EaseOut
                        |> ScaleBuilder.build

                rotationConfig =
                    Sub.builder
                        |> RotationBuilder.for elementId
                        |> RotationBuilder.to 270
                        |> RotationBuilder.speed 180.0
                        |> RotationBuilder.easing Easing.EaseInOut
                        |> RotationBuilder.build

                opacityConfig =
                    Sub.builder
                        |> OpacityBuilder.for elementId
                        |> OpacityBuilder.to 0.7
                        |> OpacityBuilder.speed 1.0
                        |> OpacityBuilder.easing Easing.EaseOut
                        |> OpacityBuilder.build

                colorConfig =
                    Sub.builder
                        |> ColorBuilder.for elementId
                        |> ColorBuilder.to (Hex "#9b59b6")
                        |> ColorBuilder.speed 300.0
                        |> ColorBuilder.easing Easing.EaseOut
                        |> ColorBuilder.build

                animations =
                    model.animations
                        |> Sub.animate positionConfig
                        |> Sub.animate scaleConfig
                        |> Sub.animate rotationConfig
                        |> Sub.animate opacityConfig
                        |> Sub.animate colorConfig
            in
            ( { model | animations = animations }, Cmd.none )

        ResetAll ->
            let
                positionConfig =
                    Sub.builder
                        |> PositionBuilder.for "mixed-box"
                        |> PositionBuilder.toXY 0 0
                        |> PositionBuilder.speed 200.0
                        |> PositionBuilder.easing Easing.EaseInOut
                        |> PositionBuilder.build

                scaleConfig =
                    Sub.builder
                        |> ScaleBuilder.for "mixed-box"
                        |> ScaleBuilder.toXY 1.0 1.0
                        |> ScaleBuilder.speed 1.5
                        |> ScaleBuilder.easing Easing.EaseInOut
                        |> ScaleBuilder.build

                rotationConfig =
                    Sub.builder
                        |> RotationBuilder.for "mixed-box"
                        |> RotationBuilder.to 0
                        |> RotationBuilder.speed 180.0
                        |> RotationBuilder.easing Easing.EaseInOut
                        |> RotationBuilder.build

                opacityConfig =
                    Sub.builder
                        |> OpacityBuilder.for "mixed-box"
                        |> OpacityBuilder.to 1.0
                        |> OpacityBuilder.speed 1.5
                        |> OpacityBuilder.easing Easing.EaseInOut
                        |> OpacityBuilder.build

                colorConfig =
                    Sub.builder
                        |> ColorBuilder.for "mixed-box"
                        |> ColorBuilder.to (Hex "#3498db")
                        |> ColorBuilder.speed 300.0
                        |> ColorBuilder.easing Easing.EaseOut
                        |> ColorBuilder.build

                animations =
                    model.animations
                        |> Sub.animate positionConfig
                        |> Sub.animate scaleConfig
                        |> Sub.animate rotationConfig
                        |> Sub.animate opacityConfig
                        |> Sub.animate colorConfig
            in
            ( { model | animations = animations }, Cmd.none )

        AnimationMsg subMsg ->
            ( { model | animations = Sub.update subMsg model.animations }, Cmd.none )



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Sub.init
      }
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.subscriptions AnimationMsg model.animations



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
            ++ (Sub.htmlAttributes "mixed-box" model.animations)
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
