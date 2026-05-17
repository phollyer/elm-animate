module Anim.Engine.Keyframe exposing
    ( AnimState, AnimGroupName
    , AnimBuilder
    , TimelineBuilder
    , EngineBuilder
    , init
    , animate, retarget
    , CurrentTargetId, TargetId, AnimEvent(..)
    , AnimMsg, update
    , attributes
    , styleNode, styleNodeFor, maybeString
    , events, eventsStopPropagation
    , iterations, loopForever, alternate
    , delay, duration, speed
    , easing
    , spring
    , stop, reset, restart, pause, resume
    , discreteEntry, discreteExit
    , transformOrder
    , anyRunning, isRunning, allComplete, isComplete, isCancelled
    , getPropertyEnd, getPropertyRange, getPropertyStart
    , getColorPropertyEnd, getColorPropertyRange, getColorPropertyStart
    , getOpacityStart, getOpacityEnd, getOpacityRange
    , getPerspectiveOriginStart, getPerspectiveOriginEnd, getPerspectiveOriginRange
    , getRotateStart, getRotateEnd, getRotateRange
    , getScaleStart, getScaleEnd, getScaleRange
    , getSizeStart, getSizeEnd, getSizeRange
    , getSkewEnd, getSkewRange, getSkewStart
    , getTranslateStart, getTranslateEnd, getTranslateRange
    )

