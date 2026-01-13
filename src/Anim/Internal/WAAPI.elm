module Anim.Internal.WAAPI exposing
    ( AnimBuilder
    , AnimState
    , allComplete
    , animate
    , animateStateless
    , anyRunning
    , builder
    , delay
    , duration
    , easing
    , encode
    , getCurrentBackgroundColor
    , getCurrentOpacity
    , getCurrentPosition
    , getCurrentRotate
    , getCurrentScale
    , getCurrentSize
    , getEndBackgroundColor
    , getEndOpacity
    , getEndPosition
    , getEndRotate
    , getEndScale
    , getEndSize
    , getOpacityRange
    , getRotateRange
    , getScaleRange
    , getSizeRange
    , getStartBackgroundColor
    , getStartOpacity
    , getStartPosition
    , getStartRotate
    , getStartScale
    , getStartSize
    , init
    , isElementComplete
    , isElementRunning
    , perspective
    , perspectiveWith
    , resetElement
    , restartElement
    , speed
    , update
    )

import Anim.Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Builders.BackgroundColor as BackgroundColor
import Anim.Internal.Builders.FontColor as FontColor
import Anim.Internal.Builders.Opacity as Opacity
import Anim.Internal.Builders.Position as Position
import Anim.Internal.Builders.Rotate as Rotate
import Anim.Internal.Builders.Scale as Scale
import Anim.Internal.Builders.Size as Size
import Anim.Internal.Easing as Easing
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Color as Color exposing (Color(..))
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Position as Position exposing (Position)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Properties.Size as Size exposing (Size)
import Dict exposing (Dict)
import Html
import Html.Attributes
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode



-- Build


type alias AnimBuilder =
    Builder.AnimBuilder


type alias ElementId =
    String


type AnimationStatus
    = NotStarted
    | Running
    | Complete


type alias ElementEndStates =
    { position : Maybe Position
    , rotate : Maybe Rotate
    , scale : Maybe Scale
    , backgroundColor : Maybe Color
    , fontColor : Maybe Color
    , opacity : Maybe Opacity
    , size : Maybe Size
    }


emptyElementEndStates : ElementEndStates
emptyElementEndStates =
    { position = Nothing
    , rotate = Nothing
    , scale = Nothing
    , backgroundColor = Nothing
    , fontColor = Nothing
    , opacity = Nothing
    , size = Nothing
    }


type alias PropertyAnimation =
    { version : Int
    , status : AnimationStatus
    }


type alias ElementAnimation =
    { currentStates : ElementEndStates -- Updated by JavaScript during playback
    , properties : Dict String PropertyAnimation -- Tracks version and status per property type ("position", "opacity", etc.)
    }


