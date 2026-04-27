module Anim.Internal.Engine.WAAPI exposing
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
    , freezeSkew
    , freezeTranslate
    , getColorPropertyCurrent
    , getColorPropertyEnd
    , getColorPropertyRange
    , getColorPropertyStart
    , getOpacityCurrent
    , getOpacityEnd
    , getOpacityRange
    , getOpacityStart
    , getProgress
    , getPropertyCurrent
    , getPropertyEnd
    , getPropertyRange
    , getPropertyStart
    , getRotateCurrent
    , getRotateEnd
    , getRotateRange
    , getRotateStart
    , getScaleCurrent
    , getScaleEnd
    , getScaleRange
    , getScaleStart
    , getSizeCurrent
    , getSizeEnd
    , getSizeRange
    , getSizeStart
    , getSkewCurrent
    , getSkewEnd
    , getSkewRange
    , getSkewStart
    , getTranslateCurrent
    , getTranslateEnd
    , getTranslateRange
    , getTranslateStart
    , init
    , isComplete
    , isRunning
    , iterations
    , loopForever
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
    )

import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder as Builder exposing (AnimationDirection(..))
import Anim.Internal.Builder.Opacity as Opacity
import Anim.Internal.Builder.Property as Property
import Anim.Internal.Builder.PropertyBaselines as PropertyBaselines exposing (PropertyBaselines)
import Anim.Internal.Builder.Rotate as Rotate
import Anim.Internal.Builder.Scale as Scale
import Anim.Internal.Builder.Size as Size
import Anim.Internal.Builder.Skew as Skew
import Anim.Internal.Builder.Translate as Translate
import Anim.Internal.Engine.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.WAAPI.AnimGroup as AnimGroup exposing (AnimGroup, AnimationStatus, PropertyState)
import Anim.Internal.Engine.WAAPI.Generator as Generator
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Property as CustomProperty
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Skew as Skew
import Anim.Internal.Property.Translate as Translate
import Anim.Internal.PropertyColor as CustomColorProperty
import Dict
import Easing exposing (Easing(..))
import Html
import Html.Attributes
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Shared.Easing as Easing



-- ============================================================
-- MODEL
-- ============================================================


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



-- ============================================================
-- INITIALIZE
-- ============================================================


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



-- ============================================================
-- TRIGGER
-- ============================================================


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
                |> Builder.injectCurrentStates (setSnapshot animGroups)
                |> build

        processed =
            Builder.process builder

        generateAnimGroup : AnimGroupName -> Builder.ProcessedAnimGroupConfig -> AnimGroup
        generateAnimGroup animGroupName config =
            Generator.generateAnimation
                processed.iterations
                processed.animationDirection
                config.transformOrder
                (Builder.getDiscreteEntryProperties builder)
                (Builder.getDiscreteExitProperties builder)
                (AnimGroups.get animGroupName animGroups)
                config.properties

        insertAnimGroup : AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertAnimGroup animGroupName animGroup acc =
            case AnimGroups.get animGroupName acc of
                Nothing ->
                    AnimGroups.insert animGroupName animGroup acc

                Just existing ->
                    AnimGroups.insert animGroupName
                        (AnimGroup.addPropertyStates animGroup existing)
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


setSnapshot : AnimGroups AnimGroup -> AnimGroups { propertySnapshot : PropertyBaselines }
setSnapshot anims =
    AnimGroups.map (\_ anim -> { propertySnapshot = AnimGroup.getPropertySnapshot anim }) anims



-- ============================================================
-- EVENTS
-- ============================================================


type AnimEvent
    = Started AnimGroupName
    | Ended AnimGroupName
    | Cancelled AnimGroupName Float
    | Restarted AnimGroupName
    | Paused AnimGroupName Float
    | Resumed AnimGroupName
    | Iteration AnimGroupName Int
    | Progress AnimGroupName Float
    | AnimError String



-- ============================================================
-- UPDATE
-- ============================================================


type AnimMsg
    = JavascriptUpdate Decode.Value