{-| Run native CSS Keyframe animations.

For specific Engine guides and examples, see the
[Keyframe Engine Documentation](https://phollyer.github.io/elm-motion/animation/engines/keyframes/).

For Engine comparisons, shared features, examples and code, see the
[Engine Overview](https://phollyer.github.io/elm-motion/animation/engines/overview/) section in the docs.


# Types

@docs AnimState, AnimGroupName


## Builders

@docs AnimBuilder


### Timeline Builder

This Engine uses the browser's Document timeline, along with the Transition, Sub, and WAAPI Engines.

Use the `TimelineBuilder` to configure animations that run on the Document timeline only. If any Engines
are used that don't run on the Document timeline (e.g., Scroll or View), you'll get a type error.

@docs TimelineBuilder


### Engine Builder

The `EngineBuilder` is a builder type restricted to the Keyframe Engine.

Use the `EngineBuilder` when you want to restrict helpers to the Keyframe Engine, such as any that rely
on Keyframe-only APIs.

@docs EngineBuilder


# Initialize

@docs init

📖 See [Initialize](https://phollyer.github.io/elm-motion/animation/workflow/init/) in the docs.


# Trigger

@docs animate, retarget

📖 See [Triggering Animations](https://phollyer.github.io/elm-motion/animation/workflow/trigger/) in the docs.


# Events

@docs CurrentTargetId, TargetId, AnimEvent

📖 See [Event Reference](https://phollyer.github.io/elm-motion/animation/workflow/react/#event-reference) in the docs.


# Update

@docs AnimMsg, update

📖 See [React](https://phollyer.github.io/elm-motion/animation/workflow/react/) in the docs.


# View

To render a CSS keyframe animation, you need to apply the animation `attributes` to your element
and include a `<style>` node with the generated keyframes.

@docs attributes

@docs styleNode, styleNodeFor, maybeString

📖 See [Render](https://phollyer.github.io/elm-motion/animation/workflow/render/) and
[Keyframe Style Node](https://phollyer.github.io/elm-motion/animation/engines/keyframes/#keyframes-style-node) in the docs.


# Event Listeners

@docs events, eventsStopPropagation

📖 See [Events](https://phollyer.github.io/elm-motion/animation/engines/keyframes/#events) in the docs.


# Playback

@docs iterations, loopForever, alternate


# Timing

@docs delay, duration, speed

📖 See [Timing](https://phollyer.github.io/elm-motion/animation/concepts/timing/) in the docs.


# Easing

@docs easing

📖 See [Easing](https://phollyer.github.io/elm-motion/animation/concepts/easing/) in the docs.


# Spring

@docs spring


# Animation Control

@docs stop, reset, restart, pause, resume

📖 See [Controlling Animations](https://phollyer.github.io/elm-motion/animation/concepts/controlling-animations/) in the docs.


# Discrete Properties

@docs discreteEntry, discreteExit

📖 See [Discrete Properties](https://phollyer.github.io/elm-motion/animation/concepts/discrete-properties/) in the docs.


# Transform Order

@docs transformOrder

📖 See [Transform Ordering](https://phollyer.github.io/elm-motion/animation/concepts/transform-order/) in the docs.


# State Queries

@docs anyRunning, isRunning, allComplete, isComplete, isCancelled

📖 See [State Queries](https://phollyer.github.io/elm-motion/animation/engines/keyframes/#state-queries) in the docs.


# Property Queries

📖 See [Property Queries](https://phollyer.github.io/elm-motion/animation/engines/keyframes/#property-queries) and
[Properties](https://phollyer.github.io/elm-motion/animation/properties/getting-started/) in the docs.


## Custom Properties

@docs getPropertyEnd, getPropertyRange, getPropertyStart


## Custom Color Properties

@docs getColorPropertyEnd, getColorPropertyRange, getColorPropertyStart


## Opacity

@docs getOpacityStart, getOpacityEnd, getOpacityRange


## Perspective Origin

@docs getPerspectiveOriginStart, getPerspectiveOriginEnd, getPerspectiveOriginRange


## Rotate

@docs getRotateStart, getRotateEnd, getRotateRange


## Scale

@docs getScaleStart, getScaleEnd, getScaleRange


## Size

@docs getSizeStart, getSizeEnd, getSizeRange


## Skew

@docs getSkewEnd, getSkewRange, getSkewStart


## Translate

@docs getTranslateStart, getTranslateEnd, getTranslateRange

-}

import Anim.Extra.Color exposing (Color)
import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.CSS.CSS as CSS
import Anim.Internal.Engine.Keyframe as Internal
import Anim.Internal.Engine.Keyframe.AnimGroup as AnimGroup
import Html
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| The animation state type used to store animation configurations and keyframes.

Store it in your model.

    type alias Model =
        { animState : Keyframe.AnimState }

-}
type alias AnimState =
    Internal.AnimState


{-| Type alias for the base [AnimBuilder](Anim.Builder#AnimBuilder) type.
-}
type alias AnimBuilder mode =
    CSS.AnimBuilder mode


{-| A type alias for animation group names.

Used to identify which animation group to target.

-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `TimelineBuilder` type.

This generic timeline builder works with any engine that uses the same timeline,
but will result in a type error if used with an Engine that does not.

    f : Keyframe.TimelineBuilder engine -> Keyframe.TimelineBuilder engine

Here's an engine-specific timeline builder for the Keyframe Engine. It will result in a type error if used with any other engine.

    f : Keyframe.TimelineBuilder ForKeyframeEngine -> Keyframe.TimelineBuilder ForKeyframeEngine

For mode restrictions and examples, see
[Build: Builder Modes](https://phollyer.github.io/elm-motion/animation/workflow/build/#builder-modes).

-}
type alias TimelineBuilder engine =
    Internal.TimelineBuilder engine


{-| Type alias for the internal `EngineBuilder` type.

This engine-specific builder will result in a type error if used with any other engine.

    f : Keyframe.EngineBuilder -> Keyframe.EngineBuilder

For mode restrictions and examples, see
[Build: Builder Modes](https://phollyer.github.io/elm-motion/animation/workflow/build/#builder-modes).

-}
type alias EngineBuilder =
    Internal.EngineBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Initialize animation state with optional property initializers.

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Opacity as Opacity
    import Anim.Property.Translate as Translate

    -- Empty state
    Keyframe.init []

    -- With initial properties
    Keyframe.init
        [ Translate.initXY "animGroupName" 100 50
        , Opacity.init "animGroupName" 0.5
        ]

-}
init : List (EngineBuilder -> EngineBuilder) -> AnimState
init =
    Internal.init



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Trigger animations.

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Opacity as Opacity
    import Anim.Property.Translate as Translate

    { model
        | animState =
            Keyframe.animate model.animState <|
                Opacity.for "box"
                    >> Opacity.to 1
                    >> Opacity.build
                    >> Translate.for "box"
                    >> Translate.toX 0
                    >> Translate.build
    }

-}
animate : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
animate =
    Internal.animate


{-| Re-anchor an animation to a new target by snapping to the new end values.

The Keyframe engine has no JavaScript-side runtime snapshot of the
currently rendered values - it only knows the previous _target_, not where
the element actually is on screen. That makes it impossible to smoothly
continue an in-flight keyframe animation when the target changes
mid-flight (the typical resize-handler case).

`retarget` therefore guarantees a deterministic outcome: the freshly
computed end values are written inline, the keyframe animation is
cleared, and the group is marked complete. It's safe to call repeatedly
during a drag or resize without accumulating partial animations or visual
glitches.

The Sub and WAAPI engines provide a `retarget` with the same builder API
that smoothly continues from the current rendered position - swap in
those engines if you need visual continuity instead of a snap.

-}
retarget : AnimState -> (EngineBuilder -> EngineBuilder) -> AnimState
retarget =
    Internal.retarget



-- ============================================================
-- EVENTS
-- ============================================================


{-| The ID of the element where the handler is attached.

Returns `Nothing` if the element has no ID attribute.

-}
type alias CurrentTargetId =
    Maybe String


{-| The ID of the element that triggered the event.

Returns `Nothing` if the element has no ID attribute.

This may be different from `CurrentTargetId` if the event bubbled up from a child element.

-}
type alias TargetId =
    Maybe String


{-| CSS keyframe animation lifecycle events.
-}
type AnimEvent
    = Started CurrentTargetId TargetId AnimGroupName
    | Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Iteration CurrentTargetId TargetId AnimGroupName Int
    | Paused AnimGroupName
    | Resumed AnimGroupName
    | Restarted AnimGroupName



-- ============================================================
-- UPDATE
-- ============================================================


{-| Internal message type.

    import Anim.Engine.Keyframe as Keyframe

    type Msg
        = KeyframeMsg Keyframe.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Handle animation lifecycle messages.

Returns the updated state and an [AnimEvent](#AnimEvent) for you to pattern match on.

    import Anim.Engine.Keyframe as Keyframe

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            KeyframeMsg animMsg ->
                let
                    ( animState, event ) =
                        Keyframe.update animMsg model.animState
                in
                handleAnimationEvent event { model | animState = animState }

    handleAnimationEvent : Keyframe.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            ...

-}
update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update msg =
    Internal.update msg
        >> Tuple.mapSecond toAnimEvent


toAnimEvent : Internal.AnimEvent -> AnimEvent
toAnimEvent event =
    case event of
        Internal.Started currentTargetId targetId animGroup ->
            Started currentTargetId targetId animGroup

        Internal.Ended currentTargetId targetId animGroup ->
            Ended currentTargetId targetId animGroup

        Internal.Cancelled currentTargetId targetId animGroup ->
            Cancelled currentTargetId targetId animGroup

        Internal.Iteration currentTargetId targetId animGroup iteration ->
            Iteration currentTargetId targetId animGroup iteration

        Internal.Paused animGroup ->
            Paused animGroup

        Internal.Resumed animGroup ->
            Resumed animGroup

        Internal.Restarted animGroup ->
            Restarted animGroup



-- ============================================================
-- VIEW
-- ============================================================


{-| Apply the animation `attributes` to your element.

    import Anim.Engine.Keyframe as Keyframe
    import Html exposing (div, text)

    div
        (Keyframe.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes =
    Internal.attributes


{-| Get a `<style>` node containing the keyframes for all animations.

    import Anim.Engine.Keyframe as Keyframe
    import Html exposing (div)

    view model =
        div []
            [ Keyframe.styleNode animState
            , ...
            ]

If there are no animations, this returns an empty text node.

-}
styleNode : AnimState -> Html.Html msg
styleNode =
    Internal.styleNode


{-| Get a `<style>` node containing keyframes for a specific animation group.

    import Anim.Engine.Keyframe as Keyframe
    import Html exposing (div)

    view model =
        div []
            [ Keyframe.styleNodeFor "animGroupName" animState
            , ...
            ]

If there are no animations, this returns an empty text node.

-}
styleNodeFor : AnimGroupName -> AnimState -> Html.Html msg
styleNodeFor =
    Internal.styleNodeFor


{-| Get the raw generated CSS keyframes string for advanced use cases.

You probably want [styleNodeFor](#styleNodeFor) instead,
which handles creating the full `<style>` node for you.

-}
maybeString : AnimGroupName -> AnimState -> Maybe String
maybeString =
    Internal.maybeKeyframesString



-- ============================================================
-- EVENT LISTENERS
-- ============================================================


{-| Receive keyframe animation lifecycle events.

Add `events` to your element with a message constructor that wraps `AnimMsg`.

    import Anim.Engine.Keyframe as Keyframe
    import Html exposing (div, text)

    type Msg
        = KeyframeMsg Keyframe.AnimMsg

    div
        (Keyframe.attributes "animGroupName" animState
            ++ Keyframe.events "animGroupName" KeyframeMsg
        )
        [ text "Animating element" ]

-}
events : (AnimMsg -> msg) -> List (Html.Attribute msg)
events =
    Internal.events


{-| The same as [events](#events) but with propagation stopped.

    import Anim.Engine.Keyframe as Keyframe
    import Html exposing (div, text)

    div
        (Keyframe.attributes "myElement" model.animState
            ++ Keyframe.eventsStopPropagation "myElement" KeyframeMsg
        )
        [ text "Animated element" ]

-}
eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation =
    Internal.eventsStopPropagation



-- ============================================================
-- PLAYBACK
-- ============================================================


{-| Set how many times an animation should repeat.

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Opacity as Opacity

    pulse : Keyframe.TimelineBuilder -> Keyframe.TimelineBuilder
    pulse =
        Opacity.for "box"
            >> Opacity.to 0.2
            >> Opacity.build

    Keyframe.animate model.animState <|
        Keyframe.iterations 3
            >> pulse

-}
iterations : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
iterations =
    CSS.iterations


{-| Make an animation loop infinitely.

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Opacity as Opacity

    pulse : Keyframe.TimelineBuilder -> Keyframe.TimelineBuilder
    pulse =
        Opacity.for "box"
            >> Opacity.to 0.2
            >> Opacity.build

    Keyframe.animate model.animState <|
        Keyframe.loopForever
            >> pulse

-}
loopForever : Builder.AnimBuilder mode -> Builder.AnimBuilder mode
loopForever =
    CSS.loopForever


{-| Make an animation alternate direction on each iteration (ping-pong effect).

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Opacity as Opacity

    pulse : Keyframe.TimelineBuilder -> Keyframe.TimelineBuilder
    pulse =
        Opacity.for "box"
            >> Opacity.to 0.2
            >> Opacity.build

    Keyframe.animate model.animState <|
        Keyframe.loopForever
            >> Keyframe.alternate
            >> pulse

This creates a smooth ping-pong animation.
The animation plays forward, then backward, then forward, etc.

-}
alternate : Builder.AnimBuilder mode -> Builder.AnimBuilder mode
alternate =
    CSS.alternate



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay for all animations.

This will be inherited by all animations that
don't define their own delay.

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Custom as Custom

    Keyframe.animate model.animState <|
        Keyframe.delay 500
            >> Custom.for "box" (Custom.BorderRadius "px")
            >> Custom.to 24
            >> Custom.build

-}
delay : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
delay =
    CSS.delay


{-| Set the duration of all animations.

This will be inherited by all animations that
don't define their own duration.

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Custom as Custom

    Keyframe.animate model.animState <|
        Keyframe.duration 500
            >> Custom.for "box" (Custom.BorderRadius "px")
            >> Custom.to 24
            >> Custom.build

-}
duration : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
duration =
    CSS.duration


{-| Set the speed that animations should run at.

This will be inherited by all animations that
don't define their own speed.

Consult each property's documentation for details on how speed is interpreted.

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Custom as Custom

    Keyframe.animate model.animState <|
        Keyframe.speed 100
            >> Custom.for "box" (Custom.BorderRadius "px")
            >> Custom.to 24
            >> Custom.build

-}
speed : Float -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
speed =
    CSS.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function to be used by all animations.

This will be inherited by all animations that
don't define their own easing.

    import Easing exposing (Easing(..))
    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Custom as Custom

    Keyframe.animate model.animState <|
        Keyframe.easing BounceOut
            >> Custom.for "box" (Custom.BorderRadius "px")
            >> Custom.to 24
            >> Custom.build

-}
easing : Easing -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
easing =
    CSS.easing



-- ============================================================
-- SPRING
-- ============================================================


{-| Set a spring as the default for all animations in this builder.

Will be inherited by any property that doesn't define its own spring
or easing. Setting `spring` clears any previously-set global `easing`,
and vice versa — they are mutually exclusive.

Spring-driven motion has _emergent_ duration: the motion ends when
the value has settled at the target. Per-property `duration` and
`speed` are ignored when a spring is in effect; `delay` is honoured.

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Translate as Translate
    import Motion.Spring as Spring

    Keyframe.animate model.animState <|
        Keyframe.spring Spring.wobbly
            >> Translate.for "box"
            >> Translate.toX 200
            >> Translate.build

-}
spring : Spring -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
spring =
    CSS.spring



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


{-| Stop a running animation by instantly jumping to its end state.

    import Anim.Engine.Keyframe as Keyframe

    Keyframe.stop "animGroup" model.animState

-}
stop : AnimGroupName -> AnimState -> AnimState
stop =
    Internal.stop


{-| Reset an animation by instantly jumping back to its start state.

    import Anim.Engine.Keyframe as Keyframe

    Keyframe.reset "animGroup" model.animState

-}
reset : AnimGroupName -> AnimState -> AnimState
reset =
    Internal.reset


{-| Restart an animation from the beginning.

    import Anim.Engine.Keyframe as Keyframe

    let
        ( newState, cmd ) =
            Keyframe.restart "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
restart : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart =
    Internal.restart


{-| Pause a running animation.

    import Anim.Engine.Keyframe as Keyframe

    let
        ( newState, cmd ) =
            Keyframe.pause "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
pause : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
pause =
    Internal.pause


{-| Resume a paused animation.

    import Anim.Engine.Keyframe as Keyframe

    let
        ( newState, cmd ) =
            Keyframe.resume "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
resume : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resume =
    Internal.resume



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


{-| Add a discrete CSS property for entry animations.

The value is applied at every step of the animation, ensuring the element is
immediately in the target state when the animation starts. The browser already
knows the element's pre-animation state from its own CSS.

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Opacity as Opacity

    Keyframe.animate model.animState <|
        Keyframe.discreteEntry "display" "block"
            >> Keyframe.discreteEntry "pointer-events" "auto"
            >> Opacity.for "box"
            >> Opacity.to 1
            >> Opacity.build

-}
discreteEntry : String -> String -> EngineBuilder -> EngineBuilder
discreteEntry =
    CSS.discreteEntry


{-| Add a discrete CSS property for exit animations.

Exit animations need to hold their initial state
until the very end of the animation, at which point they flip to the final state.

Therefore you need to set both the `from` and `to` values for the property.

Use when an element is disappearing (e.g., going from
`display: block` to `display: none`).

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Property.Opacity as Opacity

    Keyframe.animate model.animState <|
        Keyframe.discreteExit "display" "block" "none"
            >> Opacity.for "box"
            >> Opacity.to 0
            >> Opacity.build

-}
discreteExit : String -> String -> String -> EngineBuilder -> EngineBuilder
discreteExit =
    CSS.discreteExit



-- ============================================================
-- TRANSFORM ORDER
-- ============================================================


{-| Set the transform order.

The transform order specifies how translate, rotate, skew and scale transforms
are combined. Start the list with the transform to apply first.

Any missing transforms are automatically appended in the default order
(Translate → Rotate → Skew → Scale).

    import Anim.Engine.Keyframe as Keyframe
    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    Keyframe.transformOrder [ Scale, Rotate, Translate, Skew ]

-}
transformOrder : List TransformProperty -> EngineBuilder -> EngineBuilder
transformOrder =
    Internal.transformOrder



-- ============================================================
-- STATE QUERIES
-- ============================================================


{-| Check if any animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : AnimState -> Maybe Bool
anyRunning =
    CSS.anyRunning AnimGroup.isRunning


{-| Check if a specific animation group is currently running.

Returns `Nothing` if there are no animations for the group.

-}
isRunning : AnimGroupName -> AnimState -> Maybe Bool
isRunning =
    CSS.isRunning AnimGroup.isRunning


{-| Check if a specific animation group has completed.

Returns `Nothing` if there are no animations for the group.

-}
isComplete : AnimGroupName -> AnimState -> Maybe Bool
isComplete =
    CSS.isComplete AnimGroup.isComplete


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    CSS.allComplete AnimGroup.isComplete


{-| Check if a specific animation group was cancelled.

Returns `Nothing` if there are no animations for the group.

-}
isCancelled : AnimGroupName -> AnimState -> Maybe Bool
isCancelled =
    CSS.isCancelled AnimGroup.isCancelled



-- ============================================================
-- PROPERTY QUERIES
-- ============================================================
--
--
-- ============================
-- CUSTOM PROPERTY
-- ============================


{-| Get the custom property range (start and end) of an element being animated.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Float, end : Float }
getPropertyRange =
    CSS.getPropertyRange


{-| Get the start value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

Returns `Just 0` if no explicit start value was set, which is the default when no start value is set.

-}
getPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyStart =
    CSS.getPropertyStart


{-| Get the end value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyEnd =
    CSS.getPropertyEnd



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


{-| Get the custom color property range (start and end) of an element being animated.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange =
    CSS.getColorPropertyRange


{-| Get the start value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getColorPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyStart =
    CSS.getColorPropertyStart


{-| Get the end value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyEnd =
    CSS.getColorPropertyEnd



-- ============================
-- OPACITY
-- ============================


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getOpacityStart : AnimGroupName -> AnimState -> Maybe Float
getOpacityStart =
    CSS.getOpacityStart


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd =
    CSS.getOpacityEnd


{-| Get the opacity range (start and end) of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Float, end : Float }
getOpacityRange =
    CSS.getOpacityRange



-- ============================
-- PERSPECTIVE ORIGIN
-- ============================


{-| Get the start perspective origin of an element being animated.

Returns `Nothing` if the element has no perspective origin animation.

Returns `Just { x = 50, y = 50 }` if no explicit start value was set, which is the default when no start value is set.

-}
getPerspectiveOriginStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginStart =
    CSS.getPerspectiveOriginStart


{-| Get the end perspective origin of an element being animated.

Returns `Nothing` if the element has no perspective origin animation.

-}
getPerspectiveOriginEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getPerspectiveOriginEnd =
    CSS.getPerspectiveOriginEnd


{-| Get the perspective origin range (start and end) of an element being animated.

Returns `Nothing` if the element has no perspective origin animation.

-}
getPerspectiveOriginRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getPerspectiveOriginRange =
    CSS.getPerspectiveOriginRange



-- ============================
-- ROTATE
-- ============================


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getRotateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    CSS.getRotateStart


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    CSS.getRotateEnd


{-| Get the rotate range (start and end) of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange =
    CSS.getRotateRange



-- ============================
-- SCALE
-- ============================


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getScaleStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    CSS.getScaleStart


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    CSS.getScaleEnd


{-| Get the scale range (start and end) of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange =
    CSS.getScaleRange



-- ============================
-- SIZE
-- ============================


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSizeStart : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart =
    CSS.getSizeStart


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd =
    CSS.getSizeEnd


{-| Get the size range (start and end) of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange =
    CSS.getSizeRange



-- ============================
-- SKEW
-- ============================


{-| Get the start skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

Returns `Just { x = 0, y = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSkewStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewStart =
    CSS.getSkewStart


{-| Get the end skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewEnd =
    CSS.getSkewEnd


{-| Get the skew range (start and end) of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange =
    CSS.getSkewRange



-- ============================
-- TRANSLATE
-- ============================


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getTranslateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    CSS.getTranslateStart


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    CSS.getTranslateEnd


{-| Get the translate range (start and end) of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange =
    CSS.getTranslateRange
