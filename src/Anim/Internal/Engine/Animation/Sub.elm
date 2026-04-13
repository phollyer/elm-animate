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
import Anim.Extra.TransformOrder as TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)
import Anim.Internal.Engine.Animation.Sub.AnimGroup as AnimGroup exposing (AnimGroup)
import Anim.Internal.Engine.Animation.Sub.Animation exposing (Animation(..), PropertyAnimation)
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
                (Maybe.withDefault TransformOrder.default processedAnimData.globalTransformOrder)
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
                        (animGroup |> AnimGroup.addAnimation (AnimGroup.getAnimations existing))
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



{- ***** UPDATE ***** -}


type AnimMsg
    = AnimationFrame Float


update : AnimMsg -> AnimState -> ( AnimState, List AnimEvent )
update msg (AnimState state animGroups) =
    case msg of
        AnimationFrame deltaMs ->
            let
                -- Update each element and collect events
                ( updatedElementsList, elementEvents ) =
                    AnimGroups.toList animGroups
                        |> List.map
                            (\( animGroupName, elem ) ->
                                let
                                    ( newElem, events ) =
                                        handleTick deltaMs animGroupName elem
                                in
                                ( ( animGroupName, newElem ), events )
                            )
                        |> List.unzip

                updatedElements =
                    AnimGroups.fromList updatedElementsList

                allElementEvents =
                    List.concat elementEvents

                stillRunning =
                    AnimGroups.groups updatedElements |> List.any (not << .isComplete)

                -- Combine control events with tick events
                allEvents =
                    List.map Control state.pendingControlEvents
                        ++ List.map Tick allElementEvents

                newState =
                    AnimState
                        { subscriptionsActive = stillRunning
                        , builder = state.builder
                        , pendingControlEvents = []
                        }
                        updatedElements
            in
            ( newState, allEvents )


