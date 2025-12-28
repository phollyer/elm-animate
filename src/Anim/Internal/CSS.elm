module Anim.Internal.CSS exposing
    ( AnimBuilder
    , AnimState
    , ElementState(..)
    , Event(..)
    , TransformOrder(..)
    , allComplete
    , animate
    , animateWithOrder
    , animationStyleAttribute
    , anyRunning
    , builder
    , containerStyles
    , delay
    , duration
    , easing
    , getBackgroundColorRange
    , getElementAnimation
    , getElementKeyframes
    , getOpacityRange
    , getPosition
    , getPositionAnimationDuration
    , getPositionRange
    , getRotateRange
    , getScaleRange
    , getSizeRange
    , getStartPosition
    , getState
    , handleEvent
    , htmlAttributes
    , init
    , isElementComplete
    , isElementRunning
    , keyframesStyleNode
    , keyframesStyleNodeFor
    , onAnimationCancel
    , onAnimationEnd
    , onAnimationIteration
    , onAnimationStart
    , onTransitionCancel
    , onTransitionEnd
    , onTransitionRun
    , onTransitionStart
    , perspective
    , speed
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.CSS.KeyframeAnimation as KeyframeAnimation exposing (KeyframeAnimation)
import Anim.Internal.CSS.Transform as Transforms
import Anim.Internal.CSS.Transition as Transitions
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position exposing (Position)
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Timing.Easing exposing (Easing)
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode


type alias AnimBuilder =
    Builder.AnimBuilder



-- TYPES


{-| Transform property ordering for CSS generation.
-}
type TransformOrder
    = Position
    | Rotate
    | Scale


{-| Convert TransformOrder to string for the transform generation.
-}
transformOrderToString : TransformOrder -> String
transformOrderToString order =
    case order of
        Position ->
            "position"

        Rotate ->
            "rotate"

        Scale ->
            "scale"


{-| Individual element animation lifecycle state.
-}
type ElementState
    = NotStarted
    | Running
    | Complete


{-| Animation lifecycle events.
-}
type Event
    = AnimationStarted String
    | AnimationEnded String
    | AnimationCancelled String
    | AnimationIteration String
    | TransitionStarted String
    | TransitionEnded String
    | TransitionRun String
    | TransitionCancelled String


type AnimState
    = AnimState
        { elementAnimations : Dict ElementId ElementAnimation
        , elementStates : Dict ElementId ElementState
        , builder : AnimBuilder
        }


type alias ElementId =
    String


type alias ElementAnimation =
    { styles : List ( String, String )
    , animationLayers : List KeyframeAnimation
    }


init : AnimState
init =
    AnimState
        { elementAnimations = Dict.empty
        , elementStates = Dict.empty
        , builder = Builder.init
        }


builder : AnimState -> AnimBuilder
builder (AnimState state) =
    state.builder


animate : AnimBuilder -> AnimState
animate builder_ =
    let
        elementIds =
            builder_
                |> Builder.elements
                |> Dict.keys
    in
    AnimState
        { elementAnimations =
            builder_
                |> Builder.elements
                |> Dict.map (generateElementAnimation Nothing)
        , elementStates =
            elementIds
                |> List.map (\id -> ( id, NotStarted ))
                |> Dict.fromList
        , builder = Builder.markDirty builder_
        }


{-| Apply animation with custom transform ordering.
-}
animateWithOrder : List TransformOrder -> AnimBuilder -> AnimState
animateWithOrder order builder_ =
    let
        elementIds =
            builder_
                |> Builder.elements
                |> Dict.keys
    in
    AnimState
        { elementAnimations =
            builder_
                |> Builder.elements
                |> Dict.map (generateElementAnimation (Just order))
        , elementStates =
            elementIds
                |> List.map (\id -> ( id, NotStarted ))
                |> Dict.fromList
        , builder = Builder.markDirty builder_
        }



-- CSS GENERATION


generateElementAnimation : Maybe (List TransformOrder) -> String -> Builder.ElementConfig -> ElementAnimation
generateElementAnimation maybeOrder elementId elementConfig =
    let
        transforms =
            case maybeOrder of
                Nothing ->
                    -- Use default ordering: Position -> Rotate -> Scale
                    Transforms.generate elementConfig.properties

                Just order ->
                    -- Use custom ordering
                    let
                        orderStrings =
                            List.map transformOrderToString order
                    in
                    Transforms.generateWithOrder orderStrings elementConfig.properties

        transitions =
            Transitions.generate elementConfig.properties

        colorStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.BackgroundColorConfig config ->
                            Just ( "background-color", BackgroundColor.toString config.endAt )

                        _ ->
                            Nothing
                )
                elementConfig.properties

        opacityStyles =
            List.filterMap
                (\prop ->
                    case prop of
                        Builder.OpacityConfig config ->
                            Just ( "opacity", Opacity.toString config.endAt )

                        _ ->
                            Nothing
                )
                elementConfig.properties

        allStyles =
            [ ( "transform", transforms )
            , ( "transition", transitions )
            ]
                ++ colorStyles
                ++ opacityStyles
                |> List.filter (\( _, value ) -> not (String.isEmpty value))
    in
    { styles = allStyles
    , animationLayers = KeyframeAnimation.generate elementId elementConfig.properties
    }


