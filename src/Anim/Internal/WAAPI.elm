module Anim.Internal.WAAPI exposing
    ( AnimBuilder
    , AnimMsg
    , AnimState
    , TransformOrder(..)
    , allComplete
    , animate
    , animateWithOrder
    , anyRunning
    , attributes
    , builder
    , decodeAnimationEvent
    , decodeEvent
    , defaultTransformOrder
    , delay
    , duration
    , easing
    , encode
    , encodeCommand
    , fireAndForget
    , fireAndForgetWithOrder
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
    , isElementComplete
    , isElementRunning
    , onResize
    , pause
    , reset
    , restart
    , resume
    , speed
    , stop
    , subscriptions
    , update
    , updatePositions
    , updateStatus
    )

import Anim.Extra.Easing exposing (Easing(..))
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
    , transformOrder : List TransformOrder -- Order to apply transforms (default: Translate → Rotate → Scale)
    }


{-| Specifies the order in which transform operations are applied.
The order significantly affects the final visual result - rotating then translating
produces different results than translating then rotating.
-}
type TransformOrder
    = Translate
    | Rotate
    | Scale


{-| Default transform order: Translate → Rotate → Scale.
-}
defaultTransformOrder : List TransformOrder
defaultTransformOrder =
    [ Translate, Rotate, Scale ]


{-| Normalize a transform order list:

1.  Remove duplicates, keeping the first occurrence
2.  Append any missing transforms in the default order (Translate → Rotate → Scale)

-}
normalizeTransformOrder : List TransformOrder -> List TransformOrder
normalizeTransformOrder order =
    let
        removeDuplicates : List TransformOrder -> List TransformOrder -> List TransformOrder
        removeDuplicates seen remaining =
            case remaining of
                [] ->
                    List.reverse seen

                x :: xs ->
                    if List.member x seen then
                        removeDuplicates seen xs

                    else
                        removeDuplicates (x :: seen) xs

        deduped =
            removeDuplicates [] order

        missing =
            List.filter (\t -> not (List.member t deduped)) defaultTransformOrder
    in
    deduped ++ missing


{-| Pending actions for optimistic state management.
When control functions are called, Elm immediately updates its internal state,
then sends a command to JS. These pending actions allow reconciliation when
JS events return.
-}
type PendingAction
    = PendingStop
    | PendingReset ElementStates
    | PendingRestart
    | PendingPause
    | PendingResume


{-| Opaque message type for WAAPI subscriptions.
Handles both property updates and lifecycle events internally.
-}
type AnimMsg
    = PropertyUpdate Decode.Value
    | AnimEvent Decode.Value


type AnimState msg
    = AnimState
        { elementAnimations : Dict ElementId ElementAnimation
        , isRunning : Bool
        , builder : AnimBuilder
        , commandPort : Encode.Value -> Cmd msg
        , subscriptionPort : (Decode.Value -> msg) -> Sub msg
        , pendingActions : Dict ElementId PendingAction
        }


builder : AnimState msg -> AnimBuilder
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



-- Execute Animation