handleTick : Float -> String -> AnimGroup -> ( AnimGroup, List TickEvent )
handleTick deltaMs animGroupName animGroup =
    if animGroup.isPaused then
        ( animGroup, [] )

    else
        let
            updatedAnimations =
                Animations.map (\_ -> updateAnimatedProperty deltaMs) animGroup.animations

            allPropertiesComplete =
                Animations.list updatedAnimations
                    |> List.all isAnimatedPropertyComplete
        in
        if allPropertiesComplete && not animGroup.isComplete then
            -- Properties just finished - check if we need to iterate
            case animGroup.iterationCount of
                Builder.Infinite ->
                    -- Reset for next iteration
                    let
                        nextIteration =
                            animGroup.currentIteration + 1

                        resetProperties =
                            Animations.map (\_ -> resetAnimatedProperty) updatedAnimations
                    in
                    ( { animGroup
                        | animations = resetProperties
                        , currentIteration = nextIteration
                        , isComplete = False
                      }
                    , [ Iteration animGroupName nextIteration ]
                    )

                Builder.Times totalIterations ->
                    if animGroup.currentIteration < totalIterations then
                        -- More iterations to go
                        let
                            nextIteration =
                                animGroup.currentIteration + 1

                            resetProperties =
                                Animations.map (\_ -> resetAnimatedProperty) updatedAnimations
                        in
                        ( { animGroup
                            | animations = resetProperties
                            , currentIteration = nextIteration
                            , isComplete = False
                          }
                        , [ Iteration animGroupName nextIteration ]
                        )

                    else
                        -- All iterations done
                        ( { animGroup
                            | animations = updatedAnimations
                            , isComplete = True
                          }
                        , [ Ended animGroupName ]
                        )

                Builder.Once ->
                    -- Single iteration, just complete
                    ( { animGroup
                        | animations = updatedAnimations
                        , isComplete = True
                      }
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


attributes : String -> AnimState -> List (Html.Attribute msg)
attributes animGroup (AnimState _ animGroups) =
    case AnimGroups.get animGroup animGroups of
        Nothing ->
            []

        Just elementAnimation ->
            let
                properties =
                    Animations.list elementAnimation.animations

                -- Extract transforms directly from animated properties
                transformParts =
                    List.foldl collectCurrentTransform Builder.emptyTransformParts properties

                -- Build transform string using stored transform order
                transformString =
                    elementAnimation.transformOrder
                        |> List.map (transformOrderToPart transformParts)
                        |> List.filter (not << String.isEmpty)
                        |> String.join " "

                sizeStyles =
                    List.concatMap getSizeStyleAttributes properties

                nonTransformStyles =
                    List.filterMap getNonTransformStyleAttribute properties

                transformStyle =
                    if String.isEmpty transformString then
                        []

                    else
                        [ Html.Attributes.style "transform" transformString ]

                discreteStyles =
                    discreteEntryStyles elementAnimation
                        ++ discreteExitStyles elementAnimation
            in
            transformStyle ++ sizeStyles ++ nonTransformStyles ++ discreteStyles



{- ***** CONTROL ***** -}


{-| Stop animation by jumping to its end state.
-}
stop : AnimGroupName -> AnimState -> AnimState
stop animGroupName (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            let
                wasRunning =
                    not animGroup.isComplete && not animGroup.isPaused

                updatedProperties =
                    Animations.map (\_ -> stopAnimatedProperty) animGroup.animations

                updatedAnim =
                    { animGroup | animations = updatedProperties, isComplete = True, isPaused = False }

                updatedDict =
                    AnimGroups.insert animGroupName updatedAnim animGroups

                newPendingControlEvents =
                    if wasRunning then
                        state.pendingControlEvents ++ [ Cancelled animGroupName (overallProgress animGroup) ]

                    else
                        state.pendingControlEvents
            in
            AnimState { state | pendingControlEvents = newPendingControlEvents } updatedDict


{-| Reset animation by jumping to its start state.
-}
reset : String -> AnimState -> AnimState
reset animGroupName (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            let
                wasRunning =
                    not animGroup.isComplete && not animGroup.isPaused

                updatedProperties =
                    Animations.map (\_ -> resetAnimatedProperty) animGroup.animations

                updatedAnim =
                    { animGroup | animations = updatedProperties, isComplete = False, isPaused = False }

                updatedDict =
                    AnimGroups.insert animGroupName updatedAnim animGroups

                newPendingControlEvents =
                    if wasRunning then
                        state.pendingControlEvents ++ [ Cancelled animGroupName (overallProgress animGroup) ]

                    else
                        state.pendingControlEvents
            in
            AnimState { state | subscriptionsActive = False, pendingControlEvents = newPendingControlEvents } updatedDict


{-| Restart animation from the beginning.
-}
restart : String -> AnimState -> AnimState
restart animGroup (AnimState state animGroups) =
    case AnimGroups.get animGroup animGroups of
        Nothing ->
            AnimState state animGroups

        Just elementAnim ->
            let
                updatedProperties =
                    Animations.map (\_ -> resetAnimatedProperty) elementAnim.animations

                updatedAnim =
                    { elementAnim | animations = updatedProperties, isComplete = False, isPaused = False }

                updatedDict =
                    AnimGroups.insert animGroup updatedAnim animGroups
            in
            AnimState { state | subscriptionsActive = True, pendingControlEvents = state.pendingControlEvents ++ [ Restarted animGroup ] } updatedDict


{-| Pause animation for a specific element.
-}
pause : AnimGroupName -> AnimState -> AnimState
pause animGroupName (AnimState state animGroups) =
    case AnimGroups.get animGroupName animGroups of
        Nothing ->
            AnimState state animGroups

        Just animGroup ->
            let
                wasRunning =
                    not animGroup.isComplete && not animGroup.isPaused

                updatedAnimations =
                    AnimGroups.update animGroupName
                        (Maybe.map (\ea -> { ea | isPaused = True }))
                        animGroups

                newPendingControlEvents =
                    if wasRunning then
                        state.pendingControlEvents ++ [ Paused animGroupName (overallProgress animGroup) ]

                    else
                        state.pendingControlEvents
            in
            AnimState { state | pendingControlEvents = newPendingControlEvents } updatedAnimations


{-| Resume animation for a specific element.
-}
resume : String -> AnimState -> AnimState
resume animGroup (AnimState state animGroups) =
    case AnimGroups.get animGroup animGroups of
        Nothing ->
            AnimState state animGroups

        Just elementAnim ->
            let
                wasPaused =
                    elementAnim.isPaused && not elementAnim.isComplete

                updatedAnimations =
                    AnimGroups.update animGroup
                        (Maybe.map (\ea -> { ea | isPaused = False }))
                        animGroups

                newPendingControlEvents =
                    if wasPaused then
                        state.pendingControlEvents ++ [ Resumed animGroup ]

                    else
                        state.pendingControlEvents
            in
            AnimState { state | subscriptionsActive = True, pendingControlEvents = newPendingControlEvents } updatedAnimations


{-| Reset an animated property to its initial state for a new iteration.
-}
resetAnimatedProperty : Animation -> Animation
resetAnimatedProperty prop =
    let
        rewind anim =
            { anim | elapsedMs = 0, isComplete = False }
    in
    case prop of
        Translate a ->
            Translate (rewind a)

        Rotate a ->
            Rotate (rewind a)

        Scale a ->
            Scale (rewind a)

        BackgroundColor a ->
            BackgroundColor (rewind a)

        FontColor a ->
            FontColor (rewind a)

        Opacity a ->
            Opacity (rewind a)

        Size a ->
            Size (rewind a)


{-| Calculate overall element progress as the max progress across all properties.
Each property's progress accounts for its own delay and duration independently.
-}
overallProgress : AnimGroup -> Float
overallProgress { animations } =
    Animations.list animations
        |> List.map animatedPropertyProgress
        |> List.maximum
        |> Maybe.withDefault 0


animatedPropertyProgress : Animation -> Float
animatedPropertyProgress prop =
    case prop of
        Translate a ->
            propertyAnimationProgress a

        Rotate a ->
            propertyAnimationProgress a

        Scale a ->
            propertyAnimationProgress a

        BackgroundColor a ->
            propertyAnimationProgress a

        FontColor a ->
            propertyAnimationProgress a

        Opacity a ->
            propertyAnimationProgress a

        Size a ->
            propertyAnimationProgress a


propertyAnimationProgress : PropertyAnimation a -> Float
propertyAnimationProgress anim =
    if anim.isComplete || anim.totalDurationMs <= 0 then
        1.0

    else
        let
            animationElapsedMs =
                max 0 (anim.elapsedMs - anim.delayMs)
        in
        if animationElapsedMs <= 0 then
            0.0

        else
            min 1.0 (animationElapsedMs / anim.totalDurationMs)



-- SUBSCRIPTIONS


subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions toMsg (AnimState state _) =
    if state.subscriptionsActive then
        Browser.Events.onAnimationFrameDelta AnimationFrame
            |> Sub.map toMsg

    else
        Sub.none



-- VIEW


collectCurrentTransform : Animation -> Builder.TransformParts -> Builder.TransformParts
collectCurrentTransform prop acc =
    case prop of
        Translate anim ->
            { acc | translate = Translate.toCssString (computeCurrentValue anim interpolateTranslate) }

        Rotate anim ->
            { acc | rotate = Rotate.toCssString (computeCurrentValue anim interpolateRotate) }

        Scale anim ->
            { acc | scale = Scale.toCssString (computeCurrentValue anim interpolateScale) }

        _ ->
            acc


transformOrderToPart : Builder.TransformParts -> TransformProperty -> String
transformOrderToPart parts order =
    case order of
        TransformOrder.Translate ->
            parts.translate

        TransformOrder.Rotate ->
            parts.rotate

        TransformOrder.Scale ->
            parts.scale



-- Querying


allComplete : AnimState -> Maybe Bool
allComplete (AnimState _ animGroups) =
    if AnimGroups.isEmpty animGroups then
        Nothing

    else
        animGroups
            |> AnimGroups.groups
            |> List.all .isComplete
            |> Just


anyRunning : AnimState -> Maybe Bool
anyRunning (AnimState state animGroups) =
    case AnimGroups.groups animGroups of
        [] ->
            Nothing

        _ ->
            Just state.subscriptionsActive


isRunning : AnimGroupName -> AnimState -> Maybe Bool
isRunning animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map
            (\animGroup ->
                not animGroup.isComplete
                    && (Animations.list animGroup.animations
                            |> List.any (not << isAnimatedPropertyComplete)
                       )
            )


isComplete : AnimGroupName -> AnimState -> Maybe Bool
isComplete animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map .isComplete


getProgress : AnimGroupName -> AnimState -> Maybe Float
getProgress animGroupName (AnimState _ animGroups) =
    AnimGroups.get animGroupName animGroups
        |> Maybe.map overallProgress


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


computeCurrentValue : PropertyAnimation a -> (Float -> a -> a -> a) -> a
computeCurrentValue anim interpolate =
    let
        animationElapsedMs =
            max 0 (anim.elapsedMs - anim.delayMs)

        progress =
            if anim.isComplete || anim.totalDurationMs <= 0 then
                1.0

            else if animationElapsedMs <= 0 then
                0.0

            else
                min 1.0 (animationElapsedMs / anim.totalDurationMs)

        easedProgress =
            anim.easingFunction progress
    in
    interpolate easedProgress anim.startValue anim.endValue


interpolateFloat : Float -> Float -> Float -> Float
interpolateFloat t start end =
    start + (end - start) * t


interpolateTranslate : Float -> Translate -> Translate -> Translate
interpolateTranslate t start end =
    let
        ( sx, sy, sz ) =
            Translate.toTriple start

        ( ex, ey, ez ) =
            Translate.toTriple end
    in
    Translate.fromTriple ( interpolateFloat t sx ex, interpolateFloat t sy ey, interpolateFloat t sz ez )


interpolateRotate : Float -> Rotate -> Rotate -> Rotate
interpolateRotate t start end =
    let
        ( sx, sy, sz ) =
            Rotate.toTriple start

        ( ex, ey, ez ) =
            Rotate.toTriple end
    in
    Rotate.fromTriple ( interpolateFloat t sx ex, interpolateFloat t sy ey, interpolateFloat t sz ez )


interpolateScale : Float -> Scale -> Scale -> Scale
interpolateScale t start end =
    let
        ( sx, sy, sz ) =
            Scale.toTriple start

        ( ex, ey, ez ) =
            Scale.toTriple end
    in
    Scale.fromTriple ( interpolateFloat t sx ex, interpolateFloat t sy ey, interpolateFloat t sz ez )


interpolateOpacity : Float -> Opacity -> Opacity -> Opacity
interpolateOpacity t start end =
    interpolateFloat t (Opacity.toFloat start) (Opacity.toFloat end)
        |> Opacity.fromFloat


interpolateSize : Float -> Size -> Size -> Size
interpolateSize t start end =
    let
        ( sw, sh ) =
            Size.toTuple start

        ( ew, eh ) =
            Size.toTuple end
    in
    Size.fromTuple ( interpolateFloat t sw ew, interpolateFloat t sh eh )


getBackgroundColor : String -> AnimState -> Maybe Color
getBackgroundColor =
    getPropertyValue "backgroundColor"
        (\prop ->
            case prop of
                BackgroundColor anim ->
                    Just (computeCurrentValue anim Color.interpolate)

                _ ->
                    Nothing
        )


getBackgroundColorRange : String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedBackgroundColorConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getOpacityRange : String -> AnimState -> Maybe { start : Maybe Opacity, end : Opacity }
getOpacityRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedOpacityConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getOpacity : String -> AnimState -> Maybe Opacity
getOpacity =
    getPropertyValue "opacity"
        (\prop ->
            case prop of
                Opacity anim ->
                    Just (computeCurrentValue anim interpolateOpacity)

                _ ->
                    Nothing
        )


getTranslate : String -> AnimState -> Maybe Translate
getTranslate =
    getPropertyValue "translate"
        (\prop ->
            case prop of
                Translate anim ->
                    Just (computeCurrentValue anim interpolateTranslate)

                _ ->
                    Nothing
        )


getTranslateRange : String -> AnimState -> Maybe { start : Maybe Translate, end : Translate }
getTranslateRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedTranslateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getRotate : String -> AnimState -> Maybe Rotate
getRotate =
    getPropertyValue "rotate"
        (\prop ->
            case prop of
                Rotate anim ->
                    Just (computeCurrentValue anim interpolateRotate)

                _ ->
                    Nothing
        )


getRotateRange : String -> AnimState -> Maybe { start : Maybe Rotate, end : Rotate }
getRotateRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedRotateConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getScale : String -> AnimState -> Maybe Scale
getScale =
    getPropertyValue "scale"
        (\prop ->
            case prop of
                Scale anim ->
                    Just (computeCurrentValue anim interpolateScale)

                _ ->
                    Nothing
        )


getScaleRange : String -> AnimState -> Maybe { start : Maybe Scale, end : Scale }
getScaleRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedScaleConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )


getSize : String -> AnimState -> Maybe Size
getSize =
    getPropertyValue "size"
        (\prop ->
            case prop of
                Size anim ->
                    Just (computeCurrentValue anim interpolateSize)

                _ ->
                    Nothing
        )


getSizeRange : String -> AnimState -> Maybe { start : Maybe Size, end : Size }
getSizeRange =
    getPropertyRange
        (\prop ->
            case prop of
                Builder.ProcessedSizeConfig config ->
                    Just { start = config.start, end = config.end }

                _ ->
                    Nothing
        )



-- Builder Helpers


extractCurrentStates : AnimGroups AnimGroup -> AnimGroups { propertySnapshot : Builder.PropertyEndStates }
extractCurrentStates elementAnimations =
    AnimGroups.map (\_ elemAnim -> { propertySnapshot = extractElementCurrentStates elemAnim }) elementAnimations


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
extractPropertyCurrentState prop states =
    case prop of
        Translate anim ->
            { states | translate = Just (computeCurrentValue anim interpolateTranslate) }

        Rotate anim ->
            { states | rotate = Just (computeCurrentValue anim interpolateRotate) }

        Scale anim ->
            { states | scale = Just (computeCurrentValue anim interpolateScale) }

        BackgroundColor anim ->
            { states | backgroundColor = Just (computeCurrentValue anim Color.interpolate) }

        FontColor anim ->
            { states | fontColor = Just (computeCurrentValue anim Color.interpolate) }

        Opacity anim ->
            { states | opacity = Just (computeCurrentValue anim interpolateOpacity) }

        Size anim ->
            { states | size = Just (computeCurrentValue anim interpolateSize) }


updateAnimatedProperty : Float -> Animation -> Animation
updateAnimatedProperty deltaMs prop =
    let
        tick anim =
            if anim.isComplete then
                anim

            else
                let
                    newElapsedMs =
                        anim.elapsedMs + deltaMs

                    animationElapsedMs =
                        max 0 (newElapsedMs - anim.delayMs)
                in
                { anim
                    | elapsedMs = newElapsedMs
                    , isComplete = animationElapsedMs >= anim.totalDurationMs
                }
    in
    case prop of
        Translate a ->
            Translate (tick a)

        Rotate a ->
            Rotate (tick a)

        Scale a ->
            Scale (tick a)

        BackgroundColor a ->
            BackgroundColor (tick a)

        FontColor a ->
            FontColor (tick a)

        Opacity a ->
            Opacity (tick a)

        Size a ->
            Size (tick a)


isAnimatedPropertyComplete : Animation -> Bool
isAnimatedPropertyComplete prop =
    case prop of
        Translate a ->
            a.isComplete

        Rotate a ->
            a.isComplete

        Scale a ->
            a.isComplete

        BackgroundColor a ->
            a.isComplete

        FontColor a ->
            a.isComplete

        Opacity a ->
            a.isComplete

        Size a ->
            a.isComplete


stopAnimatedProperty : Animation -> Animation
stopAnimatedProperty prop =
    let
        finish anim =
            { anim
                | elapsedMs = anim.totalDurationMs + anim.delayMs
                , isComplete = True
            }
    in
    case prop of
        Translate a ->
            Translate (finish a)

        Rotate a ->
            Rotate (finish a)

        Scale a ->
            Scale (finish a)

        BackgroundColor a ->
            BackgroundColor (finish a)

        FontColor a ->
            FontColor (finish a)

        Opacity a ->
            Opacity (finish a)

        Size a ->
            Size (finish a)



-- View Helpers


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


getSizeStyleAttributes : Animation -> List (Html.Attribute msg)
getSizeStyleAttributes prop =
    case prop of
        Size anim ->
            let
                size =
                    computeCurrentValue anim interpolateSize

                ( width, height ) =
                    Size.toTuple size
            in
            [ Html.Attributes.style "width" (String.fromFloat width ++ "px")
            , Html.Attributes.style "height" (String.fromFloat height ++ "px")
            ]

        _ ->
            []


getNonTransformStyleAttribute : Animation -> Maybe (Html.Attribute msg)
getNonTransformStyleAttribute prop =
    case prop of
        Translate _ ->
            Nothing

        Rotate _ ->
            Nothing

        Scale _ ->
            Nothing

        BackgroundColor anim ->
            Just (Html.Attributes.style "background-color" (Color.toCssString (computeCurrentValue anim Color.interpolate)))

        FontColor anim ->
            Just (Html.Attributes.style "color" (Color.toCssString (computeCurrentValue anim Color.interpolate)))

        Opacity anim ->
            Just (Html.Attributes.style "opacity" (String.fromFloat (Opacity.toFloat (computeCurrentValue anim interpolateOpacity))))

        Size _ ->
            -- Size is handled separately in getSizeStyleAttributes to set width and height
            Nothing