update : AnimMsg -> AnimState msg -> ( AnimState msg, AnimEvent )
update msg ((AnimState state animGroups) as animState) =
    case msg of
        JavascriptUpdate jsonValue ->
            case Decode.decodeValue (Decode.field "type" Decode.string) jsonValue of
                Ok "animationUpdate" ->
                    case Decode.decodeValue animEventDecoder jsonValue of
                        Ok animEvent ->
                            ( handleLifecycleEvent animEvent animState
                            , animEvent
                            )

                        Err error ->
                            ( animState
                            , AnimError <|
                                "Failed to decode animation event: "
                                    ++ Decode.errorToString error
                            )

                Ok "propertyUpdate" ->
                    case Decode.decodeValue animationUpdateDecoder jsonValue of
                        Ok animUpdate ->
                            let
                                updatedAnimations =
                                    AnimGroups.update animUpdate.animGroupName
                                        (Maybe.map (updateAnimGroup animUpdate))
                                        animGroups

                                -- Update global isRunning based on animation status
                                hasRunningAnimations =
                                    AnimGroups.groups updatedAnimations
                                        |> List.any
                                            (AnimGroup.getPropertyStates
                                                >> AnimGroups.groups
                                                >> List.any (\prop -> prop.status == AnimGroup.Running)
                                            )
                            in
                            ( AnimState { state | subscriptionsActive = hasRunningAnimations } updatedAnimations
                            , Progress animUpdate.animGroupName animUpdate.progress
                            )

                        Err error ->
                            ( animState
                            , AnimError ("Failed to decode animation update: " ++ Decode.errorToString error)
                            )

                Ok unknown ->
                    ( animState
                    , AnimError ("Unknown message type: " ++ unknown)
                    )

                Err error ->
                    ( animState
                    , AnimError ("Unknown message type: " ++ Decode.errorToString error)
                    )


handleLifecycleEvent : AnimEvent -> AnimState msg -> AnimState msg
handleLifecycleEvent animEvent (AnimState state animGroups) =
    let
        animGroupName =
            animEventGroupName animEvent

        newStatus =
            animEventToStatus animEvent

        updatedAnimGroups =
            AnimGroups.update animGroupName
                (Maybe.map
                    (AnimGroup.setStatus newStatus
                        >> AnimGroup.setProgress
                            (case animEvent of
                                Paused _ progress ->
                                    progress

                                Cancelled _ progress ->
                                    progress

                                Progress _ progress ->
                                    progress

                                _ ->
                                    0
                            )
                    )
                )
                animGroups
    in
    AnimState
        { state
            | subscriptionsActive =
                AnimGroups.groups updatedAnimGroups
                    |> List.any AnimGroup.isRunning
        }
        updatedAnimGroups


updateAnimGroup : AnimationUpdate -> AnimGroup -> AnimGroup
updateAnimGroup animUpdate animGroup =
    let
        buildProp : (AnimationUpdate -> Maybe a) -> (b -> PropertyBaselines -> PropertyBaselines) -> (a -> b) -> PropertyBaselines -> PropertyBaselines
        buildProp propFn setterFn converterFn b =
            case propFn animUpdate of
                Just val ->
                    setterFn (converterFn val) b

                Nothing ->
                    b

        updateStatus : String -> PropertyState -> PropertyState
        updateStatus propType propAnim =
            case AnimGroups.get propType animUpdate.propertyVersions of
                Nothing ->
                    propAnim

                Just currentVersion ->
                    if currentVersion == propAnim.version then
                        { propAnim
                            | status =
                                if animUpdate.isAnimating then
                                    AnimGroup.Running

                                else
                                    AnimGroup.Complete
                        }

                    else
                        propAnim
    in
    animGroup
        |> AnimGroup.setProgress animUpdate.progress
        |> AnimGroup.setPropertyStates (AnimGroups.map updateStatus (AnimGroup.getPropertyStates animGroup))
        |> AnimGroup.setSnapshot
            (animGroup
                |> AnimGroup.getPropertySnapshot
                |> buildProp .opacity PropertyBaselines.setOpacity Opacity.fromFloat
                |> buildProp .rotate PropertyBaselines.setRotate Rotate.fromRecord
                |> buildProp .scale PropertyBaselines.setScale Scale.fromRecord
                |> buildProp .size PropertyBaselines.setSize Size.fromRecord
                |> buildProp .translate PropertyBaselines.setTranslate Translate.fromRecord
                |> PropertyBaselines.updateCustomProperties animUpdate.customProperties
                |> PropertyBaselines.updateCustomColorProperties animUpdate.customColorProperties
            )


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
            AnimError ("Unknown status: " ++ invalid)


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

        AnimError _ ->
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

        AnimError _ ->
            -- TODO: Consider if we want a separate status for errors
            AnimGroup.Running



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


