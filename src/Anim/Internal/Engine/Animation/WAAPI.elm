module Anim.Internal.Engine.Animation.WAAPI exposing
    ( AnimBuilder
    , AnimMsg
    , AnimState
    , EventData
    , allComplete
    , animate
    , anyRunning
    , attributes
    , decodeAnimationEvent
    , delay
    , duration
    , easing
    , encode
    , fireAndForget
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
    , getProgress
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
    , isComplete
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
    )

import Anim.Extra.Easing exposing (Easing(..))
import Anim.Internal.Builder as Builder exposing (AnimationDirection(..))
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Builder.Opacity as Opacity
import Anim.Internal.Builder.Rotate as Rotate
import Anim.Internal.Builder.Scale as Scale
import Anim.Internal.Builder.Size as Size
import Anim.Internal.Builder.Translate as Translate
import Anim.Internal.Engine.Animation.CSS.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Extra.Easing as Easing
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Html
import Html.Attributes
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode



-- Build


type AnimState msg
    = AnimState
        { builder : Builder.AnimBuilder
        , commandPort : Encode.Value -> Cmd msg
        , subscriptionPort : (Decode.Value -> msg) -> Sub msg
        , pendingActions : AnimGroups PendingAction
        , isRunning : Bool
        }
        (AnimGroups AnimGroup)


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
                { builder = Builder.init []
                , commandPort = commandPort
                , subscriptionPort = subscriptionPort
                , pendingActions = AnimGroups.init
                , isRunning = False
                }
                AnimGroups.init

        _ ->
            let
                builder =
                    Builder.init propertyInitializers

                -- Process the builder to extract element configs
                processedData =
                    Builder.process builder

                initGroup : AnimGroupName -> { a | properties : List Builder.ProcessedPropertyConfig } -> AnimGroup
                initGroup _ { properties } =
                    let
                        endStates =
                            (extractElementStates properties).end
                    in
                    { currentStates = endStates
                    , properties = AnimGroups.init -- No property tracking for init
                    , transformOrder = defaultTransformOrder
                    , progress = 0
                    }
            in
            AnimState
                { isRunning = False
                , builder =
                    builder
                        |> Builder.addAnimationToHistory processedData
                        |> Builder.mergeEndStates
                        |> Builder.clearAnimData
                , commandPort = commandPort
                , subscriptionPort = subscriptionPort
                , pendingActions = AnimGroups.init
                }
                (AnimGroups.map initGroup processedData.groups)


type alias AnimBuilder =
    Builder.AnimBuilder


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


{-| Merge two ElementStates, preferring values from the second (newer) state.
-}
mergeElementStates : ElementStates -> ElementStates -> ElementStates
mergeElementStates old new =
    let
        orElse newer older =
            case newer of
                Just _ ->
                    newer

                Nothing ->
                    older
    in
    { translate = orElse new.translate old.translate
    , rotate = orElse new.rotate old.rotate
    , scale = orElse new.scale old.scale
    , backgroundColor = orElse new.backgroundColor old.backgroundColor
    , fontColor = orElse new.fontColor old.fontColor
    , opacity = orElse new.opacity old.opacity
    , size = orElse new.size old.size
    }


getMatchingKeys : String -> AnimGroups AnimGroup -> List String
getMatchingKeys key dict =
    if AnimGroups.member key dict then
        [ key ]

    else
        []


{-| Look up an animation by key (animGroup name). Direct AnimGroups.get.
-}
lookupAnimation : String -> AnimGroups AnimGroup -> Maybe AnimGroup
lookupAnimation key animations =
    AnimGroups.get key animations


type alias PropertyAnimation =
    { version : Int
    , status : AnimationStatus
    }


type alias AnimGroup =
    { currentStates : ElementStates -- Updated by JavaScript during playback
    , properties : AnimGroups PropertyAnimation -- Tracks version and status per property type ("position", "opacity", etc.)
    , transformOrder : List Builder.TransformOrder -- Order to apply transforms (default: Translate → Rotate → Scale)
    , progress : Float -- Current animation progress (0.0 to 1.0)
    }


defaultTransformOrder : List Builder.TransformOrder
defaultTransformOrder =
    [ Builder.Translate, Builder.Rotate, Builder.Scale ]


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


{-| Data returned from animation events.
Used by the public WAAPI module to construct AnimEvent values.
-}
type alias EventData =
    { animGroupName : String
    , status : String
    , progress : Float
    }


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
    Builder.init [ buildAnimation ]
        |> Builder.process
        |> encode
        |> portFunction


