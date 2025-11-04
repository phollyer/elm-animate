module ElmUI.CSS.Rotation.Main exposing (main)

{-| Anim.CSS Rotation Example using ElmUI - Rotation transformation animations

This example demonstrates smooth rotation animations using browser-native CSS transforms.
Perfect for loading spinners, interactive elements, and dynamic orientation changes.

FEATURES:

  - ✅ Smooth rotation animations in degrees
  - ✅ Hardware-accelerated transform rotations
  - ✅ Multiple rotation directions and speeds
  - ✅ Continuous spinning and specific angle targeting
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
import Anim exposing (RotationValue, defaultConfig)
import Anim.CSS exposing (Model, init, animateRotation, styleProperties, transitionStyles, onTransitionEnd)


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
    , spinCount : Int
    }


type Msg
    = RotateTo String Float
    | RotateBy String Float
    | StartSpin String
    | StopSpin String
    | AnimationComplete


-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RotateTo elementId rotation ->
            ( { model 
                | animations = animateRotation elementId rotation model.animations
              }
            , Cmd.none
            )

        RotateBy elementId degrees ->
            -- Add to current rotation (simplified - in real app we'd track current angle)
            ( { model 
                | animations = animateRotation elementId degrees model.animations
              }
            , Cmd.none
            )

        StartSpin elementId ->
            let
                newSpinCount = model.spinCount + 1
                spinDegrees = toFloat newSpinCount * 360
            in
            ( { model 
                | animations = animateRotation elementId spinDegrees model.animations
                , spinCount = newSpinCount
              }
            , Cmd.none
            )

        StopSpin elementId ->
            ( { model 
                | animations = animateRotation elementId 0 model.animations
                , spinCount = 0
              }
            , Cmd.none
            )

        AnimationComplete ->
            ( model, Cmd.none )


-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.CSS.init
      , spinCount = 0
      }
    , Cmd.none
    )


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


-- VIEW


view : Model -> Document Msg
view model =
    { title = "ElmUI - Anim.CSS Rotation Example"
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
        , UI.pageHeader "CSS Rotation Animations"
        
        -- Controls in wrapped rows
        , column [ spacing 15, width fill ]
            [ paragraph [ Font.size 16, Font.color Colors.textMedium, centerX ] 
                [ text "Smooth rotation transformations using hardware-accelerated CSS transforms" ]
            
            -- Precise angles section
            , column [ spacing 10, width fill ]
                [ el [ Font.size 18, Font.bold, Font.color Colors.textDark, centerX ] (text "Precise Angles")
                , el [ centerX ] <|
                    UI.htmlActionButtons
                        [ ( UI.Primary, RotateTo "box1" 0, "0°" )
                        , ( UI.Success, RotateTo "box1" 45, "45°" )
                        , ( UI.Warning, RotateTo "box1" 90, "90°" )
                        , ( UI.Purple, RotateTo "box1" 180, "180°" )
                        ]
                ]
            
            -- Incremental rotation section
            , column [ spacing 10, width fill ]
                [ el [ Font.size 18, Font.bold, Font.color Colors.textDark, centerX ] (text "Incremental Rotation")
                , el [ centerX ] <|
                    UI.htmlActionButtons
                        [ ( UI.Primary, RotateBy "box2" 30, "+30°" )
                        , ( UI.Success, RotateBy "box2" 90, "+90°" )
                        , ( UI.Warning, RotateBy "box2" -30, "-30°" )
                        , ( UI.Purple, RotateTo "box2" 0, "Reset" )
                        ]
                ]
                
            -- Continuous spinning section
            , column [ spacing 10, width fill ]
                [ el [ Font.size 18, Font.bold, Font.color Colors.textDark, centerX ] (text "Continuous Spinning")
                , el [ centerX ] <|
                    UI.htmlActionButtons
                        [ ( UI.Success, StartSpin "box3", "Spin 360°" )
                        , ( UI.Warning, StopSpin "box3", "Stop & Reset" )
                        ]
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
                [ -- Box 1 - Precise angles (square with arrow)
                  rotatingElement "box1" "→" "Precise Angles" Colors.primary model
                
                -- Box 2 - Incremental rotation (circle with dot)
                , rotatingElement "box2" "●" "Incremental" Colors.success model
                
                -- Box 3 - Continuous spinning (spinner)
                , rotatingElement "box3" "⟲" "Spinner" Colors.warning model
                ]
            )
        ]


rotatingElement : String -> String -> String -> Element.Color -> Model -> Element Msg
rotatingElement elementId symbol label color model =
    column
        [ spacing 10
        , centerX
        ]
        [ -- Label
          el 
            [ centerX
            , Font.color Colors.textMedium
            , Font.size 14
            ] 
            (text label)
        
        -- Rotating element
        , el
            ([ width (px 80)
            , height (px 80)
            , Background.color color
            , Border.rounded 40
            , centerX
            , htmlAttribute (Html.Attributes.id elementId)
            , htmlAttribute (Html.Attributes.style "transform-origin" "center")
            , htmlAttribute (Html.Attributes.style "display" "flex")
            , htmlAttribute (Html.Attributes.style "align-items" "center")
            , htmlAttribute (Html.Attributes.style "justify-content" "center")
            ] 
            ++ (styleProperties elementId model.animations
                |> List.map (\(prop, value) -> htmlAttribute (Html.Attributes.style prop value)))
            ++ [ htmlAttribute (Html.Attributes.style "transition" 
                    (transitionStyles elementId model.animations))
            , htmlAttribute (onTransitionEnd AnimationComplete)
            ])
            (el 
                [ centerX
                , Element.centerY
                , Font.color Colors.backgroundWhite
                , Font.bold
                , Font.size 24
                ] 
                (text symbol)
            )
        ]