module Anim.Internal.WAAPI exposing
    ( TargetId
    , init, builder, animate, AnimState
    , getPosition, getCurrentStyles
    , delay, duration, easing, speed, update
    )

{-| Ports-based animation system for Anim.

This module converts AnimBuilder configurations to JavaScript Web Animations API
commands via Elm ports for high-performance, platform-optimized animations.


# Animation Execution

@docs TargetId


# State Management

@docs init, builder, animate, AnimState


# Animation Data

@docs getPosition, getCurrentStyles

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.BackgroundColor as Color exposing (Color)
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Properties.Size exposing (Size)
import Anim.Internal.Timing.Easing exposing (Easing)
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias AnimBuilder =
    Builder.AnimBuilder



-- ANIMATION STATE


{-| State for managing ports-based animations.
-}
type AnimState
    = AnimState
        { elementAnimations : Dict ElementId ElementAnimation
        , isRunning : Bool
        , builder : AnimBuilder
        }


type alias ElementId =
    String


type alias ElementAnimation =
    { commands : Encode.Value
    , endStates : ElementEndStates
    }


type alias ElementEndStates =
    { position : Maybe Position
    , rotate : Maybe Rotate
    , scale : Maybe Scale
    , color : Maybe Color
    , opacity : Maybe Opacity
    , size : Maybe Size
    }


{-| The ID of the target element to animate.
-}
type alias TargetId =
    String


{-| Initialize empty animation builder.
-}
init : AnimState
init =
    AnimState
        { elementAnimations = Dict.empty
        , isRunning = False
        , builder = Builder.init
        }


{-| Turn the AnimState into an AnimBuilder with current state preserved.
-}
builder : AnimState -> AnimBuilder
builder (AnimState state) =
    state.builder


{-| Create animation command with state tracking.
-}
animate : AnimState -> AnimBuilder -> ( AnimState, Encode.Value )
animate (AnimState state) builder_ =
    let
        processedData =
            Builder.processAnimationData builder_

        -- Create element animations from processed data
        newElementAnimations =
            processedData.elements
                |> Dict.map
                    (\_ elementConfig ->
                        { commands = Builder.encode processedData
                        , endStates = extractElementEndStates elementConfig
                        }
                    )

        -- Merge with existing animations (new animations replace old ones for same elements)
        updatedElementAnimations =
            Dict.union newElementAnimations state.elementAnimations

        newAnimState =
            AnimState
                { elementAnimations = updatedElementAnimations
                , isRunning = not (Dict.isEmpty newElementAnimations)
                , builder = Builder.markDirty builder_
                }

        encodedData =
            Builder.encode processedData
    in
    ( newAnimState, encodedData )


extractElementEndStates : Builder.ProcessedElementConfig -> ElementEndStates
extractElementEndStates elementConfig =
    List.foldl extractPropertyEndState emptyElementEndStates elementConfig.properties


emptyElementEndStates : ElementEndStates
emptyElementEndStates =
    { position = Nothing
    , rotate = Nothing
    , scale = Nothing
    , color = Nothing
    , opacity = Nothing
    , size = Nothing
    }


extractPropertyEndState : Builder.ProcessedPropertyConfig -> ElementEndStates -> ElementEndStates
extractPropertyEndState property state =
    case property of
        Builder.ProcessedPositionConfig config ->
            { state | position = Just config.endAt }

        Builder.ProcessedRotateConfig config ->
            { state | rotate = Just config.endAt }

        Builder.ProcessedScaleConfig config ->
            { state | scale = Just config.endAt }

        Builder.ProcessedBackgroundColorConfig config ->
            { state | color = Just config.endAt }

        Builder.ProcessedOpacityConfig config ->
            { state | opacity = Just config.endAt }

        Builder.ProcessedSizeConfig config ->
            { state | size = Just config.endAt }


{-| Get current position of an element.
-}
getPosition : String -> AnimState -> Maybe Position
getPosition elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.endStates >> .position)


duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Builder.duration


speed : Float -> AnimBuilder -> AnimBuilder
speed value =
    Builder.speed value


easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Builder.easing


delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Builder.delay


{-| Get current styles for an element (for debugging/display purposes).
-}
getCurrentStyles : String -> AnimState -> List ( String, String )
getCurrentStyles elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Nothing ->
            []

        Just elementAnimation ->
            let
                endStates =
                    elementAnimation.endStates

                transformParts =
                    [ endStates.position |> Maybe.map positionToTransform
                    , endStates.rotate |> Maybe.map rotateToTransform
                    , endStates.scale |> Maybe.map scaleToTransform
                    ]
                        |> List.filterMap identity

                nonTransformStyles =
                    [ endStates.color |> Maybe.map colorToStyle
                    , endStates.opacity |> Maybe.map opacityToStyle
                    ]
                        |> List.filterMap identity

                transformStyle =
                    if List.isEmpty transformParts then
                        []

                    else
                        [ ( "transform", String.join " " transformParts ) ]
            in
            transformStyle ++ nonTransformStyles