animate : AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )
animate (AnimState state animGroups) buildAnimation =
    let
        -- Inject current animated states as baselines, then apply user configuration
        configuredBuilder =
            state.builder
                |> Builder.injectCurrentStates animGroups
                |> buildAnimation

        processedData =
            Builder.process configuredBuilder

        builderWithHistory =
            configuredBuilder
                |> Builder.addAnimationToHistory processedData
                |> Builder.mergeEndStates
                |> Builder.clearAnimData

        -- Create element animations from processed data with property-level versioning
        newElementAnimations =
            processedData.groups
                |> AnimGroups.map
                    (\animGroupName { properties } ->
                        let
                            -- Get existing element animation to preserve states and versions for non-animated properties
                            existingAnimation =
                                AnimGroups.get animGroupName animGroups

                            -- Extract END states from this animation to use as initial currentStates
                            -- This ensures we have states available for baseline injection on the NEXT animation
                            animationEndStates =
                                (extractElementStates properties).end

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
                                    |> Maybe.withDefault AnimGroups.init

                            -- Create new property versions for properties in this animation
                            newPropertyVersions =
                                properties
                                    |> List.map
                                        (\property ->
                                            let
                                                propType =
                                                    propertyTypeString property

                                                newVersion =
                                                    AnimGroups.get propType existingPropertyVersions
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
                                    |> AnimGroups.fromList

                            -- Merge new property versions with existing ones (new ones take precedence)
                            mergedPropertyVersions =
                                AnimGroups.union newPropertyVersions existingPropertyVersions

                            -- Use builder-level order if explicitly set, otherwise preserve existing, or default
                            existingTransformOrder =
                                case processedData.globalTransformOrder of
                                    Just order ->
                                        order

                                    Nothing ->
                                        existingAnimation
                                            |> Maybe.map .transformOrder
                                            |> Maybe.withDefault defaultTransformOrder
                        in
                        { currentStates = currentStates
                        , properties = mergedPropertyVersions
                        , transformOrder = existingTransformOrder
                        , progress = 0
                        }
                    )

        -- Merge with existing animations, preserving non-animated property tracking
        updatedElementAnimations =
            AnimGroups.foldl
                (\animGroupName newAnim acc ->
                    case AnimGroups.get animGroupName acc of
                        Nothing ->
                            -- New element, just insert
                            AnimGroups.insert animGroupName newAnim acc

                        Just existingAnim ->
                            -- Existing element, merge property versions
                            let
                                mergedProperties =
                                    AnimGroups.union newAnim.properties existingAnim.properties
                            in
                            AnimGroups.insert animGroupName
                                { currentStates = newAnim.currentStates
                                , properties = mergedProperties
                                , transformOrder = newAnim.transformOrder
                                , progress = 0
                                }
                                acc
                )
                animGroups
                newElementAnimations
    in
    ( AnimState
        { state
            | builder = builderWithHistory
            , isRunning = not (AnimGroups.isEmpty newElementAnimations)
        }
        updatedElementAnimations
    , state.commandPort <|
        encodeWithVersions updatedElementAnimations processedData.groups
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


extractElementStates : List Builder.ProcessedPropertyConfig -> { start : ElementStates, end : ElementStates }
extractElementStates properties =
    let
        extractProperty : Builder.ProcessedPropertyConfig -> { start : ElementStates, end : ElementStates } -> { start : ElementStates, end : ElementStates }
        extractProperty property { start, end } =
            case property of
                Builder.ProcessedTranslateConfig config ->
                    { start = { start | translate = config.start }, end = { end | translate = Just config.end } }

                Builder.ProcessedRotateConfig config ->
                    { start = { start | rotate = config.start }, end = { end | rotate = Just config.end } }

                Builder.ProcessedScaleConfig config ->
                    { start = { start | scale = config.start }, end = { end | scale = Just config.end } }

                Builder.ProcessedBackgroundColorConfig config ->
                    { start = { start | backgroundColor = config.start }, end = { end | backgroundColor = Just config.end } }

                Builder.ProcessedFontColorConfig config ->
                    { start = { start | fontColor = config.start }, end = { end | fontColor = Just config.end } }

                Builder.ProcessedOpacityConfig config ->
                    { start = { start | opacity = config.start }, end = { end | opacity = Just config.end } }

                Builder.ProcessedSizeConfig config ->
                    { start = { start | size = config.start }, end = { end | size = Just config.end } }
    in
    List.foldl extractProperty { start = emptyElementStates, end = emptyElementStates } properties



-- Update


{-| Decode just the animation event from JavaScript (without state updates).
Returns EventData if this is an animation lifecycle event.
Returns Nothing for property updates or unknown event types.
-}
decodeAnimationEvent : Decode.Value -> Maybe EventData
decodeAnimationEvent jsonValue =
    case Decode.decodeValue (Decode.field "type" Decode.string) jsonValue of
        Ok "animationUpdate" ->
            Decode.decodeValue eventDataDecoder jsonValue
                |> Result.toMaybe

        -- Log the decoded event data
        _ ->
            Nothing


{-| Decoder for EventData from lifecycle events.
-}
eventDataDecoder : Decode.Decoder EventData
eventDataDecoder =
    Decode.map3 EventData
        (Decode.oneOf [ Decode.at [ "payload", "animGroup" ] Decode.string, Decode.at [ "payload", "elementId" ] Decode.string ])
        (Decode.at [ "payload", "status" ] Decode.string)
        (Decode.at [ "payload", "progress" ] Decode.float)


{-| TEA-style update function for WAAPI messages.

Handles both property updates and lifecycle events, returning the updated state
and an EventData for side effects. Property updates return status "progress" with
progress; lifecycle events include full property configurations.

-}
update : AnimMsg -> AnimState msg -> ( AnimState msg, EventData )
update msg animState =
    case msg of
        PropertyUpdate jsonValue ->
            let
                ( newState, propertyResult ) =
                    updatePropertyUpdate jsonValue animState
            in
            ( newState
            , { animGroupName = propertyResult.animGroupName
              , status = "progress"
              , progress = propertyResult.progress
              }
            )

        AnimEvent jsonValue ->
            case decodeAnimationEvent jsonValue of
                Just eventData ->
                    ( handleEventInternal eventData.animGroupName eventData.status animState
                    , eventData
                    )

                Nothing ->
                    ( animState
                    , { animGroupName = ""
                      , status = "unknown"
                      , progress = 0
                      }
                    )


{-| Handle full property updates from JavaScript.
Returns the updated state and property result (animGroupName, progress).
-}
updatePropertyUpdate : Decode.Value -> AnimState msg -> ( AnimState msg, { animGroupName : String, progress : Float } )
updatePropertyUpdate jsonValue (AnimState state animGroups) =
    case Decode.decodeValue animationUpdateDecoder jsonValue of
        Ok animationUpdate ->
            let
                matchingKeys =
                    getMatchingKeys animationUpdate.animGroupName animGroups

                updatedAnimations =
                    List.foldl
                        (\key acc ->
                            AnimGroups.update key
                                (Maybe.map (updateElementAnimation animationUpdate))
                                acc
                        )
                        animGroups
                        matchingKeys

                -- Update global isRunning based on animation status
                hasRunningAnimations =
                    AnimGroups.values updatedAnimations
                        |> List.any
                            (\elementAnim ->
                                AnimGroups.values elementAnim.properties
                                    |> List.any (\prop -> prop.status == Running)
                            )
            in
            ( AnimState { state | isRunning = hasRunningAnimations } updatedAnimations
            , { animGroupName = animationUpdate.animGroupName
              , progress = animationUpdate.progress
              }
            )

        Err _ ->
            -- Silently ignore decode errors
            ( AnimState state animGroups, { animGroupName = "", progress = 0 } )


updateElementAnimation : AnimationUpdate -> AnimGroup -> AnimGroup
updateElementAnimation animUpdate elementAnimation =
    let
        existing =
            elementAnimation.currentStates

        newCurrentStates =
            { translate =
                case animUpdate.translate of
                    Just t ->
                        Just (Translate.fromTriple ( t.x, t.y, t.z ))

                    Nothing ->
                        existing.translate
            , rotate =
                case animUpdate.rotate of
                    Just r ->
                        Just (Rotate.fromTriple ( r.x, r.y, r.z ))

                    Nothing ->
                        existing.rotate
            , scale =
                case animUpdate.scale of
                    Just s ->
                        Just (Scale.fromTriple ( s.x, s.y, s.z ))

                    Nothing ->
                        existing.scale
            , opacity =
                case animUpdate.opacity of
                    Just o ->
                        Just (Opacity.fromFloat o)

                    Nothing ->
                        existing.opacity
            , backgroundColor =
                case animUpdate.backgroundColor of
                    Just bg ->
                        Color.fromString bg

                    Nothing ->
                        existing.backgroundColor
            , fontColor =
                case animUpdate.color of
                    Just c ->
                        Color.fromString c

                    Nothing ->
                        existing.fontColor
            , size =
                case animUpdate.size of
                    Just s ->
                        Just (Size.fromTuple ( s.width, s.height ))

                    Nothing ->
                        existing.size
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
                |> AnimGroups.map
                    (\propType propAnim ->
                        case AnimGroups.get propType animUpdate.propertyVersions of
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
        , progress = animUpdate.progress
    }


{-| Subscribe to WAAPI messages from JavaScript.

This creates a subscription that listens for both property updates and lifecycle events.
Messages are routed based on their JSON type field. Use with `update` to handle messages.

-}
subscriptions : (AnimMsg -> msg) -> AnimState msg -> Sub msg
subscriptions toMsg (AnimState state _) =
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
handleEventInternal animGroupName status (AnimState state animGroups) =
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

                "cancelled" ->
                    Complete

                "stopped" ->
                    Complete

                "reset" ->
                    Complete

                "restarted" ->
                    Running

                _ ->
                    NotStarted

        matchingKeys =
            getMatchingKeys animGroupName animGroups

        -- Clear pending action for all matching keys since we got the event
        clearedPendingActions =
            List.foldl AnimGroups.remove state.pendingActions matchingKeys

        -- Update all matching animations
        updatedElementAnimations =
            List.foldl
                (\key acc ->
                    AnimGroups.update key
                        (Maybe.map
                            (\anim ->
                                { anim
                                    | properties =
                                        AnimGroups.map
                                            (\_ propAnim -> { propAnim | status = newStatus })
                                            anim.properties
                                    , progress =
                                        case newStatus of
                                            Complete ->
                                                1.0

                                            NotStarted ->
                                                0

                                            _ ->
                                                anim.progress
                                }
                            )
                        )
                        acc
                )
                animGroups
                matchingKeys

        isRunning =
            AnimGroups.values updatedElementAnimations
                |> List.any
                    (\anim ->
                        AnimGroups.values anim.properties
                            |> List.any (\prop -> prop.status == Running)
                    )
    in
    AnimState
        { state
            | pendingActions = clearedPendingActions
            , isRunning = isRunning
        }
        updatedElementAnimations


onResize :
    List
        { animGroupName : String
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
            AnimState { commandPort } _ ->
                ( newAnimState, commandPort updateData )


calculateResizePosition :
    AnimState msg
    ->
        { animGroupName : String
        , elementSize : { width : Int, height : Int }
        , oldContainerSize : { width : Int, height : Int }
        , newContainerSize : { width : Int, height : Int }
        }
    -> Maybe { animGroupName : String, startX : Float, startY : Float, startZ : Float, endX : Float, endY : Float, endZ : Float }
calculateResizePosition animState { animGroupName, elementSize, oldContainerSize, newContainerSize } =
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
                { animGroupName = animGroupName
                , startX = scaledStartX
                , startY = scaledStartY
                , startZ = startPos.z
                , endX = scaledEndX
                , endY = scaledEndY
                , endZ = endPos.z
                }
            )
            (getStartTranslate animGroupName animState)
            (getEndTranslate animGroupName animState)


{-| Update positions for multiple elements without creating animation history.
Used for responsive layout adjustments during window/container resize.

ARCHITECTURE: This function is smart - it checks if there's an active position animation
and sends the appropriate command to JavaScript:

  - If position is animating: "handleResize" (updates keyframes, preserves playback state)
  - If not animating: "setPosition" (direct position update, no animation involved)

-}
updatePositions :
    List { animGroupName : String, startX : Float, startY : Float, startZ : Float, endX : Float, endY : Float, endZ : Float }
    -> AnimState msg
    -> ( AnimState msg, Encode.Value )
updatePositions updates (AnimState state animGroups) =
    let
        -- Helper to update all animations for a given element ID
        updateAllForElement :
            String
            -> (AnimGroup -> AnimGroup)
            -> AnimGroups AnimGroup
            -> AnimGroups AnimGroup
        updateAllForElement animGroupName updateFn animations =
            let
                matchingKeys =
                    getMatchingKeys animGroupName animations
            in
            List.foldl
                (\key acc ->
                    AnimGroups.update key (Maybe.map updateFn) acc
                )
                animations
                matchingKeys

        -- Update AnimState with new end positions (all animations for the element)
        updatedAnimations =
            List.foldl
                (\posUpdate acc ->
                    updateAllForElement posUpdate.animGroupName
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
                        acc
                )
                animGroups
                updates

        -- DON'T update Builder during resize - we need to preserve original animation data
        -- so subsequent resizes can scale from the correct start/end positions
        -- Helper to check if an element has an active translate animation (running or paused)
        hasActiveTranslateAnimation : String -> Bool
        hasActiveTranslateAnimation animGroupName =
            lookupAnimation animGroupName animGroups
                |> Maybe.andThen (\elem -> AnimGroups.get "translate" elem.properties)
                |> Maybe.map (\prop -> prop.status == Running || prop.status == Paused)
                |> Maybe.withDefault False

        -- Separate updates into two categories
        ( animatedUpdates, directUpdates ) =
            List.partition (\upd -> hasActiveTranslateAnimation upd.animGroupName) updates

        -- Helper to encode animation update with full keyframe data (start and end positions)
        encodeAnimationUpdate : { animGroupName : String, startX : Float, startY : Float, startZ : Float, endX : Float, endY : Float, endZ : Float } -> Encode.Value
        encodeAnimationUpdate posUpdate =
            let
                -- Get current scale and rotate values from element's state
                ( scaleVals, rotateVals ) =
                    lookupAnimation posUpdate.animGroupName updatedAnimations
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
                [ ( "elementId", Encode.string posUpdate.animGroupName )
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
        encodeDirectUpdate : { animGroupName : String, startX : Float, startY : Float, startZ : Float, endX : Float, endY : Float, endZ : Float } -> Encode.Value
        encodeDirectUpdate posUpdate =
            let
                ( scaleVals, rotateVals ) =
                    lookupAnimation posUpdate.animGroupName updatedAnimations
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
                [ ( "elementId", Encode.string posUpdate.animGroupName )
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
    ( AnimState state updatedAnimations
    , encodedUpdates
    )


type alias AnimGroupName =
    String



-- View


{-| Get the list of HTML attributes to apply to an element for a given animation group.

The `data-anim-target` attribute allows the JavaScript companion to find the
element without requiring an HTML `id`. It is always present, even when no
animation is active, so the element is discoverable as soon as an animation
is triggered.

This also ensures initial values set via `init` are rendered synchronously,
avoiding a flash of unstyled content before JavaScript processes the port command.

-}
attributes : AnimGroupName -> AnimState msg -> List (Html.Attribute msg)
attributes animGroupName (AnimState _ data) =
    let
        dataAttr =
            Html.Attributes.attribute "data-anim-target" animGroupName

        maybeAnimGroup =
            AnimGroups.get animGroupName data
    in
    case maybeAnimGroup of
        Nothing ->
            [ dataAttr ]

        Just animGroup ->
            let
                currentStates =
                    animGroup.currentStates

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
                    animGroup.transformOrder
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
            dataAttr :: transformStyle ++ opacityStyle ++ backgroundColorStyle ++ fontColorStyle ++ sizeStyles


{-| Convert a TransformOrder to its corresponding CSS string part.
-}
transformOrderToPart : String -> String -> String -> Builder.TransformOrder -> String
transformOrderToPart translatePart rotatePart scalePart order =
    case order of
        Builder.Translate ->
            translatePart

        Builder.Rotate ->
            rotatePart

        Builder.Scale ->
            scalePart



-- Query State


allComplete : AnimState msg -> Maybe Bool
allComplete (AnimState _ animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        -- Check if all properties in all elements have Complete status
        AnimGroups.values animGroups
            |> List.all
                (\animGroup ->
                    AnimGroups.values animGroup.properties
                        |> List.all (\prop -> prop.status == Complete)
                )
            |> Just


anyRunning : AnimState msg -> Maybe Bool
anyRunning (AnimState state animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        Just state.isRunning


isComplete : AnimGroupName -> AnimState msg -> Maybe Bool
isComplete animGroupName (AnimState _ data) =
    AnimGroups.get animGroupName data
        |> Maybe.map
            (\elementAnimation ->
                AnimGroups.values elementAnimation.properties
                    |> List.all (\prop -> prop.status == Complete)
            )


getProgress : AnimGroupName -> AnimState msg -> Maybe Float
getProgress animGroupName (AnimState _ data) =
    AnimGroups.get animGroupName data
        |> Maybe.map .progress


isElementRunning : AnimGroupName -> AnimState msg -> Maybe Bool
isElementRunning animGroupName (AnimState _ data) =
    AnimGroups.get animGroupName data
        |> Maybe.map
            (\animGroup ->
                AnimGroups.values animGroup.properties
                    |> List.any (\prop -> prop.status == Running)
            )



-- Query Animated Properties
--
--
-- Helper functions for extracting property ranges


getPropertyRange :
    AnimGroupName
    -> AnimState msg
    -> (Builder.ProcessedPropertyConfig -> Maybe { start : Maybe a, end : a })
    -> Maybe { start : Maybe a, end : a }
getPropertyRange animGroupName (AnimState state _) extractor =
    -- Query the animation HISTORY, not the current builder state
    -- The builder gets cleared after animation starts, but history preserves the data
    state.builder
        |> Builder.getCurrentAnimation animGroupName
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


getStartBackgroundColor : AnimGroupName -> AnimState msg -> Maybe Color
getStartBackgroundColor animGroupName animState =
    getBackgroundColorRange animGroupName animState
        |> getStartWithDefault BackgroundColor.default


getEndBackgroundColor : AnimGroupName -> AnimState msg -> Maybe Color
getEndBackgroundColor animGroupName animState =
    getBackgroundColorRange animGroupName animState
        |> Maybe.map .end


getCurrentBackgroundColor : AnimGroupName -> AnimState msg -> Maybe Color
getCurrentBackgroundColor animGroupName (AnimState _ animGroups) =
    lookupAnimation animGroupName animGroups
        |> Maybe.andThen (.currentStates >> .backgroundColor)


getBackgroundColorRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange animGroupName animState =
    getPropertyRange animGroupName animState <|
        \prop ->
            case prop of
                Builder.ProcessedBackgroundColorConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Opacity


getStartOpacity : AnimGroupName -> AnimState msg -> Maybe Float
getStartOpacity animGroupName animState =
    getOpacityRange animGroupName animState
        |> getStartWithDefault Opacity.default
        |> Maybe.map Opacity.toFloat


getEndOpacity : AnimGroupName -> AnimState msg -> Maybe Float
getEndOpacity animGroupName animState =
    getOpacityRange animGroupName animState
        |> Maybe.map .end
        |> Maybe.map Opacity.toFloat


getCurrentOpacity : AnimGroupName -> AnimState msg -> Maybe Float
getCurrentOpacity animGroupName (AnimState _ animGroups) =
    lookupAnimation animGroupName animGroups
        |> Maybe.andThen (.currentStates >> .opacity)
        |> Maybe.map Opacity.toFloat


getOpacityRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Opacity, end : Opacity }
getOpacityRange animGroupName animState =
    getPropertyRange animGroupName animState <|
        \prop ->
            case prop of
                Builder.ProcessedOpacityConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Translate


getStartTranslate : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getStartTranslate animGroupName animState =
    getTranslateRange animGroupName animState
        |> getStartWithDefault Translate.default
        |> Maybe.map Translate.toRecord


getEndTranslate : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getEndTranslate animGroupName animState =
    getTranslateRange animGroupName animState
        |> Maybe.map .end
        |> Maybe.map Translate.toRecord


getCurrentTranslate : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getCurrentTranslate animGroupName (AnimState _ animGroups) =
    lookupAnimation animGroupName animGroups
        |> Maybe.andThen (.currentStates >> .translate)
        |> Maybe.map Translate.toRecord


getTranslateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Translate, end : Translate }
getTranslateRange animGroupName animState =
    getPropertyRange animGroupName animState <|
        \prop ->
            case prop of
                Builder.ProcessedTranslateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Rotate


getStartRotate : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getStartRotate animGroupName animState =
    getRotateRange animGroupName animState
        |> getStartWithDefault Rotate.default
        |> Maybe.map Rotate.toRecord


getEndRotate : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getEndRotate animGroupName animState =
    getRotateRange animGroupName animState
        |> Maybe.map .end
        |> Maybe.map Rotate.toRecord


getCurrentRotate : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getCurrentRotate animGroupName (AnimState _ animGroups) =
    lookupAnimation animGroupName animGroups
        |> Maybe.andThen (.currentStates >> .rotate)
        |> Maybe.map Rotate.toRecord


getRotateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Rotate, end : Rotate }
getRotateRange animGroupName animState =
    getPropertyRange animGroupName animState <|
        \prop ->
            case prop of
                Builder.ProcessedRotateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Scale


getStartScale : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getStartScale animGroupName animState =
    getScaleRange animGroupName animState
        |> getStartWithDefault Scale.default
        |> Maybe.map Scale.toRecord


getEndScale : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getEndScale animGroupName animState =
    getScaleRange animGroupName animState
        |> Maybe.map .end
        |> Maybe.map Scale.toRecord


getCurrentScale : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getCurrentScale animGroupName (AnimState _ animGroups) =
    lookupAnimation animGroupName animGroups
        |> Maybe.andThen (.currentStates >> .scale)
        |> Maybe.map Scale.toRecord


getScaleRange : String -> AnimState msg -> Maybe { start : Maybe Scale, end : Scale }
getScaleRange animGroupName animState =
    getPropertyRange animGroupName animState <|
        \prop ->
            case prop of
                Builder.ProcessedScaleConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Size


getStartSize : String -> AnimState msg -> Maybe { width : Float, height : Float }
getStartSize animGroupName animState =
    getSizeRange animGroupName animState
        |> getStartWithDefault Size.default
        |> Maybe.map Size.toRecord


getEndSize : String -> AnimState msg -> Maybe { width : Float, height : Float }
getEndSize animGroupName animState =
    getSizeRange animGroupName animState
        |> Maybe.map .end
        |> Maybe.map Size.toRecord


getCurrentSize : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getCurrentSize animGroupName (AnimState _ animGroups) =
    lookupAnimation animGroupName animGroups
        |> Maybe.andThen (.currentStates >> .size)
        |> Maybe.map Size.toRecord


getSizeRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Size, end : Size }
getSizeRange animGroupName animState =
    getPropertyRange animGroupName animState <|
        \prop ->
            case prop of
                Builder.ProcessedSizeConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Decoders


type alias AnimationUpdate =
    { animGroupName : String
    , progress : Float
    , translate : Maybe { x : Float, y : Float, z : Float }
    , opacity : Maybe Float
    , rotate : Maybe { x : Float, y : Float, z : Float }
    , scale : Maybe { x : Float, y : Float, z : Float }
    , backgroundColor : Maybe String
    , color : Maybe String
    , size : Maybe { width : Float, height : Float }
    , isAnimating : Bool
    , propertyVersions : AnimGroups Int -- Maps property type to version number
    }


animationUpdateDecoder : Decoder AnimationUpdate
animationUpdateDecoder =
    Decode.succeed AnimationUpdate
        |> andMap (Decode.oneOf [ Decode.field "animGroup" Decode.string, Decode.field "elementId" Decode.string ])
        |> andMap (Decode.oneOf [ Decode.field "progress" Decode.float, Decode.succeed 0 ])
        |> andMap (Decode.maybe (Decode.field "translate" (Decode.map3 (\x y z -> { x = x, y = y, z = z }) (Decode.field "x" Decode.float) (Decode.field "y" Decode.float) (Decode.field "z" Decode.float))))
        |> andMap (Decode.maybe (Decode.field "opacity" Decode.float))
        |> andMap (Decode.maybe (Decode.field "rotate" (Decode.map3 (\x y z -> { x = x, y = y, z = z }) (Decode.field "x" Decode.float) (Decode.field "y" Decode.float) (Decode.field "z" Decode.float))))
        |> andMap (Decode.maybe (Decode.field "scale" (Decode.map3 (\x y z -> { x = x, y = y, z = z }) (Decode.field "x" Decode.float) (Decode.field "y" Decode.float) (Decode.field "z" Decode.float))))
        |> andMap (Decode.maybe (Decode.field "backgroundColor" Decode.string))
        |> andMap (Decode.maybe (Decode.field "color" Decode.string))
        |> andMap (Decode.maybe (Decode.field "size" (Decode.map2 (\w h -> { width = w, height = h }) (Decode.field "width" Decode.float) (Decode.field "height" Decode.float))))
        |> andMap (Decode.field "isAnimating" Decode.bool)
        |> andMap propertyVersionDecoder


propertyVersionDecoder : Decoder (AnimGroups Int)
propertyVersionDecoder =
    Decode.field "propertyVersions" (Decode.dict Decode.int)
        |> Decode.map AnimGroups.fromDict


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)



-- Encoders


encodeWithVersions : AnimGroups AnimGroup -> AnimGroups Builder.ProcessedAnimGroupConfig -> Encode.Value
encodeWithVersions elementAnimations groups =
    let
        elementsWithVersions =
            groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroup, config ) ->
                        let
                            elementAnim =
                                AnimGroups.get animGroup elementAnimations

                            elementProps =
                                elementAnim
                                    |> Maybe.map .properties
                                    |> Maybe.withDefault AnimGroups.init

                            elemTransformOrder =
                                elementAnim
                                    |> Maybe.map .transformOrder
                                    |> Maybe.withDefault defaultTransformOrder
                        in
                        ( animGroup
                        , encodeProcessedElementConfig
                            { versions = Just elementProps
                            , transformOrder = Just elemTransformOrder
                            }
                            animGroup
                            config
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.object elementsWithVersions )
        ]


