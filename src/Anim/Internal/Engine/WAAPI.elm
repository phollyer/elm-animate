module Anim.Internal.Engine.WAAPI exposing
    ( AnimBuilder
    , AnimMsg
    , AnimState
    , EventData
    , allComplete
    , animate
    , anyRunning
    , attributes
    , builder
    , decodeAnimationEvent
    , decodeEvent
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
import Anim.Internal.Builder as Builder exposing (AnimationDirection(..), IterationCount(..))
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Builder.Opacity as Opacity
import Anim.Internal.Builder.Rotate as Rotate
import Anim.Internal.Builder.Scale as Scale
import Anim.Internal.Builder.Size as Size
import Anim.Internal.Builder.Translate as Translate
import Anim.Internal.Easing as Easing
import Anim.Internal.KeyMatch as KeyMatch
import Anim.Internal.Property.Color as Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
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


normalizeKey : String -> String
normalizeKey =
    KeyMatch.normalizeKey


findAnimationsForElement : ElementId -> Dict String ElementAnimation -> List ( String, ElementAnimation )
findAnimationsForElement =
    KeyMatch.findMatchingEntries


{-| Get merged states and transform order for all animations targeting an element.
When multiple animations exist for the same element, their states are merged
with later-defined animations taking precedence for conflicting properties.
-}
getMergedElementAnimation : ElementId -> Dict String ElementAnimation -> Maybe ElementAnimation
getMergedElementAnimation elementId animations =
    let
        matchingAnims =
            findAnimationsForElement elementId animations
    in
    case matchingAnims of
        [] ->
            Nothing

        [ ( _, anim ) ] ->
            Just anim

        first :: rest ->
            -- Merge all animations: later ones override earlier for each property
            Just <|
                List.foldl
                    (\( _, anim ) acc ->
                        { currentStates = mergeElementStates acc.currentStates anim.currentStates
                        , properties = Dict.union anim.properties acc.properties
                        , transformOrder = anim.transformOrder -- Use the latest transform order
                        }
                    )
                    (Tuple.second first)
                    rest


getMatchingCompositeKeys : String -> Dict String ElementAnimation -> List String
getMatchingCompositeKeys =
    KeyMatch.getMatchingKeys


{-| Extract the element ID from a key (either composite or plain element ID).
Used for sending commands to JavaScript which needs the DOM element ID.

If a composite key, extracts the element ID (part before the colon).
If a plain key, checks if it matches any composite keys to find the actual element ID.

-}
getElementIdForJs : String -> String
getElementIdForJs key =
    if Builder.isCompositeKey key then
        Builder.extractElementId key

    else
        key


{-| Resolve the DOM element ID for JavaScript commands by looking up animations.
If the key is a composite key, extracts the element ID directly.
If the key is a plain key (animation group name), looks up matching composite keys.
-}
resolveElementIdForJs : String -> Dict String ElementAnimation -> String
resolveElementIdForJs key animations =
    if Builder.isCompositeKey key then
        Builder.extractElementId key

    else
        -- Key might be an animation group name - look for matching composite keys
        let
            matchingKeys =
                findAnimationsForElement key animations
                    |> List.map Tuple.first
        in
        case matchingKeys of
            [] ->
                -- No matches, return key as-is (backwards compatibility)
                key

            compositeKey :: _ ->
                -- Found a composite key, extract the element ID from it
                if Builder.isCompositeKey compositeKey then
                    Builder.extractElementId compositeKey

                else
                    compositeKey


{-| Get property types for the matching composite keys.
Returns Nothing if the key is a plain element ID (meaning target all properties).
Returns Just with the list of property types if targeting specific groups.
-}
getPropertyTypesForKey : String -> Dict String ElementAnimation -> Maybe (List String)
getPropertyTypesForKey key animations =
    if Builder.isCompositeKey key then
        -- Specific composite key: get its property types
        Dict.get key animations
            |> Maybe.map (.properties >> Dict.keys)

    else
        -- Element ID: no filter (target all properties)
        Nothing


{-| Look up an animation by key. Supports both composite keys and element IDs.
For composite key: returns that specific animation.
For element ID: returns merged animation from all matching composite keys.
-}
lookupAnimation : String -> Dict String ElementAnimation -> Maybe ElementAnimation
lookupAnimation key animations =
    if Builder.isCompositeKey key then
        Dict.get key animations

    else
        getMergedElementAnimation key animations


type alias PropertyAnimation =
    { version : Int
    , status : AnimationStatus
    }


type alias ElementAnimation =
    { currentStates : ElementStates -- Updated by JavaScript during playback
    , properties : Dict String PropertyAnimation -- Tracks version and status per property type ("position", "opacity", etc.)
    , transformOrder : List Builder.TransformOrder -- Order to apply transforms (default: Translate → Rotate → Scale)
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
    { elementId : String
    , animGroup : String
    , status : String
    , progress : Float
    }


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
                                (extractElementStates elementConfig).end

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
                    |> Builder.mergeEndStates
                    |> Builder.clearAnimData
        }
    , state.commandPort <|
        encodeWithVersions updatedElementAnimations processedData
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
                                        (extractElementStates elementConfig).end
                                in
                                { currentStates = endStates
                                , properties = Dict.empty -- No property tracking for init
                                , transformOrder = defaultTransformOrder
                                }
                            )

                -- Save each element's initial state to history for reset/restart
                builderWithHistory =
                    Dict.foldl
                        (\elementId _ accBuilder ->
                            Builder.addAnimationToHistory elementId processedData Nothing accBuilder
                                |> Tuple.first
                        )
                        configuredBuilder
                        processedData.elements
            in
            AnimState
                { elementAnimations = elementAnimations
                , isRunning = False
                , builder =
                    builderWithHistory
                        |> Builder.mergeEndStates
                        |> Builder.clearAnimData
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


extractElementStates : Builder.ProcessedElementConfig -> { start : ElementStates, end : ElementStates }
extractElementStates elementConfig =
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
    List.foldl extractProperty { start = emptyElementStates, end = emptyElementStates } elementConfig.properties



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

                -- Find all matching composite keys for this element ID
                matchingKeys =
                    getMatchingCompositeKeys elementId state.elementAnimations

                -- Update all matching animations
                updatedAnimations =
                    case newStatus of
                        Just newStat ->
                            List.foldl
                                (\key acc ->
                                    Dict.update key
                                        (Maybe.map
                                            (\elementAnim ->
                                                let
                                                    updatedProps =
                                                        Dict.map (\_ prop -> { prop | status = newStat }) elementAnim.properties
                                                in
                                                { elementAnim | properties = updatedProps }
                                            )
                                        )
                                        acc
                                )
                                state.elementAnimations
                                matchingKeys

                        Nothing ->
                            state.elementAnimations

                hasRunningAnimations =
                    Dict.values updatedAnimations
                        |> List.any
                            (\elementAnim ->
                                Dict.values elementAnim.properties
                                    |> List.any (\prop -> prop.status == Running)
                            )

                -- Remove pending actions for all matching keys
                updatedPendingActions =
                    List.foldl Dict.remove state.pendingActions matchingKeys
            in
            AnimState
                { state
                    | elementAnimations = updatedAnimations
                    , isRunning = hasRunningAnimations
                    , pendingActions = updatedPendingActions
                }

        Err _ ->
            -- Fallback to old propertyUpdate decoder for backward compatibility
            Tuple.first (updatePropertyUpdate jsonValue (AnimState state))


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
            ( Tuple.first (updatePropertyUpdate jsonValue animState), Nothing )

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
    Decode.map4 EventData
        (Decode.at [ "payload", "elementId" ] Decode.string)
        (Decode.at [ "payload", "animGroup" ] Decode.string)
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
            , { elementId = propertyResult.elementId
              , animGroup = propertyResult.animGroup
              , status = "progress"
              , progress = propertyResult.progress
              }
            )

        AnimEvent jsonValue ->
            case decodeAnimationEvent jsonValue of
                Just eventData ->
                    ( handleEventInternal eventData.elementId eventData.status animState
                    , eventData
                    )

                Nothing ->
                    ( animState
                    , { elementId = ""
                      , animGroup = ""
                      , status = "unknown"
                      , progress = 0
                      }
                    )


