module Concepts.Animate3D.MainBox exposing (main)

import Anim.Engine.CSS.Keyframes as Keyframes
import Anim.Extra.Easing exposing (Easing(..))
import Anim.Extra.View3D as View3D
import Anim.Property.Rotate as Rotate
import Anim.Property.Translate as Translate
import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, centerY, clip, column, el, fill, height, html, htmlAttribute, maximum, padding, paddingEach, px, spacing, text, width)
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


cubeSize : Int
cubeSize =
    100


depth : Float
depth =
    toFloat cubeSize / 2



-- INIT


init : { window : { width : Int } } -> ( Model, Cmd Msg )
init flags =
    -- --8<-- [start:initializeProperties]
    let
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

                -- Initialize text labels at Z=0 (flush with face)
                , Translate.initZ "front-face-text" 0
                , Translate.initZ "back-face-text" 0
                , Translate.initZ "right-face-text" 0
                , Translate.initZ "left-face-text" 0
                , Translate.initZ "top-face-text" 0
                , Translate.initZ "bottom-face-text" 0
                ]
    in
    -- --8<-- [end:initializeProperties]
    -- --8<-- [start:startAnimation]
    ( { animState = Keyframes.animate initialAnimState moveSidesOut

      -- --8<-- [end:startAnimation]
      , state = Opening
      , animAreaSize =
            { width = min 500 (flags.window.width - 40)
            , height = 350
            }
      }
    , Cmd.none
    )



-- ANIMATIONS
-- --8<-- [start:animationFunctions]
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
        >> moveTextsOut


moveSidesIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveSidesIn =
    moveFrontFaceIn
        >> moveBackFaceIn
        >> moveRightFaceIn
        >> moveLeftFaceIn
        >> moveTopFaceIn
        >> moveBottomFaceIn
        >> moveTextsIn


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



-- Text animations - 3rd level of 3D animation
-- Text moves forward (Z+20) when sides expand, back to Z=0 when sides close


textMoveAmount : Float
textMoveAmount =
    20


moveText : String -> Float -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveText textId toZ =
    Translate.for textId
        >> Translate.toZ toZ
        >> Translate.duration 1000
        >> Translate.easing BounceOut
        >> Translate.build


moveTextsOut : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveTextsOut =
    moveText "front-face-text" textMoveAmount
        >> moveText "back-face-text" textMoveAmount
        >> moveText "right-face-text" textMoveAmount
        >> moveText "left-face-text" textMoveAmount
        >> moveText "top-face-text" textMoveAmount
        >> moveText "bottom-face-text" textMoveAmount


moveTextsIn : Keyframes.AnimBuilder -> Keyframes.AnimBuilder
moveTextsIn =
    moveText "front-face-text" 0
        >> moveText "back-face-text" 0
        >> moveText "right-face-text" 0
        >> moveText "left-face-text" 0
        >> moveText "top-face-text" 0
        >> moveText "bottom-face-text" 0



-- --8<-- [end:animationFunctions]
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
        Keyframes.Ended "cube" ->
            -- Only process cube ended when we're in a rotating state
            if model.state == RotatingOpen || model.state == RotatingClosed then
                cubeRotationEnded model

            else
                model

        Keyframes.Ended "front-face" ->
            -- Only process front-face ended when we're in opening/closing state
            if model.state == Opening || model.state == Closing then
                sidesMovementEnded model

            else
                model

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
        , animState =
            Keyframes.animate model.animState <|
                selectAnimation state
    }


sidesMovementEnded : Model -> Model
sidesMovementEnded model =
    let
        state =
            case model.state of
                Opening ->
                    RotatingOpen

                Closing ->
                    RotatingClosed

                _ ->
                    model.state
    in
    { model
        | state = state
        , animState =
            Keyframes.animate model.animState <|
                selectAnimation state
    }



-- --8<-- [end:stateMachine]
-- --8<-- [start:animationSelector]