subscriptions : (AnimMsg -> msg) -> AnimState msg -> Sub msg
subscriptions toMsg (AnimState state _) =
    state.subscriptionPort <|
        (toMsg << JavascriptUpdate)



-- ============================================================
-- VIEW
-- ============================================================


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
    in
    case AnimGroups.get animGroupName data of
        Nothing ->
            [ dataAttr ]

        Just animGroup ->
            let
                snapshot =
                    AnimGroup.getPropertySnapshot animGroup

                simpleStyles =
                    List.filterMap identity
                        [ PropertyBaselines.getOpacity snapshot
                            |> Maybe.map (\o -> Html.Attributes.style "opacity" (Opacity.toString o))
                        ]

                sizeStyles =
                    PropertyBaselines.getSize snapshot
                        |> Maybe.map
                            (\s ->
                                [ Html.Attributes.style "width" (Size.widthToCssString s)
                                , Html.Attributes.style "height" (Size.heightToCssString s)
                                ]
                            )
                        |> Maybe.withDefault []

                customPropertyStyles =
                    PropertyBaselines.getAllCustomProperties snapshot
                        |> List.map (\( name, cssValue ) -> Html.Attributes.style name cssValue)

                customColorPropertyStyles =
                    PropertyBaselines.getAllCustomColorProperties snapshot
                        |> List.map (\( name, color ) -> Html.Attributes.style name (Color.toCssString color))
            in
            dataAttr
                :: buildTransformStyles (AnimGroup.getTransformOrder animGroup) snapshot
                ++ simpleStyles
                ++ sizeStyles
                ++ customPropertyStyles
                ++ customColorPropertyStyles
                ++ discreteEntryStyles animGroup
                ++ discreteExitStyles animGroup


buildTransformStyles : List TransformProperty -> PropertyBaselines -> List (Html.Attribute msg)
buildTransformStyles order snapshot =
    let
        translatePart =
            PropertyBaselines.getTranslate snapshot
                |> Maybe.map Translate.toCssString
                |> Maybe.withDefault ""

        rotatePart =
            PropertyBaselines.getRotate snapshot
                |> Maybe.map Rotate.toCssString
                |> Maybe.withDefault ""

        scalePart =
            PropertyBaselines.getScale snapshot
                |> Maybe.map Scale.toCssString
                |> Maybe.withDefault ""

        skewPart =
            PropertyBaselines.getSkew snapshot
                |> Maybe.map Skew.toCssString
                |> Maybe.withDefault ""

        transformString =
            order
                |> List.map (transformOrderToPart translatePart rotatePart skewPart scalePart)
                |> List.filter (not << String.isEmpty)
                |> String.join " "
    in
    if String.isEmpty transformString then
        []

    else
        [ Html.Attributes.style "transform" transformString ]


{-| Convert a TransformProperty to its corresponding CSS string part.
-}
transformOrderToPart : String -> String -> String -> String -> TransformProperty -> String
transformOrderToPart translatePart rotatePart skewPart scalePart order =
    case order of
        TransformProperty.Translate ->
            translatePart

        TransformProperty.Rotate ->
            rotatePart

        TransformProperty.Skew ->
            skewPart

        TransformProperty.Scale ->
            scalePart


discreteEntryStyles : AnimGroup -> List (Html.Attribute msg)
discreteEntryStyles =
    AnimGroup.getDiscreteEntry
        >> Dict.toList
        >> List.map (\( prop, value ) -> Html.Attributes.style prop value)


discreteExitStyles : AnimGroup -> List (Html.Attribute msg)
discreteExitStyles animGroup =
    animGroup
        |> AnimGroup.getDiscreteExit
        |> Dict.toList
        |> List.map
            (\( prop, { from, to } ) ->
                if AnimGroup.isComplete animGroup then
                    Html.Attributes.style prop to

                else
                    Html.Attributes.style prop from
            )



