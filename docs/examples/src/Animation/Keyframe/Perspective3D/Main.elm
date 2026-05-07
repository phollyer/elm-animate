module Animation.Keyframe.Perspective3D.Main exposing (main)

import Anim.Builder exposing (ForDocumentTimeline, ForKeyframeEngine)
import Anim.Engine.Keyframe as Keyframe
import Anim.Extra.View3D as View3D
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Easing exposing (Easing(..))
import Html exposing (Html, div, text)
import Html.Attributes exposing (id, style)



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
-- Perspective container configuration


type alias PerspectiveContainerConfig =
    { id : String
    , groupName : String
    }


perspectiveContainer : PerspectiveContainerConfig
perspectiveContainer =
    { id = "perspective-container"
    , groupName = "perspectiveContainerAnim"
    }


vanishingPointDot : { id : String, groupName : String }
vanishingPointDot =
    { id = "vanishing-point-dot"
    , groupName = "vanishingPointDotAnim"
    }



-- Cube configuration


type alias CubeConfig =
    { id : String
    , groupName : String
    , size : Int
    }


cube : CubeConfig
cube =
    { id = "cube"
    , groupName = "cubeAnim"
    , size = 100
    }


depth : Float
depth =
    toFloat cube.size / 2



-- Face configuration


type alias TextConfig =
    { id : String
    , groupName : String
    , label : String
    , color : String
    }


type alias FaceConfig =
    { id : String
    , groupName : String
    , label : String
    , background : String
    , borderColor : String
    , text : TextConfig
    }


frontFace : FaceConfig
frontFace =
    { id = "front-face"
    , groupName = "frontFaceAnim"
    , label = "FRONT"
    , background = "rgb(52, 152, 219)"
    , borderColor = "rgb(41, 128, 185)"
    , text =
        { id = "front-face-text"
        , groupName = "frontFaceTextAnim"
        , label = "FRONT"
        , color = "rgb(0,0 ,0   )"
        }
    }


backFace : FaceConfig
backFace =
    { id = "back-face"
    , groupName = "backFaceAnim"
    , label = "BACK"
    , background = "rgb(41, 128, 185)"
    , borderColor = "rgb(33, 97, 140)"
    , text =
        { id = "back-face-text"
        , groupName = "backFaceTextAnim"
        , label = "BACK"
        , color = "rgb(0,0 ,0   )"
        }
    }


rightFace : FaceConfig
rightFace =
    { id = "right-face"
    , groupName = "rightFaceAnim"
    , label = "RIGHT"
    , background = "rgb(231, 76, 60)"
    , borderColor = "rgb(192, 57, 43)"
    , text =
        { id = "right-face-text"
        , groupName = "rightFaceTextAnim"
        , label = "RIGHT"
        , color = "rgb(0,0 ,0   )"
        }
    }


leftFace : FaceConfig
leftFace =
    { id = "left-face"
    , groupName = "leftFaceAnim"
    , label = "LEFT"
    , background = "rgb(230, 126, 34)"
    , borderColor = "rgb(211, 84, 0)"
    , text =
        { id = "left-face-text"
        , groupName = "leftFaceTextAnim"
        , label = "LEFT"
        , color = "rgb(0,0 ,0   )"
        }
    }


topFace : FaceConfig
topFace =
    { id = "top-face"
    , groupName = "topFaceAnim"
    , label = "TOP"
    , background = "rgb(46, 204, 113)"
    , borderColor = "rgb(39, 174, 96)"
    , text =
        { id = "top-face-text"
        , groupName = "topFaceTextAnim"
        , label = "TOP"
        , color = "rgb(0,0 ,0   )"
        }
    }


bottomFace : FaceConfig
bottomFace =
    { id = "bottom-face"
    , groupName = "bottomFaceAnim"
    , label = "BOTTOM"
    , background = "rgb(155, 89, 182)"
    , borderColor = "rgb(142, 68, 173)"
    , text =
        { id = "bottom-face-text"
        , groupName = "bottomFaceTextAnim"
        , label = "BOTTOM"
        , color = "rgb(0,0 ,0   )"
        }
    }


type State
    = Opening
    | Closing
    | RotatingOpen
    | RotatingClosed


