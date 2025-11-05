module ElmUI.Sub.Scale.Main exposing (main)

{-| Anim.Sub Scale Example using ElmUI - Size transformation animations

This example demonstrates smooth scaling animations using browser-native Subscription-Based transforms.
Perfect for hover effects, emphasis animations, and dynamic sizing.

FEATURES:

  - ✅ Smooth scale up/down animations  
  - ✅ Hardware-accelerated transform scaling
  - ✅ Multiple scale factors and timing
  - ✅ Bounce and emphasis effects
  - ✅ Battery efficient browser-native transforms

-}

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Anim exposing (ScaleValue, defaultConfig)
import Anim.Sub exposing (Model, init, step, subscriptions, step, subscriptions, animateScale, styleProperties)


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


-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.Sub.init
      }
    , Cmd.none
    )


type Msg
    = ScaleUp
    | ScaleDown
    | ScaleReset
    | ScaleWide
    | ScaleTall
    | AnimationFrame Float


-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScaleUp ->
            ( { model 
                | animations = animateScale "box" { x = 1.5, y = 1.5 } model.animations
              }
            , Cmd.none
            )

        ScaleDown ->
            ( { model 
                | animations = animateScale "box" { x = 0.7, y = 0.7 } model.animations
              }
            , Cmd.none
            )

        ScaleReset ->
            ( { model 
                | animations = animateScale "box" { x = 1.0, y = 1.0 } model.animations
              }
            , Cmd.none
            )

        ScaleWide ->
            ( { model 
                | animations = animateScale "box" { x = 1.8, y = 0.6 } model.animations
              }
            , Cmd.none
            )

        ScaleTall ->
            ( { model 
                | animations = animateScale "box" { x = 0.6, y = 1.8 } model.animations
              }
            , Cmd.none
            )

        AnimationFrame deltaTime ->
            ( { model 
                | animations = step deltaTime model.animations
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
        "Anim.Sub Scale ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "Subscription-Based Scale Animations"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Smooth size transformations using browser-native Subscription-Based transitions")
    , -- Scale controls
      UI.htmlActionButtons
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
            |> List.map (\(prop, value) -> htmlAttribute (Html.Attributes.style prop value)))
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