encodeRestartWithVersions : AnimGroups AnimGroup -> AnimGroups Builder.ProcessedAnimGroupConfig -> Encode.Value
encodeRestartWithVersions elementAnimations groups =
    let
        elementsWithVersions =
            groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroup, config ) ->
                        let
                            elementAnim =
                                AnimGroups.get animGroup elementAnimations

                            elementProps =
                                elementAnim
                                    |> Maybe.map .properties
                                    |> Maybe.withDefault AnimGroups.init

                            elemTransformOrder =
                                elementAnim
                                    |> Maybe.map .transformOrder
                                    |> Maybe.withDefault defaultTransformOrder
                        in
                        ( animGroup
                        , encodeProcessedElementConfig
                            { versions = Just elementProps
                            , transformOrder = Just elemTransformOrder
                            }
                            animGroup
                            config
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.object elementsWithVersions )
        , ( "isRestart", Encode.bool True )
        ]


encode : Builder.ProcessedAnimationData -> Encode.Value
encode data =
    let
        elementsForJs =
            data.groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroup, config ) ->
                        ( animGroup
                        , encodeProcessedElementConfig
                            { versions = Nothing
                            , transformOrder = Nothing
                            }
                            animGroup
                            config
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.object elementsForJs )
        , ( "iterationCount", encodeIterationCount data.iterationCount )
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