type PerspectiveStep
    = MoveToTopRight
    | MoveToBottomRight
    | MoveToBottomLeft
    | MoveToTopLeft


type alias Model =
    { animState : Keyframe.AnimState
    , state : State
    , perspectiveStep : PerspectiveStep
    , animAreaSize : { width : Int, height : Int }
    }



-- INIT


init : { window : { width : Int } } -> ( Model, Cmd Msg )
init flags =
    let
        animAreaWidth =
            min 500 (flags.window.width - 40)

        animAreaHeight =
            350

        initialAnimState =
            Keyframe.init
                [ -- Initialize the perspective origin at the top-left corner (0%, 0%)
                  -- It will travel around the corners in sync with the cube animation:
                  -- (0,0) -> (100,0) -> (100,100) -> (0,100) -> (0,0)
                  PerspectiveOrigin.initPercent perspectiveContainer.groupName 0 0

                -- Bring the cube forward on the Z axis
                -- so that it doesn't get clipped by the
                -- z=0 clipping plane when we expand the
                -- sides and rotate
                , Translate.initZ cube.groupName 200

                -- Position each face in 3D space along the axis it faces
                -- Front/Back faces move on Z (forward/backward)
                -- Left/Right faces move on X (sideways)
                -- Top/Bottom faces move on Y (up/down)
                , Translate.initZ frontFace.groupName depth
                , Translate.initZ backFace.groupName (depth * -1)
                , Translate.initX rightFace.groupName depth
                , Translate.initX leftFace.groupName (-1 * depth)
                , Translate.initY topFace.groupName (-1 * depth)
                , Translate.initY bottomFace.groupName depth

                -- Rotate each face into position to build the cube
                -- Front face is not rotated due to facing forward by default
                , Rotate.initY backFace.groupName 180
                , Rotate.initY rightFace.groupName 90
                , Rotate.initY leftFace.groupName -90
                , Rotate.initX topFace.groupName 90
                , Rotate.initX bottomFace.groupName -90

                -- The text labels all start on the same plane as their faces
                -- at z=0, which is the default starting position for elements, so we don't need
                -- to initialize them
                ]

        state =
            Opening
    in
    ( { animState =
            Keyframe.animate initialAnimState <|
                selectAnimation state
                    >> perspectiveAnimation { width = animAreaWidth, height = animAreaHeight } MoveToTopRight
      , state = state
      , perspectiveStep = MoveToBottomRight
      , animAreaSize =
            { width = animAreaWidth
            , height = animAreaHeight
            }
      }
    , Cmd.none
    )


selectAnimation : State -> Keyframe.AnimBuilder -> Keyframe.AnimBuilder
selectAnimation state =
    case state of
        Opening ->
            moveSidesOut
                >> moveTextsOut

        Closing ->
            moveSidesIn
                >> moveTextsIn

        RotatingOpen ->
            rotateCubeClockwise

        RotatingClosed ->
            rotateCubeAntiClockwise


perspectiveStepDuration : Int
perspectiveStepDuration =
    3000


nextPerspectiveStep : PerspectiveStep -> PerspectiveStep
nextPerspectiveStep step =
    case step of
        MoveToTopRight ->
            MoveToBottomRight

        MoveToBottomRight ->
            MoveToBottomLeft

        MoveToBottomLeft ->
            MoveToTopLeft

        MoveToTopLeft ->
            MoveToTopRight


perspectiveAnimation : { width : Int, height : Int } -> PerspectiveStep -> Keyframe.AnimBuilder -> Keyframe.AnimBuilder
perspectiveAnimation areaSize step =
    case step of
        MoveToTopRight ->
            movePerspectiveOrigin 100 0 perspectiveStepDuration areaSize

        MoveToBottomRight ->
            movePerspectiveOrigin 100 100 perspectiveStepDuration areaSize

        MoveToBottomLeft ->
            movePerspectiveOrigin 0 100 perspectiveStepDuration areaSize

        MoveToTopLeft ->
            movePerspectiveOrigin 0 0 perspectiveStepDuration areaSize



-- ANIMATIONS
--
-- PERSPECTIVE ORIGIN - animates the vanishing point around the corners of the
-- container in sync with the cube animation


