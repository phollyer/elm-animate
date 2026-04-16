port module Engines.Animation.WAAPI.Animate3D.Main exposing (main)

import Anim.Engine.Animation.WAAPI as WAAPI
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Extra.View3D as View3D
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Html exposing (Html, div, p, span, text)
import Html.Attributes exposing (id, style)
import Json.Encode as Encode
import Process
import Task



-- PORTS


port waapiCommand : Encode.Value -> Cmd msg


port waapiEvent : (Encode.Value -> msg) -> Sub msg



-- MAIN


main : Program { window : { width : Int } } Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL
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


type alias Model =
    { animState : WAAPI.AnimState Msg
    , state : State
    , animAreaSize : { width : Int, height : Int }
    }



-- INIT
---8<-- [start:initializeAndTrigger]


init : { window : { width : Int } } -> ( Model, Cmd Msg )
init flags =
    let
        animAreaWidth =
            min 500 (flags.window.width - 40)

        animAreaHeight =
            350

        initialAnimState =
            WAAPI.init waapiCommand waapiEvent <|
                [ -- Bring the cube forward on the Z axis
                  -- so that it doesn't get clipped by the
                  -- z=0 clipping plane when we expand the
                  -- sides and rotate
                  Translate.initZ cube.groupName 200

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
      , animAreaSize =
            { width = animAreaWidth
            , height = animAreaHeight
            }
      }
    , Process.sleep 50
        |> Task.perform (always TriggerAnimation)
    )



---8<-- [end:initializeAndTrigger]
---8<-- [start:selectAnimation]


selectAnimation : State -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
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



---8<-- [end:selectAnimation]
-- ANIMATIONS
--
---8<-- [start:animationFunctions]
-- CUBE - 1st level of 3D animation
--
-- We only rotate the cube, not individual faces, they maintain their
-- position in 3D space because we use `View3D.transformStyle View3D.Preserve3D`
-- on the cube container


rotateCube : Float -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
rotateCube to =
    Rotate.for cube.groupName
        >> Rotate.toXYZ to to to
        >> Rotate.easing BackInOut
        >> Rotate.duration 8000
        >> Rotate.build


rotateCubeClockwise : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
rotateCubeClockwise =
    rotateCube 360


rotateCubeAntiClockwise : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
rotateCubeAntiClockwise =
    rotateCube 0



-- SIDES - 2nd level of 3D animation
--
-- For the side movement animations, we build complex animations out of
-- smaller pieces.


moveSidesOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveSidesOut =
    moveFrontFaceOut
        >> moveBackFaceOut
        >> moveRightFaceOut
        >> moveLeftFaceOut
        >> moveTopFaceOut
        >> moveBottomFaceOut


moveSidesIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveSidesIn =
    moveFrontFaceIn
        >> moveBackFaceIn
        >> moveRightFaceIn
        >> moveLeftFaceIn
        >> moveTopFaceIn
        >> moveBottomFaceIn


sharedTiming : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
sharedTiming =
    WAAPI.duration 1000
        >> WAAPI.easing CircInOut


moveFace : FaceConfig -> (Translate.Builder -> Translate.Builder) -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
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


moveFrontFaceOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveFrontFaceOut =
    moveFace frontFace <|
        Translate.toZ (depth + moveAmount)


moveFrontFaceIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveFrontFaceIn =
    moveFace frontFace <|
        Translate.toZ depth


moveBackFaceOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveBackFaceOut =
    moveFace backFace <|
        Translate.toZ (-1 * depth - moveAmount)


moveBackFaceIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveBackFaceIn =
    moveFace backFace <|
        Translate.toZ (-1 * depth)


moveRightFaceOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveRightFaceOut =
    moveFace rightFace <|
        Translate.toX (depth + moveAmount)


moveRightFaceIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveRightFaceIn =
    moveFace rightFace <|
        Translate.toX depth


moveLeftFaceOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveLeftFaceOut =
    moveFace leftFace <|
        Translate.toX (-1 * depth - moveAmount)


moveLeftFaceIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveLeftFaceIn =
    moveFace leftFace <|
        Translate.toX (-1 * depth)


moveTopFaceOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveTopFaceOut =
    moveFace topFace <|
        Translate.toY (-1 * depth - moveAmount)


moveTopFaceIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveTopFaceIn =
    moveFace topFace <|
        Translate.toY (-1 * depth)


moveBottomFaceOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveBottomFaceOut =
    moveFace bottomFace <|
        Translate.toY (depth + moveAmount)


moveBottomFaceIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
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


moveText : TextConfig -> Float -> Float -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveText config toZ toRotate =
    sharedTiming
        >> Translate.for config.groupName
        >> Translate.toZ toZ
        >> Translate.build
        >> Rotate.for config.groupName
        >> Rotate.toZ toRotate
        >> Rotate.build


moveTextsOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveTextsOut =
    moveText frontFace.text textMoveAmount 360
        >> moveText backFace.text textMoveAmount 360
        >> moveText rightFace.text textMoveAmount 360
        >> moveText leftFace.text textMoveAmount 360
        >> moveText topFace.text textMoveAmount 360
        >> moveText bottomFace.text textMoveAmount 360


moveTextsIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveTextsIn =
    moveText frontFace.text 0 0
        >> moveText backFace.text 0 0
        >> moveText rightFace.text 0 0
        >> moveText leftFace.text 0 0
        >> moveText topFace.text 0 0
        >> moveText bottomFace.text 0 0



---8<-- [end:animationFunctions]
-- UPDATE


type Msg
    = NoOp
    | TriggerAnimation
    | GotWaapiMsg WAAPI.AnimMsg



---8<-- [start:handleAnimationEvents]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        TriggerAnimation ->
            let
                ( animState, cmd ) =
                    WAAPI.animate model.animState <|
                        selectAnimation model.state
            in
            ( { model | animState = animState }
            , cmd
            )

        GotWaapiMsg animMsg ->
            let
                ( animState, animEvent ) =
                    WAAPI.update animMsg model.animState
            in
            handleWaapiEvent animEvent { model | animState = animState }


handleWaapiEvent : WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
handleWaapiEvent animEvent model =
    case animEvent of
        WAAPI.Ended "cubeAnim" ->
            cubeRotationEnded model

        WAAPI.Ended "frontFaceAnim" ->
            sidesMovementEnded model

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
                selectAnimation state
    in
    ( { model
        | state = state
        , animState = animState
      }
    , cmd
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WAAPI.subscriptions GotWaapiMsg model.animState



---8<-- [end:handleAnimationEvents]
-- VIEW


view : Model -> Document Msg
view model =
    { title = "WAAPI 3D Example"
    , body =
        [ div
            [ style "min-height" "100vh"
            , style "background" "linear-gradient(to bottom, rgb(226, 232, 240), rgb(248, 250, 252))"
            ]
            [ div
                [ style "font-family" "system-ui, sans-serif"
                , style "padding" "20px 40px"
                , style "max-width" "700px"
                , style "margin" "0 auto"
                ]
                [ viewExplanation
                , viewAnimationArea model
                ]
            ]
        ]
    }


viewExplanation : Html Msg
viewExplanation =
    div
        [ style "background-color" "#f2f5ff"
        , style "border-radius" "8px"
        , style "padding" "14px"
        , style "margin" "0 0 40px 0"
        , style "max-width" "700px"
        ]
        [ Html.h2
            [ style "font-size" "16px"
            , style "font-weight" "bold"
            , style "margin" "0 0 10px 0"
            ]
            [ text "3D Cube Animation" ]
        , p
            [ style "margin" "0"
            , style "font-size" "14px"
            ]
            [ text "This example demonstrates a 3D cube built with six positioned faces "
            , text "that cycles through: expand sides → rotate → close sides → rotate back."
            ]
        ]


viewAnimationArea : Model -> Html Msg
viewAnimationArea model =
    div
        [ -- Perspective container
          View3D.perspective 1000
        , View3D.perspectiveOrigin View3D.Center

        --
        -- Workaround for Chrome on macOS GPU compositing issues with 3D transforms.
        -- Setting opacity: 0.99 forces a new compositing layer, which prevents
        -- the colored rectangle artifacts that can appear during complex 3D animations.
        -- It's not perfect, some flickering can still occur.
        , View3D.opacityHack
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
        [ viewCube model ]



---8<-- [start:render]


viewCube : Model -> Html Msg
viewCube model =
    let
        cubeAttrs =
            WAAPI.attributes cube.groupName model.animState
    in
    div
        (cubeAttrs
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


viewFace : WAAPI.AnimState Msg -> FaceConfig -> Html Msg
viewFace animState config =
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



---8<-- [end:render]
