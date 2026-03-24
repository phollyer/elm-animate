module Anim.Internal.CSS.Transform exposing
    ( combineStyles
    , consolidateTiming
    , generate
    , generateFromProcessed
    , generateFromProcessedWithOrder
    , generateWithOrder
    , isTransformProperty
    )

import Anim.Extra.Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Easing as Easing
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Translate as Translate
import Anim.Internal.Timing.TimeSpec as TimeSpec


{-| Generate the CSS transform string from a list of property configs.
-}
generate : List Builder.PropertyConfig -> String
generate properties =
    let
        transformParts =
            Builder.extractTransformsFromProperty properties
    in
    String.trim (transformParts.translate ++ " " ++ transformParts.rotate ++ " " ++ transformParts.scale)


{-| Generate transform with custom property ordering.
Translate = "translate", Rotate = "rotate", Scale = "scale"
-}
generateWithOrder : List String -> List Builder.PropertyConfig -> String
generateWithOrder order properties =
    let
        transformParts =
            Builder.extractTransformsFromProperty properties

        -- Build transform string in the specified order
        orderedTransforms =
            List.filterMap (getTransformByName transformParts) order
    in
    String.trim (String.join " " orderedTransforms)


{-| Get the transform string for a given property name.
-}
getTransformByName : Builder.TransformParts -> String -> Maybe String
getTransformByName parts name =
    case name of
        "translate" ->
            if String.isEmpty parts.translate then
                Nothing

            else
                Just parts.translate

        "rotate" ->
            if String.isEmpty parts.rotate then
                Nothing

            else
                Just parts.rotate

        "scale" ->
            if String.isEmpty parts.scale then
                Nothing

            else
                Just parts.scale

        _ ->
            Nothing


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
        Builder.TranslateConfig _ ->
            True

        Builder.RotateConfig _ ->
            True

        Builder.ScaleConfig _ ->
            True

        _ ->
            False


{-| Generate the CSS transform string from processed properties.
-}
generateFromProcessed : List Builder.ProcessedPropertyConfig -> String
generateFromProcessed properties =
    let
        transformParts =
            extractTransformsFromProcessed properties
    in
    String.trim (transformParts.translate ++ " " ++ transformParts.rotate ++ " " ++ transformParts.scale)


{-| Generate transform from processed properties with custom ordering.
-}
generateFromProcessedWithOrder : List String -> List Builder.ProcessedPropertyConfig -> String
generateFromProcessedWithOrder order properties =
    let
        transformParts =
            extractTransformsFromProcessed properties

        -- Build transform string in the specified order
        orderedTransforms =
            List.filterMap (getTransformByName transformParts) order
    in
    String.trim (String.join " " orderedTransforms)


{-| Extract transform parts from processed properties.
-}
extractTransformsFromProcessed : List Builder.ProcessedPropertyConfig -> Builder.TransformParts
extractTransformsFromProcessed properties =
    List.foldl collectProcessedTransform emptyTransformParts properties


emptyTransformParts : Builder.TransformParts
emptyTransformParts =
    { translate = ""
    , rotate = ""
    , scale = ""
    }


collectProcessedTransform : Builder.ProcessedPropertyConfig -> Builder.TransformParts -> Builder.TransformParts
collectProcessedTransform property acc =
    case property of
        Builder.ProcessedTranslateConfig config ->
            { acc | translate = Translate.toCssString config.end }

        Builder.ProcessedRotateConfig config ->
            { acc | rotate = Rotate.toCssString config.end }

        Builder.ProcessedScaleConfig config ->
            let
                ( x, y ) =
                    Scale.toTuple config.end
            in
            { acc | scale = "scale(" ++ String.fromFloat x ++ ", " ++ String.fromFloat y ++ ")" }

        _ ->
            acc


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
        Builder.TranslateConfig config ->
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
                        chooseLongerDuration (\ts -> TimeSpec.duration dist ts) timeSpec acc
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


findLatestEasing : List Builder.PropertyConfig -> Easing
findLatestEasing properties =
    properties
        |> List.filterMap extractEasing
        |> List.reverse
        |> List.head
        |> Maybe.withDefault Linear


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
        Builder.TranslateConfig config ->
            config.timing

        Builder.RotateConfig config ->
            config.timing

        Builder.ScaleConfig config ->
            config.timing

        _ ->
            Nothing


extractEasing : Builder.PropertyConfig -> Maybe Easing
extractEasing property =
    case property of
        Builder.TranslateConfig config ->
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
        Builder.TranslateConfig config ->
            config.delay

        Builder.RotateConfig config ->
            config.delay

        Builder.ScaleConfig config ->
            config.delay

        _ ->
            Nothing