fireAndForget : (Encode.Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg
fireAndForget portFunction buildAnimation =
    let
        processedData =
            Builder.processAnimationData (buildAnimation Builder.init)

        encodedData =
            encode processedData
    in
    portFunction encodedData


fireAndForgetWithOrder : List TransformOrder -> (Encode.Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg
fireAndForgetWithOrder order portFunction buildAnimation =
    let
        normalizedOrder =
            normalizeTransformOrder order

        processedData =
            Builder.processAnimationData (buildAnimation Builder.init)

        encodedData =
            encodeWithOrder normalizedOrder processedData
    in
    portFunction encodedData


animate : AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )
animate (AnimState state) buildAnimation =
    let
        -- Inject current animated states as baselines, then apply user configuration
        configuredBuilder =
            state.builder
                |> Builder.injectCurrentStates state.elementAnimations
                |> buildAnimation

        processedData =
            Builder.processAnimationData configuredBuilder

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

                            -- Preserve existing transform order, or use default if new element
                            existingTransformOrder =
                                existingAnimation
                                    |> Maybe.map .transformOrder
                                    |> Maybe.withDefault defaultTransformOrder
                        in
                        { currentStates = currentStates
                        , properties = mergedPropertyVersions
                        , transformOrder = existingTransformOrder
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
                                , transformOrder = newAnim.transformOrder
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
                configuredBuilder
                processedData.elements
    in
    ( AnimState
        { state
            | elementAnimations = updatedElementAnimations
            , isRunning = not (Dict.isEmpty newElementAnimations)
            , builder =
                builderWithHistory
                    |> Builder.markDirty
                    |> Builder.clearCurrentElement
        }
    , state.commandPort <|
        encodeWithVersions updatedElementAnimations processedData
    )


{-| Animate with a custom transform order.

The transform order specifies how translate, rotate, and scale are combined.
This is applied to all elements in this animation. Start the list with the
transform to apply first.

    animateWithOrder [ Rotate, Translate, Scale ] model.animState myAnimation

Any missing transforms are automatically appended in the default order.

-}
animateWithOrder : List TransformOrder -> AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )
animateWithOrder order (AnimState state) buildAnimation =
    let
        normalizedOrder =
            normalizeTransformOrder order

        -- Run the standard animate logic first
        ( AnimState newState, _ ) =
            animate (AnimState state) buildAnimation

        -- Update the transform order for all elements that were animated
        -- (We need to re-process to get the list of element IDs)
        configuredBuilder =
            state.builder
                |> Builder.injectCurrentStates state.elementAnimations
                |> buildAnimation

        processedData =
            Builder.processAnimationData configuredBuilder

        -- Apply custom transform order to all animated elements
        updatedWithOrder =
            Dict.foldl
                (\elementId _ acc ->
                    Dict.update elementId
                        (Maybe.map (\elem -> { elem | transformOrder = normalizedOrder }))
                        acc
                )
                newState.elementAnimations
                processedData.elements

        -- Rebuild the encoding with updated transform orders
        finalState =
            { newState | elementAnimations = updatedWithOrder }
    in
    ( AnimState finalState
    , state.commandPort <|
        encodeWithVersionsAndOrder updatedWithOrder processedData
    )


{-| Initialize animation state.

Pass an empty list for empty state, or property initializers to set up initial
element state. Always returns `Cmd.none` - use `attributes` in your view to apply
initial CSS values.

-}
init : (Encode.Value -> Cmd msg) -> ((Decode.Value -> msg) -> Sub msg) -> List (AnimBuilder -> AnimBuilder) -> AnimState msg
init commandPort subscriptionPort propertyInitializers =
    -- ARCHITECTURE: No Cmd for JS - the `attributes` function applies initial CSS
    -- values in the view. JS only needs to know about animations.
    -- If there are no property initializers, we can skip all the Builder processing
    -- and just return empty state.
    case propertyInitializers of
        [] ->
            AnimState
                { elementAnimations = Dict.empty
                , isRunning = False
                , builder = Builder.init
                , commandPort = commandPort
                , subscriptionPort = subscriptionPort
                , pendingActions = Dict.empty
                }

        _ ->
            let
                -- Start with inititial AnimState
                (AnimState state) =
                    AnimState
                        { elementAnimations = Dict.empty
                        , isRunning = False
                        , builder = Builder.init
                        , commandPort = commandPort
                        , subscriptionPort = subscriptionPort
                        , pendingActions = Dict.empty
                        }

                -- Apply all property initializers to the builder
                configuredBuilder =
                    List.foldl (\initializer b -> initializer b)
                        state.builder
                        propertyInitializers

                -- Process the builder to extract element configs
                processedData =
                    Builder.processAnimationData configuredBuilder

                -- Extract end states
                -- which are the same as the start states for init
                -- since there's no animation
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
                                , transformOrder = defaultTransformOrder
                                }
                            )
            in
            AnimState
                { elementAnimations = elementAnimations
                , isRunning = False
                , builder =
                    state.builder
                        |> Builder.markDirty
                        |> Builder.clearCurrentElement
                , commandPort = commandPort
                , subscriptionPort = subscriptionPort
                , pendingActions = Dict.empty
                }


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
updateStatus : Decode.Value -> AnimState msg -> AnimState msg
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
                    , pendingActions = Dict.remove elementId state.pendingActions
                }

        Err _ ->
            -- Fallback to old propertyUpdate decoder for backward compatibility
            updatePropertyUpdate jsonValue (AnimState state)


