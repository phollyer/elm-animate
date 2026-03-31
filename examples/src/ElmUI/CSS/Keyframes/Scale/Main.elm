module ElmUI.CSS.Keyframes.Scale.Main exposing (main)

{-| Anim.Engine.CSS Scale Example using ElmUI - Element scale animations with CSS keyframes

This example demonstrates smooth scale animations using browser-native CSS keyframes.
Perfect for creating zoom effects and size transformations with precise timing control.

FEATURES:

  - ✅ Smooth scale animations using CSS keyframes (uniform and axis-specific)
  - ✅ Hardware-accelerated CSS transforms with fine-grained control
  - ✅ Multiple scale targets and reset functionality
  - ✅ Keyframes provide precise control over animation timing and composition

-}

import Anim.Extra.Easing as Easing exposing (Easing(..))
import Anim.Engine.CSS.Keyframe as CSS
import Anim.Property.Scale as Scale
import Browser exposing (Document)
import Common.Animations.Scale as Animations
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
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
    { animations : CSS.AnimState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = CSS.init [] }
    , Cmd.none
    )



-- UPDATE


elementId : String
elementId =
    "box"


type Msg
    = ScaleUp
    | ScaleDown
    | ScaleWide
    | ScaleTall
    | ScaleReset
    | AnimationComplete


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScaleUp ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.scaleUp elementId)
              }
            , Cmd.none
            )

        ScaleDown ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.scaleDown elementId)
              }
            , Cmd.none
            )

        ScaleWide ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.scaleWide elementId)
              }
            , Cmd.none
            )

        ScaleTall ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.scaleTall elementId)
              }
            , Cmd.none
            )

        ScaleReset ->
            ( { model
                | animations =
                    CSS.animate model.animations
                        (Animations.scaleReset elementId)
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( model
            , Cmd.none
            )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.CSS Scale Keyframes ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ Element.html (CSS.styleNodeFor elementId model.animations)
    , UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & CSS Keyframes Scale Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        , width (fill |> maximum 600)
        ]
        (paragraph []
            [ text "Smooth scale animations using browser-native CSS keyframes with precise timing control" ]
        )
    , -- Scale controls
      UI.wrappedButtonRow
        [ ( UI.Success, ScaleUp, "Scale Up" )
        , ( UI.Warning, ScaleDown, "Scale Down" )
        , ( UI.Primary, ScaleWide, "Scale Wide" )
        , ( UI.Purple, ScaleTall, "Scale Tall" )
        , ( UI.Success, ScaleReset, "Reset Scale" )
        ]
    , -- Animation area with boxes
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
            , centerY
            , width (px 200)
            , height (px 200)
            ]
            (scaledElement "Scale Demo" Colors.primary model)
        )
    ]


scaledElement : String -> Element.Color -> Model -> Element Msg
scaledElement label color model =
    el
        [ width (px 150)
        , height (px 150)
        , Background.color color
        , Border.rounded 12
        , centerX
        , htmlAttribute (Html.Attributes.id elementId)
        , htmlAttribute (Html.Attributes.style "transform-origin" "center")
        , htmlAttribute (Html.Attributes.style "display" "flex")
        , htmlAttribute (Html.Attributes.style "align-items" "center")
        , htmlAttribute (Html.Attributes.style "justify-content" "center")
        , htmlAttribute (CSS.keyframeAttribute elementId model.animations)
        ]
        (el
            [ centerX
            , centerY
            , Font.color Colors.backgroundWhite
            , Font.bold
            , Font.size 16
            ]
            (text label)
        )
