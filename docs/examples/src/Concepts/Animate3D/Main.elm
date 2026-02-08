module Concepts.Animate3D.Main exposing (main)

import Anim.Engine.CSS.Keyframes as Keyframes
import Anim.Extra.Easing as Easing exposing (Easing(..))
import Anim.Extra.View3D as View3D
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, html, htmlAttribute, maximum, padding, px, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
import Html.Attributes



-- MAIN


main : Program { window : { width : Int } } Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type State
    = Opening
    | Closing
    | RotatingOpen
    | RotatingClosed


type alias Model =
    { animState : Keyframes.AnimState
    , state : State
    , animAreaSize : { width : Int, height : Int }
    }


cubeSize : Float
cubeSize =
    100


depth : Float
depth =
    -- +2 for border thickness
    cubeSize / 2 + 2


init : { window : { width : Int } } -> ( Model, Cmd Msg )
init flags =
    let
        animState =
            Keyframes.init
                [ Translate.initZ "cube" 200
                , Translate.initZ "front-face" depth
                , Translate.initZ "back-face" (depth * -1)
                , Translate.initX "right-face" depth
                , Translate.initX "left-face" (-1 * depth)
                , Translate.initY "top-face" (-1 * depth)
                , Translate.initY "bottom-face" depth
                , Rotate.initY "back-face" 180
                , Rotate.initY "right-face" 90
                , Rotate.initY "left-face" -90
                , Rotate.initX "top-face" 90
                , Rotate.initX "bottom-face" -90
                ]

        state =
            Opening
    in
    ( { animState =
            Keyframes.animate animState <|
                animate state
      , state = state
      , animAreaSize =
            { width = min 500 (flags.window.width - 40)
            , height = 350
            }
      }
    , Cmd.none
    )


animate : State -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
animate state =
    case state of
        Opening ->
            moveSidesOut

        Closing ->
            moveSidesIn

        RotatingOpen ->
            rotateCubeClockwise

        RotatingClosed ->
            rotateCubeAntiClockwise


rotateCube : (Rotate.Builder -> Rotate.Builder) -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
rotateCube targetFunc =
    Rotate.for "cube"
        >> targetFunc
        >> Rotate.easing BackInOut
        >> Rotate.duration 4000
        >> Rotate.build


rotateCubeClockwise : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
rotateCubeClockwise =
    rotateCube <|
        Rotate.to 360


rotateCubeAntiClockwise : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
rotateCubeAntiClockwise =
    rotateCube <|
        Rotate.to (-1 * 360)


moveSidesOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveSidesOut =
    moveFrontFaceOut
        >> moveBackFaceOut
        >> moveRightFaceOut
        >> moveLeftFaceOut
        >> moveTopFaceOut
        >> moveBottomFaceOut


moveSidesIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveSidesIn =
    moveFrontFaceIn
        >> moveBackFaceIn
        >> moveRightFaceIn
        >> moveLeftFaceIn
        >> moveTopFaceIn
        >> moveBottomFaceIn


moveFace : String -> (Translate.Builder -> Translate.Builder) -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveFace faceId targetFunc =
    Translate.for faceId
        >> targetFunc
        >> Translate.duration 1000
        >> Translate.easing BounceOut
        >> Translate.build


moveFrontFaceOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveFrontFaceOut =
    moveFace "front-face" <|
        Translate.toZ (depth + 50)


moveFrontFaceIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveFrontFaceIn =
    moveFace "front-face" <|
        Translate.toZ depth


moveBackFaceOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveBackFaceOut =
    moveFace "back-face" <|
        Translate.toZ (-1 * depth - 50)


moveBackFaceIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveBackFaceIn =
    moveFace "back-face" <|
        Translate.toZ (-1 * depth)


moveRightFaceOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveRightFaceOut =
    moveFace "right-face" <|
        Translate.toX (depth + 50)


moveRightFaceIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveRightFaceIn =
    moveFace "right-face" <|
        Translate.toX depth


moveLeftFaceOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveLeftFaceOut =
    moveFace "left-face" <|
        Translate.toX (-1 * depth - 50)


moveLeftFaceIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveLeftFaceIn =
    moveFace "left-face" <|
        Translate.toX (-1 * depth)


moveTopFaceOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveTopFaceOut =
    moveFace "top-face" <|
        Translate.toY (-1 * depth - 50)


moveTopFaceIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveTopFaceIn =
    moveFace "top-face" <|
        Translate.toY (-1 * depth)


moveBottomFaceOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveBottomFaceOut =
    moveFace "bottom-face" <|
        Translate.toY (depth + 50)


moveBottomFaceIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveBottomFaceIn =
    moveFace "bottom-face" <|
        Translate.toY depth



-- UPDATE


type Msg
    = NoOp
    | GotKeyframeEvent Keyframes.Event


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotKeyframeEvent event ->
            let
                newModel =
                    { model | animState = Keyframes.handleEvent event model.animState }
            in
            case event of
                Keyframes.Ended "cube" ->
                    let
                        newState =
                            case newModel.state of
                                RotatingOpen ->
                                    Closing

                                RotatingClosed ->
                                    Opening

                                _ ->
                                    newModel.state
                    in
                    ( { newModel
                        | state = newState
                        , animState =
                            Keyframes.animate newModel.animState <|
                                animate newState
                      }
                    , Cmd.none
                    )

                Keyframes.Ended "front-face" ->
                    let
                        newState =
                            case newModel.state of
                                Opening ->
                                    RotatingOpen

                                Closing ->
                                    RotatingClosed

                                _ ->
                                    newModel.state
                    in
                    ( { newModel
                        | state = newState
                        , animState =
                            Keyframes.animate newModel.animState <|
                                animate newState
                      }
                    , Cmd.none
                    )

                _ ->
                    ( newModel, Cmd.none )



-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Anim.Engine.Keyframes.Keyframes 3D Example"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.pageHeader "Keyframes 3D Example"
    , html <|
        Keyframes.styleNode model.animState
    , el
        [ centerX
        , padding 20
        ]
      <|
        el
            [ width <|
                px model.animAreaSize.width
            , height <|
                px model.animAreaSize.height
            , Background.color Colors.backgroundWhite
            , Border.rounded 12
            , Border.shadow
                { offset = ( 0, 4 )
                , size = 0
                , blur = 8
                , color = Element.rgba 0 0 0 0.1
                }
            ]
            (el
                [ centerX
                , centerY
                , htmlAttribute <|
                    Html.Attributes.style "position" "relative"
                , htmlAttribute <|
                    View3D.perspective 1000
                ]
                (viewCube model)
            )
    , viewExplanation
    ]



-- +2 for border thickness