{-| Decode a WAAPI event from JavaScript and update AnimState.
Returns the updated state and optionally the animation event status string
(e.g., "started", "completed", "paused") for lifecycle events, along with the elementId.

Property updates return Nothing for the status since they're just state updates.

-}
decodeEvent : Decode.Value -> AnimState msg -> ( AnimState msg, Maybe ( String, String ) )
decodeEvent jsonValue animState =
    case Decode.decodeValue (Decode.field "type" Decode.string) jsonValue of
        Ok "propertyUpdate" ->
            -- Property updates: apply to state, no event
            ( updatePropertyUpdate jsonValue animState, Nothing )

        Ok "animationUpdate" ->
            -- Animation lifecycle: apply to state, return status string and elementId
            let
                updatedState =
                    updateStatus jsonValue animState

                maybeStatusAndId =
                    Decode.decodeValue
                        (Decode.map2 Tuple.pair
                            (Decode.at [ "payload", "elementId" ] Decode.string)
                            (Decode.at [ "payload", "status" ] Decode.string)
                        )
                        jsonValue
                        |> Result.toMaybe
            in
            ( updatedState, maybeStatusAndId )

        _ ->
            -- Unknown event type, return unchanged
            ( animState, Nothing )


{-| Decode just the animation event from JavaScript (without state updates).
Returns the elementId and status string if this is an animation lifecycle event.
Returns Nothing for property updates or unknown event types.
-}
decodeAnimationEvent : Decode.Value -> Maybe ( String, String )
decodeAnimationEvent jsonValue =
    case Decode.decodeValue (Decode.field "type" Decode.string) jsonValue of
        Ok "animationUpdate" ->
            Decode.decodeValue
                (Decode.map2 Tuple.pair
                    (Decode.at [ "payload", "elementId" ] Decode.string)
                    (Decode.at [ "payload", "status" ] Decode.string)
                )
                jsonValue
                |> Result.toMaybe

        _ ->
            Nothing


{-| TEA-style update function for WAAPI messages.

Handles both property updates and lifecycle events, returning the updated state
and an optional animation event (elementId, status) for side effects.

-}
update : AnimMsg -> AnimState msg -> ( AnimState msg, Maybe ( String, String ) )
update msg animState =
    case msg of
        PropertyUpdate jsonValue ->
            ( updatePropertyUpdate jsonValue animState, Nothing )

        AnimEvent jsonValue ->
            case decodeAnimationEvent jsonValue of
                Just ( elementId, status ) ->
                    ( handleEventInternal elementId status animState
                    , Just ( elementId, status )
                    )

                Nothing ->
                    ( animState, Nothing )


{-| Handle full property updates from JavaScript.
-}
updatePropertyUpdate : Decode.Value -> AnimState msg -> AnimState msg
updatePropertyUpdate jsonValue (AnimState state) =
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


{-| Subscribe to WAAPI messages from JavaScript.

This creates a subscription that listens for both property updates and lifecycle events.
Messages are routed based on their JSON type field. Use with `update` to handle messages.

-}
subscriptions : (AnimMsg -> msg) -> AnimState msg -> Sub msg
subscriptions toMsg (AnimState state) =
    state.subscriptionPort
        (\jsonValue ->
            -- Route based on JSON type field
            case Decode.decodeValue (Decode.field "type" Decode.string) jsonValue of
                Ok "animationUpdate" ->
                    toMsg (AnimEvent jsonValue)

                _ ->
                    -- propertyUpdate or unknown types go to PropertyUpdate
                    toMsg (PropertyUpdate jsonValue)
        )


{-| Internal: Update optimistic state based on an animation lifecycle event.
-}
handleEventInternal : String -> String -> AnimState msg -> AnimState msg
handleEventInternal elementId status (AnimState state) =
    let
        newStatus =
            case status of
                "started" ->
                    Running

                "paused" ->
                    Paused

                "resumed" ->
                    Running

                "completed" ->
                    Complete

                "Cancelled" ->
                    Complete

                "restarted" ->
                    Running

                _ ->
                    NotStarted

        -- Clear pending action for this element since we got the event
        clearedPendingActions =
            Dict.remove elementId state.pendingActions

        updatedElementAnimations =
            Dict.update elementId
                (Maybe.map
                    (\anim ->
                        { anim
                            | properties =
                                Dict.map
                                    (\_ propAnim -> { propAnim | status = newStatus })
                                    anim.properties
                        }
                    )
                )
                state.elementAnimations

        isRunning =
            Dict.values updatedElementAnimations
                |> List.any
                    (\anim ->
                        Dict.values anim.properties
                            |> List.any (\prop -> prop.status == Running)
                    )
    in
    AnimState
        { state
            | elementAnimations = updatedElementAnimations
            , isRunning = isRunning
            , pendingActions = clearedPendingActions
        }


