port module ElmUI.WAAPI.Mixed.Main exposing (main)

{-| Anim.Engine.WAAPI Mixed Properties Example using ElmUI - Combined animation effects

This example demonstrates combining multiple animation properties in single animations.
Shows how to create rich, complex effects by mixing position, scale, rotation, opacity, and color.

FEATURES:

  - ✅ Multiple simultaneous property animations
  - ✅ Coordinated transform combinations (position + scale + rotation)
  - ✅ Fade + move effects (opacity + position)
  - ✅ Color morphing with size changes (background + scale)
  - ✅ Complex interaction patterns with smooth transitions

-}

import Anim.Color
import Anim.Easing as Easing exposing (Easing(..))
import Anim.Engine.WAAPI as WAAPI
import Anim.Property.BackgroundColor as Color
import Anim.Property.Opacity as Opacity
import Anim.Property.Position as Position
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
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


port animationUpdates : (Encode.Value -> msg) -> Sub msg


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
    { animState : WAAPI.AnimState
    }


type Msg
    = MoveScaleRotate String
    | FadeMove String
    | SpinScaleColor String
    | ColorSizeOpacity String
    | AllProperties String
    | ResetAll
    | ReceiveAnimationUpdate Encode.Value
    | NoOp



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        ( initialAnimState, initCmd ) =
            initAnim 0 WAAPI.init
    in
    ( { animState = initialAnimState }
    , initCmd
    )


initAnim : Int -> WAAPI.AnimState -> ( WAAPI.AnimState, Cmd msg )
initAnim duration animState =
    let
        ( newAnimState, encodedValue ) =
            animState
                |> WAAPI.builder
                |> WAAPI.duration duration
                |> WAAPI.easing Easing.EaseOut
                |> Position.for "mixed-box"
                |> Position.toXY 0 0
                |> Position.build
                |> Scale.for "mixed-box"
                |> Scale.toXYZ 1.0 1.0 1.0
                |> Scale.build
                |> Size.for "mixed-box"
                |> Size.toHW 80 80
                |> Size.build
                |> Rotate.for "mixed-box"
                |> Rotate.perspective "animation-container" 1000
                |> Rotate.toXYZ 0 0 0
                |> Rotate.build
                |> Opacity.for "mixed-box"
                |> Opacity.to 1.0
                |> Opacity.build
                |> Color.for "mixed-box"
                |> Color.to (Maybe.withDefault Anim.Color.blue (Anim.Color.fromHex "#3498db"))
                |> Color.build
                |> WAAPI.animate animState
    in
    ( newAnimState, animateElement encodedValue )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveAnimationUpdate jsonValue ->
            ( { model | animState = WAAPI.update jsonValue model.animState }, Cmd.none )

        MoveScaleRotate elementId ->
            let
                builder =
                    WAAPI.builder model.animState
                        |> WAAPI.duration 1000
                        |> WAAPI.easing Easing.EaseInOut
                        |> Position.for elementId
                        |> Position.toXY 200 100
                        |> Position.build
                        |> Scale.for elementId
                        |> Scale.toXY 1.5 1.9
                        |> Scale.build
                        |> Rotate.for elementId
                        |> Rotate.toZ 90
                        |> Rotate.build

                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState builder
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        FadeMove elementId ->
            let
                builder =
                    WAAPI.builder model.animState
                        |> WAAPI.duration 1000
                        |> WAAPI.easing Easing.EaseInOut
                        |> Opacity.for elementId
                        |> Opacity.to 0.3
                        |> Opacity.build
                        |> Position.for elementId
                        |> Position.toXY 250 80
                        |> Position.build

                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState builder
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        SpinScaleColor elementId ->
            let
                builder =
                    WAAPI.builder model.animState
                        |> WAAPI.duration 1000
                        |> WAAPI.easing Easing.EaseInOut
                        |> Rotate.for elementId
                        |> Rotate.toZ 180
                        |> Rotate.build
                        |> Scale.for elementId
                        |> Scale.toXY 0.8 0.8
                        |> Scale.build
                        |> Color.for elementId
                        |> Color.to (Maybe.withDefault Anim.Color.red (Anim.Color.fromHex "#e74c3c"))
                        |> Color.build

                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState builder
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        ColorSizeOpacity elementId ->
            let
                builder =
                    WAAPI.builder model.animState
                        |> WAAPI.duration 1000
                        |> WAAPI.easing Easing.EaseInOut
                        |> Color.for elementId
                        |> Color.to (Anim.Color.fromHsl { h = 142 / 360, s = 0.71, l = 0.45 })
                        |> Color.build
                        |> Size.for elementId
                        |> Size.toHW 60 150
                        |> Size.build
                        |> Opacity.for elementId
                        |> Opacity.to 0.8
                        |> Opacity.build

                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState builder
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        AllProperties elementId ->
            let
                builder =
                    WAAPI.builder model.animState
                        |> WAAPI.duration 1000
                        |> WAAPI.easing Easing.EaseInOut
                        |> Position.for elementId
                        |> Position.toXY 200 200
                        |> Position.build
                        |> Scale.for elementId
                        |> Scale.toXY 1.3 1.3
                        |> Scale.build
                        |> Size.for elementId
                        |> Size.toHW 150 60
                        |> Size.build
                        |> Rotate.for elementId
                        |> Rotate.toZ 270
                        |> Rotate.build
                        |> Opacity.for elementId
                        |> Opacity.to 0.7
                        |> Opacity.build
                        |> Color.for elementId
                        |> Color.to (Anim.Color.fromRgb { r = 155, g = 89, b = 182 })
                        |> Color.build

                ( newAnimState, encodedValue ) =
                    WAAPI.animate model.animState builder
            in
            ( { model | animState = newAnimState }, animateElement encodedValue )

        ResetAll ->
            let
                ( newAnimState, animCmd ) =
                    initAnim 800 model.animState
            in
            ( { model | animState = newAnimState }, animCmd )

        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    animationUpdates ReceiveAnimationUpdate



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.WAAPI Mixed Properties ElmUI Example"
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
        [ ( UI.Primary, MoveScaleRotate "mixed-box", "Move + Scale + Rotate" )
        , ( UI.Success, FadeMove "mixed-box", "Fade + Move" )
        , ( UI.Warning, SpinScaleColor "mixed-box", "Spin + Scale + Color" )
        , ( UI.Purple, ColorSizeOpacity "mixed-box", "Color + Size + Opacity" )
        , ( UI.Primary, AllProperties "mixed-box", "ALL Properties!" )
        , ( UI.Success, ResetAll, "Reset" )
        ]
    , -- Animation area
      el
        ([ htmlAttribute <|
            Html.Attributes.id "animation-container"
         , width (fill |> maximum 600)
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
            ++ List.map htmlAttribute (WAAPI.perspectiveWith 1000)
        )
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
