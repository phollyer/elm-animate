port module Animation.WAAPI.Perspective3D.Main exposing (main)

import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.WAAPI as WAAPI
import Anim.Extra.View3D as View3D
import Anim.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Property.Rotate as Rotate
import Anim.Property.Scale as Scale
import Anim.Property.Translate as Translate
import Anim.Resize as Resize
import Browser exposing (Document)
import Browser.Dom as Dom
import Browser.Events
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, id, style)
import Json.Encode as Encode
import Motion.Easing as Easing exposing (Easing(..))
import Process
import Task



-- PORTS


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



-- MAIN


main : Program { window : { width : Int, height : Int } } Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


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
    { animState : WAAPI.AnimState Msg
    , state : State
    , perspectiveStep : PerspectiveStep
    , initialAnimAreaSize : { width : Float, height : Float }
    , currentAnimAreaSize : { width : Float, height : Float }
    , cube : CubeConfig
    }



-- INIT


init : { window : { width : Int, height : Int } } -> ( Model, Cmd Msg )
init flags =
    let
        initialAreaSize =
            animAreaSize
                (toFloat flags.window.width)
                (toFloat flags.window.height)

        cubeSize =
            initialAreaSize.width / 5

        depth =
            cubeSize / 2

        initialAnimState =
            WAAPI.init motionCmd motionMsg <|
                [ -- Initialize the perspective origin at the top-left corner (0%, 0%)
                  -- It will travel around the corners in sync with the cube animation:
                  -- (0,0) -> (100,0) -> (100,100) -> (0,100) -> (0,0)
                  PerspectiveOrigin.initPercent perspectiveContainer.groupName 0 0

                -- Bring the cube forward on the Z axis
                -- so that it doesn't get clipped by the
                -- z=0 clipping plane when we expand the
                -- sides and rotate
                , Translate.initZ cubeGroupName 200
                    -- Static no-op scale so that `Scale.onResize` has
                    -- runtime state to remap when the container resizes.
                    >> Scale.init cubeGroupName 1
                    >> Scale.init vanishingPointDot.groupName 1
                    -- Seed the dot at the top-left corner (0, 0) so that
                    -- `Translate.onResize` has runtime state to remap
                    -- proportionally when the container resizes.
                    >> Translate.initXY vanishingPointDot.groupName 0 0

                -- Position each face in 3D space along the axis it faces
                -- Front/Back faces move on Z (forward/backward)
                -- Left/Right faces move on X (sideways)
                -- Top/Bottom faces move on Y (up/down)
                , Translate.initZ frontFace.groupName depth
                , Translate.initZ backFace.groupName (depth * -1)
                    -- Rotate each face into position to build the cube
                    -- Front face is not rotated due to facing forward by default
                    >> Rotate.initY backFace.groupName 180
                , Translate.initX rightFace.groupName depth
                    >> Rotate.initY rightFace.groupName 90
                , Translate.initX leftFace.groupName (-1 * depth)
                    >> Rotate.initY leftFace.groupName -90
                , Translate.initY topFace.groupName (-1 * depth)
                    >> Rotate.initX topFace.groupName 90
                , Translate.initY bottomFace.groupName depth
                    >> Rotate.initX bottomFace.groupName -90

                -- The text labels all start on the same plane as their faces
                -- at z=0, which is the default starting position for elements, so we don't need
                -- to initialize them
                ]
    in
    ( { animState = initialAnimState
      , state = Opening
      , perspectiveStep = MoveToTopRight
      , initialAnimAreaSize = initialAreaSize
      , currentAnimAreaSize = initialAreaSize
      , cube =
            { id = "cube"
            , groupName = cubeGroupName
            , size = round cubeSize
            }
      }
    , Process.sleep 100
        |> Task.andThen (\_ -> Dom.getElement perspectiveContainer.id)
        |> Task.attempt InitStageElement
    )



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