onResize :
    List
        { elementId : String
        , elementSize : { width : Int, height : Int }
        , oldContainerSize : { width : Int, height : Int }
        , newContainerSize : { width : Int, height : Int }
        }
    -> AnimState msg
    -> ( AnimState msg, Cmd msg )
onResize elements animState =
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
        case animState of
            AnimState state ->
                ( newAnimState, state.commandPort updateData )


calculateResizePosition :
    AnimState msg
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
    -> AnimState msg
    -> ( AnimState msg, Encode.Value )
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



-- View


{-| Get HTML attributes that apply the current animation state as inline styles.

This ensures initial values set via `init` are rendered synchronously,
avoiding a flash of unstyled content before JavaScript processes the port command.

-}
attributes : String -> AnimState msg -> List (Html.Attribute msg)
attributes elementId (AnimState state) =
    case Dict.get elementId state.elementAnimations of
        Nothing ->
            []

        Just elementAnimation ->
            let
                currentStates =
                    elementAnimation.currentStates

                -- Build transform parts
                translatePart =
                    currentStates.translate
                        |> Maybe.map Translate.toCssString
                        |> Maybe.withDefault ""

                rotatePart =
                    currentStates.rotate
                        |> Maybe.map Rotate.toCssString
                        |> Maybe.withDefault ""

                scalePart =
                    currentStates.scale
                        |> Maybe.map Scale.toCssString
                        |> Maybe.withDefault ""

                -- Build transform string using stored transform order
                transformString =
                    elementAnimation.transformOrder
                        |> List.map (transformOrderToPart translatePart rotatePart scalePart)
                        |> List.filter (not << String.isEmpty)
                        |> String.join " "

                transformStyle =
                    if String.isEmpty transformString then
                        []

                    else
                        [ Html.Attributes.style "transform" transformString ]

                opacityStyle =
                    currentStates.opacity
                        |> Maybe.map (\o -> Html.Attributes.style "opacity" (Opacity.toString o))
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                backgroundColorStyle =
                    currentStates.backgroundColor
                        |> Maybe.map (\c -> Html.Attributes.style "background-color" (Color.toCssString c))
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                fontColorStyle =
                    currentStates.fontColor
                        |> Maybe.map (\c -> Html.Attributes.style "color" (Color.toCssString c))
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                sizeStyles =
                    currentStates.size
                        |> Maybe.map
                            (\s ->
                                let
                                    size =
                                        Size.toRecord s
                                in
                                [ Html.Attributes.style "width" (String.fromFloat size.width ++ "px")
                                , Html.Attributes.style "height" (String.fromFloat size.height ++ "px")
                                ]
                            )
                        |> Maybe.withDefault []
            in
            transformStyle ++ opacityStyle ++ backgroundColorStyle ++ fontColorStyle ++ sizeStyles


{-| Convert a TransformOrder to its corresponding CSS string part.
-}
transformOrderToPart : String -> String -> String -> TransformOrder -> String
transformOrderToPart translatePart rotatePart scalePart order =
    case order of
        Translate ->
            translatePart

        Rotate ->
            rotatePart

        Scale ->
            scalePart



-- Query State


allComplete : AnimState msg -> Maybe Bool
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


anyRunning : AnimState msg -> Bool
anyRunning (AnimState state) =
    not (Dict.isEmpty state.elementAnimations) && state.isRunning


isElementComplete : String -> AnimState msg -> Maybe Bool
isElementComplete elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.map
            (\elementAnimation ->
                Dict.values elementAnimation.properties
                    |> List.all (\prop -> prop.status == Complete)
            )


isElementRunning : String -> AnimState msg -> Bool
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
    -> AnimState msg
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


getStartBackgroundColor : String -> AnimState msg -> Maybe Color
getStartBackgroundColor elementId animState =
    getBackgroundColorRange elementId animState
        |> getStartWithDefault BackgroundColor.default


getEndBackgroundColor : String -> AnimState msg -> Maybe Color
getEndBackgroundColor elementId animState =
    getBackgroundColorRange elementId animState
        |> Maybe.map .end


getCurrentBackgroundColor : String -> AnimState msg -> Maybe Color
getCurrentBackgroundColor elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .backgroundColor)


getBackgroundColorRange : String -> AnimState msg -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange elementId animState =
    getPropertyRange elementId animState <|
        \prop ->
            case prop of
                Builder.ProcessedBackgroundColorConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Opacity