type AnimState
    = AnimState
        { elementAnimations : Dict ElementId ElementAnimation
        , isRunning : Bool
        , builder : AnimBuilder
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


duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Builder.duration


speed : Float -> AnimBuilder -> AnimBuilder
speed =
    Builder.speed


easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Builder.easing


delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Builder.delay


perspective : String -> Float -> AnimBuilder -> AnimBuilder
perspective =
    Builder.perspective


perspectiveWith : Float -> List (Html.Attribute msg)
perspectiveWith perspectiveValue =
    [ Html.Attributes.style "perspective" (String.fromFloat perspectiveValue ++ "px")
    , Html.Attributes.style "transform-style" "preserve-3d"
    , Html.Attributes.attribute "data-perspective-source" "elm"
    ]



-- Execute Animation


animateStateless : (Encode.Value -> Cmd msg) -> AnimBuilder -> Cmd msg
animateStateless portFunction animBuilder =
    let
        builderWithCache =
            Builder.computeAndCachePerspectiveStyles animBuilder

        processedData =
            Builder.processAnimationData builderWithCache

        encodedData =
            encode processedData
    in
    portFunction encodedData


animate : AnimState -> AnimBuilder -> ( AnimState, Encode.Value )
animate (AnimState state) builder_ =
    let
        builderWithCache =
            Builder.computeAndCachePerspectiveStyles builder_

        -- Temporarily disable current state injection to test if end states are correct
        -- builderWithCurrentStates =
        --     Dict.foldl injectCurrentStatesForElement builderWithCache state.elementAnimations
        processedData =
            Builder.processAnimationData builderWithCache

        -- Create element animations from processed data with property-level versioning
        newElementAnimations =
            processedData.elements
                |> Dict.map
                    (\elementId elementConfig ->
                        let
                            -- Get existing element animation to preserve states and versions for non-animated properties
                            existingAnimation =
                                Dict.get elementId state.elementAnimations

                            -- Use current states from existing animation if available, otherwise empty
                            currentStates =
                                existingAnimation
                                    |> Maybe.map .currentStates
                                    |> Maybe.withDefault emptyElementEndStates

                            -- Get existing property versions
                            existingPropertyVersions =
                                existingAnimation
                                    |> Maybe.map .properties
                                    |> Maybe.withDefault Dict.empty

                            -- Create new property versions for properties in this animation
                            newPropertyVersions =
                                elementConfig.properties
                                    |> List.map
                                        (\property ->
                                            let
                                                propType =
                                                    propertyTypeString property

                                                newVersion =
                                                    Dict.get propType existingPropertyVersions
                                                        |> Maybe.map .version
                                                        |> Maybe.map ((+) 1)
                                                        |> Maybe.withDefault 1
                                            in
                                            ( propType
                                            , { version = newVersion
                                              , status = NotStarted
                                              }
                                            )
                                        )
                                    |> Dict.fromList

                            -- Merge new property versions with existing ones (new ones take precedence)
                            mergedPropertyVersions =
                                Dict.union newPropertyVersions existingPropertyVersions
                        in
                        { currentStates = currentStates
                        , properties = mergedPropertyVersions
                        }
                    )

        -- Merge with existing animations, preserving non-animated property tracking
        updatedElementAnimations =
            Dict.foldl
                (\elementId newAnim acc ->
                    case Dict.get elementId acc of
                        Nothing ->
                            -- New element, just insert
                            Dict.insert elementId newAnim acc

                        Just existingAnim ->
                            -- Existing element, merge property versions
                            let
                                mergedProperties =
                                    Dict.union newAnim.properties existingAnim.properties
                            in
                            Dict.insert elementId
                                { currentStates = newAnim.currentStates
                                , properties = mergedProperties
                                }
                                acc
                )
                state.elementAnimations
                newElementAnimations

        -- Save each element's animation to history before clearing
        builderWithHistory =
            Dict.foldl
                (\elementId _ accBuilder ->
                    Builder.addAnimationToHistory elementId processedData Nothing accBuilder
                        |> Tuple.first
                )
                builderWithCache
                processedData.elements
    in
    ( AnimState
        { elementAnimations = updatedElementAnimations
        , isRunning = not (Dict.isEmpty newElementAnimations)
        , builder =
            builderWithHistory
                |> Builder.markDirty
                |> Builder.clearCurrentElement
        }
    , encodeWithVersions updatedElementAnimations processedData
    )


propertyTypeString : Builder.ProcessedPropertyConfig -> String
propertyTypeString property =
    case property of
        Builder.ProcessedPositionConfig _ ->
            "position"

        Builder.ProcessedRotateConfig _ ->
            "rotate"

        Builder.ProcessedScaleConfig _ ->
            "scale"

        Builder.ProcessedBackgroundColorConfig _ ->
            "backgroundColor"

        Builder.ProcessedFontColorConfig _ ->
            "fontColor"

        Builder.ProcessedOpacityConfig _ ->
            "opacity"

        Builder.ProcessedSizeConfig _ ->
            "size"


extractElementEndStates : Builder.ProcessedElementConfig -> ElementEndStates
extractElementEndStates elementConfig =
    let
        extractPropertyEndState : Builder.ProcessedPropertyConfig -> ElementEndStates -> ElementEndStates
        extractPropertyEndState property state =
            case property of
                Builder.ProcessedPositionConfig config ->
                    { state | position = Just config.end }

                Builder.ProcessedRotateConfig config ->
                    { state | rotate = Just config.end }

                Builder.ProcessedScaleConfig config ->
                    { state | scale = Just config.end }

                Builder.ProcessedBackgroundColorConfig config ->
                    { state | backgroundColor = Just config.end }

                Builder.ProcessedFontColorConfig config ->
                    { state | fontColor = Just config.end }

                Builder.ProcessedOpacityConfig config ->
                    { state | opacity = Just config.end }

                Builder.ProcessedSizeConfig config ->
                    { state | size = Just config.end }
    in
    List.foldl extractPropertyEndState emptyElementEndStates elementConfig.properties


extractElementStartStates : Builder.ProcessedElementConfig -> ElementEndStates
extractElementStartStates elementConfig =
    let
        extractPropertyStartState : Builder.ProcessedPropertyConfig -> ElementEndStates -> ElementEndStates
        extractPropertyStartState property state =
            case property of
                Builder.ProcessedPositionConfig config ->
                    { state | position = config.start }

                Builder.ProcessedRotateConfig config ->
                    { state | rotate = config.start }

                Builder.ProcessedScaleConfig config ->
                    { state | scale = config.start }

                Builder.ProcessedBackgroundColorConfig config ->
                    { state | backgroundColor = config.start }

                Builder.ProcessedFontColorConfig config ->
                    { state | fontColor = config.start }

                Builder.ProcessedOpacityConfig config ->
                    { state | opacity = config.start }

                Builder.ProcessedSizeConfig config ->
                    { state | size = config.start }
    in
    List.foldl extractPropertyStartState emptyElementEndStates elementConfig.properties


injectCurrentStatesForElement : ElementId -> ElementAnimation -> AnimBuilder -> AnimBuilder
injectCurrentStatesForElement elementId elementAnim baseBuilder =
    case Builder.getElementConfig elementId baseBuilder of
        Just elementConfig ->
            let
                updatedProperties =
                    List.map (injectCurrentStateIntoProperty elementAnim.currentStates) elementConfig.properties

                updatedElementConfig =
                    { elementConfig | properties = updatedProperties }
            in
            Builder.updateElementConfig elementId updatedElementConfig baseBuilder

        Nothing ->
            baseBuilder


injectCurrentStateIntoProperty : ElementEndStates -> Builder.PropertyConfig -> Builder.PropertyConfig
injectCurrentStateIntoProperty currentStates propertyConfig =
    case propertyConfig of
        Builder.PositionConfig config ->
            Builder.PositionConfig
                { config
                    | start =
                        case config.start of
                            Just _ ->
                                config.start

                            Nothing ->
                                currentStates.position
                }

        Builder.RotateConfig config ->
            Builder.RotateConfig
                { config
                    | start =
                        case config.start of
                            Just _ ->
                                config.start

                            Nothing ->
                                currentStates.rotate
                }

        Builder.ScaleConfig config ->
            Builder.ScaleConfig
                { config
                    | start =
                        case config.start of
                            Just _ ->
                                config.start

                            Nothing ->
                                currentStates.scale
                }

        Builder.OpacityConfig config ->
            Builder.OpacityConfig
                { config
                    | start =
                        case config.start of
                            Just _ ->
                                config.start

                            Nothing ->
                                currentStates.opacity
                }

        Builder.BackgroundColorConfig config ->
            Builder.BackgroundColorConfig
                { config
                    | start =
                        case config.start of
                            Just _ ->
                                config.start

                            Nothing ->
                                currentStates.backgroundColor
                }

        Builder.FontColorConfig config ->
            Builder.FontColorConfig
                { config
                    | start =
                        case config.start of
                            Just _ ->
                                config.start

                            Nothing ->
                                currentStates.fontColor
                }

        Builder.SizeConfig config ->
            Builder.SizeConfig
                { config
                    | start =
                        case config.start of
                            Just _ ->
                                config.start

                            Nothing ->
                                currentStates.size
                }



-- Update


update : Decode.Value -> AnimState -> AnimState
update jsonValue (AnimState state) =
    case Decode.decodeValue animationUpdateDecoder jsonValue of
        Ok animationUpdate ->
            let
                updatedAnimations =
                    Dict.update animationUpdate.elementId
                        (Maybe.map (updateElementAnimation animationUpdate))
                        state.elementAnimations

                -- Remove completed animations to prevent memory leaks
                -- Element is fully complete when all properties are complete
                cleanedAnimations =
                    Dict.filter
                        (\_ elementAnim ->
                            Dict.values elementAnim.properties
                                |> List.any (\prop -> prop.status /= Complete)
                        )
                        updatedAnimations

                -- Update global isRunning based on remaining animations
                hasRunningAnimations =
                    Dict.values cleanedAnimations
                        |> List.any
                            (\elementAnim ->
                                Dict.values elementAnim.properties
                                    |> List.any (\prop -> prop.status == Running)
                            )
            in
            AnimState
                { state
                    | elementAnimations = cleanedAnimations
                    , isRunning = hasRunningAnimations
                }

        Err _ ->
            -- Silently ignore decode errors since we control the data shape
            AnimState state


updateElementAnimation : AnimationUpdate -> ElementAnimation -> ElementAnimation
updateElementAnimation animUpdate elementAnimation =
    let
        newCurrentStates =
            { position = Just (Position.fromTriple ( animUpdate.positionX, animUpdate.positionY, animUpdate.positionZ ))
            , rotate = Just (Rotate.fromTriple ( animUpdate.rotationX, animUpdate.rotationY, animUpdate.rotationZ ))
            , scale = Just (Scale.fromTriple ( animUpdate.scaleX, animUpdate.scaleY, animUpdate.scaleZ ))
            , opacity = Just (Opacity.fromFloat animUpdate.opacity)
            , backgroundColor = Color.fromString animUpdate.backgroundColor
            , fontColor = Color.fromString animUpdate.color
            , size = Just (Size.fromTuple ( animUpdate.width, animUpdate.height ))
            }

        newStatus =
            if animUpdate.isAnimating then
                Running

            else
                Complete

        -- Only update properties where the version matches the current tracked version
        -- This prevents stale JavaScript updates from overwriting newer animations
        updatedProperties =
            elementAnimation.properties
                |> Dict.map
                    (\propType propAnim ->
                        case Dict.get propType animUpdate.propertyVersions of
                            Nothing ->
                                -- Property not in update, keep existing
                                propAnim

                            Just updateVersion ->
                                -- Check if version matches
                                if updateVersion == propAnim.version then
                                    { propAnim | status = newStatus }

                                else
                                    -- Version mismatch, ignore this update for this property
                                    propAnim
                    )
    in
    { elementAnimation
        | currentStates = newCurrentStates
        , properties = updatedProperties
    }



-- Query State


allComplete : AnimState -> Maybe Bool
allComplete (AnimState state) =
    if Dict.isEmpty state.elementAnimations then
        Nothing

    else
        -- Check if all properties in all elements have Complete status
        Dict.values state.elementAnimations
            |> List.all
                (\elementAnim ->
                    Dict.values elementAnim.properties
                        |> List.all (\prop -> prop.status == Complete)
                )
            |> Just


anyRunning : AnimState -> Bool
anyRunning (AnimState state) =
    not (Dict.isEmpty state.elementAnimations) && state.isRunning


isElementComplete : String -> AnimState -> Maybe Bool
isElementComplete elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.map
            (\elementAnimation ->
                Dict.values elementAnimation.properties
                    |> List.all (\prop -> prop.status == Complete)
            )


isElementRunning : String -> AnimState -> Bool
isElementRunning elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Nothing ->
            False

        Just elementAnimation ->
            Dict.values elementAnimation.properties
                |> List.any (\prop -> prop.status == Running)



-- Query Animated Properties
--
--
-- Helper functions for extracting property ranges


getPropertyRange :
    String
    -> AnimState
    -> (Builder.ProcessedPropertyConfig -> Maybe { start : Maybe a, end : a })
    -> Maybe { start : Maybe a, end : a }
getPropertyRange elementId (AnimState state) extractor =
    state.builder
        |> Builder.processAnimationData
        |> .elements
        |> Dict.get elementId
        |> Maybe.andThen
            (\{ properties } ->
                properties
                    |> List.filterMap extractor
                    |> List.head
            )


getStartWithDefault : a -> Maybe { start : Maybe a, end : a } -> Maybe a
getStartWithDefault default maybeRange =
    case maybeRange of
        Nothing ->
            Just default

        Just { start } ->
            start



-- Background Color


getStartBackgroundColor : String -> AnimState -> Maybe Color
getStartBackgroundColor elementId animState =
    getBackgroundColorRange elementId animState
        |> getStartWithDefault BackgroundColor.default


getEndBackgroundColor : String -> AnimState -> Maybe Color
getEndBackgroundColor elementId animState =
    getBackgroundColorRange elementId animState
        |> Maybe.map .end


getCurrentBackgroundColor : String -> AnimState -> Maybe Color
getCurrentBackgroundColor elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .backgroundColor)