{-| Handle full property updates from JavaScript.
Returns the updated state and property result (elementId, animGroup, progress).
-}
updatePropertyUpdate : Decode.Value -> AnimState msg -> ( AnimState msg, { elementId : String, animGroup : String, progress : Float } )
updatePropertyUpdate jsonValue (AnimState state) =
    case Decode.decodeValue animationUpdateDecoder jsonValue of
        Ok animationUpdate ->
            let
                -- Find all matching composite keys for this element ID
                matchingKeys =
                    getMatchingCompositeKeys animationUpdate.elementId state.elementAnimations

                -- Update all matching animations
                updatedAnimations =
                    List.foldl
                        (\key acc ->
                            Dict.update key
                                (Maybe.map (updateElementAnimation animationUpdate))
                                acc
                        )
                        state.elementAnimations
                        matchingKeys

                -- Update global isRunning based on animation status
                hasRunningAnimations =
                    Dict.values updatedAnimations
                        |> List.any
                            (\elementAnim ->
                                Dict.values elementAnim.properties
                                    |> List.any (\prop -> prop.status == Running)
                            )
            in
            ( AnimState
                { state
                    | elementAnimations = updatedAnimations
                    , isRunning = hasRunningAnimations
                }
            , { elementId = animationUpdate.elementId
              , animGroup = animationUpdate.animGroup
              , progress = animationUpdate.progress
              }
            )

        Err _ ->
            -- Silently ignore decode errors
            ( AnimState state, { elementId = "", animGroup = "", progress = 0 } )