getStartOpacity : String -> AnimState msg -> Maybe Float
getStartOpacity elementId animState =
    getOpacityRange elementId animState
        |> getStartWithDefault Opacity.default
        |> Maybe.map Opacity.toFloat


getEndOpacity : String -> AnimState msg -> Maybe Float
getEndOpacity elementId animState =
    getOpacityRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Opacity.toFloat


getCurrentOpacity : String -> AnimState msg -> Maybe Float
getCurrentOpacity elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .opacity)
        |> Maybe.map Opacity.toFloat


getOpacityRange : String -> AnimState msg -> Maybe { start : Maybe Opacity, end : Opacity }
getOpacityRange elementId animState =
    getPropertyRange elementId animState <|
        \prop ->
            case prop of
                Builder.ProcessedOpacityConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Translate


getStartTranslate : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getStartTranslate elementId animState =
    getTranslateRange elementId animState
        |> getStartWithDefault Translate.default
        |> Maybe.map Translate.toRecord


getEndTranslate : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getEndTranslate elementId animState =
    getTranslateRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Translate.toRecord


getCurrentTranslate : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getCurrentTranslate elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .translate)
        |> Maybe.map Translate.toRecord


getTranslateRange : String -> AnimState msg -> Maybe { start : Maybe Translate, end : Translate }
getTranslateRange elementId animState =
    getPropertyRange elementId animState <|
        \prop ->
            case prop of
                Builder.ProcessedTranslateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Rotate


getStartRotate : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getStartRotate elementId animState =
    getRotateRange elementId animState
        |> getStartWithDefault Rotate.default
        |> Maybe.map Rotate.toRecord


getEndRotate : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getEndRotate elementId animState =
    getRotateRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Rotate.toRecord


getCurrentRotate : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getCurrentRotate elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .rotate)
        |> Maybe.map Rotate.toRecord


getRotateRange : String -> AnimState msg -> Maybe { start : Maybe Rotate, end : Rotate }
getRotateRange elementId animState =
    getPropertyRange elementId animState <|
        \prop ->
            case prop of
                Builder.ProcessedRotateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Scale


getStartScale : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getStartScale elementId animState =
    getScaleRange elementId animState
        |> getStartWithDefault Scale.default
        |> Maybe.map Scale.toRecord


getEndScale : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getEndScale elementId animState =
    getScaleRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Scale.toRecord


getCurrentScale : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getCurrentScale elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .scale)
        |> Maybe.map Scale.toRecord


getScaleRange : String -> AnimState msg -> Maybe { start : Maybe Scale, end : Scale }
getScaleRange elementId animState =
    getPropertyRange elementId animState <|
        \prop ->
            case prop of
                Builder.ProcessedScaleConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Size


getStartSize : String -> AnimState msg -> Maybe { width : Float, height : Float }
getStartSize elementId animState =
    getSizeRange elementId animState
        |> getStartWithDefault Size.default
        |> Maybe.map Size.toRecord


getEndSize : String -> AnimState msg -> Maybe { width : Float, height : Float }
getEndSize elementId animState =
    getSizeRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Size.toRecord


getCurrentSize : String -> AnimState msg -> Maybe { width : Float, height : Float }
getCurrentSize elementId (AnimState state) =
    Dict.get elementId state.elementAnimations
        |> Maybe.andThen (.currentStates >> .size)
        |> Maybe.map Size.toRecord


getSizeRange : String -> AnimState msg -> Maybe { start : Maybe Size, end : Size }
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
        ]


{-| Encode animation data including transform order for each element.
-}
encodeWithVersionsAndOrder : Dict ElementId ElementAnimation -> Builder.ProcessedAnimationData -> Encode.Value
encodeWithVersionsAndOrder elementAnimations data =
    let
        elementsWithVersions =
            data.elements
                |> Dict.toList
                |> List.map
                    (\( elementId, config ) ->
                        let
                            transformOrder =
                                Dict.get elementId elementAnimations
                                    |> Maybe.map .transformOrder
                                    |> Maybe.withDefault defaultTransformOrder
                        in
                        ( elementId
                        , encodeProcessedElementConfigWithVersionsAndOrder elementAnimations elementId config transformOrder
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.object elementsWithVersions )
        ]


encode : Builder.ProcessedAnimationData -> Encode.Value
encode data =
    Encode.object
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.dict identity encodeProcessedElementConfig data.elements )
        ]