{-| Encode iteration count for JavaScript.
Returns a JSON object with type and count fields.
JavaScript will use this to set the animation iterations.
-}
encodeIterationCount : Builder.Iterations -> Encode.Value
encodeIterationCount iterationCount =
    case iterationCount of
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


encodeProcessedElementConfig :
    { versions : Maybe (AnimGroups PropertyAnimation)
    , transformOrder : Maybe (List Builder.TransformOrder)
    }
    -> String
    -> Builder.ProcessedAnimGroupConfig
    -> Encode.Value
encodeProcessedElementConfig options animGroup config =
    let
        baseFields =
            [ ( "properties", Encode.list (encodeProcessedPropertyConfig options.versions) config.properties )
            , ( "animGroup", Encode.string animGroup )
            ]

        optionalFields =
            options.transformOrder
                |> Maybe.map (\order -> [ ( "transformOrder", encodeTransformOrder order ) ])
                |> Maybe.withDefault []
    in
    Encode.object (baseFields ++ optionalFields)


{-| Encode transform order as a JSON array of strings.
-}
encodeTransformOrder : List Builder.TransformOrder -> Encode.Value
encodeTransformOrder order =
    Encode.list
        (\t ->
            case t of
                Builder.Translate ->
                    Encode.string "translate"

                Builder.Rotate ->
                    Encode.string "rotate"

                Builder.Scale ->
                    Encode.string "scale"
        )
        order


