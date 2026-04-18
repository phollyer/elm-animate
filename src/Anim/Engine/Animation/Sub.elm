module Anim.Engine.Animation.Sub exposing
    ( AnimState, AnimBuilder, AnimGroupName
    , init
    , animate
    , AnimEvent(..)
    , AnimMsg, update
    , subscriptions
    , attributes
    , delay
    , duration, speed
    , easing
    , iterations, loopForever, alternate
    , stop, reset, restart, pause, resume
    , discreteEntry, discreteExit
    , transformOrder
    , FreezeProperty, translate, rotate, scale
    , freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ
    , unfreezeX, unfreezeY, unfreezeZ, unfreezeXY, unfreezeXZ, unfreezeYZ, unfreezeXYZ
    , anyRunning, isRunning, allComplete, isComplete, getProgress
    , getBackgroundColorRange, getBackgroundColorStart, getBackgroundColorEnd, getBackgroundColorCurrent
    , getFontColorRange, getFontColorStart, getFontColorEnd, getFontColorCurrent
    , getOpacityRange, getOpacityStart, getOpacityEnd, getOpacityCurrent
    , getRotateRange, getRotateStart, getRotateEnd, getRotateCurrent
    , getScaleRange, getScaleStart, getScaleEnd, getScaleCurrent
    , getSizeRange, getSizeStart, getSizeEnd, getSizeCurrent
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

@docs delay

@docs duration, speed

@docs easing

@docs iterations, loopForever, alternate

See [Timing](https://phollyer.github.io/elm-animate/getting-started/timing/) and
[Easing](https://phollyer.github.io/elm-animate/getting-started/easing/) in the docs.

📖 See [Transform Ordering](https://phollyer.github.io/elm-animate/concepts/transform-order/) in the docs.


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

@docs FreezeProperty, translate, rotate, scale

@docs freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ

📖 See [Interrupting Animations](https://phollyer.github.io/elm-animate/concepts/interruptions/) in the docs.


# Unfreeze

@docs unfreezeX, unfreezeY, unfreezeZ, unfreezeXY, unfreezeXZ, unfreezeYZ, unfreezeXYZ

📖 See [Interrupting Animations](https://phollyer.github.io/elm-animate/concepts/interruptions/) in the docs.


# State Queries

@docs anyRunning, isRunning, allComplete, isComplete, getProgress

📖 See [State Queries](https://phollyer.github.io/elm-animate/engines/animation/sub/#state-queries) in the docs.


# Property Queries

See [Property Queries](https://phollyer.github.io/elm-animate/engines/animation/sub/#property-queries) and
[Properties](https://phollyer.github.io/elm-animate/getting-started/properties/) in the docs.


## Background Color

@docs getBackgroundColorRange, getBackgroundColorStart, getBackgroundColorEnd, getBackgroundColorCurrent


## Font Color

@docs getFontColorRange, getFontColorStart, getFontColorEnd, getFontColorCurrent


## Opacity

@docs getOpacityRange, getOpacityStart, getOpacityEnd, getOpacityCurrent


## Rotate

@docs getRotateRange, getRotateStart, getRotateEnd, getRotateCurrent


## Scale

@docs getScaleRange, getScaleStart, getScaleEnd, getScaleCurrent


## Size

@docs getSizeRange, getSizeStart, getSizeEnd, getSizeCurrent


## Translate

@docs getTranslateRange, getTranslateStart, getTranslateEnd, getTranslateCurrent

-}

import Anim.Extra.Color exposing (Color)
import Anim.Extra.Easing exposing (Easing)
import Anim.Extra.TransformOrder exposing (TransformProperty)
import Anim.Internal.Engine.Animation.Sub as InternalSub
import Html



{- **** MODEL **** -}


{-| The animation state type used to store animation configurations.

Store it in your model.

    type alias Model =
        { animState : Sub.AnimState }

-}
type alias AnimState =
    InternalSub.AnimState


{-| Animation builder type for configuring animations.
-}
type alias AnimBuilder =
    InternalSub.AnimBuilder


{-| A type alias for animation group names.

Used to identify which animation group to target in functions like
[attributes](#attributes), [isRunning](#isRunning), [stop](#stop), etc.

-}
type alias AnimGroupName =
    String



{- **** INITIALIZE **** -}


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
    InternalSub.init



{- **** TRIGGER **** -}


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
    InternalSub.animate



{- **** EVENTS **** -}


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



{- **** UPDATE **** -}


{-| Internal message type.

    type Msg
        = SubMsg Sub.AnimMsg
        | ...

-}
type alias AnimMsg =
    InternalSub.AnimMsg


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
            InternalSub.update msg animState
    in
    ( newState, List.filterMap toAnimEvent internalEvents )


toAnimEvent : InternalSub.AnimEvent -> Maybe AnimEvent
toAnimEvent event =
    case event of
        InternalSub.Tick tickEvent ->
            toTickAnimEvent tickEvent

        InternalSub.Control controlEvent ->
            toControlAnimEvent controlEvent


toTickAnimEvent : InternalSub.TickEvent -> Maybe AnimEvent
toTickAnimEvent event =
    case event of
        InternalSub.Ended key ->
            Just (Ended key)

        InternalSub.Iteration key iterationNumber ->
            Just (Iteration key iterationNumber)

        InternalSub.Progress key progressValue ->
            Just (Progress key progressValue)


toControlAnimEvent : InternalSub.ControlEvent -> Maybe AnimEvent
toControlAnimEvent event =
    case event of
        InternalSub.Started key ->
            Just (Started key)

        InternalSub.Cancelled key progressValue ->
            Just (Cancelled key progressValue)

        InternalSub.Paused key progressValue ->
            Just (Paused key progressValue)

        InternalSub.Resumed key ->
            Just (Resumed key)

        InternalSub.Restarted key ->
            Just (Restarted key)



{- **** SUBSCRIPTIONS **** -}


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
    InternalSub.subscriptions



{- **** VIEW **** -}


{-| Apply the animation `attributes` to your element.

    div
        (Sub.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes =
    InternalSub.attributes



{- **** PLAYBACK SETTINGS **** -}


{-| Set the global delay in milliseconds.

    Sub.animate model.animState <|
        Sub.delay 500
            >> slideIn

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalSub.delay


{-| Set the global duration in milliseconds.

    Sub.animate model.animState <|
        Sub.duration 1000
            >> slideIn

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalSub.duration


{-| Set the global speed in property units per second.

Consult each property's documentation for details on how speed is interpreted.

    Sub.animate model.animState <|
        Sub.speed 100
            >> slideIn

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalSub.speed


{-| Set the global easing function.

    import Anim.Extra.Easing exposing (Easing(..))

    Sub.animate model.animState <|
        Sub.easing BounceOut
            >> slideIn

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalSub.easing


{-| Set how many times an animation should repeat.

    Sub.animate model.animState <|
        Sub.iterations 3
            >> pulse

-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    InternalSub.iterations


{-| Make an animation loop infinitely.

    Sub.animate model.animState <|
        Sub.loopForever
            >> pulse

-}
loopForever : AnimBuilder -> AnimBuilder
loopForever =
    InternalSub.loopForever


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
    InternalSub.alternate



{- **** CONTROL **** -}


{-| Stop a running animation by instantly jumping to its end state.

    Sub.stop "animGroup" model.animState

-}
stop : AnimGroupName -> AnimState -> AnimState
stop =
    InternalSub.stop


{-| Reset an animation by instantly jumping back to its start state.

    Sub.reset "animGroup" model.animState

-}
reset : AnimGroupName -> AnimState -> AnimState
reset =
    InternalSub.reset


{-| Restart an animation from the beginning.

    Sub.restart "animGroup" model.animState

-}
restart : AnimGroupName -> AnimState -> AnimState
restart =
    InternalSub.restart


{-| Pause a running animation.

    Sub.pause "animGroup" model.animState

-}
pause : AnimGroupName -> AnimState -> AnimState
pause =
    InternalSub.pause


{-| Resume a paused animation.

    Sub.resume "animGroup" model.animState

-}
resume : AnimGroupName -> AnimState -> AnimState
resume =
    InternalSub.resume



{- **** TRANSFORM ORDER **** -}


{-| Set the transform order.

The transform order specifies how translate, rotate, and scale transforms
are combined. Start the list with the transform to apply first.

Any missing transforms are automatically appended in the default order
(Translate → Rotate → Scale).

       Sub.transformOrder [ Scale, Rotate, Translate ]
           >> rotateLeft
           >> scaleUp
           >> moveRight

-}
transformOrder : List TransformProperty -> AnimBuilder -> AnimBuilder
transformOrder =
    InternalSub.transformOrder



{- **** DISCRETE PROPERTIES **** -}


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
    InternalSub.discreteEntry


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
    InternalSub.discreteExit



{- *** FREEZE PROPERTIES *** -}


{-| Identifies a property that can be frozen at its current animated position.

Use with [freezeX](#freezeX), [freezeY](#freezeY), etc. to hold specific axes
at their current values during animation interruptions.

-}
type alias FreezeProperty =
    InternalSub.FreezeProperty


{-| Freeze the translate property.
-}
translate : FreezeProperty
translate =
    InternalSub.freezeTranslate


{-| Freeze the rotate property.
-}
rotate : FreezeProperty
rotate =
    InternalSub.freezeRotate


{-| Freeze the scale property.
-}
scale : FreezeProperty
scale =
    InternalSub.freezeScale


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
    InternalSub.freezeAxes [ "x" ]


{-| Freeze the Y axis of the specified properties at their current animated values.
-}
freezeY : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeY =
    InternalSub.freezeAxes [ "y" ]


{-| Freeze the Z axis of the specified properties at their current animated values.
-}
freezeZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeZ =
    InternalSub.freezeAxes [ "z" ]


{-| Freeze the X and Y axes of the specified properties at their current animated values.
-}
freezeXY : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeXY =
    InternalSub.freezeAxes [ "x", "y" ]


{-| Freeze the X and Z axes of the specified properties at their current animated values.
-}
freezeXZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeXZ =
    InternalSub.freezeAxes [ "x", "z" ]


{-| Freeze the Y and Z axes of the specified properties at their current animated values.
-}
freezeYZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeYZ =
    InternalSub.freezeAxes [ "y", "z" ]


{-| Freeze all axes of the specified properties at their current animated values.
-}
freezeXYZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeXYZ =
    InternalSub.freezeAxes [ "x", "y", "z" ]



-- UNFREEZE


{-| Unfreeze the X axis of the specified properties, allowing it to animate again.
-}
unfreezeX : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeX =
    InternalSub.unfreezeAxes [ "x" ]


{-| Unfreeze the Y axis of the specified properties, allowing it to animate again.
-}
unfreezeY : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeY =
    InternalSub.unfreezeAxes [ "y" ]


{-| Unfreeze the Z axis of the specified properties, allowing it to animate again.
-}
unfreezeZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeZ =
    InternalSub.unfreezeAxes [ "z" ]


{-| Unfreeze the X and Y axes of the specified properties.
-}
unfreezeXY : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeXY =
    InternalSub.unfreezeAxes [ "x", "y" ]


{-| Unfreeze the X and Z axes of the specified properties.
-}
unfreezeXZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeXZ =
    InternalSub.unfreezeAxes [ "x", "z" ]


{-| Unfreeze the Y and Z axes of the specified properties.
-}
unfreezeYZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeYZ =
    InternalSub.unfreezeAxes [ "y", "z" ]


{-| Unfreeze all axes of the specified properties.
-}
unfreezeXYZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeXYZ =
    InternalSub.unfreezeAxes [ "x", "y", "z" ]



{- **** STATE QUERIES **** -}


{-| Check if any animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : AnimState -> Maybe Bool
anyRunning =
    InternalSub.anyRunning


{-| Check if a specific animation group is currently running.

Returns `Nothing` if there are no animations for the group.

-}
isRunning : AnimGroupName -> AnimState -> Maybe Bool
isRunning =
    InternalSub.isRunning


{-| Check if a specific animation group has completed.

Returns `Nothing` if there are no animations for the group.

-}
isComplete : AnimGroupName -> AnimState -> Maybe Bool
isComplete =
    InternalSub.isComplete


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    InternalSub.allComplete


{-| Get the current progress of an animation group as a value from 0.0 to 1.0.

Returns `Nothing` if there are no animations for the group.

    Sub.getProgress "myAnimation" model.animState
    -- Just 0.5 (halfway through)

-}
getProgress : AnimGroupName -> AnimState -> Maybe Float
getProgress =
    InternalSub.getProgress



{- **** PROPERTY QUERIES **** -}
--
--
{- *** BACKGROUND COLOR *** -}


{-| Get the background color range (start and end) of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange =
    InternalSub.getBackgroundColorRange


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getBackgroundColorStart : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorStart =
    InternalSub.getBackgroundColorStart


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorEnd : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorEnd =
    InternalSub.getBackgroundColorEnd


{-| Get the current background color of an element based on its animation state.

Returns `Nothing` if the element has no background color animation.

Returns the start color if the animation has not started yet.

Returns the current interpolated color if the animation is running.

Returns the end color if the animation has completed.

-}
getBackgroundColorCurrent : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorCurrent =
    InternalSub.getBackgroundColorCurrent



{- *** FONT COLOR *** -}


{-| Get the font color range (start and end) of an element being animated.

Returns `Nothing` if the element has no font color animation.

-}
getFontColorRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Color, end : Color }
getFontColorRange =
    InternalSub.getFontColorRange


{-| Get the start font color of an element being animated.

Returns `Nothing` if the element has no font color animation.

Returns `opaque black (rgba 0 0 0 1)` if no explicit start value was set, which is the default when no start value is set.

-}
getFontColorStart : AnimGroupName -> AnimState -> Maybe Color
getFontColorStart =
    InternalSub.getFontColorStart


{-| Get the end font color of an element being animated.

Returns `Nothing` if the element has no font color animation.

-}
getFontColorEnd : AnimGroupName -> AnimState -> Maybe Color
getFontColorEnd =
    InternalSub.getFontColorEnd


{-| Get the current font color of an element based on its animation state.

Returns `Nothing` if the element has no font color animation.

Returns the start color if the animation has not started yet.

Returns the current interpolated color if the animation is running.

Returns the end color if the animation has completed.

-}
getFontColorCurrent : AnimGroupName -> AnimState -> Maybe Color
getFontColorCurrent =
    InternalSub.getFontColorCurrent



{- *** OPACITY *** -}


{-| Get the opacity range (start and end) of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Float, end : Float }
getOpacityRange =
    InternalSub.getOpacityRange


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getOpacityStart : AnimGroupName -> AnimState -> Maybe Float
getOpacityStart =
    InternalSub.getOpacityStart


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd =
    InternalSub.getOpacityEnd


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the current interpolated opacity if the animation is running.

Returns the end opacity if the animation has completed.

-}
getOpacityCurrent : AnimGroupName -> AnimState -> Maybe Float
getOpacityCurrent =
    InternalSub.getOpacityCurrent



{- *** ROTATE *** -}


{-| Get the rotate range (start and end) of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange =
    InternalSub.getRotateRange


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getRotateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    InternalSub.getRotateStart


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    InternalSub.getRotateEnd


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the current interpolated rotation if the animation is running.

Returns the end rotation if the animation has completed.

-}
getRotateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent =
    InternalSub.getRotateCurrent



{- *** SCALE *** -}


{-| Get the scale range (start and end) of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange =
    InternalSub.getScaleRange


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getScaleStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    InternalSub.getScaleStart


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    InternalSub.getScaleEnd


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the current interpolated scale if the animation is running.

Returns the end scale if the animation has completed.

-}
getScaleCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent =
    InternalSub.getScaleCurrent



{- *** SIZE *** -}


{-| Get the size range (start and end) of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange =
    InternalSub.getSizeRange


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSizeStart : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart =
    InternalSub.getSizeStart


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd =
    InternalSub.getSizeEnd


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the current interpolated size if the animation is running.

Returns the end size if the animation has completed.

-}
getSizeCurrent : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeCurrent =
    InternalSub.getSizeCurrent



{- *** TRANSLATE *** -}


{-| Get the translate range (start and end) of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange =
    InternalSub.getTranslateRange


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just {x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getTranslateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    InternalSub.getTranslateStart


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    InternalSub.getTranslateEnd


{-| Get the current translate of an element based on its animation state.

Returns `Nothing` if the element has no translate animation.

Returns the start translate if the animation has not started yet.

Returns the current interpolated translate if the animation is running.

Returns the end translate if the animation has completed.

-}
getTranslateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent =
    InternalSub.getTranslateCurrent
