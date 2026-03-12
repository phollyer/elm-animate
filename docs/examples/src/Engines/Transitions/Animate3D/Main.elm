module Engines.Transitions.Animate3D.Main exposing (main)

import Anim.Engine.CSS.Transitions as Transitions
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Extra.View3D as View3D
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Html exposing (Html, div, p, span, text)
import Html.Attributes exposing (id, style)
import Process
import Task



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
    { animState : Transitions.AnimState
    , state : State
    , animAreaSize : { width : Int, height : Int }
    }


cubeSize : Int
cubeSize =
    100


depth : Float
depth =
    toFloat cubeSize / 2



-- INIT
-- --8<-- [start:initializeAndTrigger]


init : { window : { width : Int } } -> ( Model, Cmd Msg )
init flags =
    let
        animAreaWidth =
            min 500 (flags.window.width - 40)

        animAreaHeight =
            350

        initialAnimState =
            Transitions.init
                [ -- Bring the cube forward on the Z axis
                  -- so that it doesn't get clipped by the
                  -- z=0 clipping plane when we expand the
                  -- sides and rotate
                  Translate.initZ "cube" 200

                -- Position each face in 3D space along the axis it faces
                -- Front/Back faces move on Z (forward/backward)
                -- Left/Right faces move on X (sideways)
                -- Top/Bottom faces move on Y (up/down)
                , Translate.initZ "front-face" depth
                , Translate.initZ "back-face" (depth * -1)
                , Translate.initX "right-face" depth
                , Translate.initX "left-face" (-1 * depth)
                , Translate.initY "top-face" (-1 * depth)
                , Translate.initY "bottom-face" depth

                -- Rotate each face into position to build the cube
                -- Front face is not rotated due to facing forward by default
                , Rotate.initY "back-face" 180
                , Rotate.initY "right-face" 90
                , Rotate.initY "left-face" -90
                , Rotate.initX "top-face" 90
                , Rotate.initX "bottom-face" -90

                -- The text labels all start on the same plane as their faces
                -- at z=0, which is the default starting position for elements, so we don't need
                -- to initialize them
                ]

        state =
            Opening
    in
    ( { animState = initialAnimState

      -- --8<-- [end:startAnimation]
      , state = state
      , animAreaSize =
            { width = animAreaWidth
            , height = animAreaHeight
            }
      }
    , Process.sleep 50
        |> Task.perform (always TriggerAnimation)
    )



-- --8<-- [end:initializeAndTrigger]
-- --8<-- [start:animationSelector]


selectAnimation : State -> Transitions.AnimBuilder -> Transitions.AnimBuilder
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



-- --8<-- [end:animationSelector]
-- ANIMATIONS
--
-- --8<-- [start:animationFunctions]
-- CUBE - 1st level of 3D animation
--
-- We only rotate the whole cube, not individual faces, they maintain their
-- position in 3D space because we use `View3D.transformStyle View3D.Preserve3D`
-- on the cube container


rotateCube : Float -> Transitions.AnimBuilder -> Transitions.AnimBuilder
rotateCube to =
    Rotate.for "cube"
        >> Rotate.toXYZ to to to
        >> Rotate.easing BackInOut
        >> Rotate.duration 8000
        >> Rotate.build


rotateCubeClockwise : Transitions.AnimBuilder -> Transitions.AnimBuilder
rotateCubeClockwise =
    rotateCube 360


rotateCubeAntiClockwise : Transitions.AnimBuilder -> Transitions.AnimBuilder
rotateCubeAntiClockwise =
    rotateCube 0



-- SIDES - 2nd level of 3D animation
--
-- For the side movement animations, we build complex animations out of
-- smaller pieces.


moveSidesOut : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveSidesOut =
    moveFrontFaceOut
        >> moveBackFaceOut
        >> moveRightFaceOut
        >> moveLeftFaceOut
        >> moveTopFaceOut
        >> moveBottomFaceOut


moveSidesIn : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveSidesIn =
    moveFrontFaceIn
        >> moveBackFaceIn
        >> moveRightFaceIn
        >> moveLeftFaceIn
        >> moveTopFaceIn
        >> moveBottomFaceIn


