module ElmUI.CSS.Keyframe.Cube.Main exposing (main)

{-| Anim.Engine.CSS Keyframe 3D Cube Example using ElmUI - True 3D rotation with depth

This example demonstrates how to create a proper 3D cube with 6 faces that can be rotated
in 3D space without the "disappearing back side" problem of flat 2D elements.

FEATURES:

  - ✅ True 3D cube with 6 visible faces
  - ✅ Smooth 3D rotations on all axes
  - ✅ Proper perspective and transform-style setup
  - ✅ Multiple rotation combinations
  - ✅ Visual depth with different colored faces

KEY TECHNIQUE:

The cube is built with 6 positioned faces, each transformed to form a cube:

  - Front/Back: translateZ(±depth/2)
  - Left/Right: rotateY(±90°) + translateZ(depth/2)
  - Top/Bottom: rotateX(±90°) + translateZ(depth/2)

-}

import Anim.Extra.Easing as Easing
import Anim.Engine.CSS.Keyframe as CSS
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.Animations.Cube as Cube
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, px, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
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
    { animState : CSS.AnimState
    , perspectiveValue : Float
    , zPosition : Float
    , rotateX : Float
    , rotateY : Float
    , rotateZ : Float
    }


type Msg
    = SetPerspective Float
    | SetZPosition Float
    | SetRotateX Float
    | SetRotateY Float
    | SetRotateZ Float


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            CSS.animate (CSS.init [])
                (Translate.initZ "cube" 0
                    >> Rotate.initXYZ "cube" 0 0 0
                )
      , perspectiveValue = 1000
      , zPosition = 0
      , rotateX = 0
      , rotateY = 0
      , rotateZ = 0
      }
    , Cmd.none
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetPerspective value ->
            ( { model | perspectiveValue = value }, Cmd.none )

        SetZPosition value ->
            let
                newAnimState =
                    CSS.animate model.animState
                        (Cube.setCubeTransform "cube" value model.rotateX model.rotateY model.rotateZ)
            in
            ( { model | animState = newAnimState, zPosition = value }, Cmd.none )

        SetRotateX value ->
            let
                newAnimState =
                    CSS.animate model.animState
                        (Cube.setCubeTransform "cube" model.zPosition value model.rotateY model.rotateZ)
            in
            ( { model | animState = newAnimState, rotateX = value }, Cmd.none )

        SetRotateY value ->
            let
                newAnimState =
                    CSS.animate model.animState
                        (Cube.setCubeTransform "cube" model.zPosition model.rotateX value model.rotateZ)
            in
            ( { model | animState = newAnimState, rotateY = value }, Cmd.none )

        SetRotateZ value ->
            let
                newAnimState =
                    CSS.animate model.animState
                        (Cube.setCubeTransform "cube" model.zPosition model.rotateX model.rotateY value)
            in
            ( { model | animState = newAnimState, rotateZ = value }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.CSS Keyframe 3D Cube Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.backButtonWithPath "../../../index.html"
    , UI.pageHeader "ElmUI & CSS Keyframe 3D Cube Demo"
    , el
        [ Font.size 16
        , Font.color Colors.textMedium
        , centerX
        ]
        (text "Interactive 3D cube with live slider controls")
    , -- Control sliders
      column
        [ width (fill |> maximum 600)
        , centerX
        , spacing 20
        , padding 20
        , Background.color (Element.rgb 0.95 0.95 0.97)
        , Border.rounded 8
        ]
        [ viewSlider "Perspective" model.perspectiveValue "px" 500 1500 10 SetPerspective
        , viewSlider "Z Position" model.zPosition "px" -50 300 10 SetZPosition
        , viewSlider "Rotate X" model.rotateX "°" 0 360 1 SetRotateX
        , viewSlider "Rotate Y" model.rotateY "°" 0 360 1 SetRotateY
        , viewSlider "Rotate Z" model.rotateZ "°" 0 360 1 SetRotateZ
        ]
    , el
        ([ htmlAttribute <| Html.Attributes.id "animation-container"
         , width (fill |> maximum 600)
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
         , htmlAttribute (Html.Attributes.style "align-items" "center")
         , htmlAttribute (Html.Attributes.style "justify-content" "center")
         ]
            ++ List.map htmlAttribute (CSS.perspectiveWith model.perspectiveValue)
        )
        (viewCube model)
    , viewExplanation
    ]