updateElementAnimation : AnimationUpdate -> ElementAnimation -> ElementAnimation
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

        -- Find all matching composite keys for this element ID
        matchingKeys =
            getMatchingCompositeKeys elementId state.elementAnimations

        -- Clear pending action for all matching keys since we got the event
        clearedPendingActions =
            List.foldl Dict.remove state.pendingActions matchingKeys

        -- Update all matching animations
        updatedElementAnimations =
            List.foldl
                (\key acc ->
                    Dict.update key
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
                        acc
                )
                state.elementAnimations
                matchingKeys

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
        -- Helper to update all animations for a given element ID
        updateAllForElement :
            String
            -> (ElementAnimation -> ElementAnimation)
            -> Dict String ElementAnimation
            -> Dict String ElementAnimation
        updateAllForElement elementId updateFn animations =
            let
                matchingKeys =
                    getMatchingCompositeKeys elementId animations
            in
            List.foldl
                (\key acc ->
                    Dict.update key (Maybe.map updateFn) acc
                )
                animations
                matchingKeys

        -- Update AnimState with new end positions (all animations for the element)
        updatedAnimations =
            List.foldl
                (\posUpdate acc ->
                    updateAllForElement posUpdate.elementId
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
                state.elementAnimations
                updates

        -- DON'T update Builder during resize - we need to preserve original animation data
        -- so subsequent resizes can scale from the correct start/end positions
        -- Helper to check if an element has an active translate animation (running or paused)
        hasActiveTranslateAnimation : String -> Bool
        hasActiveTranslateAnimation elementId =
            lookupAnimation elementId state.elementAnimations
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
                    lookupAnimation posUpdate.elementId updatedAnimations
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
                    lookupAnimation posUpdate.elementId updatedAnimations
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


{-| Get HTML attributes that apply the current animation state as inline styles,
plus a `data-anim-target` attribute for JavaScript element targeting.

The `data-anim-target` attribute allows the JavaScript companion to find the
element without requiring an HTML `id`. It is always present, even when no
animation is active, so the element is discoverable as soon as an animation
is triggered.

This also ensures initial values set via `init` are rendered synchronously,
avoiding a flash of unstyled content before JavaScript processes the port command.

The key parameter can be either:

  - A composite key like `"myBox:fadeIn"` - looks up that exact animation
  - Just an element ID like `"myBox"` - merges all animations targeting that element

-}
attributes : String -> AnimState msg -> List (Html.Attribute msg)
attributes rawKey (AnimState state) =
    let
        key =
            normalizeKey rawKey

        targetId =
            getElementIdForJs key

        dataAttr =
            Html.Attributes.attribute "data-anim-target" targetId

        maybeElementAnimation =
            if Builder.isCompositeKey key then
                -- Direct lookup by composite key
                Dict.get key state.elementAnimations

            else
                -- Search for all animations targeting this element ID and merge
                getMergedElementAnimation key state.elementAnimations
    in
    case maybeElementAnimation of
        Nothing ->
            [ dataAttr ]

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


anyRunning : AnimState msg -> Maybe Bool
anyRunning (AnimState state) =
    if Dict.isEmpty state.elementAnimations then
        Nothing

    else
        Just state.isRunning


isElementComplete : String -> AnimState msg -> Maybe Bool
isElementComplete rawKey (AnimState state) =
    let
        key =
            normalizeKey rawKey

        maybeAnimation =
            if Builder.isCompositeKey key then
                Dict.get key state.elementAnimations

            else
                getMergedElementAnimation key state.elementAnimations
    in
    maybeAnimation
        |> Maybe.map
            (\elementAnimation ->
                Dict.values elementAnimation.properties
                    |> List.all (\prop -> prop.status == Complete)
            )


isElementRunning : String -> AnimState msg -> Maybe Bool
isElementRunning rawKey (AnimState state) =
    let
        key =
            normalizeKey rawKey

        maybeAnimation =
            if Builder.isCompositeKey key then
                Dict.get key state.elementAnimations

            else
                getMergedElementAnimation key state.elementAnimations
    in
    maybeAnimation
        |> Maybe.map
            (\elementAnimation ->
                Dict.values elementAnimation.properties
                    |> List.any (\prop -> prop.status == Running)
            )



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
getCurrentBackgroundColor key (AnimState state) =
    lookupAnimation key state.elementAnimations
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
getCurrentOpacity key (AnimState state) =
    lookupAnimation key state.elementAnimations
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
getCurrentTranslate key (AnimState state) =
    lookupAnimation key state.elementAnimations
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
getCurrentRotate key (AnimState state) =
    lookupAnimation key state.elementAnimations
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
getCurrentScale key (AnimState state) =
    lookupAnimation key state.elementAnimations
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
getCurrentSize key (AnimState state) =
    lookupAnimation key state.elementAnimations
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
    , animGroup : String
    , progress : Float
    , translate : Maybe { x : Float, y : Float, z : Float }
    , opacity : Maybe Float
    , rotate : Maybe { x : Float, y : Float, z : Float }
    , scale : Maybe { x : Float, y : Float, z : Float }
    , backgroundColor : Maybe String
    , color : Maybe String
    , size : Maybe { width : Float, height : Float }
    , isAnimating : Bool
    , propertyVersions : Dict String Int -- Maps property type to version number
    }


