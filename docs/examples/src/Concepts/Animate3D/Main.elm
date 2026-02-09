module Concepts.Animate3D.Main exposing (main)

import Anim.Engine.CSS.Keyframes as Keyframes
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Extra.View3D as View3D
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, column, el, fill, height, html, htmlAttribute, maximum, padding, paddingEach, px, spacing, text, width)
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
    -- --8<-- [start:initializeProperties]
    let
        initialAnimState =
            Keyframes.init
                [ Translate.initZ "cube" 200

                -- Position each face in 3D space
                , Translate.initZ "front-face" depth
                , Translate.initZ "back-face" (depth * -1)
                , Translate.initX "right-face" depth
                , Translate.initX "left-face" (-1 * depth)
                , Translate.initY "top-face" (-1 * depth)
                , Translate.initY "bottom-face" depth

                -- Rotate each face to build the cube
                -- Front face is not rotated due to facing forward by default
                , Rotate.initY "back-face" 180
                , Rotate.initY "right-face" 90
                , Rotate.initY "left-face" -90
                , Rotate.initX "top-face" 90
                , Rotate.initX "bottom-face" -90
                ]

        state =
            Opening
    in
    -- --8<-- [end:initializeProperties]
    -- --8<-- [start:startAnimation]
    ( { animState =
            Keyframes.animate initialAnimState <|
                animate state

      -- --8<-- [end:startAnimation]
      , state = state
      , animAreaSize =
            { width = min 500 (flags.window.width - 40)
            , height = 350
            }
      }
    , Cmd.none
    )



-- --8<-- [start:animationSelector]


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



-- --8<-- [end:animationSelector]
-- --8<-- [start:animationFunctions]


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



-- --8<-- [end:animationFunctions]
-- UPDATE


type Msg
    = GotKeyframeEvent Keyframes.Event



-- --8<-- [start:stateMachine]


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



-- --8<-- [end:stateMachine]
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
    , viewExplanation
    , el
        [ width <|
            px model.animAreaSize.width
        , height <|
            px model.animAreaSize.height
        , centerX
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



-- --8<-- [start:viewCube]


viewCube : Model -> Element Msg
viewCube model =
    let
        shouldListenForSideEvents =
            model.state == Opening || model.state == Closing

        cubeStyles =
            Keyframes.attributes "cube" model.animState
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



-- --8<-- [end:viewCube]
-- --8<-- [start:viewFace]


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
            Keyframes.attributes config.id animState
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



-- --8<-- [end:viewFace]


viewExplanation : Element Msg
viewExplanation =
    el
        [ centerX
        , paddingEach
            { top = 20
            , right = 0
            , left = 0
            , bottom = 0
            }
        ]
    <|
        column
            [ width (fill |> maximum 700)
            , centerX
            , padding 20
            , spacing 10
            , Background.color (Element.rgb 0.95 0.97 1)
            , Border.rounded 8
            , Font.size 14
            ]
            [ el [ Font.bold, Font.size 16 ] (text "3D Cube Animation")
            , Element.paragraph []
                [ text "This example demonstrates a 3D cube built with six positioned faces "
                , text "that cycles through: expand sides → rotate → close sides → rotate back."
                ]
            ]
