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


type alias Model =
    { animState : WAAPI.AnimState Msg
    , perspectiveStep : PerspectiveStep
    , currentAnimAreaSize : { width : Float, height : Float }
    , cube : CubeConfig
    }



-- INIT


init : { window : { width : Int, height : Int } } -> ( Model, Cmd Msg )
init flags =
    let
        initialAreaSize =
            { width = toFloat flags.window.width * 0.8, height = toFloat flags.window.height * 0.8 }

        cubeSize =
            min initialAreaSize.width initialAreaSize.height / 4

        depth =
            cubeSize / 2

        initialAnimState =
            WAAPI.init motionCmd motionMsg <|
                [ -- Initialize the perspective origin at the top-left corner (0%, 0%)
                  -- It will travel around the corners in sync with the dot animation:
                  -- (0,0) -> (100,0) -> (100,100) -> (0,100) -> (0,0)
                  PerspectiveOrigin.initPx perspectiveContainer.groupName 0 0
                    -- Keep perspective-origin on the same proportional behavior
                    -- so vanishing point and dot stay in sync on resize.
                    >> PerspectiveOrigin.resizePolicy perspectiveContainer.groupName
                        (Resize.withTiming Resize.SolveFromCurrent Resize.retarget)
                , Translate.initXY vanishingPointDot.groupName 0 0

                -- Bring the cube forward on the Z axis
                -- so that it doesn't get clipped by the
                -- z=0 clipping plane.
                , Translate.initZ cubeGroupName 420
                    >> Scale.init cubeGroupName 1
                    >> Scale.resizePolicy cubeGroupName Resize.proportional
                    -- Seed the dot at the top-left corner (0, 0) so that
                    -- `Translate.bounds` has runtime state to remap
                    -- with proportional policy when the container resizes.
                    >> Translate.initXY vanishingPointDot.groupName 0 0
                    >> Translate.resizePolicy vanishingPointDot.groupName
                        (Resize.withTiming Resize.SolveFromCurrent Resize.retarget)

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
      , perspectiveStep = MoveToTopRight
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


type PerspectiveStep
    = MoveToTopRight
    | MoveToBottomRight
    | MoveToBottomLeft
    | MoveToTopLeft



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



-- Face configuration


type alias TextConfig =
    { id : String
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
        , label = "BOTTOM"
        , color = "rgb(0,0 ,0   )"
        }
    }


perspectiveStepSpeed : Float
perspectiveStepSpeed =
    150


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


perspectiveAnimation : { width : Float, height : Float } -> PerspectiveStep -> AnimBuilder mode -> AnimBuilder mode
perspectiveAnimation areaSize step =
    case step of
        MoveToTopRight ->
            movePerspectiveRight perspectiveStepSpeed areaSize
                >> movePerspectiveTargetRight perspectiveStepSpeed areaSize

        MoveToBottomRight ->
            movePerspectiveDown perspectiveStepSpeed areaSize
                >> movePerspectiveTargetDown perspectiveStepSpeed areaSize

        MoveToBottomLeft ->
            movePerspectiveLeft perspectiveStepSpeed
                >> movePerspectiveTargetLeft perspectiveStepSpeed areaSize

        MoveToTopLeft ->
            movePerspectiveUp perspectiveStepSpeed
                >> movePerspectiveTargetUp perspectiveStepSpeed areaSize



-- ANIMATIONS
--
-- PERSPECTIVE ORIGIN - animates the vanishing point around the corners of the
-- container in sync with the cube animation


