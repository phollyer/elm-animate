module ElmUI.CSS.Color.Main exposing (main)

{-| Anim.CSS Color Example using ElmUI - Background color transition animations

This example demonstrates smooth color transitions using browser-native CSS animations.
Perfect for theme changes, state indicators, and dynamic color feedback.

FEATURES:

  - ✅ Smooth background color transitions
  - ✅ Hardware-accelerated color interpolation
  - ✅ Multiple color formats (hex, rgb, hsl)
  - ✅ Theme switching and state changes
  - ✅ Battery efficient browser-native transitions

-}

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Anim exposing (ColorValue(..), defaultConfig)
import Anim.CSS exposing (Model, init, animateBackgroundColor, styleProperties, transitionStyles, onTransitionEnd)


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
    = ChangeColorTo String ColorValue
    | CycleColors String
    | ResetColors String
    | AnimationComplete


-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeColorTo elementId color ->
            ( { model 
                | animations = animateBackgroundColor elementId color model.animations
              }
            , Cmd.none
            )

        CycleColors elementId ->
            -- Cycle through a series of colors
            let
                nextColor = case elementId of
                    "box1" -> Hex "#e74c3c"  -- Red
                    "box2" -> Rgb { r = 52, g = 152, b = 219 }  -- Blue
                    "box3" -> Hsl { h = 142, s = 71, l = 45 }   -- Green
                    _ -> Hex "#3498db"
            in
            ( { model 
                | animations = animateBackgroundColor elementId nextColor model.animations
              }
            , Cmd.none
            )

        ResetColors elementId ->
            ( { model 
                | animations = animateBackgroundColor elementId (Hex "#95a5a6") model.animations
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
    { title = "ElmUI - Anim.CSS Color Example"
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
        , UI.pageHeader "CSS Color Animations"
        
        -- Controls in wrapped rows
        , column [ spacing 15, width fill ]
            [ paragraph [ Font.size 16, Font.color Colors.textMedium, centerX ] 
                [ text "Smooth color transitions using browser-native CSS animations" ]
            
            -- Hex colors section
            , column [ spacing 10 ]
                [ el [ Font.size 16, Font.bold, Font.color Colors.textDark, centerX ] (text "Hex Colors")
                , el [ centerX ] <|
                    UI.htmlActionButtons
                        [ ( UI.Primary, ChangeColorTo "box1" (Hex "#3498db"), "Blue" )
                        , ( UI.Success, ChangeColorTo "box1" (Hex "#2ecc71"), "Green" )
                        , ( UI.Warning, ChangeColorTo "box1" (Hex "#f39c12"), "Orange" )
                        , ( UI.Purple, ChangeColorTo "box1" (Hex "#e74c3c"), "Red" )
                        ]
                ]
            
            -- RGB colors section
            , column [ spacing 10 ]
                [ el [ Font.size 16, Font.bold, Font.color Colors.textDark, centerX ] (text "RGB Colors")
                , el [ centerX ] <|
                    UI.htmlActionButtons
                        [ ( UI.Primary, ChangeColorTo "box2" (Rgb { r = 52, g = 152, b = 219 }), "RGB Blue" )
                        , ( UI.Success, ChangeColorTo "box2" (Rgb { r = 46, g = 204, b = 113 }), "RGB Green" )
                        , ( UI.Warning, ChangeColorTo "box2" (Rgb { r = 243, g = 156, b = 18 }), "RGB Orange" )
                        , ( UI.Purple, ChangeColorTo "box2" (Rgb { r = 155, g = 89, b = 182 }), "RGB Purple" )
                        ]
                ]
                
            -- HSL colors section
            , column [ spacing 10 ]
                [ el [ Font.size 16, Font.bold, Font.color Colors.textDark, centerX ] (text "HSL Colors")
                , el [ centerX ] <|
                    UI.htmlActionButtons
                        [ ( UI.Primary, ChangeColorTo "box3" (Hsl { h = 204, s = 70, l = 53 }), "HSL Blue" )
                        , ( UI.Success, ChangeColorTo "box3" (Hsl { h = 145, s = 63, l = 49 }), "HSL Green" )
                        , ( UI.Warning, ChangeColorTo "box3" (Hsl { h = 35, s = 84, l = 62 }), "HSL Orange" )
                        , ( UI.Purple, ChangeColorTo "box3" (Hsl { h = 6, s = 78, l = 57 }), "HSL Red" )
                        ]
                ]
                
            -- Reset section
            , column [ spacing 10 ]
                [ el [ Font.size 16, Font.bold, Font.color Colors.textDark, centerX ] (text "Reset All")
                , el [ centerX ] <|
                    UI.htmlActionButtons
                        [ ( UI.Primary, ResetColors "box1", "Reset to Default" )
                        ]
                ]
            ]        -- Animation area with boxes
        , el
            [ width (fill |> maximum 600)
            , height (px 350)
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
            (column
                [ spacing 30
                , padding 40
                , width fill
                , height fill
                ]
                [ -- Box 1 - Hex colors
                  colorBox "box1" "Hex Colors" model
                
                -- Box 2 - RGB colors
                , colorBox "box2" "RGB Colors" model
                
                -- Box 3 - HSL colors
                , colorBox "box3" "HSL Colors" model
                ]
            )
        ]


colorBox : String -> String -> Model -> Element Msg
colorBox elementId label model =
    el
        ([ width fill
        , height (px 70)
        , Border.rounded 12
        , paddingXY 20 0
        , htmlAttribute (Html.Attributes.id elementId)
        , htmlAttribute (Html.Attributes.style "background-color" "#95a5a6") -- Default gray
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
            , Font.size 18
            , htmlAttribute (Html.Attributes.style "text-shadow" "0 1px 3px rgba(0,0,0,0.5)")
            ] 
            (text label)
        )