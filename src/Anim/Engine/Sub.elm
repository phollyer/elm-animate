module Anim.Engine.Sub exposing
    ( AnimState, AnimBuilder, AnimGroupName
    , init
    , animate
    , AnimEvent(..)
    , AnimMsg, update
    , subscriptions
    , attributes
    , iterations, loopForever, alternate
    , delay
    , duration, speed
    , easing
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
    , getSkewCurrent, getSkewEnd, getSkewRange, getSkewStart
    , getTranslateRange, getTranslateStart, getTranslateEnd, getTranslateCurrent
    )

{-| Run Subscription-based animations with frame-by-frame control.

For specific Engine guides and examples, see the
[Sub Engine Documentation](https://phollyer.github.io/elm-animate/engines/animation/sub/).

For Engine comparisons, shared features, examples and code, see the
[Engine Overview](https://phollyer.github.io/elm-animate/engines/animation/overview/) section in the docs.


# Types

@docs AnimState, AnimBuilder, AnimGroupName


# Initialize

@docs init

📖 See [Initialize](https://phollyer.github.io/elm-animate/animation-workflow/init/) in the docs.


# Trigger

@docs animate

📖 See [Triggering Animations](https://phollyer.github.io/elm-animate/animation-workflow/trigger/) in the docs.


# Events

@docs AnimEvent

📖 See [Event Reference](https://phollyer.github.io/elm-animate/animation-workflow/react/#event-reference) in the docs.


# Update

@docs AnimMsg, update

📖 See [React](https://phollyer.github.io/elm-animate/animation-workflow/react/) in the docs.


# Subscriptions

@docs subscriptions

📖 See [Subscriptions](https://phollyer.github.io/elm-animate/engines/animation/sub/#subscriptions) in the docs.


# View

To render an animation, you need to apply the animation `attributes` to your element.

@docs attributes

📖 See [Render](https://phollyer.github.io/elm-animate/animation-workflow/render/) in the docs.


# Playback Settings

@docs iterations, loopForever, alternate


## Timing

@docs delay

@docs duration, speed

📖 See [Timing](https://phollyer.github.io/elm-animate/getting-started/timing/) in the docs.


## Easing

@docs easing

📖 See [Easing](https://phollyer.github.io/elm-animate/getting-started/easing/) in the docs.


# Animation Control

@docs stop, reset, restart, pause, resume

📖 See [Controlling Animations](https://phollyer.github.io/elm-animate/concepts/controlling-animations/) in the docs.


# Discrete Properties

@docs discreteEntry, discreteExit

📖 See [Discrete Properties](https://phollyer.github.io/elm-animate/concepts/discrete-properties/) in the docs.


# Transform Order

@docs transformOrder

📖 See [Transform Ordering](https://phollyer.github.io/elm-animate/concepts/transform-order/) in the docs.


# Freeze

@docs FreezeProperty, translate, rotate, scale, skew

@docs freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ

📖 See [Interrupting Animations](https://phollyer.github.io/elm-animate/concepts/interruptions/) in the docs.


# Unfreeze

@docs unfreezeX, unfreezeY, unfreezeZ, unfreezeXY, unfreezeXZ, unfreezeYZ, unfreezeXYZ

📖 See [Interrupting Animations](https://phollyer.github.io/elm-animate/concepts/interruptions/) in the docs.


# State Queries

@docs anyRunning, isRunning, allComplete, isComplete, getProgress

📖 See [State Queries](https://phollyer.github.io/elm-animate/engines/animation/sub/#state-queries) in the docs.


# Property Queries

📖 See [Property Queries](https://phollyer.github.io/elm-animate/engines/animation/sub/#property-queries) and
[Properties](https://phollyer.github.io/elm-animate/getting-started/properties/) in the docs.


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

@docs getSkewCurrent, getSkewEnd, getSkewRange, getSkewStart


## Translate

@docs getTranslateRange, getTranslateStart, getTranslateEnd, getTranslateCurrent

-}

import Anim.Builder as Builder
import Anim.Extra.Color exposing (Color)
import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Engine.Sub as Internal
import Easing exposing (Easing)
import Html



-- ============================================================
-- MODEL
-- ============================================================


{-| The animation state type used to store animation configurations.

Store it in your model.

    type alias Model =
        { animState : Sub.AnimState }

-}
type alias AnimState =
    Internal.AnimState


{-| Animation builder type for configuring animations.
-}
type alias AnimBuilder =
    Builder.AnimBuilder


{-| A type alias for animation group names.

Used to identify which animation group to target in functions like
[attributes](#attributes), [isRunning](#isRunning), [stop](#stop), etc.

-}
type alias AnimGroupName =
    String



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Initialize animation state with optional property initializers.

    -- Empty state
    Sub.init []

    -- With initial properties
    Sub.init
        [ Translate.initXY "animGroupName" 100 50
        , Opacity.init "animGroupName" 0.5
        ]

-}
init : List (AnimBuilder -> AnimBuilder) -> AnimState
init =
    Internal.init



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Trigger animations.

    { model
        | animState =
            Sub.animate model.animState <|
                fadeIn
                    >> slideIn
    }

-}
animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
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

    type Msg
        = SubMsg Sub.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Handle animation lifecycle messages.

Returns the updated state and a list of [AnimEvent](#AnimEvent)s for you to pattern match on.

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            SubMsg animMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update animMsg model.animState
                in
                handleAnimationEvents ({ model | animState = newAnimState }, Cmd.none) events

    handleAnimationEvents : (Model, Cmd Msg) -> List Sub.AnimEvent -> ( Model, Cmd Msg )
    handleAnimationEvents =
        List.foldl handleEvent

    handleEvent : Sub.AnimEvent -> (Model, Cmd Msg) -> ( Model, Cmd Msg )
    handleEvent event (model, cmd) =
        case event of
            ...

-}
update : AnimMsg -> AnimState -> ( AnimState, List AnimEvent )
update msg animState =
    let
        ( newState, internalEvents ) =
            Internal.update msg animState
    in
    ( newState, List.filterMap toAnimEvent internalEvents )


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

    div
        (Sub.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes =
    Internal.attributes



-- ============================================================
-- PLAYBACK SETTINGS
-- ============================================================


{-| Set the global delay in milliseconds.

    Sub.animate model.animState <|
        Sub.delay 500
            >> slideIn

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Internal.delay


{-| Set the global duration in milliseconds.

    Sub.animate model.animState <|
        Sub.duration 1000
            >> slideIn

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Internal.duration


{-| Set the global speed in property units per second.

Consult each property's documentation for details on how speed is interpreted.

    Sub.animate model.animState <|
        Sub.speed 100
            >> slideIn

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    Internal.speed


{-| Set the global easing function.

    import Easing exposing (Easing(..))

    Sub.animate model.animState <|
        Sub.easing BounceOut
            >> slideIn

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Internal.easing


{-| Set how many times an animation should repeat.

    Sub.animate model.animState <|
        Sub.iterations 3
            >> pulse

-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    Internal.iterations


{-| Make an animation loop infinitely.

    Sub.animate model.animState <|
        Sub.loopForever
            >> pulse

-}
loopForever : AnimBuilder -> AnimBuilder
loopForever =
    Internal.loopForever


{-| Make an animation alternate direction on each iteration (ping-pong effect).

    Sub.animate model.animState <|
        Sub.loopForever
            >> Sub.alternate
            >> pulse

This creates a smooth ping-pong animation.
The animation plays forward, then backward, then forward, etc.

-}
alternate : AnimBuilder -> AnimBuilder
alternate =
    Internal.alternate



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


{-| Stop a running animation by instantly jumping to its end state.

    Sub.stop "animGroup" model.animState

-}
stop : AnimGroupName -> AnimState -> AnimState
stop =
    Internal.stop


{-| Reset an animation by instantly jumping back to its start state.

    Sub.reset "animGroup" model.animState

-}
reset : AnimGroupName -> AnimState -> AnimState
reset =
    Internal.reset


{-| Restart an animation from the beginning.

    Sub.restart "animGroup" model.animState

-}
restart : AnimGroupName -> AnimState -> AnimState
restart =
    Internal.restart


{-| Pause a running animation.

    Sub.pause "animGroup" model.animState

-}
pause : AnimGroupName -> AnimState -> AnimState
pause =
    Internal.pause


{-| Resume a paused animation.

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

    Sub.animate model.animState <|
        Sub.discreteEntry "display" "block"
            >> Sub.discreteEntry "visibility" "visible"
            >> fadeIn

-}
discreteEntry : String -> String -> AnimBuilder -> AnimBuilder
discreteEntry =
    Internal.discreteEntry


{-| Add a discrete CSS property for exit animations.

Exit animations need to hold their initial state
until the very end of the animation, at which point they flip to the final state.

Therefore you need to set both the `from` and `to` values for the property.

Use when an element is disappearing (e.g., going from
`display: block` to `display: none`).

    Sub.animate model.animState <|
        Sub.discreteExit "display" "block" "none"
            >> fadeOut

-}
discreteExit : String -> String -> String -> AnimBuilder -> AnimBuilder
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

       Sub.transformOrder [ Scale, Rotate, Translate, Skew ]
           >> rotateLeft
           >> scaleUp
           >> moveRight

-}
transformOrder : List TransformProperty -> AnimBuilder -> AnimBuilder
transformOrder =
    Internal.transformOrder



-- ============================================================
-- FREEZE / UNFREEZE PROPERTIES
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



-- ============================================================
-- FREEZE AXES
-- ============================================================


{-| Freeze the X axis of the specified properties at their current animated values.

The named axis indicates which axis will remain frozen while you animate the others.

    Sub.animate model.animState <|
        Sub.freezeX [ Sub.translate ]
            >> Translate.for "box"
            >> Translate.toY 0
            >> Translate.build

-}
freezeX : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeX =
    Internal.freezeAxes [ "x" ]


{-| Freeze the Y axis of the specified properties at their current animated values.
-}
freezeY : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeY =
    Internal.freezeAxes [ "y" ]


{-| Freeze the Z axis of the specified properties at their current animated values.
-}
freezeZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeZ =
    Internal.freezeAxes [ "z" ]


{-| Freeze the X and Y axes of the specified properties at their current animated values.
-}
freezeXY : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeXY =
    Internal.freezeAxes [ "x", "y" ]


{-| Freeze the X and Z axes of the specified properties at their current animated values.
-}
freezeXZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeXZ =
    Internal.freezeAxes [ "x", "z" ]


{-| Freeze the Y and Z axes of the specified properties at their current animated values.
-}
freezeYZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeYZ =
    Internal.freezeAxes [ "y", "z" ]


{-| Freeze all axes of the specified properties at their current animated values.
-}
freezeXYZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeXYZ =
    Internal.freezeAxes [ "x", "y", "z" ]



-- ============================================================
-- UNFREEZE AXES
-- ============================================================


{-| Unfreeze the X axis of the specified properties, allowing it to animate again.
-}
unfreezeX : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeX =
    Internal.unfreezeAxes [ "x" ]


{-| Unfreeze the Y axis of the specified properties, allowing it to animate again.
-}
unfreezeY : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeY =
    Internal.unfreezeAxes [ "y" ]


{-| Unfreeze the Z axis of the specified properties, allowing it to animate again.
-}
unfreezeZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeZ =
    Internal.unfreezeAxes [ "z" ]


{-| Unfreeze the X and Y axes of the specified properties.
-}
unfreezeXY : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeXY =
    Internal.unfreezeAxes [ "x", "y" ]


{-| Unfreeze the X and Z axes of the specified properties.
-}
unfreezeXZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeXZ =
    Internal.unfreezeAxes [ "x", "z" ]


{-| Unfreeze the Y and Z axes of the specified properties.
-}
unfreezeYZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeYZ =
    Internal.unfreezeAxes [ "y", "z" ]


{-| Unfreeze all axes of the specified properties.
-}
unfreezeXYZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
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
