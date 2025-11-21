module Anim.Internal.CSS.KeyframeAnimation exposing
    ( KeyframeAnimation
    , generate
    , toAttributeString
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.CSS.Transition as Transitions
import Anim.Internal.Properties.Color as Color
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position as Position
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Timing.Easing as Easing
import Anim.Internal.Timing.TimeSpec as TimeSpec
import Dict


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
            processed =
                Builder.processElement
                    { globalTiming = Nothing, globalEasing = Nothing, globalDelay = Nothing, currentElementId = Nothing, elements = Dict.empty }
                    elementId
                    { properties = properties }

            processedProps =
                processed.properties

            maxDuration =
                processedProps
                    |> List.map
                        (\p ->
                            case p of
                                Builder.ProcessedPositionConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedScaleConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedRotateConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedColorConfig cfg ->
                                    cfg.duration

                                Builder.ProcessedOpacityConfig cfg ->
                                    cfg.duration
                        )
                    |> List.maximum
                    |> Maybe.withDefault 0

            totalDuration =
                if maxDuration == 0 then
                    800

                else
                    maxDuration

            keyframeCount =
                30

            keyframeSteps =
                List.range 0 keyframeCount
                    |> List.map
                        (\i ->
                            let
                                globalProgress =
                                    toFloat i / toFloat keyframeCount

                                time =
                                    globalProgress * toFloat totalDuration

                                stepStyles =
                                    processedProps
                                        |> List.filterMap
                                            (\p ->
                                                case p of
                                                    Builder.ProcessedPositionConfig cfg ->
                                                        let
                                                            dur =
                                                                cfg.duration

                                                            propProgress =
                                                                if time <= toFloat dur then
                                                                    time / toFloat dur

                                                                else
                                                                    1.0

                                                            startPos =
                                                                case cfg.startAt of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Position.fromTuple ( 0.0, 0.0 )

                                                            endPos =
                                                                cfg.endAt

                                                            interpolatedPos =
                                                                Position.interpolate propProgress startPos endPos
                                                        in
                                                        Just ( "transform-component", "translate(" ++ Position.toCssString interpolatedPos ++ ")" )

                                                    Builder.ProcessedRotateConfig cfg ->
                                                        let
                                                            dur =
                                                                cfg.duration

                                                            propProgress =
                                                                if time <= toFloat dur then
                                                                    time / toFloat dur

                                                                else
                                                                    1.0

                                                            startRot =
                                                                case cfg.startAt of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Rotate.fromFloat 0.0

                                                            endRot =
                                                                cfg.endAt

                                                            startAngle =
                                                                Rotate.toFloat startRot

                                                            endAngle =
                                                                Rotate.toFloat endRot

                                                            interpolatedAngle =
                                                                startAngle + (endAngle - startAngle) * propProgress

                                                            interpolatedRot =
                                                                Rotate.fromFloat interpolatedAngle
                                                        in
                                                        Just ( "transform-component", "rotate(" ++ Rotate.toCssString interpolatedRot ++ ")" )

                                                    Builder.ProcessedScaleConfig cfg ->
                                                        let
                                                            dur =
                                                                cfg.duration

                                                            propProgress =
                                                                if dur > 0 then
                                                                    clamp 0 1 (time / toFloat dur)

                                                                else
                                                                    1.0

                                                            startScale =
                                                                case cfg.startAt of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Scale.fromTuple ( 1.0, 1.0 )

                                                            endScale =
                                                                cfg.endAt

                                                            ( startX, startY ) =
                                                                Scale.toTuple startScale

                                                            ( endX, endY ) =
                                                                Scale.toTuple endScale

                                                            interpolatedX =
                                                                startX + (endX - startX) * propProgress

                                                            interpolatedY =
                                                                startY + (endY - startY) * propProgress

                                                            interpolatedScale =
                                                                Scale.fromTuple ( interpolatedX, interpolatedY )
                                                        in
                                                        Just ( "transform-component", "scale(" ++ Scale.toCssString interpolatedScale ++ ")" )

                                                    Builder.ProcessedColorConfig cfg ->
                                                        let
                                                            dur =
                                                                cfg.duration

                                                            propProgress =
                                                                if dur > 0 then
                                                                    clamp 0 1 (time / toFloat dur)

                                                                else
                                                                    1.0

                                                            startColor =
                                                                case cfg.startAt of
                                                                    Just c ->
                                                                        c

                                                                    Nothing ->
                                                                        Color.rgb255 59 130 246

                                                            endColor =
                                                                cfg.endAt

                                                            interpolatedColor =
                                                                Color.interpolate startColor endColor propProgress
                                                        in
                                                        Just ( "background-color", Color.toString interpolatedColor )

                                                    Builder.ProcessedOpacityConfig cfg ->
                                                        let
                                                            dur =
                                                                cfg.duration

                                                            propProgress =
                                                                if time <= toFloat dur then
                                                                    time / toFloat dur

                                                                else
                                                                    1.0

                                                            startOpacity =
                                                                case cfg.startAt of
                                                                    Just s ->
                                                                        s

                                                                    Nothing ->
                                                                        Opacity.fromFloat 1.0

                                                            endOpacity =
                                                                cfg.endAt

                                                            startValue =
                                                                Opacity.toFloat startOpacity

                                                            endValue =
                                                                Opacity.toFloat endOpacity

                                                            interpolatedValue =
                                                                startValue + (endValue - startValue) * propProgress

                                                            interpolatedOpacity =
                                                                Opacity.fromFloat interpolatedValue
                                                        in
                                                        Just ( "opacity", Opacity.toString interpolatedOpacity )
                                            )

                                transformComponents =
                                    stepStyles
                                        |> List.filterMap
                                            (\s ->
                                                case s of
                                                    ( "transform-component", v ) ->
                                                        Just v

                                                    _ ->
                                                        Nothing
                                            )

                                transformStyle =
                                    if List.isEmpty transformComponents then
                                        Nothing

                                    else
                                        Just ( "transform", String.join " " transformComponents )

                                otherStyles =
                                    stepStyles
                                        |> List.filterMap
                                            (\s ->
                                                case s of
                                                    ( "transform-component", _ ) ->
                                                        Nothing

                                                    _ ->
                                                        Just s
                                            )

                                styles =
                                    case transformStyle of
                                        Just t ->
                                            t :: otherStyles

                                        Nothing ->
                                            otherStyles
                            in
                            ( globalProgress, styles )
                        )

            -- Generate a unique animation name based on content hash
            contentForHash =
                elementId
                    ++ String.fromInt totalDuration
                    ++ (processedProps
                            |> List.map
                                (\p ->
                                    case p of
                                        Builder.ProcessedPositionConfig cfg ->
                                            "pos" ++ String.fromInt cfg.duration ++ Position.toCssString cfg.endAt

                                        Builder.ProcessedScaleConfig cfg ->
                                            "scale" ++ String.fromInt cfg.duration ++ Scale.toCssString cfg.endAt

                                        Builder.ProcessedRotateConfig cfg ->
                                            "rot" ++ String.fromInt cfg.duration ++ Rotate.toCssString cfg.endAt

                                        Builder.ProcessedColorConfig cfg ->
                                            "color" ++ String.fromInt cfg.duration ++ Color.toString cfg.endAt

                                        Builder.ProcessedOpacityConfig cfg ->
                                            "opacity" ++ String.fromInt cfg.duration ++ Opacity.toString cfg.endAt
                                )
                            |> String.join ""
                       )

            simpleHash =
                contentForHash
                    |> String.toList
                    |> List.map Char.toCode
                    |> List.sum
                    |> modBy 999999

            animationName =
                elementId ++ "-anim-" ++ String.fromInt simpleHash

            keyframesString =
                buildKeyframesString animationName keyframeSteps

            animatedProperties =
                [ "transform", "background-color", "opacity" ]
        in
        [ { animationName = animationName
          , keyframes = keyframesString
          , duration = totalDuration
          , easing = "linear"
          , delay = 0
          , properties = animatedProperties
          }
        ]


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
        -- Composite pattern: build a single transform string and combine with other properties
        -- Composite keyframe logic: all properties animated in one layer, with per-property timing windows
        generateStepStyles : Float -> List ( String, String )
        generateStepStyles globalProgress =
            let
                -- Find the max duration among all properties
                maxDuration =
                    allProperties
                        |> List.map
                            (\prop ->
                                case prop of
                                    Builder.PositionConfig cfg ->
                                        cfg.duration

                                    Builder.ScaleConfig cfg ->
                                        cfg.duration

                                    Builder.RotateConfig cfg ->
                                        cfg.duration

                                    Builder.BackgroundColorConfig cfg ->
                                        cfg.duration

                                    Builder.OpacityConfig cfg ->
                                        cfg.duration
                            )
                        |> List.maximum
                        |> Maybe.withDefault 0

                totalDuration =
                    if maxDuration == 0 then
                        800

                    else
                        maxDuration

                time =
                    globalProgress * toFloat totalDuration

                -- For each property, map its progress to its timing window
                stepStyles =
                    allProperties
                        |> List.filterMap
                            (\prop ->
                                case prop of
                                    Builder.PositionConfig cfg ->
                                        let
                                            dur =
                                                cfg.duration

                                            propProgress =
                                                if time <= toFloat dur then
                                                    time / toFloat dur

                                                else
                                                    1.0

                                            startPos =
                                                Maybe.withDefault (Position.fromTuple ( 0, 0 )) cfg.startAt

                                            endPos =
                                                cfg.endAt

                                            interpolatedPos =
                                                Position.interpolate propProgress startPos endPos
                                        in
                                        Just ( "transform-component", "translate(" ++ Position.toCssString interpolatedPos ++ ")" )

                                    Builder.RotateConfig cfg ->
                                        let
                                            dur =
                                                cfg.duration

                                            propProgress =
                                                if time <= toFloat dur then
                                                    time / toFloat dur

                                                else
                                                    1.0

                                            startRot =
                                                Maybe.withDefault (Rotate.fromFloat 0) cfg.startAt

                                            endRot =
                                                cfg.endAt

                                            startAngle =
                                                Rotate.toFloat startRot

                                            endAngle =
                                                Rotate.toFloat endRot

                                            interpolatedAngle =
                                                startAngle + (endAngle - startAngle) * propProgress

                                            interpolatedRot =
                                                Rotate.fromFloat interpolatedAngle
                                        in
                                        Just ( "transform-component", "rotate(" ++ Rotate.toCssString interpolatedRot ++ ")" )

                                    Builder.ScaleConfig cfg ->
                                        let
                                            dur =
                                                cfg.duration

                                            propProgress =
                                                if time <= toFloat dur then
                                                    time / toFloat dur

                                                else
                                                    1.0

                                            startScale =
                                                Maybe.withDefault (Scale.fromTuple ( 1, 1 )) cfg.startAt

                                            endScale =
                                                cfg.endAt

                                            ( startX, startY ) =
                                                Scale.toTuple startScale

                                            ( endX, endY ) =
                                                Scale.toTuple endScale

                                            interpolatedX =
                                                startX + (endX - startX) * propProgress

                                            interpolatedY =
                                                startY + (endY - startY) * propProgress

                                            interpolatedScale =
                                                Scale.fromTuple ( interpolatedX, interpolatedY )
                                        in
                                        Just ( "transform-component", "scale(" ++ Scale.toCssString interpolatedScale ++ ")" )

                                    Builder.BackgroundColorConfig cfg ->
                                        let
                                            dur =
                                                cfg.duration

                                            propProgress =
                                                if time <= toFloat dur then
                                                    time / toFloat dur

                                                else
                                                    1.0

                                            startColor =
                                                Maybe.withDefault (Color.rgb255 0 0 0) cfg.startAt

                                            endColor =
                                                cfg.endAt

                                            interpolatedColor =
                                                Color.interpolate startColor endColor propProgress
                                        in
                                        Just ( "background-color", Color.toString interpolatedColor )

                                    Builder.OpacityConfig cfg ->
                                        let
                                            dur =
                                                cfg.duration

                                            propProgress =
                                                if time <= toFloat dur then
                                                    time / toFloat dur

                                                else
                                                    1.0

                                            startOpacity =
                                                Maybe.withDefault (Opacity.fromFloat 1.0) cfg.startAt

                                            endOpacity =
                                                cfg.endAt

                                            startValue =
                                                Opacity.toFloat startOpacity

                                            endValue =
                                                Opacity.toFloat endOpacity

                                            interpolatedValue =
                                                startValue + (endValue - startValue) * propProgress

                                            interpolatedOpacity =
                                                Opacity.fromFloat interpolatedValue
                                        in
                                        Just ( "opacity", Opacity.toString interpolatedOpacity )
                            )

                -- Compose transform string from all transform components
                transformComponents =
                    stepStyles
                        |> List.filterMap
                            (\s ->
                                case s of
                                    ( "transform-component", v ) ->
                                        Just v

                                    _ ->
                                        Nothing
                            )

                transformStyle =
                    if List.isEmpty transformComponents then
                        Nothing

                    else
                        Just ( "transform", String.join " " transformComponents )

                otherStyles =
                    stepStyles
                        |> List.filterMap
                            (\s ->
                                case s of
                                    ( "transform-component", _ ) ->
                                        Nothing

                                    _ ->
                                        Just s
                            )

                styles =
                    case transformStyle of
                        Just t ->
                            t :: otherStyles

                        Nothing ->
                            otherStyles
            in
            styles

        -- Helper: extract non-transform styles
        propertyToNonTransformStyle : Float -> Builder.PropertyConfig -> Maybe ( String, String )
        propertyToNonTransformStyle progress property =
            case property of
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

                _ ->
                    Nothing
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
