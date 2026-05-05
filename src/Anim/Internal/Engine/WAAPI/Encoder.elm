module Anim.Internal.Engine.WAAPI.Encoder exposing
    ( encode
    , encodeCommandWithProperties
    , encodeProcessedData
    , encodeRestart
    , encodeScroll
    , encodeView
    )

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder as Builder exposing (AnimationDirection(..))
import Anim.Internal.Engine.Shared.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.WAAPI.AnimGroup as AnimGroup exposing (AnimGroup, PropertyState)
import Anim.Internal.Engine.WAAPI.Generator as Generator
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.PerspectiveOrigin as PerspectiveOrigin
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Easing exposing (Easing(..))
import Json.Encode as Encode
import Shared.Easing as Easing


type alias AnimGroupName =
    String


encode : AnimGroups AnimGroup -> Builder.ProcessedAnimationData -> Encode.Value
encode animGroups processed =
    let
        elementsWithVersions =
            processed.groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroupName, config ) ->
                        let
                            animGroup =
                                AnimGroups.get animGroupName animGroups

                            propertyStatesGroup =
                                animGroup
                                    |> Maybe.map AnimGroup.getPropertyStates
                                    |> Maybe.withDefault AnimGroups.init

                            animTransformOrder =
                                animGroup
                                    |> Maybe.map AnimGroup.getTransformOrder
                                    |> Maybe.withDefault TransformProperty.default
                        in
                        ( animGroupName
                        , encodeProcessedAnimGroupConfig
                            animGroupName
                            animGroupName
                            (Just propertyStatesGroup)
                            (Just animTransformOrder)
                            config.properties
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.object elementsWithVersions )
        , ( "iterations", encodeIterations processed.iterations )
        , ( "direction", encodeAnimationDirection processed.animationDirection )
        ]


encodeRestart : Builder.Iterations -> Builder.AnimationDirection -> AnimGroups AnimGroup -> AnimGroups Builder.ProcessedAnimGroupConfig -> Encode.Value
encodeRestart iterationsConfig directionConfig animGroup configGroup =
    let
        elementsWithVersions =
            configGroup
                |> AnimGroups.toList
                |> List.map
                    (\( animGroupName, config ) ->
                        let
                            elementAnim =
                                AnimGroups.get animGroupName animGroup

                            elementProps =
                                elementAnim
                                    |> Maybe.map AnimGroup.getPropertyStates
                                    |> Maybe.withDefault AnimGroups.init

                            elemTransformOrder =
                                elementAnim
                                    |> Maybe.map AnimGroup.getTransformOrder
                                    |> Maybe.withDefault TransformProperty.default
                        in
                        ( animGroupName
                        , encodeProcessedAnimGroupConfig
                            animGroupName
                            animGroupName
                            (Just elementProps)
                            (Just elemTransformOrder)
                            config.properties
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.object elementsWithVersions )
        , ( "iterations", encodeIterations iterationsConfig )
        , ( "direction", encodeAnimationDirection directionConfig )
        , ( "isRestart", Encode.bool True )
        ]


encodeProcessedData : Builder.ProcessedAnimationData -> Encode.Value
encodeProcessedData data =
    let
        processedProperties =
            data.groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroupName, config ) ->
                        ( animGroupName
                        , encodeProcessedAnimGroupConfig
                            animGroupName
                            animGroupName
                            Nothing
                            Nothing
                            config.properties
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.object processedProperties )
        , ( "iterations", encodeIterations data.iterations )
        , ( "direction", encodeAnimationDirection data.animationDirection )
        ]


{-| Encode a command with an optional property filter.
When properties is Nothing, the command affects all properties.
When properties is Just [...], only those property types are affected.
-}
encodeCommandWithProperties : String -> String -> Maybe (List String) -> Encode.Value
encodeCommandWithProperties commandType animGroupName maybeProperties =
    let
        baseFields =
            [ ( "type", Encode.string commandType )
            , ( "elementId", Encode.string animGroupName )
            ]

        propertyField =
            case maybeProperties of
                Just props ->
                    [ ( "properties", Encode.list Encode.string props ) ]

                Nothing ->
                    []
    in
    Encode.object (baseFields ++ propertyField)