animationUpdateDecoder : Decoder AnimationUpdate
animationUpdateDecoder =
    Decode.succeed AnimationUpdate
        |> andMap (Decode.field "elementId" Decode.string)
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
                    (\( compositeKey, config ) ->
                        let
                            jsElementId =
                                config.targetElement
                                    |> Maybe.withDefault (getElementIdForJs compositeKey)

                            elementAnim =
                                Dict.get compositeKey elementAnimations

                            elementProps =
                                elementAnim
                                    |> Maybe.map .properties
                                    |> Maybe.withDefault Dict.empty

                            elemTransformOrder =
                                elementAnim
                                    |> Maybe.map .transformOrder
                                    |> Maybe.withDefault defaultTransformOrder

                            -- hasExplicitTarget is True when:
                            -- 1. forElement was used (targetElement is set), OR
                            -- 2. Using single key pattern (not a composite key) where the key IS the element ID
                            hasExplicitTarget =
                                config.targetElement /= Nothing || not (Builder.isCompositeKey compositeKey)
                        in
                        ( jsElementId
                        , encodeProcessedElementConfig
                            { versions = Just elementProps
                            , transformOrder = Just elemTransformOrder
                            , hasExplicitTarget = Just hasExplicitTarget
                            }
                            compositeKey
                            config
                        )
                    )
    in
    Encode.object
        [ ( "type", Encode.string "animate" )
        , ( "elements", Encode.object elementsWithVersions )
        ]