cubeGroupName : String
cubeGroupName =
    "cubeAnim"


type alias CubeConfig =
    { id : String
    , groupName : String
    , size : Int
    }


{-| Square animation area sized off the smaller viewport axis so it
always fits the page in either orientation. Mirrors the responsive
strategy used by `Animation.WAAPI.Animate3D.Main`.
-}
animAreaSize : Float -> Float -> { width : Float, height : Float }
animAreaSize windowWidth windowHeight =
    if windowWidth < windowHeight then
        { width = windowWidth, height = windowWidth }

    else
        { width = windowHeight, height = windowHeight }



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


selectAnimation : Float -> State -> AnimBuilder mode -> AnimBuilder mode
selectAnimation targetAmount state =
    case state of
        Opening ->
            moveSidesOut targetAmount
                >> moveTextsOut

        Closing ->
            moveSidesIn targetAmount
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


{-| Which axis is moving for the leg currently in flight.
The model's `perspectiveStep` field always holds the _next_ step
(it is advanced immediately after `TriggerAnimation` fires), so the
in-flight leg is the one that produced the current `perspectiveStep`.
-}
type LegAxis
    = XAxisLeg
    | YAxisLeg


inFlightPerspectiveStep : PerspectiveStep -> LegAxis
inFlightPerspectiveStep nextStep =
    case nextStep of
        -- in-flight = MoveToTopRight: (0,0) -> (W,0)
        MoveToBottomRight ->
            XAxisLeg

        -- in-flight = MoveToBottomRight: (W,0) -> (W,H)
        MoveToBottomLeft ->
            YAxisLeg

        -- in-flight = MoveToBottomLeft: (W,H) -> (0,H)
        MoveToTopLeft ->
            XAxisLeg

        -- in-flight = MoveToTopLeft: (0,H) -> (0,0)
        MoveToTopRight ->
            YAxisLeg


perspectiveAnimation : { width : Float, height : Float } -> PerspectiveStep -> AnimBuilder mode -> AnimBuilder mode
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


