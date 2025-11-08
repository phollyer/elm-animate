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

import Anim exposing (ColorValue(..), Position, RotationValue, ScaleValue)
import Anim.Sub exposing (Model, animate, init, step, styleProperties, transform)
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
    { animations : Anim.Sub.Model
    }


type Msg
    = StartComplexAnimation String
    | StartFadeMove String
    | StartSpinScale String
    | StartColorMorph String
    | StartFullTransform String
    | ResetAll
    | AnimationFrame Float



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartComplexAnimation elementId ->
            -- Combine position + scale + rotation
            let
                positionAnimation =
                    Anim.position elementId { x = 200, y = 100 }
                        |> Anim.pixelsPerSecond 200.0
                        |> Anim.easeOut

                scaleAnimation =
                    Anim.scale elementId { x = 1.5, y = 1.9 }
                        |> Anim.scalePerSecond 2.0
                        |> Anim.easeOut

                rotationAnimation =
                    Anim.rotation elementId 90
                        |> Anim.degreesPerSecond 120.0
                        |> Anim.easeInOut

                animations =
                    model.animations
                        |> animate positionAnimation
                        |> animate scaleAnimation
                        |> animate rotationAnimation
            in
            ( { model | animations = animations }, Cmd.none )

        StartFadeMove elementId ->
            -- Combine opacity + position
            let
                opacityAnimation =
                    Anim.opacity elementId 0.3
                        |> Anim.opacityPerSecond 2.0
                        |> Anim.easeOut

                positionAnimation =
                    Anim.position elementId { x = 250, y = 80 }
                        |> Anim.pixelsPerSecond 200.0
                        |> Anim.easeOut

                animations =
                    model.animations
                        |> animate opacityAnimation
                        |> animate positionAnimation
            in
            ( { model | animations = animations }, Cmd.none )

        StartSpinScale elementId ->
            -- Combine rotation + scale + color
            let
                rotationAnimation =
                    Anim.rotation elementId 180
                        |> Anim.degreesPerSecond 180.0
                        |> Anim.easeInOut

                scaleAnimation =
                    Anim.scale elementId { x = 0.8, y = 0.8 }
                        |> Anim.scalePerSecond 1.5
                        |> Anim.easeInOut

                colorAnimation =
                    Anim.backgroundColor elementId (Hex "#e74c3c")
                        |> Anim.colorStepsPerSecond 300.0
                        |> Anim.easeOut

                animations =
                    model.animations
                        |> animate rotationAnimation
                        |> animate scaleAnimation
                        |> animate colorAnimation
            in
            ( { model | animations = animations }, Cmd.none )

        StartColorMorph elementId ->
            -- Combine color + scale + opacity
            let
                colorAnimation =
                    Anim.backgroundColor elementId (Hsl { h = 142, s = 71, l = 45 })
                        |> Anim.colorStepsPerSecond 300.0
                        |> Anim.easeInOut

                scaleAnimation =
                    Anim.scale elementId { x = 2.0, y = 0.5 }
                        |> Anim.scalePerSecond 2.0
                        |> Anim.easeOut

                opacityAnimation =
                    Anim.opacity elementId 0.8
                        |> Anim.opacityPerSecond 1.5
                        |> Anim.easeOut

                animations =
                    model.animations
                        |> animate colorAnimation
                        |> animate scaleAnimation
                        |> animate opacityAnimation
            in
            ( { model | animations = animations }, Cmd.none )

        StartFullTransform elementId ->
            -- All properties at once!
            let
                positionAnimation =
                    Anim.position elementId { x = 200, y = 200 }
                        |> Anim.pixelsPerSecond 200.0
                        |> Anim.easeInOut

                scaleAnimation =
                    Anim.scale elementId { x = 1.3, y = 1.3 }
                        |> Anim.scalePerSecond 1.5
                        |> Anim.easeOut

                rotationAnimation =
                    Anim.rotation elementId 270
                        |> Anim.degreesPerSecond 180.0
                        |> Anim.easeInOut

                opacityAnimation =
                    Anim.opacity elementId 0.7
                        |> Anim.opacityPerSecond 1.0
                        |> Anim.easeOut

                colorAnimation =
                    Anim.backgroundColor elementId (Hex "#9b59b6")
                        |> Anim.colorStepsPerSecond 300.0
                        |> Anim.easeOut

                animations =
                    model.animations
                        |> animate positionAnimation
                        |> animate scaleAnimation
                        |> animate rotationAnimation
                        |> animate opacityAnimation
                        |> animate colorAnimation
            in
            ( { model | animations = animations }, Cmd.none )

        ResetAll ->
            let
                positionAnimation =
                    Anim.position "mixed-box" { x = 0, y = 0 }
                        |> Anim.pixelsPerSecond 200.0
                        |> Anim.easeInOut

                scaleAnimation =
                    Anim.scale "mixed-box" { x = 1.0, y = 1.0 }
                        |> Anim.scalePerSecond 1.5
                        |> Anim.easeInOut

                rotationAnimation =
                    Anim.rotation "mixed-box" 0
                        |> Anim.degreesPerSecond 180.0
                        |> Anim.easeInOut

                opacityAnimation =
                    Anim.opacity "mixed-box" 1.0
                        |> Anim.opacityPerSecond 1.5
                        |> Anim.easeInOut

                colorAnimation =
                    Anim.backgroundColor "mixed-box" (Hex "#3498db")
                        |> Anim.colorStepsPerSecond 300.0
                        |> Anim.easeOut

                animations =
                    model.animations
                        |> animate positionAnimation
                        |> animate scaleAnimation
                        |> animate rotationAnimation
                        |> animate opacityAnimation
                        |> animate colorAnimation
            in
            ( { model | animations = animations }, Cmd.none )

        AnimationFrame deltaTime ->
            ( { model | animations = step deltaTime model.animations }, Cmd.none )



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.Sub.init
      }
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Anim.Sub.subscriptions AnimationFrame model.animations



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
    , UI.pageHeader "Subscription-Based Mixed Property Animations"
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
            ++ (styleProperties "mixed-box" model.animations
                    |> List.map (\( prop, value ) -> htmlAttribute (Html.Attributes.style prop value))
               )
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
