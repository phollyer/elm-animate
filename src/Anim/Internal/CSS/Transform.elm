module Anim.Internal.CSS.Transform exposing
    ( combineStyles
    , consolidateTiming
    , generate
    , generateWithOrder
    , isTransformProperty
    )

import Anim.Internal.Builder as Builder
import Anim.Internal.Timing.Easing as Easing
import Anim.Internal.Timing.TimeSpec as TimeSpec


{-| Generate the CSS transform string from a list of property configs.
-}
generate : List Builder.PropertyConfig -> String
generate properties =
    let
        transformParts =
            Builder.extractTransformsFromProperty properties
    in
    String.trim (transformParts.position ++ " " ++ transformParts.rotate ++ " " ++ transformParts.scale)


{-| Generate transform with custom property ordering.
Position = "position", Rotate = "rotate", Scale = "scale"
-}
generateWithOrder : List String -> List Builder.PropertyConfig -> String
generateWithOrder order properties =
    let
        -- Sort properties according to the specified order
        sortedProperties =
            sortPropertiesByOrder order properties

        transformParts =
            Builder.extractTransformsFromProperty sortedProperties
    in
    String.trim (transformParts.position ++ " " ++ transformParts.rotate ++ " " ++ transformParts.scale)


{-| Sort properties according to specified order.
-}
sortPropertiesByOrder : List String -> List Builder.PropertyConfig -> List Builder.PropertyConfig
sortPropertiesByOrder order properties =
    let
        getPropertyPriority prop =
            case prop of
                Builder.PositionConfig _ ->
                    getOrderIndex "position" order

                Builder.RotateConfig _ ->
                    getOrderIndex "rotate" order

                Builder.ScaleConfig _ ->
                    getOrderIndex "scale" order

                _ ->
                    999

        -- Non-transform properties go last
        getOrderIndex propType orderList =
            orderList
                |> List.indexedMap Tuple.pair
                |> List.filter (\( _, item ) -> item == propType)
                |> List.head
                |> Maybe.map Tuple.first
                |> Maybe.withDefault 999
    in
    List.sortBy getPropertyPriority properties


{-| Combine multiple transform styles into a single transform style.
-}
combineStyles : List ( String, String ) -> List ( String, String )
combineStyles styles =
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


{-| Check if a property config is a transform property.
-}
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


{-| Consolidate timing for transform properties into a single transition string.
-}
consolidateTiming : List Builder.PropertyConfig -> Maybe String
consolidateTiming transformProps =
    case transformProps of
        [] ->
            Nothing

        _ ->
            let
                longestDistance =
                    findLongestDistance transformProps

                longestDuration =
                    findLongestDuration transformProps

                latestEasing =
                    findLatestEasing transformProps

                earliestDelay =
                    findEarliestDelay transformProps
            in
            let
                delayString =
                    case earliestDelay of
                        Just d ->
                            String.fromInt d ++ "ms"

                        Nothing ->
                            "0ms"
            in
            Just ("transform " ++ TimeSpec.toCssString longestDistance longestDuration ++ " " ++ Easing.toCSS (Just latestEasing) ++ " " ++ delayString)


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
            distances |> List.maximum |> Maybe.withDefault 0.0


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


findLongestDuration : List Builder.PropertyConfig -> Maybe TimeSpec.TimeSpec
findLongestDuration properties =
    let
        propertyDistances =
            List.filterMap
                (\prop ->
                    extractTiming prop
                        |> Maybe.map (\timeSpec -> ( timeSpec, extractDistance prop |> Maybe.withDefault 0 ))
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


findLatestEasing : List Builder.PropertyConfig -> Easing.Easing
findLatestEasing properties =
    properties
        |> List.filterMap extractEasing
        |> List.reverse
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