movePerspectiveOrigin : Float -> Float -> Int -> { width : Int, height : Int } -> Keyframe.AnimBuilder -> Keyframe.AnimBuilder
movePerspectiveOrigin x y ms areaSize =
    PerspectiveOrigin.for perspectiveContainer.groupName
        >> PerspectiveOrigin.percent
        >> PerspectiveOrigin.toXY x y
        >> PerspectiveOrigin.duration ms
        >> PerspectiveOrigin.easing Linear
        >> PerspectiveOrigin.build
        >> Translate.for vanishingPointDot.groupName
        >> Translate.toX (x / 100 * toFloat areaSize.width)
        >> Translate.toY (y / 100 * toFloat areaSize.height)
        >> Translate.duration ms
        >> Translate.easing Linear
        >> Translate.build



-- CUBE - 1st level of 3D animation
--
-- We only rotate the cube, not individual faces, they maintain their
-- position in 3D space because we use `View3D.transformStyle View3D.Preserve3D`
-- on the cube container


rotateCube : Float -> Keyframe.AnimBuilder -> Keyframe.AnimBuilder
rotateCube to =
    Rotate.for cube.groupName
        >> Rotate.toXYZ to to to
        >> Rotate.easing BackInOut
        >> Rotate.duration 8000
        >> Rotate.build


rotateCubeClockwise : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
rotateCubeClockwise =
    rotateCube 360


rotateCubeAntiClockwise : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
rotateCubeAntiClockwise =
    rotateCube 0



-- SIDES - 2nd level of 3D animation
--
-- For the side movement animations, we build complex animations out of
-- smaller pieces.


moveSidesOut : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveSidesOut =
    moveFrontFaceOut
        >> moveBackFaceOut
        >> moveRightFaceOut
        >> moveLeftFaceOut
        >> moveTopFaceOut
        >> moveBottomFaceOut


moveSidesIn : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveSidesIn =
    moveFrontFaceIn
        >> moveBackFaceIn
        >> moveRightFaceIn
        >> moveLeftFaceIn
        >> moveTopFaceIn
        >> moveBottomFaceIn


sharedTiming : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
sharedTiming =
    Keyframe.duration 1000
        >> Keyframe.easing CircInOut


moveFace : FaceConfig -> (Translate.Builder (ForDocumentTimeline ForKeyframeEngine) -> Translate.Builder (ForDocumentTimeline ForKeyframeEngine)) -> Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveFace { groupName } moveToBuilder =
    sharedTiming
        >> Translate.for groupName
        >> moveToBuilder
        >> Translate.build



-- Each face moves along the axis it faces by a `moveAmount` number
-- of pixels when the cube expands, and moves back to it's original position
-- when the cube closes.
--
-- Front/Back faces move on Z (forward/backward)
-- Left/Right faces move on X (sideways)
-- Top/Bottom faces move on Y (up/down)


moveAmount : Float
moveAmount =
    50


moveFrontFaceOut : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveFrontFaceOut =
    moveFace frontFace <|
        Translate.toZ (depth + moveAmount)


moveFrontFaceIn : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveFrontFaceIn =
    moveFace frontFace <|
        Translate.toZ depth


moveBackFaceOut : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveBackFaceOut =
    moveFace backFace <|
        Translate.toZ (-1 * depth - moveAmount)


moveBackFaceIn : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveBackFaceIn =
    moveFace backFace <|
        Translate.toZ (-1 * depth)


moveRightFaceOut : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveRightFaceOut =
    moveFace rightFace <|
        Translate.toX (depth + moveAmount)


moveRightFaceIn : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveRightFaceIn =
    moveFace rightFace <|
        Translate.toX depth


moveLeftFaceOut : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveLeftFaceOut =
    moveFace leftFace <|
        Translate.toX (-1 * depth - moveAmount)


moveLeftFaceIn : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveLeftFaceIn =
    moveFace leftFace <|
        Translate.toX (-1 * depth)


moveTopFaceOut : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveTopFaceOut =
    moveFace topFace <|
        Translate.toY (-1 * depth - moveAmount)


moveTopFaceIn : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveTopFaceIn =
    moveFace topFace <|
        Translate.toY (-1 * depth)