animationStyleAttribute : String -> AnimState -> Html.Attribute msg
animationStyleAttribute elementId animationState =
    case getElementAnimation elementId animationState of
        Just elementAnimation ->
            let
                animationValues =
                    KeyframeAnimation.toAttributeString elementAnimation.animationLayers
            in
            Html.Attributes.style "animation" animationValues

        Nothing ->
            Html.Attributes.style "animation" ""


keyframesStyleNode : AnimState -> Html msg
keyframesStyleNode (AnimState state) =
    let
        allKeyframes =
            Dict.values state.elementAnimations
                |> List.concatMap .animationLayers
                |> List.map .keyframes
                |> String.join "\n\n"
    in
    if String.isEmpty allKeyframes then
        Html.text ""

    else
        Html.node "style" [] [ Html.text allKeyframes ]


keyframesStyleNodeFor : String -> AnimState -> Html msg
keyframesStyleNodeFor elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Just elementAnimation ->
            if List.isEmpty elementAnimation.animationLayers then
                Html.text ""

            else
                let
                    elementKeyframes =
                        elementAnimation.animationLayers
                            |> List.map .keyframes
                            |> String.join "\n\n"
                in
                Html.node "style" [] [ Html.text elementKeyframes ]

        Nothing ->
            Html.text ""


getElementAnimation : String -> AnimState -> Maybe ElementAnimation
getElementAnimation elementId (AnimState state) =
    Dict.get elementId state.elementAnimations


getElementKeyframes : String -> AnimState -> Maybe String
getElementKeyframes elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen
            (\elementAnimation ->
                if List.isEmpty elementAnimation.animationLayers then
                    Nothing

                else
                    elementAnimation.animationLayers
                        |> List.map .keyframes
                        |> String.join "\n\n"
                        |> Just
            )


getPosition : String -> AnimState -> Maybe Position
getPosition elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedPositionConfig config ->
                                    Just config.endAt

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get the starting position for an element's animation.
Returns Nothing if the element has no position animation or no explicit start position.
-}
getStartPosition : String -> AnimState -> Maybe Position
getStartPosition elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedPositionConfig config ->
                                    config.startAt

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


getState : String -> AnimState -> Maybe ElementState
getState elementId (AnimState state) =
    Dict.get elementId state.elementStates


{-| Get both start and end positions for an element's animation.
Returns Nothing if the element has no position animation.
-}
getPositionRange : String -> AnimState -> Maybe { start : Maybe Position, end : Position }
getPositionRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedPositionConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end scales for an element's animation.
Returns Nothing if the element has no scale animation.
-}
getScaleRange : String -> AnimState -> Maybe { start : Maybe Scale.Scale, end : Scale.Scale }
getScaleRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedScaleConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end rotations for an element's animation.
Returns Nothing if the element has no rotate animation.
-}
getRotateRange : String -> AnimState -> Maybe { start : Maybe Rotate.Rotate, end : Rotate.Rotate }
getRotateRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedRotateConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end background colors for an element's animation.
Returns Nothing if the element has no background color animation.
-}
getBackgroundColorRange : String -> AnimState -> Maybe { start : Maybe BackgroundColor.Color, end : BackgroundColor.Color }
getBackgroundColorRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedBackgroundColorConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end opacity for an element's animation.
Returns Nothing if the element has no opacity animation.
-}
getOpacityRange : String -> AnimState -> Maybe { start : Maybe Opacity.Opacity, end : Opacity.Opacity }
getOpacityRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedOpacityConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get both start and end sizes for an element's animation.
Returns Nothing if the element has no size animation.
-}
getSizeRange : String -> AnimState -> Maybe { start : Maybe Size.Size, end : Size.Size }
getSizeRange elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedSizeConfig config ->
                                    Just { start = config.startAt, end = config.endAt }

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Get the animation duration for a position animation in milliseconds.
Returns Nothing if the element has no position animation.
-}
getPositionAnimationDuration : String -> AnimState -> Maybe Int
getPositionAnimationDuration elementId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder
    in
    Dict.get elementId processedData.elements
        |> Maybe.andThen
            (\elementConfig ->
                elementConfig.properties
                    |> List.filterMap
                        (\prop ->
                            case prop of
                                Builder.ProcessedPositionConfig config ->
                                    Just config.duration

                                _ ->
                                    Nothing
                        )
                    |> List.head
            )


{-| Check if any animations are currently running.
-}
anyRunning : AnimState -> Bool
anyRunning (AnimState state) =
    case Dict.values state.elementStates of
        [] ->
            False

        values ->
            List.any (\elementState -> elementState == Running) values


