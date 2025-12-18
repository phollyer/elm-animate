port module ElmUI.Ports.Mixed.Main exposing (main)

{-| Anim.Ports Mixed Properties Example using ElmUI - Combined animation effects

This example demonstrates combining multiple animation properties in single animations.
Shows how to create rich, complex effects by mixing position, scale, rotation, opacity, and color.

FEATURES:

  - ✅ Multiple simultaneous property animations
  - ✅ Coordinated transform combinations (position + scale + rotation)
  - ✅ Fade + move effects (opacity + position)
  - ✅ Color morphing with size changes (background + scale)
  - ✅ Complex interaction patterns with smooth transitions

-}


import Anim.Ports as Ports
import Anim.Properties.BackgroundColor as Color
import Anim.Properties.Opacity as Opacity
import Anim.Properties.Position as Position
import Anim.Properties.Rotate as Rotate
import Anim.Properties.Scale as Scale
import Anim.Timing.Easing as Easing exposing (Easing(..))
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


port stopElement : String -> Cmd msg


port positionUpdates : (Encode.Value -> msg) -> Sub msg


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
    {}


type Msg
    = StartComplexAnimation String
    | StartFadeMove String
    | StartSpinScale String
    | StartColorMorph String
    | StartFullTransform String
    | ResetAll
    | NoOp



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( {}
    , Cmd.none
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartComplexAnimation elementId ->
            -- Combine position + scale + rotation
            ( model
            , Ports.init
                |> Ports.duration 1000
                |> Ports.easing Easing.EaseInOut
                |> Position.for elementId
                |> Position.toXY 200 100
                |> Position.build
                |> Scale.for elementId
                |> Scale.toXY 1.5 1.9
                |> Scale.build
                |> Rotate.for elementId
                |> Rotate.to 90
                |> Rotate.build
                |> Ports.animate animateElement
            )

        StartFadeMove elementId ->
            -- Combine opacity + position
            ( model
            , Ports.init
                |> Ports.duration 1000
                |> Ports.easing Easing.EaseInOut
                |> Opacity.for elementId
                |> Opacity.to 0.3
                |> Opacity.build
                |> Position.for elementId
                |> Position.toXY 250 80
                |> Position.build
                |> Ports.animate animateElement
            )

        StartSpinScale elementId ->
            -- Combine rotation + scale + color
            ( model
            , Ports.init
                |> Ports.duration 1000
                |> Ports.easing Easing.EaseInOut
                |> Rotate.for elementId
                |> Rotate.to 180
                |> Rotate.build
                |> Scale.for elementId
                |> Scale.toXY 0.8 0.8
                |> Scale.build
                |> Color.for elementId
                |> Color.to (Color.Hex "#e74c3c")
                |> Color.build
                |> Ports.animate animateElement
            )

        StartColorMorph elementId ->
            -- Combine color + scale + opacity
            ( model
            , Ports.init
                |> Ports.duration 1000
                |> Ports.easing Easing.EaseInOut
                |> Color.for elementId
                |> Color.to (Color.Hsl { h = 142, s = 71, l = 45 })
                |> Color.build
                |> Scale.for elementId
                |> Scale.toXY 2.0 0.5
                |> Scale.build
                |> Opacity.for elementId
                |> Opacity.to 0.8
                |> Opacity.build
                |> Ports.animate animateElement
            )

        StartFullTransform elementId ->
            -- All properties at once!
            ( model
            , Ports.init
                |> Ports.duration 1000
                |> Ports.easing Easing.EaseInOut
                |> Position.for elementId
                |> Position.toXY 200 200
                |> Position.build
                |> Scale.for elementId
                |> Scale.toXY 1.3 1.3
                |> Scale.build
                |> Rotate.for elementId
                |> Rotate.to 270
                |> Rotate.build
                |> Opacity.for elementId
                |> Opacity.to 0.7
                |> Opacity.build
                |> Color.for elementId
                |> Color.to (Color.Hex "#9b59b6")
                |> Color.build
                |> Ports.animate animateElement
            )

        ResetAll ->
            ( model
            , Ports.init
                |> Ports.duration 800
                |> Ports.easing Easing.EaseOut
                |> Position.for "mixed-box"
                |> Position.toXY 0 0
                |> Position.build
                |> Scale.for "mixed-box"
                |> Scale.toXY 1.0 1.0
                |> Scale.build
                |> Rotate.for "mixed-box"
                |> Rotate.to 0
                |> Rotate.build
                |> Opacity.for "mixed-box"
                |> Opacity.to 1.0
                |> Opacity.build
                |> Color.for "mixed-box"
                |> Color.to (Color.Hex "#3498db")
                |> Color.build
                |> Ports.animate animateElement
            )

        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



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
    , UI.pageHeader "ElmUI & Ports Mixed Example"
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
        [ width (px 80)
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