viewCube : Model -> Element Msg
viewCube model =
    Element.html <|
        Html.div
            ([ Html.Attributes.id "cube"
             , Html.Attributes.style "width" (String.fromFloat cubeSize ++ "px")
             , Html.Attributes.style "height" (String.fromFloat cubeSize ++ "px")
             , Html.Attributes.style "position" "relative"
             , View3D.transformStyle View3D.Preserve3D
             , View3D.perspectiveOrigin View3D.Center
             ]
                ++ Keyframes.styles "cube" model.animState
                ++ (if model.state == RotatingOpen || model.state == RotatingClosed then
                        Keyframes.events "cube" GotKeyframeEvent

                    else
                        []
                   )
            )
            [ -- Front face
              Html.div
                ([ Html.Attributes.id "front-face"
                 , Html.Attributes.style "position" "absolute"
                 , Html.Attributes.style "width" (String.fromFloat cubeSize ++ "px")
                 , Html.Attributes.style "height" (String.fromFloat cubeSize ++ "px")
                 , Html.Attributes.style "background" "#3498db"
                 , Html.Attributes.style "border" "2px solid #2980b9"
                 , Html.Attributes.style "display" "flex"
                 , Html.Attributes.style "align-items" "center"
                 , Html.Attributes.style "justify-content" "center"
                 , Html.Attributes.style "color" "white"
                 , Html.Attributes.style "font-weight" "bold"
                 , Html.Attributes.style "font-size" "14px"
                 ]
                    ++ Keyframes.styles "front-face" model.animState
                    ++ (if model.state == Opening || model.state == Closing then
                            Keyframes.events "front-face" GotKeyframeEvent

                        else
                            []
                       )
                )
                [ Html.text "FRONT" ]
            , -- Back face
              Html.div
                ([ Html.Attributes.id "back-face"
                 , Html.Attributes.style "position" "absolute"
                 , Html.Attributes.style "width" (String.fromFloat cubeSize ++ "px")
                 , Html.Attributes.style "height" (String.fromFloat cubeSize ++ "px")
                 , Html.Attributes.style "background" "#2980b9"
                 , Html.Attributes.style "border" "2px solid #21618c"
                 , Html.Attributes.style "display" "flex"
                 , Html.Attributes.style "align-items" "center"
                 , Html.Attributes.style "justify-content" "center"
                 , Html.Attributes.style "color" "white"
                 , Html.Attributes.style "font-weight" "bold"
                 , Html.Attributes.style "font-size" "14px"
                 ]
                    ++ Keyframes.styles "back-face" model.animState
                )
                [ Html.text "BACK" ]
            , -- Right face
              Html.div
                ([ Html.Attributes.id "right-face"
                 , Html.Attributes.style "position" "absolute"
                 , Html.Attributes.style "width" (String.fromFloat cubeSize ++ "px")
                 , Html.Attributes.style "height" (String.fromFloat cubeSize ++ "px")
                 , Html.Attributes.style "background" "#e74c3c"
                 , Html.Attributes.style "border" "2px solid #c0392b"
                 , Html.Attributes.style "display" "flex"
                 , Html.Attributes.style "align-items" "center"
                 , Html.Attributes.style "justify-content" "center"
                 , Html.Attributes.style "color" "white"
                 , Html.Attributes.style "font-weight" "bold"
                 , Html.Attributes.style "font-size" "14px"
                 ]
                    ++ Keyframes.styles "right-face" model.animState
                )
                [ Html.text "RIGHT" ]
            , -- Left face
              Html.div
                ([ Html.Attributes.id "left-face"
                 , Html.Attributes.style "position" "absolute"
                 , Html.Attributes.style "width" (String.fromFloat cubeSize ++ "px")
                 , Html.Attributes.style "height" (String.fromFloat cubeSize ++ "px")
                 , Html.Attributes.style "background" "#e67e22"
                 , Html.Attributes.style "border" "2px solid #d35400"
                 , Html.Attributes.style "display" "flex"
                 , Html.Attributes.style "align-items" "center"
                 , Html.Attributes.style "justify-content" "center"
                 , Html.Attributes.style "color" "white"
                 , Html.Attributes.style "font-weight" "bold"
                 , Html.Attributes.style "font-size" "14px"
                 ]
                    ++ Keyframes.styles "left-face" model.animState
                )
                [ Html.text "LEFT" ]
            , -- Top face
              Html.div
                ([ Html.Attributes.id "top-face"
                 , Html.Attributes.style "position" "absolute"
                 , Html.Attributes.style "width" (String.fromFloat cubeSize ++ "px")
                 , Html.Attributes.style "height" (String.fromFloat cubeSize ++ "px")
                 , Html.Attributes.style "background" "#2ecc71"
                 , Html.Attributes.style "border" "2px solid #27ae60"
                 , Html.Attributes.style "display" "flex"
                 , Html.Attributes.style "align-items" "center"
                 , Html.Attributes.style "justify-content" "center"
                 , Html.Attributes.style "color" "white"
                 , Html.Attributes.style "font-weight" "bold"
                 , Html.Attributes.style "font-size" "14px"
                 , Html.Attributes.style "transform" ("rotateX(90deg) translateZ(" ++ String.fromFloat depth ++ "px)")
                 ]
                    ++ Keyframes.styles "top-face" model.animState
                )
                [ Html.text "TOP" ]
            , -- Bottom face
              Html.div
                ([ Html.Attributes.id "bottom-face"
                 , Html.Attributes.style "position" "absolute"
                 , Html.Attributes.style "width" (String.fromFloat cubeSize ++ "px")
                 , Html.Attributes.style "height" (String.fromFloat cubeSize ++ "px")
                 , Html.Attributes.style "background" "#9b59b6"
                 , Html.Attributes.style "border" "2px solid #8e44ad"
                 , Html.Attributes.style "display" "flex"
                 , Html.Attributes.style "align-items" "center"
                 , Html.Attributes.style "justify-content" "center"
                 , Html.Attributes.style "color" "white"
                 , Html.Attributes.style "font-weight" "bold"
                 , Html.Attributes.style "font-size" "14px"
                 ]
                    ++ Keyframes.styles "bottom-face" model.animState
                )
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