{-| Check if all animations are complete.
-}
allComplete : AnimState -> Maybe Bool
allComplete (AnimState state) =
    if Dict.isEmpty state.elementStates then
        Nothing

    else
        state.elementStates
            |> Dict.values
            |> List.all (\elementState -> elementState == Complete)
            |> Just


{-| Check if a specific element has any animations currently running.
-}
isElementRunning : String -> AnimState -> Bool
isElementRunning elementId (AnimState state) =
    Dict.get elementId state.elementStates == Just Running


{-| Check if a specific element's animations have completed.
-}
isElementComplete : String -> AnimState -> Maybe Bool
isElementComplete elementId (AnimState state) =
    Dict.get elementId state.elementStates
        |> Maybe.map
            (\elementState ->
                case elementState of
                    Complete ->
                        True

                    _ ->
                        False
            )


{-| Handle animation lifecycle events to update element states.
-}
handleEvent : Event -> AnimState -> AnimState
handleEvent event (AnimState state) =
    let
        ( elementId, newElementState ) =
            case event of
                AnimationStarted id ->
                    ( id, Running )

                AnimationEnded id ->
                    ( id, Complete )

                AnimationCancelled id ->
                    ( id, Complete )

                AnimationIteration id ->
                    ( id, Running )

                TransitionStarted id ->
                    ( id, Running )

                TransitionEnded id ->
                    ( id, Complete )

                TransitionRun id ->
                    ( id, Running )

                TransitionCancelled id ->
                    ( id, Complete )
    in
    AnimState
        { state
            | elementStates =
                Dict.insert elementId newElementState state.elementStates
        }


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


perspective : String -> Float -> AnimBuilder -> AnimBuilder
perspective =
    Builder.perspective


containerStyles : String -> AnimState -> List (Html.Attribute msg)
containerStyles containerId animationState =
    getContainerPerspectiveStyles containerId animationState


getContainerPerspectiveStyles : String -> AnimState -> List (Html.Attribute msg)
getContainerPerspectiveStyles targetContainerId (AnimState state) =
    let
        processedData =
            Builder.processAnimationData state.builder

        -- Check if any elements use this containerId for perspective
        perspectiveValues =
            processedData.elements
                |> Dict.values
                |> List.concatMap .properties
                |> List.filterMap extractPerspectiveFromProperty
                |> List.filter (\{ containerId, value } -> containerId == targetContainerId)
                |> List.map .value
                |> List.head

        globalPerspective =
            processedData.globalPerspective
                |> Maybe.andThen
                    (\{ containerId, value } ->
                        if containerId == targetContainerId then
                            Just value

                        else
                            Nothing
                    )

        perspectiveValue =
            case perspectiveValues of
                Just value ->
                    Just value

                Nothing ->
                    globalPerspective
    in
    case perspectiveValue of
        Just value ->
            [ Html.Attributes.style "perspective" (String.fromFloat value ++ "px")
            , Html.Attributes.style "transform-style" "preserve-3d"
            ]

        Nothing ->
            []


extractPerspectiveFromProperty : Builder.ProcessedPropertyConfig -> Maybe { containerId : String, value : Float }
extractPerspectiveFromProperty property =
    case property of
        Builder.ProcessedPositionConfig config ->
            config.perspective

        Builder.ProcessedRotateConfig config ->
            config.perspective

        Builder.ProcessedScaleConfig config ->
            config.perspective

        _ ->
            Nothing


htmlAttributes : String -> AnimState -> List (Html.Attribute msg)
htmlAttributes elementId animationResult =
    getElementStyles elementId animationResult
        |> List.map (\( prop, value ) -> Html.Attributes.style prop value)


getElementStyles : String -> AnimState -> List ( String, String )
getElementStyles elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.map .styles
        |> Maybe.withDefault []



-- CSS TRANSITION EVENT HANDLERS


onTransitionStart : msg -> Html.Attribute msg
onTransitionStart msg =
    Html.Events.on "transitionstart" (Json.Decode.succeed msg)


onTransitionEnd : msg -> Html.Attribute msg
onTransitionEnd msg =
    Html.Events.on "transitionend" (Json.Decode.succeed msg)


onTransitionRun : msg -> Html.Attribute msg
onTransitionRun msg =
    Html.Events.on "transitionrun" (Json.Decode.succeed msg)


onTransitionCancel : msg -> Html.Attribute msg
onTransitionCancel msg =
    Html.Events.on "transitioncancel" (Json.Decode.succeed msg)



-- CSS ANIMATION EVENT HANDLERS


onAnimationStart : msg -> Html.Attribute msg
onAnimationStart msg =
    Html.Events.on "animationstart" (Json.Decode.succeed msg)


onAnimationEnd : msg -> Html.Attribute msg
onAnimationEnd msg =
    Html.Events.on "animationend" (Json.Decode.succeed msg)


onAnimationIteration : msg -> Html.Attribute msg
onAnimationIteration msg =
    Html.Events.on "animationiteration" (Json.Decode.succeed msg)


onAnimationCancel : msg -> Html.Attribute msg
onAnimationCancel msg =
    Html.Events.on "animationcancel" (Json.Decode.succeed msg)
