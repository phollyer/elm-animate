module Concepts.Animate3D.Main exposing (main)

import Anim.Engine.CSS.Keyframes as Keyframes
import Anim.Extra.Easing exposing (Easing(..))
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
    cubeSize / 2


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
    = GotKeyframeEvent Keyframes.Event


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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
                    View3D.perspective 1000
                ]
                (viewCube model)
            )
    , viewExplanation
    ]


type alias FaceConfig =
    { id : String
    , label : String
    , background : Element.Color
    , borderColor : Element.Color
    , listenForEvents : Bool
    }


frontFace : FaceConfig
frontFace =
    { id = "front-face"
    , label = "FRONT"
    , background = Element.rgb255 52 152 219
    , borderColor = Element.rgb255 41 128 185
    , listenForEvents = True
    }


backFace : FaceConfig
backFace =
    { id = "back-face"
    , label = "BACK"
    , background = Element.rgb255 41 128 185
    , borderColor = Element.rgb255 33 97 140
    , listenForEvents = False
    }


rightFace : FaceConfig
rightFace =
    { id = "right-face"
    , label = "RIGHT"
    , background = Element.rgb255 231 76 60
    , borderColor = Element.rgb255 192 57 43
    , listenForEvents = False
    }


leftFace : FaceConfig
leftFace =
    { id = "left-face"
    , label = "LEFT"
    , background = Element.rgb255 230 126 34
    , borderColor = Element.rgb255 211 84 0
    , listenForEvents = False
    }


topFace : FaceConfig
topFace =
    { id = "top-face"
    , label = "TOP"
    , background = Element.rgb255 46 204 113
    , borderColor = Element.rgb255 39 174 96
    , listenForEvents = False
    }


bottomFace : FaceConfig
bottomFace =
    { id = "bottom-face"
    , label = "BOTTOM"
    , background = Element.rgb255 155 89 182
    , borderColor = Element.rgb255 142 68 173
    , listenForEvents = False
    }


viewCube : Model -> Element Msg
viewCube model =
    let
        shouldListenForSideEvents =
            model.state == Opening || model.state == Closing

        cubeStyles =
            Keyframes.styles "cube" model.animState
                |> List.map htmlAttribute

        cubeEvents =
            if model.state == RotatingOpen || model.state == RotatingClosed then
                Keyframes.events "cube" GotKeyframeEvent
                    |> List.map htmlAttribute

            else
                []
    in
    column
        ([ htmlAttribute <|
            Html.Attributes.id "cube"
         , width <|
            px (round cubeSize)
         , height <|
            px (round cubeSize)
         , htmlAttribute <|
            View3D.transformStyle View3D.Preserve3D
         , htmlAttribute <|
            View3D.perspectiveOrigin View3D.Center
         ]
            ++ cubeStyles
            ++ cubeEvents
        )
        [ viewFace model.animState (shouldListenForSideEvents && frontFace.listenForEvents) frontFace
        , viewFace model.animState False backFace
        , viewFace model.animState False rightFace
        , viewFace model.animState False leftFace
        , viewFace model.animState False topFace
        , viewFace model.animState False bottomFace
        ]


viewFace : Keyframes.AnimState -> Bool -> FaceConfig -> Element Msg
viewFace animState listenForEvents config =
    let
        baseAttributes =
            [ htmlAttribute <|
                Html.Attributes.id config.id
            , width <|
                px (round cubeSize)
            , height <|
                px (round cubeSize)
            , Background.color config.background
            , Border.width 2
            , Border.color config.borderColor
            , Font.color <|
                Element.rgb 1 1 1
            , Font.bold
            , Font.size 14
            , htmlAttribute <|
                Html.Attributes.style "position" "absolute"
            ]

        animAttributes =
            Keyframes.styles config.id animState
                |> List.map htmlAttribute

        eventAttributes =
            if listenForEvents then
                Keyframes.events config.id GotKeyframeEvent
                    |> List.map htmlAttribute

            else
                []
    in
    el
        (baseAttributes ++ animAttributes ++ eventAttributes)
        (el [ centerX, centerY ] (text config.label))


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
