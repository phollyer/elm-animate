module Anim.Internal.Engine.Animation.WAAPI exposing
    ( AnimBuilder
    , AnimEvent(..)
    , AnimMsg
    , AnimState
    , FreezeProperty
    , allComplete
    , alternate
    , animate
    , anyRunning
    , attributes
    , decodeAnimationEvent
    , delay
    , discreteEntry
    , discreteExit
    , duration
    , easing
    , encode
    , fireAndForget
    , freezeAxes
    , freezeRotate
    , freezeScale
    , freezeTranslate
    , getBackgroundColorCurrent
    , getBackgroundColorEnd
    , getBackgroundColorRange
    , getBackgroundColorStart
    , getCurrentOpacity
    , getCurrentRotate
    , getCurrentScale
    , getCurrentSize
    , getCurrentTranslate
    , getEndOpacity
    , getEndRotate
    , getEndScale
    , getEndSize
    , getEndTranslate
    , getFontColorCurrent
    , getFontColorEnd
    , getFontColorRange
    , getFontColorStart
    , getOpacityRange
    , getOpacityStart
    , getProgress
    , getRotateRange
    , getScaleRange
    , getSizeRange
    , getStartRotate
    , getStartScale
    , getStartSize
    , getStartTranslate
    , getTranslateRange
    , init
    , isComplete
    , isElementRunning
    , iterations
    , loopForever
    , onResize
    , pause
    , reset
    , restart
    , resume
    , speed
    , stop
    , subscriptions
    , transformOrder
    , unfreezeAxes
    , update
    , updatePositions
    )

import Anim.Extra.Easing exposing (Easing(..))
import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder as Builder exposing (AnimationDirection(..))
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Builder.FontColor as FontColor
import Anim.Internal.Builder.Opacity as Opacity
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Builder.Rotate as Rotate
import Anim.Internal.Builder.Scale as Scale
import Anim.Internal.Builder.Size as Size
import Anim.Internal.Builder.Translate as Translate
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Animation.WAAPI.AnimGroup as AnimGroup exposing (AnimGroup, AnimationStatus, PropertyAnimation)
import Anim.Internal.Engine.Animation.WAAPI.Generator as Generator
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Extra.Easing as Easing
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Translate as Translate
import Dict
import Html
import Html.Attributes
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode



{- ***** MODEL ***** -}


type AnimState msg
    = AnimState
        { subscriptionsActive : Bool
        , commandPort : Encode.Value -> Cmd msg
        , subscriptionPort : (Decode.Value -> msg) -> Sub msg
        , builder : Builder.AnimBuilder
        }
        (AnimGroups AnimGroup)


type alias AnimBuilder =
    Builder.AnimBuilder


type alias AnimGroupName =
    String



{- **** INITIALIZE **** -}


init : (Encode.Value -> Cmd msg) -> ((Decode.Value -> msg) -> Sub msg) -> List (AnimBuilder -> AnimBuilder) -> AnimState msg
init commandPort subscriptionPort propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { builder = Builder.init []
                , subscriptionsActive = False
                , commandPort = commandPort
                , subscriptionPort = subscriptionPort
                }
                AnimGroups.init

        _ ->
            let
                builder =
                    Builder.init propertyInitializers

                animGroups =
                    Builder.getAnimGroups builder

                initGroup : AnimGroupName -> Builder.AnimGroupConfig -> AnimGroup
                initGroup _ { properties } =
                    Generator.init
                        (Builder.getDiscreteEntryProperties builder)
                        (Builder.getDiscreteExitProperties builder)
                        properties
            in
            AnimState
                { subscriptionsActive = False
                , builder =
                    builder
                        |> Builder.mergeBaselines
                        |> Builder.clearAnimData
                , commandPort = commandPort
                , subscriptionPort = subscriptionPort
                }
                (AnimGroups.map initGroup animGroups)



{- ***** TRIGGER ***** -}