movePerspectiveOrigin : Float -> Float -> Int -> { width : Float, height : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveOrigin x y ms areaSize =
    PerspectiveOrigin.for perspectiveContainer.groupName
        >> PerspectiveOrigin.percent
        >> PerspectiveOrigin.toXY x y
        >> PerspectiveOrigin.duration ms
        >> PerspectiveOrigin.easing Linear
        >> PerspectiveOrigin.build
        >> Translate.for vanishingPointDot.groupName
        >> Translate.toX (x / 100 * areaSize.width)
        >> Translate.toY (y / 100 * areaSize.height)
        >> Translate.duration ms
        >> Translate.easing Linear
        >> Translate.build



-- CUBE - 1st level of 3D animation
--
-- We only rotate the cube, not individual faces, they maintain their
-- position in 3D space because we use `View3D.transformStyle View3D.Preserve3D`
-- on the cube container


rotateCube : Float -> AnimBuilder mode -> AnimBuilder mode
rotateCube to =
    Rotate.for cubeGroupName
        >> Rotate.toXYZ to to to
        >> Rotate.easing BackInOut
        >> Rotate.duration 8000
        >> Rotate.build


rotateCubeClockwise : AnimBuilder mode -> AnimBuilder mode
rotateCubeClockwise =
    rotateCube 360


rotateCubeAntiClockwise : AnimBuilder mode -> AnimBuilder mode
rotateCubeAntiClockwise =
    rotateCube 0



-- SIDES - 2nd level of 3D animation
--
-- For the side movement animations, we build complex animations out of
-- smaller pieces.


moveSidesOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveSidesOut targetAmount =
    moveFrontFaceOut targetAmount
        >> moveBackFaceOut targetAmount
        >> moveRightFaceOut targetAmount
        >> moveLeftFaceOut targetAmount
        >> moveTopFaceOut targetAmount
        >> moveBottomFaceOut targetAmount


moveSidesIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveSidesIn targetAmount =
    moveFrontFaceIn targetAmount
        >> moveBackFaceIn targetAmount
        >> moveRightFaceIn targetAmount
        >> moveLeftFaceIn targetAmount
        >> moveTopFaceIn targetAmount
        >> moveBottomFaceIn targetAmount


sharedTiming : AnimBuilder mode -> AnimBuilder mode
sharedTiming =
    WAAPI.duration 1000
        >> WAAPI.easing CircInOut


moveFace : FaceConfig -> (Translate.Builder mode -> Translate.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
moveFace config moveToBuilder =
    sharedTiming
        >> Translate.for config.groupName
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


moveFrontFaceOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveFrontFaceOut toZ =
    moveFace frontFace <|
        Translate.toZ (toZ + moveAmount)


moveFrontFaceIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveFrontFaceIn toZ =
    moveFace frontFace <|
        Translate.toZ toZ


moveBackFaceOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveBackFaceOut toZ =
    moveFace backFace <|
        Translate.toZ (-1 * toZ - moveAmount)


moveBackFaceIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveBackFaceIn toZ =
    moveFace backFace <|
        Translate.toZ (-1 * toZ)


moveRightFaceOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveRightFaceOut toX =
    moveFace rightFace <|
        Translate.toX (toX + moveAmount)


moveRightFaceIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveRightFaceIn toX =
    moveFace rightFace <|
        Translate.toX toX


moveLeftFaceOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveLeftFaceOut toX =
    moveFace leftFace <|
        Translate.toX (-1 * toX - moveAmount)


moveLeftFaceIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveLeftFaceIn toX =
    moveFace leftFace <|
        Translate.toX (-1 * toX)


moveTopFaceOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveTopFaceOut toY =
    moveFace topFace <|
        Translate.toY (-1 * toY - moveAmount)


moveTopFaceIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveTopFaceIn toY =
    moveFace topFace <|
        Translate.toY (-1 * toY)


moveBottomFaceOut : Float -> AnimBuilder mode -> AnimBuilder mode
moveBottomFaceOut toY =
    moveFace bottomFace <|
        Translate.toY (toY + moveAmount)


moveBottomFaceIn : Float -> AnimBuilder mode -> AnimBuilder mode
moveBottomFaceIn toY =
    moveFace bottomFace <|
        Translate.toY toY



-- TEXT - 3rd level of 3D animation
--
-- Text moves forward (Z+20) and rotates (to Z=360deg) when sides expand,
-- and then moves back (to Z=0) and rotates back (to Z=0deg) when sides close


textMoveAmount : Float
textMoveAmount =
    20


moveText : TextConfig -> Float -> Float -> AnimBuilder mode -> AnimBuilder mode
moveText config toZ toRotate =
    sharedTiming
        >> Translate.for config.groupName
        >> Translate.toZ toZ
        >> Translate.build
        >> Rotate.for config.groupName
        >> Rotate.toZ toRotate
        >> Rotate.build


moveTextsOut : AnimBuilder mode -> AnimBuilder mode
moveTextsOut =
    moveText frontFace.text textMoveAmount 360
        >> moveText backFace.text textMoveAmount 360
        >> moveText rightFace.text textMoveAmount 360
        >> moveText leftFace.text textMoveAmount 360
        >> moveText topFace.text textMoveAmount 360
        >> moveText bottomFace.text textMoveAmount 360


moveTextsIn : AnimBuilder mode -> AnimBuilder mode
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
    | TriggerAnimation
    | GotWaapiMsg WAAPI.AnimMsg
    | InitStageElement (Result Dom.Error Dom.Element)
    | GotStageElement (Result Dom.Error Dom.Element)
    | OnWindowResize Int Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        TriggerAnimation ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState <|
                        selectAnimation (toFloat model.cube.size / 2) model.state
                            >> perspectiveAnimation model.currentAnimAreaSize model.perspectiveStep
            in
            ( { model
                | animState = animState
                , perspectiveStep = nextPerspectiveStep model.perspectiveStep
              }
            , cmd
            )

        GotWaapiMsg animMsg ->
            let
                ( animState, maybeAnimEvent ) =
                    WAAPI.update animMsg model.animState
            in
            case maybeAnimEvent of
                Just animEvent ->
                    handleMotionEvent animEvent { model | animState = animState }

                Nothing ->
                    ( { model | animState = animState }, Cmd.none )

        InitStageElement (Ok { element }) ->
            let
                measured =
                    animAreaSize element.width element.height
            in
            ( { model
                | initialAnimAreaSize = measured
                , currentAnimAreaSize = measured
              }
            , Process.sleep 0
                |> Task.perform (always TriggerAnimation)
            )

        InitStageElement (Err _) ->
            ( model, Cmd.none )

        GotStageElement (Ok { element }) ->
            let
                newAreaSize =
                    animAreaSize element.width element.height

                scale =
                    newAreaSize.width
                        / model.initialAnimAreaSize.width

                scaleBounds =
                    { x = Just { min = scale, max = scale }
                    , y = Just { min = scale, max = scale }
                    , z = Just { min = scale, max = scale }
                    }

                -- The dot only animates one axis per leg (it tracks
                -- container corners). Passing bounds for the static
                -- axis would make `Resize.applyAxis` Clamp re-clamp
                -- its end to the new bounds and drag the dot off the
                -- corner. Constrain only the in-flight axis.
                translateBounds =
                    case inFlightPerspectiveStep model.perspectiveStep of
                        XAxisLeg ->
                            { x = Just { min = 0, max = newAreaSize.width }
                            , y = Nothing
                            , z = Nothing
                            }

                        YAxisLeg ->
                            { x = Nothing
                            , y = Just { min = 0, max = newAreaSize.height }
                            , z = Nothing
                            }

                ( animState, cmd ) =
                    -- `Scale.onResize` remaps the cube and dot scale
                    -- snapshots proportionally to the new container
                    -- (matches the strategy used by `Animation.WAAPI.Animate3D`).
                    -- `Translate.onResize` uses `Clamp` so the dot stays
                    -- on its current pixel during resize while the new
                    -- corner becomes the leg's endpoint - `Proportional`
                    -- would relocate the dot to a new spot along the
                    -- track and look like the leg restarted.
                    -- Group-wide `Resize.onResize` is avoided here because
                    -- it would also clamp `Translate.initZ 200` into the
                    -- scale-ratio bounds and collapse the cube's z-depth.
                    WAAPI.onResize model.animState <|
                        Scale.onResize cubeGroupName Resize.Proportional scaleBounds
                            >> Scale.onResize vanishingPointDot.groupName Resize.Proportional scaleBounds
                            >> Translate.onResize vanishingPointDot.groupName
                                Resize.Clamp
                                translateBounds
            in
            ( { model
                | animState = animState
                , currentAnimAreaSize = newAreaSize
              }
            , cmd
            )

        GotStageElement (Err _) ->
            ( model, Cmd.none )

        OnWindowResize _ _ ->
            ( model
            , Task.attempt GotStageElement <|
                Dom.getElement perspectiveContainer.id
            )


handleMotionEvent : WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
handleMotionEvent animEvent model =
    case animEvent of
        WAAPI.Ended "cubeAnim" ->
            cubeRotationEnded model

        WAAPI.Ended "frontFaceAnim" ->
            sidesMovementEnded model

        WAAPI.Ended "vanishingPointDotAnim" ->
            perspectiveStepEnded model

        _ ->
            ( model, Cmd.none )


cubeRotationEnded : Model -> ( Model, Cmd Msg )
cubeRotationEnded model =
    case model.state of
        RotatingOpen ->
            stateChanged Closing model

        RotatingClosed ->
            stateChanged Opening model

        _ ->
            ( model, Cmd.none )


sidesMovementEnded : Model -> ( Model, Cmd Msg )
sidesMovementEnded model =
    case model.state of
        Opening ->
            stateChanged RotatingOpen model

        Closing ->
            stateChanged RotatingClosed model

        _ ->
            ( model, Cmd.none )


stateChanged : State -> Model -> ( Model, Cmd Msg )
stateChanged state model =
    let
        ( animState, cmd ) =
            WAAPI.animate model.animState <|
                selectAnimation (toFloat model.cube.size / 2) state
    in
    ( { model
        | state = state
        , animState = animState
      }
    , cmd
    )


perspectiveStepEnded : Model -> ( Model, Cmd Msg )
perspectiveStepEnded model =
    let
        ( animState, cmd ) =
            WAAPI.animate model.animState <|
                perspectiveAnimation model.currentAnimAreaSize model.perspectiveStep
    in
    ( { model
        | animState = animState
        , perspectiveStep = nextPerspectiveStep model.perspectiveStep
      }
    , cmd
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ WAAPI.subscriptions GotWaapiMsg model.animState
        , Browser.Events.onResize OnWindowResize
        ]



-- VIEW


view : Model -> Document Msg
view model =
    { title = "WAAPI Engine - 3D Perspective Origin Example"
    , body =
        [ div
            [ class "example-stage"
            , style "background" "linear-gradient(to bottom, rgb(226, 232, 240), rgb(248, 250, 252))"
            , style "font-family" "system-ui, sans-serif"
            ]
            [ viewAnimationArea model ]
        ]
    }


viewAnimationArea : Model -> Html Msg
viewAnimationArea model =
    div
        (WAAPI.attributes perspectiveContainer.groupName model.animState
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
               , style "width" "80vw"
               , style "height" "80vh"
               , style "max-width" "600px"
               , style "max-height" "600px"
               , style "aspect-ratio" "1 / 1"
               , style "margin" "0 auto"
               , style "background-color" "#ffffff"
               , style "border-radius" "12px"
               , style "box-shadow" "0 4px 8px rgba(0,0,0,0.1)"
               ]
        )
        [ viewVanishingPoint model.animState
        , viewCube model
        ]


viewVanishingPoint : WAAPI.AnimState Msg -> Html Msg
viewVanishingPoint animState =
    div
        (WAAPI.attributes vanishingPointDot.groupName animState
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


viewCube : Model -> Html Msg
viewCube model =
    let
        cubeAttrs =
            WAAPI.attributes cubeGroupName model.animState

        cubeSize =
            toFloat model.cube.size
    in
    div
        (cubeAttrs
            ++ [ View3D.transformStyle View3D.Preserve3D
               , id model.cube.id
               , style "width" (String.fromFloat cubeSize ++ "px")
               , style "height" (String.fromFloat cubeSize ++ "px")
               , style "position" "relative"
               ]
        )
        [ viewFace cubeSize model.animState frontFace
        , viewFace cubeSize model.animState backFace
        , viewFace cubeSize model.animState rightFace
        , viewFace cubeSize model.animState leftFace
        , viewFace cubeSize model.animState topFace
        , viewFace cubeSize model.animState bottomFace
        ]


viewFace : Float -> WAAPI.AnimState Msg -> FaceConfig -> Html Msg
viewFace cubeSize animState config =
    let
        faceAnimAttributes =
            WAAPI.attributes config.groupName animState

        textAnimAttributes =
            WAAPI.attributes config.text.groupName animState
    in
    div
        (faceAnimAttributes
            ++ [ View3D.transformStyle View3D.Preserve3D
               , id config.id
               , style "position" "absolute"
               , style "width" (String.fromFloat cubeSize ++ "px")
               , style "height" (String.fromFloat cubeSize ++ "px")
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
