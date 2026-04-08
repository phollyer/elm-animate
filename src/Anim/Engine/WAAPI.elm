module Anim.Engine.WAAPI exposing
    ( AnimState, AnimBuilder, AnimGroupName
    , init
    , attributes
    , animate, fireAndForget
    , AnimMsg, update
    , AnimEvent(..)
    , subscriptions
    , FreezeProperty, translate, rotate, scale
    , freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ
    , unfreezeX, unfreezeXY, unfreezeXYZ, unfreezeXZ, unfreezeY, unfreezeYZ, unfreezeZ
    , transformOrder
    , stop, reset, restart, pause, resume
    , delay
    , duration, speed
    , easing
    , iterations, loopForever, alternate
    , anyRunning, isRunning, allComplete, isComplete
    , getProgress
    , getBackgroundColorStart, getBackgroundColorEnd, getBackgroundColorCurrent
    , getOpacityStart, getOpacityEnd, getOpacityCurrent
    , getRotateStart, getRotateEnd, getRotateCurrent
    , getScaleStart, getScaleEnd, getScaleCurrent
    , getSizeStart, getSizeEnd, getSizeCurrent
    , getTranslateStart, getTranslateEnd, getTranslateCurrent
    --, onResize
    )

{-| Web Animations API engine via ports for maximum performance.

Requires the `elm-animate-waapi` JavaScript companion library.

For detailed guides, setup instructions, and engine comparisons, see the
[full documentation](https://phollyer.github.io/elm-animate/engines/waapi/).


# Types

@docs AnimState, AnimBuilder, AnimGroupName


# Initialize

@docs init


# Render

@docs attributes


# Trigger

@docs animate, fireAndForget


# Update

@docs AnimMsg, update


# Anim Events

@docs AnimEvent


## Subscriptions

@docs subscriptions


# Freeze

@docs FreezeProperty, translate, rotate, scale

@docs freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ


# Unfreeze

@docs unfreezeX, unfreezeXY, unfreezeXYZ, unfreezeXZ, unfreezeY, unfreezeYZ, unfreezeZ


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

@docs getProgress


# Querying Animated Properties


## Background Color

@docs getBackgroundColorStart, getBackgroundColorEnd, getBackgroundColorCurrent


## Opacity

@docs getOpacityStart, getOpacityEnd, getOpacityCurrent


## Rotate

@docs getRotateStart, getRotateEnd, getRotateCurrent


## Scale

@docs getScaleStart, getScaleEnd, getScaleCurrent


## Size

@docs getSizeStart, getSizeEnd, getSizeCurrent


## Translate

@docs getTranslateStart, getTranslateEnd, getTranslateCurrent

-}

import Anim.Extra.Color exposing (Color)
import Anim.Extra.Easing exposing (Easing)
import Anim.Extra.TransformOrder exposing (TransformOrder)
import Anim.Internal.Builder as Builder
import Anim.Internal.Engine.Animation.WAAPI as Internal
import Html
import Json.Decode as Decode
import Json.Encode as Encode



-- TYPES


{-| A type alias for animation group names.

Used to identify which animation group to target in functions like
[attributes](#attributes), [isRunning](#isRunning), [stop](#stop), etc.

-}
type alias AnimGroupName =
    String


{-| The animation state type used to store animation configurations.

Store it in your model.

The `msg` type parameter is your `Msg` type.

    type alias Model =
        { animState : WAAPI.AnimState Msg }

-}
type alias AnimState msg =
    Internal.AnimState msg


{-| Initialize animation state.

Takes the command port, event port, and optional property initializers:

    port waapiCommand : Json.Encode.Value -> Cmd msg

    port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg

    -- Basic initialization
    WAAPI.init waapiCommand waapiEvent []

    -- With initial properties
    WAAPI.init waapiCommand
        waapiEvent
        [ Translate.initXY "animGroupName" 100 50
        , Opacity.init "animGroupName" 1.0
        ]

-}
init : (Encode.Value -> Cmd msg) -> ((Decode.Value -> msg) -> Sub msg) -> List (AnimBuilder -> AnimBuilder) -> AnimState msg
init =
    Internal.init


{-| Apply the animation attributes to your element.

    div
        (WAAPI.attributes "animGroupName" model.animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState msg -> List (Html.Attribute msg)
attributes =
    Internal.attributes


{-| Animation builder type for configuring animations.
-}
type alias AnimBuilder =
    Internal.AnimBuilder


{-| Set the global duration in milliseconds.

    WAAPI.animate model.animState <|
        WAAPI.duration 1000
            >> slideIn

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Internal.duration


{-| Set the global speed in property units per second.

Consult each property's documentation for details on how speed is interpreted.

    WAAPI.animate model.animState <|
        WAAPI.speed 100
            >> slideIn

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    Internal.speed


{-| Set the global easing function.

    import Anim.Extra.Easing exposing (Easing(..))

    WAAPI.animate model.animState <|
        WAAPI.easing BounceOut
            >> slideIn

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Internal.easing


{-| Set the global delay in milliseconds.

    WAAPI.animate model.animState <|
        WAAPI.delay 500
            >> slideIn

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Internal.delay


{-| Set how many times an animation should repeat.

    WAAPI.animate model.animState <|
        WAAPI.iterations 3
            >> pulse

-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    Builder.iterations


{-| Make an animation loop infinitely.

    WAAPI.animate model.animState <|
        WAAPI.loopForever
            >> pulse

-}
loopForever : AnimBuilder -> AnimBuilder
loopForever =
    Builder.loopForever


{-| Make an animation alternate direction on each iteration (ping-pong effect).

    WAAPI.animate model.animState <|
        WAAPI.loopForever
            >> WAAPI.alternate
            >> pulse

This creates a smooth ping-pong animation.
The animation plays forward, then backward, then forward, etc.

-}
alternate : AnimBuilder -> AnimBuilder
alternate =
    Builder.alternate



-- FREEZE


{-| Identifies a property that can be frozen at its current animated position.

Use with [freezeX](#freezeX), [freezeY](#freezeY), etc. to hold specific axes
at their current values during animation interruptions.

-}
type alias FreezeProperty =
    Builder.FreezeProperty


{-| Freeze the translate property.
-}
translate : FreezeProperty
translate =
    Builder.FreezeTranslate


{-| Freeze the rotate property.
-}
rotate : FreezeProperty
rotate =
    Builder.FreezeRotate


{-| Freeze the scale property.
-}
scale : FreezeProperty
scale =
    Builder.FreezeScale


{-| Freeze the X axis of the specified properties at their current animated values.

The named axis indicates which axis will remain frozen while you animate the others.

    let
        ( newAnimState, animCmd ) =
            WAAPI.animate model.animState <|
                WAAPI.freezeX [ WAAPI.translate ]
                    >> Translate.for "box"
                    >> Translate.toY 0
                    >> Translate.build
    in
    ( { model | animState = newAnimState }, animCmd )

-}
freezeX : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeX =
    Builder.freezeAxes [ "x" ]


{-| Freeze the Y axis of the specified properties at their current animated values.
-}
freezeY : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeY =
    Builder.freezeAxes [ "y" ]


{-| Freeze the Z axis of the specified properties at their current animated values.
-}
freezeZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeZ =
    Builder.freezeAxes [ "z" ]


{-| Freeze the X and Y axes of the specified properties at their current animated values.
-}
freezeXY : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeXY =
    Builder.freezeAxes [ "x", "y" ]


{-| Freeze the X and Z axes of the specified properties at their current animated values.
-}
freezeXZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeXZ =
    Builder.freezeAxes [ "x", "z" ]


{-| Freeze the Y and Z axes of the specified properties at their current animated values.
-}
freezeYZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeYZ =
    Builder.freezeAxes [ "y", "z" ]


{-| Freeze all axes of the specified properties at their current animated values.
-}
freezeXYZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
freezeXYZ =
    Builder.freezeAxes [ "x", "y", "z" ]



-- UNFREEZE


{-| Unfreeze the X axis of the specified properties, allowing it to animate again.
-}
unfreezeX : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeX =
    Builder.unfreezeAxes [ "x" ]


{-| Unfreeze the Y axis of the specified properties, allowing it to animate again.
-}
unfreezeY : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeY =
    Builder.unfreezeAxes [ "y" ]


{-| Unfreeze the Z axis of the specified properties, allowing it to animate again.
-}
unfreezeZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeZ =
    Builder.unfreezeAxes [ "z" ]


{-| Unfreeze the X and Y axes of the specified properties.
-}
unfreezeXY : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeXY =
    Builder.unfreezeAxes [ "x", "y" ]


{-| Unfreeze the X and Z axes of the specified properties.
-}
unfreezeXZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeXZ =
    Builder.unfreezeAxes [ "x", "z" ]


{-| Unfreeze the Y and Z axes of the specified properties.
-}
unfreezeYZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeYZ =
    Builder.unfreezeAxes [ "y", "z" ]


{-| Unfreeze all axes of the specified properties.
-}
unfreezeXYZ : List FreezeProperty -> AnimBuilder -> AnimBuilder
unfreezeXYZ =
    Builder.unfreezeAxes [ "x", "y", "z" ]



-- TRIGGER


{-| Trigger animations.

Returns the updated animation state and the command to send to JavaScript.

    let
        ( newAnimState, animCmd ) =
            WAAPI.animate model.animState <|
                fadeIn
                    >> slideIn
    in
    ( { model | animState = newAnimState }, animCmd )

-}
animate : AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )
animate =
    Internal.animate


{-| Execute a fire-and-forget animation without state tracking.

The animation runs entirely in the browser via the Web Animations API.

    port waapiCommand : Encode.Value -> Cmd msg

    WAAPI.fireAndForget waapiCommand <|
        fadeIn
            >> slideIn

For state management and continuity, use [animate](#animate) instead.

-}
fireAndForget : (Encode.Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg
fireAndForget =
    Internal.fireAndForget


{-| Set the transform order.

The transform order specifies how translate, rotate, and scale transforms
are combined. Start the list with the transform to apply first.

Any missing transforms are automatically appended in the default order
(Translate → Rotate → Scale).

    WAAPI.transformOrder [ Scale, Rotate, Translate ]
        >> rotateLeft
        >> scaleUp
        >> moveRight

-}
transformOrder : List TransformOrder -> AnimBuilder -> AnimBuilder
transformOrder =
    Builder.transformOrder



-- ANIMATION CONTROL


{-| Stop a running animation by instantly jumping to its end state.

    let
        ( newAnimState, stopCmd ) =
            WAAPI.stop "animGroup" model.animState
    in
    ( { model | animState = newAnimState }, stopCmd )

-}
stop : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
stop =
    Internal.stop


{-| Reset an animation by instantly jumping back to its start state.

    let
        ( newAnimState, resetCmd ) =
            WAAPI.reset "animGroup" model.animState
    in
    ( { model | animState = newAnimState }, resetCmd )

-}
reset : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
reset =
    Internal.reset


{-| Restart an animation from the beginning.

    let
        ( newAnimState, restartCmd ) =
            WAAPI.restart "animGroup" model.animState
    in
    ( { model | animState = newAnimState }, restartCmd )

-}
restart : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
restart =
    Internal.restart


{-| Pause a running animation.

    let
        ( newAnimState, pauseCmd ) =
            WAAPI.pause "animGroup" model.animState
    in
    ( { model | animState = newAnimState }, pauseCmd )

-}
pause : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
pause =
    Internal.pause


{-| Resume a paused animation.

    let
        ( newAnimState, resumeCmd ) =
            WAAPI.resume "animGroup" model.animState
    in
    ( { model | animState = newAnimState }, resumeCmd )

-}
resume : AnimGroupName -> AnimState msg -> ( AnimState msg, Cmd msg )
resume =
    Internal.resume



-- RESPONSIVE LAYOUT


{-| Handle window or container resize by repositioning elements proportionally.

This function scales element positions when their container dimensions change, maintaining their
relative positioning.

**Use case:** Responsive layouts where container size changes (window resize, sidebar toggle, orientation change, breakpoint changes, etc.)

**Example:**

    OnResize newWidth newHeight ->
        let
            newContainerWidth =
                min 500 (newWidth - 40)

            ( newAnimState, resizeCmd ) =
                WAAPI.onResize
                    [ { animGroupName = "ball"
                      , elementSize = { width = 50, height = 50 }
                      , oldContainerSize =
                            { width = model.containerSize.width
                            , height = model.containerSize.height
                            }
                      , newContainerSize =
                            { width = newContainerWidth
                            , height = 350
                            }
                      }
                    , { animGroupName = "other-element"
                      , elementSize = { width = 100, height = 100 }
                      , oldContainerSize = { width = 800, height = 600 }
                      , newContainerSize = { width = newWidth, height = newHeight }
                      }
                    ]
                    waapiCommand
                    model.animStatetate
        in
        ( { model
            | animState = newAnimState
            , containerSize = { width = newContainerWidth, height = 350 }
          }
        , resizeCmd
        )

**How it works:**

1.  Gets current position of each element (or uses element center if no position set)
2.  Calculates offset from container center
3.  Applies same offset to new container center
4.  Sends instant position update to JavaScript (no animation history)
5.  Updates AnimState with new positions

**^^ This is all wrong, and needs to be fixed. ^^**

Should not be using element center, should be using proportional position within container.
Need option for user to select proportional vs fixed offset behavior.

-}
onResize :
    List
        { animGroupName : String
        , elementSize : { width : Int, height : Int }
        , oldContainerSize : { width : Int, height : Int }
        , newContainerSize : { width : Int, height : Int }
        }
    -> AnimState msg
    -> ( AnimState msg, Cmd msg )
onResize =
    Internal.onResize



-- QUERY ANIMATION STATE


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
    Internal.isElementRunning


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

    WAAPI.getProgress "myAnimation" model.animState
    -- Just 0.5 (halfway through)

-}
getProgress : AnimGroupName -> AnimState msg -> Maybe Float
getProgress =
    Internal.getProgress



-- QUERY ANIMATED PROPERTIES: BACKGROUND COLOR


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getBackgroundColorStart : AnimGroupName -> AnimState msg -> Maybe Color
getBackgroundColorStart =
    Internal.getStartBackgroundColor


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorEnd : AnimGroupName -> AnimState msg -> Maybe Color
getBackgroundColorEnd =
    Internal.getEndBackgroundColor


{-| Get the current background color of an element based on its animation state.

Returns `Nothing` if the element has no background color animation.

Returns the start color if the animation has not started yet.

Returns the current interpolated color if the animation is running.

Returns the end color if the animation has completed.

-}
getBackgroundColorCurrent : AnimGroupName -> AnimState msg -> Maybe Color
getBackgroundColorCurrent =
    Internal.getCurrentBackgroundColor



-- QUERY ANIMATED PROPERTIES: OPACITY


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getOpacityStart : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityStart =
    Internal.getStartOpacity


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityEnd =
    Internal.getEndOpacity


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the current interpolated opacity if the animation is running.

Returns the end opacity if the animation has completed.

-}
getOpacityCurrent : AnimGroupName -> AnimState msg -> Maybe Float
getOpacityCurrent =
    Internal.getCurrentOpacity



-- QUERY ANIMATED PROPERTIES: TRANSLATE


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just {x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getTranslateStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    Internal.getStartTranslate


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    Internal.getEndTranslate


{-| Get the current translate of an element based on its animation state.

Returns `Nothing` if the element has no translate animation.

Returns the start translate if the animation has not started yet.

Returns the current interpolated translate if the animation is running.

Returns the end translate if the animation has completed.

-}
getTranslateCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent =
    Internal.getCurrentTranslate



-- QUERY ANIMATED PROPERTIES: ROTATE


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getRotateStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    Internal.getStartRotate


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    Internal.getEndRotate


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the current interpolated rotation if the animation is running.

Returns the end rotation if the animation has completed.

-}
getRotateCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent =
    Internal.getCurrentRotate



-- QUERY ANIMATED PROPERTIES: SCALE


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getScaleStart : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    Internal.getStartScale


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    Internal.getEndScale


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the current interpolated scale if the animation is running.

Returns the end scale if the animation has completed.

-}
getScaleCurrent : AnimGroupName -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent =
    Internal.getCurrentScale



-- QUERY ANIMATED PROPERTIES: SIZE


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSizeStart : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeStart =
    Internal.getStartSize


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeEnd =
    Internal.getEndSize


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the current interpolated size if the animation is running.

Returns the end size if the animation has completed.

-}
getSizeCurrent : AnimGroupName -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeCurrent =
    Internal.getCurrentSize


{-| Animation lifecycle events from the Web Animations API.
-}
type AnimEvent
    = Started AnimGroupName
    | Ended AnimGroupName
    | Cancelled AnimGroupName { progress : Float }
    | Restarted AnimGroupName
    | Paused AnimGroupName { progress : Float }
    | Resumed AnimGroupName
    | Iteration AnimGroupName Int
    | Progress AnimGroupName { progress : Float }


{-| Opaque message type.

    type Msg
        = WaapiMsg WAAPI.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Subscribe to receive animation updates from JavaScript.

Your animations will not run without this subscription.

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


{-| Handle animation lifecycle messages.

Returns the updated state and an [AnimEvent](#AnimEvent) for you to pattern match on.

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            WaapiMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        WAAPI.update animMsg model.animState
                in
                handleAnimationEvent event { model | animState = newAnimState }

    handleAnimationEvent : WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            ...

-}
update : AnimMsg -> AnimState msg -> ( AnimState msg, AnimEvent )
update msg animState =
    let
        ( newState, eventData ) =
            Internal.update msg animState
    in
    ( newState, eventDataToEvent eventData )


{-| Convert internal EventData to public AnimEvent.
-}
eventDataToEvent : Internal.EventData -> AnimEvent
eventDataToEvent eventData =
    let
        animGroup =
            eventData.animGroupName
    in
    case eventData.status of
        "progress" ->
            Progress animGroup { progress = eventData.progress }

        "started" ->
            Started animGroup

        "paused" ->
            Paused animGroup { progress = eventData.progress }

        "resumed" ->
            Resumed animGroup

        "completed" ->
            Ended animGroup

        "cancelled" ->
            Cancelled animGroup { progress = eventData.progress }

        "stopped" ->
            Ended animGroup

        "reset" ->
            Cancelled animGroup { progress = eventData.progress }

        "restarted" ->
            Restarted animGroup

        "iteration" ->
            -- Extract iteration number from progress (JS encodes it in progress field)
            Iteration animGroup (round eventData.progress)

        _ ->
            -- Fallback for unknown status (includes "unknown" from decode failures)
            Progress animGroup { progress = eventData.progress }