{-| Encode iterations config for JavaScript.
Returns a JSON object with type and count fields.
JavaScript will use this to set the animation iterations.
-}
encodeIterations : Builder.Iterations -> Encode.Value
encodeIterations iterations_ =
    case iterations_ of
        Builder.Once ->
            Encode.object
                [ ( "type", Encode.string "once" )
                , ( "count", Encode.int 1 )
                ]

        Builder.Times n ->
            Encode.object
                [ ( "type", Encode.string "times" )
                , ( "count", Encode.int n )
                ]

        Builder.Infinite ->
            Encode.object
                [ ( "type", Encode.string "infinite" )
                , ( "count", Encode.int -1 )
                ]


{-| Encode animation direction for JavaScript.
Returns a string that matches Web Animations API direction values.
-}
encodeAnimationDirection : AnimationDirection -> Encode.Value
encodeAnimationDirection direction =
    case direction of
        Normal ->
            Encode.string "normal"

        Alternate ->
            Encode.string "alternate"


encodeProcessedAnimGroupConfig :
    AnimGroupName
    -> String
    -> Maybe (AnimGroups PropertyState)
    -> Maybe (List TransformProperty)
    -> List Builder.ProcessedPropertyConfig
    -> Encode.Value
encodeProcessedAnimGroupConfig animGroupName targetId propertyState transformOrder_ propertyConfigs =
    let
        baseFields =
            [ ( "properties", Encode.list (encodeProcessedPropertyConfig propertyState) propertyConfigs )
            , ( "animGroup", Encode.string animGroupName )
            , ( "target", Encode.string targetId )
            ]

        optionalFields =
            transformOrder_
                |> Maybe.map (\order -> [ ( "transformOrder", encodeTransformOrder order ) ])
                |> Maybe.withDefault []
    in
    Encode.object (baseFields ++ optionalFields)


{-| Encode transform order as a JSON array of strings.
-}
encodeTransformOrder : List TransformProperty -> Encode.Value
encodeTransformOrder order =
    Encode.list
        (\t ->
            case t of
                TransformProperty.Translate ->
                    Encode.string "translate"

                TransformProperty.Rotate ->
                    Encode.string "rotate"

                TransformProperty.Skew ->
                    Encode.string "skew"

                TransformProperty.Scale ->
                    Encode.string "scale"
        )
        order


