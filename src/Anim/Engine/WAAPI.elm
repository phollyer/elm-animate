module Anim.Engine.WAAPI exposing
    ( AnimState, AnimGroupName
    , AnimBuilder
    , TimelineBuilder
    , EngineBuilder
    , init
    , animate, fireAndForget, retarget
    , AnimEvent(..)
    , AnimMsg, update
    , subscriptions
    , attributes
    , iterations, loopForever, alternate
    , delay, duration, speed
    , easing
    , spring
    , stop, reset, restart, pause, resume
    , discreteEntry, discreteExit
    , transformOrder
    , FreezeProperty, translate, rotate, scale, skew
    , freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ
    , unfreezeX, unfreezeY, unfreezeZ, unfreezeXY, unfreezeXZ, unfreezeYZ, unfreezeXYZ
    , anyRunning, isRunning, allComplete, isComplete, getProgress
    , getPropertyCurrent, getPropertyEnd, getPropertyRange, getPropertyStart
    , getColorPropertyCurrent, getColorPropertyEnd, getColorPropertyRange, getColorPropertyStart
    , getOpacityRange, getOpacityStart, getOpacityEnd, getOpacityCurrent
    , getRotateRange, getRotateStart, getRotateEnd, getRotateCurrent
    , getScaleRange, getScaleStart, getScaleEnd, getScaleCurrent
    , getSizeRange, getSizeStart, getSizeEnd, getSizeCurrent
    , getSkewRange, getSkewStart, getSkewEnd, getSkewCurrent
    , getTranslateRange, getTranslateStart, getTranslateEnd, getTranslateCurrent
    )