-- ============================================================
-- PLAYBACK SETTINGS
-- ============================================================


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


iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    Builder.iterations


loopForever : AnimBuilder -> AnimBuilder
loopForever =
    Builder.loopForever


alternate : AnimBuilder -> AnimBuilder
alternate =
    Builder.alternate



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


stop : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
stop animGroupName (AnimState state animGroups) =
    let
        endStates =
            Builder.getCurrentAnimationConfig animGroupName state.builder
                |> Maybe.map (.properties >> Generator.propertyBounds >> .end)
                |> Maybe.withDefault PropertyBaselines.empty

        updatedElementAnimations =
            AnimGroups.update animGroupName
                (Maybe.map
                    (\anim ->
                        AnimGroup.setSnapshot
                            (PropertyBaselines.merge
                                (AnimGroup.getPropertySnapshot anim)
                                endStates
                            )
                            anim
                    )
                )
                animGroups
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


reset : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
reset animGroupName animState =
    resetSingleKey animGroupName animState


resetSingleKey : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
resetSingleKey animGroupName (AnimState state animGroups) =
    case Builder.getCurrentAnimationConfig animGroupName state.builder of
        Nothing ->
            ( AnimState state animGroups, Cmd.none )

        Just { properties } ->
            let
                -- Extract start and end states from the animation history
                states =
                    Generator.propertyBounds properties

                startStates =
                    states.start

                -- Get properties that were in the original animation
                animatedPropertyTypes =
                    List.map Generator.propertyTypeString properties

                resetBuilder =
                    Builder.init []
                        |> Builder.duration 0
                        |> Builder.easing Linear
                        |> Builder.for animGroupName
                        |> resetProperties animGroupName properties startStates

                processedData =
                    Builder.process resetBuilder
            in
            case AnimGroups.get animGroupName animGroups of
                Nothing ->
                    -- No tracking entry, create one with property versions
                    let
                        newProperties =
                            animatedPropertyTypes
                                |> List.map (\propType -> ( propType, { version = 1, status = AnimGroup.NotStarted } ))
                                |> AnimGroups.fromList

                        newAnimGroup =
                            AnimGroup.init
                                |> AnimGroup.setSnapshot startStates
                                |> AnimGroup.setPropertyStates newProperties

                        updatedElementAnimations =
                            AnimGroups.insert animGroupName newAnimGroup animGroups

                        updatedAnimState =
                            AnimState
                                { state | subscriptionsActive = False }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeWithVersions updatedElementAnimations processedData
                    )

                Just animGroup ->
                    -- Existing tracking entry, increment versions for reset properties
                    let
                        updatedPropertyStates =
                            animGroup
                                |> AnimGroup.bumpPropertyVersions animatedPropertyTypes
                                |> AnimGroup.getPropertyStates

                        resetAnimGroup =
                            animGroup
                                |> AnimGroup.setSnapshot startStates
                                |> AnimGroup.setPropertyStates updatedPropertyStates
                                |> AnimGroup.setProgress 0

                        updatedAnimGroup =
                            AnimGroups.insert animGroupName resetAnimGroup animGroups
                    in
                    ( AnimState
                        { state
                            | subscriptionsActive =
                                AnimGroups.groups updatedAnimGroup
                                    |> List.any AnimGroup.isRunning
                        }
                        updatedAnimGroup
                    , state.commandPort <|
                        encodeWithVersions updatedAnimGroup processedData
                    )


restart : String -> AnimState msg -> ( AnimState msg, Cmd msg )
restart animGroup animState =
    restartSingleKey animGroup animState


