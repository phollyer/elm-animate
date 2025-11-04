module ElmUI.CSS.Opacity.Main exposing (main)

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

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Anim exposing (defaultConfig)
import Anim.CSS exposing (Model, init, animateOpacity, styleProperties, transitionStyles, onTransitionEnd)


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
    = FadeIn String
    | FadeOut String
    | FadeToggle String
    | AnimationComplete


-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FadeIn elementId ->
            ( { model 
                | animations = animateOpacity elementId 1.0 model.animations
              }
            , Cmd.none
            )

        FadeOut elementId ->
            ( { model 
                | animations = animateOpacity elementId 0.0 model.animations
              }
            , Cmd.none
            )

        FadeToggle elementId ->
            -- Simple toggle between visible and semi-transparent
            ( { model 
                | animations = animateOpacity elementId 0.5 model.animations
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
    { title = "ElmUI - Anim.CSS Opacity Example"
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
        , UI.pageHeader "CSS Opacity Animations"
        
        -- Controls in wrapped rows
        , column [ spacing 15, width fill ]
            [ paragraph [ Font.size 16, Font.color Colors.textMedium, centerX ] 
                [ text "Smooth fade-in and fade-out effects using browser-native CSS transitions" ]
            
            , el [ centerX ] <|
                UI.htmlActionButtons
                    [ ( UI.Success, FadeIn "box1", "Fade In Box 1" )
                    , ( UI.Warning, FadeOut "box1", "Fade Out Box 1" )
                    , ( UI.Primary, FadeToggle "box1", "Toggle Box 1" )
                    ]
            
            , el [ centerX ] <|
                UI.htmlActionButtons
                    [ ( UI.Success, FadeIn "box2", "Fade In Box 2" )
                    , ( UI.Warning, FadeOut "box2", "Fade Out Box 2" )
                    , ( UI.Primary, FadeToggle "box2", "Toggle Box 2" )
                    ]
                
            , el [ centerX ] <|
                UI.htmlActionButtons
                    [ ( UI.Success, FadeIn "box3", "Fade In Box 3" )
                    , ( UI.Warning, FadeOut "box3", "Fade Out Box 3" )
                    , ( UI.Primary, FadeToggle "box3", "Toggle Box 3" )
                    ]
            ]
        
        -- Animation area with boxes
        , el
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
            (column
                [ spacing 20
                , padding 40
                , width fill
                , height fill
                ]
                [ -- Box 1 - Fast fade
                  animatedBox "box1" "Fast Fade (0.3s)" Colors.primary model
                
                -- Box 2 - Medium fade  
                , animatedBox "box2" "Medium Fade (0.6s)" Colors.success model
                
                -- Box 3 - Slow fade
                , animatedBox "box3" "Slow Fade (1.2s)" Colors.warning model
                ]
            )
        ]


animatedBox : String -> String -> Element.Color -> Model -> Element Msg
animatedBox elementId label color model =
    el
        ([ width fill
        , height (px 60)
        , Background.color color
        , Border.rounded 8
        , paddingXY 20 0
        , htmlAttribute (Html.Attributes.id elementId)
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
            ] 
            (text label)
        )