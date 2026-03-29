module Anim.Engine.CSS.Keyframes exposing
    ( AnimState, AnimBuilder, AnimGroupName
    , init
    , attributes
    , styleNode, styleNodeFor, getElementKeyframes
    , animate
    , AnimMsg, update
    , CurrentTargetId, TargetId, AnimEvent(..)
    , events, eventsStopPropagation
    , TransformOrder(..), transformOrder
    , stop, reset, restart, pause, resume
    , delay
    , duration, speed
    , easing
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


# Types

@docs AnimState, AnimBuilder, AnimGroupName


# Initialize

@docs init


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

@docs CurrentTargetId, TargetId, AnimEvent


## Event Handlers

@docs events, eventsStopPropagation


# Transform Order

@docs TransformOrder, transformOrder


# Animation Control

@docs stop, reset, restart, pause, resume


# Playback Settings

@docs delay

@docs duration, speed

@docs easing

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
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Engine.Animation.CSS.CSS as InternalCSS exposing (ElementState(..))
import Anim.Internal.Engine.Animation.CSS.Keyframes as InternalKeyframes
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Translate as Translate
import Html
import Task



-- TYPES


{-| A type alias for animation group names.

Used to identify which animation group to target in functions like
[attributes](#attributes), [isRunning](#isRunning), [stop](#stop), etc.

-}
type alias AnimGroupName =
    String


{-| The animation state type used to store animation configurations and keyframes.

Store it in your model.

    type alias Model =
        { animState : Keyframes.AnimState }

-}
type alias AnimState =
    InternalKeyframes.AnimState


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


{-| The ID of the element where the handler is attached.

If the element has no ID attribute, this will be an empty string.

-}
type alias CurrentTargetId =
    String


{-| The ID of the element that triggered the event.

If the element has no ID attribute, this will be an empty string.

This may be different from `CurrentTargetId` if the event bubbled up from a child element.

-}
type alias TargetId =
    String


{-| CSS keyframe animation lifecycle events.
-}
type AnimEvent
    = Started CurrentTargetId TargetId AnimGroupName
    | Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Iteration CurrentTargetId TargetId AnimGroupName
    | Paused CurrentTargetId TargetId AnimGroupName
    | Resumed CurrentTargetId TargetId AnimGroupName
    | Restarted CurrentTargetId TargetId AnimGroupName



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
    InternalKeyframes.init



-- TRIGGER


{-| Trigger animations.

    { model
        | animState =
            Keyframes.animate model.animState <|
                fadeIn
                    >> slideIn
    }

-}
animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate =
    InternalKeyframes.animate


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
transformOrder =
    Builder.transformOrder
        << List.map
            (\to ->
                case to of
                    Translate ->
                        Builder.Translate

                    Rotate ->
                        Builder.Rotate

                    Scale ->
                        Builder.Scale
            )



-- PLAYBACK SETTINGS


{-| Set the global delay in milliseconds.

    Keyframes.animate model.animState <|
        Keyframes.delay 500
            >> slideIn

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Builder.delay


{-| Set the global duration in milliseconds.

    Keyframes.animate model.animState <|
        Keyframes.duration 500
            >> slideIn

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Builder.duration


{-| Set the global speed in property units per second.

Consult each property's documentation for details on how speed is interpreted.

    Keyframes.animate model.animState <|
        Keyframes.speed 100
            >> slideIn

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    Builder.speed


{-| Set the global easing function.

    import Anim.Extra.Easing exposing (Easing(..))

    Keyframes.animate model.animState <|
        Keyframes.easing BounceOut
            >> slideIn

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalCSS.easing


{-| Set how many times an animation should repeat.

    Keyframes.animate model.animState <|
        Keyframes.iterations 3
            >> pulse

-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    Builder.iterations


{-| Make an animation loop infinitely.

    Keyframes.animate model.animState <|
        Keyframes.loopForever
            >> pulse

-}
loopForever : AnimBuilder -> AnimBuilder
loopForever =
    Builder.loopForever


{-| Make an animation alternate direction on each iteration (ping-pong effect).

    Keyframes.animate model.animState <|
        Keyframes.loopForever
            >> Keyframes.alternate
            >> pulse

This creates a smooth ping-pong animation.
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
attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes =
    InternalKeyframes.keyframesStyles


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
    InternalKeyframes.keyframesStyleNode


{-| Get a `<style>` node containing keyframes for a specific animation group.

    view model =
        div []
            [ Keyframes.styleNodeFor "animGroupName" animState
            , ...
            ]

If the element has no animations, this returns an empty text node.

-}
styleNodeFor : AnimGroupName -> AnimState -> Html.Html msg
styleNodeFor =
    InternalKeyframes.keyframesStyleNodeFor


{-| Get the raw generated CSS keyframes string for advanced use cases.

You probably want [styleNodeFor](#styleNodeFor) instead,
which handles creating the full `<style>` node for you.

-}
getElementKeyframes : AnimGroupName -> AnimState -> Maybe String
getElementKeyframes =
    InternalKeyframes.getKeyframes



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
    [ InternalKeyframes.onAnimationStartWithSource (\data -> toMsg (AnimMsg (InternalStarted data)))
    , InternalKeyframes.onAnimationEndWithSource (\data -> toMsg (AnimMsg (InternalEnded data)))
    , InternalKeyframes.onAnimationCancelWithSource (\data -> toMsg (AnimMsg (InternalCancelled data)))
    , InternalKeyframes.onAnimationIterationWithSource (\data -> toMsg (AnimMsg (InternalIteration data)))
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
    [ InternalKeyframes.onAnimationStartWithSourceStopPropagation (\data -> toMsg (AnimMsg (InternalStarted data)))
    , InternalKeyframes.onAnimationEndWithSourceStopPropagation (\data -> toMsg (AnimMsg (InternalEnded data)))
    , InternalKeyframes.onAnimationCancelWithSourceStopPropagation (\data -> toMsg (AnimMsg (InternalCancelled data)))
    , InternalKeyframes.onAnimationIterationWithSourceStopPropagation (\data -> toMsg (AnimMsg (InternalIteration data)))
    ]


{-| Handle animation lifecycle messages.

Returns the updated state and an [AnimEvent](#AnimEvent) for you to pattern match on.

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
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
stop : AnimGroupName -> AnimState -> AnimState
stop =
    InternalKeyframes.stopAnimation


{-| Reset an animation by instantly jumping back to its start state.

    Keyframes.reset "animGroup" model.animState

-}
reset : AnimGroupName -> AnimState -> AnimState
reset =
    InternalKeyframes.reset


{-| Restart an animation from the beginning.

    let
        ( newState, cmd ) =
            Keyframes.restart "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
restart : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart animGroupName toMsg animState =
    let
        newState =
            InternalKeyframes.restartAnimation animGroupName animState

        cmd =
            if InternalCSS.isRunning animGroupName animState |> Maybe.withDefault False then
                Task.succeed (toMsg (AnimMsg (InternalRestarted animGroupName)))
                    |> Task.perform identity

            else
                Cmd.none
    in
    ( newState, cmd )


{-| Pause a running animation.

    let
        ( newState, cmd ) =
            Keyframes.pause "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
pause : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
pause animGroupName toMsg animState =
    let
        newState =
            InternalKeyframes.pauseAnimation animGroupName animState

        cmd =
            if InternalCSS.isRunning animGroupName animState |> Maybe.withDefault False then
                Task.succeed (toMsg (AnimMsg (InternalPaused animGroupName)))
                    |> Task.perform identity

            else
                Cmd.none
    in
    ( newState, cmd )


{-| Resume a paused animation.

    let
        ( newState, cmd ) =
            Keyframes.resume "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
resume : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resume animGroupName toMsg animState =
    let
        newState =
            InternalKeyframes.resumeAnimation animGroupName animState

        cmd =
            if InternalCSS.isRunning animGroupName animState |> Maybe.withDefault False then
                Task.succeed (toMsg (AnimMsg (InternalResumed animGroupName)))
                    |> Task.perform identity

            else
                Cmd.none
    in
    ( newState, cmd )



-- STATE QUERIES


{-| Check if any animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : AnimState -> Maybe Bool
anyRunning =
    InternalCSS.anyRunning


{-| Check if a specific animation group is currently running.

Returns `Nothing` if there are no animations for the group.

-}
isRunning : AnimGroupName -> AnimState -> Maybe Bool
isRunning =
    InternalCSS.isRunning


{-| Check if a specific animation group has completed.

Returns `Nothing` if there are no animations for the group.

-}
isComplete : AnimGroupName -> AnimState -> Maybe Bool
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
getTranslateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart animGroupName animState =
    InternalCSS.getTranslateRange animGroupName animState
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
getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd animGroupName animState =
    InternalCSS.getTranslateRange animGroupName animState
        |> Maybe.map .end
        |> Maybe.map Translate.toRecord



-- SCALE GETTERS


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart animGroupName animState =
    InternalCSS.getScaleRange animGroupName animState
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
getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd animGroupName animState =
    InternalCSS.getScaleRange animGroupName animState
        |> Maybe.map (.end >> Scale.toRecord)



-- ROTATE GETTERS


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart animGroupName animState =
    InternalCSS.getRotateRange animGroupName animState
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
getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd animGroupName animState =
    InternalCSS.getRotateRange animGroupName animState
        |> Maybe.map (.end >> Rotate.toRecord)



-- OPACITY GETTERS


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityStart : AnimGroupName -> AnimState -> Maybe Float
getOpacityStart animGroupName animState =
    InternalCSS.getOpacityRange animGroupName animState
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
getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd animGroupName animState =
    InternalCSS.getOpacityRange animGroupName animState
        |> Maybe.map (.end >> Opacity.toFloat)



-- SIZE GETTERS


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeStart : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart animGroupName animState =
    InternalCSS.getSizeRange animGroupName animState
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
getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd animGroupName animState =
    InternalCSS.getSizeRange animGroupName animState
        |> Maybe.map (.end >> Size.toRecord)



-- BACKGROUND COLOR GETTERS


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorStart : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorStart animGroupName animState =
    InternalCSS.getBackgroundColorRange animGroupName animState
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
getBackgroundColorEnd : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorEnd animGroupName animState =
    InternalCSS.getBackgroundColorRange animGroupName animState
        |> Maybe.map .end