encodeProcessedPropertyConfig : Maybe (AnimGroups PropertyAnimation) -> Builder.ProcessedPropertyConfig -> Encode.Value
encodeProcessedPropertyConfig maybeVersions property =
    let
        versionFields =
            case maybeVersions of
                Just propertyVersions ->
                    let
                        propType =
                            propertyTypeString property

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

        Builder.ProcessedBackgroundColorConfig config ->
            let
                startColorField =
                    config.start
                        |> Maybe.map (\start -> [ ( "startColor", Encode.string (Color.toCssString start) ) ])
                        |> Maybe.withDefault []
            in
            Encode.object
                (( "type", Encode.string "backgroundColor" )
                    :: versionFields
                    ++ [ ( "endColor", Encode.string (Color.toCssString config.end) )
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
                (( "type", Encode.string "color" )
                    :: versionFields
                    ++ [ ( "endColor", Encode.string (Color.toCssString config.end) )
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


stop : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
stop animGroupName (AnimState state animGroups) =
    let
        matchingKeys =
            getMatchingKeys animGroupName animGroups

        -- Update pending actions for all matching keys
        updatedPendingActions =
            List.foldl
                (\k acc -> AnimGroups.insert k PendingStop acc)
                state.pendingActions
                matchingKeys

        -- Update elementAnimations with per-key end states
        updatedElementAnimations =
            List.foldl
                (\k acc ->
                    let
                        endStatesForK =
                            Builder.getCurrentAnimation k state.builder
                                |> Maybe.map (.properties >> extractElementStates >> .end)
                                |> Maybe.withDefault emptyElementStates
                    in
                    AnimGroups.update k
                        (Maybe.map
                            (\anim ->
                                { anim | currentStates = mergeElementStates anim.currentStates endStatesForK }
                            )
                        )
                        acc
                )
                animGroups
                matchingKeys
    in
    ( AnimState { state | pendingActions = updatedPendingActions } updatedElementAnimations
    , state.commandPort <|
        encodeCommandWithProperties "stop" animGroupName Nothing
    )


pause : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
pause animGroupName (AnimState state animGroups) =
    let
        matchingKeys =
            getMatchingKeys animGroupName animGroups

        -- Update pending actions for all matching keys
        updatedPendingActions =
            List.foldl
                (\k acc -> AnimGroups.insert k PendingPause acc)
                state.pendingActions
                matchingKeys
    in
    ( AnimState { state | pendingActions = updatedPendingActions } animGroups
    , state.commandPort <|
        encodeCommandWithProperties "pause" animGroupName Nothing
    )


{-| Reset an element to its initial animation state by resetting internal state and creating a 0ms animation to start positions.
-}
reset : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
reset animGroupName ((AnimState _ animGroups) as animState) =
    let
        matchingKeys =
            getMatchingKeys animGroupName animGroups
                |> (\names ->
                        if List.isEmpty names then
                            [ animGroupName ]

                        else
                            names
                   )
    in
    List.foldl
        (\resolvedKey ( acc, accCmds ) ->
            let
                ( newAnimState, cmd ) =
                    resetSingleKey resolvedKey acc
            in
            ( newAnimState, cmd :: accCmds )
        )
        ( animState, [] )
        matchingKeys
        |> Tuple.mapSecond Cmd.batch


resetSingleKey : String -> AnimState msg -> ( AnimState msg, Cmd msg )
resetSingleKey resolvedKey (AnimState state animGroups) =
    case Builder.getCurrentAnimation resolvedKey state.builder of
        Nothing ->
            ( AnimState state animGroups, Cmd.none )

        Just { properties } ->
            let
                -- Extract start and end states from the animation history
                states =
                    extractElementStates properties

                startStates =
                    states.start

                endStates =
                    states.end

                -- Get properties that were in the original animation
                animatedPropertyTypes =
                    properties
                        |> List.map propertyTypeString

                resetBuilder =
                    Builder.init []
                        |> Builder.duration 0
                        |> Builder.easing Linear
                        |> Builder.for resolvedKey
                        |> addResetProperties resolvedKey endStates startStates

                processedData =
                    Builder.process resetBuilder
            in
            case AnimGroups.get resolvedKey animGroups of
                Nothing ->
                    -- No tracking entry, create one with property versions
                    let
                        newProperties =
                            animatedPropertyTypes
                                |> List.map (\propType -> ( propType, { version = 1, status = NotStarted } ))
                                |> AnimGroups.fromList

                        newElementAnimation =
                            { currentStates = startStates
                            , properties = newProperties
                            , transformOrder = defaultTransformOrder
                            , progress = 0
                            }

                        updatedElementAnimations =
                            AnimGroups.insert resolvedKey newElementAnimation animGroups

                        updatedAnimState =
                            AnimState
                                { state
                                    | pendingActions = AnimGroups.insert resolvedKey (PendingReset startStates) state.pendingActions
                                    , isRunning = False
                                }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeWithVersions updatedElementAnimations processedData.groups
                    )

                Just elementAnimation ->
                    -- Existing tracking entry, increment versions for reset properties
                    let
                        updatedProperties =
                            elementAnimation.properties
                                |> AnimGroups.map
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
                                , progress = 0
                            }

                        updatedElementAnimations =
                            AnimGroups.insert resolvedKey resetElementAnimation animGroups

                        updatedAnimState =
                            AnimState
                                { state
                                    | pendingActions = AnimGroups.insert resolvedKey (PendingReset startStates) state.pendingActions
                                    , isRunning =
                                        AnimGroups.values updatedElementAnimations
                                            |> List.any
                                                (\anim ->
                                                    AnimGroups.values anim.properties
                                                        |> List.any (\prop -> prop.status == Running)
                                                )
                                }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeWithVersions updatedElementAnimations processedData.groups
                    )


{-| Restart the last animation by retrieving it from Builder history and replaying it.
-}
restart : String -> AnimState msg -> ( AnimState msg, Cmd msg )
restart animGroup ((AnimState _ animGroups) as animState) =
    let
        matchingKeys =
            getMatchingKeys animGroup animGroups
                |> (\keys ->
                        if List.isEmpty keys then
                            [ animGroup ]

                        else
                            keys
                   )
    in
    List.foldl
        (\resolvedKey ( acc, accCmds ) ->
            let
                ( newAnimState, cmd ) =
                    restartSingleKey resolvedKey acc
            in
            ( newAnimState, cmd :: accCmds )
        )
        ( animState, [] )
        matchingKeys
        |> Tuple.mapSecond Cmd.batch


restartSingleKey : String -> AnimState msg -> ( AnimState msg, Cmd msg )
restartSingleKey resolvedKey (AnimState state animGroups) =
    case Builder.getCurrentAnimation resolvedKey state.builder of
        Nothing ->
            ( AnimState state animGroups, Cmd.none )

        Just processedData ->
            -- Get properties that are being restarted
            let
                restartedPropertyTypes =
                    processedData.properties
                        |> List.map propertyTypeString

                startStates =
                    (extractElementStates processedData.properties).start
            in
            case AnimGroups.get resolvedKey animGroups of
                Nothing ->
                    -- No tracking entry exists, create one with property versions
                    let
                        newProperties =
                            restartedPropertyTypes
                                |> List.map (\propType -> ( propType, { version = 1, status = NotStarted } ))
                                |> AnimGroups.fromList

                        newElementAnimation =
                            { currentStates = startStates
                            , properties = newProperties
                            , transformOrder = defaultTransformOrder
                            , progress = 0
                            }

                        updatedElementAnimations =
                            AnimGroups.insert resolvedKey newElementAnimation animGroups

                        updatedAnimState =
                            AnimState
                                { state
                                    | pendingActions = AnimGroups.insert resolvedKey PendingRestart state.pendingActions
                                    , isRunning = True
                                }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeRestartWithVersions updatedElementAnimations (AnimGroups.singleton resolvedKey processedData)
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
                                                AnimGroups.get propType elementAnimation.properties
                                                    |> Maybe.map .version
                                                    |> Maybe.map ((+) 1)
                                                    |> Maybe.withDefault 1
                                        in
                                        AnimGroups.insert propType
                                            { version = newVersion, status = NotStarted }
                                            acc
                                    )
                                    elementAnimation.properties

                        resetElementAnimation =
                            { elementAnimation
                                | currentStates = startStates
                                , properties = updatedProperties
                                , progress = 0
                            }

                        updatedElementAnimations =
                            AnimGroups.insert resolvedKey resetElementAnimation animGroups

                        updatedAnimState =
                            AnimState
                                { state
                                    | pendingActions = AnimGroups.insert resolvedKey PendingRestart state.pendingActions
                                    , isRunning = True
                                }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeRestartWithVersions updatedElementAnimations (AnimGroups.singleton resolvedKey processedData)
                    )


