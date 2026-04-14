module Anim.Internal.Engine.Animation.Sub exposing
    ( AnimEvent(..)
    , AnimMsg
    , AnimState
    , ControlEvent(..)
    , TickEvent(..)
    , allComplete
    , animate
    , anyRunning
    , attributes
    , getBackgroundColor
    , getBackgroundColorRange
    , getFontColor
    , getFontColorRange
    , getOpacity
    , getOpacityRange
    , getProgress
    , getRotate
    , getRotateRange
    , getScale
    , getScaleRange
    , getSize
    , getSizeRange
    , getTranslate
    , getTranslateRange
    , init
    , isComplete
    , isRunning
    , pause
    , reset
    , restart
    , resume
    , stop
    , subscriptions
    , update
    )

import Anim.Extra.Easing exposing (Easing(..))
import Anim.Extra.TransformOrder as TransformProperty exposing (TransformProperty)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Animation.Sub.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Animation.Sub.Animation as Animation exposing (Animation(..), PropertyAnimation)
import Anim.Internal.Engine.Animation.Sub.Animations as Animations
import Anim.Internal.Engine.Animation.Sub.Generator as Generator
import Anim.Internal.Extra.Color as Color exposing (Color(..))
import Anim.Internal.Property.Opacity as Opacity exposing (Opacity)
import Anim.Internal.Property.Rotate as Rotate exposing (Rotate)
import Anim.Internal.Property.Scale as Scale exposing (Scale)
import Anim.Internal.Property.Size as Size exposing (Size)
import Anim.Internal.Property.Translate as Translate exposing (Translate)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))
import Browser.Events
import Dict
import Html
import Html.Attributes



{- ***** MODEL ***** -}


type AnimState
    = AnimState
        { builder : AnimBuilder
        , subscriptionsActive : Bool
        , pendingControlEvents : List ControlEvent
        }
        (AnimGroups AnimGroup)


type alias AnimGroupName =
    String


init : List (AnimBuilder -> AnimBuilder) -> AnimState
init propertyInitializers =
    case propertyInitializers of
        [] ->
            AnimState
                { builder = Builder.init []
                , subscriptionsActive = False
                , pendingControlEvents = []
                }
                AnimGroups.init

        _ ->
            let
                builder =
                    Builder.init propertyInitializers

                animGroups =
                    Builder.getAnimGroups builder

                initGroup : AnimGroupName -> { a | properties : List Builder.PropertyConfig } -> AnimGroup
                initGroup _ { properties } =
                    Generator.init
                        (Builder.getDiscreteEntryProperties builder)
                        (Builder.getDiscreteExitProperties builder)
                        properties
            in
            AnimState
                { builder =
                    builder
                        |> Builder.mergeEndStates
                        |> Builder.clearAnimData
                , subscriptionsActive = False
                , pendingControlEvents = []
                }
                (AnimGroups.map initGroup animGroups)



{- ***** TRIGGER ***** -}


animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate (AnimState state animGroups) transform =
    let
        builder =
            state.builder
                |> Builder.injectCurrentStates (extractCurrentStates animGroups)
                |> transform

        processedAnimData =
            Builder.process builder

        generateAnimGroup : AnimGroupName -> { a | properties : List Builder.ProcessedPropertyConfig } -> AnimGroup
        generateAnimGroup _ { properties } =
            Generator.generateAnimation
                processedAnimData.iterationCount
                (Maybe.withDefault TransformProperty.default processedAnimData.globalTransformOrder)
                (Builder.getDiscreteEntryProperties builder)
                (Builder.getDiscreteExitProperties builder)
                properties

        insertAnimGroup : AnimGroupName -> AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup
        insertAnimGroup animGroupName animGroup acc =
            case AnimGroups.get animGroupName acc of
                Nothing ->
                    AnimGroups.insert animGroupName animGroup acc

                Just existing ->
                    AnimGroups.insert animGroupName
                        (AnimGroup.addAnimation (AnimGroup.getAnimations existing) animGroup)
                        acc

        startedEvents =
            AnimGroups.names processedAnimData.groups
                |> List.map Started
    in
    AnimState
        { subscriptionsActive = True
        , builder =
            builder
                |> Builder.mergeEndStates
                |> Builder.clearAnimData
        , pendingControlEvents = state.pendingControlEvents ++ startedEvents
        }
        (processedAnimData.groups
            |> AnimGroups.map generateAnimGroup
            |> AnimGroups.foldl insertAnimGroup animGroups
        )


