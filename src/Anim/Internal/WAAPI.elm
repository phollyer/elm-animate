module Anim.Internal.WAAPI exposing
    ( AnimBuilder
    , AnimState
    , allComplete
    , animate
    , animateStateless
    , anyRunning
    , builder
    , decodeEvent
    , delay
    , duration
    , easing
    , encode
    , encodeCommand
    , getCurrentBackgroundColor
    , getCurrentOpacity
    , getCurrentRotate
    , getCurrentScale
    , getCurrentSize
    , getCurrentTranslate
    , getEndBackgroundColor
    , getEndOpacity
    , getEndRotate
    , getEndScale
    , getEndSize
    , getEndTranslate
    , getOpacityRange
    , getRotateRange
    , getScaleRange
    , getSizeRange
    , getStartBackgroundColor
    , getStartOpacity
    , getStartRotate
    , getStartScale
    , getStartSize
    , getStartTranslate
    , getTranslateRange
    , init
    , initProperties
    , isElementComplete
    , isElementRunning
    , onResize
    , pause
    , perspective
    , perspectiveWith
    , reset
    , restart
    , resume
    , speed
    , stop
    , update
    , updatePositions
    , updateStatus
    )

import Anim.Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder
import Anim.Internal.Builders.BackgroundColor as BackgroundColor
import Anim.Internal.Builders.Opacity as Opacity
import Anim.Internal.Builders.Rotate as Rotate
import Anim.Internal.Builders.Scale as Scale
import Anim.Internal.Builders.Size as Size
import Anim.Internal.Builders.Translate as Translate
import Anim.Internal.Easing as Easing
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Color as Color exposing (Color(..))
import Anim.Internal.Properties.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Properties.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Properties.Scale as Scale exposing (Scale)
import Anim.Internal.Properties.Size as Size exposing (Size)
import Anim.Internal.Properties.Translate as Translate exposing (Translate)
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
    | Paused
    | Complete


type alias ElementStates =
    { translate : Maybe Translate
    , rotate : Maybe Rotate
    , scale : Maybe Scale
    , backgroundColor : Maybe Color
    , fontColor : Maybe Color
    , opacity : Maybe Opacity
    , size : Maybe Size
    }