restartSingleKey : String -> AnimState msg -> ( AnimState msg, Cmd msg )
restartSingleKey resolvedKey (AnimState state animGroups) =
    case Builder.getCurrentAnimationConfig resolvedKey state.builder of
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

                        newAnimGroup =
                            AnimGroup.init
                                |> AnimGroup.setSnapshot startStates
                                |> AnimGroup.setPropertyStates newProperties

                        updatedElementAnimations =
                            AnimGroups.insert resolvedKey newAnimGroup animGroups

                        updatedAnimState =
                            AnimState
                                { state | subscriptionsActive = True }
                                updatedElementAnimations
                    in
                    ( updatedAnimState
                    , state.commandPort <|
                        encodeRestartWithVersions
                            (AnimGroup.getIterations newAnimGroup)
                            (AnimGroup.getAnimationDirection newAnimGroup)
                            updatedElementAnimations
                            (AnimGroups.singleton resolvedKey processedData)
                    )

                Just animGroup ->
                    -- Update existing entry, incrementing versions for restarted properties
                    let
                        updatedProperties =
                            restartedPropertyTypes
                                |> List.foldl
                                    (\propType acc ->
                                        let
                                            newVersion =
                                                animGroup
                                                    |> AnimGroup.getPropertyStates
                                                    |> AnimGroups.get propType
                                                    |> Maybe.map .version
                                                    |> Maybe.map ((+) 1)
                                                    |> Maybe.withDefault 1
                                        in
                                        AnimGroups.insert propType
                                            { version = newVersion, status = AnimGroup.NotStarted }
                                            acc
                                    )
                                    (AnimGroup.getPropertyStates animGroup)

                        resetElementAnimation =
                            animGroup
                                |> AnimGroup.setSnapshot startStates
                                |> AnimGroup.setPropertyStates updatedProperties
                                |> AnimGroup.setProgress 0

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
                            (AnimGroup.getIterations animGroup)
                            (AnimGroup.getAnimationDirection animGroup)
                            updatedElementAnimations
                            (AnimGroups.singleton resolvedKey processedData)
                    )


resume : String -> AnimState msg -> ( AnimState msg, Cmd msg )
resume animGroup (AnimState state animGroups) =
    ( AnimState state animGroups
    , state.commandPort <|
        encodeCommandWithProperties "resume" animGroup Nothing
    )


resetProperties : String -> List Builder.ProcessedPropertyConfig -> PropertyBaselines -> AnimBuilder -> AnimBuilder
resetProperties animGroupName properties startStates =
    let
        -- Use the actual stored start states to reset each property that was animated
        buildFromStartState : (PropertyBaselines -> Maybe a) -> (a -> AnimBuilder -> AnimBuilder) -> AnimBuilder -> AnimBuilder
        buildFromStartState accessor builderFn animBuilder =
            case accessor startStates of
                Just start ->
                    builderFn start animBuilder

                Nothing ->
                    animBuilder

        opacityBuilder start =
            Opacity.for animGroupName
                >> Opacity.to start
                >> Opacity.build

        rotateBuilder start =
            Rotate.for animGroupName
                >> Rotate.to start
                >> Rotate.build

        scaleBuilder start =
            Scale.for animGroupName
                >> Scale.to start
                >> Scale.build

        sizeBuilder start =
            Size.for animGroupName
                >> Size.to start
                >> Size.build

        translateBuilder start =
            Translate.for animGroupName
                >> Translate.to start
                >> Translate.build

        buildCustomFromStartState : Builder.ProcessedPropertyConfig -> (AnimBuilder -> AnimBuilder)
        buildCustomFromStartState propertyConfig =
            case propertyConfig of
                Builder.ProcessedCustomPropertyConfig cssName unit _ ->
                    case PropertyBaselines.getCustomProperty cssName startStates of
                        Just start ->
                            CustomProperty.for animGroupName cssName unit
                                >> CustomProperty.to start
                                >> CustomProperty.build

                        Nothing ->
                            identity

                Builder.ProcessedCustomColorPropertyConfig cssName _ ->
                    case PropertyBaselines.getCustomColorProperty cssName startStates of
                        Just start ->
                            CustomColorProperty.for animGroupName cssName
                                >> CustomColorProperty.to start
                                >> CustomColorProperty.build

                        Nothing ->
                            identity

                _ ->
                    identity
    in
    buildFromStartState PropertyBaselines.getOpacity opacityBuilder
        >> buildFromStartState PropertyBaselines.getRotate rotateBuilder
        >> buildFromStartState PropertyBaselines.getScale scaleBuilder
        >> buildFromStartState PropertyBaselines.getSize sizeBuilder
        >> buildFromStartState PropertyBaselines.getTranslate translateBuilder
        >> List.foldl (>>) identity (List.map buildCustomFromStartState properties)



