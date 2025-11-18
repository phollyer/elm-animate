module Anim.Internal.CSS exposing (..)

import Anim exposing (AnimBuilder)
import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.Color as Color
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position as Position
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Timing.Delay as Delay
import Anim.Internal.Timing.Easing as Easing
import Anim.Internal.Timing.TimeSpec as TimeSpec
import Browser exposing (UrlRequest(..))
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode


type AnimationState
    = AnimationState
        { elementAnimations : Dict ElementId ElementAnimation
        , builder : AnimBuilder -- Store original builder for automatic state queries
        }


type alias ElementId =
    String


{-| CSS animation data for a single element with support for multiple simultaneous animations.
-}
type alias ElementAnimation =
    { elementId : ElementId
    , styles : List ( String, String )
    , animationLayers : List AnimationLayer
    }


{-| Individual animation layer that can run independently.
-}
type alias AnimationLayer =
    { animationName : String
    , keyframes : String
    , duration : Int
    , easing : String
    , delay : Int
    , properties : List String -- Properties this layer animates
    }


init : AnimationState
init =
    AnimationState
        { elementAnimations = Dict.empty
        , builder = Anim.init
        }


builder : AnimationState -> AnimBuilder
builder (AnimationState state) =
    state.builder


animate : AnimBuilder -> AnimationState
animate builder_ =
    let
        elementsDict =
            Builder.elements builder_

        elementAnimations =
            elementsDict
                |> Dict.map generateElementAnimation
    in
    AnimationState
        { elementAnimations = elementAnimations
        , builder = builder_ -- Store builder for automatic queries
        }



-- CSS GENERATION


generateElementAnimation : String -> Builder.ElementConfig -> ElementAnimation
generateElementAnimation elementId elementConfig =
    let
        transforms =
            generateTransforms elementConfig.properties

        transitions =
            generateTransitions elementConfig.properties

        colors =
            generateColorStyles elementConfig.properties

        allStyles =
            [ ( "transform", transforms )
            , ( "transition", transitions )
            ]
                ++ colors
                |> List.filter (\( _, value ) -> not (String.isEmpty value))

        animationLayers =
            generateAnimationLayers elementId elementConfig.properties
    in
    { elementId = elementId
    , styles = allStyles
    , animationLayers = animationLayers
    }


generateTransforms : List Builder.PropertyConfig -> String
generateTransforms properties =
    let
        transformParts =
            List.filterMap transformFromProperty properties
    in
    String.join " " transformParts


transformFromProperty : Builder.PropertyConfig -> Maybe String
transformFromProperty property =
    case property of
        Builder.PositionConfig config ->
            Just ("translate(" ++ Position.toCssString config.endAt ++ ")")

        Builder.RotateConfig config ->
            Just ("rotate(" ++ Rotate.toCssString config.endAt ++ ")")

        Builder.ScaleConfig config ->
            Just ("scale(" ++ Scale.toCssString config.endAt ++ ")")

        Builder.ColorConfig _ ->
            -- Color doesn't use transform
            Nothing

        Builder.OpacityConfig _ ->
            -- Opacity doesn't use transform
            Nothing



-- CSS TRANSITIONS


generateTransitions : List Builder.PropertyConfig -> String
generateTransitions properties =
    let
        -- Group properties by CSS property type
        transformProperties =
            List.filter isTransformProperty properties

        nonTransformTransitions =
            List.filterMap transitionFromNonTransformProperty properties

        -- Generate single consolidated transform transition
        transformTransition =
            case consolidateTransformTiming transformProperties of
                Just transition ->
                    [ transition ]

                Nothing ->
                    []

        allTransitions =
            transformTransition ++ nonTransformTransitions
    in
    String.join ", " allTransitions


isTransformProperty : Builder.PropertyConfig -> Bool
isTransformProperty property =
    case property of
        Builder.PositionConfig _ ->
            True

        Builder.RotateConfig _ ->
            True

        Builder.ScaleConfig _ ->
            True

        _ ->
            False