emptyElementStates : ElementStates
emptyElementStates =
    { translate = Nothing
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
    { currentStates : ElementStates -- Updated by JavaScript during playback
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


animate : (Encode.Value -> Cmd msg) -> AnimState -> (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )
animate portFunction (AnimState state) buildAnimation =
    let
        -- Inject current animated states as baselines, then apply user configuration
        configuredBuilder =
            state.builder
                |> Builder.injectCurrentStates state.elementAnimations
                |> buildAnimation

        builderWithCache =
            Builder.computeAndCachePerspectiveStyles configuredBuilder

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

                            -- Extract END states from this animation to use as initial currentStates
                            -- This ensures we have states available for baseline injection on the NEXT animation
                            animationEndStates =
                                extractElementEndStates elementConfig

                            -- Start with existing current states, then update with this animation's end states
                            currentStates =
                                case existingAnimation of
                                    Just existing ->
                                        -- Merge: Prefer new animation's end states, keep existing for non-animated properties
                                        let
                                            base =
                                                existing.currentStates

                                            orElse new old =
                                                case new of
                                                    Just _ ->
                                                        new

                                                    Nothing ->
                                                        old
                                        in
                                        { translate = orElse animationEndStates.translate base.translate
                                        , rotate = orElse animationEndStates.rotate base.rotate
                                        , scale = orElse animationEndStates.scale base.scale
                                        , backgroundColor = orElse animationEndStates.backgroundColor base.backgroundColor
                                        , fontColor = orElse animationEndStates.fontColor base.fontColor
                                        , opacity = orElse animationEndStates.opacity base.opacity
                                        , size = orElse animationEndStates.size base.size
                                        }

                                    Nothing ->
                                        -- First animation: use end states directly
                                        animationEndStates

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
    , portFunction <|
        encodeWithVersions updatedElementAnimations processedData
    )


{-| Initialize properties without creating animation history.
This sets AnimState and sends position updates to JS without WAAPI animations.
-}
initProperties : (Encode.Value -> Cmd msg) -> List (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )
initProperties portFunction propertyInitializers =
    let
        -- Start with init AnimState
        (AnimState state) =
            init

        -- Apply all property initializers to the builder
        configuredBuilder =
            List.foldl (\initializer b -> initializer b)
                state.builder
                propertyInitializers

        builderWithCache =
            Builder.computeAndCachePerspectiveStyles configuredBuilder

        processedData =
            Builder.processAnimationData builderWithCache

        -- Extract end states (which are same as start states for init)
        elementAnimations =
            processedData.elements
                |> Dict.map
                    (\_ elementConfig ->
                        let
                            endStates =
                                extractElementEndStates elementConfig
                        in
                        { currentStates = endStates
                        , properties = Dict.empty -- No property tracking for init
                        }
                    )

        -- Create property updates for JS (without creating WAAPI animations)
        -- ARCHITECTURE: Initialize ALL properties (transforms, opacity, colors, size)
        -- This ensures inline styles, JS state, and Elm state all start synchronized
        propertyUpdates =
            processedData.elements
                |> Dict.toList
                |> List.map
                    (\( elementId, elementConfig ) ->
                        ( elementId, encodeInitProperties elementConfig.properties )
                    )
    in
    ( AnimState
        { elementAnimations = elementAnimations
        , isRunning = False
        , builder =
            state.builder
                |> Builder.markDirty
                |> Builder.clearCurrentElement
        }
    , portFunction <|
        Encode.object
            [ ( "type", Encode.string "setProperties" )
            , ( "updates"
              , Encode.list
                    (\( elementId, props ) ->
                        Encode.object
                            [ ( "elementId", Encode.string elementId )
                            , ( "properties", props )
                            ]
                    )
                    propertyUpdates
              )
            ]
    )


propertyTypeString : Builder.ProcessedPropertyConfig -> String
propertyTypeString property =
    case property of
        Builder.ProcessedTranslateConfig _ ->
            "translate"

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


extractElementEndStates : Builder.ProcessedElementConfig -> ElementStates
extractElementEndStates elementConfig =
    let
        extractPropertyEndState : Builder.ProcessedPropertyConfig -> ElementStates -> ElementStates
        extractPropertyEndState property state =
            case property of
                Builder.ProcessedTranslateConfig config ->
                    { state | translate = Just config.end }

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
    List.foldl extractPropertyEndState emptyElementStates elementConfig.properties


extractElementStartStates : Builder.ProcessedElementConfig -> ElementStates
extractElementStartStates elementConfig =
    let
        extractPropertyStartState : Builder.ProcessedPropertyConfig -> ElementStates -> ElementStates
        extractPropertyStartState property state =
            case property of
                Builder.ProcessedTranslateConfig config ->
                    { state | translate = config.start }

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
    List.foldl extractPropertyStartState emptyElementStates elementConfig.properties



-- Update


{-| Handle animation status updates from JavaScript (paused, resumed).
-}
updateStatus : Decode.Value -> AnimState -> AnimState
updateStatus jsonValue (AnimState state) =
    case Decode.decodeValue statusUpdateDecoder jsonValue of
        Ok { elementId, status } ->
            let
                newStatus =
                    case status of
                        "paused" ->
                            Just Paused

                        "resumed" ->
                            Just Running

                        _ ->
                            Nothing

                updatedAnimations =
                    case newStatus of
                        Just newStat ->
                            Dict.update elementId
                                (Maybe.map
                                    (\elementAnim ->
                                        let
                                            updatedProps =
                                                Dict.map (\_ prop -> { prop | status = newStat }) elementAnim.properties
                                        in
                                        { elementAnim | properties = updatedProps }
                                    )
                                )
                                state.elementAnimations

                        Nothing ->
                            state.elementAnimations

                hasRunningAnimations =
                    Dict.values updatedAnimations
                        |> List.any
                            (\elementAnim ->
                                Dict.values elementAnim.properties
                                    |> List.any (\prop -> prop.status == Running)
                            )
            in
            AnimState
                { state
                    | elementAnimations = updatedAnimations
                    , isRunning = hasRunningAnimations
                }

        Err _ ->
            -- Fallback to old propertyUpdate decoder for backward compatibility
            update jsonValue (AnimState state)


{-| Decode a WAAPI event from JavaScript and update AnimState.
Returns the updated state and optionally the animation event status string
(e.g., "started", "completed", "paused") for lifecycle events.

Property updates return Nothing for the status since they're just state updates.

-}
decodeEvent : Decode.Value -> AnimState -> ( AnimState, Maybe String )
decodeEvent jsonValue animState =
    case Decode.decodeValue (Decode.field "type" Decode.string) jsonValue of
        Ok "propertyUpdate" ->
            -- Property updates: apply to state, no event
            ( update jsonValue animState, Nothing )

        Ok "animationUpdate" ->
            -- Animation lifecycle: apply to state, return status string
            let
                updatedState =
                    updateStatus jsonValue animState

                maybeStatus =
                    Decode.decodeValue (Decode.at [ "payload", "status" ] Decode.string) jsonValue
                        |> Result.toMaybe
            in
            ( updatedState, maybeStatus )

        _ ->
            -- Unknown event type, return unchanged
            ( animState, Nothing )


{-| Handle full property updates from JavaScript (for backward compatibility).
-}
update : Decode.Value -> AnimState -> AnimState
update jsonValue (AnimState state) =
    case Decode.decodeValue animationUpdateDecoder jsonValue of
        Ok animationUpdate ->
            let
                updatedAnimations =
                    Dict.update animationUpdate.elementId
                        (Maybe.map (updateElementAnimation animationUpdate))
                        state.elementAnimations

                -- Update global isRunning based on animation status
                hasRunningAnimations =
                    Dict.values updatedAnimations
                        |> List.any
                            (\elementAnim ->
                                Dict.values elementAnim.properties
                                    |> List.any (\prop -> prop.status == Running)
                            )
            in
            AnimState
                { state
                    | elementAnimations = updatedAnimations
                    , isRunning = hasRunningAnimations
                }

        Err _ ->
            -- Silently ignore decode errors
            -- TODO: Consider logging, or making it available via a callback
            AnimState state


updateElementAnimation : AnimationUpdate -> ElementAnimation -> ElementAnimation
updateElementAnimation animUpdate elementAnimation =
    let
        newCurrentStates =
            { translate = Just (Translate.fromTriple ( animUpdate.translateX, animUpdate.translateY, animUpdate.translateZ ))
            , rotate = Just (Rotate.fromTriple ( animUpdate.rotateX, animUpdate.rotateY, animUpdate.rotateZ ))
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


onResize :
    List
        { elementId : String
        , elementSize : { width : Int, height : Int }
        , oldContainerSize : { width : Int, height : Int }
        , newContainerSize : { width : Int, height : Int }
        }
    -> (Encode.Value -> Cmd msg)
    -> AnimState
    -> ( AnimState, Cmd msg )
onResize elements portCmd animState =
    let
        updates =
            List.filterMap (calculateResizePosition animState) elements
    in
    if List.isEmpty updates then
        -- No updates needed - avoid sending null command
        ( animState, Cmd.none )

    else
        let
            ( newAnimState, updateData ) =
                updatePositions updates animState
        in
        ( newAnimState, portCmd updateData )


calculateResizePosition :
    AnimState
    ->
        { elementId : String
        , elementSize : { width : Int, height : Int }
        , oldContainerSize : { width : Int, height : Int }
        , newContainerSize : { width : Int, height : Int }
        }
    -> Maybe { elementId : String, startX : Float, startY : Float, startZ : Float, endX : Float, endY : Float, endZ : Float }
calculateResizePosition animState { elementId, elementSize, oldContainerSize, newContainerSize } =
    let
        -- Only reposition if dimensions actually changed
        widthChanged =
            oldContainerSize.width /= newContainerSize.width

        heightChanged =
            oldContainerSize.height /= newContainerSize.height
    in
    if not (widthChanged || heightChanged) then
        Nothing

    else
        -- Get original animation start and end positions from Builder history
        Maybe.map2
            (\startPos endPos ->
                let
                    -- Calculate scaling ratios
                    ratioX =
                        if oldContainerSize.width > 0 then
                            toFloat newContainerSize.width / toFloat oldContainerSize.width

                        else
                            1

                    ratioY =
                        if oldContainerSize.height > 0 then
                            toFloat newContainerSize.height / toFloat oldContainerSize.height

                        else
                            1

                    -- Scale both start and end positions (only for changed dimensions)
                    scaledStartX =
                        if widthChanged then
                            startPos.x * ratioX - (toFloat elementSize.width / 2)

                        else
                            startPos.x

                    scaledStartY =
                        if heightChanged then
                            startPos.y * ratioY

                        else
                            startPos.y

                    scaledEndX =
                        if widthChanged then
                            endPos.x * ratioX - (toFloat elementSize.width / 2)

                        else
                            endPos.x

                    scaledEndY =
                        if heightChanged then
                            endPos.y * ratioY

                        else
                            endPos.y
                in
                { elementId = elementId
                , startX = scaledStartX
                , startY = scaledStartY
                , startZ = startPos.z
                , endX = scaledEndX
                , endY = scaledEndY
                , endZ = endPos.z
                }
            )
            (getStartTranslate elementId animState)
            (getEndTranslate elementId animState)


{-| Update positions for multiple elements without creating animation history.
Used for responsive layout adjustments during window/container resize.

ARCHITECTURE: This function is smart - it checks if there's an active position animation
and sends the appropriate command to JavaScript:

  - If position is animating: "handleResize" (updates keyframes, preserves playback state)
  - If not animating: "setPosition" (direct position update, no animation involved)

-}
updatePositions :
    List { elementId : String, startX : Float, startY : Float, startZ : Float, endX : Float, endY : Float, endZ : Float }
    -> AnimState
    -> ( AnimState, Encode.Value )
updatePositions updates (AnimState state) =
    let
        -- Update AnimState with new end positions
        updatedAnimations =
            List.foldl
                (\posUpdate acc ->
                    Dict.update posUpdate.elementId
                        (Maybe.map
                            (\elementAnim ->
                                let
                                    newTranslate =
                                        Translate.fromTriple ( posUpdate.endX, posUpdate.endY, posUpdate.endZ )

                                    newCurrentStates =
                                        elementAnim.currentStates

                                    updatedCurrentStates =
                                        { newCurrentStates | translate = Just newTranslate }
                                in
                                { elementAnim | currentStates = updatedCurrentStates }
                            )
                        )
                        acc
                )
                state.elementAnimations
                updates

        -- DON'T update Builder during resize - we need to preserve original animation data
        -- so subsequent resizes can scale from the correct start/end positions
        -- Helper to check if an element has an active translate animation (running or paused)
        hasActiveTranslateAnimation : String -> Bool
        hasActiveTranslateAnimation elementId =
            Dict.get elementId state.elementAnimations
                |> Maybe.andThen (\elem -> Dict.get "translate" elem.properties)
                |> Maybe.map (\prop -> prop.status == Running || prop.status == Paused)
                |> Maybe.withDefault False

        -- Separate updates into two categories
        ( animatedUpdates, directUpdates ) =
            List.partition (\upd -> hasActiveTranslateAnimation upd.elementId) updates

        -- Helper to encode animation update with full keyframe data (start and end positions)
        encodeAnimationUpdate : { elementId : String, startX : Float, startY : Float, startZ : Float, endX : Float, endY : Float, endZ : Float } -> Encode.Value
        encodeAnimationUpdate posUpdate =
            let
                -- Get current scale and rotate values from element's state
                ( scaleVals, rotateVals ) =
                    Dict.get posUpdate.elementId updatedAnimations
                        |> Maybe.map
                            (\elementAnim ->
                                let
                                    scale =
                                        elementAnim.currentStates.scale
                                            |> Maybe.map Scale.toRecord
                                            |> Maybe.withDefault { x = 1, y = 1, z = 1 }

                                    rotate =
                                        elementAnim.currentStates.rotate
                                            |> Maybe.map Rotate.toRecord
                                            |> Maybe.withDefault { x = 0, y = 0, z = 0 }
                                in
                                ( scale, rotate )
                            )
                        |> Maybe.withDefault
                            ( { x = 1, y = 1, z = 1 }
                            , { x = 0, y = 0, z = 0 }
                            )
            in
            Encode.object
                [ ( "elementId", Encode.string posUpdate.elementId )
                , ( "startPosition"
                  , Encode.object
                        [ ( "x", Encode.float posUpdate.startX )
                        , ( "y", Encode.float posUpdate.startY )
                        , ( "z", Encode.float posUpdate.startZ )
                        , ( "scaleX", Encode.float scaleVals.x )
                        , ( "scaleY", Encode.float scaleVals.y )
                        , ( "scaleZ", Encode.float scaleVals.z )
                        , ( "rotateX", Encode.float rotateVals.x )
                        , ( "rotateY", Encode.float rotateVals.y )
                        , ( "rotateZ", Encode.float rotateVals.z )
                        ]
                  )
                , ( "endPosition"
                  , Encode.object
                        [ ( "x", Encode.float posUpdate.endX )
                        , ( "y", Encode.float posUpdate.endY )
                        , ( "z", Encode.float posUpdate.endZ )
                        , ( "scaleX", Encode.float scaleVals.x )
                        , ( "scaleY", Encode.float scaleVals.y )
                        , ( "scaleZ", Encode.float scaleVals.z )
                        , ( "rotateX", Encode.float rotateVals.x )
                        , ( "rotateY", Encode.float rotateVals.y )
                        , ( "rotateZ", Encode.float rotateVals.z )
                        ]
                  )
                ]

        -- Helper for direct property updates (no animation)
        encodeDirectUpdate : { elementId : String, startX : Float, startY : Float, startZ : Float, endX : Float, endY : Float, endZ : Float } -> Encode.Value
        encodeDirectUpdate posUpdate =
            let
                ( scaleVals, rotateVals ) =
                    Dict.get posUpdate.elementId updatedAnimations
                        |> Maybe.map
                            (\elementAnim ->
                                let
                                    scale =
                                        elementAnim.currentStates.scale
                                            |> Maybe.map Scale.toRecord
                                            |> Maybe.withDefault { x = 1, y = 1, z = 1 }

                                    rotate =
                                        elementAnim.currentStates.rotate
                                            |> Maybe.map Rotate.toRecord
                                            |> Maybe.withDefault { x = 0, y = 0, z = 0 }
                                in
                                ( scale, rotate )
                            )
                        |> Maybe.withDefault
                            ( { x = 1, y = 1, z = 1 }
                            , { x = 0, y = 0, z = 0 }
                            )
            in
            Encode.object
                [ ( "elementId", Encode.string posUpdate.elementId )
                , ( "properties"
                  , Encode.object
                        [ ( "x", Encode.float posUpdate.endX )
                        , ( "y", Encode.float posUpdate.endY )
                        , ( "z", Encode.float posUpdate.endZ )
                        , ( "scaleX", Encode.float scaleVals.x )
                        , ( "scaleY", Encode.float scaleVals.y )
                        , ( "scaleZ", Encode.float scaleVals.z )
                        , ( "rotateX", Encode.float rotateVals.x )
                        , ( "rotateY", Encode.float rotateVals.y )
                        , ( "rotateZ", Encode.float rotateVals.z )
                        ]
                  )
                ]

        -- Encode commands for JavaScript
        encodedUpdates =
            if List.isEmpty animatedUpdates && List.isEmpty directUpdates then
                Encode.null

            else if List.isEmpty animatedUpdates then
                -- Only direct updates (no active animations)
                Encode.object
                    [ ( "type", Encode.string "setProperties" )
                    , ( "updates", Encode.list encodeDirectUpdate directUpdates )
                    ]

            else if List.isEmpty directUpdates then
                -- Only animated updates (all have active animations)
                Encode.object
                    [ ( "type", Encode.string "handleResize" )
                    , ( "updates", Encode.list encodeAnimationUpdate animatedUpdates )
                    ]

            else
                -- Mixed: some animating, some not - send both commands
                Encode.list identity
                    [ Encode.object
                        [ ( "type", Encode.string "handleResize" )
                        , ( "updates", Encode.list encodeAnimationUpdate animatedUpdates )
                        ]
                    , Encode.object
                        [ ( "type", Encode.string "setProperties" )
                        , ( "updates", Encode.list encodeDirectUpdate directUpdates )
                        ]
                    ]
    in
    ( AnimState { state | elementAnimations = updatedAnimations }
    , encodedUpdates
    )


encodeInitProperties : List Builder.ProcessedPropertyConfig -> Encode.Value
encodeInitProperties properties =
    let
        -- Build an object with all property values
        propertyFields =
            properties
                |> List.concatMap encodeProperty
    in
    Encode.object propertyFields


encodeProperty : Builder.ProcessedPropertyConfig -> List ( String, Encode.Value )
encodeProperty property =
    case property of
        Builder.ProcessedTranslateConfig config ->
            let
                pos =
                    Translate.toRecord config.end
            in
            [ ( "x", Encode.float pos.x )
            , ( "y", Encode.float pos.y )
            , ( "z", Encode.float pos.z )
            ]

        Builder.ProcessedScaleConfig config ->
            let
                scale =
                    Scale.toRecord config.end
            in
            [ ( "scaleX", Encode.float scale.x )
            , ( "scaleY", Encode.float scale.y )
            , ( "scaleZ", Encode.float scale.z )
            ]

        Builder.ProcessedRotateConfig config ->
            let
                rotate =
                    Rotate.toRecord config.end
            in
            [ ( "rotateX", Encode.float rotate.x )
            , ( "rotateY", Encode.float rotate.y )
            , ( "rotateZ", Encode.float rotate.z )
            ]

        Builder.ProcessedOpacityConfig config ->
            [ ( "opacity", Encode.float (Opacity.toFloat config.end) ) ]

        Builder.ProcessedBackgroundColorConfig config ->
            [ ( "backgroundColor", Encode.string (Color.toCssString config.end) ) ]

        Builder.ProcessedFontColorConfig config ->
            [ ( "color", Encode.string (Color.toCssString config.end) ) ]

        Builder.ProcessedSizeConfig config ->
            let
                size =
                    Size.toRecord config.end
            in
            [ ( "width", Encode.float size.width )
            , ( "height", Encode.float size.height )
            ]



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
    -- Query the animation HISTORY, not the current builder state
    -- The builder gets cleared after animation starts, but history preserves the data
    state.builder
        |> Builder.getCurrentAnimation elementId
        |> Maybe.andThen
            (\historyEntry ->
                historyEntry.processedData.elements
                    |> Dict.get elementId
                    |> Maybe.andThen
                        (\{ properties } ->
                            properties
                                |> List.filterMap extractor
                                |> List.head
                        )
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


getStartOpacity : String -> AnimState -> Maybe Float
getStartOpacity elementId animState =
    getOpacityRange elementId animState
        |> getStartWithDefault Opacity.default
        |> Maybe.map Opacity.toFloat


getEndOpacity : String -> AnimState -> Maybe Float
getEndOpacity elementId animState =
    getOpacityRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Opacity.toFloat


getCurrentOpacity : String -> AnimState -> Maybe Float
getCurrentOpacity elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .opacity)
        |> Maybe.map Opacity.toFloat


getOpacityRange : String -> AnimState -> Maybe { start : Maybe Opacity, end : Opacity }
getOpacityRange elementId animState =
    getPropertyRange elementId animState <|
        \prop ->
            case prop of
                Builder.ProcessedOpacityConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Translate


getStartTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartTranslate elementId animState =
    getTranslateRange elementId animState
        |> getStartWithDefault Translate.default
        |> Maybe.map Translate.toRecord


getEndTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndTranslate elementId animState =
    getTranslateRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Translate.toRecord


getCurrentTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentTranslate elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .translate)
        |> Maybe.map Translate.toRecord


getTranslateRange : String -> AnimState -> Maybe { start : Maybe Translate, end : Translate }
getTranslateRange elementId animState =
    getPropertyRange elementId animState <|
        \prop ->
            case prop of
                Builder.ProcessedTranslateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Rotate


getStartRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartRotate elementId animState =
    getRotateRange elementId animState
        |> getStartWithDefault Rotate.default
        |> Maybe.map Rotate.toRecord


getEndRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndRotate elementId animState =
    getRotateRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Rotate.toRecord


getCurrentRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentRotate elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .rotate)
        |> Maybe.map Rotate.toRecord


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


getStartScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartScale elementId animState =
    getScaleRange elementId animState
        |> getStartWithDefault Scale.default
        |> Maybe.map Scale.toRecord


getEndScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndScale elementId animState =
    getScaleRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Scale.toRecord


getCurrentScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentScale elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .scale)
        |> Maybe.map Scale.toRecord


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


getStartSize : String -> AnimState -> Maybe { width : Float, height : Float }
getStartSize elementId animState =
    getSizeRange elementId animState
        |> getStartWithDefault Size.default
        |> Maybe.map Size.toRecord


getEndSize : String -> AnimState -> Maybe { width : Float, height : Float }
getEndSize elementId animState =
    getSizeRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Size.toRecord


getCurrentSize : String -> AnimState -> Maybe { width : Float, height : Float }
getCurrentSize elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .size)
        |> Maybe.map Size.toRecord


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


type alias StatusUpdate =
    { elementId : String
    , status : String
    }


statusUpdateDecoder : Decoder StatusUpdate
statusUpdateDecoder =
    Decode.succeed StatusUpdate
        |> andMap (Decode.field "elementId" Decode.string)
        |> andMap (Decode.at [ "payload", "status" ] Decode.string)


type alias AnimationUpdate =
    { elementId : String
    , translateX : Float
    , translateY : Float
    , translateZ : Float
    , opacity : Float
    , rotateX : Float
    , rotateY : Float
    , rotateZ : Float
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
        |> andMap (Decode.at [ "translate", "x" ] Decode.float)
        |> andMap (Decode.at [ "translate", "y" ] Decode.float)
        |> andMap (Decode.at [ "translate", "z" ] Decode.float)
        |> andMap (Decode.field "opacity" Decode.float)
        |> andMap (Decode.at [ "rotate", "x" ] Decode.float)
        |> andMap (Decode.at [ "rotate", "y" ] Decode.float)
        |> andMap (Decode.at [ "rotate", "z" ] Decode.float)
        |> andMap (Decode.at [ "scale", "x" ] Decode.float)
        |> andMap (Decode.at [ "scale", "y" ] Decode.float)
        |> andMap (Decode.at [ "scale", "z" ] Decode.float)
        |> andMap (Decode.field "backgroundColor" Decode.string)
        |> andMap (Decode.field "color" Decode.string)
        |> andMap (Decode.at [ "size", "width" ] Decode.float)
        |> andMap (Decode.at [ "size", "height" ] Decode.float)
        |> andMap (Decode.field "isAnimating" Decode.bool)
        |> andMap (Decode.maybe (Decode.field "propertyVersions" (Decode.dict Decode.int)) |> Decode.map (Maybe.withDefault Dict.empty))


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
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.object elementsWithVersions )
        , ( "globalPerspective", encodeMaybePerspective data.globalPerspective )
        ]