{-| Encode animation data with a custom transform order applied to all elements.
Used by fireAndForgetWithOrder.
-}
encodeWithOrder : List TransformOrder -> Builder.ProcessedAnimationData -> Encode.Value
encodeWithOrder order data =
    let
        elementsWithOrder =
            data.elements
                |> Dict.toList
                |> List.map
                    (\( elementId, config ) ->
                        ( elementId
                        , encodeProcessedElementConfigWithOrder config order
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.object elementsWithOrder )
        ]


{-| Encode a simple command to send to JavaScript (stop, pause, resume).
-}
encodeCommand : String -> String -> Encode.Value
encodeCommand commandType elementId =
    Encode.object
        [ ( "type", Encode.string commandType )
        , ( "elementId", Encode.string elementId )
        ]


encodeProcessedElementConfigWithVersions : Dict ElementId ElementAnimation -> String -> Builder.ProcessedElementConfig -> Encode.Value
encodeProcessedElementConfigWithVersions elementAnimations elementId config =
    let
        elementProps =
            Dict.get elementId elementAnimations
                |> Maybe.map .properties
                |> Maybe.withDefault Dict.empty

        hasExplicitTarget =
            config.targetElement /= Nothing
    in
    Encode.object
        [ ( "properties", Encode.list (encodeProcessedPropertyConfigWithVersion elementProps) config.properties )
        , ( "hasExplicitTarget", Encode.bool hasExplicitTarget )
        ]


{-| Encode element config with versions and custom transform order.
-}
encodeProcessedElementConfigWithVersionsAndOrder : Dict ElementId ElementAnimation -> String -> Builder.ProcessedElementConfig -> List TransformOrder -> Encode.Value
encodeProcessedElementConfigWithVersionsAndOrder elementAnimations elementId config transformOrder =
    let
        elementProps =
            Dict.get elementId elementAnimations
                |> Maybe.map .properties
                |> Maybe.withDefault Dict.empty

        hasExplicitTarget =
            config.targetElement /= Nothing
    in
    Encode.object
        [ ( "properties", Encode.list (encodeProcessedPropertyConfigWithVersion elementProps) config.properties )
        , ( "transformOrder", encodeTransformOrder transformOrder )
        , ( "hasExplicitTarget", Encode.bool hasExplicitTarget )
        ]


{-| Encode transform order as a JSON array of strings.
-}
encodeTransformOrder : List TransformOrder -> Encode.Value
encodeTransformOrder order =
    Encode.list
        (\t ->
            case t of
                Translate ->
                    Encode.string "translate"

                Rotate ->
                    Encode.string "rotate"

                Scale ->
                    Encode.string "scale"
        )
        order


encodeProcessedElementConfig : Builder.ProcessedElementConfig -> Encode.Value
encodeProcessedElementConfig config =
    Encode.object
        [ ( "properties", Encode.list encodeProcessedPropertyConfig config.properties )
        ]


