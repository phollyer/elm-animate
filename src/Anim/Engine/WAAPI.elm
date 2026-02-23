module Anim.Engine.WAAPI exposing
    ( AnimState, AnimBuilder, init
    , animate, fireAndForget
    , TransformOrder(..), animateOrder, fireAndForgetOrder
    , forElement
    , AnimMsg, AnimEvent(..), EventInfo, PropertyConfig, update, subscriptions
    , attributes
    , stop, reset, restart, pause, resume
    , onResize
    , duration, speed
    , easing
    , delay
    , anyRunning, isRunning, allComplete, isComplete
    , getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor
    , getStartOpacity, getEndOpacity, getCurrentOpacity
    , getStartTranslate, getEndTranslate, getCurrentTranslate
    , getStartRotate, getEndRotate, getCurrentRotate
    , getStartScale, getEndScale, getCurrentScale
    , getStartSize, getEndSize, getCurrentSize
    )

{-| Ports-based animation system with optional state tracking.

This Engine converts [AnimBuilder](#AnimBuilder) configurations to [JavaScript Web Animations API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Animations_API)
calls via Elm [ports](https://guide.elm-lang.org/interop/ports) for maximum performance and browser compatibility.

**Note:** This module requires the accompanying JavaScript library to handle the Web Animations API.


## Design Decisions


### State Tracking vs Fire-and-Forget

This Engine supports both state-tracked animations and fire-and-forget animations.

**State-tracked** animations allow you to query the state of your animations.
Use [animate](#animate) when you need to:

  - Query if animations are running or complete
  - Query start/end/current values of animated properties
  - Chain animations that continue from the previous end state
  - Use animation controls (pause, resume, stop, reset, restart)

**Fire-and-forget** animations don't require `AnimState` in your model.
Use [fireAndForget](#fireAndForget) when you don't need any of the above.


## JavaScript Companion

Install the `elm-animate-waapi` package from npm.

        npm install elm-animate-waapi

Then import and initialize it in your JavaScript code:

```javascript
    import ElmAnimateWAAPI from 'elm-animate-waapi';

    const app = Elm.Main.init({ ... });

    ElmAnimateWAAPI.init(app.ports);
```


## Ports

The JavaScript companion automatically connects to these ports when you call `ElmAnimateWAAPI.init(app.ports)` in your JavaScript code.

  - **`waapiCommand`**: Outgoing port to send animation commands to JavaScript (always required)
  - **`waapiEvent`**: Incoming port to receive animation lifecycle events (required for stateful animations)

**For fire-and-forget animations** (no state tracking):

Only the outgoing command port is needed to send animation instructions to JavaScript.

        port waapiCommand : Json.Encode.Value -> Cmd msg

**For stateful animations** (with state tracking, real-time updates, and lifecycle events):

Both ports are needed.

        port waapiCommand : Json.Encode.Value -> Cmd msg

        port waapiEvent : (Json.Decode.Value -> msg) -> Sub msg


# State

@docs AnimState, AnimBuilder, init


# Execute

@docs animate, fireAndForget

@docs TransformOrder, animateOrder, fireAndForgetOrder


# Element Targeting

@docs forElement


# Update

The JavaScript companion library sends real-time property updates and events back to Elm during animations.

Updates are throttled to approximately 60 FPS (~16ms intervals) regardless of display refresh rate.
This balances real-time feedback with performance, preventing message flooding on high-refresh-rate
displays (120Hz, 144Hz, etc.) while maintaining smooth visual feedback.

@docs AnimMsg, AnimEvent, EventInfo, PropertyConfig, update, subscriptions


# View

@docs attributes


# Animation Control

Control running animations with stop, reset, restart, pause, and resume functionality.

**WAAPI Animation Behavior:**

  - **stop**: Instantly jump to the animation's end state.
  - **reset**: Instantly jump back to the animation's start state.
  - **restart**: Instantly jump back to the animation's start state, then start playing.
  - **pause**: Freeze the animation at its current progress.
  - **resume**: Continue a paused animation from where it was paused.

All control methods work with Web Animations API animations and trigger the appropriate animation lifecycle events.

@docs stop, reset, restart, pause, resume


# Responsive Layout

Handle window and container resizes by repositioning elements proportionally.

@docs onResize


# Default Settings

These settings will be used for all animations unless overridden on a per-property basis.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay


# Querying Animation State

@docs anyRunning, isRunning, allComplete, isComplete


# Querying Animated Properties

**When tracking state in your model**: WAAPI animations provide direct mid-flight access to the current values of animated properties through the Web Animations API.
This engine tracks the start, end, and current values of all animated properties, allowing you to query them in real-time
during animation playback.


## Background Color

@docs getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor


## Opacity

@docs getStartOpacity, getEndOpacity, getCurrentOpacity


## Translate

@docs getStartTranslate, getEndTranslate, getCurrentTranslate


## Rotate

@docs getStartRotate, getEndRotate, getCurrentRotate


## Scale

@docs getStartScale, getEndScale, getCurrentScale


## Size

@docs getStartSize, getEndSize, getCurrentSize

-}

import Anim.Extra.Color exposing (Color)
import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.WAAPI as Internal
import Html
import Json.Decode as Decode
import Json.Encode as Encode



-- BUILD


{-| Optional State for managing animations.

This state keeps track of animations and their configurations.

The `msg` type parameter is your `Msg` type.

    import Anim.Engine.WAAPI as WAAPI

    type Msg
        = ...

    type alias Model =
        { animState : WAAPI.AnimState Msg
        , ...
        }

**Note:** You do not need this for fire-and-forget animations.

-}
type alias AnimState msg =
    Internal.AnimState msg


{-| Initialize animation state.

Takes the command port, event port, and optional property initializers:

    -- Basic initialization
    WAAPI.init waapiCommand waapiEvent []

    -- With initial properties
    WAAPI.init waapiCommand waapiEvent <|
        [ Translate.initXY "animGroupName" 100 50
        , Opacity.init "animGroupName" 1.0
        ]

Use [attributes](#attributes) in your view to apply these initial property values as CSS inline styles.

-}
init : (Encode.Value -> Cmd msg) -> ((Decode.Value -> msg) -> Sub msg) -> List (AnimBuilder -> AnimBuilder) -> AnimState msg
init =
    Internal.init


{-| Get HTML attributes that apply the current animation state as inline styles.

Use this in your view to apply initial property values and maintain state between animations:

    view model =
        div
            ([ id elementId ]
                ++ WAAPI.attributes elementId model.animState
            )
            [ text "Hello World!" ]

-}
attributes : String -> AnimState msg -> List (Html.Attribute msg)
attributes =
    Internal.attributes


{-| Animation builder type.

This is used internally to configure animations.

-}
type alias AnimBuilder =
    Internal.AnimBuilder


{-| Set global duration in milliseconds (overrides any previous speed setting).

    WAAPI.animate waapiCommand model.animState <|
        (WAAPI.duration 1000
            >> ... -- continue building the animation
        )

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Internal.duration


{-| Set global speed in units per second (overrides any previous duration setting).

    WAAPI.animate waapiCommand model.animState <|
        (WAAPI.speed 100
            >> ... -- continue building the animation
        )

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    Internal.speed


{-| Set global easing function.

    WAAPI.animate waapiCommand model.animState <|
        (WAAPI.easing EaseInOutQuad
            >> ... -- continue building the animation
        )

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Internal.easing


{-| Set global delay in milliseconds.

    WAAPI.animate waapiCommand model.animState <|
        (WAAPI.delay 500
            >> ... -- continue building the animation
        )

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Internal.delay


{-| Set the ID of the element being animated.

    -- Define reusable animations
    fadeIn : AnimBuilder -> AnimBuilder
    fadeIn =
        Opacity.for "animGroupName"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

    slideIn : AnimBuilder -> AnimBuilder
    slideIn =
        Translate.for "animGroupName"
            >> Translate.fromX -100
            >> Translate.toX 0
            >> Translate.build

    -- Apply to multiple elements
    WAAPI.animate model.animState <|
        (WAAPI.forElement "card-1"
            >> fadeIn
            >> slideIn
            >> WAAPI.forElement "card-2"
            >> fadeIn
        )

-}
forElement : String -> AnimBuilder -> AnimBuilder
forElement =
    Builder.setWaapiTargetElement



-- EXECUTE


{-| Configure an animation.

Returns the updated animation state and the command to execute the animation.

    let
        ( newAnimState, animCmd ) =
            WAAPI.animate model.animState <|
                \builder ->
                    builder
                        |> -- configure animation

    in
    ( { model | animations = newAnimState }, animCmd )

-}
animate : AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )
animate =
    Internal.animate


{-| Type for specifying the order in which transform operations are applied.

CSS transforms are applied left to right, so `[Rotate, Translate, Scale]` means:

1.  Rotate first
2.  Translate second
3.  Scale last

The order significantly affects the final result - rotating then translating
produces different results than translating then rotating.

-}
type TransformOrder
    = Translate
    | Rotate
    | Scale


{-| Convert public TransformOrder to internal TransformOrder.
-}
toInternalTransformOrder : TransformOrder -> Internal.TransformOrder
toInternalTransformOrder order =
    case order of
        Translate ->
            Internal.Translate

        Rotate ->
            Internal.Rotate

        Scale ->
            Internal.Scale


{-| Animate with a custom transform order.

Use this when you need transforms applied in a specific order.
Start the list with the transform you want applied first (outermost).

    WAAPI.animateOrder [ Rotate, Translate, Scale ] model.animState <|
        \builder ->
            builder
                |> -- configure animation

Any missing transforms are automatically appended in the default order
(Translate → Rotate → Scale), so `[Scale]` becomes `[Scale, Translate, Rotate]`.

-}
animateOrder : List TransformOrder -> AnimState msg -> (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )
animateOrder order animState buildAnimation =
    Internal.animateWithOrder (List.map toInternalTransformOrder order) animState buildAnimation


{-| Execute a fire-and-forget animation without state tracking.

Use this when you don't need to track animation state or query animated values.
The animation runs entirely in the browser via the Web Animations API.

    port waapiCommand : Encode.Value -> Cmd msg

    myAnimationCmd : Cmd msg
    myAnimationCmd =
        WAAPI.fireAndForget waapiCommand <|
            \builder ->
                builder
                    |> -- configure animation

For state management and continuity, use [animate](#animate) instead.

-}
fireAndForget : (Encode.Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg
fireAndForget =
    Internal.fireAndForget


{-| Fire-and-forget animation with custom transform order.

    port waapiCommand : Encode.Value -> Cmd msg

    myAnimationCmd : Cmd msg
    myAnimationCmd =
        WAAPI.fireAndForgetOrder [ Rotate, Translate, Scale ] waapiCommand <|
            \builder ->
                builder
                    |> -- configure animation

-}
fireAndForgetOrder : List TransformOrder -> (Encode.Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg
fireAndForgetOrder order portFunction buildAnimation =
    Internal.fireAndForgetWithOrder (List.map toInternalTransformOrder order) portFunction buildAnimation



-- ANIMATION CONTROL


{-| Stop an animation by instantly jumping to its end state.

    let
        ( newAnimState, stopCmd ) =
            WAAPI.stop "elementId" model.animState
    in
    ( { model | animations = newAnimState }, stopCmd )

-}
stop : String -> AnimState msg -> ( AnimState msg, Cmd msg )
stop =
    Internal.stop


{-| Reset an animation by instantly jumping back to its start state.

    let
        ( newAnimState, resetCmd ) =
            WAAPI.reset "elementId" model.animState
    in
    ( { model | animations = newAnimState }, resetCmd )

-}
reset : String -> AnimState msg -> ( AnimState msg, Cmd msg )
reset =
    Internal.reset


{-| Restart an animation from the beginning.

    let
        ( newAnimState, restartCmd ) =
            WAAPI.restart "elementId" model.animState
    in
    ( { model | animations = newAnimState }, restartCmd )

-}
restart : String -> AnimState msg -> ( AnimState msg, Cmd msg )
restart =
    Internal.restart


{-| Pause a running animation for a specific element.

    let
        ( newAnimState, pauseCmd ) =
            WAAPI.pause "elementId" model.animState
    in
    ( { model | animations = newAnimState }, pauseCmd )

-}
pause : String -> AnimState msg -> ( AnimState msg, Cmd msg )
pause =
    Internal.pause


{-| Resume a paused animation for a specific element.

    let
        ( newAnimState, resumeCmd ) =
            WAAPI.resume "elementId" model.animState
    in
    ( { model | animations = newAnimState }, resumeCmd )

-}
resume : String -> AnimState msg -> ( AnimState msg, Cmd msg )
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
                    [ { elementId = "ball"
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
                    , { elementId = "other-element"
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
        { elementId : String
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
-}
anyRunning : AnimState msg -> Bool
anyRunning =
    Internal.anyRunning


{-| Check if a specific element has any animations currently running.
-}
isRunning : String -> AnimState msg -> Bool
isRunning =
    Internal.isElementRunning


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState msg -> Maybe Bool
allComplete =
    Internal.allComplete


{-| Check if a specific element's animations have completed.

Returns `Nothing` if there are no animations for the element.

-}
isComplete : String -> AnimState msg -> Maybe Bool
isComplete =
    Internal.isElementComplete



-- QUERY ANIMATED PROPERTIES: BACKGROUND COLOR


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getStartBackgroundColor : String -> AnimState msg -> Maybe Color
getStartBackgroundColor =
    Internal.getStartBackgroundColor


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getEndBackgroundColor : String -> AnimState msg -> Maybe Color
getEndBackgroundColor =
    Internal.getEndBackgroundColor


{-| Get the current background color of an element based on its animation state.

Returns `Nothing` if the element has no background color animation.

Returns the start color if the animation has not started yet.

Returns the current interpolated color if the animation is running.

Returns the end color if the animation has completed.

-}
getCurrentBackgroundColor : String -> AnimState msg -> Maybe Color
getCurrentBackgroundColor =
    Internal.getCurrentBackgroundColor



-- QUERY ANIMATED PROPERTIES: OPACITY


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getStartOpacity : String -> AnimState msg -> Maybe Float
getStartOpacity =
    Internal.getStartOpacity


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getEndOpacity : String -> AnimState msg -> Maybe Float
getEndOpacity =
    Internal.getEndOpacity


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the current interpolated opacity if the animation is running.

Returns the end opacity if the animation has completed.

-}
getCurrentOpacity : String -> AnimState msg -> Maybe Float
getCurrentOpacity =
    Internal.getCurrentOpacity



-- QUERY ANIMATED PROPERTIES: TRANSLATE


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just {x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getStartTranslate : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getStartTranslate =
    Internal.getStartTranslate


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getEndTranslate : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getEndTranslate =
    Internal.getEndTranslate


{-| Get the current translate of an element based on its animation state.

Returns `Nothing` if the element has no translate animation.

Returns the start translate if the animation has not started yet.

Returns the current interpolated translate if the animation is running.

Returns the end translate if the animation has completed.

-}
getCurrentTranslate : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getCurrentTranslate =
    Internal.getCurrentTranslate



-- QUERY ANIMATED PROPERTIES: ROTATE


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartRotate : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getStartRotate =
    Internal.getStartRotate


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getEndRotate : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getEndRotate =
    Internal.getEndRotate


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the current interpolated rotation if the animation is running.

Returns the end rotation if the animation has completed.

-}
getCurrentRotate : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getCurrentRotate =
    Internal.getCurrentRotate



-- QUERY ANIMATED PROPERTIES: SCALE


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartScale : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getStartScale =
    Internal.getStartScale


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getEndScale : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getEndScale =
    Internal.getEndScale


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the current interpolated scale if the animation is running.

Returns the end scale if the animation has completed.

-}
getCurrentScale : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getCurrentScale =
    Internal.getCurrentScale



-- QUERY ANIMATED PROPERTIES: SIZE


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartSize : String -> AnimState msg -> Maybe { width : Float, height : Float }
getStartSize =
    Internal.getStartSize


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getEndSize : String -> AnimState msg -> Maybe { width : Float, height : Float }
getEndSize =
    Internal.getEndSize


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the current interpolated size if the animation is running.

Returns the end size if the animation has completed.

-}
getCurrentSize : String -> AnimState msg -> Maybe { width : Float, height : Float }
getCurrentSize =
    Internal.getCurrentSize


{-| Animation lifecycle events from the Web Animations API.

These events notify you when animations change state, allowing you to trigger
side effects like starting the next animation in a sequence or updating the UI.

Each event carries the `elementId` and `animGroup` of the animated element, along
with contextual data. Lifecycle events include full `EventInfo` with duration,
progress, and property configurations. `Changed` events (fired per-frame) include
only progress to minimize overhead.

    case event of
        WAAPI.Ended "box" "fadeIn" info ->
            -- The "box" element finished the "fadeIn" animation
            -- info.duration tells you how long it took
            -- info.properties has the animation configuration
            ...

        WAAPI.Iteration "box" "pulse" iterationNumber info ->
            -- Animation completed iteration number (1-based)
            ...

        WAAPI.Changed "box" "fadeIn" { progress } ->
            -- Animation in progress, progress is 0.0 to 1.0
            ...

-}
type AnimEvent
    = Started String String EventInfo
    | Ended String String EventInfo
    | Cancelled String String EventInfo
    | Restarted String String EventInfo
    | Paused String String EventInfo
    | Resumed String String EventInfo
    | Iteration String String Int EventInfo
    | Changed String String { progress : Float }


{-| Information about an animation event.

  - `duration`: The maximum duration across all animated properties (in milliseconds)
  - `progress`: Current progress from 0.0 to 1.0 (0.0 for Started, 1.0 for Ended)
  - `properties`: List of property configurations being animated

-}
type alias EventInfo =
    { duration : Int
    , progress : Float
    , properties : List PropertyConfig
    }


{-| Configuration for a single animated property.

  - `property`: Property type name ("translate", "opacity", "scale", etc.)
  - `from`: Starting value as a string (e.g., "100,50,0" for translate, "0.5" for opacity, "rgb(255,0,0)" for colors)
  - `to`: Ending value as a string
  - `duration`: Duration for this property in milliseconds
  - `easing`: Easing function name

Use Elm's built-in parsers (`String.toFloat`, `String.toInt`) or string splitting
to extract numeric values when needed.

-}
type alias PropertyConfig =
    { property : String
    , from : String
    , to : String
    , duration : Int
    , easing : String
    }


{-| Opaque message type for WAAPI updates and subscriptions.

    type Msg
        = WaapiMsg WAAPI.AnimMsg
        | ...

-}
type alias AnimMsg =
    Internal.AnimMsg


{-| Subscribe to WAAPI messages from JavaScript.

    type Msg
        = WaapiMsg WAAPI.Msg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions WaapiMsg model.animState

-}
subscriptions : (AnimMsg -> msg) -> AnimState msg -> Sub msg
subscriptions =
    Internal.subscriptions


{-| Handles both property updates and lifecycle events, returning the updated state
and an `AnimEvent` that you can pattern match on and react to.

    type Msg
        = WaapiMsg WAAPI.AnimMsg
        | ...

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            WaapiMsg waapiMsg ->
                let
                    ( newAnimState, event ) =
                        WAAPI.update waapiMsg model.animState
                in
                handleAnimationEvent event { model | animState = newAnimState }

            ...

    handleAnimationEvent : WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            WAAPI.Ended "box" "fadeIn" info ->
                -- The "box" element finished the "fadeIn" animation
                -- info.duration, info.progress, info.properties available
                ( model, startNextAnimation )

            WAAPI.Changed _ _ { progress } ->
                -- Property update during animation (fires frequently)
                -- progress is 0.0 to 1.0
                ( model, Cmd.none )

            _ ->
                -- Other lifecycle events
                ( model, Cmd.none )

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
        elementId =
            eventData.elementId

        animGroup =
            eventData.animGroup

        eventInfo =
            { duration = eventData.duration
            , progress = eventData.progress
            , properties = List.map internalToPublicPropertyConfig eventData.properties
            }
    in
    case eventData.status of
        "changed" ->
            Changed elementId animGroup { progress = eventData.progress }

        "started" ->
            Started elementId animGroup eventInfo

        "paused" ->
            Paused elementId animGroup eventInfo

        "resumed" ->
            Resumed elementId animGroup eventInfo

        "completed" ->
            Ended elementId animGroup eventInfo

        "cancelled" ->
            Cancelled elementId animGroup eventInfo

        "stopped" ->
            Ended elementId animGroup eventInfo

        "reset" ->
            Cancelled elementId animGroup eventInfo

        "restarted" ->
            Restarted elementId animGroup eventInfo

        "iteration" ->
            -- Extract iteration number from progress (JS encodes it in progress field)
            Iteration elementId animGroup (round eventData.progress) eventInfo

        _ ->
            -- Fallback for unknown status (includes "unknown" from decode failures)
            Changed elementId animGroup { progress = eventData.progress }


{-| Convert internal PropertyConfig to public PropertyConfig.
-}
internalToPublicPropertyConfig : Internal.PropertyConfig -> PropertyConfig
internalToPublicPropertyConfig internal =
    { property = internal.property
    , from = internal.from
    , to = internal.to
    , duration = internal.duration
    , easing = internal.easing
    }
