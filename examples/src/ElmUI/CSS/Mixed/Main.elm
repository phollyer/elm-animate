module ElmUI.CSS.Mixed.Main exposing (main)

{-| Anim.CSS Mixed Properties Example using ElmUI - Combined animation effects

This example demonstrates combining multiple CSS properties in single animations.
Shows how to create rich, complex effects by mixing position, scale, rotation, opacity, and color.

FEATURES:

  - ✅ Multiple simultaneous property animations
  - ✅ Coordinated transform combinations (position + scale + rotation)
  - ✅ Fade + move effects (opacity + position)
  - ✅ Color morphing with size changes (background + scale)
  - ✅ Complex interaction patterns with smooth transitions

-}

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Anim exposing (Position, ScaleValue, RotationValue, ColorValue(..), defaultConfig)
import Anim.CSS exposing (Model, init, animatePosition, animateScale, animateRotation, animateOpacity, animateBackgroundColor, styleProperties, transitionStyles, onTransitionEnd)


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
    , activeAnimation : String
    }


type Msg
    = StartComplexAnimation String
    | StartFadeMove String
    | StartSpinScale String  
    | StartColorMorph String
    | StartFullTransform String
    | ResetAll
    | AnimationComplete


-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartComplexAnimation elementId ->
            -- Combine position + scale + rotation
            let
                updatedModel1 = { model | animations = animatePosition elementId (Position 200 150) model.animations }
                updatedModel2 = { updatedModel1 | animations = animateScale elementId { x = 1.5, y = 1.5 } updatedModel1.animations }
                updatedModel3 = { updatedModel2 | animations = animateRotation elementId 45 updatedModel2.animations }
            in
            ( { updatedModel3 | activeAnimation = elementId }, Cmd.none )

        StartFadeMove elementId ->
            -- Combine opacity + position
            let
                updatedModel1 = { model | animations = animateOpacity elementId 0.3 model.animations }
                updatedModel2 = { updatedModel1 | animations = animatePosition elementId (Position 300 100) updatedModel1.animations }
            in
            ( { updatedModel2 | activeAnimation = elementId }, Cmd.none )

        StartSpinScale elementId ->
            -- Combine rotation + scale + color
            let
                updatedModel1 = { model | animations = animateRotation elementId 180 model.animations }
                updatedModel2 = { updatedModel1 | animations = animateScale elementId { x = 0.8, y = 0.8 } updatedModel1.animations }
                updatedModel3 = { updatedModel2 | animations = animateBackgroundColor elementId (Hex "#e74c3c") updatedModel2.animations }
            in
            ( { updatedModel3 | activeAnimation = elementId }, Cmd.none )

        StartColorMorph elementId ->
            -- Combine color + scale + opacity
            let
                updatedModel1 = { model | animations = animateBackgroundColor elementId (Hsl { h = 142, s = 71, l = 45 }) model.animations }
                updatedModel2 = { updatedModel1 | animations = animateScale elementId { x = 2.0, y = 0.5 } updatedModel1.animations }
                updatedModel3 = { updatedModel2 | animations = animateOpacity elementId 0.8 updatedModel2.animations }
            in
            ( { updatedModel3 | activeAnimation = elementId }, Cmd.none )

        StartFullTransform elementId ->
            -- All properties at once!
            let
                updatedModel1 = { model | animations = animatePosition elementId (Position 250 200) model.animations }
                updatedModel2 = { updatedModel1 | animations = animateScale elementId { x = 1.2, y = 1.2 } updatedModel1.animations }
                updatedModel3 = { updatedModel2 | animations = animateRotation elementId 90 updatedModel2.animations }
                updatedModel4 = { updatedModel3 | animations = animateOpacity elementId 0.7 updatedModel3.animations }
                updatedModel5 = { updatedModel4 | animations = animateBackgroundColor elementId (Hex "#9b59b6") updatedModel4.animations }
            in
            ( { updatedModel5 | activeAnimation = elementId }, Cmd.none )

        ResetAll ->
            let
                resetModel1 = { model | animations = animatePosition "mixed-box" (Position 0 0) model.animations }
                resetModel2 = { resetModel1 | animations = animateScale "mixed-box" { x = 1.0, y = 1.0 } resetModel1.animations }
                resetModel3 = { resetModel2 | animations = animateRotation "mixed-box" 0 resetModel2.animations }
                updatedModel4 = { resetModel3 | animations = animateOpacity "mixed-box" 1.0 resetModel3.animations }
                resetModel5 = { updatedModel4 | animations = animateBackgroundColor "mixed-box" (Hex "#3498db") updatedModel4.animations }
            in
            ( { resetModel5 | activeAnimation = "reset" }, Cmd.none )

        AnimationComplete ->
            ( { model | activeAnimation = "" }, Cmd.none )


