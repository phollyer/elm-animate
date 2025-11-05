port module ElmUI.Ports.Opacity.Main exposing (main)

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
import Anim.Ports exposing (Model, animate, encodeAnimationCommand, handlePropertyUpdateFromJson, init, sendAnimationCommand, styleProperties)
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
    , isVisible : Bool
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.Ports.init
      , isVisible = True
      }
    , Cmd.none
    )


type Msg
    = FadeIn
    | FadeOut
    | FadeToggle
    | AnimationComplete String
    | PositionUpdateReceived (Result Decode.Error Anim.Ports.PropertyUpdate)



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FadeIn ->
            let
                animation =
                    Anim.opacity "box" 1.0
                        |> Anim.opacityPerSecond 2.0
                        |> Anim.easeOut

                ( newModel, maybeCommand ) =
                    animate animation model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel, isVisible = True }
                    , sendAnimationCommand animateElement command
                    )

                Nothing ->
                    ( model, Cmd.none )

        FadeOut ->
            let
                animation =
                    Anim.opacity "box" 0.0
                        |> Anim.opacityPerSecond 2.0
                        |> Anim.easeIn

                ( newModel, maybeCommand ) =
                    animate animation model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel, isVisible = False }
                    , sendAnimationCommand animateElement command
                    )

                Nothing ->
                    ( model, Cmd.none )

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

                animation =
                    Anim.opacity "box" newOpacity
                        |> Anim.opacityPerSecond 1.5
                        |> Anim.easeInOut

                ( newModel, maybeCommand ) =
                    animate animation model.animations
            in
            case maybeCommand of
                Just command ->
                    ( { model | animations = newModel, isVisible = newVisible }
                    , sendAnimationCommand animateElement command
                    )

                Nothing ->
                    ( model, Cmd.none )

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
        "Anim.Ports Opacity ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "Ports Opacity Animations"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth fade-in and fade-out effects using JavaScript Web Animations API")
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