moveBottomFaceOut : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveBottomFaceOut =
    moveFace bottomFace <|
        Translate.toY (depth + moveAmount)


moveBottomFaceIn : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveBottomFaceIn =
    moveFace bottomFace <|
        Translate.toY depth



-- TEXT - 3rd level of 3D animation
--
-- Text moves forward (Z+20) and rotates (to Z=360deg) when sides expand,
-- and then moves back (to Z=0) and rotates back (to Z=0deg) when sides close


textMoveAmount : Float
textMoveAmount =
    20


moveText : TextConfig -> Float -> Float -> Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveText { groupName } toZ toRotate =
    sharedTiming
        >> Translate.for groupName
        >> Translate.toZ toZ
        >> Translate.build
        >> Rotate.for groupName
        >> Rotate.toZ toRotate
        >> Rotate.build


moveTextsOut : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveTextsOut =
    moveText frontFace.text textMoveAmount 360
        >> moveText backFace.text textMoveAmount 360
        >> moveText rightFace.text textMoveAmount 360
        >> moveText leftFace.text textMoveAmount 360
        >> moveText topFace.text textMoveAmount 360
        >> moveText bottomFace.text textMoveAmount 360


moveTextsIn : Keyframe.AnimBuilder -> Keyframe.AnimBuilder
moveTextsIn =
    moveText frontFace.text 0 0
        >> moveText backFace.text 0 0
        >> moveText rightFace.text 0 0
        >> moveText leftFace.text 0 0
        >> moveText topFace.text 0 0
        >> moveText bottomFace.text 0 0



-- UPDATE


type Msg
    = NoOp
    | GotKeyframeMsg Keyframe.AnimMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotKeyframeMsg animMsg ->
            let
                ( animState, animEvent ) =
                    Keyframe.update animMsg model.animState
            in
            ( handleEvent animEvent { model | animState = animState }
            , Cmd.none
            )


handleEvent : Keyframe.AnimEvent -> Model -> Model
handleEvent animEvent model =
    case animEvent of
        Keyframe.Ended _ _ "cubeAnim" ->
            cubeRotationEnded model

        Keyframe.Ended _ _ "frontFaceAnim" ->
            sidesMovementEnded model

        Keyframe.Ended _ _ "vanishingPointDotAnim" ->
            perspectiveStepEnded model

        _ ->
            model


cubeRotationEnded : Model -> Model
cubeRotationEnded model =
    case model.state of
        RotatingOpen ->
            stateChanged Closing model

        RotatingClosed ->
            stateChanged Opening model

        _ ->
            model


sidesMovementEnded : Model -> Model
sidesMovementEnded model =
    case model.state of
        Opening ->
            stateChanged RotatingOpen model

        Closing ->
            stateChanged RotatingClosed model

        _ ->
            model


stateChanged : State -> Model -> Model
stateChanged state model =
    { model
        | state = state
        , animState =
            Keyframe.animate model.animState <|
                selectAnimation state
    }


perspectiveStepEnded : Model -> Model
perspectiveStepEnded model =
    { model
        | animState =
            Keyframe.animate model.animState <|
                perspectiveAnimation model.animAreaSize model.perspectiveStep
        , perspectiveStep =
            nextPerspectiveStep model.perspectiveStep
    }



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Keyframe Engine - 3D Perspective Origin Example"
    , body =
        [ Keyframe.styleNode model.animState
        , div
            [ style "min-height" "100vh"
            , style "background" "linear-gradient(to bottom, rgb(226, 232, 240), rgb(248, 250, 252))"
            ]
            [ div
                [ style "font-family" "system-ui, sans-serif"
                , style "padding" "20px 40px"
                , style "max-width" "700px"
                , style "margin" "0 auto"
                ]
                [ viewAnimationArea model ]
            ]
        ]
    }