-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animations = Anim.CSS.init
      , activeAnimation = ""
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
    { title = "ElmUI - Anim.CSS Mixed Properties Example"
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
        , width (fill |> maximum 900)
        ]
        [ -- Back Button
          UI.backButton
        
        -- Header
        , UI.pageHeader "CSS Mixed Property Animations"
        
        -- Animation controls in wrapped rows
        , column [ spacing 15, width fill ]
            [ paragraph [ Font.size 16, Font.color Colors.textMedium, centerX ] 
                [ text "Complex animations combining position, scale, rotation, opacity, and color simultaneously" ]
            
            -- Transform combo
            , el [ centerX ] <|
                UI.htmlActionButtons
                    [ ( UI.Primary, StartComplexAnimation "mixed-box", "Position + Scale + Rotation" )
                    ]
            
            -- Visibility effects
            , el [ centerX ] <|
                UI.htmlActionButtons
                    [ ( UI.Success, StartFadeMove "mixed-box", "Fade + Move" )
                    ]
            
            -- Dynamic style
            , el [ centerX ] <|
                UI.htmlActionButtons
                    [ ( UI.Warning, StartSpinScale "mixed-box", "Spin + Scale + Color" )
                    ]
            
            -- Color morphing
            , el [ centerX ] <|
                UI.htmlActionButtons
                    [ ( UI.Purple, StartColorMorph "mixed-box", "Color + Shape + Opacity" )
                    ]
            
            -- Ultimate transform
            , el [ centerX ] <|
                UI.htmlActionButtons
                    [ ( UI.Primary, StartFullTransform "mixed-box", "ALL Properties!" )
                    ]
            
            -- Reset
            , el [ centerX ] <|
                UI.htmlActionButtons
                    [ ( UI.Success, ResetAll, "Reset to Default" )
                    ]
            ]
        
        -- Status indicator
        , if model.activeAnimation /= "" then
            el 
                [ centerX
                , Font.color Colors.primary
                , Font.bold
                , Font.size 16
                ]
                (text ("Active: " ++ 
                    case model.activeAnimation of
                        "reset" -> "Resetting..."
                        _ -> "Animating " ++ model.activeAnimation
                ))
          else
            el 
                [ centerX
                , Font.color Colors.textMedium
                , Font.size 16
                ]
                (text "Ready for animation")
        
        -- Animation area
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
            ]
            (mixedAnimationBox model)
        ]


mixedAnimationBox : Model -> Element Msg
mixedAnimationBox model =
    el
        ([ width (px 80)
        , height (px 80)
        , Border.rounded 12
        , htmlAttribute (Html.Attributes.id "mixed-box")
        , htmlAttribute (Html.Attributes.style "position" "absolute")
        , htmlAttribute (Html.Attributes.style "left" "50px")
        , htmlAttribute (Html.Attributes.style "top" "50px")
        , htmlAttribute (Html.Attributes.style "background-color" "#3498db") -- Default blue
        , htmlAttribute (Html.Attributes.style "transform-origin" "center")
        , htmlAttribute (Html.Attributes.style "display" "flex")
        , htmlAttribute (Html.Attributes.style "align-items" "center")
        , htmlAttribute (Html.Attributes.style "justify-content" "center")
        ] 
        ++ (styleProperties "mixed-box" model.animations
            |> List.map (\(prop, value) -> htmlAttribute (Html.Attributes.style prop value)))
        ++ [ htmlAttribute (Html.Attributes.style "transition" 
                (transitionStyles "mixed-box" model.animations))
        , htmlAttribute (onTransitionEnd AnimationComplete)
        ])
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