module Anim.Engine.CSS.Keyframe exposing
    ( AnimState, AnimBuilder
    , init
    , attributes
    , styleNode, styleNodeFor
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
    , AnimGroup, maybeString
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
import Anim.Internal.Engine.Animation.CSS.CSS as CSS
import Anim.Internal.Engine.Animation.CSS.Keyframe as Keyframe
import Html



{- **** MODEL **** -}


{-| The animation state type used to store animation configurations and keyframes.

Store it in your model.

    type alias Model =
        { animState : Keyframes.AnimState }

-}
type alias AnimState =
    Keyframe.AnimState


{-| Animation builder type for configuring animations.
-}
type alias AnimBuilder =
    CSS.AnimBuilder


{-| A type alias for animation group names.

Used to identify which animation group to target in functions like
[attributes](#attributes), [isRunning](#isRunning), [stop](#stop), etc.

-}
type alias AnimGroup =
    String



{- **** INITIALIZE **** -}


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
    Keyframe.init



{- **** TRIGGER **** -}


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
    Keyframe.animate



{- **** EVENTS **** -}


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
    = Started CurrentTargetId TargetId AnimGroup
    | Ended CurrentTargetId TargetId AnimGroup
    | Cancelled CurrentTargetId TargetId AnimGroup
    | Iteration CurrentTargetId TargetId AnimGroup Int
    | Paused CurrentTargetId TargetId AnimGroup
    | Resumed CurrentTargetId TargetId AnimGroup
    | Restarted CurrentTargetId TargetId AnimGroup



{- **** UPDATE **** -}


{-| Opaque message type.

    type Msg
        = KeyframeMsg Keyframes.AnimMsg
        | ...

-}
type alias AnimMsg =
    Keyframe.AnimMsg


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
update msg =
    Keyframe.update msg
        >> Tuple.mapSecond mapEvent


mapEvent : Keyframe.AnimEvent -> AnimEvent
mapEvent event =
    case event of
        Keyframe.Started currentTargetId targetId animGroup ->
            Started currentTargetId targetId animGroup

        Keyframe.Ended currentTargetId targetId animGroup ->
            Ended currentTargetId targetId animGroup

        Keyframe.Cancelled currentTargetId targetId animGroup ->
            Cancelled currentTargetId targetId animGroup

        Keyframe.Iteration currentTargetId targetId animGroup iteration ->
            Iteration currentTargetId targetId animGroup iteration

        Keyframe.Paused currentTargetId targetId animGroup ->
            Paused currentTargetId targetId animGroup

        Keyframe.Resumed currentTargetId targetId animGroup ->
            Resumed currentTargetId targetId animGroup

        Keyframe.Restarted currentTargetId targetId animGroup ->
            Restarted currentTargetId targetId animGroup



{- **** TRANSFORM ORDER **** -}


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



{- **** PLAYBACK SETTINGS **** -}


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
    CSS.easing


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



{- **** CONTROLS **** -}


{-| Stop a running animation by instantly jumping to its end state.

    Keyframes.stop "animGroup" model.animState

-}
stop : AnimGroup -> AnimState -> AnimState
stop =
    Keyframe.stop


{-| Reset an animation by instantly jumping back to its start state.

    Keyframes.reset "animGroup" model.animState

-}
reset : AnimGroup -> AnimState -> AnimState
reset =
    Keyframe.reset


{-| Restart an animation from the beginning.

    let
        ( newState, cmd ) =
            Keyframes.restart "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
restart : AnimGroup -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart =
    Keyframe.restart


{-| Pause a running animation.

    let
        ( newState, cmd ) =
            Keyframes.pause "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
pause : AnimGroup -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
pause =
    Keyframe.pause


{-| Resume a paused animation.

    let
        ( newState, cmd ) =
            Keyframes.resume "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
resume : AnimGroup -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resume =
    Keyframe.resume



{- **** VIEW **** -}


{-| Apply the animation attributes to your element.

    div
        (Keyframes.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroup -> AnimState -> List (Html.Attribute msg)
attributes =
    Keyframe.attributes


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
    Keyframe.styleNode


{-| Get a `<style>` node containing keyframes for a specific animation group.

    view model =
        div []
            [ Keyframes.styleNodeFor "animGroupName" animState
            , ...
            ]

If the element has no animations, this returns an empty text node.

-}
styleNodeFor : AnimGroup -> AnimState -> Html.Html msg
styleNodeFor =
    Keyframe.styleNodeFor


{-| Get the raw generated CSS keyframes string for advanced use cases.

You probably want [styleNodeFor](#styleNodeFor) instead,
which handles creating the full `<style>` node for you.

-}
maybeString : AnimGroup -> AnimState -> Maybe String
maybeString =
    Keyframe.maybeString



{- **** EVENT LISTENERS **** -}


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
events =
    Keyframe.events


{-| The same as [events](#events) but with propagation stopped.

    div
        (Keyframes.attributes "myElement" model.animState
            ++ Keyframes.eventsStopPropagation KeyframeMsg
        )
        [ text "Animated element" ]

-}
eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation =
    Keyframe.eventsStopPropagation



{- **** STATE QUERIES **** -}


{-| Check if any animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : AnimState -> Maybe Bool
anyRunning =
    CSS.anyRunning


{-| Check if a specific animation group is currently running.

Returns `Nothing` if there are no animations for the group.

-}
isRunning : AnimGroup -> AnimState -> Maybe Bool
isRunning =
    CSS.isRunning


{-| Check if a specific animation group has completed.

Returns `Nothing` if there are no animations for the group.

-}
isComplete : AnimGroup -> AnimState -> Maybe Bool
isComplete =
    CSS.isComplete


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    CSS.allComplete



{- **** PROPERTY QUERIES **** -}
--
--
-- BACKGROUND COLOR QUERIES


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorStart : AnimGroup -> AnimState -> Maybe Color
getBackgroundColorStart =
    CSS.getBackgroundColorStart


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorEnd : AnimGroup -> AnimState -> Maybe Color
getBackgroundColorEnd =
    CSS.getBackgroundColorEnd



-- OPACITY QUERIES


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityStart : AnimGroup -> AnimState -> Maybe Float
getOpacityStart =
    CSS.getOpacityStart


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroup -> AnimState -> Maybe Float
getOpacityEnd =
    CSS.getOpacityEnd



-- ROTATE QUERIES


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateStart : AnimGroup -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    CSS.getRotateStart


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroup -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    CSS.getRotateEnd



-- SCALE QUERIES


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleStart : AnimGroup -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    CSS.getScaleStart


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroup -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    CSS.getScaleEnd



-- SIZE QUERIES


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeStart : AnimGroup -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart =
    CSS.getSizeStart


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroup -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd =
    CSS.getSizeEnd



-- TRANSLATE QUERIES


{-| Get the start translate value of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateStart : AnimGroup -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    CSS.getTranslateStart


{-| Get the end translate value of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroup -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    CSS.getTranslateEnd
