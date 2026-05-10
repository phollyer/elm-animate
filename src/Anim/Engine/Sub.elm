module Anim.Engine.Sub exposing
    ( AnimState, AnimGroupName
    , AnimBuilder
    , TimelineBuilder
    , EngineBuilder
    , init
    , animate
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

{-| Run Subscription-based animations with frame-by-frame control.

For specific Engine guides and examples, see the
[Sub Engine Documentation](https://phollyer.github.io/elm-motion/animation/engines/sub/).

For Engine comparisons, shared features, examples and code, see the
[Engine Overview](https://phollyer.github.io/elm-motion/animation/engines/overview/) section in the docs.


# Types

@docs AnimState, AnimGroupName


## Builders

@docs AnimBuilder


### Timeline Builder

This Engine uses the browser's Document timeline, along with the Transition, Keyframe, and WAAPI Engines.

Use the `TimelineBuilder` to configure animations that run on the Document timeline only. If any Engines
are used that don't run on the Document timeline (e.g., Scroll or View), you'll get a type error.

@docs TimelineBuilder


### Engine Builder

The `EngineBuilder` is a builder type restricted to the Sub Engine.

Use the `EngineBuilder` when you want to restrict helpers to the Sub Engine, such as any that rely
on Sub-only APIs.

@docs EngineBuilder


# Initialize

@docs init

📖 See [Initialize](https://phollyer.github.io/elm-motion/animation/workflow/init/) in the docs.


# Trigger

@docs animate

📖 See [Triggering Animations](https://phollyer.github.io/elm-motion/animation/workflow/trigger/) in the docs.


# Events

@docs AnimEvent

📖 See [Event Reference](https://phollyer.github.io/elm-motion/animation/workflow/react/#event-reference) in the docs.


# Update

@docs AnimMsg, update

📖 See [React](https://phollyer.github.io/elm-motion/animation/workflow/react/) in the docs.


# Subscriptions

@docs subscriptions

📖 See [Subscriptions](https://phollyer.github.io/elm-motion/animation/engines/sub/#subscriptions) in the docs.


# View

To render an animation, you need to apply the animation `attributes` to your element.

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

📖 See [Interrupting Animations](https://phollyer.github.io/elm-motion/animation/concepts/interruptions/) in the docs.


# Unfreeze

@docs unfreezeX, unfreezeY, unfreezeZ, unfreezeXY, unfreezeXZ, unfreezeYZ, unfreezeXYZ

📖 See [Interrupting Animations](https://phollyer.github.io/elm-motion/animation/concepts/interruptions/) in the docs.


# State Queries

@docs anyRunning, isRunning, allComplete, isComplete, getProgress

📖 See [State Queries](https://phollyer.github.io/elm-motion/animation/engines/sub/#state-queries) in the docs.


# Property Queries

📖 See [Property Queries](https://phollyer.github.io/elm-motion/animation/engines/sub/#property-queries) and
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
import Anim.Internal.Engine.Sub as Internal
import Browser exposing (UrlRequest(..))
import Motion.Easing as Easing exposing (Easing)
import Html
import Motion.Spring exposing (Spring)



-- ============================================================
-- TYPES
-- ============================================================


{-| The animation state type used to store animation configurations.

Store it in your model.

    type alias Model =
        { animState : Sub.AnimState }

-}
type alias AnimState =
    Internal.AnimState


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

    f : Sub.TimelineBuilder engine -> Sub.TimelineBuilder engine

Here's an engine-specific timeline builder for the Sub Engine. It will result in a type error if used with any other engine.

    f : Sub.TimelineBuilder ForSubEngine -> Sub.TimelineBuilder ForSubEngine

For mode restrictions and examples, see
[Build: Builder Modes](https://phollyer.github.io/elm-motion/animation/workflow/build/#builder-modes).

-}
type alias TimelineBuilder engine =
    Internal.TimelineBuilder engine


{-| Type alias for the internal `EngineBuilder` type.

This engine-specific builder will result in a type error if used with any other engine.

    f : Sub.EngineBuilder -> Sub.EngineBuilder

For mode restrictions and examples, see
[Build: Builder Modes](https://phollyer.github.io/elm-motion/animation/workflow/build/#builder-modes).

-}
type alias EngineBuilder =
    Internal.EngineBuilder



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Initialize animation state with optional property initializers.

    import Anim.Engine.Sub as Sub
    import Anim.Property.Opacity as Opacity
    import Anim.Property.Translate as Translate

    -- Empty state
    Sub.init []

    -- With initial properties
    Sub.init
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

    import Anim.Engine.Sub as Sub
    import Anim.Property.Opacity as Opacity
    import Anim.Property.Translate as Translate

    { model
        | animState =
            Sub.animate model.animState <|
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



-- ============================================================
-- EVENTS
-- ============================================================


{-| Subscription animation lifecycle events.
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



-- ============================================================
-- UPDATE
-- ============================================================


{-| Internal message type.

    import Anim.Engine.Sub as Sub

    type Msg
        = SubMsg Sub.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Handle animation lifecycle messages.

Returns the updated state and a list of [AnimEvent](#AnimEvent)s for you to pattern match on.

    import Anim.Engine.Sub as Sub

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            SubMsg animMsg ->
                let
                    ( animState, events ) =
                        Sub.update animMsg model.animState
                in
                handleAnimationEvents ({ model | animState = animState }, Cmd.none) events

    handleAnimationEvents : (Model, Cmd Msg) -> List Sub.AnimEvent -> ( Model, Cmd Msg )
    handleAnimationEvents =
        List.foldl handleEvent

    handleEvent : Sub.AnimEvent -> (Model, Cmd Msg) -> ( Model, Cmd Msg )
    handleEvent event (model, cmd) =
        case event of
            ...

-}
update : AnimMsg -> AnimState -> ( AnimState, List AnimEvent )
update msg =
    Internal.update msg
        >> Tuple.mapSecond (List.filterMap toAnimEvent)


toAnimEvent : Internal.AnimEvent -> Maybe AnimEvent
toAnimEvent event =
    case event of
        Internal.Tick tickEvent ->
            toTickAnimEvent tickEvent

        Internal.Control controlEvent ->
            toControlAnimEvent controlEvent


toTickAnimEvent : Internal.TickEvent -> Maybe AnimEvent
toTickAnimEvent event =
    case event of
        Internal.Ended key ->
            Just (Ended key)

        Internal.Iteration key iterationNumber ->
            Just (Iteration key iterationNumber)

        Internal.Progress key progressValue ->
            Just (Progress key progressValue)


toControlAnimEvent : Internal.ControlEvent -> Maybe AnimEvent
toControlAnimEvent event =
    case event of
        Internal.Started key ->
            Just (Started key)

        Internal.Cancelled key progressValue ->
            Just (Cancelled key progressValue)

        Internal.Paused key progressValue ->
            Just (Paused key progressValue)

        Internal.Resumed key ->
            Just (Resumed key)

        Internal.Restarted key ->
            Just (Restarted key)



-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================


{-| Subscribe to receive animation frame updates.

Your animations will not run without this subscription.

    import Anim.Engine.Sub as Sub

    type Msg
        = SubMsg Sub.AnimMsg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions SubMsg model.animState

-}
subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions =
    Internal.subscriptions



-- ============================================================
-- VIEW
-- ============================================================


{-| Apply the animation `attributes` to your element.

    import Anim.Engine.Sub as Sub
    import Html exposing (div, text)

    div
        (Sub.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes =
    Internal.attributes



-- ============================================================
-- PLAYBACK
-- ============================================================


{-| Set how many times an animation should repeat.

    import Anim.Engine.Sub as Sub
    import Anim.Property.Opacity as Opacity

    pulse : Sub.EngineBuilder -> Sub.TimelineBuilder
    pulse =
        Opacity.for "box"
            >> Opacity.to 0.2
            >> Opacity.build

    Sub.animate model.animState <|
        Sub.iterations 3
            >> pulse

-}
iterations : Int -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
iterations =
    Internal.iterations


{-| Make an animation loop infinitely.

    import Anim.Engine.Sub as Sub
    import Anim.Property.Opacity as Opacity

    pulse : Sub.EngineBuilder -> Sub.TimelineBuilder
    pulse =
        Opacity.for "box"
            >> Opacity.to 0.2
            >> Opacity.build

    Sub.animate model.animState <|
        Sub.loopForever
            >> pulse

-}
loopForever : Builder.AnimBuilder mode -> Builder.AnimBuilder mode
loopForever =
    Internal.loopForever


{-| Make an animation alternate direction on each iteration (ping-pong effect).

    import Anim.Engine.Sub as Sub
    import Anim.Property.Opacity as Opacity

    pulse : Sub.EngineBuilder -> Sub.TimelineBuilder
    pulse =
        Opacity.for "box"
            >> Opacity.to 0.2
            >> Opacity.build

    Sub.animate model.animState <|
        Sub.loopForever
            >> Sub.alternate
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

    import Anim.Engine.Sub as Sub
    import Anim.Property.Custom as Custom

    Sub.animate model.animState <|
        Sub.delay 500
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

    import Anim.Engine.Sub as Sub
    import Anim.Property.Custom as Custom

    Sub.animate model.animState <|
        Sub.duration 1000
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

    import Anim.Engine.Sub as Sub
    import Anim.Property.Custom as Custom

    Sub.animate model.animState <|
        Sub.speed 100
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
    import Anim.Engine.Sub as Sub
    import Anim.Property.Custom as Custom

    Sub.animate model.animState <|
        Sub.easing BounceOut
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


{-| Set a global default `Spring` for every property in this animation.

Individual properties can override with their own `spring` (or with
`easing` to opt back into curve-driven motion).

Spring and easing globals are mutually exclusive: setting one clears
the other.

    import Motion.Spring as Spring

    Sub.animate model.animState <|
        Sub.spring Spring.wobbly
            >> Opacity.for "box"
            >> Opacity.to 1
            >> Opacity.build

-}
spring : Spring -> Builder.AnimBuilder mode -> Builder.AnimBuilder mode
spring =
    Internal.spring



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


{-| Stop a running animation by instantly jumping to its end state.

    import Anim.Engine.Sub as Sub

    Sub.stop "animGroup" model.animState

-}
stop : AnimGroupName -> AnimState -> AnimState
stop =
    Internal.stop


{-| Reset an animation by instantly jumping back to its start state.

    import Anim.Engine.Sub as Sub

    Sub.reset "animGroup" model.animState

-}
reset : AnimGroupName -> AnimState -> AnimState
reset =
    Internal.reset


{-| Restart an animation from the beginning.

    import Anim.Engine.Sub as Sub

    Sub.restart "animGroup" model.animState

-}
restart : AnimGroupName -> AnimState -> AnimState
restart =
    Internal.restart


{-| Pause a running animation.

    import Anim.Engine.Sub as Sub

    Sub.pause "animGroup" model.animState

-}
pause : AnimGroupName -> AnimState -> AnimState
pause =
    Internal.pause


{-| Resume a paused animation.

    import Anim.Engine.Sub as Sub

    Sub.resume "animGroup" model.animState

-}
resume : AnimGroupName -> AnimState -> AnimState
resume =
    Internal.resume



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


{-| Add a discrete CSS property for entry animations.

The value is applied as an inline style from the first frame and held throughout
the animation. Use this when an element is appearing (e.g., going from
`display: none` to `display: block`).

    import Anim.Engine.Sub as Sub
    import Anim.Property.Opacity as Opacity

    Sub.animate model.animState <|
        Sub.discreteEntry "display" "block"
            >> Sub.discreteEntry "visibility" "visible"
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

    import Anim.Engine.Sub as Sub
    import Anim.Property.Opacity as Opacity

    Sub.animate model.animState <|
        Sub.discreteExit "display" "block" "none"
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

    import Anim.Engine.Sub as Sub
    import Anim.Extra.TransformOrder exposing (TransformProperty(..))

    Sub.transformOrder [ Scale, Rotate, Translate, Skew ]

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


{-| Freeze the scale property.
-}
skew : FreezeProperty
skew =
    Internal.freezeSkew


{-| Freeze the translate property.
-}
translate : FreezeProperty
translate =
    Internal.freezeTranslate


{-| Freeze the X axis of the specified properties at their current animated values.

The named axis indicates which axis will remain frozen while you animate the others.

    import Anim.Engine.Sub as Sub
    import Anim.Property.Translate as Translate

    Sub.animate model.animState <|
        Sub.freezeX [ Sub.translate ]
            >> Translate.for "box"
            >> Translate.toY 0
            >> Translate.build

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
anyRunning : AnimState -> Maybe Bool
anyRunning =
    Internal.anyRunning


{-| Check if a specific animation group is currently running.

Returns `Nothing` if there are no animations for the group.

-}
isRunning : AnimGroupName -> AnimState -> Maybe Bool
isRunning =
    Internal.isRunning


{-| Check if a specific animation group has completed.

Returns `Nothing` if there are no animations for the group.

-}
isComplete : AnimGroupName -> AnimState -> Maybe Bool
isComplete =
    Internal.isComplete


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    Internal.allComplete


{-| Get the current progress of an animation group as a value from 0.0 to 1.0.

Returns `Nothing` if there are no animations for the group.

    import Anim.Engine.Sub as Sub

    Sub.getProgress "myAnimation" model.animState
    -- Just 0.5 (halfway through)

-}
getProgress : AnimGroupName -> AnimState -> Maybe Float
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
getPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Float, end : Float }
getPropertyRange =
    Internal.getPropertyRange


{-| Get the start value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

Returns `Just 0` if no explicit start value was set, which is the default when no start value is set.

-}
getPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyStart =
    Internal.getPropertyStart


{-| Get the end value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyEnd =
    Internal.getPropertyEnd


{-| Get the current interpolated value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyCurrent : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyCurrent =
    Internal.getPropertyCurrent



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


{-| Get the custom color property range (start and end) of an element being animated.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange =
    Internal.getColorPropertyRange


{-| Get the start value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getColorPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyStart =
    Internal.getColorPropertyStart


{-| Get the end value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyEnd =
    Internal.getColorPropertyEnd


{-| Get the current interpolated value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyCurrent : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyCurrent =
    Internal.getColorPropertyCurrent



-- ============================
-- OPACITY
-- ============================


{-| Get the opacity range (start and end) of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Float, end : Float }
getOpacityRange =
    Internal.getOpacityRange


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getOpacityStart : AnimGroupName -> AnimState -> Maybe Float
getOpacityStart =
    Internal.getOpacityStart


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd =
    Internal.getOpacityEnd


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the current interpolated opacity if the animation is running.

Returns the end opacity if the animation has completed.

-}
getOpacityCurrent : AnimGroupName -> AnimState -> Maybe Float
getOpacityCurrent =
    Internal.getOpacityCurrent



-- ============================
-- ROTATE
-- ============================


{-| Get the rotate range (start and end) of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange =
    Internal.getRotateRange


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getRotateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    Internal.getRotateStart


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    Internal.getRotateEnd


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the current interpolated rotation if the animation is running.

Returns the end rotation if the animation has completed.

-}
getRotateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent =
    Internal.getRotateCurrent



-- ============================
-- SCALE
-- ============================


{-| Get the scale range (start and end) of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange =
    Internal.getScaleRange


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getScaleStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    Internal.getScaleStart


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    Internal.getScaleEnd


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the current interpolated scale if the animation is running.

Returns the end scale if the animation has completed.

-}
getScaleCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent =
    Internal.getScaleCurrent



-- ============================
-- SIZE
-- ============================


{-| Get the size range (start and end) of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange =
    Internal.getSizeRange


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSizeStart : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart =
    Internal.getSizeStart


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd =
    Internal.getSizeEnd


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the current interpolated size if the animation is running.

Returns the end size if the animation has completed.

-}
getSizeCurrent : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeCurrent =
    Internal.getSizeCurrent



-- ============================
-- SKEW
-- ============================


{-| Get the skew range (start and end) of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float }, end : { x : Float, y : Float } }
getSkewRange =
    Internal.getSkewRange


{-| Get the start skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewStart =
    Internal.getSkewStart


{-| Get the end skew of an element being animated.

Returns `Nothing` if the element has no skew animation.

-}
getSkewEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewEnd =
    Internal.getSkewEnd


{-| Get the current skew of an element based on its animation state.

Returns `Nothing` if the element has no skew animation.

Returns the start skew if the animation has not started yet.

Returns the current interpolated skew if the animation is running.

Returns the end skew if the animation has completed.

-}
getSkewCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float }
getSkewCurrent =
    Internal.getSkewCurrent



-- ============================
-- TRANSLATE
-- ============================


{-| Get the translate range (start and end) of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange =
    Internal.getTranslateRange


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just {x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getTranslateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    Internal.getTranslateStart


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    Internal.getTranslateEnd


{-| Get the current translate of an element based on its animation state.

Returns `Nothing` if the element has no translate animation.

Returns the start translate if the animation has not started yet.

Returns the current interpolated translate if the animation is running.

Returns the end translate if the animation has completed.

-}
getTranslateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent =
    Internal.getTranslateCurrent