getBackgroundColorRange : String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange elementId animState =
    getPropertyRange elementId animState <|
        \prop ->
            case prop of
                Builder.ProcessedBackgroundColorConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Opacity


getStartOpacity : String -> AnimState -> Maybe Opacity
getStartOpacity elementId animState =
    getOpacityRange elementId animState
        |> getStartWithDefault Opacity.default


getEndOpacity : String -> AnimState -> Maybe Opacity
getEndOpacity elementId animState =
    getOpacityRange elementId animState
        |> Maybe.map .end


getCurrentOpacity : String -> AnimState -> Maybe Opacity
getCurrentOpacity elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .opacity)


getOpacityRange : String -> AnimState -> Maybe { start : Maybe Opacity, end : Opacity }
getOpacityRange elementId animState =
    getPropertyRange elementId animState <|
        \prop ->
            case prop of
                Builder.ProcessedOpacityConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Position


getStartPosition : String -> AnimState -> Maybe Position
getStartPosition elementId animState =
    getPositionRange elementId animState
        |> getStartWithDefault Position.default


getEndPosition : String -> AnimState -> Maybe Position
getEndPosition elementId animState =
    getPositionRange elementId animState
        |> Maybe.map .end


getCurrentPosition : String -> AnimState -> Maybe Position
getCurrentPosition elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .position)