extractCurrentStates : AnimGroups AnimGroup -> AnimGroups { propertySnapshot : Builder.PropertyEndStates }
extractCurrentStates anims =
    AnimGroups.map (\_ anim -> { propertySnapshot = extractElementCurrentStates anim }) anims


extractElementCurrentStates : AnimGroup -> Builder.PropertyEndStates
extractElementCurrentStates animGroup =
    Animations.foldl (\_ -> extractPropertyCurrentState)
        { translate = Nothing
        , rotate = Nothing
        , scale = Nothing
        , backgroundColor = Nothing
        , fontColor = Nothing
        , opacity = Nothing
        , size = Nothing
        }
        animGroup.animations


extractPropertyCurrentState : Animation -> Builder.PropertyEndStates -> Builder.PropertyEndStates
extractPropertyCurrentState anim states =
    case anim of
        Translate a ->
            { states | translate = Just (computeCurrentValue interpolateTranslate a) }

        Rotate a ->
            { states | rotate = Just (computeCurrentValue interpolateRotate a) }

        Scale a ->
            { states | scale = Just (computeCurrentValue interpolateScale a) }

        BackgroundColor a ->
            { states | backgroundColor = Just (computeCurrentValue Color.interpolate a) }

        FontColor a ->
            { states | fontColor = Just (computeCurrentValue Color.interpolate a) }

        Opacity a ->
            { states | opacity = Just (computeCurrentValue interpolateOpacity a) }

        Size a ->
            { states | size = Just (computeCurrentValue interpolateSize a) }



{- ***** UPDATE ***** -}


type AnimMsg
    = AnimationFrame Float


update : AnimMsg -> AnimState -> ( AnimState, List AnimEvent )
update msg (AnimState state animGroups) =
    case msg of
        AnimationFrame deltaMs ->
            let
                ( groups, events ) =
                    AnimGroups.toList animGroups
                        |> List.map
                            (\( animGroupName, animGroup ) ->
                                let
                                    ( newAnim, newEvents ) =
                                        handleTick deltaMs animGroupName animGroup
                                in
                                ( ( animGroupName, newAnim ), newEvents )
                            )
                        |> List.unzip

                updatedGroups =
                    AnimGroups.fromList groups

                allEvents =
                    List.concat events

                stillRunning =
                    AnimGroups.groups updatedGroups
                        |> List.any (not << .isComplete)
            in
            ( AnimState
                { subscriptionsActive = stillRunning
                , builder = state.builder
                , pendingControlEvents = []
                }
                updatedGroups
            , List.map Control state.pendingControlEvents
                ++ List.map Tick allEvents
            )


handleTick : Float -> AnimGroupName -> AnimGroup -> ( AnimGroup, List TickEvent )
handleTick deltaMs animGroupName animGroup =
    if animGroup.isPaused then
        ( animGroup, [] )

    else
        let
            updatedAnimations =
                Animations.map (\_ -> updateAnimatedProperty deltaMs) animGroup.animations

            allPropertiesComplete =
                Animations.list updatedAnimations
                    |> List.all (Animation.foldTiming .isComplete)
        in
        if allPropertiesComplete && not animGroup.isComplete then
            -- Properties just finished - check if we need to iterate
            let
                shouldIterate =
                    case animGroup.iterationCount of
                        Builder.Infinite ->
                            True

                        Builder.Times totalIterations ->
                            animGroup.currentIteration < totalIterations

                        Builder.Once ->
                            False
            in
            if shouldIterate then
                iterateAnimGroup animGroupName animGroup updatedAnimations

            else
                ( { animGroup | animations = updatedAnimations, isComplete = True }
                , [ Ended animGroupName ]
                )

        else
            let
                updatedAnimGroup =
                    { animGroup | animations = updatedAnimations }
            in
            -- Not all properties complete yet (or already complete)
            ( updatedAnimGroup
            , if updatedAnimGroup.isComplete then
                []

              else
                [ Progress animGroupName (overallProgress updatedAnimGroup) ]
            )


