module Anim.Engine.CSS.Keyframes exposing
    ( AnimState, AnimBuilder, init
    , attributes
    , styleNode, styleNodeFor, getElementKeyframes
    , animate
    , AnimMsg, update
    , AnimEvent(..)
    , events, eventsStopPropagation
    , TransformOrder(..), transformOrder
    , stop, reset, restart, pause, resume
    , duration, speed
    , easing
    , delay
    , iterations, loopForever, alternate
    , anyRunning, isRunning, allComplete, isComplete
    , getBackgroundColorStart, getBackgroundColorEnd
    , getOpacityStart, getOpacityEnd
    , getRotateStart, getRotateEnd
    , getScaleStart, getScaleEnd
    , getSizeStart, getSizeEnd
    , getTranslateStart, getTranslateEnd
    )

{-| Run native CSS Keyframe animations.

For detailed guides, examples, and engine comparisons, see the
[full documentation](https://phollyer.github.io/elm-animate/engines/keyframes/).


# Initialize

@docs AnimState, AnimBuilder, init


# Render

To render a CSS keyframe animation, you need to apply the animation attributes to your element
and include a `<style>` node with the generated keyframes.

@docs attributes

@docs styleNode, styleNodeFor, getElementKeyframes


# Trigger

@docs animate


# Update

@docs AnimMsg, update


# Anim Events

@docs AnimEvent


## Event Handlers

@docs events, eventsStopPropagation


# Transform Order

@docs TransformOrder, transformOrder


# Animation Control

@docs stop, reset, restart, pause, resume


# Playback Settings

@docs duration, speed

@docs easing

@docs delay

@docs iterations, loopForever, alternate


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


{-| Opaque message type.

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

Each event contains three `String` values:

  - `currentTargetId`: The HTML `id` attribute of the element where the handler is attached, or `""` if the handler is attached to an element without an `id`.
  - `targetId`: The HTML `id` attribute of the element that triggered the event, or `""` if the source element has no `id`. This may be different
    from `currentTargetId` if the event bubbled up from a child element.
  - `animGroup`: The animation group name passed to `Keyframes.attributes`.

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



-- TRIGGER


{-| Trigger animations.

    { model
        | animState =
            Keyframes.animate model.animState <|
                (fadeIn >> slideIn)
    }

-}
animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate =
    InternalCSS.animate


{-| Set the transform order.

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



-- BUILDER SETTINGS


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



-- RENDER


{-| Apply the animation attributes to your element.

    div
        (Keyframes.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : String -> AnimState -> List (Html.Attribute msg)
attributes =
    InternalCSS.keyframesStyles


{-| Get a `<style>` node containing the keyframes for all animations.

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


{-| Get a `<style>` node containing keyframes for a specific animation group.

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


{-| Receive keyframe animation lifecycle events.

Add `events` to your element with a message constructor that wraps `AnimMsg`.

    type Msg
        = KeyframeMsg Keyframes.AnimMsg

    div
        (Keyframes.attributes "animGroupName" animState
            ++ Keyframes.events KeyframeMsg
        )
        [ text "Animating element" ]

-}
events : (AnimMsg -> msg) -> List (Html.Attribute msg)
events toMsg =
    [ InternalCSS.onAnimationStartWithSource (\data -> toMsg (AnimMsg (InternalStarted data)))
    , InternalCSS.onAnimationEndWithSource (\data -> toMsg (AnimMsg (InternalEnded data)))
    , InternalCSS.onAnimationCancelWithSource (\data -> toMsg (AnimMsg (InternalCancelled data)))
    , InternalCSS.onAnimationIterationWithSource (\data -> toMsg (AnimMsg (InternalIteration data)))
    ]


{-| The same as [events](#events) but with propagation stopped.

    div
        (Keyframes.attributes "myElement" model.animState
            ++ Keyframes.eventsStopPropagation KeyframeMsg
        )
        [ text "Animated element" ]

-}
eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation toMsg =
    [ InternalCSS.onAnimationStartWithSourceStopPropagation (\data -> toMsg (AnimMsg (InternalStarted data)))
    , InternalCSS.onAnimationEndWithSourceStopPropagation (\data -> toMsg (AnimMsg (InternalEnded data)))
    , InternalCSS.onAnimationCancelWithSourceStopPropagation (\data -> toMsg (AnimMsg (InternalCancelled data)))
    , InternalCSS.onAnimationIterationWithSourceStopPropagation (\data -> toMsg (AnimMsg (InternalIteration data)))
    ]


{-| Handle animation lifecycle messages.

Returns the updated state and an [AnimEvent](#AnimEvent) for you to pattern match on.

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
            ...

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
            , Started (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )

        InternalEnded data ->
            ( InternalCSS.handleEvent (InternalCSS.AnimationEnded data.animGroup) animState
            , Ended (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )

        InternalCancelled data ->
            ( InternalCSS.handleEvent (InternalCSS.AnimationCancelled data.animGroup) animState
            , Cancelled (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )

        InternalIteration data ->
            ( InternalCSS.handleEvent (InternalCSS.AnimationIteration data.animGroup) animState
            , Iteration (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )

        InternalPaused animGroup ->
            ( animState, Paused "" "" animGroup )

        InternalResumed animGroup ->
            ( animState, Resumed "" "" animGroup )

        InternalRestarted animGroup ->
            ( animState, Restarted "" "" animGroup )



-- ANIMATION CONTROL


{-| Stop a running animation by instantly jumping to its end state.

    Keyframes.stop "animGroup" model.animState

-}
stop : String -> AnimState -> AnimState
stop =
    InternalCSS.stopAnimation


{-| Reset an animation by instantly jumping back to its start state.

    Keyframes.reset "animGroup" model.animState

-}
reset : String -> AnimState -> AnimState
reset =
    InternalCSS.reset


{-| Restart an animation from the beginning.

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