positionToTransform : Position -> String
positionToTransform pos =
    let
        ( x, y, z ) =
            Position.toTriple pos
    in
    "translate3d(" ++ String.fromFloat x ++ "px, " ++ String.fromFloat y ++ "px, " ++ String.fromFloat z ++ "px)"


rotateToTransform : Rotate -> String
rotateToTransform rot =
    Rotate.to3DCssString rot


scaleToTransform : Scale -> String
scaleToTransform scl =
    let
        ( x, y ) =
            Scale.toTuple scl
    in
    "scale(" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")"


colorToStyle : Color -> ( String, String )
colorToStyle col =
    ( "background-color", Color.toString col )


opacityToStyle : Opacity -> ( String, String )
opacityToStyle op =
    ( "opacity", String.fromFloat (Opacity.toFloat op) )


{-| Update animation state with data received from JavaScript via ports.

This function processes animation update data received from the JavaScript WAAPI
integration and updates the internal animation state accordingly.

    case msg of
        ReceiveWAAPI value ->
            { model | animations = WAAPI.update value model.animations }

-}
update : Decode.Value -> AnimState -> AnimState
update jsonValue (AnimState state) =
    case Decode.decodeValue animationUpdateDecoder jsonValue of
        Ok animationUpdate ->
            let
                updatedAnimations =
                    Dict.update animationUpdate.elementId
                        (Maybe.map (updateElementAnimation animationUpdate))
                        state.elementAnimations

                newState =
                    AnimState
                        { state
                            | elementAnimations = updatedAnimations
                            , isRunning = not (Dict.isEmpty updatedAnimations)
                        }
            in
            newState

        Err _ ->
            -- Silently ignore decode errors since we control the data shape
            AnimState state


type alias AnimationUpdate =
    { elementId : String
    , x : Maybe Float
    , y : Maybe Float
    , opacity : Maybe Float
    , rotation : Maybe Float
    , scaleX : Maybe Float
    , scaleY : Maybe Float
    , backgroundColor : Maybe String
    , isAnimating : Bool
    }


animationUpdateDecoder : Decoder AnimationUpdate
animationUpdateDecoder =
    -- For now, just handle the basic position update format that JavaScript sends
    Decode.map4
        (\elementId x y isAnimating ->
            { elementId = elementId
            , x = x
            , y = y
            , opacity = Nothing
            , rotation = Nothing
            , scaleX = Nothing
            , scaleY = Nothing
            , backgroundColor = Nothing
            , isAnimating = isAnimating
            }
        )
        (Decode.field "elementId" Decode.string)
        (Decode.maybe (Decode.field "x" Decode.float))
        (Decode.maybe (Decode.field "y" Decode.float))
        (Decode.field "isAnimating" Decode.bool)


updateElementAnimation : AnimationUpdate -> ElementAnimation -> ElementAnimation
updateElementAnimation animUpdate elementAnimation =
    let
        currentEndStates =
            elementAnimation.endStates

        updatedEndStates =
            { currentEndStates
                | position =
                    case ( animUpdate.x, animUpdate.y ) of
                        ( Just x, Just y ) ->
                            Just (Position.fromTuple ( x, y ))

                        ( Just x, Nothing ) ->
                            currentEndStates.position
                                |> Maybe.map (\pos -> Position.fromTuple ( x, Position.toTuple pos |> Tuple.second ))
                                |> Maybe.withDefault (Position.fromTuple ( x, 0 ))
                                |> Just

                        ( Nothing, Just y ) ->
                            currentEndStates.position
                                |> Maybe.map (\pos -> Position.fromTuple ( Position.toTuple pos |> Tuple.first, y ))
                                |> Maybe.withDefault (Position.fromTuple ( 0, y ))
                                |> Just

                        ( Nothing, Nothing ) ->
                            currentEndStates.position
                , opacity =
                    case animUpdate.opacity of
                        Just opacityValue ->
                            Just (Opacity.fromFloat opacityValue)

                        Nothing ->
                            currentEndStates.opacity
                , rotate =
                    case animUpdate.rotation of
                        Just rotationValue ->
                            Just (Rotate.fromFloat rotationValue)

                        Nothing ->
                            currentEndStates.rotate
                , scale =
                    case ( animUpdate.scaleX, animUpdate.scaleY ) of
                        ( Just x, Just y ) ->
                            Just (Scale.fromTuple ( x, y ))

                        ( Just x, Nothing ) ->
                            currentEndStates.scale
                                |> Maybe.map (\scl -> Scale.fromTuple ( x, Scale.toTuple scl |> Tuple.second ))
                                |> Maybe.withDefault (Scale.fromTuple ( x, 1 ))
                                |> Just

                        ( Nothing, Just y ) ->
                            currentEndStates.scale
                                |> Maybe.map (\scl -> Scale.fromTuple ( Scale.toTuple scl |> Tuple.first, y ))
                                |> Maybe.withDefault (Scale.fromTuple ( 1, y ))
                                |> Just

                        ( Nothing, Nothing ) ->
                            currentEndStates.scale
                , color =
                    case animUpdate.backgroundColor of
                        Just colorString ->
                            Just (Color.hex colorString)

                        Nothing ->
                            currentEndStates.color
            }
    in
    { elementAnimation | endStates = updatedEndStates }
