module Anim.Engine.CSS.Keyframes exposing
    ( AnimState, init
    , attributes
    , styleNode, styleNodeFor, getElementKeyframes
    , AnimMsg, AnimEvent(..), update
    , events, eventsStopPropagation
    , onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel
    , onAnimationStartStopPropagation, onAnimationEndStopPropagation, onAnimationIterationStopPropagation, onAnimationCancelStopPropagation
    , AnimBuilder, animate, fireAndForget, TransformOrder(..), animateOrder, fireAndForgetOrder
    , duration, speed
    , easing
    , delay
    , iterations, loopForever, alternate
    , stop, reset, restart, pause, resume
    , pauseCmd, resumeCmd, restartCmd
    , anyRunning, isRunning, allComplete, isComplete
    , getBackgroundColorStart, getBackgroundColorEnd
    , getOpacityStart, getOpacityEnd
    , getRotateStart, getRotateEnd
    , getScaleStart, getScaleEnd
    , getSizeStart, getSizeEnd
    , getTranslateStart, getTranslateEnd
    )

{-| CSS Keyframe Animations engine for complex, multi-step animations.

CSS Keyframe Animations offer more control than transitions, allowing complex
multi-step animations with precise timing control.

**Use CSS Keyframes for:**

  - Complex, multi-step animations
  - Advanced easing curves (bounce, elastic, back)
  - Pause/resume functionality
  - Loop/iteration control
  - Better debugging visibility in DevTools

**Requirements:**

  - Must add a `<style>` node to the DOM with the generated keyframes
  - Use [keyframesStyleNode](#keyframesStyleNode) or [keyframesStyleNodeFor](#keyframesStyleNodeFor)


# State

@docs AnimState, init


# Apply Keyframe Animations

Keyframe animations require both styles on the element AND a `<style>` node in the DOM:

    import Anim.Engine.CSS.Keyframes as Keyframes

    view model =
        div []
            [ Keyframes.styleNode model.animState
            , div
                (Keyframes.attributes "animGroupName" model.animState)
                [ text "Animating element" ]
            ]

@docs attributes

@docs styleNode, styleNodeFor, getElementKeyframes


# Keyframe Animation Events

CSS keyframe animations trigger events at various stages of their lifecycle.
Use these events to keep your [AnimState](#AnimState) in sync.

@docs AnimMsg, AnimEvent, update

@docs events, eventsStopPropagation

For more granular control over which events to handle:

@docs onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel

To stop event propagation (for nested animated elements):

@docs onAnimationStartStopPropagation, onAnimationEndStopPropagation, onAnimationIterationStopPropagation, onAnimationCancelStopPropagation


# Execute

@docs AnimBuilder, animate, fireAndForget, TransformOrder, animateOrder, fireAndForgetOrder


# Default Settings


## Timing

@docs duration, speed


## Easing

@docs easing

**Note:** Keyframe animations bake easing into the keyframes themselves, enabling
accurate complex curves like bounce and elastic.


## Delay

@docs delay


## Iteration / Looping

Control how many times an animation repeats.

@docs iterations, loopForever, alternate


# Animation Control

@docs stop, reset, restart, pause, resume

@docs pauseCmd, resumeCmd, restartCmd


# Querying Animation State

@docs anyRunning, isRunning, allComplete, isComplete


# Querying Animated Properties

CSS animations do not provide direct access to mid-flight values.
However, this engine tracks start and end values, allowing you to query them.

For accurate mid-flight values, consider [Sub](Anim.Engine.Sub) or [WAAPI](Anim.Engine.WAAPI) engines.


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
import Html.Attributes
import Task



-- TYPES


{-| The animation state type used to store animation configurations and keyframes.

Both state-tracked and fire-and-forget animations produce an `AnimState`, but only
state-tracked animations require storing it in your model:

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
    = InternalStarted String
    | InternalEnded String
    | InternalCancelled String
    | InternalIteration String
    | InternalPaused String
    | InternalResumed String
    | InternalRestarted String


{-| CSS keyframe animation lifecycle events.

Returned by [update](#update) for you to pattern match and react to.

    handleAnimationEvent : Keyframes.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            Keyframes.Ended elementId ->
                -- Animation ended, trigger next step
                ( model, startNextAnimation )

            Keyframes.Iteration elementId ->
                -- Animation iteration completed (for looping animations)
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

-}
type AnimEvent
    = Started String
    | Ended String
    | Cancelled String
    | Iteration String
    | Paused String
    | Resumed String
    | Restarted String



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


{-| Apply the animation configuration with custom transform ordering.

    -- Custom transform order: Scale → Rotate → Translate
    Keyframes.animateOrder [ Scale, Rotate, Translate ] model.animState <|
        rotateLeft
            >> scaleUp
            >> moveRight

-}
animateOrder : List TransformOrder -> AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animateOrder order =
    let
        mapOrder xform =
            case xform of
                Translate ->
                    InternalCSS.Translate

                Rotate ->
                    InternalCSS.Rotate

                Scale ->
                    InternalCSS.Scale
    in
    InternalCSS.animateWithOrder (List.map mapOrder order)


{-| Create a fire-and-forget animation without state tracking.

    entranceAnimation : Keyframes.AnimState
    entranceAnimation =
        Keyframes.fireAndForget <|
            (fadeIn >> slideIn)

-}
fireAndForget : (AnimBuilder -> AnimBuilder) -> AnimState
fireAndForget =
    animate (init [])


{-| Create a fire-and-forget animation with custom transform ordering.
-}
fireAndForgetOrder : List TransformOrder -> (AnimBuilder -> AnimBuilder) -> AnimState
fireAndForgetOrder order =
    animateOrder order (init [])



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

    type Msg
        = KeyframeMsg Keyframes.AnimMsg

    div
        (Keyframes.attributes "animGroupName" animState
            ++ Keyframes.events "animGroupName" KeyframeMsg
        )
        [ text "Animating element" ]

-}
events : String -> (AnimMsg -> msg) -> List (Html.Attribute msg)
events elementId toMsg =
    List.map (Html.Attributes.map toMsg) <|
        [ onAnimationStart (AnimMsg (InternalStarted elementId))
        , onAnimationEnd (AnimMsg (InternalEnded elementId))
        , onAnimationCancel (AnimMsg (InternalCancelled elementId))
        , onAnimationIteration (AnimMsg (InternalIteration elementId))
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
            Keyframes.Ended elementId ->
                -- Animation ended
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

-}
update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update (AnimMsg animMsg) animState =
    case animMsg of
        InternalStarted elementId ->
            ( InternalCSS.handleEvent (InternalCSS.AnimationStarted elementId) animState
            , Started elementId
            )

        InternalEnded elementId ->
            ( InternalCSS.handleEvent (InternalCSS.AnimationEnded elementId) animState
            , Ended elementId
            )

        InternalCancelled elementId ->
            ( InternalCSS.handleEvent (InternalCSS.AnimationCancelled elementId) animState
            , Cancelled elementId
            )

        InternalIteration elementId ->
            ( InternalCSS.handleEvent (InternalCSS.AnimationIteration elementId) animState
            , Iteration elementId
            )

        InternalPaused elementId ->
            ( animState, Paused elementId )

        InternalResumed elementId ->
            ( animState, Resumed elementId )

        InternalRestarted elementId ->
            ( animState, Restarted elementId )


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
Use this to prevent events from bubbling up to parent elements with listeners.

    div
        (Keyframes.attributes "myElement" model.animState
            ++ Keyframes.eventsStopPropagation "myElement" KeyframeMsg
        )
        [ text "Animated element" ]

-}
eventsStopPropagation : String -> (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation elementId toMsg =
    List.map (Html.Attributes.map toMsg) <|
        [ onAnimationStartStopPropagation (AnimMsg (InternalStarted elementId))
        , onAnimationEndStopPropagation (AnimMsg (InternalEnded elementId))
        , onAnimationCancelStopPropagation (AnimMsg (InternalCancelled elementId))
        , onAnimationIterationStopPropagation (AnimMsg (InternalIteration elementId))
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

    Keyframes.restart "elementId" model.animState

-}
restart : String -> AnimState -> AnimState
restart =
    InternalCSS.restartAnimation


{-| Restart an animation and receive a `Restarted` event through `update`.

    let
        ( newState, cmd ) =
            Keyframes.restartCmd "elementId" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
restartCmd : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restartCmd elementId toMsg animState =
    ( InternalCSS.restartAnimation elementId animState
    , Task.succeed (toMsg (AnimMsg (InternalRestarted elementId)))
        |> Task.perform identity
    )


{-| Pause a running animation.

    Keyframes.pause "elementId" model.animState

-}
pause : String -> AnimState -> AnimState
pause =
    InternalCSS.pauseAnimation


{-| Pause an animation and receive a `Paused` event through `update`.

    let
        ( newState, cmd ) =
            Keyframes.pauseCmd "elementId" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
pauseCmd : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
pauseCmd elementId toMsg animState =
    ( InternalCSS.pauseAnimation elementId animState
    , Task.succeed (toMsg (AnimMsg (InternalPaused elementId)))
        |> Task.perform identity
    )


{-| Resume a paused animation.

    Keyframes.resume "elementId" model.animState

-}
resume : String -> AnimState -> AnimState
resume =
    InternalCSS.resumeAnimation


{-| Resume an animation and receive a `Resumed` event through `update`.

    let
        ( newState, cmd ) =
            Keyframes.resumeCmd "elementId" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
resumeCmd : String -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resumeCmd elementId toMsg animState =
    ( InternalCSS.resumeAnimation elementId animState
    , Task.succeed (toMsg (AnimMsg (InternalResumed elementId)))
        |> Task.perform identity
    )



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