viewSlider : String -> Float -> String -> Float -> Float -> Float -> (Float -> Msg) -> Element Msg
viewSlider label value unit minVal maxVal stepVal toMsg =
    column
        [ width fill
        , spacing 8
        ]
        [ el
            [ Font.size 14
            , Font.color Colors.textDark
            , Font.semiBold
            ]
            (text (label ++ ": " ++ String.fromInt (round value) ++ unit))
        , Input.slider
            [ height (px 30)
            , width fill
            , Element.behindContent
                (el
                    [ width fill
                    , height (px 4)
                    , Element.centerY
                    , Background.color (Element.rgb 0.7 0.7 0.7)
                    , Border.rounded 2
                    ]
                    Element.none
                )
            ]
            { onChange = toMsg
            , label = Input.labelHidden label
            , min = minVal
            , max = maxVal
            , step = Just stepVal
            , value = value
            , thumb = Input.defaultThumb
            }
        ]


viewCube : Model -> Element Msg
viewCube model =
    let
        cubeSize =
            100

        depth =
            cubeSize // 2 + 2

        -- +2 for border thickness
    in
    Element.html <|
        Html.div
            ([ Html.Attributes.id "cube"
             , Html.Attributes.style "width" (String.fromInt cubeSize ++ "px")
             , Html.Attributes.style "height" (String.fromInt cubeSize ++ "px")
             , Html.Attributes.style "position" "relative"
             , Html.Attributes.style "transform-style" "preserve-3d"
             , Html.Attributes.style "transform-origin" "center"
             ]
                ++ CSS.attributes "cube" model.animState
            )
            [ -- Front face
              Html.div
                [ Html.Attributes.style "position" "absolute"
                , Html.Attributes.style "width" (String.fromInt cubeSize ++ "px")
                , Html.Attributes.style "height" (String.fromInt cubeSize ++ "px")
                , Html.Attributes.style "background" "#3498db"
                , Html.Attributes.style "border" "2px solid #2980b9"
                , Html.Attributes.style "display" "flex"
                , Html.Attributes.style "align-items" "center"
                , Html.Attributes.style "justify-content" "center"
                , Html.Attributes.style "color" "white"
                , Html.Attributes.style "font-weight" "bold"
                , Html.Attributes.style "font-size" "14px"
                , Html.Attributes.style "transform" ("translateZ(" ++ String.fromInt depth ++ "px)")
                ]
                [ Html.text "FRONT" ]
            , -- Back face
              Html.div
                [ Html.Attributes.style "position" "absolute"
                , Html.Attributes.style "width" (String.fromInt cubeSize ++ "px")
                , Html.Attributes.style "height" (String.fromInt cubeSize ++ "px")
                , Html.Attributes.style "background" "#2980b9"
                , Html.Attributes.style "border" "2px solid #21618c"
                , Html.Attributes.style "display" "flex"
                , Html.Attributes.style "align-items" "center"
                , Html.Attributes.style "justify-content" "center"
                , Html.Attributes.style "color" "white"
                , Html.Attributes.style "font-weight" "bold"
                , Html.Attributes.style "font-size" "14px"
                , Html.Attributes.style "transform" ("translateZ(-" ++ String.fromInt depth ++ "px) rotateY(180deg)")
                ]
                [ Html.text "BACK" ]
            , -- Right face
              Html.div
                [ Html.Attributes.style "position" "absolute"
                , Html.Attributes.style "width" (String.fromInt cubeSize ++ "px")
                , Html.Attributes.style "height" (String.fromInt cubeSize ++ "px")
                , Html.Attributes.style "background" "#e74c3c"
                , Html.Attributes.style "border" "2px solid #c0392b"
                , Html.Attributes.style "display" "flex"
                , Html.Attributes.style "align-items" "center"
                , Html.Attributes.style "justify-content" "center"
                , Html.Attributes.style "color" "white"
                , Html.Attributes.style "font-weight" "bold"
                , Html.Attributes.style "font-size" "14px"
                , Html.Attributes.style "transform" ("rotateY(90deg) translateZ(" ++ String.fromInt depth ++ "px)")
                ]
                [ Html.text "RIGHT" ]
            , -- Left face
              Html.div
                [ Html.Attributes.style "position" "absolute"
                , Html.Attributes.style "width" (String.fromInt cubeSize ++ "px")
                , Html.Attributes.style "height" (String.fromInt cubeSize ++ "px")
                , Html.Attributes.style "background" "#e67e22"
                , Html.Attributes.style "border" "2px solid #d35400"
                , Html.Attributes.style "display" "flex"
                , Html.Attributes.style "align-items" "center"
                , Html.Attributes.style "justify-content" "center"
                , Html.Attributes.style "color" "white"
                , Html.Attributes.style "font-weight" "bold"
                , Html.Attributes.style "font-size" "14px"
                , Html.Attributes.style "transform" ("rotateY(-90deg) translateZ(" ++ String.fromInt depth ++ "px)")
                ]
                [ Html.text "LEFT" ]
            , -- Top face
              Html.div
                [ Html.Attributes.style "position" "absolute"
                , Html.Attributes.style "width" (String.fromInt cubeSize ++ "px")
                , Html.Attributes.style "height" (String.fromInt cubeSize ++ "px")
                , Html.Attributes.style "background" "#2ecc71"
                , Html.Attributes.style "border" "2px solid #27ae60"
                , Html.Attributes.style "display" "flex"
                , Html.Attributes.style "align-items" "center"
                , Html.Attributes.style "justify-content" "center"
                , Html.Attributes.style "color" "white"
                , Html.Attributes.style "font-weight" "bold"
                , Html.Attributes.style "font-size" "14px"
                , Html.Attributes.style "transform" ("rotateX(90deg) translateZ(" ++ String.fromInt depth ++ "px)")
                ]
                [ Html.text "TOP" ]
            , -- Bottom face
              Html.div
                [ Html.Attributes.style "position" "absolute"
                , Html.Attributes.style "width" (String.fromInt cubeSize ++ "px")
                , Html.Attributes.style "height" (String.fromInt cubeSize ++ "px")
                , Html.Attributes.style "background" "#9b59b6"
                , Html.Attributes.style "border" "2px solid #8e44ad"
                , Html.Attributes.style "display" "flex"
                , Html.Attributes.style "align-items" "center"
                , Html.Attributes.style "justify-content" "center"
                , Html.Attributes.style "color" "white"
                , Html.Attributes.style "font-weight" "bold"
                , Html.Attributes.style "font-size" "14px"
                , Html.Attributes.style "transform" ("rotateX(-90deg) translateZ(" ++ String.fromInt depth ++ "px)")
                ]
                [ Html.text "BOTTOM" ]
            ]


