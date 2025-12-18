module Anim.Internal.Ports exposing
    ( TargetId
    , init, builder, animate, AnimationState
    , getPosition, getCurrentStyles
    , htmlAttributes
    , delay, duration, easing, speed
    )

{-| Ports-based animation system for Anim.

This module converts AnimBuilder configurations to JavaScript Web Animations API
commands via Elm ports for high-performance, platform-optimized animations.


# Animation Execution

@docs TargetId


# State Management

@docs init, builder, animate, AnimationState


# Animation Data

@docs getPosition, getCurrentStyles


# JavaScript Integration

@docs htmlAttributes

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
import Html
import Html.Attributes
import Json.Encode as Encode


type alias AnimBuilder =
    Builder.AnimBuilder



-- ANIMATION STATE


{-| State for managing ports-based animations.
-}
type AnimationState
    = AnimationState
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
init : AnimationState
init =
    AnimationState
        { elementAnimations = Dict.empty
        , isRunning = False
        , builder = Builder.init
        }


{-| Turn the AnimationState into an AnimBuilder with current state preserved.
-}
builder : AnimationState -> AnimBuilder
builder (AnimationState state) =
    state.builder


{-| Create animation command with state tracking.
-}
animate : AnimationState -> AnimBuilder -> ( AnimationState, Encode.Value )
animate (AnimationState state) builder_ =
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

        newAnimationState =
            AnimationState
                { elementAnimations = updatedElementAnimations
                , isRunning = not (Dict.isEmpty newElementAnimations)
                , builder = Builder.markDirty builder_
                }

        encodedData =
            Builder.encode processedData
    in
    ( newAnimationState, encodedData )


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
getPosition : String -> AnimationState -> Maybe Position
getPosition elementId (AnimationState state) =
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
getCurrentStyles : String -> AnimationState -> List ( String, String )
getCurrentStyles elementId (AnimationState state) =
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
        ( x, y ) =
            Position.toTuple pos
    in
    "translate(" ++ String.fromFloat x ++ "px, " ++ String.fromFloat y ++ "px)"


rotateToTransform : Rotate -> String
rotateToTransform rot =
    "rotate(" ++ String.fromFloat (Rotate.toFloat rot) ++ "deg)"


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


{-| Generate HTML attributes for ports-based animations.

This function provides a way to add animation data attributes to elements,
which can be useful for debugging or JavaScript integration.

-}
htmlAttributes : String -> AnimationState -> List (Html.Attribute msg)
htmlAttributes elementId (AnimationState state) =
    case Dict.get elementId state.elementAnimations of
        Nothing ->
            []

        Just _ ->
            [ Html.Attributes.attribute "data-animation-state" "ports"
            , Html.Attributes.attribute "data-element-id" elementId
            ]