sharedTiming : Transitions.AnimBuilder -> Transitions.AnimBuilder
sharedTiming =
    Transitions.duration 1000
        >> Transitions.easing BounceOut


moveFace : String -> (Translate.Builder -> Translate.Builder) -> Transitions.AnimBuilder -> Transitions.AnimBuilder
moveFace animGroup moveToBuilder =
    sharedTiming
        >> Translate.for animGroup
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


moveFrontFaceOut : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveFrontFaceOut =
    moveFace "front-face" <|
        Translate.toZ (depth + moveAmount)


moveFrontFaceIn : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveFrontFaceIn =
    moveFace "front-face" <|
        Translate.toZ depth


moveBackFaceOut : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveBackFaceOut =
    moveFace "back-face" <|
        Translate.toZ (-1 * depth - moveAmount)


moveBackFaceIn : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveBackFaceIn =
    moveFace "back-face" <|
        Translate.toZ (-1 * depth)


moveRightFaceOut : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveRightFaceOut =
    moveFace "right-face" <|
        Translate.toX (depth + moveAmount)


moveRightFaceIn : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveRightFaceIn =
    moveFace "right-face" <|
        Translate.toX depth


moveLeftFaceOut : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveLeftFaceOut =
    moveFace "left-face" <|
        Translate.toX (-1 * depth - moveAmount)


moveLeftFaceIn : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveLeftFaceIn =
    moveFace "left-face" <|
        Translate.toX (-1 * depth)


moveTopFaceOut : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveTopFaceOut =
    moveFace "top-face" <|
        Translate.toY (-1 * depth - moveAmount)


moveTopFaceIn : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveTopFaceIn =
    moveFace "top-face" <|
        Translate.toY (-1 * depth)


moveBottomFaceOut : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveBottomFaceOut =
    moveFace "bottom-face" <|
        Translate.toY (depth + moveAmount)


moveBottomFaceIn : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveBottomFaceIn =
    moveFace "bottom-face" <|
        Translate.toY depth



-- TEXT - 3rd level of 3D animation
--
-- Text moves forward (Z+20) and rotates (to Z=360deg) when sides expand,
-- and then moves back (to Z=0) and rotates back (to Z=0deg) when sides close


textMoveAmount : Float
textMoveAmount =
    20


moveText : String -> Float -> Float -> Transitions.AnimBuilder -> Transitions.AnimBuilder
moveText animGroup toZ toRotate =
    sharedTiming
        >> Translate.for animGroup
        >> Translate.toZ toZ
        >> Translate.build
        >> Rotate.for animGroup
        >> Rotate.toZ toRotate
        >> Rotate.build


moveTextsOut : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveTextsOut =
    moveText "front-face-text" textMoveAmount 360
        >> moveText "back-face-text" textMoveAmount 360
        >> moveText "right-face-text" textMoveAmount 360
        >> moveText "left-face-text" textMoveAmount 360
        >> moveText "top-face-text" textMoveAmount 360
        >> moveText "bottom-face-text" textMoveAmount 360


moveTextsIn : Transitions.AnimBuilder -> Transitions.AnimBuilder
moveTextsIn =
    moveText "front-face-text" 0 0
        >> moveText "back-face-text" 0 0
        >> moveText "right-face-text" 0 0
        >> moveText "left-face-text" 0 0
        >> moveText "top-face-text" 0 0
        >> moveText "bottom-face-text" 0 0



-- --8<-- [end:animationFunctions]
-- UPDATE


type Msg
    = NoOp
    | TriggerAnimation
    | GotTransitionsMsg Transitions.AnimMsg



-- --8<-- [start:stateMachine]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg |> Debug.log "Msg" of
        NoOp ->
            ( model, Cmd.none )

        TriggerAnimation ->
            ( { model
                | animState =
                    Transitions.animate model.animState <|
                        selectAnimation model.state
              }
            , Cmd.none
            )

        GotTransitionsMsg animMsg ->
            let
                ( animState, animEvent ) =
                    Transitions.update animMsg model.animState
            in
            ( handleKeyframeEvent animEvent { model | animState = animState }
            , Cmd.none
            )


