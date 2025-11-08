port module ElmUI.Ports.Mixed.Main exposing (main)

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
import Anim.Easing exposing (Easing(..))
import Anim.Ports exposing (Model, animateMultiple, handlePropertyUpdateFromJson, init, styleProperties)
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode



-- PORTS


port animateElement : Encode.Value -> Cmd msg


port stopElement : Encode.Value -> Cmd msg


port positionUpdates : (Decode.Value -> msg) -> Sub msg


port animationComplete : (String -> msg) -> Sub msg



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
    { animations : Anim.Ports.Model
    }


type Msg
    = StartComplexAnimation String
    | StartFadeMove String
    | StartSpinScale String
    | StartColorMorph String
    | StartFullTransform String
    | ResetAll
    | AnimationComplete String
    | PositionUpdateReceived (Result Decode.Error Anim.Ports.PropertyUpdate)



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartComplexAnimation elementId ->
            -- Combine position + scale + rotation
            let
                ( newModel, cmd ) =
                    element elementId
                        |> withPosition (Position 200 100)
                        |> withScale { x = 1.5, y = 1.9 }
                        |> withRotation 90
                        |> animateMultiple model.animations
                            { duration = 1000
                            , easing = EasePreset EaseInOut
                            , portFunction = animateElement
                            }
            in
            ( { model | animations = newModel }, cmd )

        StartFadeMove elementId ->
            -- Combine opacity + position
            let
                ( newModel, cmd ) =
                    element elementId
                        |> withOpacity 0.3
                        |> withPosition (Position 250 80)
                        |> animateMultiple model.animations
                            { duration = 1000
                            , easing = EasePreset EaseInOut
                            , portFunction = animateElement
                            }
            in
            ( { model | animations = newModel }, cmd )

        StartSpinScale elementId ->
            -- Combine rotation + scale + color
            let
                ( newModel, cmd ) =
                    element elementId
                        |> withRotation 180
                        |> withScale { x = 0.8, y = 0.8 }
                        |> withBackgroundColor (Hex "#e74c3c")
                        |> animateMultiple model.animations
                            { duration = 1000
                            , easing = EasePreset EaseInOut
                            , portFunction = animateElement
                            }
            in
            ( { model | animations = newModel }, cmd )

        StartColorMorph elementId ->
            -- Combine color + scale + opacity
            let
                ( newModel, cmd ) =
                    element elementId
                        |> withBackgroundColor (Hsl { h = 142, s = 71, l = 45 })
                        |> withScale { x = 2.0, y = 0.5 }
                        |> withOpacity 0.8
                        |> animateMultiple model.animations
                            { duration = 1000
                            , easing = EasePreset EaseInOut
                            , portFunction = animateElement
                            }
            in
            ( { model | animations = newModel }, cmd )

        StartFullTransform elementId ->
            -- All properties at once with elegant multi-property builder!
            let
                ( newModel, cmd ) =
                    element elementId
                        |> withPosition (Position 200 200)
                        |> withScale { x = 1.3, y = 1.3 }
                        |> withRotation 270
                        |> withOpacity 0.7
                        |> withBackgroundColor (Hex "#9b59b6")
                        |> animateMultiple model.animations
                            { duration = 1000
                            , easing = EasePreset EaseInOut
                            , portFunction = animateElement
                            }
            in
            ( { model | animations = newModel }, cmd )

        ResetAll ->
            let
                ( newModel, cmd ) =
                    element "mixed-box"
                        |> withPosition (Position 0 0)
                        |> withScale { x = 1.0, y = 1.0 }
                        |> withRotation 0
                        |> withOpacity 1.0
                        |> withBackgroundColor (Hex "#3498db")
                        |> animateMultiple model.animations
                            { duration = 800
                            , easing = EasePreset EaseInOut
                            , portFunction = animateElement
                            }
            in
            ( { model | animations = newModel }, cmd )

        AnimationComplete _ ->
            ( model, Cmd.none )

        PositionUpdateReceived result ->
            case result of
                Ok propertyUpdate ->
                    ( { model | animations = Anim.Ports.handlePropertyUpdate propertyUpdate model.animations }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.Ports.init
      }
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ positionUpdates (PositionUpdateReceived << handlePropertyUpdateFromJson)
        , animationComplete AnimationComplete
        ]



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Ports Mixed Properties ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "Ports Mixed Property Animations"
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
