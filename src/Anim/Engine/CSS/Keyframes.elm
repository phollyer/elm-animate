module Anim.Engine.CSS.Keyframes exposing
    ( AnimState, init
    , AnimBuilder, animate, fireAndForget
    , attributes
    , styleNode, styleNodeFor, getElementKeyframes
    , TransformOrder(..), transformOrder
    , AnimMsg, AnimEvent(..), update
    , events, eventsStopPropagation
    , onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel
    , onAnimationStartStopPropagation, onAnimationEndStopPropagation, onAnimationIterationStopPropagation, onAnimationCancelStopPropagation
    , duration, speed
    , easing
    , delay
    , iterations, loopForever, alternate
    , stop, reset, restart, pause, resume
    , anyRunning, isRunning, allComplete, isComplete
    , getBackgroundColorStart, getBackgroundColorEnd
    , getOpacityStart, getOpacityEnd
    , getRotateStart, getRotateEnd
    , getScaleStart, getScaleEnd
    , getSizeStart, getSizeEnd
    , getTranslateStart, getTranslateEnd
    )

{-| CSS Keyframe Animations engine for complex, multi-step animations.

For detailed guides, examples, and engine comparisons, see the
[full documentation](https://phollyer.github.io/elm-animate/engines/keyframes/).


# State

@docs AnimState, init


# Trigger

@docs AnimBuilder, animate, fireAndForget


# Render

@docs attributes

@docs styleNode, styleNodeFor, getElementKeyframes


# Transform Order

@docs TransformOrder, transformOrder


# Events

@docs AnimMsg, AnimEvent, update

@docs events, eventsStopPropagation

@docs onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel

@docs onAnimationStartStopPropagation, onAnimationEndStopPropagation, onAnimationIterationStopPropagation, onAnimationCancelStopPropagation


# Default Settings

@docs duration, speed

@docs easing

@docs delay

@docs iterations, loopForever, alternate


# Animation Control

@docs stop, reset, restart, pause, resume


# Querying Animation State

@docs anyRunning, isRunning, allComplete, isComplete


# Querying Animated Properties


## Background Color

@docs getBackgroundColorStart, getBackgroundColorEnd


## Opacity

@docs getOpacityStart, getOpacityEnd


## Rotate

@docs getRotateStart, getRotateEnd


## Scale

@docs getScaleStart, getScaleEnd


## Size

@docs getSizeStart, getSizeEnd


## Translate

@docs getTranslateStart, getTranslateEnd

-}

import Anim.Extra.Color exposing (Color)
import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.CSS as InternalCSS exposing (ElementState(..))
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate as Translate
import Html
import Task



-- TYPES


{-| The animation state type used to store animation configurations and keyframes.

Store it in your model.

    type alias Model =
        { animState : Keyframes.AnimState }

-}
type alias AnimState =
    InternalCSS.AnimState


{-| Animation builder type for configuring animations.
-}
type alias AnimBuilder =
    InternalCSS.AnimBuilder


{-| Transform property ordering.

The **default** (recommended) transform order is: Translate → Rotate → Scale.

  - Translate sets the base location
  - Rotation happens around that position
  - Scale happens last to avoid affecting rotation radius

-}
type TransformOrder
    = Translate
    | Rotate
    | Scale


{-| Opaque message type for CSS keyframe animation DOM events.

Pass this to your parent Msg type and forward it to [update](#update).

    type Msg
        = KeyframeMsg Keyframes.AnimMsg
        | ...

-}
type AnimMsg
    = AnimMsg InternalAnimMsg


{-| Internal message variants.
-}
type InternalAnimMsg
    = InternalStarted InternalCSS.SourceEventData
    | InternalEnded InternalCSS.SourceEventData
    | InternalCancelled InternalCSS.SourceEventData
    | InternalIteration InternalCSS.SourceEventData
    | InternalPaused String
    | InternalResumed String
    | InternalRestarted String


{-| CSS keyframe animation lifecycle events.

Returned by [update](#update) for you to pattern match and react to.

Each event contains three `String` values: `currentTargetId`, `targetId`, and `animGroup`.

  - `currentTargetId`: The HTML `id` attribute of the element where the handler is attached.
    This is an empty string `""` if the element has no `id` attribute set.
  - `targetId`: The HTML `id` attribute of the element that triggered the event (event.target).
    This is an empty string `""` if the element has no `id` attribute set.
  - `animGroup`: The animation group name passed to `Keyframes.attributes`.

You can pattern match on any combination of values:

    handleAnimationEvent : Keyframes.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            -- Match specific handler, any source element, specific animation
            Keyframes.Ended "cube" _ "fadeIn" ->
                ( { model | phase = Complete }, Cmd.none )

            -- Match any handler and any source with a specific animation group
            Keyframes.Ended _ _ "box" ->
                ( model, startNextAnimation )

            -- Match specific source element with any handler and animation
            Keyframes.Ended _ "header" _ ->
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

-}
type AnimEvent
    = Started String String String
    | Ended String String String
    | Cancelled String String String
    | Iteration String String String
    | Paused String String String
    | Resumed String String String
    | Restarted String String String



-- INIT


{-| Initialize animation state with optional property initializers.

    -- Empty state
    Keyframes.init []

    -- With initial properties
    Keyframes.init
        [ Translate.initXY "animGroupName" 100 50
        , Opacity.init "animGroupName" 0.5
        ]

-}
init : List (AnimBuilder -> AnimBuilder) -> AnimState
init =
    InternalCSS.init



-- EXECUTE


{-| Create a state-tracked animation.

    { model
        | animState =
            Keyframes.animate model.animState <|
                (fadeIn >> slideIn)
    }

-}
animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate =
    InternalCSS.animate


{-| Set the transform order for all future animations.

The transform order specifies how translate, rotate, and scale transforms
are combined. Start the list with the transform to apply first.

Any missing transforms are automatically appended in the default order
(Translate → Rotate → Scale).

    Keyframes.transformOrder [ Scale, Rotate, Translate ]
        >> rotateLeft
        >> scaleUp
        >> moveRight

-}
transformOrder : List TransformOrder -> AnimBuilder -> AnimBuilder
transformOrder order =
    let
        mapOrder xform =
            case xform of
                Translate ->
                    Builder.Translate

                Rotate ->
                    Builder.Rotate

                Scale ->
                    Builder.Scale
    in
    Builder.transformOrder (List.map mapOrder order)


{-| Create a fire-and-forget animation without state tracking.

    { model
        | animState =
            Keyframes.fireAndForget <|
                (fadeIn >> slideIn)
    }

-}
fireAndForget : (AnimBuilder -> AnimBuilder) -> AnimState
fireAndForget =
    animate (init [])



-- GLOBAL SETTINGS


{-| Set the global duration in milliseconds.

    model.animState
        |> Keyframes.builder
        |> Keyframes.duration 500
        |> ...

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalCSS.duration


{-| Set the global speed in pixels per second.

    model.animState
        |> Keyframes.builder
        |> Keyframes.speed 100
        |> ...

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalCSS.speed


{-| Set the global easing function.

    model.animState
        |> Keyframes.builder
        |> Keyframes.easing EaseInOutQuad
        |> ...

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalCSS.easing


{-| Set the global delay in milliseconds.

    model.animState
        |> Keyframes.builder
        |> Keyframes.delay 500
        |> ...

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalCSS.delay


{-| Set how many times an animation should repeat.

    Keyframes.animate model.animState <|
        (iterations 3 >> pulse "elementId")

-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    Builder.iterations


{-| Make an animation loop infinitely.

    Keyframes.animate model.animState <|
        (loopForever >> pulse "elementId")

The animation will continue until you call `stop`, `reset`, or remove the element.

-}
loopForever : AnimBuilder -> AnimBuilder
loopForever =
    Builder.loopForever


{-| Make an animation alternate direction on each iteration (ping-pong effect).

    Keyframes.animate model.animState <|
        (loopForever >> alternate >> pulse "elementId")

This creates a smooth ping-pong animation without needing reverse keyframes.
The animation plays forward, then backward, then forward, etc.

-}
alternate : AnimBuilder -> AnimBuilder
alternate =
    Builder.alternate



-- KEYFRAMES STYLES


{-| Get all attributes for keyframe-based animations.

    div
        (Keyframes.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : String -> AnimState -> List (Html.Attribute msg)
attributes =
    InternalCSS.keyframesStyles


{-| Get a `<style>` node containing keyframes for all animated elements.

    view model =
        div []
            [ Keyframes.styleNode animState
            , ...
            ]

If there are no animations, this returns an empty text node.

-}
styleNode : AnimState -> Html.Html msg
styleNode =
    InternalCSS.keyframesStyleNode


{-| Get a `<style>` node containing keyframes for a specific element.

    view model =
        div []
            [ Keyframes.styleNodeFor "animGroupName" animState
            , ...
            ]

If the element has no animations, this returns an empty text node.

-}
styleNodeFor : String -> AnimState -> Html.Html msg
styleNodeFor =
    InternalCSS.keyframesStyleNodeFor


{-| Get the raw generated CSS keyframes string for advanced use cases.

You probably want [styleNodeFor](#styleNodeFor) instead,
which handles creating the full `<style>` node for you.

-}
getElementKeyframes : String -> AnimState -> Maybe String
getElementKeyframes =
    InternalCSS.getElementKeyframes



-- KEYFRAME ANIMATION EVENTS


{-| The simplest way to receive keyframe animation messages.

Events automatically detect their source element from the CSS animation name,
so even bubbled events correctly report which element triggered them.

    type Msg
        = KeyframeMsg Keyframes.AnimMsg

    div
        (Keyframes.attributes "animGroupName" animState
            ++ Keyframes.events "animGroupName" KeyframeMsg
        )
        [ text "Animating element" ]

**Note:** The `elementId` parameter is kept for API consistency but is not used.
The actual source element ID is decoded from the DOM event's `animationName` property.

-}
events : String -> (AnimMsg -> msg) -> List (Html.Attribute msg)
events _ toMsg =
    [ InternalCSS.onAnimationStartWithSource (\data -> toMsg (AnimMsg (InternalStarted data)))
    , InternalCSS.onAnimationEndWithSource (\data -> toMsg (AnimMsg (InternalEnded data)))
    , InternalCSS.onAnimationCancelWithSource (\data -> toMsg (AnimMsg (InternalCancelled data)))
    , InternalCSS.onAnimationIterationWithSource (\data -> toMsg (AnimMsg (InternalIteration data)))
    ]


{-| Handle CSS keyframe animation lifecycle messages.

Returns the updated state and an event for you to pattern match on.

    updateModel msg model =
        case msg of
            KeyframeMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Keyframes.update animMsg model.animState
                in
                handleAnimationEvent event { model | animState = newAnimState }

    handleAnimationEvent : Keyframes.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            Keyframes.Ended domElementId animGroup ->
                -- Animation ended
                -- domElementId is the HTML id attribute (or "" if not set)
                -- animGroup is the animation group name
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

-}
update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update (AnimMsg animMsg) animState =
    let
        idOrEmpty maybeId =
            Maybe.withDefault "" maybeId
    in
    case animMsg of
        InternalStarted data ->
            ( InternalCSS.handleEvent (InternalCSS.AnimationStarted data.animGroup) animState
            , Started (idOrEmpty data.currentTargetId) (idOrEmpty data.domElementId) data.animGroup
            )

        InternalEnded data ->
            ( InternalCSS.handleEvent (InternalCSS.AnimationEnded data.animGroup) animState
            , Ended (idOrEmpty data.currentTargetId) (idOrEmpty data.domElementId) data.animGroup
            )

        InternalCancelled data ->
            ( InternalCSS.handleEvent (InternalCSS.AnimationCancelled data.animGroup) animState
            , Cancelled (idOrEmpty data.currentTargetId) (idOrEmpty data.domElementId) data.animGroup
            )

        InternalIteration data ->
            ( InternalCSS.handleEvent (InternalCSS.AnimationIteration data.animGroup) animState
            , Iteration (idOrEmpty data.currentTargetId) (idOrEmpty data.domElementId) data.animGroup
            )

        InternalPaused animGroup ->
            ( animState, Paused "" "" animGroup )

        InternalResumed animGroup ->
            ( animState, Resumed "" "" animGroup )

        InternalRestarted animGroup ->
            ( animState, Restarted "" "" animGroup )


{-| Event handler for when a CSS animation starts.
-}
onAnimationStart : msg -> Html.Attribute msg
onAnimationStart =
    InternalCSS.onAnimationStart


{-| Event handler for when a CSS animation ends.
-}
onAnimationEnd : msg -> Html.Attribute msg
onAnimationEnd =
    InternalCSS.onAnimationEnd


{-| Event handler for when a CSS animation iteration completes.
-}
onAnimationIteration : msg -> Html.Attribute msg
onAnimationIteration =
    InternalCSS.onAnimationIteration


{-| Event handler for when a CSS animation is cancelled.
-}
onAnimationCancel : msg -> Html.Attribute msg
onAnimationCancel =
    InternalCSS.onAnimationCancel


{-| Like [onAnimationStart](#onAnimationStart) but stops event propagation.
Use this to prevent events from bubbling up to parent elements with listeners.
-}
onAnimationStartStopPropagation : msg -> Html.Attribute msg
onAnimationStartStopPropagation =
    InternalCSS.onAnimationStartStopPropagation


{-| Like [onAnimationEnd](#onAnimationEnd) but stops event propagation.
Use this to prevent events from bubbling up to parent elements with listeners.
-}
onAnimationEndStopPropagation : msg -> Html.Attribute msg
onAnimationEndStopPropagation =
    InternalCSS.onAnimationEndStopPropagation


{-| Like [onAnimationIteration](#onAnimationIteration) but stops event propagation.
Use this to prevent events from bubbling up to parent elements with listeners.
-}
onAnimationIterationStopPropagation : msg -> Html.Attribute msg
onAnimationIterationStopPropagation =
    InternalCSS.onAnimationIterationStopPropagation


{-| Like [onAnimationCancel](#onAnimationCancel) but stops event propagation.
Use this to prevent events from bubbling up to parent elements with listeners.
-}
onAnimationCancelStopPropagation : msg -> Html.Attribute msg
onAnimationCancelStopPropagation =
    InternalCSS.onAnimationCancelStopPropagation


{-| All keyframe animation event handlers with propagation stopped.

Events automatically detect their source element from the CSS animation name,
so even bubbled events correctly report which element triggered them.
This version also stops propagation to prevent parent handlers from receiving the event.

    div
        (Keyframes.attributes "myElement" model.animState
            ++ Keyframes.eventsStopPropagation "myElement" KeyframeMsg
        )
        [ text "Animated element" ]

**Note:** The `elementId` parameter is kept for API consistency but is not used.
The actual source element ID is decoded from the DOM event's `animationName` property.

-}
eventsStopPropagation : String -> (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation _ toMsg =
    [ InternalCSS.onAnimationStartWithSourceStopPropagation (\data -> toMsg (AnimMsg (InternalStarted data)))
    , InternalCSS.onAnimationEndWithSourceStopPropagation (\data -> toMsg (AnimMsg (InternalEnded data)))
    , InternalCSS.onAnimationCancelWithSourceStopPropagation (\data -> toMsg (AnimMsg (InternalCancelled data)))
    , InternalCSS.onAnimationIterationWithSourceStopPropagation (\data -> toMsg (AnimMsg (InternalIteration data)))
    ]



-- ANIMATION CONTROL


{-| Stop a running animation by instantly jumping to its end state.

    Keyframes.stop "elementId" model.animState

-}
stop : String -> AnimState -> AnimState
stop =
    InternalCSS.stopAnimation


{-| Reset an animation by instantly jumping back to its start state.

    Keyframes.reset "elementId" model.animState

-}
reset : String -> AnimState -> AnimState
reset =
    InternalCSS.reset


{-| Restart an animation from the beginning.

Returns a `Restarted` event through `update` if the animation is running.
If the animation is not running, returns `Cmd.none`.

    let
        ( newState, cmd ) =
            Keyframes.restart "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
restart : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart animGroupName toMsg animState =
    let
        newState =
            InternalCSS.restartAnimation animGroupName animState

        cmd =
            if InternalCSS.isRunning animGroupName animState then
                Task.succeed (toMsg (AnimMsg (InternalRestarted animGroupName)))
                    |> Task.perform identity

            else
                Cmd.none
    in
    ( newState, cmd )


{-| Pause a running animation.

Returns a `Paused` event through `update` if the animation is running.
If the animation is not running, returns `Cmd.none`.

    let
        ( newState, cmd ) =
            Keyframes.pause "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
pause : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
pause animGroupName toMsg animState =
    let
        newState =
            InternalCSS.pauseAnimation animGroupName animState

        cmd =
            if InternalCSS.isRunning animGroupName animState then
                Task.succeed (toMsg (AnimMsg (InternalPaused animGroupName)))
                    |> Task.perform identity

            else
                Cmd.none
    in
    ( newState, cmd )


{-| Resume a paused animation.

Returns a `Resumed` event through `update` if the animation is running.
If the animation is not running, returns `Cmd.none`.

    let
        ( newState, cmd ) =
            Keyframes.resume "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
resume : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resume animGroupName toMsg animState =
    let
        newState =
            InternalCSS.resumeAnimation animGroupName animState

        cmd =
            if InternalCSS.isRunning animGroupName animState then
                Task.succeed (toMsg (AnimMsg (InternalResumed animGroupName)))
                    |> Task.perform identity

            else
                Cmd.none
    in
    ( newState, cmd )



-- STATE QUERIES


{-| Check if any animations are currently running.
-}
anyRunning : AnimState -> Bool
anyRunning =
    InternalCSS.anyRunning


{-| Check if a specific element has any animations currently running.
-}
isRunning : String -> AnimState -> Bool
isRunning =
    InternalCSS.isRunning


{-| Check if a specific element's animations have completed.

Returns `Nothing` if there are no animations for the element.

-}
isComplete : String -> AnimState -> Maybe Bool
isComplete =
    InternalCSS.isComplete


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    InternalCSS.allComplete



-- TRANSLATE GETTERS


{-| Get the start translate value of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateStart : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart elementId animState =
    InternalCSS.getTranslateRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 0, y = 0, z = 0 }

                    Just startPos ->
                        Translate.toRecord startPos
            )


{-| Get the end translate value of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd elementId animState =
    InternalCSS.getTranslateRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Translate.toRecord



-- SCALE GETTERS


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleStart : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart elementId animState =
    InternalCSS.getScaleRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 1, y = 1, z = 1 }

                    Just startScale ->
                        Scale.toRecord startScale
            )


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd elementId animState =
    InternalCSS.getScaleRange elementId animState
        |> Maybe.map (.end >> Scale.toRecord)



-- ROTATE GETTERS


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateStart : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart elementId animState =
    InternalCSS.getRotateRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 0, y = 0, z = 0 }

                    Just startRotate ->
                        Rotate.toRecord startRotate
            )


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd elementId animState =
    InternalCSS.getRotateRange elementId animState
        |> Maybe.map (.end >> Rotate.toRecord)



-- OPACITY GETTERS


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityStart : String -> AnimState -> Maybe Float
getOpacityStart elementId animState =
    InternalCSS.getOpacityRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        1.0

                    Just startOpacity ->
                        Opacity.toFloat startOpacity
            )


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : String -> AnimState -> Maybe Float
getOpacityEnd elementId animState =
    InternalCSS.getOpacityRange elementId animState
        |> Maybe.map (.end >> Opacity.toFloat)



-- SIZE GETTERS


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeStart : String -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart elementId animState =
    InternalCSS.getSizeRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { width = 0, height = 0 }

                    Just startSize ->
                        Size.toRecord startSize
            )


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : String -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd elementId animState =
    InternalCSS.getSizeRange elementId animState
        |> Maybe.map (.end >> Size.toRecord)



-- BACKGROUND COLOR GETTERS


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorStart : String -> AnimState -> Maybe Color
getBackgroundColorStart elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Just startColor ->
                        startColor

                    Nothing ->
                        BackgroundColor.default
            )


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorEnd : String -> AnimState -> Maybe Color
getBackgroundColorEnd elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.map .end