encodeProcessedPropertyConfig : Maybe (AnimGroups PropertyState) -> Builder.ProcessedPropertyConfig -> Encode.Value
encodeProcessedPropertyConfig maybeVersions property =
    let
        versionFields =
            case maybeVersions of
                Just propertyVersions ->
                    let
                        propType =
                            Generator.propertyTypeString property

                        version =
                            AnimGroups.get propType propertyVersions
                                |> Maybe.map .version
                                |> Maybe.withDefault 1
                    in
                    [ ( "version", Encode.int version ) ]

                Nothing ->
                    []

        encodeTripleStart toTriple default maybeStart =
            case maybeVersions of
                Just _ ->
                    case maybeStart of
                        Just start ->
                            let
                                ( sx, sy, sz ) =
                                    toTriple start
                            in
                            [ ( "startX", Encode.float sx )
                            , ( "startY", Encode.float sy )
                            , ( "startZ", Encode.float sz )
                            ]

                        Nothing ->
                            [ ( "startX", Encode.null )
                            , ( "startY", Encode.null )
                            , ( "startZ", Encode.null )
                            ]

                Nothing ->
                    let
                        ( sx, sy, sz ) =
                            maybeStart
                                |> Maybe.map toTriple
                                |> Maybe.withDefault default
                    in
                    [ ( "startX", Encode.float sx )
                    , ( "startY", Encode.float sy )
                    , ( "startZ", Encode.float sz )
                    ]
    in
    case property of
        Builder.ProcessedCustomPropertyConfig cssName unit config ->
            let
                startValue =
                    config.start
                        |> Maybe.map (\s -> [ ( "startValue", Encode.float s ) ])
                        |> Maybe.withDefault []
            in
            Encode.object
                (( "type", Encode.string "customProperty" )
                    :: ( "cssProperty", Encode.string cssName )
                    :: ( "unit", Encode.string unit )
                    :: versionFields
                    ++ [ ( "endValue", Encode.float config.end )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ startValue
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedCustomColorPropertyConfig cssName config ->
            let
                startColorField =
                    config.start
                        |> Maybe.map (\start -> [ ( "startColor", Encode.string (Color.toCssString start) ) ])
                        |> Maybe.withDefault []
            in
            Encode.object
                (( "type", Encode.string "customColorProperty" )
                    :: ( "cssProperty", Encode.string cssName )
                    :: versionFields
                    ++ [ ( "endColor", Encode.string (Color.toCssString config.end) )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ startColorField
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedOpacityConfig config ->
            let
                startValue =
                    config.start
                        |> Maybe.map Opacity.toFloat
                        |> Maybe.withDefault 1.0
            in
            Encode.object
                (( "type", Encode.string "opacity" )
                    :: versionFields
                    ++ [ ( "startValue", Encode.float startValue )
                       , ( "endValue", Encode.float (Opacity.toFloat config.end) )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedPerspectiveOriginConfig config ->
            let
                ( startX, startY ) =
                    config.start
                        |> Maybe.map PerspectiveOrigin.toTuple
                        |> Maybe.withDefault ( 50, 50 )

                ( endX, endY ) =
                    PerspectiveOrigin.toTuple config.end

                unitStr =
                    case PerspectiveOrigin.getUnit config.end of
                        PerspectiveOrigin.PercentUnit ->
                            "%"

                        PerspectiveOrigin.PxUnit ->
                            "px"
            in
            Encode.object
                (( "type", Encode.string "perspectiveOrigin" )
                    :: versionFields
                    ++ [ ( "startX", Encode.float startX )
                       , ( "startY", Encode.float startY )
                       , ( "endX", Encode.float endX )
                       , ( "endY", Encode.float endY )
                       , ( "unit", Encode.string unitStr )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedScaleConfig config ->
            let
                ( endX, endY, endZ ) =
                    Scale.toTriple config.end
            in
            Encode.object
                (( "type", Encode.string "scale" )
                    :: versionFields
                    ++ encodeTripleStart Scale.toTriple ( 1, 1, 1 ) config.start
                    ++ [ ( "endX", Encode.float endX )
                       , ( "endY", Encode.float endY )
                       , ( "endZ", Encode.float endZ )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedRotateConfig config ->
            let
                ( endX, endY, endZ ) =
                    Rotate.toTriple config.end
            in
            Encode.object
                (( "type", Encode.string "rotate" )
                    :: versionFields
                    ++ encodeTripleStart Rotate.toTriple ( 0, 0, 0 ) config.start
                    ++ [ ( "endX", Encode.float endX )
                       , ( "endY", Encode.float endY )
                       , ( "endZ", Encode.float endZ )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedSkewConfig config ->
            let
                ( endX, endY ) =
                    Skew.toTuple config.end

                startFields =
                    case maybeVersions of
                        Just _ ->
                            case config.start of
                                Just start ->
                                    let
                                        ( startX, startY ) =
                                            Skew.toTuple start
                                    in
                                    [ ( "startX", Encode.float startX )
                                    , ( "startY", Encode.float startY )
                                    ]

                                Nothing ->
                                    [ ( "startX", Encode.null )
                                    , ( "startY", Encode.null )
                                    ]

                        Nothing ->
                            let
                                ( startX, startY ) =
                                    config.start
                                        |> Maybe.map Skew.toTuple
                                        |> Maybe.withDefault ( 0, 0 )
                            in
                            [ ( "startX", Encode.float startX )
                            , ( "startY", Encode.float startY )
                            ]
            in
            Encode.object
                (( "type", Encode.string "skew" )
                    :: versionFields
                    ++ startFields
                    ++ [ ( "endX", Encode.float endX )
                       , ( "endY", Encode.float endY )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedSizeConfig config ->
            let
                ( startWidth, startHeight ) =
                    config.start
                        |> Maybe.map Size.toTuple
                        |> Maybe.withDefault ( 0, 0 )

                ( endWidth, endHeight ) =
                    Size.toTuple config.end
            in
            Encode.object
                (( "type", Encode.string "size" )
                    :: versionFields
                    ++ [ ( "startWidth", Encode.float startWidth )
                       , ( "startHeight", Encode.float startHeight )
                       , ( "endWidth", Encode.float endWidth )
                       , ( "endHeight", Encode.float endHeight )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedTranslateConfig config ->
            let
                ( endX, endY, endZ ) =
                    Translate.toTriple config.end
            in
            Encode.object
                (( "type", Encode.string "translate" )
                    :: versionFields
                    ++ encodeTripleStart Translate.toTriple ( 0, 0, 0 ) config.start
                    ++ [ ( "endX", Encode.float endX )
                       , ( "endY", Encode.float endY )
                       , ( "endZ", Encode.float endZ )
                       , ( "duration", Encode.int config.duration )
                       ]
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )


{-| Encode easing with keyframes for complex easings (Bounce, Elastic).
For complex easings, returns list with easing="linear" and keyframes array.
For simple easings, returns list with just easing string.
-}
encodeEasingWithKeyframes : Int -> Easing -> List ( String, Encode.Value )
encodeEasingWithKeyframes durationMs easingValue =
    if isComplexEasing easingValue then
        [ ( "easing", Encode.string "linear" )
        , ( "easingKeyframes", Encode.list Encode.float (Easing.generateKeyframes easingValue (toFloat durationMs)) )
        ]

    else
        [ ( "easing", Encode.string (Easing.toWebAnimations easingValue) ) ]


{-| Check if an easing type requires keyframe pre-computation for accuracy.
Bounce and Elastic easings cannot be represented accurately with a single cubic-bezier curve.
-}
isComplexEasing : Easing -> Bool
isComplexEasing easing_ =
    case easing_ of
        ElasticIn ->
            True

        ElasticOut ->
            True

        ElasticInOut ->
            True

        ElasticInCustom _ ->
            True

        ElasticOutCustom _ ->
            True

        ElasticInOutCustom _ ->
            True

        ElasticInAdvanced _ ->
            True

        ElasticOutAdvanced _ ->
            True

        ElasticInOutAdvanced _ ->
            True

        BounceIn ->
            True

        BounceOut ->
            True

        BounceInOut ->
            True

        BounceInCustom _ ->
            True

        BounceOutCustom _ ->
            True

        BounceInOutCustom _ ->
            True

        BounceInAdvanced _ ->
            True

        BounceOutAdvanced _ ->
            True

        BounceInOutAdvanced _ ->
            True

        BackInCustom _ ->
            True

        BackOutCustom _ ->
            True

        BackInOutCustom _ ->
            True

        _ ->
            False


{-| Encode a scroll-driven animation using a `ScrollTimeline`.
Duration and delay are omitted — the timeline drives progress.
Iterations, direction, and easing are supported.
-}
encodeScroll : Builder.AnimBuilder { isScrollBased : () } -> Encode.Value
encodeScroll builder =
    let
        processed =
            Builder.process builder

        source =
            Builder.getScrollSource builder
                |> Maybe.withDefault "document"

        axis_ =
            Builder.getScrollAxis builder
                |> Maybe.withDefault "block"

        elements =
            processed.groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroupName, config ) ->
                        ( animGroupName
                        , encodeProcessedAnimGroupConfig
                            animGroupName
                            (Builder.getAnimTarget animGroupName builder |> Maybe.withDefault animGroupName)
                            Nothing
                            Nothing
                            config.properties
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "scrollDriven" )
        , ( "timeline"
          , Encode.object
                [ ( "type", Encode.string "scroll" )
                , ( "source", Encode.string source )
                , ( "axis", Encode.string axis_ )
                ]
          )
        , ( "elements", Encode.object elements )
        , ( "iterations", encodeIterations processed.iterations )
        , ( "direction", encodeAnimationDirection processed.animationDirection )
        ]


{-| Encode a view-driven animation using a `ViewTimeline`.
Duration and delay are omitted — the timeline drives progress.
Iterations, direction, and easing are supported.
-}
encodeView : Builder.AnimBuilder { isViewBased : () } -> Encode.Value
encodeView builder =
    let
        processed =
            Builder.process builder

        axis_ =
            Builder.getScrollAxis builder
                |> Maybe.withDefault "block"

        timelineBase =
            [ ( "type", Encode.string "view" )
            , ( "axis", Encode.string axis_ )
            ]

        rangeFields =
            [ Builder.getViewRangeStart builder
                |> Maybe.map (\r -> ( "rangeStart", Encode.string r ))
            , Builder.getViewRangeEnd builder
                |> Maybe.map (\r -> ( "rangeEnd", Encode.string r ))
            ]
                |> List.filterMap identity

        elements =
            processed.groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroupName, config ) ->
                        ( animGroupName
                        , encodeProcessedAnimGroupConfig
                            animGroupName
                            (Builder.getAnimTarget animGroupName builder |> Maybe.withDefault animGroupName)
                            Nothing
                            Nothing
                            config.properties
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "viewDriven" )
        , ( "timeline", Encode.object (timelineBase ++ rangeFields) )
        , ( "elements", Encode.object elements )
        , ( "iterations", encodeIterations processed.iterations )
        , ( "direction", encodeAnimationDirection processed.animationDirection )
        ]