getPositionRange : String -> AnimState -> Maybe { start : Maybe Position, end : Position }
getPositionRange elementId animState =
    getPropertyRange elementId animState <|
        \prop ->
            case prop of
                Builder.ProcessedPositionConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Rotate


getStartRotate : String -> AnimState -> Maybe Rotate
getStartRotate elementId animState =
    getRotateRange elementId animState
        |> getStartWithDefault Rotate.default


getEndRotate : String -> AnimState -> Maybe Rotate
getEndRotate elementId animState =
    getRotateRange elementId animState
        |> Maybe.map .end


getCurrentRotate : String -> AnimState -> Maybe Rotate
getCurrentRotate elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .rotate)


getRotateRange : String -> AnimState -> Maybe { start : Maybe Rotate, end : Rotate }
getRotateRange elementId animState =
    getPropertyRange elementId animState <|
        \prop ->
            case prop of
                Builder.ProcessedRotateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Scale


getStartScale : String -> AnimState -> Maybe Scale
getStartScale elementId animState =
    getScaleRange elementId animState
        |> getStartWithDefault Scale.default


getEndScale : String -> AnimState -> Maybe Scale
getEndScale elementId animState =
    getScaleRange elementId animState
        |> Maybe.map .end


getCurrentScale : String -> AnimState -> Maybe Scale
getCurrentScale elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .scale)


getScaleRange : String -> AnimState -> Maybe { start : Maybe Scale, end : Scale }
getScaleRange elementId animState =
    getPropertyRange elementId animState <|
        \prop ->
            case prop of
                Builder.ProcessedScaleConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Size


getStartSize : String -> AnimState -> Maybe Size
getStartSize elementId animState =
    getSizeRange elementId animState
        |> getStartWithDefault Size.default


getEndSize : String -> AnimState -> Maybe Size
getEndSize elementId animState =
    getSizeRange elementId animState
        |> Maybe.map .end


getCurrentSize : String -> AnimState -> Maybe Size
getCurrentSize elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .size)


getSizeRange : String -> AnimState -> Maybe { start : Maybe Size, end : Size }
getSizeRange elementId animState =
    getPropertyRange elementId animState <|
        \prop ->
            case prop of
                Builder.ProcessedSizeConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Decoders


type alias AnimationUpdate =
    { elementId : String
    , positionX : Float
    , positionY : Float
    , positionZ : Float
    , opacity : Float
    , rotationX : Float
    , rotationY : Float
    , rotationZ : Float
    , scaleX : Float
    , scaleY : Float
    , scaleZ : Float
    , backgroundColor : String
    , color : String
    , width : Float
    , height : Float
    , isAnimating : Bool
    , propertyVersions : Dict String Int -- Maps property type to version number
    }