{-| Encode element config with custom transform order.
Used by encodeWithOrder for fire-and-forget animations.
-}
encodeProcessedElementConfigWithOrder : Builder.ProcessedElementConfig -> List TransformOrder -> Encode.Value
encodeProcessedElementConfigWithOrder config transformOrder =
    Encode.object
        [ ( "properties", Encode.list encodeProcessedPropertyConfig config.properties )
        , ( "transformOrder", encodeTransformOrder transformOrder )
        ]


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
                ( startX, startY, startZ ) =
                    config.start
                        |> Maybe.map Translate.toTriple
                        |> Maybe.withDefault ( 0, 0, 0 )

                ( endX, endY, endZ ) =
                    Translate.toTriple config.end
            in
            Encode.object
                ([ ( "type", Encode.string "translate" )
                 , versionField
                 , ( "startX", Encode.float startX )
                 , ( "startY", Encode.float startY )
                 , ( "startZ", Encode.float startZ )
                 , ( "endX", Encode.float endX )
                 , ( "endY", Encode.float endY )
                 , ( "endZ", Encode.float endZ )
                 , ( "duration", Encode.int config.duration )
                 ]
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedScaleConfig config ->
            let
                ( startX, startY, startZ ) =
                    config.start
                        |> Maybe.map Scale.toTriple
                        |> Maybe.withDefault ( 1, 1, 1 )

                ( endX, endY, endZ ) =
                    Scale.toTriple config.end
            in
            Encode.object
                ([ ( "type", Encode.string "scale" )
                 , versionField
                 , ( "startX", Encode.float startX )
                 , ( "startY", Encode.float startY )
                 , ( "startZ", Encode.float startZ )
                 , ( "endX", Encode.float endX )
                 , ( "endY", Encode.float endY )
                 , ( "endZ", Encode.float endZ )
                 , ( "duration", Encode.int config.duration )
                 ]
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedRotateConfig config ->
            let
                ( startX, startY, startZ ) =
                    config.start
                        |> Maybe.map Rotate.toTriple
                        |> Maybe.withDefault ( 0, 0, 0 )

                ( endX, endY, endZ ) =
                    Rotate.toTriple config.end
            in
            Encode.object
                ([ ( "type", Encode.string "rotate" )
                 , versionField
                 , ( "startX", Encode.float startX )
                 , ( "startY", Encode.float startY )
                 , ( "startZ", Encode.float startZ )
                 , ( "endX", Encode.float endX )
                 , ( "endY", Encode.float endY )
                 , ( "endZ", Encode.float endZ )
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
                ([ ( "type", Encode.string "size" )
                 , versionField
                 , ( "startWidth", Encode.float startWidth )
                 , ( "startHeight", Encode.float startHeight )
                 , ( "endWidth", Encode.float endWidth )
                 , ( "endHeight", Encode.float endHeight )
                 , ( "duration", Encode.int config.duration )
                 ]
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
                ([ ( "type", Encode.string "opacity" )
                 , versionField
                 , ( "startValue", Encode.float startValue )
                 , ( "endValue", Encode.float (Opacity.toFloat config.end) )
                 , ( "duration", Encode.int config.duration )
                 ]
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedBackgroundColorConfig config ->
            let
                startColorField =
                    config.start
                        |> Maybe.map (\start -> [ ( "startColor", Encode.string (Color.toCssString start) ) ])
                        |> Maybe.withDefault []
            in
            Encode.object
                ([ ( "type", Encode.string "backgroundColor" )
                 , versionField
                 , ( "endColor", Encode.string (Color.toCssString config.end) )
                 , ( "duration", Encode.int config.duration )
                 ]
                    ++ startColorField
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedFontColorConfig config ->
            let
                startColorField =
                    config.start
                        |> Maybe.map (\start -> [ ( "startColor", Encode.string (Color.toCssString start) ) ])
                        |> Maybe.withDefault []
            in
            Encode.object
                ([ ( "type", Encode.string "color" )
                 , versionField
                 , ( "endColor", Encode.string (Color.toCssString config.end) )
                 , ( "duration", Encode.int config.duration )
                 ]
                    ++ startColorField
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )


encodeProcessedPropertyConfig : Builder.ProcessedPropertyConfig -> Encode.Value
encodeProcessedPropertyConfig property =
    case property of
        Builder.ProcessedTranslateConfig config ->
            let
                ( startX, startY, startZ ) =
                    config.start
                        |> Maybe.map Translate.toTriple
                        |> Maybe.withDefault ( 0, 0, 0 )

                ( endX, endY, endZ ) =
                    Translate.toTriple config.end
            in
            Encode.object
                ([ ( "type", Encode.string "translate" )
                 , ( "startX", Encode.float startX )
                 , ( "startY", Encode.float startY )
                 , ( "startZ", Encode.float startZ )
                 , ( "endX", Encode.float endX )
                 , ( "endY", Encode.float endY )
                 , ( "endZ", Encode.float endZ )
                 , ( "duration", Encode.int config.duration )
                 ]
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedScaleConfig config ->
            let
                ( startX, startY, startZ ) =
                    config.start
                        |> Maybe.map Scale.toTriple
                        |> Maybe.withDefault ( 1, 1, 1 )

                ( endX, endY, endZ ) =
                    Scale.toTriple config.end
            in
            Encode.object
                ([ ( "type", Encode.string "scale" )
                 , ( "startX", Encode.float startX )
                 , ( "startY", Encode.float startY )
                 , ( "startZ", Encode.float startZ )
                 , ( "endX", Encode.float endX )
                 , ( "endY", Encode.float endY )
                 , ( "endZ", Encode.float endZ )
                 , ( "duration", Encode.int config.duration )
                 ]
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedRotateConfig config ->
            let
                ( startX, startY, startZ ) =
                    config.start
                        |> Maybe.map Rotate.toTriple
                        |> Maybe.withDefault ( 0, 0, 0 )

                ( endX, endY, endZ ) =
                    Rotate.toTriple config.end
            in
            Encode.object
                ([ ( "type", Encode.string "rotate" )
                 , ( "startX", Encode.float startX )
                 , ( "startY", Encode.float startY )
                 , ( "startZ", Encode.float startZ )
                 , ( "endX", Encode.float endX )
                 , ( "endY", Encode.float endY )
                 , ( "endZ", Encode.float endZ )
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
                ([ ( "type", Encode.string "size" )
                 , ( "startWidth", Encode.float startWidth )
                 , ( "startHeight", Encode.float startHeight )
                 , ( "endWidth", Encode.float endWidth )
                 , ( "endHeight", Encode.float endHeight )
                 , ( "duration", Encode.int config.duration )
                 ]
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
                ([ ( "type", Encode.string "opacity" )
                 , ( "startValue", Encode.float startValue )
                 , ( "endValue", Encode.float (Opacity.toFloat config.end) )
                 , ( "duration", Encode.int config.duration )
                 ]
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedBackgroundColorConfig config ->
            let
                startColorField =
                    config.start
                        |> Maybe.map (\start -> [ ( "startColor", Encode.string (Color.toCssString start) ) ])
                        |> Maybe.withDefault []
            in
            Encode.object
                ([ ( "type", Encode.string "backgroundColor" )
                 , ( "endColor", Encode.string (Color.toCssString config.end) )
                 , ( "duration", Encode.int config.duration )
                 ]
                    ++ startColorField
                    ++ encodeEasingWithKeyframes config.duration config.easing
                )

        Builder.ProcessedFontColorConfig config ->
            let
                startColorField =
                    config.start
                        |> Maybe.map (\start -> [ ( "startColor", Encode.string (Color.toCssString start) ) ])
                        |> Maybe.withDefault []
            in
            Encode.object
                ([ ( "type", Encode.string "color" )
                 , ( "endColor", Encode.string (Color.toCssString config.end) )
                 , ( "duration", Encode.int config.duration )
                 ]
                    ++ startColorField
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


stop : String -> AnimState msg -> ( AnimState msg, Cmd msg )
stop elementId (AnimState state) =
    ( AnimState
        { state
            | pendingActions = Dict.insert elementId PendingStop state.pendingActions
        }
    , state.commandPort <|
        encodeCommand "stop" elementId
    )


pause : String -> AnimState msg -> ( AnimState msg, Cmd msg )
pause elementId (AnimState state) =
    ( AnimState
        { state
            | pendingActions = Dict.insert elementId PendingPause state.pendingActions
        }
    , state.commandPort <|
        encodeCommand "pause" elementId
    )


{-| Reset an element to its initial animation state by resetting internal state and creating a 0ms animation to start positions.
-}
reset : String -> AnimState msg -> ( AnimState msg, Cmd msg )
reset elementId (AnimState state) =
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

                processedData =
                    Builder.processAnimationData resetBuilder
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
                            , transformOrder = defaultTransformOrder
                            }

                        updatedElementAnimations =
                            Dict.insert elementId newElementAnimation state.elementAnimations

                        updatedAnimState =
                            AnimState
                                { state
                                    | elementAnimations = updatedElementAnimations
                                    , isRunning = False
                                    , pendingActions = Dict.insert elementId (PendingReset startStates) state.pendingActions
                                }
                    in
                    ( updatedAnimState
                    , state.commandPort <|
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
                                    , pendingActions = Dict.insert elementId (PendingReset startStates) state.pendingActions
                                }
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeWithVersions updatedElementAnimations processedData
                    )


{-| Restart the last animation by retrieving it from Builder history and replaying it.
The history will have already been updated by onResize, so we can use it directly.
-}
restart : String -> AnimState msg -> ( AnimState msg, Cmd msg )
restart elementId (AnimState state) =
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
                            , transformOrder = defaultTransformOrder
                            }

                        updatedElementAnimations =
                            Dict.insert elementId newElementAnimation state.elementAnimations

                        updatedAnimState =
                            AnimState
                                { state
                                    | elementAnimations = updatedElementAnimations
                                    , isRunning = True
                                    , pendingActions = Dict.insert elementId PendingRestart state.pendingActions
                                }
                    in
                    ( updatedAnimState
                    , state.commandPort <|
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
                                    , pendingActions = Dict.insert elementId PendingRestart state.pendingActions
                                }
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeWithVersions updatedElementAnimations processedData
                    )


resume : String -> AnimState msg -> ( AnimState msg, Cmd msg )
resume elementId (AnimState state) =
    ( AnimState
        { state
            | pendingActions = Dict.insert elementId PendingResume state.pendingActions
        }
    , state.commandPort <|
        encodeCommand "resume" elementId
    )


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