viewExplanation : Element Msg
viewExplanation =
    column
        [ width (fill |> maximum 700)
        , centerX
        , padding 20
        , spacing 15
        , Background.color (Element.rgb 1 0.95 0.8)
        , Border.rounded 8
        , Font.size 14
        ]
        [ el [ Font.bold, Font.size 16 ] (text "How the 3D Cube Works")
        , Element.paragraph []
            [ text "Each face is a flat div positioned in 3D space using transforms:" ]
        , column [ spacing 5, padding 10 ]
            [ text "• Front/Back: translateZ(±50px)"
            , text "• Left/Right: rotateY(±90°) + translateZ(50px)"
            , text "• Top/Bottom: rotateX(±90°) + translateZ(50px)"
            ]
        , Element.paragraph []
            [ text "The entire cube rotates as one unit when you animate the container div. "
            ]
        , el [ Font.bold, Font.size 16, Element.paddingEach { top = 10, bottom = 0, left = 0, right = 0 } ] (text "The Near Clipping Plane")
        , Element.paragraph []
            [ text "The perspective origin acts as an "
            , el [ Font.bold ] (text "opaque clipping plane")
            , text ". Any part of the cube that passes behind this plane (negative Z direction) becomes invisible."
            ]
        , Element.paragraph []
            [ text "This is why the cube disappears when Z Position is too small. The cube is 100px deep (±50px from center), so at Z=50px, the back face reaches Z=0px. Any closer (Z<50px) causes parts to go behind the plane and disappear."
            ]
        , Element.paragraph []
            [ text "When rotating or scaling, parts can also disappear if they move behind the plane."
            ]
        , Element.paragraph []
            [ text "The safe rule: "
            , el [ Font.bold ] (text "Z Position ≥ (object depth / 2)")
            , text " ensures all faces stay visible during any rotation. For this 100px cube, that means Z ≥ 50px."
            ]
        , el [ Font.bold, Font.size 16, Element.paddingEach { top = 10, bottom = 0, left = 0, right = 0 } ] (text "Perspective and Depth")
        , Element.paragraph []
            [ text "The perspective value controls how pronounced the 3D effect appears. Lower values create a stronger perspective, making depth changes more dramatic."
            ]
        , Element.paragraph []
            [ text "Experiment with the sliders to see how perspective, Z position, and rotations affect the cube's appearance! "
            , text "For maximum zoom effect, set Perspective low (closer to the viewer) and Z Position high (closer to the viewer)."
            ]
        ]