animationUpdateDecoder : Decoder AnimationUpdate
animationUpdateDecoder =
    Decode.succeed AnimationUpdate
        |> andMap (Decode.field "elementId" Decode.string)
        |> andMap (Decode.field "positionX" Decode.float)
        |> andMap (Decode.field "positionY" Decode.float)
        |> andMap (Decode.field "positionZ" Decode.float)
        |> andMap (Decode.field "opacity" Decode.float)
        |> andMap (Decode.field "rotationX" Decode.float)
        |> andMap (Decode.field "rotationY" Decode.float)
        |> andMap (Decode.field "rotationZ" Decode.float)
        |> andMap (Decode.field "scaleX" Decode.float)
        |> andMap (Decode.field "scaleY" Decode.float)
        |> andMap (Decode.field "scaleZ" Decode.float)
        |> andMap (Decode.field "backgroundColor" Decode.string)
        |> andMap (Decode.field "color" Decode.string)
        |> andMap (Decode.field "width" Decode.float)
        |> andMap (Decode.field "height" Decode.float)
        |> andMap (Decode.field "isAnimating" Decode.bool)
        |> andMap (Decode.field "propertyVersions" (Decode.dict Decode.int))


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)



-- Encoders


encodeWithVersions : Dict ElementId ElementAnimation -> Builder.ProcessedAnimationData -> Encode.Value
encodeWithVersions elementAnimations data =
    let
        elementsWithVersions =
            data.elements
                |> Dict.toList
                |> List.map
                    (\( elementId, config ) ->
                        ( elementId
                        , encodeProcessedElementConfigWithVersions elementAnimations elementId config
                        )
                    )
    in
    Encode.object
        [ ( "elements", Encode.object elementsWithVersions )
        , ( "globalPerspective", encodeMaybePerspective data.globalPerspective )
        ]


encode : Builder.ProcessedAnimationData -> Encode.Value
encode data =
    Encode.object
        [ ( "elements", Encode.dict identity encodeProcessedElementConfig data.elements )
        , ( "globalPerspective", encodeMaybePerspective data.globalPerspective )
        ]


encodeMaybePerspective : Maybe { containerId : String, value : Float } -> Encode.Value
encodeMaybePerspective maybePerspective =
    case maybePerspective of
        Nothing ->
            Encode.null

        Just perspectiveData ->
            Encode.object
                [ ( "containerId", Encode.string perspectiveData.containerId )
                , ( "value", Encode.float perspectiveData.value )
                ]


encodeProcessedElementConfigWithVersions : Dict ElementId ElementAnimation -> String -> Builder.ProcessedElementConfig -> Encode.Value
encodeProcessedElementConfigWithVersions elementAnimations elementId config =
    let
        elementProps =
            Dict.get elementId elementAnimations
                |> Maybe.map .properties
                |> Maybe.withDefault Dict.empty
    in
    Encode.object
        [ ( "properties", Encode.list (encodeProcessedPropertyConfigWithVersion elementProps) config.properties ) ]


encodeProcessedElementConfig : Builder.ProcessedElementConfig -> Encode.Value
encodeProcessedElementConfig config =
    Encode.object
        [ ( "properties", Encode.list encodeProcessedPropertyConfig config.properties ) ]


