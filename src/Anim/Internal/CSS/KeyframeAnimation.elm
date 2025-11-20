module Anim.Internal.CSS.KeyframeAnimation exposing
    ( KeyframeAnimation
    , generate
    , toAttributeString
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.CSS.Transform as Transforms
import Anim.Internal.CSS.Transition as Transitions
import Anim.Internal.Properties.Color as Color
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position as Position
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Timing.Easing as Easing
import Anim.Internal.Timing.TimeSpec as TimeSpec


type alias KeyframeAnimation =
    { animationName : String
    , keyframes : String
    , duration : Int
    , easing : String
    , delay : Int
    , properties : List String -- Properties this layer animates
    }


{-| Generate animation layers for an element's properties, supporting multiple simultaneous animations.
-}
generate : String -> List Builder.PropertyConfig -> List KeyframeAnimation
generate elementId properties =
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


toAttributeString : List KeyframeAnimation -> String
toAttributeString animationLayers =
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


{-| Create an animation layer from a timing group.
-}
createAnimationLayerFromGroup : String -> Int -> TimingGroup -> Maybe KeyframeAnimation
createAnimationLayerFromGroup elementId layerIndex timingGroup =
    let
        keyframeSteps =
            generateTimedKeyframeSteps timingGroup timingGroup.properties

        -- Create a truly unique identifier by hashing all the animation data
        contentForHash =
            elementId
                ++ String.fromInt layerIndex
                ++ String.fromInt timingGroup.duration
                ++ String.fromInt timingGroup.delay
                ++ (keyframeSteps
                        |> List.map
                            (\( progress, properties ) ->
                                String.fromFloat progress
                                    ++ (properties |> List.map (\( prop, value ) -> prop ++ value) |> String.join "")
                            )
                        |> String.join ""
                   )

        simpleHash =
            contentForHash
                |> String.toList
                |> List.map Char.toCode
                |> List.sum
                |> modBy 999999

        uniqueId =
            "anim" ++ String.fromInt simpleHash

        animationName =
            elementId ++ "-layer-" ++ String.fromInt layerIndex ++ "-" ++ uniqueId

        _ =
            Debug.log ("Animation name for " ++ elementId) animationName

        keyframesString =
            buildKeyframesString animationName keyframeSteps

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
            , easing = "linear" -- Use linear since easing is already in keyframes
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

                Builder.BackgroundColorConfig _ ->
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
            let
                distance =
                    Transitions.calculatePropertyDistance property

                timing =
                    Maybe.withDefault (TimeSpec.Duration 0) config.timing

                duration_ =
                    TimeSpec.duration distance timing

                easing_ =
                    Maybe.withDefault Easing.Linear config.easing

                delay_ =
                    Maybe.withDefault 0 config.delay
            in
            Just ( { duration = duration_, easing = easing_, delay = delay_ }, property )

        Builder.RotateConfig config ->
            let
                distance =
                    Transitions.calculatePropertyDistance property

                timing =
                    Maybe.withDefault (TimeSpec.Duration 0) config.timing

                duration_ =
                    TimeSpec.duration distance timing

                easing_ =
                    Maybe.withDefault Easing.Linear config.easing

                delay_ =
                    Maybe.withDefault 0 config.delay
            in
            Just ( { duration = duration_, easing = easing_, delay = delay_ }, property )

        Builder.ScaleConfig config ->
            let
                distance =
                    Transitions.calculatePropertyDistance property

                timing =
                    Maybe.withDefault (TimeSpec.Duration 0) config.timing

                duration_ =
                    TimeSpec.duration distance timing

                easing_ =
                    Maybe.withDefault Easing.Linear config.easing

                delay_ =
                    Maybe.withDefault 0 config.delay
            in
            Just ( { duration = duration_, easing = easing_, delay = delay_ }, property )

        Builder.BackgroundColorConfig config ->
            let
                distance =
                    Transitions.calculatePropertyDistance property

                timing =
                    Maybe.withDefault (TimeSpec.Duration 0) config.timing

                duration_ =
                    TimeSpec.duration distance timing

                easing_ =
                    Maybe.withDefault Easing.Linear config.easing

                delay_ =
                    Maybe.withDefault 0 config.delay
            in
            Just ( { duration = duration_, easing = easing_, delay = delay_ }, property )

        Builder.OpacityConfig config ->
            let
                distance =
                    Transitions.calculatePropertyDistance property

                timing =
                    Maybe.withDefault (TimeSpec.Duration 0) config.timing

                duration_ =
                    TimeSpec.duration distance timing

                easing_ =
                    Maybe.withDefault Easing.Linear config.easing

                delay_ =
                    Maybe.withDefault 0 config.delay
            in
            Just ( { duration = duration_, easing = easing_, delay = delay_ }, property )


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
        generateStepStyles : Float -> List ( String, String )
        generateStepStyles easedProgress =
            allProperties
                |> List.filterMap (propertyToKeyframeStyle easedProgress)
                |> Transforms.combineStyles
    in
    -- Handle zero duration case: create single keyframe at 100%
    if dominantGroup.duration == 0 then
        [ ( 1.0, generateStepStyles 1.0 ) ]

    else
        let
            easingFunction =
                Easing.toFunction dominantGroup.easing

            -- Generate more keyframes for smooth easing representation
            -- Use more steps for complex easings like bounce and elastic
            keyframeCount =
                case dominantGroup.easing of
                    Easing.BounceIn ->
                        80

                    Easing.BounceOut ->
                        80

                    Easing.BounceInOut ->
                        80

                    Easing.ElasticIn ->
                        60

                    Easing.ElasticOut ->
                        60

                    Easing.ElasticInOut ->
                        60

                    _ ->
                        30

            -- Base linear distribution 0..1
            baseLinear =
                List.range 0 (keyframeCount - 1)
                    |> List.map (\i -> toFloat i / toFloat (keyframeCount - 1))

            piecewiseTimes : List Float
            piecewiseTimes =
                case dominantGroup.easing of
                    Easing.BounceOut ->
                        -- Use uniform sampling for all bounce types
                        List.range 0 50
                            |> List.map (\i -> toFloat i / 50.0)

                    Easing.BounceIn ->
                        -- Use uniform sampling - the easing function handles the bounce timing
                        List.range 0 50
                            |> List.map (\i -> toFloat i / 50.0)

                    Easing.BounceInOut ->
                        -- Use uniform sampling - the easing function handles the bounce timing
                        List.range 0 50
                            |> List.map (\i -> toFloat i / 50.0)

                    _ ->
                        baseLinear

            -- Use piecewise sampling for Bounce, otherwise uniform
            rawSteps =
                case dominantGroup.easing of
                    Easing.BounceIn ->
                        piecewiseTimes

                    Easing.BounceOut ->
                        piecewiseTimes

                    Easing.BounceInOut ->
                        piecewiseTimes

                    _ ->
                        baseLinear

            progressPairs =
                rawSteps |> List.map (\raw -> ( raw, easingFunction raw ))
        in
        progressPairs
            |> List.map (\( raw, eased ) -> ( raw, generateStepStyles eased ))
            |> List.filter (\( _, styles ) -> not (List.isEmpty styles))


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

        Builder.BackgroundColorConfig config ->
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


buildKeyframesString : String -> List ( Float, List ( String, String ) ) -> String
buildKeyframesString animationName steps =
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

        animationPropertiesComment =
            "\n\n/* Animation properties for "
                ++ elementId
                ++ " */\n"
    in
    "@keyframes " ++ animationName ++ " {\n" ++ stepsString ++ "\n}" ++ animationPropertiesComment