encode : Builder.ProcessedAnimationData -> Encode.Value
encode data =
    Encode.object
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.dict identity encodeProcessedElementConfig data.elements )
        , ( "globalPerspective", encodeMaybePerspective data.globalPerspective )
        ]


{-| Encode a simple command to send to JavaScript (stop, pause, resume).
-}
encodeCommand : String -> String -> Encode.Value
encodeCommand commandType elementId =
    Encode.object
        [ ( "type", Encode.string commandType )
        , ( "elementId", Encode.string elementId )
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
        Builder.ProcessedTranslateConfig config ->
            let
                ( endX, endY, endZ ) =
                    Translate.toTriple config.end

                ( startXField, startYField, startZField ) =
                    case config.start of
                        Just start ->
                            let
                                ( sx, sy, sz ) =
                                    Translate.toTriple start
                            in
                            ( ( "startX", Encode.float sx )
                            , ( "startY", Encode.float sy )
                            , ( "startZ", Encode.float sz )
                            )

                        Nothing ->
                            ( ( "startX", Encode.null )
                            , ( "startY", Encode.null )
                            , ( "startZ", Encode.null )
                            )

                baseFields =
                    [ ( "type", Encode.string "translate" )
                    , versionField
                    , ( "endX", Encode.float endX )
                    , ( "endY", Encode.float endY )
                    , ( "endZ", Encode.float endZ )
                    , startXField
                    , startYField
                    , startZField
                    , ( "duration", Encode.int config.duration )
                    , ( "perspective", encodeMaybePerspective config.perspective )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedScaleConfig config ->
            let
                ( endX, endY, endZ ) =
                    Scale.toTriple config.end

                ( startXField, startYField, startZField ) =
                    case config.start of
                        Just start ->
                            let
                                ( sx, sy, sz ) =
                                    Scale.toTriple start
                            in
                            ( ( "startX", Encode.float sx )
                            , ( "startY", Encode.float sy )
                            , ( "startZ", Encode.float sz )
                            )

                        Nothing ->
                            ( ( "startX", Encode.null )
                            , ( "startY", Encode.null )
                            , ( "startZ", Encode.null )
                            )

                baseFields =
                    [ ( "type", Encode.string "scale" )
                    , versionField
                    , ( "endX", Encode.float endX )
                    , ( "endY", Encode.float endY )
                    , ( "endZ", Encode.float endZ )
                    , startXField
                    , startYField
                    , startZField
                    , ( "duration", Encode.int config.duration )
                    , ( "perspective", encodeMaybePerspective config.perspective )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedRotateConfig config ->
            let
                ( endX, endY, endZ ) =
                    Rotate.toTriple config.end

                ( startXField, startYField, startZField ) =
                    case config.start of
                        Just start ->
                            let
                                ( sx, sy, sz ) =
                                    Rotate.toTriple start
                            in
                            ( ( "startX", Encode.float sx )
                            , ( "startY", Encode.float sy )
                            , ( "startZ", Encode.float sz )
                            )

                        Nothing ->
                            ( ( "startX", Encode.null )
                            , ( "startY", Encode.null )
                            , ( "startZ", Encode.null )
                            )

                baseFields =
                    [ ( "type", Encode.string "rotate" )
                    , versionField
                    , ( "endX", Encode.float endX )
                    , ( "endY", Encode.float endY )
                    , ( "endZ", Encode.float endZ )
                    , startXField
                    , startYField
                    , startZField
                    , ( "duration", Encode.int config.duration )
                    , ( "perspective", encodeMaybePerspective config.perspective )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedSizeConfig config ->
            let
                ( width, height ) =
                    Size.toTuple config.end

                ( startWidthField, startHeightField ) =
                    case config.start of
                        Just start ->
                            let
                                ( sw, sh ) =
                                    Size.toTuple start
                            in
                            ( ( "startWidth", Encode.float sw )
                            , ( "startHeight", Encode.float sh )
                            )

                        Nothing ->
                            ( ( "startWidth", Encode.null )
                            , ( "startHeight", Encode.null )
                            )

                baseFields =
                    [ ( "type", Encode.string "size" )
                    , versionField
                    , ( "endWidth", Encode.float width )
                    , ( "endHeight", Encode.float height )
                    , startWidthField
                    , startHeightField
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedOpacityConfig config ->
            let
                startValueField =
                    case config.start of
                        Just start ->
                            ( "startValue", Encode.float (Opacity.toFloat start) )

                        Nothing ->
                            ( "startValue", Encode.null )

                baseFields =
                    [ ( "type", Encode.string "opacity" )
                    , versionField
                    , ( "endValue", Encode.float (Opacity.toFloat config.end) )
                    , startValueField
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedBackgroundColorConfig config ->
            let
                startColorField =
                    case config.start of
                        Just start ->
                            ( "startColor", Encode.string (Color.toCssString start) )

                        Nothing ->
                            ( "startColor", Encode.null )

                baseFields =
                    [ ( "type", Encode.string "backgroundColor" )
                    , versionField
                    , ( "endColor", Encode.string (Color.toCssString config.end) )
                    , startColorField
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedFontColorConfig config ->
            let
                startColorField =
                    case config.start of
                        Just start ->
                            ( "startColor", Encode.string (Color.toCssString start) )

                        Nothing ->
                            ( "startColor", Encode.null )

                baseFields =
                    [ ( "type", Encode.string "color" )
                    , versionField
                    , ( "endColor", Encode.string (Color.toCssString config.end) )
                    , startColorField
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)


encodeProcessedPropertyConfig : Builder.ProcessedPropertyConfig -> Encode.Value
encodeProcessedPropertyConfig property =
    case property of
        Builder.ProcessedTranslateConfig config ->
            let
                ( endX, endY, endZ ) =
                    Translate.toTriple config.end

                ( startXField, startYField, startZField ) =
                    case config.start of
                        Just start ->
                            let
                                ( sx, sy, sz ) =
                                    Translate.toTriple start
                            in
                            ( ( "startX", Encode.float sx )
                            , ( "startY", Encode.float sy )
                            , ( "startZ", Encode.float sz )
                            )

                        Nothing ->
                            ( ( "startX", Encode.null )
                            , ( "startY", Encode.null )
                            , ( "startZ", Encode.null )
                            )

                baseFields =
                    [ ( "type", Encode.string "translate" )
                    , ( "endX", Encode.float endX )
                    , ( "endY", Encode.float endY )
                    , ( "endZ", Encode.float endZ )
                    , startXField
                    , startYField
                    , startZField
                    , ( "duration", Encode.int config.duration )
                    , ( "perspective", encodeMaybePerspective config.perspective )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedScaleConfig config ->
            let
                ( endX, endY, endZ ) =
                    Scale.toTriple config.end

                ( startXField, startYField, startZField ) =
                    case config.start of
                        Just start ->
                            let
                                ( sx, sy, sz ) =
                                    Scale.toTriple start
                            in
                            ( ( "startX", Encode.float sx )
                            , ( "startY", Encode.float sy )
                            , ( "startZ", Encode.float sz )
                            )

                        Nothing ->
                            ( ( "startX", Encode.null )
                            , ( "startY", Encode.null )
                            , ( "startZ", Encode.null )
                            )

                baseFields =
                    [ ( "type", Encode.string "scale" )
                    , ( "endX", Encode.float endX )
                    , ( "endY", Encode.float endY )
                    , ( "endZ", Encode.float endZ )
                    , startXField
                    , startYField
                    , startZField
                    , ( "duration", Encode.int config.duration )
                    , ( "perspective", encodeMaybePerspective config.perspective )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedRotateConfig config ->
            let
                ( endX, endY, endZ ) =
                    Rotate.toTriple config.end

                ( startXField, startYField, startZField ) =
                    case config.start of
                        Just start ->
                            let
                                ( sx, sy, sz ) =
                                    Rotate.toTriple start
                            in
                            ( ( "startX", Encode.float sx )
                            , ( "startY", Encode.float sy )
                            , ( "startZ", Encode.float sz )
                            )

                        Nothing ->
                            ( ( "startX", Encode.null )
                            , ( "startY", Encode.null )
                            , ( "startZ", Encode.null )
                            )

                baseFields =
                    [ ( "type", Encode.string "rotate" )
                    , ( "endX", Encode.float endX )
                    , ( "endY", Encode.float endY )
                    , ( "endZ", Encode.float endZ )
                    , startXField
                    , startYField
                    , startZField
                    , ( "duration", Encode.int config.duration )
                    , ( "perspective", encodeMaybePerspective config.perspective )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedSizeConfig config ->
            let
                ( width, height ) =
                    Size.toTuple config.end

                ( startWidthField, startHeightField ) =
                    case config.start of
                        Just start ->
                            let
                                ( sw, sh ) =
                                    Size.toTuple start
                            in
                            ( ( "startWidth", Encode.float sw )
                            , ( "startHeight", Encode.float sh )
                            )

                        Nothing ->
                            ( ( "startWidth", Encode.null )
                            , ( "startHeight", Encode.null )
                            )

                baseFields =
                    [ ( "type", Encode.string "size" )
                    , ( "endWidth", Encode.float width )
                    , ( "endHeight", Encode.float height )
                    , startWidthField
                    , startHeightField
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedOpacityConfig config ->
            let
                startValueField =
                    case config.start of
                        Just start ->
                            ( "startValue", Encode.float (Opacity.toFloat start) )

                        Nothing ->
                            ( "startValue", Encode.null )

                baseFields =
                    [ ( "type", Encode.string "opacity" )
                    , ( "endValue", Encode.float (Opacity.toFloat config.end) )
                    , startValueField
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedBackgroundColorConfig config ->
            let
                startColorField =
                    case config.start of
                        Just start ->
                            ( "startColor", Encode.string (Color.toCssString start) )

                        Nothing ->
                            ( "startColor", Encode.null )

                baseFields =
                    [ ( "type", Encode.string "backgroundColor" )
                    , ( "endColor", Encode.string (Color.toCssString config.end) )
                    , startColorField
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)

        Builder.ProcessedFontColorConfig config ->
            let
                startColorField =
                    case config.start of
                        Just start ->
                            ( "startColor", Encode.string (Color.toCssString start) )

                        Nothing ->
                            ( "startColor", Encode.null )

                baseFields =
                    [ ( "type", Encode.string "color" )
                    , ( "endColor", Encode.string (Color.toCssString config.end) )
                    , startColorField
                    , ( "duration", Encode.int config.duration )
                    ]

                easingFields =
                    encodeEasingWithKeyframes config.duration config.easing
            in
            Encode.object (baseFields ++ easingFields)


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


stop : String -> (Encode.Value -> Cmd msg) -> Cmd msg
stop elementId portFunction =
    portFunction <|
        encodeCommand "stop" elementId


pause : String -> (Encode.Value -> Cmd msg) -> Cmd msg
pause elementId portFunction =
    portFunction <|
        encodeCommand "pause" elementId


{-| Reset an element to its initial animation state by resetting internal state and creating a 0ms animation to start positions.
-}
reset : String -> (Encode.Value -> Cmd msg) -> AnimState -> ( AnimState, Cmd msg )
reset elementId portFunction (AnimState state) =
    case Builder.getCurrentAnimation elementId state.builder of
        Nothing ->
            ( AnimState state, Cmd.none )

        Just historyEntry ->
            let
                -- Extract start and end states from the animation history
                startStates =
                    historyEntry.processedData.elements
                        |> Dict.get elementId
                        |> Maybe.map extractElementStartStates
                        |> Maybe.withDefault emptyElementStates

                endStates =
                    historyEntry.processedData.elements
                        |> Dict.get elementId
                        |> Maybe.map extractElementEndStates
                        |> Maybe.withDefault emptyElementStates

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
                    ( updatedAnimState
                    , portFunction <|
                        encodeWithVersions updatedElementAnimations processedData
                    )

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
                    ( updatedAnimState
                    , portFunction <|
                        encodeWithVersions updatedElementAnimations processedData
                    )


{-| Restart the last animation by retrieving it from Builder history and replaying it.
The history will have already been updated by onResize, so we can use it directly.
-}
restart : String -> (Encode.Value -> Cmd msg) -> AnimState -> ( AnimState, Cmd msg )
restart elementId portFunction (AnimState state) =
    case Builder.restartCurrentAnimation elementId state.builder of
        Nothing ->
            ( AnimState state, Cmd.none )

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
                        |> Maybe.withDefault emptyElementStates
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
                    ( updatedAnimState
                    , portFunction <|
                        encodeWithVersions updatedElementAnimations processedData
                    )

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
                    ( updatedAnimState
                    , portFunction <|
                        encodeWithVersions updatedElementAnimations processedData
                    )


resume : String -> (Encode.Value -> Cmd msg) -> Cmd msg
resume elementId portFunction =
    portFunction <|
        encodeCommand "resume" elementId


{-| Helper to add reset properties to a builder for all animated properties.
-}
addResetProperties : String -> ElementStates -> ElementStates -> AnimBuilder -> AnimBuilder
addResetProperties elementId endStates startStates builderState =
    let
        -- Use the actual stored start states to reset each property that was animated
        builderWithTranslate =
            case ( endStates.translate, startStates.translate ) of
                ( Just _, Just startTranslate ) ->
                    let
                        ( startX, startY, startZ ) =
                            Translate.toTriple startTranslate
                    in
                    builderState
                        |> Translate.for elementId
                        |> Translate.toXYZ startX startY startZ
                        -- Only set target, let system inject current translate as start
                        |> Translate.build

                _ ->
                    builderState

        builderWithOpacity =
            case ( endStates.opacity, startStates.opacity ) of
                ( Just _, Just startOpacity ) ->
                    builderWithTranslate
                        |> Opacity.for elementId
                        |> Opacity.to startOpacity
                        |> Opacity.build

                _ ->
                    builderWithTranslate

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