viewAnimationArea : Model -> Html Msg
viewAnimationArea model =
    div
        (Keyframe.attributes perspectiveContainer.groupName model.animState
            ++ Keyframe.events GotKeyframeMsg
            ++ [ id perspectiveContainer.id

               -- Perspective container - perspective-origin is animated by the engine
               , View3D.perspective 1000

               --
               -- Workaround for Chrome on macOS GPU compositing issues with 3D transforms.
               -- Setting opacity: 0.99 forces a new compositing layer, which prevents
               -- the colored rectangle artifacts that can appear during complex 3D animations.
               -- It's not perfect, some flickering can still occur.
               , View3D.opacityHack
               , style "position" "relative"
               , style "display" "flex"
               , style "justify-content" "center"
               , style "align-items" "center"
               , style "width" (String.fromInt model.animAreaSize.width ++ "px")
               , style "height" (String.fromInt model.animAreaSize.height ++ "px")
               , style "margin" "0 auto"
               , style "background-color" "#ffffff"
               , style "border-radius" "12px"
               , style "box-shadow" "0 4px 8px rgba(0,0,0,0.1)"
               ]
        )
        [ viewVanishingPoint model.animState
        , viewCube model
        ]


viewCube : Model -> Html Msg
viewCube model =
    let
        cubeAttrs =
            Keyframe.attributes cube.groupName model.animState

        cubeEvents =
            Keyframe.events GotKeyframeMsg
    in
    div
        (cubeAttrs
            ++ cubeEvents
            ++ [ View3D.transformStyle View3D.Preserve3D
               , id cube.id
               , style "width" (String.fromInt cube.size ++ "px")
               , style "height" (String.fromInt cube.size ++ "px")
               , style "position" "relative"
               ]
        )
        [ viewFace model.animState frontFace
        , viewFace model.animState backFace
        , viewFace model.animState rightFace
        , viewFace model.animState leftFace
        , viewFace model.animState topFace
        , viewFace model.animState bottomFace
        ]


viewVanishingPoint : Keyframe.AnimState -> Html Msg
viewVanishingPoint animState =
    div
        (Keyframe.attributes vanishingPointDot.groupName animState
            ++ [ style "position" "absolute"
               , style "top" "0"
               , style "left" "0"
               , style "width" "0"
               , style "height" "0"
               , style "overflow" "visible"
               , style "pointer-events" "none"
               ]
        )
        [ div
            [ style "position" "absolute"
            , style "width" "1px"
            , style "height" "40px"
            , style "top" "-20px"
            , style "left" "-0.5px"
            , style "background" "rgba(80, 80, 80, 0.4)"
            ]
            []
        , div
            [ style "position" "absolute"
            , style "height" "1px"
            , style "width" "40px"
            , style "left" "-20px"
            , style "top" "-0.5px"
            , style "background" "rgba(80, 80, 80, 0.4)"
            ]
            []
        , div
            [ style "position" "absolute"
            , style "width" "10px"
            , style "height" "10px"
            , style "border-radius" "50%"
            , style "background" "rgba(40, 40, 40, 0.8)"
            , style "border" "2px solid rgba(255, 255, 255, 0.9)"
            , style "box-shadow" "0 0 6px rgba(0, 0, 0, 0.4)"
            , style "transform" "translate(-50%, -50%)"
            ]
            []
        ]


viewFace : Keyframe.AnimState -> FaceConfig -> Html Msg
viewFace animState config =
    let
        faceAnimAttributes =
            Keyframe.attributes config.groupName animState

        textAnimAttributes =
            Keyframe.attributes config.text.groupName animState
    in
    div
        (faceAnimAttributes
            ++ [ View3D.transformStyle View3D.Preserve3D
               , id config.id
               , style "position" "absolute"
               , style "width" (String.fromInt cube.size ++ "px")
               , style "height" (String.fromInt cube.size ++ "px")
               , style "background-color" config.background
               , style "border" ("2px solid " ++ config.borderColor)
               , style "box-sizing" "border-box"
               , style "display" "flex"
               , style "justify-content" "center"
               , style "align-items" "center"
               , style "font-weight" "bold"
               , style "font-size" "14px"
               ]
        )
        [ div
            [ style "color" "#ffffff"
            , style "position" "absolute"
            ]
            [ text config.label ]
        , div
            (textAnimAttributes
                ++ [ id config.text.id
                   , style "color" config.text.color
                   , style "position" "absolute"
                   ]
            )
            [ text config.text.label ]
        ]
