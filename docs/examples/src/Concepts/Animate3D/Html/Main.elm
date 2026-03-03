module Concepts.Animate3D.Html.Main exposing (main)

import Anim.Engine.CSS.Keyframes as Keyframes
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Extra.View3D as View3D
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Html exposing (Html, div, p, span, text)
import Html.Attributes exposing (style)



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
                -- to initialize them with a transform
                ]

        state =
            Ready
    in
    ( { animState =
            Keyframes.animate initialAnimState <|
                selectAnimation state
      , state = state
      , animAreaSize =
            { width = animAreaWidth
            , height = animAreaHeight
            }
      }
    , Cmd.none
    )



-- ANIMATIONS
--
-- CUBE - 1st level of 3D animation
--
-- We only rotate the whole cube, not individual faces, they maintain their
-- position in 3D space because we use `View3D.transformStyle View3D.Preserve3D`
-- on the cube container which preserves the 3D transforms of child elements
-- instead of flattening them into 2D space


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
    rotateCube (-1 * 360)



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


moveFace : String -> (Translate.Builder -> Translate.Builder) -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveFace animGroup moveToBuilder =
    Translate.for animGroup
        >> moveToBuilder
        >> Translate.duration 1000
        >> Translate.easing BounceOut
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
-- Text moves forward (Z+20) and rotate (to 360deg) when sides expand,
-- and then back to Z=0 and 0deg when sides close


textMoveAmount : Float
textMoveAmount =
    20


textTiming : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
textTiming =
    Keyframes.duration 1000
        >> Keyframes.easing BounceOut


moveText : String -> Float -> Float -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveText textId toZ toRotate =
    textTiming
        >> Translate.for textId
        >> Translate.toZ toZ
        >> Translate.build
        >> Rotate.for textId
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



-- UPDATE


type Msg
    = NoOp
    | GotKeyframeMsg Keyframes.AnimMsg


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
        Keyframes.Ended "cube" ->
            if model.state /= Ready then
                cubeRotationEnded model

            else
                model

        Keyframes.Ended "front-face" ->
            sidesMovementEnded model

        _ ->
            model


cubeRotationEnded : Model -> Model
cubeRotationEnded model =
    let
        state =
            case model.state of
                RotatingOpen ->
                    Closing

                RotatingClosed ->
                    Opening

                _ ->
                    model.state
    in
    { model
        | state = state
        , animState = Keyframes.animate model.animState <| selectAnimation state
    }


sidesMovementEnded : Model -> Model
sidesMovementEnded model =
    let
        state =
            case model.state of
                Ready ->
                    RotatingOpen

                Opening ->
                    RotatingOpen

                Closing ->
                    RotatingClosed

                _ ->
                    model.state
    in
    { model
        | state = state
        , animState = Keyframes.animate model.animState <| selectAnimation state
    }



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Keyframes 3D Example - HTML"
    , body =
        [ div
            [ style "font-family" "system-ui, sans-serif"
            , style "padding" "20px"
            , style "max-width" "800px"
            , style "margin" "0 auto"
            ]
            [ Keyframes.styleNode model.animState
            , viewHeader
            , viewExplanation
            , viewAnimationArea model
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
            [ style "font-size" "24px"
            , style "margin" "0"
            ]
            [ text "Keyframes 3D Example - HTML" ]
        ]


viewExplanation : Html Msg
viewExplanation =
    div
        [ style "background-color" "#f2f5ff"
        , style "border-radius" "8px"
        , style "padding" "20px"
        , style "margin-bottom" "20px"
        ]
        [ Html.h2
            [ style "font-size" "16px"
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
        [ style "width" (String.fromInt model.animAreaSize.width ++ "px")
        , style "height" (String.fromInt model.animAreaSize.height ++ "px")
        , style "margin" "0 auto"
        , style "background-color" "#ffffff"
        , style "border-radius" "12px"
        , style "box-shadow" "0 4px 8px rgba(0,0,0,0.1)"

        -- Perspective container
        , View3D.perspective 1000
        , View3D.perspectiveOrigin View3D.Center
        , View3D.opacityHack

        -- flexbox centering on the perspective container
        , style "display" "flex"
        , style "justify-content" "center"
        , style "align-items" "center"
        ]
        [ div
            [ View3D.transformStyle View3D.Preserve3D
            , style "position" "relative"
            ]
            [ viewCube model ]
        ]


viewCube : Model -> Html Msg
viewCube model =
    let
        cubeAttrs =
            Keyframes.attributes "cube" model.animState

        cubeEvents =
            Keyframes.eventsStopPropagation "cube" GotKeyframeMsg
    in
    div
        (cubeAttrs
            ++ cubeEvents
            ++ [ View3D.transformStyle View3D.Preserve3D
               , style "width" (String.fromInt cubeSize ++ "px")
               , style "height" (String.fromInt cubeSize ++ "px")
               , style "position" "relative"
               ]
        )
        [ -- we only listen for animation events on the front face
          -- since all faces would trigger at the same time
          viewFace model.animState True frontFace
        , viewFace model.animState False backFace
        , viewFace model.animState False rightFace
        , viewFace model.animState False leftFace
        , viewFace model.animState False topFace
        , viewFace model.animState False bottomFace
        ]


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


viewFace : Keyframes.AnimState -> Bool -> FaceConfig -> Html Msg
viewFace animState listenForEvents config =
    let
        animAttributes =
            Keyframes.attributes config.id animState

        -- Always stop propagation on face events to prevent bubbling to cube
        -- Only forward events to our handler when we actually want to listen
        eventAttributes =
            Keyframes.eventsStopPropagation config.id
                (if listenForEvents then
                    GotKeyframeMsg

                 else
                    \_ -> NoOp
                )

        -- Text element with its own 3D animation (3rd level)
        -- Use eventsStopPropagation to prevent text animation events from
        -- bubbling up to the face element and triggering unwanted state changes
        textAnimAttributes =
            Keyframes.attributes config.textId animState

        textEventAttributes =
            Keyframes.eventsStopPropagation config.textId (\_ -> NoOp)
    in
    div
        (animAttributes
            ++ eventAttributes
            ++ [ style "position" "absolute"
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
               , View3D.transformStyle View3D.Preserve3D
               ]
        )
        [ span (textAnimAttributes ++ textEventAttributes) [ text config.label ] ]
