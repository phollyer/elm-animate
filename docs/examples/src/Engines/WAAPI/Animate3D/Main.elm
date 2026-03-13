port module Engines.WAAPI.Animate3D.Main exposing (main)

import Anim.Engine.WAAPI as WAAPI
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


cubeSize : Int
cubeSize =
    100


depth : Float
depth =
    toFloat cubeSize / 2


type alias CubeConfig =
    { id : String
    , groupName : String
    }


cube : CubeConfig
cube =
    { id = "cube"
    , groupName = "cubeAnim"
    }


type alias TextConfig =
    { id : String
    , groupName : String
    , label : String
    , color : String
    }


type alias FaceConfig =
    { id : String
    , groupName : String
    , background : String
    , borderColor : String
    , text : TextConfig
    }


frontFace : FaceConfig
frontFace =
    { id = "front-face"
    , groupName = "frontFaceAnim"
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
    , background = "rgb(155, 89, 182)"
    , borderColor = "rgb(142, 68, 173)"
    , text =
        { id = "bottom-face-text"
        , groupName = "bottomFaceTextAnim"
        , label = "BOTTOM"
        , color = "rgb(0,0 ,0   )"
        }
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
                [ Translate.initZ cube.groupName 200
                , WAAPI.forElement frontFace.id
                    >> Translate.initZ frontFace.groupName depth
                , WAAPI.forElement backFace.id
                    >> Translate.initZ backFace.groupName (depth * -1)
                    >> Rotate.initY backFace.groupName 180
                , WAAPI.forElement rightFace.id
                    >> Translate.initX rightFace.groupName depth
                    >> Rotate.initY rightFace.groupName 90
                , WAAPI.forElement leftFace.id
                    >> Translate.initX leftFace.groupName (-1 * depth)
                    >> Rotate.initY leftFace.groupName -90
                , WAAPI.forElement topFace.id
                    >> Translate.initY topFace.groupName (-1 * depth)
                    >> Rotate.initX topFace.groupName 90
                , WAAPI.forElement bottomFace.id
                    >> Translate.initY bottomFace.groupName depth
                    >> Rotate.initX bottomFace.groupName -90
                ]

        state =
            Opening
    in
    ( { animState = initialAnimState

      ---8<-- [end:startAnimation]
      , state = state
      , animAreaSize =
            { width = animAreaWidth
            , height = animAreaHeight
            }
      }
    , Process.sleep 50
        |> Task.perform (\_ -> TriggerAnimation)
    )



---8<-- [end:initializeAndTrigger]
---8<-- [start:animationSelector]


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
            WAAPI.forElement cube.id
                >> rotateCubeClockwise

        RotatingClosed ->
            WAAPI.forElement cube.id
                >> rotateCubeAntiClockwise



---8<-- [end:animationSelector]
-- ANIMATIONS
--
---8<-- [start:animationFunctions]
-- CUBE - 1st level of 3D animation
--
-- We only rotate the whole cube, not individual faces, they maintain their
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
    rotateCube -360



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
        >> WAAPI.easing BounceOut


moveFace : String -> (Translate.Builder -> Translate.Builder) -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
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


moveFrontFaceOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveFrontFaceOut =
    WAAPI.forElement frontFace.id
        >> (moveFace frontFace.groupName <|
                Translate.toZ (depth + moveAmount)
           )


moveFrontFaceIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveFrontFaceIn =
    WAAPI.forElement frontFace.id
        >> (moveFace frontFace.groupName <|
                Translate.toZ depth
           )


moveBackFaceOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveBackFaceOut =
    WAAPI.forElement backFace.id
        >> (moveFace backFace.groupName <|
                Translate.toZ (-1 * depth - moveAmount)
           )


moveBackFaceIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveBackFaceIn =
    WAAPI.forElement backFace.id
        >> (moveFace backFace.groupName <|
                Translate.toZ (-1 * depth)
           )


moveRightFaceOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveRightFaceOut =
    WAAPI.forElement rightFace.id
        >> (moveFace rightFace.groupName <|
                Translate.toX (depth + moveAmount)
           )


moveRightFaceIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveRightFaceIn =
    WAAPI.forElement rightFace.id
        >> (moveFace rightFace.groupName <|
                Translate.toX depth
           )


moveLeftFaceOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveLeftFaceOut =
    WAAPI.forElement leftFace.id
        >> (moveFace leftFace.groupName <|
                Translate.toX (-1 * depth - moveAmount)
           )


moveLeftFaceIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveLeftFaceIn =
    WAAPI.forElement leftFace.id
        >> (moveFace leftFace.groupName <|
                Translate.toX (-1 * depth)
           )


moveTopFaceOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveTopFaceOut =
    WAAPI.forElement topFace.id
        >> (moveFace topFace.groupName <|
                Translate.toY (-1 * depth - moveAmount)
           )


moveTopFaceIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveTopFaceIn =
    WAAPI.forElement topFace.id
        >> (moveFace topFace.groupName <|
                Translate.toY (-1 * depth)
           )


moveBottomFaceOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveBottomFaceOut =
    WAAPI.forElement bottomFace.id
        >> (moveFace bottomFace.groupName <|
                Translate.toY (depth + moveAmount)
           )


moveBottomFaceIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveBottomFaceIn =
    WAAPI.forElement bottomFace.id
        >> (moveFace bottomFace.groupName <|
                Translate.toY depth
           )



-- TEXT - 3rd level of 3D animation
--
-- Text moves forward (Z+20) and rotates (to Z=360deg) when sides expand,
-- and then moves back (to Z=0) and rotates back (to Z=0deg) when sides close


textMoveAmount : Float
textMoveAmount =
    20


moveText : String -> String -> Float -> Float -> WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveText elementId animGroup toZ toRotate =
    sharedTiming
        >> WAAPI.forElement elementId
        >> Translate.for animGroup
        >> Translate.toZ toZ
        >> Translate.build
        >> Rotate.for animGroup
        >> Rotate.toZ toRotate
        >> Rotate.build


moveTextsOut : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveTextsOut =
    moveText frontFace.text.id frontFace.text.groupName textMoveAmount 360
        >> moveText backFace.text.id backFace.text.groupName textMoveAmount 360
        >> moveText rightFace.text.id rightFace.text.groupName textMoveAmount 360
        >> moveText leftFace.text.id leftFace.text.groupName textMoveAmount 360
        >> moveText topFace.text.id topFace.text.groupName textMoveAmount 360
        >> moveText bottomFace.text.id bottomFace.text.groupName textMoveAmount 360


moveTextsIn : WAAPI.AnimBuilder -> WAAPI.AnimBuilder
moveTextsIn =
    moveText frontFace.text.id frontFace.text.groupName 0 0
        >> moveText backFace.text.id backFace.text.groupName 0 0
        >> moveText rightFace.text.id rightFace.text.groupName 0 0
        >> moveText leftFace.text.id leftFace.text.groupName 0 0
        >> moveText topFace.text.id topFace.text.groupName 0 0
        >> moveText bottomFace.text.id bottomFace.text.groupName 0 0



---8<-- [end:animationFunctions]
-- UPDATE


type Msg
    = NoOp
    | TriggerAnimation
    | GotKeyframeMsg WAAPI.AnimMsg



---8<-- [start:stateMachine]


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
            ( { model
                | animState = animState
              }
            , cmd
            )

        GotKeyframeMsg animMsg ->
            let
                ( animState, animEvent ) =
                    WAAPI.update animMsg model.animState
            in
            handleKeyframeEvent animEvent { model | animState = animState }


handleKeyframeEvent : WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
handleKeyframeEvent animEvent model =
    case animEvent of
        WAAPI.Ended "cube" "cubeAnim" ->
            cubeRotationEnded model

        WAAPI.Ended "front-face" "frontFaceAnim" ->
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
    WAAPI.subscriptions GotKeyframeMsg model.animState



---8<-- [end:stateMachine]
-- VIEW


view : Model -> Document Msg
view model =
    { title = "WAAPI 3D Example - HTML"
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
            [ text "WAAPI 3D Example - HTML" ]
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



---8<-- [start:renderCube]


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
            [ text config.text.label ]
        , div
            (textAnimAttributes
                ++ [ id config.text.id
                   , style "color" config.text.color
                   , style "position" "absolute"
                   ]
            )
            [ text config.text.label ]
        ]



---8<-- [end:renderCube]