updateAnimatedProperty : Float -> Animation -> Animation
updateAnimatedProperty deltaMs =
    Animation.mapTiming
        (\timing ->
            if timing.isComplete then
                timing

            else
                let
                    newElapsedMs =
                        timing.elapsedMs + deltaMs

                    animationElapsedMs =
                        max 0 (newElapsedMs - timing.delayMs)
                in
                { timing
                    | elapsedMs = newElapsedMs
                    , isComplete = animationElapsedMs >= timing.totalDurationMs
                }
        )


iterateAnimGroup : AnimGroupName -> AnimGroup -> Animations.Animations -> ( AnimGroup, List TickEvent )
iterateAnimGroup animGroupName animGroup updatedAnimations =
    let
        nextIteration =
            animGroup.currentIteration + 1

        resetProperties =
            Animations.map resetAnimation updatedAnimations
    in
    ( { animGroup
        | animations = resetProperties
        , currentIteration = nextIteration
        , isComplete = False
      }
    , [ Iteration animGroupName nextIteration ]
    )



{- ***** SUBSCRIPTIONS ***** -}


subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions toMsg (AnimState state _) =
    if state.subscriptionsActive then
        Browser.Events.onAnimationFrameDelta AnimationFrame
            |> Sub.map toMsg

    else
        Sub.none



{- ***** EVENTS ***** -}


type alias Progress =
    Float


{-| Events generated naturally by animation frame ticks.
-}
type TickEvent
    = Progress AnimGroupName Progress
    | Ended AnimGroupName
    | Iteration AnimGroupName Int


{-| Events generated by control function calls (animate, stop, pause, etc.).
-}
type ControlEvent
    = Started AnimGroupName
    | Cancelled AnimGroupName Progress
    | Paused AnimGroupName Progress
    | Resumed AnimGroupName
    | Restarted AnimGroupName


type AnimEvent
    = Tick TickEvent
    | Control ControlEvent



{- ***** VIEW ***** -}


attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes animGroupName (AnimState _ animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            []

        Just animGroup ->
            let
                anims =
                    Animations.list animGroup.animations

                transformParts =
                    List.foldl collectCurrentTransform Builder.emptyTransformParts anims

                transformString =
                    animGroup.transformOrder
                        |> List.map (transformOrderToPart transformParts)
                        |> List.filter (not << String.isEmpty)
                        |> String.join " "

                transformStyle =
                    if String.isEmpty transformString then
                        []

                    else
                        [ Html.Attributes.style "transform" transformString ]

                nonTransformStyles =
                    List.concatMap getNonTransformStyleAttribute anims

                discreteStyles =
                    discreteEntryStyles animGroup
                        ++ discreteExitStyles animGroup
            in
            transformStyle ++ nonTransformStyles ++ discreteStyles


collectCurrentTransform : Animation -> Builder.TransformParts -> Builder.TransformParts
collectCurrentTransform anim acc =
    case anim of
        Translate a ->
            { acc | translate = Translate.toCssString (computeCurrentValue interpolateTranslate a) }

        Rotate a ->
            { acc | rotate = Rotate.toCssString (computeCurrentValue interpolateRotate a) }

        Scale a ->
            { acc | scale = Scale.toCssString (computeCurrentValue interpolateScale a) }

        _ ->
            acc


transformOrderToPart : Builder.TransformParts -> TransformProperty -> String
transformOrderToPart parts property =
    case property of
        TransformProperty.Translate ->
            parts.translate

        TransformProperty.Rotate ->
            parts.rotate

        TransformProperty.Scale ->
            parts.scale


discreteEntryStyles : AnimGroup -> List (Html.Attribute msg)
discreteEntryStyles animGroup =
    Dict.toList animGroup.discreteEntry
        |> List.map (\( prop, value ) -> Html.Attributes.style prop value)


discreteExitStyles : AnimGroup -> List (Html.Attribute msg)
discreteExitStyles animGroup =
    Dict.toList animGroup.discreteExit
        |> List.map
            (\( prop, { from, to } ) ->
                if animGroup.isComplete then
                    Html.Attributes.style prop to

                else
                    Html.Attributes.style prop from
            )


getNonTransformStyleAttribute : Animation -> List (Html.Attribute msg)
getNonTransformStyleAttribute anim =
    case anim of
        Translate _ ->
            []

        Rotate _ ->
            []

        Scale _ ->
            []

        BackgroundColor a ->
            [ Html.Attributes.style "background-color" (Color.toCssString (computeCurrentValue Color.interpolate a)) ]

        FontColor a ->
            [ Html.Attributes.style "color" (Color.toCssString (computeCurrentValue Color.interpolate a)) ]

        Opacity a ->
            [ Html.Attributes.style "opacity" (String.fromFloat (Opacity.toFloat (computeCurrentValue interpolateOpacity a))) ]

        Size a ->
            let
                size =
                    computeCurrentValue interpolateSize a

                ( width, height ) =
                    Size.toTuple size
            in
            [ Html.Attributes.style "width" (String.fromFloat width ++ "px")
            , Html.Attributes.style "height" (String.fromFloat height ++ "px")
            ]



{- ***** CONTROL ***** -}


stop : AnimGroupName -> AnimState -> AnimState
stop animGroupName =
    let
        stopAnimation : String -> Animation -> Animation
        stopAnimation _ =
            Animation.mapTiming
                (\timing ->
                    { timing
                        | elapsedMs = timing.totalDurationMs + timing.delayMs
                        , isComplete = True
                    }
                )
    in
    controlWithCancel animGroupName
        (\animGroup animGroups ->
            AnimGroups.insert animGroupName
                { animGroup
                    | animations = Animations.map stopAnimation animGroup.animations
                    , isComplete = True
                    , isPaused = False
                }
                animGroups
        )
        Cancelled


reset : AnimGroupName -> AnimState -> AnimState
reset animGroupName =
    controlWithCancel animGroupName
        (\animGroup animGroups ->
            AnimGroups.insert animGroupName
                { animGroup
                    | animations = Animations.map resetAnimation animGroup.animations
                    , isComplete = False
                    , isPaused = False
                }
                animGroups
        )
        Cancelled


restart : AnimGroupName -> AnimState -> AnimState
restart animGroupName (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            let
                updatedAnimGroup =
                    { animGroup
                        | animations = Animations.map resetAnimation animGroup.animations
                        , isComplete = False
                        , isPaused = False
                    }
            in
            AnimState
                { state
                    | subscriptionsActive = True
                    , pendingControlEvents = state.pendingControlEvents ++ [ Restarted animGroupName ]
                }
                (AnimGroups.insert animGroupName updatedAnimGroup animGroups)


resetAnimation : String -> Animation -> Animation
resetAnimation _ =
    Animation.mapTiming
        (\timing -> { timing | elapsedMs = 0, isComplete = False })


pause : AnimGroupName -> AnimState -> AnimState
pause animGroupName =
    controlWithCancel animGroupName
        (\_ animGroups ->
            AnimGroups.update animGroupName
                (Maybe.map (\anim -> { anim | isPaused = True }))
                animGroups
        )
        Paused


resume : AnimGroupName -> AnimState -> AnimState
resume animGroupName (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just elementAnim ->
            let
                wasPaused =
                    elementAnim.isPaused && not elementAnim.isComplete

                newPendingControlEvents =
                    if wasPaused then
                        state.pendingControlEvents ++ [ Resumed animGroupName ]

                    else
                        state.pendingControlEvents
            in
            AnimState
                { state
                    | subscriptionsActive = True
                    , pendingControlEvents = newPendingControlEvents
                }
                (AnimGroups.update animGroupName
                    (Maybe.map (\anim -> { anim | isPaused = False }))
                    animGroups
                )


controlWithCancel :
    AnimGroupName
    -> (AnimGroup -> AnimGroups AnimGroup -> AnimGroups AnimGroup)
    -> (AnimGroupName -> Float -> ControlEvent)
    -> AnimState
    -> AnimState
controlWithCancel animGroupName transformGroups toEvent (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            let
                wasRunning =
                    not animGroup.isComplete && not animGroup.isPaused

                updatedAnimGroups =
                    transformGroups animGroup animGroups

                newPendingControlEvents =
                    if wasRunning then
                        state.pendingControlEvents ++ [ toEvent animGroupName (overallProgress animGroup) ]

                    else
                        state.pendingControlEvents

                stillRunning =
                    AnimGroups.groups updatedAnimGroups
                        |> List.any (\group -> not group.isComplete && not group.isPaused)
            in
            AnimState
                { state
                    | subscriptionsActive = stillRunning
                    , pendingControlEvents = newPendingControlEvents
                }
                updatedAnimGroups



{- ***** STATE QUERIES ***** -}


anyRunning : AnimState -> Maybe Bool
anyRunning (AnimState state animGroups) =
    case AnimGroups.groups animGroups of
        [] ->
            Nothing

        _ ->
            Just state.subscriptionsActive


allComplete : AnimState -> Maybe Bool
allComplete (AnimState _ animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        animGroups
            |> AnimGroups.groups
            |> List.all .isComplete
            |> Just


isComplete : AnimGroupName -> AnimState -> Maybe Bool
isComplete animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map .isComplete


isRunning : AnimGroupName -> AnimState -> Maybe Bool
isRunning animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map
            (\animGroup ->
                not animGroup.isComplete
                    && (Animations.list animGroup.animations
                            |> List.any (not << isAnimationComplete)
                       )
            )


isAnimationComplete : Animation -> Bool
isAnimationComplete =
    Animation.foldTiming .isComplete


getProgress : AnimGroupName -> AnimState -> Maybe Float
getProgress animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map overallProgress


overallProgress : AnimGroup -> Float
overallProgress { animations } =
    Animations.list animations
        |> List.map animationProgress
        |> List.maximum
        |> Maybe.withDefault 0


animationProgress : Animation -> Float
animationProgress =
    Animation.foldTiming calculateProgress



{- ***** PROPERTY QUERIES ***** -}
--
--
--
{- *** BACKGROUND COLOR *** -}


getBackgroundColor : String -> AnimState -> Maybe Color
getBackgroundColor =
    getPropertyValue "backgroundColor"
        (\prop ->
            case prop of
                BackgroundColor a ->
                    Just (computeCurrentValue Color.interpolate a)

                _ ->
                    Nothing
        )


getBackgroundColorRange : String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange =
    getPropertyRange
        (\propConfig ->
            case propConfig of
                Builder.ProcessedBackgroundColorConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )



{- *** FONT COLOR *** -}


getFontColor : String -> AnimState -> Maybe Color
getFontColor =
    getPropertyValue "fontColor"
        (\prop ->
            case prop of
                FontColor a ->
                    Just (computeCurrentValue Color.interpolate a)

                _ ->
                    Nothing
        )


getFontColorRange : String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getFontColorRange =
    getPropertyRange
        (\propConfig ->
            case propConfig of
                Builder.ProcessedFontColorConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )



{- *** OPACITY *** -}


getOpacity : String -> AnimState -> Maybe Opacity
getOpacity =
    getPropertyValue "opacity"
        (\prop ->
            case prop of
                Opacity a ->
                    Just (computeCurrentValue interpolateOpacity a)

                _ ->
                    Nothing
        )


interpolateOpacity : Float -> Opacity -> Opacity -> Opacity
interpolateOpacity t start end =
    Opacity.fromFloat (interpolateFloat t (Opacity.toFloat start) (Opacity.toFloat end))


getOpacityRange : String -> AnimState -> Maybe { start : Maybe Opacity, end : Opacity }
getOpacityRange =
    getPropertyRange
        (\propConfig ->
            case propConfig of
                Builder.ProcessedOpacityConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )



{- *** ROTATE *** -}


getRotate : String -> AnimState -> Maybe Rotate
getRotate =
    getPropertyValue "rotate"
        (\prop ->
            case prop of
                Rotate a ->
                    Just (computeCurrentValue interpolateRotate a)

                _ ->
                    Nothing
        )


interpolateRotate : Float -> Rotate -> Rotate -> Rotate
interpolateRotate =
    interpolateTriple Rotate.toTriple Rotate.fromTriple


getRotateRange : String -> AnimState -> Maybe { start : Maybe Rotate, end : Rotate }
getRotateRange =
    getPropertyRange
        (\propConfig ->
            case propConfig of
                Builder.ProcessedRotateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )



{- *** SCALE *** -}


getScale : String -> AnimState -> Maybe Scale
getScale =
    getPropertyValue "scale"
        (\prop ->
            case prop of
                Scale a ->
                    Just (computeCurrentValue interpolateScale a)

                _ ->
                    Nothing
        )


interpolateScale : Float -> Scale -> Scale -> Scale
interpolateScale =
    interpolateTriple Scale.toTriple Scale.fromTriple


getScaleRange : String -> AnimState -> Maybe { start : Maybe Scale, end : Scale }
getScaleRange =
    getPropertyRange
        (\propConfig ->
            case propConfig of
                Builder.ProcessedScaleConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )



{- *** SIZE *** -}


getSize : String -> AnimState -> Maybe Size
getSize =
    getPropertyValue "size"
        (\prop ->
            case prop of
                Size a ->
                    Just (computeCurrentValue interpolateSize a)

                _ ->
                    Nothing
        )


interpolateSize : Float -> Size -> Size -> Size
interpolateSize =
    interpolateTuple Size.toTuple Size.fromTuple


getSizeRange : String -> AnimState -> Maybe { start : Maybe Size, end : Size }
getSizeRange =
    getPropertyRange
        (\propConfig ->
            case propConfig of
                Builder.ProcessedSizeConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )



{- *** TRANSLATE *** -}


getTranslate : String -> AnimState -> Maybe Translate
getTranslate =
    getPropertyValue "translate"
        (\prop ->
            case prop of
                Translate a ->
                    Just (computeCurrentValue interpolateTranslate a)

                _ ->
                    Nothing
        )


interpolateTranslate : Float -> Translate -> Translate -> Translate
interpolateTranslate =
    interpolateTriple Translate.toTriple Translate.fromTriple


getTranslateRange : String -> AnimState -> Maybe { start : Maybe Translate, end : Translate }
getTranslateRange =
    getPropertyRange
        (\propConfig ->
            case propConfig of
                Builder.ProcessedTranslateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )



{- *** PROPERTY HELPERS *** -}


getPropertyRange : (Builder.ProcessedPropertyConfig -> Maybe a) -> String -> AnimState -> Maybe a
getPropertyRange matcher animGroup (AnimState state _) =
    let
        elements =
            Builder.process state.builder
                |> .groups
    in
    AnimGroups.get animGroup elements
        |> Maybe.andThen (.properties >> List.filterMap matcher >> List.head)


getPropertyValue : String -> (Animation -> Maybe a) -> AnimGroupName -> AnimState -> Maybe a
getPropertyValue propertyKey valueExtractor animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.andThen (Animations.get propertyKey << .animations)
        |> Maybe.andThen valueExtractor


calculateProgress : { a | elapsedMs : Float, delayMs : Float, totalDurationMs : Float, isComplete : Bool } -> Float
calculateProgress timing =
    if timing.isComplete || timing.totalDurationMs <= 0 then
        1.0

    else
        let
            animationElapsedMs =
                max 0 (timing.elapsedMs - timing.delayMs)
        in
        if animationElapsedMs <= 0 then
            0.0

        else
            min 1.0 (animationElapsedMs / timing.totalDurationMs)


computeCurrentValue : (Float -> a -> a -> a) -> PropertyAnimation a -> a
computeCurrentValue interpolate anim =
    let
        easedProgress =
            anim.easingFunction (calculateProgress anim)
    in
    interpolate easedProgress anim.start anim.end


interpolateFloat : Float -> Float -> Float -> Float
interpolateFloat t start end =
    start + (end - start) * t


interpolateTriple : (a -> ( Float, Float, Float )) -> (( Float, Float, Float ) -> a) -> Float -> a -> a -> a
interpolateTriple toTriple fromTriple t start end =
    let
        ( s1, s2, s3 ) =
            toTriple start

        ( e1, e2, e3 ) =
            toTriple end
    in
    fromTriple ( interpolateFloat t s1 e1, interpolateFloat t s2 e2, interpolateFloat t s3 e3 )


interpolateTuple : (a -> ( Float, Float )) -> (( Float, Float ) -> a) -> Float -> a -> a -> a
interpolateTuple toTuple fromTuple t start end =
    let
        ( s1, s2 ) =
            toTuple start

        ( e1, e2 ) =
            toTuple end
    in
    fromTuple ( interpolateFloat t s1 e1, interpolateFloat t s2 e2 )