encode : Builder.ProcessedAnimationData -> Encode.Value
encode data =
    let
        elementsForJs =
            data.elements
                |> Dict.toList
                |> List.map
                    (\( compositeKey, config ) ->
                        let
                            jsElementId =
                                config.targetElement
                                    |> Maybe.withDefault (getElementIdForJs compositeKey)
                        in
                        ( jsElementId
                        , encodeProcessedElementConfig
                            { versions = Nothing
                            , transformOrder = Nothing
                            , hasExplicitTarget = Nothing
                            }
                            compositeKey
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
encodeCommandWithProperties commandType elementId maybeProperties =
    let
        baseFields =
            [ ( "type", Encode.string commandType )
            , ( "elementId", Encode.string elementId )
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
encodeIterationCount : IterationCount -> Encode.Value
encodeIterationCount iterationCount =
    case iterationCount of
        Once ->
            Encode.object
                [ ( "type", Encode.string "once" )
                , ( "count", Encode.int 1 )
                ]

        Times n ->
            Encode.object
                [ ( "type", Encode.string "times" )
                , ( "count", Encode.int n )
                ]

        Infinite ->
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
    { versions : Maybe (Dict String PropertyAnimation)
    , transformOrder : Maybe (List Builder.TransformOrder)
    , hasExplicitTarget : Maybe Bool
    }
    -> String
    -> Builder.ProcessedElementConfig
    -> Encode.Value
encodeProcessedElementConfig options compositeKey config =
    let
        animGroup =
            Builder.extractGroupName compositeKey

        baseFields =
            [ ( "properties", Encode.list (encodeProcessedPropertyConfig options.versions) config.properties )
            , ( "animGroup", Encode.string animGroup )
            ]

        optionalFields =
            (options.hasExplicitTarget
                |> Maybe.map (\b -> [ ( "hasExplicitTarget", Encode.bool b ) ])
                |> Maybe.withDefault []
            )
                ++ (options.transformOrder
                        |> Maybe.map (\order -> [ ( "transformOrder", encodeTransformOrder order ) ])
                        |> Maybe.withDefault []
                   )
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


encodeProcessedPropertyConfig : Maybe (Dict String PropertyAnimation) -> Builder.ProcessedPropertyConfig -> Encode.Value
encodeProcessedPropertyConfig maybeVersions property =
    let
        versionFields =
            case maybeVersions of
                Just propertyVersions ->
                    let
                        propType =
                            propertyTypeString property

                        version =
                            Dict.get propType propertyVersions
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


stop : String -> AnimState msg -> ( AnimState msg, Cmd msg )
stop rawKey (AnimState state) =
    let
        key =
            normalizeKey rawKey

        -- Resolve the key: if it's an element ID, find the first matching composite key
        resolvedKey =
            if Builder.isCompositeKey key then
                key

            else
                getMatchingCompositeKeys key state.elementAnimations
                    |> List.head
                    |> Maybe.withDefault key

        -- Get the element ID for JavaScript command
        elementId =
            getElementIdForJs resolvedKey

        -- Get property types to filter (Nothing = all properties)
        propertyFilter =
            getPropertyTypesForKey key state.elementAnimations

        -- Get all matching composite keys
        matchingKeys =
            getMatchingCompositeKeys key state.elementAnimations

        -- Update pending actions for all matching keys
        updatedPendingActions =
            List.foldl
                (\k acc -> Dict.insert k PendingStop acc)
                state.pendingActions
                matchingKeys

        -- Update elementAnimations with per-key end states
        updatedElementAnimations =
            List.foldl
                (\k acc ->
                    let
                        endStatesForK =
                            Builder.getCurrentAnimation k state.builder
                                |> Maybe.andThen
                                    (\historyEntry ->
                                        historyEntry.processedData.elements
                                            |> Dict.get k
                                            |> Maybe.map (extractElementStates >> .end)
                                    )
                                |> Maybe.withDefault emptyElementStates
                    in
                    Dict.update k
                        (Maybe.map
                            (\anim ->
                                { anim | currentStates = mergeElementStates anim.currentStates endStatesForK }
                            )
                        )
                        acc
                )
                state.elementAnimations
                matchingKeys
    in
    ( AnimState
        { state
            | pendingActions = updatedPendingActions
            , elementAnimations = updatedElementAnimations
        }
    , state.commandPort <|
        encodeCommandWithProperties "stop" elementId propertyFilter
    )


pause : String -> AnimState msg -> ( AnimState msg, Cmd msg )
pause rawKey (AnimState state) =
    let
        key =
            normalizeKey rawKey

        -- Get the element ID for JavaScript command
        elementId =
            resolveElementIdForJs key state.elementAnimations

        -- Get property types to filter (Nothing = all properties)
        propertyFilter =
            getPropertyTypesForKey key state.elementAnimations

        -- Get all matching composite keys
        matchingKeys =
            getMatchingCompositeKeys key state.elementAnimations

        -- Update pending actions for all matching keys
        updatedPendingActions =
            List.foldl
                (\k acc -> Dict.insert k PendingPause acc)
                state.pendingActions
                matchingKeys
    in
    ( AnimState
        { state
            | pendingActions = updatedPendingActions
        }
    , state.commandPort <|
        encodeCommandWithProperties "pause" elementId propertyFilter
    )


{-| Reset an element to its initial animation state by resetting internal state and creating a 0ms animation to start positions.

The key parameter can be either:

  - A composite key like `"myBox:fadeIn"` - resets that specific animation
  - An element ID like `"myBox"` - resets all matching animations for that element

-}
reset : String -> AnimState msg -> ( AnimState msg, Cmd msg )
reset rawKey (AnimState state) =
    let
        key =
            normalizeKey rawKey

        matchingKeys =
            if Builder.isCompositeKey key then
                [ key ]

            else
                let
                    compositeKeys =
                        getMatchingCompositeKeys key state.elementAnimations
                in
                if List.isEmpty compositeKeys then
                    [ key ]

                else
                    compositeKeys
    in
    List.foldl
        (\resolvedKey ( AnimState accState, accCmds ) ->
            let
                ( newAnimState, cmd ) =
                    resetSingleKey resolvedKey (AnimState accState)
            in
            ( newAnimState, cmd :: accCmds )
        )
        ( AnimState state, [] )
        matchingKeys
        |> Tuple.mapSecond Cmd.batch


resetSingleKey : String -> AnimState msg -> ( AnimState msg, Cmd msg )
resetSingleKey resolvedKey (AnimState state) =
    let
        -- Get the element ID for JavaScript targets
        jsElementId =
            getElementIdForJs resolvedKey
    in
    case Builder.getCurrentAnimation resolvedKey state.builder of
        Nothing ->
            ( AnimState state, Cmd.none )

        Just historyEntry ->
            let
                -- Extract start and end states from the animation history
                states =
                    historyEntry.processedData.elements
                        |> Dict.get resolvedKey
                        |> Maybe.map extractElementStates

                startStates =
                    states
                        |> Maybe.map .start
                        |> Maybe.withDefault emptyElementStates

                endStates =
                    states
                        |> Maybe.map .end
                        |> Maybe.withDefault emptyElementStates

                -- Get properties that were in the original animation
                animatedPropertyTypes =
                    historyEntry.processedData.elements
                        |> Dict.get resolvedKey
                        |> Maybe.map .properties
                        |> Maybe.withDefault []
                        |> List.map propertyTypeString

                -- Create 0ms animation to visually jump to start positions
                -- Use the resolved key for Builder.for so it ends up in the right place
                groupName =
                    Builder.extractGroupName resolvedKey

                resetBuilder =
                    Builder.init
                        |> Builder.duration 0
                        |> Builder.easing Linear
                        |> Builder.for groupName
                        |> Builder.setTargetElement jsElementId
                        |> addResetProperties resolvedKey endStates startStates

                processedData =
                    Builder.processAnimationData resetBuilder
            in
            case Dict.get resolvedKey state.elementAnimations of
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
                            Dict.insert resolvedKey newElementAnimation state.elementAnimations

                        updatedAnimState =
                            AnimState
                                { state
                                    | elementAnimations = updatedElementAnimations
                                    , isRunning = False
                                    , pendingActions = Dict.insert resolvedKey (PendingReset startStates) state.pendingActions
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
                            Dict.insert resolvedKey resetElementAnimation state.elementAnimations

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
                                    , pendingActions = Dict.insert resolvedKey (PendingReset startStates) state.pendingActions
                                }
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeWithVersions updatedElementAnimations processedData
                    )


{-| Restart the last animation by retrieving it from Builder history and replaying it.
The history will have already been updated by onResize, so we can use it directly.

The key parameter can be either:

  - A composite key like `"myBox:fadeIn"` - restarts that specific animation
  - An element ID like `"myBox"` - restarts all matching animations for that element

-}
restart : String -> AnimState msg -> ( AnimState msg, Cmd msg )
restart rawKey (AnimState state) =
    let
        key =
            normalizeKey rawKey

        matchingKeys =
            if Builder.isCompositeKey key then
                [ key ]

            else
                let
                    compositeKeys =
                        getMatchingCompositeKeys key state.elementAnimations
                in
                if List.isEmpty compositeKeys then
                    [ key ]

                else
                    compositeKeys
    in
    List.foldl
        (\resolvedKey ( AnimState accState, accCmds ) ->
            let
                ( newAnimState, cmd ) =
                    restartSingleKey resolvedKey (AnimState accState)
            in
            ( newAnimState, cmd :: accCmds )
        )
        ( AnimState state, [] )
        matchingKeys
        |> Tuple.mapSecond Cmd.batch


restartSingleKey : String -> AnimState msg -> ( AnimState msg, Cmd msg )
restartSingleKey resolvedKey (AnimState state) =
    case Builder.restartCurrentAnimation resolvedKey state.builder of
        Nothing ->
            ( AnimState state, Cmd.none )

        Just processedData ->
            -- Get properties that are being restarted
            let
                restartedPropertyTypes =
                    processedData.elements
                        |> Dict.get resolvedKey
                        |> Maybe.map .properties
                        |> Maybe.withDefault []
                        |> List.map propertyTypeString

                startStates =
                    processedData.elements
                        |> Dict.get resolvedKey
                        |> Maybe.map (extractElementStates >> .start)
                        |> Maybe.withDefault emptyElementStates
            in
            case Dict.get resolvedKey state.elementAnimations of
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
                            Dict.insert resolvedKey newElementAnimation state.elementAnimations

                        updatedAnimState =
                            AnimState
                                { state
                                    | elementAnimations = updatedElementAnimations
                                    , isRunning = True
                                    , pendingActions = Dict.insert resolvedKey PendingRestart state.pendingActions
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
                            Dict.insert resolvedKey resetElementAnimation state.elementAnimations

                        updatedAnimState =
                            AnimState
                                { state
                                    | elementAnimations = updatedElementAnimations
                                    , isRunning = True
                                    , pendingActions = Dict.insert resolvedKey PendingRestart state.pendingActions
                                }
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeWithVersions updatedElementAnimations processedData
                    )


resume : String -> AnimState msg -> ( AnimState msg, Cmd msg )
resume rawKey (AnimState state) =
    let
        key =
            normalizeKey rawKey

        -- Get the element ID for JavaScript command
        elementId =
            resolveElementIdForJs key state.elementAnimations

        -- Get property types to filter (Nothing = all properties)
        propertyFilter =
            getPropertyTypesForKey key state.elementAnimations

        -- Get all matching composite keys
        matchingKeys =
            getMatchingCompositeKeys key state.elementAnimations

        -- Update pending actions for all matching keys
        updatedPendingActions =
            List.foldl
                (\k acc -> Dict.insert k PendingResume acc)
                state.pendingActions
                matchingKeys
    in
    ( AnimState
        { state
            | pendingActions = updatedPendingActions
        }
    , state.commandPort <|
        encodeCommandWithProperties "resume" elementId propertyFilter
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