fireAndForget : (Encode.Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg
fireAndForget sendToPort buildAnimation =
    Builder.init [ buildAnimation ]
        |> Builder.process
        |> encode
        |> sendToPort


animate : AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )
animate (AnimState state animGroups) build =
    let
        builder =
            state.builder
                |> Builder.injectCurrentStates animGroups
                |> build

        processed =
            Builder.process builder

        generateAnimGroup : AnimGroupName -> { a | properties : List Builder.ProcessedPropertyConfig } -> AnimGroup
        generateAnimGroup animGroupName { properties } =
            Generator.generateAnimation
                processed.iterations
                processed.animationDirection
                processed.globalTransformOrder
                (Builder.getDiscreteEntryProperties builder)
                (Builder.getDiscreteExitProperties builder)
                (AnimGroups.get animGroupName animGroups)
                properties

        insertAnimGroup : AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertAnimGroup animGroupName animGroup acc =
            case AnimGroups.get animGroupName acc of
                Nothing ->
                    AnimGroups.insert animGroupName animGroup acc

                Just existing ->
                    AnimGroups.insert animGroupName
                        { propertySnapshot = animGroup.propertySnapshot
                        , properties = AnimGroups.union animGroup.properties existing.properties
                        , transformOrder = animGroup.transformOrder
                        , progress = 0
                        , iterations = animGroup.iterations
                        , animationDirection = animGroup.animationDirection
                        , discreteEntry = animGroup.discreteEntry
                        , discreteExit = animGroup.discreteExit
                        }
                        acc

        processedAnimGroups =
            processed.groups
                |> AnimGroups.map generateAnimGroup
                |> AnimGroups.foldl insertAnimGroup animGroups
    in
    ( AnimState
        { state
            | builder =
                builder
                    |> Builder.addAnimationToHistory processed
                    |> Builder.mergeBaselines
                    |> Builder.clearAnimData
            , subscriptionsActive = True
        }
        processedAnimGroups
    , state.commandPort <|
        encodeWithVersions processedAnimGroups processed
    )



{- ***** EVENTS ***** -}


type AnimEvent
    = Started AnimGroupName
    | Ended AnimGroupName
    | Cancelled AnimGroupName Float
    | Restarted AnimGroupName
    | Paused AnimGroupName Float
    | Resumed AnimGroupName
    | Iteration AnimGroupName Int
    | Progress AnimGroupName Float
    | JavaScriptError String



{- ***** UPDATE ***** -}


type AnimMsg
    = PropertyUpdate Decode.Value
    | LifecycleEvent Decode.Value
    | UnknownMessage String


