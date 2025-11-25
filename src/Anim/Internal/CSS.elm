module Anim.Internal.CSS exposing
    ( AnimationState
    , TransformOrder(..)
    , animate
    , animateWithOrder
    , animationStyleAttribute
    , builder
    , getElementAnimation
    , getElementKeyframes
    , getPosition
    , getPositionAnimationDuration
    , getPositionRange
    , getStartPosition
    , htmlAttributes
    , init
    , isRunning
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
    )

import Anim exposing (AnimBuilder)
import Anim.Internal.Builder as Builder
import Anim.Internal.CSS.KeyframeAnimation as KeyframeAnimation exposing (KeyframeAnimation)
import Anim.Internal.CSS.Transform as Transforms
import Anim.Internal.CSS.Transition as Transitions
import Anim.Internal.Properties.Color as Color
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position exposing (Position)
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode



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


type AnimationState
    = AnimationState
        { elementAnimations : Dict ElementId ElementAnimation
        , isRunning : Bool
        , builder : AnimBuilder
        }


type alias ElementId =
    String


type alias ElementAnimation =
    { styles : List ( String, String )
    , animationLayers : List KeyframeAnimation
    }


init : AnimationState
init =
    AnimationState
        { elementAnimations = Dict.empty
        , isRunning = False
        , builder = Anim.init
        }


builder : AnimationState -> AnimBuilder
builder (AnimationState state) =
    state.builder


animate : AnimBuilder -> AnimationState
animate builder_ =
    AnimationState
        { elementAnimations =
            builder_
                |> Builder.elements
                |> Dict.map (generateElementAnimation Nothing)
        , builder = Builder.markDirty builder_
        , isRunning = True
        }


{-| Apply animation with custom transform ordering.
-}
animateWithOrder : List TransformOrder -> AnimBuilder -> AnimationState
animateWithOrder order builder_ =
    AnimationState
        { elementAnimations =
            builder_
                |> Builder.elements
                |> Dict.map (generateElementAnimation (Just order))
        , builder = Builder.markDirty builder_
        , isRunning = True
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
                            Just ( "background-color", Color.toString config.endAt )

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


animationStyleAttribute : String -> AnimationState -> Html.Attribute msg
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


keyframesStyleNode : AnimationState -> Html msg
keyframesStyleNode (AnimationState state) =
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


keyframesStyleNodeFor : String -> AnimationState -> Html msg
keyframesStyleNodeFor elementId (AnimationState state) =
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


getElementAnimation : String -> AnimationState -> Maybe ElementAnimation
getElementAnimation elementId (AnimationState state) =
    Dict.get elementId state.elementAnimations


getElementKeyframes : String -> AnimationState -> Maybe String
getElementKeyframes elementId (AnimationState state) =
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


getPosition : String -> AnimationState -> Maybe Position
getPosition elementId (AnimationState state) =
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
getStartPosition : String -> AnimationState -> Maybe Position
getStartPosition elementId (AnimationState state) =
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


{-| Get both start and end positions for an element's animation.
Returns Nothing if the element has no position animation.
-}
getPositionRange : String -> AnimationState -> Maybe { start : Maybe Position, end : Position }
getPositionRange elementId (AnimationState state) =
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


{-| Get the animation duration for a position animation in milliseconds.
Returns Nothing if the element has no position animation.
-}
getPositionAnimationDuration : String -> AnimationState -> Maybe Int
getPositionAnimationDuration elementId (AnimationState state) =
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
isRunning : AnimationState -> Bool
isRunning (AnimationState state) =
    state.isRunning


htmlAttributes : String -> AnimationState -> List (Html.Attribute msg)
htmlAttributes elementId animationResult =
    getElementStyles elementId animationResult
        |> List.map (\( prop, value ) -> Html.Attributes.style prop value)


getElementStyles : String -> AnimationState -> List ( String, String )
getElementStyles elementId (AnimationState state) =
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
