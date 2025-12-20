port module ElmUI.Ports.Scale.Main exposing (main)

{-| Anim.Engine.CSS Scale Example using ElmUI - Size transformation animations

This example demonstrates smooth scaling animations using browser-native CSS transforms.
Perfect for hover effects, emphasis animations, and dynamic sizing.

FEATURES:

  - ✅ Smooth scale up/down animations
  - ✅ Hardware-accelerated transform scaling
  - ✅ Multiple scale factors and timing
  - ✅ Bounce and emphasis effects
  - ✅ Battery efficient browser-native transforms

-}


import Anim.Engine.WAAPI exposing (Model, animate, handlePropertyUpdateFromJson, init, sendAnimationCommand, styleProperties)
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
    { animations : Anim.Engine.WAAPI.Model
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.Engine.WAAPI.init
      }
    , Cmd.none
    )


type Msg
    = ScaleUp
    | ScaleDown
    | ScaleReset
    | ScaleWide
    | ScaleTall
    | AnimationComplete String
    | PositionUpdateReceived (Result Decode.Error Anim.Engine.WAAPI.PropertyUpdate)



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScaleUp ->
            let
                animation =
                    Anim.scale "box" { x = 1.3, y = 1.3 }
                        |> Anim.scalePerSecond 2.0
                        |> Anim.easeOut

                ( newModel, maybeCommand ) =
                    animate animation model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel }
                    , sendAnimationCommand animateElement command
                    )

                Nothing ->
                    ( model, Cmd.none )

        ScaleDown ->
            let
                animation =
                    Anim.scale "box" { x = 0.7, y = 0.7 }
                        |> Anim.scalePerSecond 3.0
                        |> Anim.easeIn

                ( newModel, maybeCommand ) =
                    animate animation model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel }
                    , sendAnimationCommand animateElement command
                    )

                Nothing ->
                    ( model, Cmd.none )

        ScaleReset ->
            let
                animation =
                    Anim.scale "box" { x = 1.0, y = 1.0 }
                        |> Anim.scaleDuration 800
                        |> Anim.easeInOut

                ( newModel, maybeCommand ) =
                    animate animation model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel }
                    , sendAnimationCommand animateElement command
                    )

                Nothing ->
                    ( model, Cmd.none )

        ScaleWide ->
            let
                animation =
                    Anim.scale "box" { x = 2.0, y = 0.8 }
                        |> Anim.scaleDuration 1200
                        |> Anim.easeOut

                ( newModel, maybeCommand ) =
                    animate animation model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel }
                    , sendAnimationCommand animateElement command
                    )

                Nothing ->
                    ( model, Cmd.none )

        ScaleTall ->
            let
                animation =
                    Anim.scale "box" { x = 0.6, y = 1.8 }
                        |> Anim.scalePerSecond 1.5
                        |> Anim.easeInOut

                ( newModel, maybeCommand ) =
                    animate animation model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel }
                    , sendAnimationCommand animateElement command
                    )

                Nothing ->
                    ( model, Cmd.none )

        AnimationComplete _ ->
            ( model, Cmd.none )

        PositionUpdateReceived result ->
            case result of
                Ok propertyUpdate ->
                    ( { model | animations = Anim.Engine.WAAPI.handlePropertyUpdate propertyUpdate model.animations }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )



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
        "Anim.Engine.WAAPI Scale ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Ports Scale Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth size transformations using browser-native CSS transitions")
    , -- Scale controls
      UI.wrappedButtonRow
        [ ( UI.Primary, ScaleUp, "Scale Up" )
        , ( UI.Warning, ScaleDown, "Scale Down" )
        , ( UI.Success, ScaleWide, "Wide" )
        , ( UI.Success, ScaleTall, "Tall" )
        , ( UI.Purple, ScaleReset, "Reset" )
        ]
    , -- Animation area with box
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
        , htmlAttribute (Html.Attributes.style "display" "flex")
        , htmlAttribute (Html.Attributes.style "flex-direction" "column")
        , htmlAttribute (Html.Attributes.style "align-items" "center")
        , htmlAttribute (Html.Attributes.style "justify-content" "space-around")
        , htmlAttribute (Html.Attributes.style "padding" "40px")
        ]
        (el
            [ centerX
            , Element.centerY
            , width (px 200)
            , height (px 200)
            ]
            (animatedBox "box" "Scale Demo" Colors.primary model)
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
         , htmlAttribute (Html.Attributes.style "transform-origin" "center")
         , htmlAttribute (Html.Attributes.style "display" "flex")
         , htmlAttribute (Html.Attributes.style "align-items" "center")
         , htmlAttribute (Html.Attributes.style "justify-content" "center")
         ]
            ++ (styleProperties elementId model.animations
                    |> List.map (\( prop, value ) -> htmlAttribute (Html.Attributes.style prop value))
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