update : AnimMsg -> AnimState msg -> ( AnimState msg, AnimEvent )
update msg animState =
    case msg of
        PropertyUpdate jsonValue ->
            let
                ( newState, propertyResult ) =
                    updatePropertyUpdate jsonValue animState
            in
            ( newState
            , Progress propertyResult.animGroupName propertyResult.progress
            )

        LifecycleEvent jsonValue ->
            case decodeAnimationEvent jsonValue of
                Just animEvent ->
                    ( handleEventInternal animEvent animState
                    , animEvent
                    )

                Nothing ->
                    ( animState
                    , Progress "" 0
                    )

        UnknownMessage unknown ->
            ( animState
            , JavaScriptError ("Unknown message: " ++ unknown)
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
                    AnimGroups.groups updatedAnimations
                        |> List.any
                            (\elementAnim ->
                                AnimGroups.groups elementAnim.properties
                                    |> List.any (\prop -> prop.status == AnimGroup.Running)
                            )
            in
            ( AnimState { state | subscriptionsActive = hasRunningAnimations } updatedAnimations
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
            elementAnimation.propertySnapshot

        newCurrentStates =
            existing
                |> (\b ->
                        case animUpdate.translate of
                            Just t ->
                                PropertyBaselines.setTranslate (Translate.fromTriple ( t.x, t.y, t.z )) b

                            Nothing ->
                                b
                   )
                |> (\b ->
                        case animUpdate.rotate of
                            Just r ->
                                PropertyBaselines.setRotate (Rotate.fromTriple ( r.x, r.y, r.z )) b

                            Nothing ->
                                b
                   )
                |> (\b ->
                        case animUpdate.scale of
                            Just s ->
                                PropertyBaselines.setScale (Scale.fromTriple ( s.x, s.y, s.z )) b

                            Nothing ->
                                b
                   )
                |> (\b ->
                        case animUpdate.opacity of
                            Just o ->
                                PropertyBaselines.setOpacity (Opacity.fromFloat o) b

                            Nothing ->
                                b
                   )
                |> (\b ->
                        case animUpdate.backgroundColor of
                            Just bg ->
                                case Color.fromString bg of
                                    Just c ->
                                        PropertyBaselines.setBackgroundColor c b

                                    Nothing ->
                                        b

                            Nothing ->
                                b
                   )
                |> (\b ->
                        case animUpdate.color of
                            Just c ->
                                case Color.fromString c of
                                    Just fc ->
                                        PropertyBaselines.setFontColor fc b

                                    Nothing ->
                                        b

                            Nothing ->
                                b
                   )
                |> (\b ->
                        case animUpdate.size of
                            Just s ->
                                PropertyBaselines.setSize (Size.fromTuple ( s.width, s.height )) b

                            Nothing ->
                                b
                   )

        newStatus =
            if animUpdate.isAnimating then
                AnimGroup.Running

            else
                AnimGroup.Complete

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
        | propertySnapshot = newCurrentStates
        , properties = updatedProperties
        , progress = animUpdate.progress
    }



{- ***** SUBSCRIPTIONS ***** -}


subscriptions : (AnimMsg -> msg) -> AnimState msg -> Sub msg
subscriptions toMsg (AnimState state _) =
    state.subscriptionPort
        (\jsonValue ->
            -- Route based on JSON type field
            case Decode.decodeValue (Decode.field "type" Decode.string) jsonValue of
                Ok "animationUpdate" ->
                    toMsg (LifecycleEvent jsonValue)

                Ok "propertyUpdate" ->
                    toMsg (PropertyUpdate jsonValue)

                Ok unknown ->
                    toMsg <|
                        UnknownMessage <|
                            "Unknown message type: "
                                ++ unknown

                Err unknown ->
                    toMsg <|
                        UnknownMessage <|
                            Decode.errorToString unknown
        )



{- ***** VIEW ***** -}
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
                propertySnapshot =
                    animGroup.propertySnapshot

                -- Build transform parts
                translatePart =
                    PropertyBaselines.getTranslate propertySnapshot
                        |> Maybe.map Translate.toCssString
                        |> Maybe.withDefault ""

                rotatePart =
                    PropertyBaselines.getRotate propertySnapshot
                        |> Maybe.map Rotate.toCssString
                        |> Maybe.withDefault ""

                scalePart =
                    PropertyBaselines.getScale propertySnapshot
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
                    PropertyBaselines.getOpacity propertySnapshot
                        |> Maybe.map (\o -> Html.Attributes.style "opacity" (Opacity.toString o))
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                backgroundColorStyle =
                    PropertyBaselines.getBackgroundColor propertySnapshot
                        |> Maybe.map (\c -> Html.Attributes.style "background-color" (Color.toCssString c))
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                fontColorStyle =
                    PropertyBaselines.getFontColor propertySnapshot
                        |> Maybe.map (\c -> Html.Attributes.style "color" (Color.toCssString c))
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []

                sizeStyles =
                    PropertyBaselines.getSize propertySnapshot
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

                discreteStyles =
                    discreteEntryStyles animGroup
                        ++ discreteExitStyles animGroup
            in
            dataAttr :: transformStyle ++ opacityStyle ++ backgroundColorStyle ++ fontColorStyle ++ sizeStyles ++ discreteStyles



{- ***** CONTROL ***** -}


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


type alias FreezeProperty =
    Builder.FreezeProperty


freezeTranslate : FreezeProperty
freezeTranslate =
    Builder.FreezeTranslate


freezeRotate : FreezeProperty
freezeRotate =
    Builder.FreezeRotate


freezeScale : FreezeProperty
freezeScale =
    Builder.FreezeScale


iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    Builder.iterations


loopForever : AnimBuilder -> AnimBuilder
loopForever =
    Builder.loopForever


alternate : AnimBuilder -> AnimBuilder
alternate =
    Builder.alternate


discreteEntry : String -> String -> AnimBuilder -> AnimBuilder
discreteEntry =
    Builder.discreteEntry


discreteExit : String -> String -> String -> AnimBuilder -> AnimBuilder
discreteExit =
    Builder.discreteExit


transformOrder : List TransformProperty -> AnimBuilder -> AnimBuilder
transformOrder =
    Builder.transformOrder


freezeAxes : List String -> List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeAxes =
    Builder.freezeAxes


unfreezeAxes : List String -> List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeAxes =
    Builder.unfreezeAxes


{-| Decode just the animation event from JavaScript (without state updates).
Returns AnimEvent if this is an animation lifecycle event.
Returns Nothing for property updates or unknown event types.
-}
decodeAnimationEvent : Decode.Value -> Maybe AnimEvent
decodeAnimationEvent jsonValue =
    case Decode.decodeValue (Decode.field "type" Decode.string) jsonValue of
        Ok "animationUpdate" ->
            Decode.decodeValue animEventDecoder jsonValue
                |> Result.toMaybe

        _ ->
            Nothing


{-| Decoder for AnimEvent from lifecycle events.
-}
animEventDecoder : Decode.Decoder AnimEvent
animEventDecoder =
    Decode.map3 statusToAnimEvent
        (Decode.oneOf [ Decode.at [ "payload", "animGroup" ] Decode.string, Decode.at [ "payload", "elementId" ] Decode.string ])
        (Decode.at [ "payload", "status" ] Decode.string)
        (Decode.at [ "payload", "progress" ] Decode.float)


{-| Map a decoded status string to the appropriate AnimEvent constructor.
-}
statusToAnimEvent : String -> String -> Float -> AnimEvent
statusToAnimEvent animGroupName status progress =
    case status of
        "started" ->
            Started animGroupName

        "paused" ->
            Paused animGroupName progress

        "resumed" ->
            Resumed animGroupName

        "completed" ->
            Ended animGroupName

        "cancelled" ->
            Cancelled animGroupName progress

        "stopped" ->
            Ended animGroupName

        "reset" ->
            Cancelled animGroupName progress

        "restarted" ->
            Restarted animGroupName

        "iteration" ->
            Iteration animGroupName (round progress)

        invalid ->
            JavaScriptError ("Unknown status: " ++ invalid)


{-| Internal: Update optimistic state based on an animation lifecycle event.
-}
handleEventInternal : AnimEvent -> AnimState msg -> AnimState msg
handleEventInternal animEvent (AnimState state animGroups) =
    let
        animGroupName =
            animEventGroupName animEvent

        newStatus =
            animEventToStatus animEvent

        matchingKeys =
            getMatchingKeys animGroupName animGroups

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
                                            AnimGroup.Complete ->
                                                1.0

                                            AnimGroup.NotStarted ->
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
            AnimGroups.groups updatedElementAnimations
                |> List.any
                    (\anim ->
                        AnimGroups.groups anim.properties
                            |> List.any (\prop -> prop.status == AnimGroup.Running)
                    )
    in
    AnimState
        { state | subscriptionsActive = isRunning }
        updatedElementAnimations


animEventGroupName : AnimEvent -> String
animEventGroupName animEvent =
    case animEvent of
        Started name ->
            name

        Ended name ->
            name

        Cancelled name _ ->
            name

        Restarted name ->
            name

        Paused name _ ->
            name

        Resumed name ->
            name

        Iteration name _ ->
            name

        Progress name _ ->
            name

        JavaScriptError _ ->
            ""


animEventToStatus : AnimEvent -> AnimationStatus
animEventToStatus animEvent =
    case animEvent of
        Started _ ->
            AnimGroup.Running

        Ended _ ->
            AnimGroup.Complete

        Cancelled _ _ ->
            AnimGroup.Complete

        Restarted _ ->
            AnimGroup.Running

        Paused _ _ ->
            AnimGroup.Paused

        Resumed _ ->
            AnimGroup.Running

        Iteration _ _ ->
            AnimGroup.Running

        Progress _ _ ->
            AnimGroup.Running

        JavaScriptError _ ->
            -- TODO: Consider if we want a separate status for errors
            AnimGroup.Running


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

                                updatedCurrentStates =
                                    PropertyBaselines.setTranslate newTranslate elementAnim.propertySnapshot
                            in
                            { elementAnim | propertySnapshot = updatedCurrentStates }
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
            AnimGroups.get animGroupName animGroups
                |> Maybe.andThen (\elem -> AnimGroups.get "translate" elem.properties)
                |> Maybe.map (\prop -> prop.status == AnimGroup.Running || prop.status == AnimGroup.Paused)
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
                    AnimGroups.get posUpdate.animGroupName updatedAnimations
                        |> Maybe.map
                            (\elementAnim ->
                                let
                                    scale =
                                        PropertyBaselines.getScale elementAnim.propertySnapshot
                                            |> Maybe.map Scale.toRecord
                                            |> Maybe.withDefault { x = 1, y = 1, z = 1 }

                                    rotate =
                                        PropertyBaselines.getRotate elementAnim.propertySnapshot
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
                    AnimGroups.get posUpdate.animGroupName updatedAnimations
                        |> Maybe.map
                            (\elementAnim ->
                                let
                                    scale =
                                        PropertyBaselines.getScale elementAnim.propertySnapshot
                                            |> Maybe.map Scale.toRecord
                                            |> Maybe.withDefault { x = 1, y = 1, z = 1 }

                                    rotate =
                                        PropertyBaselines.getRotate elementAnim.propertySnapshot
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


{-| Convert a TransformProperty to its corresponding CSS string part.
-}
transformOrderToPart : String -> String -> String -> TransformProperty -> String
transformOrderToPart translatePart rotatePart scalePart order =
    case order of
        TransformProperty.Translate ->
            translatePart

        TransformProperty.Rotate ->
            rotatePart

        TransformProperty.Scale ->
            scalePart


isAnimGroupComplete : AnimGroup -> Bool
isAnimGroupComplete animGroup =
    AnimGroups.groups animGroup.properties
        |> List.all (\prop -> prop.status == AnimGroup.Complete)


discreteEntryStyles : AnimGroup -> List (Html.Attribute msg)
discreteEntryStyles animGroup =
    Dict.toList animGroup.discreteEntry
        |> List.map (\( prop, value ) -> Html.Attributes.style prop value)


discreteExitStyles : AnimGroup -> List (Html.Attribute msg)
discreteExitStyles animGroup =
    Dict.toList animGroup.discreteExit
        |> List.map
            (\( prop, { from, to } ) ->
                if isAnimGroupComplete animGroup then
                    Html.Attributes.style prop to

                else
                    Html.Attributes.style prop from
            )



-- Query State


allComplete : AnimState msg -> Maybe Bool
allComplete (AnimState _ animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        -- Check if all properties in all elements have Complete status
        AnimGroups.groups animGroups
            |> List.all
                (\animGroup ->
                    AnimGroups.groups animGroup.properties
                        |> List.all (\prop -> prop.status == AnimGroup.Complete)
                )
            |> Just


anyRunning : AnimState msg -> Maybe Bool
anyRunning (AnimState state animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        Just state.subscriptionsActive


isComplete : AnimGroupName -> AnimState msg -> Maybe Bool
isComplete animGroupName (AnimState _ data) =
    AnimGroups.get animGroupName data
        |> Maybe.map
            (\elementAnimation ->
                AnimGroups.groups elementAnimation.properties
                    |> List.all (\prop -> prop.status == AnimGroup.Complete)
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
                AnimGroups.groups animGroup.properties
                    |> List.any (\prop -> prop.status == AnimGroup.Running)
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


getBackgroundColorStart : AnimGroupName -> AnimState msg -> Maybe Color
getBackgroundColorStart animGroupName animState =
    getBackgroundColorRange animGroupName animState
        |> getStartWithDefault BackgroundColor.default


getBackgroundColorEnd : AnimGroupName -> AnimState msg -> Maybe Color
getBackgroundColorEnd animGroupName animState =
    getBackgroundColorRange animGroupName animState
        |> Maybe.map .end


getBackgroundColorCurrent : AnimGroupName -> AnimState msg -> Maybe Color
getBackgroundColorCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (\ag -> PropertyBaselines.getBackgroundColor ag.propertySnapshot)


getBackgroundColorRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange animGroupName animState =
    getPropertyRange animGroupName animState <|
        \prop ->
            case prop of
                Builder.ProcessedBackgroundColorConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Font Color


getFontColorStart : AnimGroupName -> AnimState msg -> Maybe Color
getFontColorStart animGroupName animState =
    getFontColorRange animGroupName animState
        |> getStartWithDefault FontColor.default


getFontColorEnd : AnimGroupName -> AnimState msg -> Maybe Color
getFontColorEnd animGroupName animState =
    getFontColorRange animGroupName animState
        |> Maybe.map .end


getFontColorCurrent : AnimGroupName -> AnimState msg -> Maybe Color
getFontColorCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (\ag -> PropertyBaselines.getFontColor ag.propertySnapshot)


getFontColorRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Color, end : Color }
getFontColorRange animGroupName animState =
    getPropertyRange animGroupName animState <|
        \prop ->
            case prop of
                Builder.ProcessedFontColorConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing



-- Opacity


getOpacityStart : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityStart animGroupName =
    getOpacityRange animGroupName
        >> Maybe.andThen .start


getEndOpacity : AnimGroupName -> AnimState msg -> Maybe Float
getEndOpacity animGroupName =
    getOpacityRange animGroupName
        >> Maybe.map .end


getCurrentOpacity : AnimGroupName -> AnimState msg -> Maybe Float
getCurrentOpacity animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (\ag -> PropertyBaselines.getOpacity ag.propertySnapshot)
        |> Maybe.map Opacity.toFloat


getOpacityRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Float, end : Float }
getOpacityRange animGroupName animState =
    getPropertyRange animGroupName animState <|
        \prop ->
            case prop of
                Builder.ProcessedOpacityConfig config ->
                    Just
                        { start = Maybe.map Opacity.toFloat config.start
                        , end = Opacity.toFloat config.end
                        }

                _ ->
                    Nothing



-- Rotate


getStartRotate : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getStartRotate animGroupName =
    getRotateRange animGroupName
        >> Maybe.andThen .start
        >> Maybe.withDefault (Rotate.toRecord Rotate.default)
        >> Just


getEndRotate : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getEndRotate animGroupName animState =
    getRotateRange animGroupName animState
        |> Maybe.map .end


getCurrentRotate : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getCurrentRotate animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (\ag -> PropertyBaselines.getRotate ag.propertySnapshot)
        |> Maybe.map Rotate.toRecord


getRotateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange animGroupName animState =
    getPropertyRange animGroupName animState <|
        \prop ->
            case prop of
                Builder.ProcessedRotateConfig config ->
                    Just
                        { start = Maybe.map Rotate.toRecord config.start
                        , end = Rotate.toRecord config.end
                        }

                _ ->
                    Nothing



-- Scale


getStartScale : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getStartScale animGroupName =
    getScaleRange animGroupName
        >> Maybe.andThen .start
        >> Maybe.withDefault (Scale.toRecord Scale.default)
        >> Just


getEndScale : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getEndScale animGroupName animState =
    getScaleRange animGroupName animState
        |> Maybe.map .end


getCurrentScale : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getCurrentScale animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (\ag -> PropertyBaselines.getScale ag.propertySnapshot)
        |> Maybe.map Scale.toRecord


getScaleRange : String -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange animGroupName animState =
    getPropertyRange animGroupName animState <|
        \prop ->
            case prop of
                Builder.ProcessedScaleConfig config ->
                    Just
                        { start = Maybe.map Scale.toRecord config.start
                        , end = Scale.toRecord config.end
                        }

                _ ->
                    Nothing



-- Size


getStartSize : String -> AnimState msg -> Maybe { width : Float, height : Float }
getStartSize animGroupName =
    getSizeRange animGroupName
        >> Maybe.andThen .start


getEndSize : String -> AnimState msg -> Maybe { width : Float, height : Float }
getEndSize animGroupName =
    getSizeRange animGroupName
        >> Maybe.map .end


getCurrentSize : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getCurrentSize animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (\ag -> PropertyBaselines.getSize ag.propertySnapshot)
        |> Maybe.map Size.toRecord


getSizeRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange animGroupName animState =
    getPropertyRange animGroupName animState <|
        \prop ->
            case prop of
                Builder.ProcessedSizeConfig config ->
                    Just
                        { start = Maybe.map Size.toRecord config.start
                        , end = Size.toRecord config.end
                        }

                _ ->
                    Nothing



-- Translate


getStartTranslate : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getStartTranslate animGroupName =
    getTranslateRange animGroupName
        >> Maybe.andThen .start
        >> Maybe.withDefault (Translate.toRecord Translate.default)
        >> Just


getEndTranslate : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getEndTranslate animGroupName =
    getTranslateRange animGroupName
        >> Maybe.map .end


getCurrentTranslate : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getCurrentTranslate animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (\ag -> PropertyBaselines.getTranslate ag.propertySnapshot)
        |> Maybe.map Translate.toRecord


getTranslateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange animGroupName animState =
    getPropertyRange animGroupName animState <|
        \prop ->
            case prop of
                Builder.ProcessedTranslateConfig config ->
                    Just
                        { start = Maybe.map Translate.toRecord config.start
                        , end = Translate.toRecord config.end
                        }

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


encodeWithVersions : AnimGroups AnimGroup -> Builder.ProcessedAnimationData -> Encode.Value
encodeWithVersions elementAnimations processed =
    let
        elementsWithVersions =
            processed.groups
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
                                    |> Maybe.withDefault TransformProperty.default
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
        , ( "iterations", encodeIterations processed.iterations )
        , ( "direction", encodeAnimationDirection processed.animationDirection )
        ]


encodeRestartWithVersions : Builder.Iterations -> Builder.AnimationDirection -> AnimGroups AnimGroup -> AnimGroups Builder.ProcessedAnimGroupConfig -> Encode.Value
encodeRestartWithVersions iterationsConfig directionConfig elementAnimations groups =
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
                                    |> Maybe.withDefault TransformProperty.default
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
        , ( "iterations", encodeIterations iterationsConfig )
        , ( "direction", encodeAnimationDirection directionConfig )
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


encodeProcessedElementConfig :
    { versions : Maybe (AnimGroups PropertyAnimation)
    , transformOrder : Maybe (List TransformProperty)
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
encodeTransformOrder : List TransformProperty -> Encode.Value
encodeTransformOrder order =
    Encode.list
        (\t ->
            case t of
                TransformProperty.Translate ->
                    Encode.string "translate"

                TransformProperty.Rotate ->
                    Encode.string "rotate"

                TransformProperty.Scale ->
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

        -- Update elementAnimations with per-key end states
        updatedElementAnimations =
            List.foldl
                (\k acc ->
                    let
                        endStatesForK =
                            Builder.getCurrentAnimation k state.builder
                                |> Maybe.map (.properties >> Generator.propertyBounds >> .end)
                                |> Maybe.withDefault PropertyBaselines.empty
                    in
                    AnimGroups.update k
                        (Maybe.map
                            (\anim ->
                                { anim | propertySnapshot = PropertyBaselines.merge anim.propertySnapshot endStatesForK }
                            )
                        )
                        acc
                )
                animGroups
                matchingKeys
    in
    ( AnimState state updatedElementAnimations
    , state.commandPort <|
        encodeCommandWithProperties "stop" animGroupName Nothing
    )


pause : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
pause animGroupName (AnimState state animGroups) =
    ( AnimState state animGroups
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
                    Generator.propertyBounds properties

                startStates =
                    states.start

                endStates =
                    states.end

                -- Get properties that were in the original animation
                animatedPropertyTypes =
                    properties
                        |> List.map Generator.propertyTypeString

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
                                |> List.map (\propType -> ( propType, { version = 1, status = AnimGroup.NotStarted } ))
                                |> AnimGroups.fromList

                        newElementAnimation =
                            { propertySnapshot = startStates
                            , properties = newProperties
                            , transformOrder = TransformProperty.default
                            , progress = 0
                            , iterations = Builder.Once
                            , animationDirection = Builder.Normal
                            , discreteEntry = Dict.empty
                            , discreteExit = Dict.empty
                            }

                        updatedElementAnimations =
                            AnimGroups.insert resolvedKey newElementAnimation animGroups

                        updatedAnimState =
                            AnimState
                                { state | subscriptionsActive = False }
                                updatedElementAnimations
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
                                |> AnimGroups.map
                                    (\propType propAnim ->
                                        if List.member propType animatedPropertyTypes then
                                            { propAnim
                                                | version = propAnim.version + 1
                                                , status = AnimGroup.NotStarted
                                            }

                                        else
                                            propAnim
                                    )

                        resetElementAnimation =
                            { elementAnimation
                                | propertySnapshot = startStates
                                , properties = updatedProperties
                                , progress = 0
                            }

                        updatedElementAnimations =
                            AnimGroups.insert resolvedKey resetElementAnimation animGroups

                        updatedAnimState =
                            AnimState
                                { state
                                    | subscriptionsActive =
                                        AnimGroups.groups updatedElementAnimations
                                            |> List.any
                                                (\anim ->
                                                    AnimGroups.groups anim.properties
                                                        |> List.any (\prop -> prop.status == AnimGroup.Running)
                                                )
                                }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeWithVersions updatedElementAnimations processedData
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


getMatchingKeys : String -> AnimGroups AnimGroup -> List String
getMatchingKeys key dict =
    if AnimGroups.member key dict then
        [ key ]

    else
        []


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
                        |> List.map Generator.propertyTypeString

                startStates =
                    (Generator.propertyBounds processedData.properties).start
            in
            case AnimGroups.get resolvedKey animGroups of
                Nothing ->
                    -- No tracking entry exists, create one with property versions
                    let
                        newProperties =
                            restartedPropertyTypes
                                |> List.map (\propType -> ( propType, { version = 1, status = AnimGroup.NotStarted } ))
                                |> AnimGroups.fromList

                        newElementAnimation =
                            { propertySnapshot = startStates
                            , properties = newProperties
                            , transformOrder = TransformProperty.default
                            , progress = 0
                            , iterations = Builder.Once
                            , animationDirection = Builder.Normal
                            , discreteEntry = Dict.empty
                            , discreteExit = Dict.empty
                            }

                        updatedElementAnimations =
                            AnimGroups.insert resolvedKey newElementAnimation animGroups

                        updatedAnimState =
                            AnimState
                                { state | subscriptionsActive = True }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeRestartWithVersions
                            newElementAnimation.iterations
                            newElementAnimation.animationDirection
                            updatedElementAnimations
                            (AnimGroups.singleton resolvedKey processedData)
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
                                            { version = newVersion, status = AnimGroup.NotStarted }
                                            acc
                                    )
                                    elementAnimation.properties

                        resetElementAnimation =
                            { elementAnimation
                                | propertySnapshot = startStates
                                , properties = updatedProperties
                                , progress = 0
                            }

                        updatedElementAnimations =
                            AnimGroups.insert resolvedKey resetElementAnimation animGroups

                        updatedAnimState =
                            AnimState
                                { state | subscriptionsActive = True }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeRestartWithVersions
                            elementAnimation.iterations
                            elementAnimation.animationDirection
                            updatedElementAnimations
                            (AnimGroups.singleton resolvedKey processedData)
                    )


resume : String -> AnimState msg -> ( AnimState msg, Cmd msg )
resume animGroup (AnimState state animGroups) =
    ( AnimState state animGroups
    , state.commandPort <|
        encodeCommandWithProperties "resume" animGroup Nothing
    )


{-| Helper to add reset properties to a builder for all animated properties.
-}
addResetProperties : String -> PropertyBaselines -> PropertyBaselines -> AnimBuilder -> AnimBuilder
addResetProperties animGroupName endStates startStates builderState =
    let
        -- Use the actual stored start states to reset each property that was animated
        builderWithTranslate =
            case ( PropertyBaselines.getTranslate endStates, PropertyBaselines.getTranslate startStates ) of
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
            case ( PropertyBaselines.getOpacity endStates, PropertyBaselines.getOpacity startStates ) of
                ( Just _, Just startOpacity ) ->
                    builderWithTranslate
                        |> Opacity.for animGroupName
                        |> Opacity.to startOpacity
                        |> Opacity.build

                _ ->
                    builderWithTranslate

        builderWithScale =
            case ( PropertyBaselines.getScale endStates, PropertyBaselines.getScale startStates ) of
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
            case ( PropertyBaselines.getRotate endStates, PropertyBaselines.getRotate startStates ) of
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
            case ( PropertyBaselines.getBackgroundColor endStates, PropertyBaselines.getBackgroundColor startStates ) of
                ( Just _, Just startColor ) ->
                    builderWithRotate
                        |> BackgroundColor.for animGroupName
                        |> BackgroundColor.to startColor
                        |> BackgroundColor.build

                _ ->
                    builderWithRotate

        builderWithSize =
            case ( PropertyBaselines.getSize endStates, PropertyBaselines.getSize startStates ) of
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
