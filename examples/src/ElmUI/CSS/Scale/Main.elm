module ElmUI.CSS.Scale.Main exposing (main)

{-| Anim.CSS Scale Example using ElmUI - Size transformation animations

This example demonstrates smooth scaling animations using browser-native CSS transforms.
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
import Anim.CSS exposing (Model, init, animateScale, styleProperties, transitionStyles, onTransitionEnd)


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
    { animations : Anim.CSS.Model
    }


-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.CSS.init
      }
    , Cmd.none
    )


type Msg
    = ScaleTo String ScaleValue
    | ScaleReset String
    | PulseAnimation String
    | AnimationComplete


-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScaleTo elementId scale ->
            ( { model 
                | animations = animateScale elementId scale model.animations
              }
            , Cmd.none
            )

        ScaleReset elementId ->
            ( { model 
                | animations = animateScale elementId { x = 1.0, y = 1.0 } model.animations
              }
            , Cmd.none
            )

        PulseAnimation elementId ->
            ( { model 
                | animations = animateScale elementId { x = 1.2, y = 1.2 } model.animations
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( model, Cmd.none )


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


-- VIEW


view : Model -> Document Msg
view model =
    { title = "ElmUI - Anim.CSS Scale Example"
    , body = 
        [ Element.layout
            [ padding 20
            , Background.color Colors.backgroundLight
            , Font.family [ Font.typeface "Inter", Font.sansSerif ]
            ]
            (viewContent model)
        ]
    }


viewContent : Model -> Element Msg
viewContent model =
    column
        [ spacing 30
        , width fill
        , centerX
        , width (fill |> maximum 800)
        ]
        [ -- Back Button
          UI.backButton
        
        -- Header
        , UI.pageHeader "CSS Scale Animations"
        
        -- Controls in wrapped rows
        , column [ spacing 15, width fill ]
            [ paragraph [ Font.size 16, Font.color Colors.textMedium, centerX ] 
                [ text "Smooth size transformations using browser-native CSS transitions" ]
            
            , el [ centerX ] <|
                UI.htmlActionButtons
                    [ ( UI.Primary, ScaleTo "box1" { x = 1.5, y = 1.5 }, "Scale Up" )
                    , ( UI.Warning, ScaleTo "box1" { x = 0.7, y = 0.7 }, "Scale Down" )
                    , ( UI.Purple, ScaleReset "box1", "Reset Scale" )
                    ]
            
            , el [ centerX ] <|
                UI.htmlActionButtons
                    [ ( UI.Success, ScaleTo "box1" { x = 1.2, y = 1.2 }, "Scale 120%" )
                    , ( UI.Primary, ScaleTo "box1" { x = 1.8, y = 1.8 }, "Scale 180%" )
                    , ( UI.Purple, ScaleTo "box1" { x = 1.0, y = 1.0 }, "Reset to 100%" )
                    ]
                
            , el [ centerX ] <|
                UI.htmlActionButtons
                    [ ( UI.Warning, ScaleTo "box1" { x = 1.5, y = 0.5 }, "Wide & Short" )
                    , ( UI.Success, ScaleTo "box1" { x = 0.5, y = 1.5 }, "Tall & Narrow" )
                    , ( UI.Primary, ScaleTo "box1" { x = 1.0, y = 1.0 }, "Normal" )
                    ]
            ]        -- Controls for Box 2 - Non-uniform scaling
        , column [ spacing 15, width fill ]
            [ el [ Font.size 18, Font.bold, Font.color Colors.textDark ] (text "Non-Uniform Scaling")
            , UI.htmlActionButtons
                [ ( UI.Primary, ScaleTo "box2" { x = 2.0, y = 0.5 }, "Wide & Thin" )
                , ( UI.Success, ScaleTo "box2" { x = 0.5, y = 2.0 }, "Tall & Narrow" )
                , ( UI.Warning, ScaleTo "box2" { x = 1.0, y = 1.0 }, "Reset" )
                , ( UI.Purple, ScaleTo "box2" { x = 1.5, y = 1.5 }, "Proportional" )
                ]
            ]
            
        -- Controls for Box 3 - Pulse effects
        , column [ spacing 15, width fill ]
            [ el [ Font.size 18, Font.bold, Font.color Colors.textDark ] (text "Pulse Effects")
            , UI.htmlActionButtons
                [ ( UI.Success, PulseAnimation "box3", "Pulse" )
                , ( UI.Primary, ScaleReset "box3", "Reset" )
                ]
            ]
        
        -- Animation area with boxes
        , el
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
            (column
                [ spacing 40
                , width fill
                , height fill
                ]
                [ -- Box 1 - Uniform scaling
                  animatedBox "box1" "Uniform Scale" Colors.primary model
                
                -- Box 2 - Non-uniform scaling
                , animatedBox "box2" "Non-Uniform Scale" Colors.success model
                
                -- Box 3 - Pulse effects
                , animatedBox "box3" "Pulse Effects" Colors.warning model
                ]
            )
        ]


animatedBox : String -> String -> Element.Color -> Model -> Element Msg
animatedBox elementId label color model =
    el
        ([ width (px 120)
        , height (px 80)
        , Background.color color
        , Border.rounded 12
        , centerX
        , htmlAttribute (Html.Attributes.id elementId)
        , htmlAttribute (Html.Attributes.style "transform-origin" "center")
        ] 
        ++ (styleProperties elementId model.animations
            |> List.map (\(prop, value) -> htmlAttribute (Html.Attributes.style prop value)))
        ++ [ htmlAttribute (Html.Attributes.style "transition" 
                (transitionStyles elementId model.animations))
        , htmlAttribute (onTransitionEnd AnimationComplete)
        ])
        (column
            [ centerX
            , Element.centerY
            , spacing 5
            ]
            [ el 
                [ centerX
                , Font.color Colors.backgroundWhite
                , Font.bold
                , Font.size 14
                ] 
                (text label)
            ]
        )