resume : String -> AnimState msg -> ( AnimState msg, Cmd msg )
resume animGroup (AnimState state animGroups) =
    let
        matchingKeys =
            getMatchingKeys animGroup animGroups

        -- Update pending actions for all matching keys
        updatedPendingActions =
            List.foldl
                (\k acc -> AnimGroups.insert k PendingResume acc)
                state.pendingActions
                matchingKeys
    in
    ( AnimState
        { state
            | pendingActions = updatedPendingActions
        }
        animGroups
    , state.commandPort <|
        encodeCommandWithProperties "resume" animGroup Nothing
    )


{-| Helper to add reset properties to a builder for all animated properties.
-}
addResetProperties : String -> ElementStates -> ElementStates -> AnimBuilder -> AnimBuilder
addResetProperties animGroupName endStates startStates builderState =
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
                        |> Translate.for animGroupName
                        |> Translate.toXYZ startX startY startZ
                        -- Only set target, let system inject current translate as start
                        |> Translate.build

                _ ->
                    builderState

        builderWithOpacity =
            case ( endStates.opacity, startStates.opacity ) of
                ( Just _, Just startOpacity ) ->
                    builderWithTranslate
                        |> Opacity.for animGroupName
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
                        |> Scale.for animGroupName
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
                        |> Rotate.for animGroupName
                        |> Rotate.toXYZ startX startY startZ
                        |> Rotate.build

                _ ->
                    builderWithScale

        builderWithBackgroundColor =
            case ( endStates.backgroundColor, startStates.backgroundColor ) of
                ( Just _, Just startColor ) ->
                    builderWithRotate
                        |> BackgroundColor.for animGroupName
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
                        |> Size.for animGroupName
                        |> Size.toHW startHeight startWidth
                        |> Size.build

                _ ->
                    builderWithBackgroundColor
    in
    builderWithSize
