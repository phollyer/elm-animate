module Concepts.Animate3D.Main exposing (main)

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



-- Each face moves along the axis it faces:
-- Front/Back faces move on Z (forward/backward)
-- Left/Right faces move on X (sideways)
-- Top/Bottom faces move on Y (up/down)


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
    = GotKeyframeMsg Keyframes.AnimMsg



-- --8<-- [start:stateMachine]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotKeyframeMsg animMsg ->
            let
                ( newAnimState, event ) =
                    Keyframes.update animMsg model.animState

                newModel =
                    { model | animState = newAnimState }
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
                                selectAnimation newState
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
                                selectAnimation newState
                      }
                    , Cmd.none
                    )

                _ ->
                    ( newModel, Cmd.none )



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
        ]
        (el
            [ View3D.perspective 1000
                |> htmlAttribute
            , View3D.opacityHack
                -- Kind of fixes Chrome on macOS compositor tile corruption when
                -- animating 3D transforms by creating a new stacking
                -- context for the animation area
                -- it's not perfect, some flickering can still occur
                -- pull requests to improve this are welcome!
                |> htmlAttribute
            , centerX
            , centerY
            ]
            (viewCube model)
        )
    ]


type alias FaceConfig =
    { id : String
    , label : String
    , background : Element.Color
    , borderColor : Element.Color
    }


frontFace : FaceConfig
frontFace =
    { id = "front-face"
    , label = "FRONT"
    , background = Element.rgb255 52 152 219
    , borderColor = Element.rgb255 41 128 185
    }


backFace : FaceConfig
backFace =
    { id = "back-face"
    , label = "BACK"
    , background = Element.rgb255 41 128 185
    , borderColor = Element.rgb255 33 97 140
    }


rightFace : FaceConfig
rightFace =
    { id = "right-face"
    , label = "RIGHT"
    , background = Element.rgb255 231 76 60
    , borderColor = Element.rgb255 192 57 43
    }


leftFace : FaceConfig
leftFace =
    { id = "left-face"
    , label = "LEFT"
    , background = Element.rgb255 230 126 34
    , borderColor = Element.rgb255 211 84 0
    }


topFace : FaceConfig
topFace =
    { id = "top-face"
    , label = "TOP"
    , background = Element.rgb255 46 204 113
    , borderColor = Element.rgb255 39 174 96
    }


bottomFace : FaceConfig
bottomFace =
    { id = "bottom-face"
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

        -- Conditionally listen for keyframe events on both the cube and front face
        -- depending on the current state of the animation.
        -- This prevents us from receiving events that would bubble up from the 
        -- sides to the cube which would trigger unwanted state changes
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
               , View3D.perspectiveOrigin View3D.Center
                    |> htmlAttribute
               , width (px cubeSize)
               , height (px cubeSize)
               ]
        )
        [ -- we only listen for animation events on the front face
          -- since all faces would trigger at the same time
          viewFace model.animState shouldListenForSideEvents frontFace
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
            , Font.color (Element.rgb 1 1 1)
            , Font.bold
            , Font.size 14
            ]

        animAttributes =
            Keyframes.attributes config.id animState
                |> List.map htmlAttribute

        eventAttributes =
            if listenForEvents then
                Keyframes.events config.id GotKeyframeMsg
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