encodeProcessedPropertyConfigWithVersion : Dict String PropertyAnimation -> Builder.ProcessedPropertyConfig -> Encode.Value
encodeProcessedPropertyConfigWithVersion propertyVersions property =
    let
        propType =
            propertyTypeString property

        version =
            Dict.get propType propertyVersions
                |> Maybe.map .version
                |> Maybe.withDefault 1

        versionField =
            ( "version", Encode.int version )
    in
    case property of
        Builder.ProcessedPositionConfig config ->
            let
                ( endX, endY, endZ ) =
                    Position.toTriple config.end

                ( startX, startY, startZ ) =
                    config.start
                        |> Maybe.map Position.toTriple
                        |> Maybe.withDefault ( 0, 0, 0 )

                baseFields =
                    [ ( "type", Encode.string "position" )
                    , versionField
                    , ( "endX", Encode.float endX )
                    , ( "endY", Encode.float endY )
                    , ( "endZ", Encode.float endZ )
                    , ( "startX", Encode.float startX )
                    , ( "startY", Encode.float startY )
                    , ( "startZ", Encode.float startZ )
                    , ( "duration", Encode.int config.duration )
                    , ( "perspective", encodeMaybePerspective config.perspective )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedScaleConfig config ->
            let
                ( endX, endY, endZ ) =
                    Scale.toTriple config.end

                ( startX, startY, startZ ) =
                    config.start
                        |> Maybe.map Scale.toTriple
                        |> Maybe.withDefault ( 1, 1, 1 )

                baseFields =
                    [ ( "type", Encode.string "scale" )
                    , versionField
                    , ( "endX", Encode.float endX )
                    , ( "endY", Encode.float endY )
                    , ( "endZ", Encode.float endZ )
                    , ( "startX", Encode.float startX )
                    , ( "startY", Encode.float startY )
                    , ( "startZ", Encode.float startZ )
                    , ( "duration", Encode.int config.duration )
                    , ( "perspective", encodeMaybePerspective config.perspective )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedRotateConfig config ->
            let
                ( endX, endY, endZ ) =
                    Rotate.toTriple config.end

                ( startX, startY, startZ ) =
                    config.start
                        |> Maybe.map Rotate.toTriple
                        |> Maybe.withDefault ( 0, 0, 0 )

                baseFields =
                    [ ( "type", Encode.string "rotate" )
                    , versionField
                    , ( "endX", Encode.float endX )
                    , ( "endY", Encode.float endY )
                    , ( "endZ", Encode.float endZ )
                    , ( "startX", Encode.float startX )
                    , ( "startY", Encode.float startY )
                    , ( "startZ", Encode.float startZ )
                    , ( "duration", Encode.int config.duration )
                    , ( "perspective", encodeMaybePerspective config.perspective )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedSizeConfig config ->
            let
                ( width, height ) =
                    Size.toTuple config.end

                ( startWidth, startHeight ) =
                    config.start
                        |> Maybe.map Size.toTuple
                        |> Maybe.withDefault ( 0, 0 )

                baseFields =
                    [ ( "type", Encode.string "size" )
                    , versionField
                    , ( "endWidth", Encode.float width )
                    , ( "endHeight", Encode.float height )
                    , ( "startWidth", Encode.float startWidth )
                    , ( "startHeight", Encode.float startHeight )
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedOpacityConfig config ->
            let
                startValue =
                    config.start
                        |> Maybe.map Opacity.toFloat
                        |> Maybe.withDefault 1.0

                baseFields =
                    [ ( "type", Encode.string "opacity" )
                    , versionField
                    , ( "endValue", Encode.float (Opacity.toFloat config.end) )
                    , ( "startValue", Encode.float startValue )
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedBackgroundColorConfig config ->
            let
                startColor =
                    config.start
                        |> Maybe.map Color.toCssString
                        |> Maybe.withDefault (Color.toCssString BackgroundColor.default)

                baseFields =
                    [ ( "type", Encode.string "backgroundColor" )
                    , versionField
                    , ( "endColor", Encode.string (Color.toCssString config.end) )
                    , ( "startColor", Encode.string startColor )
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedFontColorConfig config ->
            let
                startColor =
                    config.start
                        |> Maybe.map Color.toCssString
                        |> Maybe.withDefault "rgba(0, 0, 0, 1)"

                baseFields =
                    [ ( "type", Encode.string "color" )
                    , versionField
                    , ( "endColor", Encode.string (Color.toCssString config.end) )
                    , ( "startColor", Encode.string startColor )
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)


encodeProcessedPropertyConfig : Builder.ProcessedPropertyConfig -> Encode.Value
encodeProcessedPropertyConfig property =
    case property of
        Builder.ProcessedPositionConfig config ->
            let
                ( endX, endY, endZ ) =
                    Position.toTriple config.end

                ( startX, startY, startZ ) =
                    config.start
                        |> Maybe.map Position.toTriple
                        |> Maybe.withDefault ( 0, 0, 0 )

                baseFields =
                    [ ( "type", Encode.string "position" )
                    , ( "endX", Encode.float endX )
                    , ( "endY", Encode.float endY )
                    , ( "endZ", Encode.float endZ )
                    , ( "startX", Encode.float startX )
                    , ( "startY", Encode.float startY )
                    , ( "startZ", Encode.float startZ )
                    , ( "duration", Encode.int config.duration )
                    , ( "perspective", encodeMaybePerspective config.perspective )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedScaleConfig config ->
            let
                ( endX, endY, endZ ) =
                    Scale.toTriple config.end

                ( startX, startY, startZ ) =
                    config.start
                        |> Maybe.map Scale.toTriple
                        |> Maybe.withDefault ( 1, 1, 1 )

                baseFields =
                    [ ( "type", Encode.string "scale" )
                    , ( "endX", Encode.float endX )
                    , ( "endY", Encode.float endY )
                    , ( "endZ", Encode.float endZ )
                    , ( "startX", Encode.float startX )
                    , ( "startY", Encode.float startY )
                    , ( "startZ", Encode.float startZ )
                    , ( "duration", Encode.int config.duration )
                    , ( "perspective", encodeMaybePerspective config.perspective )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedRotateConfig config ->
            let
                ( endX, endY, endZ ) =
                    Rotate.toTriple config.end

                ( startX, startY, startZ ) =
                    config.start
                        |> Maybe.map Rotate.toTriple
                        |> Maybe.withDefault ( 0, 0, 0 )

                baseFields =
                    [ ( "type", Encode.string "rotate" )
                    , ( "endX", Encode.float endX )
                    , ( "endY", Encode.float endY )
                    , ( "endZ", Encode.float endZ )
                    , ( "startX", Encode.float startX )
                    , ( "startY", Encode.float startY )
                    , ( "startZ", Encode.float startZ )
                    , ( "duration", Encode.int config.duration )
                    , ( "perspective", encodeMaybePerspective config.perspective )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedSizeConfig config ->
            let
                ( width, height ) =
                    Size.toTuple config.end

                ( startWidth, startHeight ) =
                    config.start
                        |> Maybe.map Size.toTuple
                        |> Maybe.withDefault ( 0, 0 )

                baseFields =
                    [ ( "type", Encode.string "size" )
                    , ( "endWidth", Encode.float width )
                    , ( "endHeight", Encode.float height )
                    , ( "startWidth", Encode.float startWidth )
                    , ( "startHeight", Encode.float startHeight )
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedOpacityConfig config ->
            let
                startValue =
                    config.start
                        |> Maybe.map Opacity.toFloat
                        |> Maybe.withDefault 1.0

                baseFields =
                    [ ( "type", Encode.string "opacity" )
                    , ( "endValue", Encode.float (Opacity.toFloat config.end) )
                    , ( "startValue", Encode.float startValue )
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedBackgroundColorConfig config ->
            let
                startColor =
                    config.start
                        |> Maybe.map Color.toCssString
                        |> Maybe.withDefault (Color.toCssString BackgroundColor.default)

                baseFields =
                    [ ( "type", Encode.string "backgroundColor" )
                    , ( "endColor", Encode.string (Color.toCssString config.end) )
                    , ( "startColor", Encode.string startColor )
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedFontColorConfig config ->
            let
                startColor =
                    config.start
                        |> Maybe.map Color.toCssString
                        |> Maybe.withDefault "rgba(0, 0, 0, 1)"

                baseFields =
                    [ ( "type", Encode.string "color" )
                    , ( "endColor", Encode.string (Color.toCssString config.end) )
                    , ( "startColor", Encode.string startColor )
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.easing
            in
            Encode.object (baseFields ++ easingFields)


{-| Encode easing with keyframes for complex easings (Bounce, Elastic).
For complex easings, returns list with easing="linear" and keyframes array.
For simple easings, returns list with just easing string.
-}
encodeEasingWithKeyframes : Easing -> List ( String, Encode.Value )
encodeEasingWithKeyframes easingValue =
    if isComplexEasing easingValue then
        [ ( "easing", Encode.string "linear" )
        , ( "easingKeyframes", Encode.list Encode.float (Easing.generateKeyframes easingValue) )
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

        BounceIn ->
            True

        BounceOut ->
            True

        BounceInOut ->
            True

        _ ->
            False


{-| Empty command structure that JavaScript can safely ignore.
-}
emptyCommand : Encode.Value
emptyCommand =
    Encode.object
        [ ( "elements", Encode.object [] )
        , ( "globalPerspective", Encode.null )
        ]


{-| Reset an element to its initial animation state by resetting internal state and creating a 0ms animation to start positions.
-}
resetElement : String -> AnimState -> ( AnimState, Encode.Value )
resetElement elementId (AnimState state) =
    case Builder.getCurrentAnimation elementId state.builder |> Debug.log "Reset Animation" of
        Nothing ->
            -- No animation in history to reset
            ( AnimState state, emptyCommand )

        Just historyEntry ->
            let
                -- Extract start and end states from the animation history
                startStates =
                    historyEntry.processedData.elements
                        |> Dict.get elementId
                        |> Maybe.map extractElementStartStates
                        |> Maybe.withDefault emptyElementEndStates

                endStates =
                    historyEntry.processedData.elements
                        |> Dict.get elementId
                        |> Maybe.map extractElementEndStates
                        |> Maybe.withDefault emptyElementEndStates

                -- Get properties that were in the original animation
                animatedPropertyTypes =
                    historyEntry.processedData.elements
                        |> Dict.get elementId
                        |> Maybe.map .properties
                        |> Maybe.withDefault []
                        |> List.map propertyTypeString

                -- Create 0ms animation to visually jump to start positions
                resetBuilder =
                    Builder.init
                        |> Builder.duration 0
                        |> Builder.easing Linear
                        |> Builder.for elementId
                        |> addResetProperties elementId endStates startStates

                builderWithCache =
                    Builder.computeAndCachePerspectiveStyles resetBuilder

                processedData =
                    Builder.processAnimationData builderWithCache

                resetCommands =
                    encode processedData
            in
            case Dict.get elementId state.elementAnimations of
                Nothing ->
                    -- No tracking entry, create one with property versions
                    let
                        newProperties =
                            animatedPropertyTypes
                                |> List.map (\propType -> ( propType, { version = 1, status = NotStarted } ))
                                |> Dict.fromList

                        newElementAnimation =
                            { currentStates = startStates
                            , properties = newProperties
                            }

                        updatedElementAnimations =
                            Dict.insert elementId newElementAnimation state.elementAnimations

                        updatedAnimState =
                            AnimState
                                { state
                                    | elementAnimations = updatedElementAnimations
                                    , isRunning = False
                                }
                    in
                    ( updatedAnimState, resetCommands )

                Just elementAnimation ->
                    -- Existing tracking entry, increment versions for reset properties
                    let
                        updatedProperties =
                            elementAnimation.properties
                                |> Dict.map
                                    (\propType propAnim ->
                                        if List.member propType animatedPropertyTypes then
                                            { propAnim
                                                | version = propAnim.version + 1
                                                , status = NotStarted
                                            }

                                        else
                                            propAnim
                                    )

                        resetElementAnimation =
                            { elementAnimation
                                | currentStates = startStates
                                , properties = updatedProperties
                            }

                        updatedElementAnimations =
                            Dict.insert elementId resetElementAnimation state.elementAnimations

                        updatedAnimState =
                            AnimState
                                { state
                                    | elementAnimations = updatedElementAnimations
                                    , isRunning =
                                        Dict.values updatedElementAnimations
                                            |> List.any
                                                (\anim ->
                                                    Dict.values anim.properties
                                                        |> List.any (\prop -> prop.status == Running)
                                                )
                                }
                    in
                    ( updatedAnimState, resetCommands )


{-| Restart the last animation by retrieving it from Builder history and replaying it.
-}
restartElement : String -> AnimState -> ( AnimState, Encode.Value )
restartElement elementId (AnimState state) =
    case Builder.restartCurrentAnimation elementId state.builder of
        Nothing ->
            -- No animation in history to restart
            ( AnimState state, emptyCommand )

        Just processedData ->
            -- Get properties that are being restarted
            let
                restartedPropertyTypes =
                    processedData.elements
                        |> Dict.get elementId
                        |> Maybe.map .properties
                        |> Maybe.withDefault []
                        |> List.map propertyTypeString

                startStates =
                    processedData.elements
                        |> Dict.get elementId
                        |> Maybe.map extractElementStartStates
                        |> Maybe.withDefault emptyElementEndStates
            in
            case Dict.get elementId state.elementAnimations of
                Nothing ->
                    -- No tracking entry exists, create one with property versions
                    let
                        newProperties =
                            restartedPropertyTypes
                                |> List.map (\propType -> ( propType, { version = 1, status = NotStarted } ))
                                |> Dict.fromList

                        newElementAnimation =
                            { currentStates = startStates
                            , properties = newProperties
                            }

                        updatedElementAnimations =
                            Dict.insert elementId newElementAnimation state.elementAnimations

                        updatedAnimState =
                            AnimState
                                { state
                                    | elementAnimations = updatedElementAnimations
                                    , isRunning = True
                                }
                    in
                    ( updatedAnimState, encode processedData )

                Just elementAnimation ->
                    -- Update existing entry, incrementing versions for restarted properties
                    let
                        updatedProperties =
                            restartedPropertyTypes
                                |> List.foldl
                                    (\propType acc ->
                                        let
                                            newVersion =
                                                Dict.get propType elementAnimation.properties
                                                    |> Maybe.map .version
                                                    |> Maybe.map ((+) 1)
                                                    |> Maybe.withDefault 1
                                        in
                                        Dict.insert propType
                                            { version = newVersion, status = NotStarted }
                                            acc
                                    )
                                    elementAnimation.properties

                        resetElementAnimation =
                            { elementAnimation
                                | currentStates = startStates
                                , properties = updatedProperties
                            }

                        updatedElementAnimations =
                            Dict.insert elementId resetElementAnimation state.elementAnimations

                        updatedAnimState =
                            AnimState
                                { state
                                    | elementAnimations = updatedElementAnimations
                                    , isRunning = True
                                }
                    in
                    ( updatedAnimState, encode processedData )


{-| Helper to add reset properties to a builder for all animated properties.
-}
addResetProperties : String -> ElementEndStates -> ElementEndStates -> AnimBuilder -> AnimBuilder
addResetProperties elementId endStates startStates builderState =
    let
        -- Use the actual stored start states to reset each property that was animated
        builderWithPosition =
            case ( endStates.position, startStates.position ) of
                ( Just _, Just startPosition ) ->
                    let
                        ( startX, startY, startZ ) =
                            Position.toTriple startPosition
                    in
                    builderState
                        |> Position.for elementId
                        |> Position.toXYZ startX startY startZ
                        -- Only set target, let system inject current position as start
                        |> Position.build

                _ ->
                    builderState

        builderWithOpacity =
            case ( endStates.opacity, startStates.opacity ) of
                ( Just _, Just startOpacity ) ->
                    builderWithPosition
                        |> Opacity.for elementId
                        |> Opacity.to startOpacity
                        |> Opacity.build

                _ ->
                    builderWithPosition

        builderWithScale =
            case ( endStates.scale, startStates.scale ) of
                ( Just _, Just startScale ) ->
                    let
                        ( startX, startY, startZ ) =
                            Scale.toTriple startScale
                    in
                    builderWithOpacity
                        |> Scale.for elementId
                        |> Scale.toXYZ startX startY startZ
                        |> Scale.build

                _ ->
                    builderWithOpacity

        builderWithRotate =
            case ( endStates.rotate, startStates.rotate ) of
                ( Just _, Just startRotate ) ->
                    let
                        ( startX, startY, startZ ) =
                            Rotate.toTriple startRotate
                    in
                    builderWithScale
                        |> Rotate.for elementId
                        |> Rotate.toXYZ startX startY startZ
                        |> Rotate.build

                _ ->
                    builderWithScale

        builderWithBackgroundColor =
            case ( endStates.backgroundColor, startStates.backgroundColor ) of
                ( Just _, Just startColor ) ->
                    builderWithRotate
                        |> BackgroundColor.for elementId
                        |> BackgroundColor.to startColor
                        |> BackgroundColor.build

                _ ->
                    builderWithRotate

        builderWithSize =
            case ( endStates.size, startStates.size ) of
                ( Just _, Just startSize ) ->
                    let
                        ( startWidth, startHeight ) =
                            Size.toTuple startSize
                    in
                    builderWithBackgroundColor
                        |> Size.for elementId
                        |> Size.toHW startHeight startWidth
                        |> Size.build

                _ ->
                    builderWithBackgroundColor
    in
    builderWithSize
