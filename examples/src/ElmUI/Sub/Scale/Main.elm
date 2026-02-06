module ElmUI.Sub.Scale.Main exposing (main)

{-| Anim.Engine.Sub Scale Example using ElmUI - Size transformation animations

This example demonstrates smooth scaling animations using browser-native Subscription-Based transforms.
Perfect for hover effects, emphasis animations, and dynamic sizing.

FEATURES:

  - ✅ Smooth scale up/down animations
  - ✅ Hardware-accelerated transform scaling
  - ✅ Multiple scale factors and timing
  - ✅ Bounce and emphasis effects
  - ✅ Battery efficient browser-native transforms

-}

import Anim.Extra.Easing as Easing exposing (Easing(..))
import Anim.Engine.Sub as Sub
import Anim.Property.Scale as Scale
import Browser exposing (Document)
import Browser.Events
import Common.Animations.Scale as Animations
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
    { animations : Sub.AnimState }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations =
            Sub.animate Sub.init (Scale.initXY "box" 1.0 1.0)
      }
    , Cmd.none
    )


type Msg
    = ScaleUp
    | ScaleDown
    | ScaleReset
    | ScaleWide
    | ScaleTall
    | AnimationMsg Sub.AnimMsg



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScaleUp ->
            ( { model
                | animations =
                    Sub.animate model.animations (Animations.scaleUp "box")
              }
            , Cmd.none
            )

        ScaleDown ->
            ( { model
                | animations =
                    Sub.animate model.animations (Animations.scaleDown "box")
              }
            , Cmd.none
            )

        ScaleReset ->
            ( { model
                | animations =
                    Sub.animate model.animations (Animations.scaleReset "box")
              }
            , Cmd.none
            )

        ScaleWide ->
            ( { model
                | animations =
                    Sub.animate model.animations (Animations.scaleWide "box")
              }
            , Cmd.none
            )

        ScaleTall ->
            ( { model
                | animations =
                    Sub.animate model.animations (Animations.scaleTall "box")
              }
            , Cmd.none
            )

        AnimationMsg animMsg ->
            let
                ( newAnimations, _ ) =
                    Sub.update animMsg model.animations
            in
            ( { model | animations = newAnimations }
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
        "Anim.Engine.Sub Scale ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Subscription Scale Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth size transformations using browser-native Subscription-Based transitions")
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
            ++ (Sub.htmlAttributes elementId model.animations
                    |> List.map htmlAttribute
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