handleKeyframeEvent : Transitions.AnimEvent -> Model -> Model
handleKeyframeEvent animEvent model =
    case animEvent |> Debug.log "AnimEvent" of
        Transitions.Ended _ _ "cube" ->
            cubeRotationEnded model

        Transitions.Ended _ _ "front-face" ->
            sidesMovementEnded model

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
            Transitions.animate model.animState <|
                selectAnimation state
    }



-- --8<-- [end:stateMachine]
-- VIEW


view : Model -> Document Msg
view model =
    { title = "Transitions 3D Example - HTML"
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
                [ viewHeader
                , viewExplanation
                , viewAnimationArea model
                ]
            ]
        ]
    }


viewHeader : Html Msg
viewHeader =
    div
        [ style "text-align" "center"
        , style "margin-bottom" "20px"
        ]
        [ Html.h1
            [ style "font-size" "28px"
            , style "font-weight" "bold"
            , style "margin" "0"
            ]
            [ text "Transitions 3D Example - HTML" ]
        ]


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


type alias FaceConfig =
    { id : String
    , textId : String
    , label : String
    , background : String
    , borderColor : String
    }


frontFace : FaceConfig
frontFace =
    { id = "front-face"
    , textId = "front-face-text"
    , label = "FRONT"
    , background = "rgb(52, 152, 219)"
    , borderColor = "rgb(41, 128, 185)"
    }


backFace : FaceConfig
backFace =
    { id = "back-face"
    , textId = "back-face-text"
    , label = "BACK"
    , background = "rgb(41, 128, 185)"
    , borderColor = "rgb(33, 97, 140)"
    }


rightFace : FaceConfig
rightFace =
    { id = "right-face"
    , textId = "right-face-text"
    , label = "RIGHT"
    , background = "rgb(231, 76, 60)"
    , borderColor = "rgb(192, 57, 43)"
    }


leftFace : FaceConfig
leftFace =
    { id = "left-face"
    , textId = "left-face-text"
    , label = "LEFT"
    , background = "rgb(230, 126, 34)"
    , borderColor = "rgb(211, 84, 0)"
    }


topFace : FaceConfig
topFace =
    { id = "top-face"
    , textId = "top-face-text"
    , label = "TOP"
    , background = "rgb(46, 204, 113)"
    , borderColor = "rgb(39, 174, 96)"
    }


bottomFace : FaceConfig
bottomFace =
    { id = "bottom-face"
    , textId = "bottom-face-text"
    , label = "BOTTOM"
    , background = "rgb(155, 89, 182)"
    , borderColor = "rgb(142, 68, 173)"
    }



-- --8<-- [start:renderCube]


viewCube : Model -> Html Msg
viewCube model =
    let
        cubeAttrs =
            Transitions.attributes "cube" model.animState

        cubeEvents =
            Transitions.events "cube" GotTransitionsMsg
    in
    div
        (cubeAttrs
            ++ cubeEvents
            ++ [ View3D.transformStyle View3D.Preserve3D
               , id "cube"
               , style "width" (String.fromInt cubeSize ++ "px")
               , style "height" (String.fromInt cubeSize ++ "px")
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


viewFace : Transitions.AnimState -> FaceConfig -> Html Msg
viewFace animState config =
    let
        faceAnimAttributes =
            Transitions.attributes config.id animState

        textAnimAttributes =
            Transitions.attributes config.textId animState
    in
    div
        (faceAnimAttributes
            ++ [ View3D.transformStyle View3D.Preserve3D
               , id config.id
               , style "position" "absolute"
               , style "width" (String.fromInt cubeSize ++ "px")
               , style "height" (String.fromInt cubeSize ++ "px")
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
                ++ [ style "position" "absolute"
                   , id config.textId
                   ]
            )
            [ text config.label ]
        ]



-- --8<-- [end:renderCube]