transitionFromNonTransformProperty : Builder.PropertyConfig -> Maybe String
transitionFromNonTransformProperty property =
    case property of
        Builder.ColorConfig config ->
            let
                distance =
                    calculatePropertyDistance (Builder.ColorConfig config)
            in
            Just ("background-color " ++ TimeSpec.toCssString distance config.timing ++ " " ++ Easing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        Builder.OpacityConfig config ->
            let
                distance =
                    calculatePropertyDistance (Builder.OpacityConfig config)
            in
            Just ("opacity " ++ TimeSpec.toCssString distance config.timing ++ " " ++ Easing.toCSS config.easing ++ " " ++ Delay.toCssString config.delay)

        _ ->
            Nothing


consolidateTransformTiming : List Builder.PropertyConfig -> Maybe String
consolidateTransformTiming transformProps =
    case transformProps of
        [] ->
            Nothing

        _ ->
            let
                -- Strategy: Use the longest duration, latest easing, earliest delay
                longestDistance =
                    findLongestDistance transformProps

                longestDuration =
                    findLongestDuration transformProps

                latestEasing =
                    findLatestEasing transformProps

                earliestDelay =
                    findEarliestDelay transformProps
            in
            Just ("transform " ++ TimeSpec.toCssString longestDistance longestDuration ++ " " ++ Easing.toCSS (Just latestEasing) ++ " " ++ Delay.toCssString earliestDelay)


findLongestDistance : List Builder.PropertyConfig -> Float
findLongestDistance properties =
    let
        distances =
            List.filterMap extractDistance properties
    in
    case distances of
        [] ->
            0.0

        _ ->
            distances
                |> List.maximum
                |> Maybe.withDefault 0.0


extractDistance : Builder.PropertyConfig -> Maybe Float
extractDistance property =
    case property of
        Builder.PositionConfig config ->
            Just config.distance

        Builder.RotateConfig config ->
            Just config.distance

        Builder.ScaleConfig config ->
            Just config.distance

        _ ->
            Nothing


calculatePropertyDistance : Builder.PropertyConfig -> Float
calculatePropertyDistance property =
    case property of
        Builder.PositionConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Position.fromTuple ( 0, 0 )
            in
            Position.distance startAt config.endAt

        Builder.RotateConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Rotate.fromFloat 0
            in
            Rotate.distance startAt config.endAt

        Builder.ScaleConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Scale.fromTuple ( 1, 1 )
            in
            Scale.distance startAt config.endAt

        Builder.ColorConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Color.rgb255 0 0 0
            in
            Color.distance startAt config.endAt

        Builder.OpacityConfig config ->
            let
                startAt =
                    case config.startAt of
                        Just s ->
                            s

                        Nothing ->
                            Opacity.fromFloat 1.0
            in
            Opacity.distance startAt config.endAt


findLongestDuration : List Builder.PropertyConfig -> Maybe TimeSpec.TimeSpec
findLongestDuration properties =
    let
        propertyDistances =
            List.filterMap
                (\prop ->
                    extractTiming prop
                        |> Maybe.map (\timeSpec -> ( timeSpec, calculatePropertyDistance prop ))
                )
                properties
    in
    case propertyDistances of
        [] ->
            Nothing

        ( firstTimeSpec, _ ) :: rest ->
            rest
                |> List.foldl
                    (\( timeSpec, dist ) acc ->
                        chooseLongerDuration (\ts -> toFloat (TimeSpec.duration dist ts)) timeSpec acc
                    )
                    firstTimeSpec
                |> Just


chooseLongerDuration : (TimeSpec.TimeSpec -> Float) -> TimeSpec.TimeSpec -> TimeSpec.TimeSpec -> TimeSpec.TimeSpec
chooseLongerDuration calcDuration a b =
    let
        durationA =
            calcDuration a

        durationB =
            calcDuration b
    in
    if durationA >= durationB then
        a

    else
        b



-- Slower speed = longer duration


findLatestEasing : List Builder.PropertyConfig -> Easing.Easing
findLatestEasing properties =
    properties
        |> List.filterMap extractEasing
        |> List.reverse
        -- Get the last one added
        |> List.head
        |> Maybe.withDefault Easing.Linear


findEarliestDelay : List Builder.PropertyConfig -> Maybe Int
findEarliestDelay properties =
    let
        delays =
            List.filterMap extractDelay properties
    in
    case delays of
        [] ->
            Nothing

        _ ->
            delays
                |> List.foldl chooseSmallerDelay 999999
                -- Start with large delay
                |> Just


chooseSmallerDelay : Int -> Int -> Int
chooseSmallerDelay a b =
    if a <= b then
        a

    else
        b


extractTiming : Builder.PropertyConfig -> Maybe TimeSpec.TimeSpec
extractTiming property =
    case property of
        Builder.PositionConfig config ->
            config.timing

        Builder.RotateConfig config ->
            config.timing

        Builder.ScaleConfig config ->
            config.timing

        _ ->
            Nothing


extractEasing : Builder.PropertyConfig -> Maybe Easing.Easing
extractEasing property =
    case property of
        Builder.PositionConfig config ->
            config.easing

        Builder.RotateConfig config ->
            config.easing

        Builder.ScaleConfig config ->
            config.easing

        _ ->
            Nothing


extractDelay : Builder.PropertyConfig -> Maybe Int
extractDelay property =
    case property of
        Builder.PositionConfig config ->
            config.delay

        Builder.RotateConfig config ->
            config.delay

        Builder.ScaleConfig config ->
            config.delay

        _ ->
            Nothing


generateColorStyles : List Builder.PropertyConfig -> List ( String, String )
generateColorStyles properties =
    List.filterMap colorStyleFromProperty properties


colorStyleFromProperty : Builder.PropertyConfig -> Maybe ( String, String )
colorStyleFromProperty property =
    case property of
        Builder.ColorConfig config ->
            Just ( "background-color", Color.toString config.endAt )

        Builder.OpacityConfig config ->
            Just ( "opacity", Opacity.toString config.endAt )

        _ ->
            Nothing


{-| Generate animation layers for an element's properties, supporting multiple simultaneous animations.
-}
generateAnimationLayers : String -> List Builder.PropertyConfig -> List AnimationLayer
generateAnimationLayers elementId properties =
    if List.isEmpty properties then
        []

    else
        let
            -- Group properties by timing characteristics
            timingGroups =
                groupPropertiesByTiming properties

            -- Create separate animation layers for different timing groups
            layersFromGroups =
                timingGroups
                    |> List.indexedMap (createAnimationLayerFromGroup elementId)
                    |> List.filterMap identity
        in
        layersFromGroups


{-| Create an animation layer from a timing group.
-}
createAnimationLayerFromGroup : String -> Int -> TimingGroup -> Maybe AnimationLayer
createAnimationLayerFromGroup elementId layerIndex timingGroup =
    let
        keyframeSteps =
            generateTimedKeyframeSteps timingGroup timingGroup.properties

        animationName =
            elementId ++ "-layer-" ++ String.fromInt layerIndex ++ "-animation"

        keyframesString =
            buildKeyframesString animationName keyframeSteps (Just timingGroup)

        animatedProperties =
            extractAnimatedProperties timingGroup.properties
    in
    if List.isEmpty keyframeSteps then
        Nothing

    else
        Just
            { animationName = animationName
            , keyframes = keyframesString
            , duration = timingGroup.duration
            , easing = Easing.toCSS (Just timingGroup.easing)
            , delay = timingGroup.delay
            , properties = animatedProperties
            }


{-| Extract the CSS property names that are animated by a list of property configs.
-}
extractAnimatedProperties : List Builder.PropertyConfig -> List String
extractAnimatedProperties properties =
    List.filterMap
        (\property ->
            case property of
                Builder.PositionConfig _ ->
                    Just "transform"

                Builder.RotateConfig _ ->
                    Just "transform"

                Builder.ScaleConfig _ ->
                    Just "transform"

                Builder.ColorConfig _ ->
                    Just "background-color"

                Builder.OpacityConfig _ ->
                    Just "opacity"
        )
        properties
        |> removeDuplicates


{-| Remove duplicate strings from a list.
-}
removeDuplicates : List String -> List String
removeDuplicates list =
    case list of
        [] ->
            []

        x :: xs ->
            if List.member x xs then
                removeDuplicates xs

            else
                x :: removeDuplicates xs


groupPropertiesByTiming : List Builder.PropertyConfig -> List TimingGroup
groupPropertiesByTiming properties =
    properties
        |> List.filterMap extractPropertyTiming
        |> List.foldl groupByTiming []
        |> List.map (\group -> { group | properties = List.reverse group.properties })


extractPropertyTiming : Builder.PropertyConfig -> Maybe ( TimingInfo, Builder.PropertyConfig )
extractPropertyTiming property =
    case property of
        Builder.PositionConfig config ->
            config.timing
                |> Maybe.map
                    (\timing ->
                        let
                            distance =
                                calculatePropertyDistance property

                            duration_ =
                                TimeSpec.duration distance timing

                            easing_ =
                                Maybe.withDefault Easing.Linear config.easing

                            delay_ =
                                Maybe.withDefault 0 config.delay
                        in
                        ( { duration = duration_, easing = easing_, delay = delay_ }, property )
                    )

        Builder.RotateConfig config ->
            config.timing
                |> Maybe.map
                    (\timing ->
                        let
                            distance =
                                calculatePropertyDistance property

                            duration_ =
                                TimeSpec.duration distance timing

                            easing_ =
                                Maybe.withDefault Easing.Linear config.easing

                            delay_ =
                                Maybe.withDefault 0 config.delay
                        in
                        ( { duration = duration_, easing = easing_, delay = delay_ }, property )
                    )

        Builder.ScaleConfig config ->
            config.timing
                |> Maybe.map
                    (\timing ->
                        let
                            distance =
                                calculatePropertyDistance property

                            duration_ =
                                TimeSpec.duration distance timing

                            easing_ =
                                Maybe.withDefault Easing.Linear config.easing

                            delay_ =
                                Maybe.withDefault 0 config.delay
                        in
                        ( { duration = duration_, easing = easing_, delay = delay_ }, property )
                    )

        Builder.ColorConfig config ->
            config.timing
                |> Maybe.map
                    (\timing ->
                        let
                            distance =
                                calculatePropertyDistance property

                            duration_ =
                                TimeSpec.duration distance timing

                            easing_ =
                                Maybe.withDefault Easing.Linear config.easing

                            delay_ =
                                Maybe.withDefault 0 config.delay
                        in
                        ( { duration = duration_, easing = easing_, delay = delay_ }, property )
                    )

        Builder.OpacityConfig config ->
            config.timing
                |> Maybe.map
                    (\timing ->
                        let
                            distance =
                                calculatePropertyDistance property

                            duration_ =
                                TimeSpec.duration distance timing

                            easing_ =
                                Maybe.withDefault Easing.Linear config.easing

                            delay_ =
                                Maybe.withDefault 0 config.delay
                        in
                        ( { duration = duration_, easing = easing_, delay = delay_ }, property )
                    )


type alias TimingInfo =
    { duration : Int
    , easing : Easing.Easing
    , delay : Int
    }


groupByTiming : ( TimingInfo, Builder.PropertyConfig ) -> List TimingGroup -> List TimingGroup
groupByTiming ( timing, property ) groups =
    case findMatchingGroup timing groups of
        Just group ->
            List.map
                (\g ->
                    if g == group then
                        { g | properties = property :: g.properties }

                    else
                        g
                )
                groups

        Nothing ->
            { duration = timing.duration
            , easing = timing.easing
            , delay = timing.delay
            , properties = [ property ]
            }
                :: groups


findMatchingGroup : TimingInfo -> List TimingGroup -> Maybe TimingGroup
findMatchingGroup timing groups =
    groups
        |> List.filter
            (\group ->
                group.duration
                    == timing.duration
                    && group.easing
                    == timing.easing
                    && group.delay
                    == timing.delay
            )
        |> List.head


{-| Generate keyframes with proper timing and easing distribution.
-}
generateTimedKeyframeSteps : TimingGroup -> List Builder.PropertyConfig -> List ( Float, List ( String, String ) )
generateTimedKeyframeSteps dominantGroup allProperties =
    let
        easingFunction =
            Easing.toFunction dominantGroup.easing

        -- Generate 15 keyframes for smooth easing representation
        rawSteps =
            List.range 0 14
                |> List.map (\i -> toFloat i / 14.0)

        -- Apply easing function to get actual progress values
        easedSteps =
            rawSteps
                |> List.map easingFunction
                |> List.indexedMap
                    (\i easedProgress ->
                        ( toFloat i / 14.0, easedProgress )
                    )

        -- Always include 0% and 100% keyframes
        allSteps =
            ( 0.0, 0.0 )
                :: (easedSteps |> List.drop 1 |> List.take 13)
                ++ [ ( 1.0, 1.0 ) ]

        generateStepStyles : Float -> List ( String, String )
        generateStepStyles easedProgress =
            allProperties
                |> List.filterMap (propertyToKeyframeStyle easedProgress)
                |> combineTransformStyles
    in
    allSteps
        |> List.map (\( _, easedProgress ) -> ( easedProgress, generateStepStyles easedProgress ))
        |> List.filter (\( _, styles ) -> not (List.isEmpty styles))
        |> List.indexedMap (\i ( _, styles ) -> ( toFloat i / 14.0, styles ))


{-| Combine multiple transform properties into a single transform style.
-}
combineTransformStyles : List ( String, String ) -> List ( String, String )
combineTransformStyles styles =
    let
        ( transformStyles, otherStyles ) =
            styles |> List.partition (\( prop, _ ) -> prop == "transform")

        combinedTransform =
            case transformStyles of
                [] ->
                    []

                _ ->
                    let
                        transformValues =
                            transformStyles
                                |> List.map Tuple.second
                                |> String.join " "
                    in
                    [ ( "transform", transformValues ) ]
    in
    combinedTransform ++ otherStyles


{-| Convert a property to its CSS style at a given progress.
-}
propertyToKeyframeStyle : Float -> Builder.PropertyConfig -> Maybe ( String, String )
propertyToKeyframeStyle progress property =
    case property of
        Builder.PositionConfig config ->
            let
                startPos =
                    Maybe.withDefault (Position.fromTuple ( 0, 0 )) config.startAt

                endPos =
                    config.endAt

                interpolatedPos =
                    Position.interpolate progress startPos endPos
            in
            Just ( "transform", "translate(" ++ Position.toCssString interpolatedPos ++ ")" )

        Builder.RotateConfig config ->
            let
                startRot =
                    Maybe.withDefault (Rotate.fromFloat 0) config.startAt

                endRot =
                    config.endAt

                startAngle =
                    Rotate.toFloat startRot

                endAngle =
                    Rotate.toFloat endRot

                interpolatedAngle =
                    startAngle + (endAngle - startAngle) * progress

                interpolatedRot =
                    Rotate.fromFloat interpolatedAngle
            in
            Just ( "transform", "rotate(" ++ Rotate.toCssString interpolatedRot ++ ")" )

        Builder.ScaleConfig config ->
            let
                startScale =
                    Maybe.withDefault (Scale.fromTuple ( 1, 1 )) config.startAt

                endScale =
                    config.endAt

                ( startX, startY ) =
                    Scale.toTuple startScale

                ( endX, endY ) =
                    Scale.toTuple endScale

                interpolatedX =
                    startX + (endX - startX) * progress

                interpolatedY =
                    startY + (endY - startY) * progress

                interpolatedScale =
                    Scale.fromTuple ( interpolatedX, interpolatedY )
            in
            Just ( "transform", "scale(" ++ Scale.toCssString interpolatedScale ++ ")" )

        Builder.ColorConfig config ->
            let
                startColor =
                    Maybe.withDefault (Color.rgb255 0 0 0) config.startAt

                endColor =
                    config.endAt

                interpolatedColor =
                    Color.interpolate startColor endColor progress
            in
            Just ( "background-color", Color.toString interpolatedColor )

        Builder.OpacityConfig config ->
            let
                startOpacity =
                    Maybe.withDefault (Opacity.fromFloat 1.0) config.startAt

                endOpacity =
                    config.endAt

                startValue =
                    Opacity.toFloat startOpacity

                endValue =
                    Opacity.toFloat endOpacity

                interpolatedValue =
                    startValue + (endValue - startValue) * progress

                interpolatedOpacity =
                    Opacity.fromFloat interpolatedValue
            in
            Just ( "opacity", Opacity.toString interpolatedOpacity )


type alias TimingGroup =
    { duration : Int
    , easing : Easing.Easing
    , delay : Int
    , properties : List Builder.PropertyConfig
    }


buildKeyframesString : String -> List ( Float, List ( String, String ) ) -> Maybe TimingGroup -> String
buildKeyframesString animationName steps maybeTimingGroup =
    let
        stepToString : ( Float, List ( String, String ) ) -> String
        stepToString ( progress, styles ) =
            let
                percentage =
                    String.fromFloat (progress * 100) ++ "%"

                styleStrings =
                    List.map (\( prop, value ) -> "  " ++ prop ++ ": " ++ value ++ ";") styles
            in
            percentage ++ " {\n" ++ String.join "\n" styleStrings ++ "\n}"

        stepsString =
            List.map stepToString steps |> String.join "\n\n"

        -- Extract element ID from animation name (remove the layer and animation suffixes)
        elementId =
            animationName
                |> String.split "-layer-"
                |> List.head
                |> Maybe.withDefault animationName

        animationProperties =
            case maybeTimingGroup of
                Just group ->
                    "\n\n/* Animation properties for "
                        ++ elementId
                        ++ " */\n"
                        ++ "/* Use: animation: "
                        ++ animationName
                        ++ " "
                        ++ String.fromInt group.duration
                        ++ "ms "
                        ++ Easing.toCSS (Just group.easing)
                        ++ " "
                        ++ String.fromInt group.delay
                        ++ "ms; */\n"

                Nothing ->
                    "\n\n/* Animation properties for "
                        ++ elementId
                        ++ " */\n"
                        ++ "/* Use: animation: "
                        ++ animationName
                        ++ " 1s ease 0ms; */\n"
    in
    "@keyframes " ++ animationName ++ " {\n" ++ stepsString ++ "\n}" ++ animationProperties


{-| Generate the keyframes CSS string for a given element and animations.
This is the internal string generation logic separated for testability.
-}
generateKeyframesString : Maybe String -> String
generateKeyframesString maybeKeyframes =
    maybeKeyframes
        |> Maybe.withDefault ""


animationStyleAttribute : String -> AnimationState -> Html.Attribute msg
animationStyleAttribute elementId animationState =
    case getElementAnimation elementId animationState of
        Just elementAnimation ->
            let
                animationValues =
                    generateAnimationAttributeString elementAnimation.animationLayers
            in
            Html.Attributes.style "animation" animationValues

        Nothing ->
            Html.Attributes.style "animation" ""


generateAnimationAttributeString : List AnimationLayer -> String
generateAnimationAttributeString animationLayers =
    if not (List.isEmpty animationLayers) then
        animationLayers
            |> List.map
                (\layer ->
                    layer.animationName
                        ++ " "
                        ++ String.fromInt layer.duration
                        ++ "ms "
                        ++ layer.easing
                        ++ " "
                        ++ String.fromInt layer.delay
                        ++ "ms forwards"
                )
            |> String.join ", "

    else
        ""


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


htmlAttributes : String -> AnimationState -> List (Html.Attribute msg)
htmlAttributes elementId animationResult =
    getElementStyles elementId animationResult
        |> List.map (\( prop, value ) -> Html.Attributes.style prop value)


getElementStyles : ElementId -> AnimationState -> List ( String, String )
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
