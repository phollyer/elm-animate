module Anim.Internal.CSS exposing
    ( AnimBuilder
    , AnimState
    , TransformOrder(..)
    , animate
    , animateWithOrder
    , animationStyleAttribute
    , builder
    , delay
    , duration
    , easing
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
    , speed
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.CSS.KeyframeAnimation as KeyframeAnimation exposing (KeyframeAnimation)
import Anim.Internal.CSS.Transform as Transforms
import Anim.Internal.CSS.Transition as Transitions
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position exposing (Position)
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


type AnimState
    = AnimState
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


init : AnimState
init =
    AnimState
        { elementAnimations = Dict.empty
        , isRunning = False
        , builder = Builder.init
        }


builder : AnimState -> AnimBuilder
builder (AnimState state) =
    state.builder


animate : AnimBuilder -> AnimState
animate builder_ =
    AnimState
        { elementAnimations =
            builder_
                |> Builder.elements
                |> Dict.map (generateElementAnimation Nothing)
        , builder = Builder.markDirty builder_
        , isRunning = True
        }


{-| Apply animation with custom transform ordering.
-}
animateWithOrder : List TransformOrder -> AnimBuilder -> AnimState
animateWithOrder order builder_ =
    AnimState
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
isRunning : AnimState -> Bool
isRunning (AnimState state) =
    state.isRunning


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