selectAnimation : State -> Keyframes.AnimBuilder -> Keyframes.AnimBuilder
selectAnimation state =
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
    , Keyframes.styleNode model.animState
        |> html
    , viewExplanation
    , el
        [ width (px model.animAreaSize.width)
        , height (px model.animAreaSize.height)
        , centerX
        , Background.color Colors.backgroundWhite
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }

        -- Perspective and centering on the same element to avoid breaking 3D context
        , View3D.perspective 1000
            |> htmlAttribute
        , View3D.perspectiveOrigin View3D.Center
            |> htmlAttribute
        , View3D.opacityHack
            -- Kind of fixes Chrome on macOS compositor tile corruption when
            -- animating 3D transforms by creating a new stacking
            -- context for the animation area
            -- it's not perfect, some flickering can still occur
            -- pull requests to improve this are welcome!
            |> htmlAttribute

        -- Use raw CSS for centering to avoid elm-ui wrapper elements
        , Html.Attributes.style "display" "flex" |> htmlAttribute
        , Html.Attributes.style "justify-content" "center" |> htmlAttribute
        , Html.Attributes.style "align-items" "center" |> htmlAttribute
        ]
      <|
        el
            [ View3D.transformStyle View3D.Preserve3D
                |> htmlAttribute
            ]
    , width (px model.animAreaSize.width)
    , height (px model.animAreaSize.height) <|
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



-- --8<-- [start:viewCube]


viewCube : Model -> Element Msg
viewCube model =
    let
        cubeAttrs =
            Keyframes.attributes "cube" model.animState
                |> List.map htmlAttribute

        -- Only listen for cube events when we're in rotation states
        -- This prevents catching bubbled events from faces during side movement
        cubeEvents =
            if model.state == RotatingOpen || model.state == RotatingClosed then
                Keyframes.events "cube" GotKeyframeMsg
                    |> List.map htmlAttribute

            else
                []

        shouldListenForSideEvents =
            model.state == Opening || model.state == Closing
    in
    column
        (cubeAttrs
            ++ cubeEvents
            ++ [ View3D.transformStyle View3D.Preserve3D
                    |> htmlAttribute
               , width (px cubeSize)
               , height (px cubeSize)
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



-- --8<-- [end:viewCube]
-- --8<-- [start:viewFace]


viewFace : Keyframes.AnimState -> Bool -> FaceConfig -> Element Msg
viewFace animState listenForEvents config =
    let
        baseAttributes =
            [ Html.Attributes.style "position" "absolute"
                |> htmlAttribute
            , width (px cubeSize)
            , height (px cubeSize)
            , Background.color config.background
            , Border.width 2
            , Border.color config.borderColor
            , Font.color (Element.rgb 0 0 0)
            , Font.bold
            , Font.size 14
            ]

        animAttributes =
            Keyframes.attributes config.id animState
                |> List.map htmlAttribute

        -- Always stop propagation on face events to prevent bubbling to cube
        -- Only forward events to our handler when we actually want to listen
        eventAttributes =
            Keyframes.events config.id
                (if listenForEvents then
                    GotKeyframeMsg

                 else
                    \_ -> NoOp
                )
                |> List.map htmlAttribute

        -- Text element with its own 3D animation (3rd level)
        -- Use eventsStopPropagation to prevent text animation events from
        -- bubbling up to the face element and triggering unwanted state changes
        textAnimAttributes =
            Keyframes.attributes config.textId animState
                |> List.map htmlAttribute
    in
    el
        (baseAttributes
            ++ animAttributes
            ++ eventAttributes
            ++ [ Html.Attributes.style "display" "flex" |> htmlAttribute
               , Html.Attributes.style "justify-content" "center" |> htmlAttribute
               , Html.Attributes.style "align-items" "center" |> htmlAttribute
               , View3D.transformStyle View3D.Preserve3D |> htmlAttribute
               ]
        )
        (el (textAnimAttributes ++ [ centerX, centerY ]) (text config.label))



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
