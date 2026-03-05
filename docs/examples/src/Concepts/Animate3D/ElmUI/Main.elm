module Concepts.Animate3D.ElmUI.Main exposing (main)

import Anim.Engine.CSS.Keyframes as Keyframes
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Extra.View3D as View3D
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, clip, column, el, fill, height, html, htmlAttribute, maximum, moveDown, moveRight, padding, paddingEach, px, spacing, text, width)
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
    = Ready
    | Opening
    | Closing
    | RotatingOpen
    | RotatingClosed


type alias Model =
    { animState : Keyframes.AnimState
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
            Keyframes.init
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
            Ready
    in
    ( { animState =
            Keyframes.animate initialAnimState <|
                selectAnimation state

      -- --8<-- [end:startAnimation]
      , state = state
      , animAreaSize =
            { width = animAreaWidth
            , height = animAreaHeight
            }
      }
    , Cmd.none
    )



-- --8<-- [end:initializeAndTrigger]
-- ANIMATIONS
--
-- --8<-- [start:animationFunctions]
-- CUBE - 1st level of 3D animation
--
-- We only rotate the whole cube, not individual faces, they maintain their
-- position in 3D space because we use `View3D.transformStyle View3D.Preserve3D`
-- on the cube container


rotateCube : Float -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
rotateCube to =
    Rotate.for "cube"
        >> Rotate.to to
        >> Rotate.easing BackInOut
        >> Rotate.duration 8000
        >> Rotate.build


rotateCubeClockwise : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
rotateCubeClockwise =
    rotateCube 360


rotateCubeAntiClockwise : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
rotateCubeAntiClockwise =
    rotateCube 0



-- SIDES - 2nd level of 3D animation
--
-- For the side movement animations, we build complex animations out of
-- smaller pieces. Each individual piece is easy to understand and reason about


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


sharedTiming : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
sharedTiming =
    Keyframes.duration 1000
        >> Keyframes.easing BounceOut


moveFace : String -> (Translate.Builder -> Translate.Builder) -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
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


moveFrontFaceOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveFrontFaceOut =
    moveFace "front-face" <|
        Translate.toZ (depth + moveAmount)


moveFrontFaceIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveFrontFaceIn =
    moveFace "front-face" <|
        Translate.toZ depth


moveBackFaceOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveBackFaceOut =
    moveFace "back-face" <|
        Translate.toZ (-1 * depth - moveAmount)


moveBackFaceIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveBackFaceIn =
    moveFace "back-face" <|
        Translate.toZ (-1 * depth)


moveRightFaceOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveRightFaceOut =
    moveFace "right-face" <|
        Translate.toX (depth + moveAmount)


moveRightFaceIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveRightFaceIn =
    moveFace "right-face" <|
        Translate.toX depth


moveLeftFaceOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveLeftFaceOut =
    moveFace "left-face" <|
        Translate.toX (-1 * depth - moveAmount)


moveLeftFaceIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveLeftFaceIn =
    moveFace "left-face" <|
        Translate.toX (-1 * depth)


moveTopFaceOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveTopFaceOut =
    moveFace "top-face" <|
        Translate.toY (-1 * depth - moveAmount)


moveTopFaceIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveTopFaceIn =
    moveFace "top-face" <|
        Translate.toY (-1 * depth)


moveBottomFaceOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveBottomFaceOut =
    moveFace "bottom-face" <|
        Translate.toY (depth + moveAmount)


moveBottomFaceIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveBottomFaceIn =
    moveFace "bottom-face" <|
        Translate.toY depth



-- TEXT - 3rd level of 3D animation
--
-- Text moves forward (Z+20) and rotates (to z=360deg) when sides expand,
-- and then moves back (to Z=0) and rotates back (to z=0deg) when sides close


textMoveAmount : Float
textMoveAmount =
    20


moveText : String -> Float -> Float -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveText animGroup toZ toRotate =
    sharedTiming
        >> Translate.for animGroup
        >> Translate.toZ toZ
        >> Translate.build
        >> Rotate.for animGroup
        >> Rotate.toZ toRotate
        >> Rotate.build


moveTextsOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveTextsOut =
    moveText "front-face-text" textMoveAmount 360
        >> moveText "back-face-text" textMoveAmount 360
        >> moveText "right-face-text" textMoveAmount 360
        >> moveText "left-face-text" textMoveAmount 360
        >> moveText "top-face-text" textMoveAmount 360
        >> moveText "bottom-face-text" textMoveAmount 360


moveTextsIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveTextsIn =
    moveText "front-face-text" 0 0
        >> moveText "back-face-text" 0 0
        >> moveText "right-face-text" 0 0
        >> moveText "left-face-text" 0 0
        >> moveText "top-face-text" 0 0
        >> moveText "bottom-face-text" 0 0



-- --8<-- [end:animationFunctions]
-- --8<-- [start:animationSelector]


selectAnimation : State -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
selectAnimation state =
    case state of
        Ready ->
            moveSidesOut
                >> moveTextsOut

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
-- UPDATE


type Msg
    = NoOp
    | GotKeyframeMsg Keyframes.AnimMsg



-- --8<-- [start:stateMachine]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotKeyframeMsg animMsg ->
            let
                ( animState, animEvent ) =
                    Keyframes.update animMsg model.animState
            in
            ( handleKeyframeEvent animEvent { model | animState = animState }
            , Cmd.none
            )


handleKeyframeEvent : Keyframes.AnimEvent -> Model -> Model
handleKeyframeEvent animEvent model =
    case animEvent of
        Keyframes.Ended _ _ "cube" ->
            if model.state /= Ready then
                cubeRotationEnded model

            else
                model

        Keyframes.Ended _ _ "front-face" ->
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
        Ready ->
            stateChanged RotatingOpen model

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
            Keyframes.animate model.animState <|
                selectAnimation state
    }