-- ============================================================
-- TRANSFORM ORDER
-- ============================================================


transformOrder : List TransformProperty -> AnimBuilder -> AnimBuilder
transformOrder =
    Builder.transformOrder



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


discreteEntry : String -> String -> AnimBuilder -> AnimBuilder
discreteEntry =
    Builder.discreteEntry


discreteExit : String -> String -> String -> AnimBuilder -> AnimBuilder
discreteExit =
    Builder.discreteExit



-- ============================================================
-- FREEZE / UNFREEZE PROPERTIES
-- ============================================================


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


freezeSkew : FreezeProperty
freezeSkew =
    Builder.FreexeSkew



-- ============================================================
-- FREEZE
-- ============================================================


freezeAxes : List String -> List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeAxes =
    Builder.freezeAxes



-- ============================================================
-- UNFREEZE
-- ============================================================


unfreezeAxes : List String -> List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeAxes =
    Builder.unfreezeAxes



-- ============================================================
-- STATUS QUERIES
-- ============================================================


allComplete : AnimState msg -> Maybe Bool
allComplete (AnimState _ animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        AnimGroups.groups animGroups
            |> List.all AnimGroup.isComplete
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
        |> Maybe.map AnimGroup.isComplete


getProgress : AnimGroupName -> AnimState msg -> Maybe Float
getProgress animGroupName (AnimState _ data) =
    AnimGroups.get animGroupName data
        |> Maybe.map AnimGroup.getProgress


isRunning : AnimGroupName -> AnimState msg -> Maybe Bool
isRunning animGroupName (AnimState _ data) =
    AnimGroups.get animGroupName data
        |> Maybe.map AnimGroup.isRunning



-- ============================================================
-- PROPERTY QUERIES
-- ============================================================


getBuilder : AnimState msg -> Builder.AnimBuilder
getBuilder (AnimState state _) =
    state.builder



-- ============================
-- CUSTOM PROPERTY
-- ============================


getPropertyStart : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyStart animGroupName cssName =
    getBuilder >> Property.getPropertyStart animGroupName cssName


getPropertyEnd : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyEnd animGroupName cssName =
    getBuilder >> Property.getPropertyEnd animGroupName cssName


getPropertyCurrent : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyCurrent animGroupName cssName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getCustomProperty cssName)


getPropertyRange : AnimGroupName -> String -> AnimState msg -> Maybe { start : Maybe Float, end : Float }
getPropertyRange animGroupName cssName =
    getBuilder >> Property.getPropertyRange animGroupName cssName



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


getColorPropertyStart : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyStart animGroupName cssName =
    getBuilder >> Property.getColorPropertyStart animGroupName cssName


getColorPropertyEnd : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyEnd animGroupName cssName =
    getBuilder >> Property.getColorPropertyEnd animGroupName cssName


getColorPropertyCurrent : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyCurrent animGroupName cssName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getCustomColorProperty cssName)


getColorPropertyRange : AnimGroupName -> String -> AnimState msg -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange animGroupName cssName =
    getBuilder >> Property.getColorPropertyRange animGroupName cssName



-- ============================
-- OPACITY
-- ============================


getOpacityStart : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityStart animGroupName =
    getBuilder >> Property.getOpacityStart animGroupName


getOpacityEnd : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityEnd animGroupName =
    getBuilder >> Property.getOpacityEnd animGroupName


getOpacityCurrent : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getOpacity)
        |> Maybe.map Opacity.toFloat


getOpacityRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Float, end : Float }
getOpacityRange animGroupName =
    getBuilder >> Property.getOpacityRange animGroupName



-- ============================
-- ROTATE
-- ============================


getRotateStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateStart animGroupName =
    getBuilder >> Property.getRotateStart animGroupName


getRotateEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd animGroupName =
    getBuilder >> Property.getRotateEnd animGroupName


getRotateCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getRotate)
        |> Maybe.map Rotate.toRecord


getRotateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange animGroupName =
    getBuilder >> Property.getRotateRange animGroupName



-- ============================
-- SCALE
-- ============================


getScaleStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleStart animGroupName =
    getBuilder >> Property.getScaleStart animGroupName


getScaleEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd animGroupName =
    getBuilder >> Property.getScaleEnd animGroupName


getScaleCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getScale)
        |> Maybe.map Scale.toRecord


getScaleRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange animGroupName =
    getBuilder >> Property.getScaleRange animGroupName



-- ============================
-- SIZE
-- ============================


getSizeStart : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeStart animGroupName =
    getBuilder >> Property.getSizeStart animGroupName


getSizeEnd : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeEnd animGroupName =
    getBuilder >> Property.getSizeEnd animGroupName


getSizeCurrent : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getSize)
        |> Maybe.map Size.toRecord


getSizeRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange animGroupName =
    getBuilder >> Property.getSizeRange animGroupName



-- ============================
-- SKEW
-- ============================


getSkewStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewStart animGroupName =
    getBuilder >> Property.getSkewStart animGroupName


getSkewEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewEnd animGroupName =
    getBuilder >> Property.getSkewEnd animGroupName


getSkewCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getSkew)
        |> Maybe.map Skew.toRecord


getSkewRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange animGroupName =
    getBuilder >> Property.getSkewRange animGroupName



-- ============================
-- TRANSLATE
-- ============================


getTranslateStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart animGroupName =
    getBuilder >> Property.getTranslateStart animGroupName


getTranslateEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd animGroupName =
    getBuilder >> Property.getTranslateEnd animGroupName


getTranslateCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (AnimGroup.getPropertySnapshot >> PropertyBaselines.getTranslate)
        |> Maybe.map Translate.toRecord


getTranslateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange animGroupName =
    getBuilder >> Property.getTranslateRange animGroupName



-- ============================
-- DECODERS
-- ============================


type alias AnimationUpdate =
    { animGroupName : String
    , progress : Float
    , translate : Maybe { x : Float, y : Float, z : Float }
    , opacity : Maybe Float
    , rotate : Maybe { x : Float, y : Float, z : Float }
    , scale : Maybe { x : Float, y : Float, z : Float }
    , size : Maybe { width : Float, height : Float }
    , customProperties : Dict.Dict String Float
    , customColorProperties : Dict.Dict String String
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
        |> andMap (Decode.maybe (Decode.field "size" (Decode.map2 (\w h -> { width = w, height = h }) (Decode.field "width" Decode.float) (Decode.field "height" Decode.float))))
        |> andMap (Decode.oneOf [ Decode.field "customProperties" (Decode.dict Decode.float), Decode.succeed Dict.empty ])
        |> andMap (Decode.oneOf [ Decode.field "customColorProperties" (Decode.dict Decode.string), Decode.succeed Dict.empty ])
        |> andMap (Decode.field "isAnimating" Decode.bool)
        |> andMap propertyVersionDecoder


propertyVersionDecoder : Decoder (AnimGroups Int)
propertyVersionDecoder =
    Decode.field "propertyVersions" (Decode.dict Decode.int)
        |> Decode.map AnimGroups.fromDict


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)



-- ============================
-- ENCODERS
-- ============================


encodeWithVersions : AnimGroups AnimGroup -> Builder.ProcessedAnimationData -> Encode.Value
encodeWithVersions animGroups processed =
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


encodeRestartWithVersions : Builder.Iterations -> Builder.AnimationDirection -> AnimGroups AnimGroup -> AnimGroups Builder.ProcessedAnimGroupConfig -> Encode.Value
encodeRestartWithVersions iterationsConfig directionConfig animGroup configGroup =
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


encode : Builder.ProcessedAnimationData -> Encode.Value
encode data =
    let
        processedProperties =
            data.groups
                |> AnimGroups.toList
                |> List.map
                    (\( animGroupName, config ) ->
                        ( animGroupName
                        , encodeProcessedAnimGroupConfig
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
    -> Maybe (AnimGroups PropertyState)
    -> Maybe (List TransformProperty)
    -> List Builder.ProcessedPropertyConfig
    -> Encode.Value
encodeProcessedAnimGroupConfig animGroupName propertyState transformOrder_ propertyConfigs =
    let
        baseFields =
            [ ( "properties", Encode.list (encodeProcessedPropertyConfig propertyState) propertyConfigs )
            , ( "animGroup", Encode.string animGroupName )
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
