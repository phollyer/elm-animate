module ElmUI.Sub.Mixed.Main exposing (main)

{-| Anim.Engine.Sub Mixed Properties Example using ElmUI - Combined animation effects

This example demonstrates combining multiple Subscription-Based properties in single animations.
Shows how to create rich, complex effects by mixing position, scale, rotation, opacity, and color.

FEATURES:

  - ✅ Multiple simultaneous property animations
  - ✅ Coordinated transform combinations (position + scale + rotation)
  - ✅ Fade + move effects (opacity + position)
  - ✅ Color morphing with size changes (background + scale)
  - ✅ Complex interaction patterns with smooth transitions

-}

import Anim.Extra.Color
import Easing as Easing exposing (Easing(..))
import Anim.Engine.Sub as Sub
import Anim.Property.BackgroundColor as Color
import Anim.Property.Opacity as Opacity
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Size as Size
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.Animations.Mixed as Mixed
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
            Sub.animate Sub.init
                (Translate.initXY "mixed-box" 0 0
                    >> Scale.initXY "mixed-box" 1.0 1.0
                    >> Size.initWH "mixed-box" 80 80
                    >> Rotate.initZ "mixed-box" 0
                    >> Opacity.init "mixed-box" 1.0
                    >> Color.init "mixed-box" (Anim.Extra.Color.fromHsl { h = 207 / 360, s = 0.9, l = 0.54 })
                )
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = MoveScaleRotate String
    | FadeMove String
    | ColorSizeOpacity String
    | SpinScaleColor String
    | AllProperties String
    | ResetAll
    | AnimationMsg Sub.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveScaleRotate elementId ->
            ( { model
                | animations =
                    Sub.animate model.animations (Mixed.moveScaleRotate elementId)
              }
            , Cmd.none
            )

        FadeMove elementId ->
            ( { model
                | animations =
                    Sub.animate model.animations (Mixed.fadeMove elementId)
              }
            , Cmd.none
            )

        SpinScaleColor elementId ->
            ( { model
                | animations =
                    Sub.animate model.animations (Mixed.spinScaleColor elementId)
              }
            , Cmd.none
            )

        ColorSizeOpacity elementId ->
            ( { model
                | animations =
                    Sub.animate model.animations (Mixed.colorSizeOpacity elementId)
              }
            , Cmd.none
            )

        AllProperties elementId ->
            ( { model
                | animations =
                    Sub.animate model.animations (Mixed.allProperties elementId)
              }
            , Cmd.none
            )

        ResetAll ->
            ( { model
                | animations =
                    Sub.animate model.animations (Mixed.resetAll "mixed-box")
              }
            , Cmd.none
            )

        AnimationMsg subMsg ->
            let
                ( newAnimations, _ ) =
                    Sub.update subMsg model.animations
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
        "Anim.Engine.Sub Mixed Properties ElmUI Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButton
    , UI.pageHeader "ElmUI & Subscription Mixed Example"
    , -- Description
      el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Combining multiple Subscription-Based properties in single animations for complex transformations")
    , -- Mixed property animation controls
      UI.wrappedButtonRow
        [ ( UI.Primary, MoveScaleRotate "mixed-box", "Move + Scale + Rotate" )
        , ( UI.Success, FadeMove "mixed-box", "Fade + Move" )
        , ( UI.Purple, ColorSizeOpacity "mixed-box", "Color + Size + Opacity" )
        , ( UI.Primary, AllProperties "mixed-box", "ALL Properties!" )
        , ( UI.Success, ResetAll, "Reset" )
        ]
    , -- Animation area
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
         , htmlAttribute (Html.Attributes.style "background-color" "#3498db") -- Default blue
         , htmlAttribute (Html.Attributes.style "transform-origin" "center")
         , htmlAttribute (Html.Attributes.style "display" "flex")
         , htmlAttribute (Html.Attributes.style "align-items" "center")
         , htmlAttribute (Html.Attributes.style "justify-content" "center")
         ]
            ++ List.map htmlAttribute (Sub.attributes "mixed-box" model.animations)
        )
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