movePerspectiveOrigin : Float -> (PerspectiveOrigin.Builder mode -> PerspectiveOrigin.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveOrigin speed moveTo =
    PerspectiveOrigin.for perspectiveContainer.groupName
        >> PerspectiveOrigin.px
        >> moveTo
        >> PerspectiveOrigin.speed speed
        >> PerspectiveOrigin.easing Linear
        >> PerspectiveOrigin.build


movePerspectiveRight : Float -> { a | width : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveRight speed areaSize =
    movePerspectiveOrigin speed <|
        PerspectiveOrigin.toX areaSize.width


movePerspectiveLeft : Float -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveLeft speed =
    movePerspectiveOrigin speed <|
        PerspectiveOrigin.toX 0


movePerspectiveDown : Float -> { a | height : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveDown speed areaSize =
    movePerspectiveOrigin speed <|
        PerspectiveOrigin.toY areaSize.height


movePerspectiveUp : Float -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveUp speed =
    movePerspectiveOrigin speed <|
        PerspectiveOrigin.toY 0


movePerspectiveTarget : Float -> (Translate.Builder mode -> Translate.Builder mode) -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveTarget speed moveTo =
    Translate.for vanishingPointDot.groupName
        >> moveTo
        >> Translate.speed speed
        >> Translate.easing Linear
        >> Translate.build


movePerspectiveTargetRight : Float -> { a | width : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveTargetRight speed { width } =
    movePerspectiveTarget speed <|
        Translate.toX width
            >> Translate.clampY 0 0
            >> Translate.clampX 0 width


movePerspectiveTargetLeft : Float -> { a | height : Float, width : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveTargetLeft speed { height, width } =
    movePerspectiveTarget speed <|
        Translate.toX 0
            >> Translate.clampY height height
            >> Translate.clampX 0 width


movePerspectiveTargetDown : Float -> { a | height : Float, width : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveTargetDown speed { height, width } =
    movePerspectiveTarget speed <|
        Translate.toY height
            >> Translate.clampX width width
            >> Translate.clampY 0 height


movePerspectiveTargetUp : Float -> { a | height : Float } -> AnimBuilder mode -> AnimBuilder mode
movePerspectiveTargetUp speed { height } =
    movePerspectiveTarget speed <|
        Translate.toY 0
            >> Translate.clampX 0 0
            >> Translate.clampY 0 height


resizeEpsilon : Float
resizeEpsilon =
    0.01


isSameArea : { width : Float, height : Float } -> { width : Float, height : Float } -> Bool
isSameArea a b =
    abs (a.width - b.width)
        < resizeEpsilon
        && abs (a.height - b.height)
        < resizeEpsilon



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
                        perspectiveAnimation model.currentAnimAreaSize model.perspectiveStep
            in
            ( { model
                | animState = animState
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
                    { height = element.height, width = element.width }
            in
            ( { model | currentAnimAreaSize = measured }
            , Process.sleep 0
                |> Task.perform (always TriggerAnimation)
            )

        InitStageElement (Err _) ->
            ( model, Cmd.none )

        GotStageElement (Ok { element }) ->
            let
                newAreaSize =
                    { height = element.height, width = element.width }
            in
            if isSameArea newAreaSize model.currentAnimAreaSize then
                ( model, Cmd.none )

            else
                let
                    scale =
                        min newAreaSize.width newAreaSize.height
                            / min model.currentAnimAreaSize.width model.currentAnimAreaSize.height

                    scaleBounds =
                        { x = Just { min = scale, max = scale }
                        , y = Just { min = scale, max = scale }
                        , z = Just { min = scale, max = scale }
                        }

                    translateBounds =
                        case model.perspectiveStep of
                            -- Top edge: x moves, y stays pinned to 0
                            MoveToTopRight ->
                                { x = Just { min = 0, max = newAreaSize.width }
                                , y = Just { min = 0, max = 0 }
                                , z = Nothing
                                }

                            -- Right edge: y moves, x stays pinned to max width
                            MoveToBottomRight ->
                                { x = Just { min = newAreaSize.width, max = newAreaSize.width }
                                , y = Just { min = 0, max = newAreaSize.height }
                                , z = Nothing
                                }

                            -- Bottom edge: x moves, y stays pinned to max height
                            MoveToBottomLeft ->
                                { x = Just { min = 0, max = newAreaSize.width }
                                , y = Just { min = newAreaSize.height, max = newAreaSize.height }
                                , z = Nothing
                                }

                            -- Left edge: y moves, x stays pinned to 0
                            MoveToTopLeft ->
                                { x = Just { min = 0, max = 0 }
                                , y = Just { min = 0, max = newAreaSize.height }
                                , z = Nothing
                                }

                    ( animState, cmd ) =
                        -- `Scale.bounds` remaps the cube scale snapshot
                        -- proportionally to the new container (policy set at init).
                        -- `Translate.bounds` uses proportional policy (set at init)
                        -- so the dot remaps smoothly within the resized area.
                        -- `PerspectiveOrigin.bounds` uses the same resize bounds so
                        -- the camera vanishing point follows the exact same track.
                        -- Group-wide `Resize.bounds` is avoided here because
                        -- it would also clamp `Translate.initZ 200` into the
                        -- scale-ratio bounds and collapse the cube's z-depth.
                        WAAPI.onResize model.animState <|
                            Scale.bounds cubeGroupName scaleBounds
                                >> Translate.bounds vanishingPointDot.groupName translateBounds
                                >> PerspectiveOrigin.bounds perspectiveContainer.groupName translateBounds
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
        WAAPI.Ended "perspectiveContainerAnim" ->
            perspectiveStepEnded model

        _ ->
            ( model, Cmd.none )


perspectiveStepEnded : Model -> ( Model, Cmd Msg )
perspectiveStepEnded model =
    let
        nextStep =
            nextPerspectiveStep model.perspectiveStep

        ( animState, cmd ) =
            WAAPI.animate model.animState <|
                perspectiveAnimation model.currentAnimAreaSize nextStep
    in
    ( { model
        | animState = animState
        , perspectiveStep = nextStep
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
            , style "width" "100vw"
            , style "height" "100vh"
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
               , View3D.perspective 1200

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
               , style "background-color" "#7675ae"
               , style "border-radius" "12px"
               , style "box-shadow" "0 4px 8px rgba(0,0,0,0.1)"
               ]
        )
        [ viewVanishingPoint model.animState
        , div
            [ View3D.transformStyle View3D.Preserve3D
            , style "position" "absolute"
            , style "left" "50%"
            , style "top" "50%"
            , style "transform" "translate(-50%, -50%)"
            ]
            [ viewCube model ]
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
            [ id config.text.id
            , style "color" config.text.color
            , style "position" "absolute"
            ]
            [ text config.text.label ]
        ]