{-| Run animations using the Web Animations API via ports for maximum performance.

Requires the `@phollyer/elm-motion` JavaScript companion library.

For specific Engine guides, setup instructions, and examples, see the
[WAAPI Engine Documentation](https://phollyer.github.io/elm-motion/animation/engines/waapi/).

For Engine comparisons, shared features, examples and code, see the
[Engine Overview](https://phollyer.github.io/elm-motion/animation/engines/overview/) section in the docs.


# Types

@docs AnimState, AnimGroupName


## Builders

@docs AnimBuilder


### Timeline Builder

This Engine uses the browser's Document timeline, along with the Keyframe, Sub, and Transition Engines.

Use the `TimelineBuilder` to configure animations that run on the Document timeline only. If any Engines
are used that don't run on the Document timeline (e.g., Scroll or View), you'll get a type error.

@docs TimelineBuilder


### Engine Builder

The `EngineBuilder` is a builder type restricted to the WAAPI Engine.

Use the `EngineBuilder` when you want to restrict helpers to the WAAPI Engine, such as any that rely
on WAAPI-only APIs.

@docs EngineBuilder


# Initialize

@docs init

📖 See [Initialize](https://phollyer.github.io/elm-motion/animation/workflow/init/) in the docs.


# Trigger

@docs animate, fireAndForget, retarget

📖 See [Triggering Animations](https://phollyer.github.io/elm-motion/animation/workflow/trigger/) in the docs.


# Events

@docs AnimEvent

📖 See [Event Reference](https://phollyer.github.io/elm-motion/animation/workflow/react/#event-reference) in the docs.


# Update

@docs AnimMsg, update

📖 See [React](https://phollyer.github.io/elm-motion/animation/workflow/react/) in the docs.


# Subscriptions

@docs subscriptions

📖 See [Subscriptions](https://phollyer.github.io/elm-motion/animation/engines/waapi/#subscriptions) in the docs.


# View

Apply `attributes` to your element to set its starting and end state as inline styles.

This ensures the element displays the correct property values before, during, and after the animation runs.

@docs attributes

📖 See [Render](https://phollyer.github.io/elm-motion/animation/workflow/render/) in the docs.


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


# Freeze

@docs FreezeProperty, translate, rotate, scale, skew

@docs freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ

📖 See [Interrupting Animations](https://phollyer.github.io/elm-motion/animation/concepts/interrupting-animations/) in the docs.


# Unfreeze

@docs unfreezeX, unfreezeY, unfreezeZ, unfreezeXY, unfreezeXZ, unfreezeYZ, unfreezeXYZ

📖 See [Interrupting Animations](https://phollyer.github.io/elm-motion/animation/concepts/interrupting-animations/) in the docs.


# State Queries

@docs anyRunning, isRunning, allComplete, isComplete, getProgress

📖 See [State Queries](https://phollyer.github.io/elm-motion/animation/engines/waapi/#state-queries) in the docs.


# Property Queries

📖 See [Property Queries](https://phollyer.github.io/elm-motion/animation/engines/waapi/#property-queries) and
[Properties](https://phollyer.github.io/elm-motion/animation/properties/getting-started/) in the docs.


## Custom Properties

@docs getPropertyCurrent, getPropertyEnd, getPropertyRange, getPropertyStart


## Custom Color Properties

@docs getColorPropertyCurrent, getColorPropertyEnd, getColorPropertyRange, getColorPropertyStart


## Opacity

@docs getOpacityRange, getOpacityStart, getOpacityEnd, getOpacityCurrent


## Rotate

@docs getRotateRange, getRotateStart, getRotateEnd, getRotateCurrent


## Scale

@docs getScaleRange, getScaleStart, getScaleEnd, getScaleCurrent


## Size

@docs getSizeRange, getSizeStart, getSizeEnd, getSizeCurrent


## Skew

@docs getSkewRange, getSkewStart, getSkewEnd, getSkewCurrent


## Translate

@docs getTranslateRange, getTranslateStart, getTranslateEnd, getTranslateCurrent

-}

import Anim.Extra.Color exposing (Color)
import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.WAAPI as Internal
import Html
import Json.Decode as Decode
import Json.Encode as Encode
import Motion.Easing exposing (Easing)
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| The animation state type used to store animation configurations.

Store it in your model.

The `msg` type parameter is your `Msg` type.

    type alias Model =
        { animState : WAAPI.AnimState Msg }

-}
type alias AnimState msg =
    Internal.AnimState msg


{-| Type alias for the base [AnimBuilder](Anim.Builder#AnimBuilder) type.
-}
type alias AnimBuilder mode =
    Internal.AnimBuilder mode


{-| A type alias for animation group names.

Used to identify which animation group to target.

-}
type alias AnimGroupName =
    String


{-| Type alias for the internal `TimelineBuilder` type.

This generic timeline builder works with any engine that uses the same timeline,
but will result in a type error if used with an Engine that does not.

    f : WAAPI.TimelineBuilder engine -> WAAPI.TimelineBuilder engine

Here's an engine-specific timeline builder for the WAAPI Engine. It will result in a type error if used with any other engine.

    f : WAAPI.TimelineBuilder ForWAAPIEngine -> WAAPI.TimelineBuilder ForWAAPIEngine

For mode restrictions and examples, see
[Build: Builder Modes](https://phollyer.github.io/elm-motion/animation/workflow/build/#builder-modes).

-}
type alias TimelineBuilder engine =
    Internal.TimelineBuilder engine


{-| Type alias for the internal `EngineBuilder` type.

This engine-specific builder will result in a type error if used with any other engine.

    f : WAAPI.EngineBuilder -> WAAPI.EngineBuilder

For mode restrictions and examples, see
[Build: Builder Modes](https://phollyer.github.io/elm-motion/animation/workflow/build/#builder-modes).

-}
type alias EngineBuilder =
    Internal.EngineBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Initialize animation state.

Takes the command port, event port, and optional property initializers:

    port motionCmd : Json.Encode.Value -> Cmd msg

    port motionMsg : (Json.Decode.Value -> msg) -> Sub msg

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Opacity as Opacity
    import Anim.Property.Translate as Translate

    -- Basic initialization
    WAAPI.init motionCmd motionMsg []

    -- With initial properties
    WAAPI.init motionCmd
        motionMsg
        [ Translate.initXY "animGroupName" 100 50
        , Opacity.init "animGroupName" 1.0
        ]

-}
init : (Encode.Value -> Cmd msg) -> ((Decode.Value -> msg) -> Sub msg) -> List (EngineBuilder -> EngineBuilder) -> AnimState msg
init =
    Internal.init



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Trigger animations.

Returns the updated animation state and the command to send to JavaScript.

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Opacity as Opacity
    import Anim.Property.Translate as Translate

    let
        ( animState, animCmd ) =
            WAAPI.animate model.animState <|
                Opacity.for "box"
                    >> Opacity.to 1
                    >> Opacity.build
                    >> Translate.for "box"
                    >> Translate.toX 0
                    >> Translate.build
    in
    ( { model | animState = animState }, animCmd )

-}
animate : AnimState msg -> (EngineBuilder -> EngineBuilder) -> ( AnimState msg, Cmd msg )
animate =
    Internal.animate


{-| Continue an in-flight animation toward a new target without restarting it.

Works like [animate](#animate), but for any property the engine currently
reports as `Running`, [continueFor](Anim-Property-Translate#continueFor) will
inherit the in-flight timing (duration / speed / easing / delay) and use the
property's current animated value as the new `from` — producing smooth
retargeting instead of a fresh animation.

Idle properties fall back to `for`-style behaviour: they snap to the new
value rather than animating. This is the typical resize-handler pattern —
while the user is mid-drag the box keeps animating; once the resize stops,
the box snaps to its final position.

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Translate as Translate

    let
        ( animState, animCmd ) =
            WAAPI.retarget model.animState <|
                Translate.continueFor "box"
                    >> Translate.toX newX
                    >> Translate.build
    in
    ( { model | animState = animState }, animCmd )

-}
retarget : AnimState msg -> (EngineBuilder -> EngineBuilder) -> ( AnimState msg, Cmd msg )
retarget =
    Internal.retarget


{-| Execute a fire-and-forget animation without state tracking.

The animation runs entirely in the browser via the Web Animations API.

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Opacity as Opacity
    import Anim.Property.Translate as Translate
    import Json.Encode as Encode

    port motionCmd : Encode.Value -> Cmd msg

    WAAPI.fireAndForget motionCmd <|
        Opacity.for "box"
            >> Opacity.to 1
            >> Opacity.build
            >> Translate.for "box"
            >> Translate.toX 0
            >> Translate.build

For state management and continuity, use [animate](#animate) instead.

-}
fireAndForget : (Encode.Value -> Cmd msg) -> (EngineBuilder -> EngineBuilder) -> Cmd msg
fireAndForget =
    Internal.fireAndForget



-- ============================================================
-- EVENTS
-- ============================================================


{-| Animation lifecycle events from the Web Animations API.

Returned as a `Maybe` — `Nothing` indicates the message was not intended for this engine.

-}
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


{-| Internal message type.

    import Anim.Engine.WAAPI as WAAPI

    type Msg
        = WaapiMsg WAAPI.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Handle animation lifecycle messages.

Returns the updated state and an [AnimEvent](#AnimEvent) for you to pattern match on.

    import Anim.Engine.WAAPI as WAAPI

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            WaapiMsg animMsg ->
                let
                    ( animState, maybeAnimEvent ) =
                        WAAPI.update animMsg model.animState
                in
                handleAnimationEvent maybeAnimEvent { model | animState = animState }

    handleAnimationEvent : Maybe WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            ...

-}
update : AnimMsg -> AnimState msg -> ( AnimState msg, Maybe AnimEvent )
update msg =
    Internal.update msg
        >> Tuple.mapSecond (Maybe.map toAnimEvent)


toAnimEvent : Internal.AnimEvent -> AnimEvent
toAnimEvent internalEvent =
    case internalEvent of
        Internal.Started animGroup ->
            Started animGroup

        Internal.Ended animGroup ->
            Ended animGroup

        Internal.Cancelled animGroup progress ->
            Cancelled animGroup progress

        Internal.Restarted animGroup ->
            Restarted animGroup

        Internal.Paused animGroup progress ->
            Paused animGroup progress

        Internal.Resumed animGroup ->
            Resumed animGroup

        Internal.Iteration animGroup count ->
            Iteration animGroup count

        Internal.Progress animGroup progress ->
            Progress animGroup progress

        Internal.AnimError errorMsg ->
            AnimError errorMsg



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


{-| Subscribe to receive animation updates from JavaScript.

Without this, your app won't receive any animation events or updates.

    import Anim.Engine.WAAPI as WAAPI

    type Msg
        = WaapiMsg WAAPI.AnimMsg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions WaapiMsg model.animState

-}
subscriptions : (AnimMsg -> msg) -> AnimState msg -> Sub msg
subscriptions =
    Internal.subscriptions



-- ============================================================
-- VIEW
-- ============================================================


{-| Apply baseline and state styles to your element.

Sets the element's starting, current, and end property values as inline styles,
and adds the `data-anim-target` attribute so the JavaScript companion can locate
the element when the animation is triggered.

    import Anim.Engine.WAAPI as WAAPI
    import Html exposing (div, text)

    div
        (WAAPI.attributes "animGroupName" model.animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState msg -> List (Html.Attribute msg)
attributes =
    Internal.attributes



-- ============================================================
-- PLAYBACK
-- ============================================================


{-| Set how many times an animation should repeat.

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Opacity as Opacity

    pulse : WAAPI.EngineBuilder -> WAAPI.TimelineBuilder
    pulse =
        Opacity.for "box"
            >> Opacity.to 0.2
            >> Opacity.build

    WAAPI.animate model.animState <|
        WAAPI.iterations 3
            >> pulse

-}
iterations : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
iterations =
    Internal.iterations


{-| Make an animation loop infinitely.

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Opacity as Opacity

    pulse : WAAPI.EngineBuilder -> WAAPI.TimelineBuilder
    pulse =
        Opacity.for "box"
            >> Opacity.to 0.2
            >> Opacity.build

    WAAPI.animate model.animState <|
        WAAPI.loopForever
            >> pulse

-}
loopForever : Builder.AnimBuilder mode -> Builder.AnimBuilder mode
loopForever =
    Internal.loopForever


{-| Make an animation alternate direction on each iteration (ping-pong effect).

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Opacity as Opacity

    pulse : WAAPI.EngineBuilder -> WAAPI.TimelineBuilder
    pulse =
        Opacity.for "box"
            >> Opacity.to 0.2
            >> Opacity.build

    WAAPI.animate model.animState <|
        WAAPI.loopForever
            >> WAAPI.alternate
            >> pulse

This creates a smooth ping-pong animation.
The animation plays forward, then backward, then forward, etc.

-}
alternate : Builder.AnimBuilder mode -> Builder.AnimBuilder mode
alternate =
    Internal.alternate



-- ============================================================
-- TIMING
-- ============================================================


{-| Set the delay for all animations.

This will be inherited by all animations that
don't define their own delay.

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Custom as Custom

    WAAPI.animate model.animState <|
        WAAPI.delay 500
            >> Custom.for "box" (Custom.BorderRadius "px")
            >> Custom.to 24
            >> Custom.build

-}
delay : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
delay =
    Internal.delay


{-| Set the duration of all animations.

This will be inherited by all animations that
don't define their own duration.

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Custom as Custom

    WAAPI.animate model.animState <|
        WAAPI.duration 1000
            >> Custom.for "box" (Custom.BorderRadius "px")
            >> Custom.to 24
            >> Custom.build

-}
duration : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
duration =
    Internal.duration


{-| Set the speed that animations should run at.

This will be inherited by all animations that
don't define their own speed.

Consult each property's documentation for details on how speed is interpreted.

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Custom as Custom

    WAAPI.animate model.animState <|
        WAAPI.speed 100
            >> Custom.for "box" (Custom.BorderRadius "px")
            >> Custom.to 24
            >> Custom.build

-}
speed : Float -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
speed =
    Internal.speed



-- ============================================================
-- EASING
-- ============================================================


{-| Set the easing function to be used by all animations.

This will be inherited by all animations that
don't define their own easing.

    import Easing exposing (Easing(..))
    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Custom as Custom

    WAAPI.animate model.animState <|
        WAAPI.easing BounceOut
            >> Custom.for "box" (Custom.BorderRadius "px")
            >> Custom.to 24
            >> Custom.build

-}
easing : Easing -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
easing =
    Internal.easing



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

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Translate as Translate
    import Motion.Spring as Spring

    WAAPI.animate model.animState <|
        WAAPI.spring Spring.wobbly
            >> Translate.for "box"
            >> Translate.toX 200
            >> Translate.build

-}
spring : Spring -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
spring =
    Internal.spring



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


{-| Stop a running animation by instantly jumping to its end state.

    import Anim.Engine.WAAPI as WAAPI

    let
        ( animState, stopCmd ) =
            WAAPI.stop "animGroup" model.animState
    in
    ( { model | animState = animState }, stopCmd )

-}
stop : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
stop =
    Internal.stop


{-| Reset an animation by instantly jumping back to its start state.

    import Anim.Engine.WAAPI as WAAPI

    let
        ( animState, resetCmd ) =
            WAAPI.reset "animGroup" model.animState
    in
    ( { model | animState = animState }, resetCmd )

-}
reset : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
reset =
    Internal.reset


{-| Restart an animation from the beginning.

    import Anim.Engine.WAAPI as WAAPI

    let
        ( animState, restartCmd ) =
            WAAPI.restart "animGroup" model.animState
    in
    ( { model | animState = animState }, restartCmd )

-}
restart : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
restart =
    Internal.restart


{-| Pause a running animation.

    import Anim.Engine.WAAPI as WAAPI

    let
        ( animState, pauseCmd ) =
            WAAPI.pause "animGroup" model.animState
    in
    ( { model | animState = animState }, pauseCmd )

-}
pause : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
pause =
    Internal.pause


{-| Resume a paused animation.

    import Anim.Engine.WAAPI as WAAPI

    let
        ( animState, resumeCmd ) =
            WAAPI.resume "animGroup" model.animState
    in
    ( { model | animState = animState }, resumeCmd )

-}
resume : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
resume =
    Internal.resume



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


{-| Add a discrete CSS property for entry animations.

The value is applied as an inline style from the first frame and held throughout
the animation. Use this when an element is appearing (e.g., going from
`display: none` to `display: block`).

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Opacity as Opacity

    WAAPI.animate model.animState <|
        WAAPI.discreteEntry "display" "block"
            >> WAAPI.discreteEntry "visibility" "visible"
            >> Opacity.for "box"
            >> Opacity.to 1
            >> Opacity.build

-}
discreteEntry : String -> String -> EngineBuilder -> EngineBuilder
discreteEntry =
    Internal.discreteEntry


{-| Add a discrete CSS property for exit animations.

Exit animations need to hold their initial state
until the very end of the animation, at which point they flip to the final state.

Therefore you need to set both the `from` and `to` values for the property.

Use when an element is disappearing (e.g., going from
`display: block` to `display: none`).

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Opacity as Opacity

    WAAPI.animate model.animState <|
        WAAPI.discreteExit "display" "block" "none"
            >> Opacity.for "box"
            >> Opacity.to 0
            >> Opacity.build

-}
discreteExit : String -> String -> String -> EngineBuilder -> EngineBuilder
discreteExit =
    Internal.discreteExit



-- ============================================================
-- TRANSFORM ORDER
-- ============================================================


{-| Set the transform order.

The transform order specifies how translate, rotate, skew and scale transforms
are combined. Start the list with the transform to apply first.

Any missing transforms are automatically appended in the default order
(Translate → Rotate → Skew → Scale).

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    WAAPI.transformOrder [ Scale, Rotate, Translate, Skew ]

-}
transformOrder : List TransformProperty -> EngineBuilder -> EngineBuilder
transformOrder =
    Internal.transformOrder



-- ============================================================
-- FREEZE
-- ============================================================


{-| Identifies a property that can be frozen at its current animated position.

Use with [freezeX](#freezeX), [freezeY](#freezeY), etc. to hold specific axes
at their current values during animation interruptions.

-}
type alias FreezeProperty =
    Internal.FreezeProperty


{-| Freeze the translate property.
-}
translate : FreezeProperty
translate =
    Internal.freezeTranslate


{-| Freeze the rotate property.
-}
rotate : FreezeProperty
rotate =
    Internal.freezeRotate


{-| Freeze the scale property.
-}
scale : FreezeProperty
scale =
    Internal.freezeScale


{-| Freeze the skew property.
-}
skew : FreezeProperty
skew =
    Internal.freezeSkew


{-| Freeze the X axis of the specified properties at their current animated values.

The named axis indicates which axis will remain frozen while you animate the others.

    import Anim.Engine.WAAPI as WAAPI
    import Anim.Property.Translate as Translate

    let
        ( animState, animCmd ) =
            WAAPI.animate model.animState <|
                WAAPI.freezeX [ WAAPI.translate ]
                    >> Translate.for "box"
                    >> Translate.toY 0
                    >> Translate.build
    in
    ( { model | animState = animState }, animCmd )

-}
freezeX : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeX =
    Internal.freezeAxes [ "x" ]


{-| Freeze the Y axis of the specified properties at their current animated values.
-}
freezeY : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeY =
    Internal.freezeAxes [ "y" ]


{-| Freeze the Z axis of the specified properties at their current animated values.
-}
freezeZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeZ =
    Internal.freezeAxes [ "z" ]


{-| Freeze the X and Y axes of the specified properties at their current animated values.
-}
freezeXY : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeXY =
    Internal.freezeAxes [ "x", "y" ]


{-| Freeze the X and Z axes of the specified properties at their current animated values.
-}
freezeXZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeXZ =
    Internal.freezeAxes [ "x", "z" ]


{-| Freeze the Y and Z axes of the specified properties at their current animated values.
-}
freezeYZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeYZ =
    Internal.freezeAxes [ "y", "z" ]


{-| Freeze all axes of the specified properties at their current animated values.
-}
freezeXYZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
freezeXYZ =
    Internal.freezeAxes [ "x", "y", "z" ]



-- ============================================================
-- UNFREEZE
-- ============================================================


{-| Unfreeze the X axis of the specified properties, allowing it to animate again.
-}
unfreezeX : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeX =
    Internal.unfreezeAxes [ "x" ]


{-| Unfreeze the Y axis of the specified properties, allowing it to animate again.
-}
unfreezeY : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeY =
    Internal.unfreezeAxes [ "y" ]


{-| Unfreeze the Z axis of the specified properties, allowing it to animate again.
-}
unfreezeZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeZ =
    Internal.unfreezeAxes [ "z" ]


{-| Unfreeze the X and Y axes of the specified properties.
-}
unfreezeXY : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeXY =
    Internal.unfreezeAxes [ "x", "y" ]


{-| Unfreeze the X and Z axes of the specified properties.
-}
unfreezeXZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeXZ =
    Internal.unfreezeAxes [ "x", "z" ]


{-| Unfreeze the Y and Z axes of the specified properties.
-}
unfreezeYZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeYZ =
    Internal.unfreezeAxes [ "y", "z" ]


{-| Unfreeze all axes of the specified properties.
-}
unfreezeXYZ : List FreezeProperty -> EngineBuilder -> EngineBuilder
unfreezeXYZ =
    Internal.unfreezeAxes [ "x", "y", "z" ]



-- ============================================================
-- STATE QUERIES
-- ============================================================


{-| Check if any animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : AnimState msg -> Maybe Bool
anyRunning =
    Internal.anyRunning


{-| Check if a specific animation group is currently running.

Returns `Nothing` if there are no animations for the group.

-}
isRunning : AnimGroupName -> AnimState msg -> Maybe Bool
isRunning =
    Internal.isRunning


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState msg -> Maybe Bool
allComplete =
    Internal.allComplete


{-| Check if a specific animation group has completed.

Returns `Nothing` if there are no animations for the group.

-}
isComplete : AnimGroupName -> AnimState msg -> Maybe Bool
isComplete =
    Internal.isComplete


{-| Get the current progress of an animation group as a value from 0.0 to 1.0.

Returns `Nothing` if there are no animations for the group.

    import Anim.Engine.WAAPI as WAAPI

    WAAPI.getProgress "myAnimation" model.animState
    -- Just 0.5 (halfway through)

-}
getProgress : AnimGroupName -> AnimState msg -> Maybe Float
getProgress =
    Internal.getProgress



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
getPropertyRange : AnimGroupName -> String -> AnimState msg -> Maybe { start : Maybe Float, end : Float }
getPropertyRange =
    Internal.getPropertyRange


{-| Get the start value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

Returns `Just 0` if no explicit start value was set, which is the default when no start value is set.

-}
getPropertyStart : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyStart =
    Internal.getPropertyStart


{-| Get the end value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyEnd : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyEnd =
    Internal.getPropertyEnd


{-| Get the current interpolated value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyCurrent : AnimGroupName -> String -> AnimState msg -> Maybe Float
getPropertyCurrent =
    Internal.getPropertyCurrent



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


{-| Get the custom color property range (start and end) of an element being animated.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyRange : AnimGroupName -> String -> AnimState msg -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange =
    Internal.getColorPropertyRange


{-| Get the start value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getColorPropertyStart : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyStart =
    Internal.getColorPropertyStart


{-| Get the end value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyEnd : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyEnd =
    Internal.getColorPropertyEnd


{-| Get the current interpolated value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyCurrent : AnimGroupName -> String -> AnimState msg -> Maybe Color
getColorPropertyCurrent =
    Internal.getColorPropertyCurrent



-- ============================
-- OPACITY
-- ============================


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getOpacityStart : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityStart =
    Internal.getOpacityStart


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityEnd =
    Internal.getOpacityEnd


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the current interpolated opacity if the animation is running.

Returns the end opacity if the animation has completed.

-}
getOpacityCurrent : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityCurrent =
    Internal.getOpacityCurrent


{-| Get the opacity range (start and end) of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Float, end : Float }
getOpacityRange =
    Internal.getOpacityRange



-- ============================
-- ROTATE
-- ============================


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getRotateStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    Internal.getRotateStart


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    Internal.getRotateEnd


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the current interpolated rotation if the animation is running.

Returns the end rotation if the animation has completed.

-}
getRotateCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent =
    Internal.getRotateCurrent


{-| Get the rotate range (start and end) of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange =
    Internal.getRotateRange



-- ============================
-- SCALE
-- ============================


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getScaleStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    Internal.getScaleStart


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    Internal.getScaleEnd


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the current interpolated scale if the animation is running.

Returns the end scale if the animation has completed.

-}
getScaleCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent =
    Internal.getScaleCurrent


{-| Get the scale range (start and end) of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange =
    Internal.getScaleRange



-- ============================
-- SIZE
-- ============================


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSizeStart : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeStart =
    Internal.getSizeStart


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeEnd =
    Internal.getSizeEnd


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the current interpolated size if the animation is running.

Returns the end size if the animation has completed.

-}
getSizeCurrent : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeCurrent =
    Internal.getSizeCurrent


{-| Get the size range (start and end) of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange =
    Internal.getSizeRange



-- ============================
-- SKEW
-- ============================


{-| Get the start skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

Returns `Just {x = 0, y = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getSkewStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewStart =
    Internal.getSkewStart


{-| Get the end skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewEnd =
    Internal.getSkewEnd


{-| Get the current skew of an element based on its animation state.

Returns `Nothing` if the element has no skew animation.

Returns the start skew if the animation has not started yet.

Returns the current interpolated skew if the animation is running.

Returns the end skew if the animation has completed.

-}
getSkewCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float }
getSkewCurrent =
    Internal.getSkewCurrent


{-| Get the skew range (start and end) of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange =
    Internal.getSkewRange



-- ============================
-- TRANSLATE
-- ============================


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just {x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getTranslateStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    Internal.getTranslateStart


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    Internal.getTranslateEnd


{-| Get the current translate of an element based on its animation state.

Returns `Nothing` if the element has no translate animation.

Returns the start translate if the animation has not started yet.

Returns the current interpolated translate if the animation is running.

Returns the end translate if the animation has completed.

-}
getTranslateCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent =
    Internal.getTranslateCurrent


{-| Get the translate range (start and end) of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange =
    Internal.getTranslateRange