-- --8<-- [end:stateMachine]
-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument
        "Keyframes 3D Example - ElmUI"
        UI.Basic
        (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    [ UI.pageHeader "Keyframes 3D Example - ElmUI"
    , Keyframes.styleNode model.animState
        |> html
    , viewExplanation
    , el
        [ -- Perspective container
          View3D.perspective 1000
            |> htmlAttribute
        , View3D.perspectiveOrigin View3D.Center
            |> htmlAttribute

        --
        -- Workaround for Chrome on macOS GPU compositing issues with 3D transforms.
        -- Setting opacity: 0.99 forces a new compositing layer, which prevents
        -- the colored rectangle artifacts that can appear during complex 3D animations.
        -- It's not perfect, some flickering can still occur.
        , View3D.opacityHack
            |> htmlAttribute
        , width (px model.animAreaSize.width)
        , height (px model.animAreaSize.height)
        , centerX
        , centerY
        , Background.color Colors.backgroundWhite
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }
        ]
      <|
        viewCube model
    ]


type alias FaceConfig =
    { id : String
    , textId : String
    , label : String
    , background : Element.Color
    , borderColor : Element.Color
    }


frontFace : FaceConfig
frontFace =
    { id = "front-face"
    , textId = "front-face-text"
    , label = "FRONT"
    , background = Element.rgb255 52 152 219
    , borderColor = Element.rgb255 41 128 185
    }


backFace : FaceConfig
backFace =
    { id = "back-face"
    , textId = "back-face-text"
    , label = "BACK"
    , background = Element.rgb255 41 128 185
    , borderColor = Element.rgb255 33 97 140
    }


rightFace : FaceConfig
rightFace =
    { id = "right-face"
    , textId = "right-face-text"
    , label = "RIGHT"
    , background = Element.rgb255 231 76 60
    , borderColor = Element.rgb255 192 57 43
    }


leftFace : FaceConfig
leftFace =
    { id = "left-face"
    , textId = "left-face-text"
    , label = "LEFT"
    , background = Element.rgb255 230 126 34
    , borderColor = Element.rgb255 211 84 0
    }


topFace : FaceConfig
topFace =
    { id = "top-face"
    , textId = "top-face-text"
    , label = "TOP"
    , background = Element.rgb255 46 204 113
    , borderColor = Element.rgb255 39 174 96
    }


bottomFace : FaceConfig
bottomFace =
    { id = "bottom-face"
    , textId = "bottom-face-text"
    , label = "BOTTOM"
    , background = Element.rgb255 155 89 182
    , borderColor = Element.rgb255 142 68 173
    }



-- --8<-- [start:renderCube]


viewCube : Model -> Element Msg
viewCube model =
    let
        cubeAttrs =
            Keyframes.attributes "cube" model.animState
                |> List.map htmlAttribute

        -- We only need one listener on the cube - no need to listen for events on the faces
        -- or the text elements, they will bubble up to the cube listener.
        cubeEvents =
            Keyframes.events "cube" GotKeyframeMsg
                |> List.map htmlAttribute
    in
    column
        (cubeAttrs
            ++ cubeEvents
            ++ [ View3D.transformStyle View3D.Preserve3D
                    |> htmlAttribute
               , width (px cubeSize)
               , height (px cubeSize)
               , centerX
               , centerY
               ]
        )
        [ viewFace model.animState frontFace
        , viewFace model.animState backFace
        , viewFace model.animState rightFace
        , viewFace model.animState leftFace
        , viewFace model.animState topFace
        , viewFace model.animState bottomFace
        ]


viewFace : Keyframes.AnimState -> FaceConfig -> Element Msg
viewFace animState config =
    let
        animAttributes =
            Keyframes.attributes config.id animState
                |> List.map htmlAttribute

        -- No event handlers needed here - events bubble to the cube listener
        -- and correctly report this element's ID as the source
        -- Text element with its own 3D animation (3rd level)
        textAnimAttributes =
            Keyframes.attributes config.textId animState
                |> List.map htmlAttribute
    in
    el
        (animAttributes
            ++ [ View3D.transformStyle View3D.Preserve3D |> htmlAttribute
               , Html.Attributes.style "position" "absolute"
                    |> htmlAttribute
               , Html.Attributes.style "display" "flex" |> htmlAttribute
               , Html.Attributes.style "justify-content" "center" |> htmlAttribute
               , Html.Attributes.style "align-items" "center" |> htmlAttribute
               , width (px cubeSize)
               , height (px cubeSize)
               , Background.color config.background
               , Border.width 2
               , Border.color config.borderColor
               , Font.color (Element.rgb 0 0 0)
               , Font.bold
               , Font.size 14
               ]
        )
        (el
            (textAnimAttributes
                ++ [ centerX, centerY ]
            )
            (text config.label)
        )



-- --8<-- [end:renderCube]


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
