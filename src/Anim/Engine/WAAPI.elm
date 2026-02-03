module Anim.Engine.WAAPI exposing
    ( AnimState, AnimBuilder, init
    , Msg, AnimationEvent(..), update, subscriptions
    , animate, fireAndForget
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
  - **`waapiSubscription`**: Incoming port to receive property updates and lifecycle events (required for stateful animations)

**For fire-and-forget animations** (no state tracking):

Only the outgoing command port is needed to send animation instructions to JavaScript.

        port waapiCommand : Json.Encode.Value -> Cmd msg

**For stateful animations** (with state tracking, real-time updates, and lifecycle events):

Both command and subscription ports are needed.

        port waapiCommand : Json.Encode.Value -> Cmd msg

        port waapiSubscription : (Json.Decode.Value -> msg) -> Sub msg


# State

@docs AnimState, AnimBuilder, init


# Update

The JavaScript companion library sends real-time property updates and events back to Elm during animations.

Updates are throttled to approximately 60 FPS (~16ms intervals) regardless of display refresh rate.
This balances real-time feedback with performance, preventing message flooding on high-refresh-rate
displays (120Hz, 144Hz, etc.) while maintaining smooth visual feedback.

@docs Msg, AnimationEvent, update, subscriptions


# Execute

@docs animate, fireAndForget


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


# Global Settings

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

import Anim.Color exposing (Color)
import Anim.Easing exposing (Easing)
import Anim.Internal.WAAPI as Internal
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

Takes the command port, subscription port, and optional property initializers:

    -- Basic initialization
    WAAPI.init waapiCommand waapiSubscription []

    -- With initial properties
    WAAPI.init waapiCommand
        waapiSubscription
        [ Translate.initXY "element-id" 100 50
        , Opacity.init "element-id" 1.0
        ]

**Note:** If you set the same property both here and via inline CSS styles in your
view, the values set here will take precedence (JavaScript applies them after
Elm renders the view). To avoid confusion, pick one approach:

  - Use `init` with property initializers (no inline styles needed), or
  - Use inline styles and ensure your `from` values in animations match them

-}
init : (Encode.Value -> Cmd msg) -> ((Decode.Value -> msg) -> Sub msg) -> List (AnimBuilder -> AnimBuilder) -> ( AnimState msg, Cmd msg )
init =
    Internal.init


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



-- ANIMATION CONTROL


{-| Stop an animation by instantly jumping to its end state.

    let
        ( newAnimState, stopCmd ) =
            WAAPI.stop "my-element" model.animState
    in
    ( { model | animations = newAnimState }, stopCmd )

-}
stop : String -> AnimState msg -> ( AnimState msg, Cmd msg )
stop =
    Internal.stop


{-| Reset an animation by instantly jumping back to its start state.

    let
        ( newAnimState, resetCmd ) =
            WAAPI.reset "my-element" model.animState
    in
    ( { model | animations = newAnimState }, resetCmd )

-}
reset : String -> AnimState msg -> ( AnimState msg, Cmd msg )
reset =
    Internal.reset


{-| Restart an animation from the beginning.

    let
        ( newAnimState, restartCmd ) =
            WAAPI.restart "my-element" model.animState
    in
    ( { model | animations = newAnimState }, restartCmd )

-}
restart : String -> AnimState msg -> ( AnimState msg, Cmd msg )
restart =
    Internal.restart


{-| Pause a running animation for a specific element.

    let
        ( newAnimState, pauseCmd ) =
            WAAPI.pause "my-element" model.animState
    in
    ( { model | animations = newAnimState }, pauseCmd )

-}
pause : String -> AnimState msg -> ( AnimState msg, Cmd msg )
pause =
    Internal.pause


{-| Resume a paused animation for a specific element.

    let
        ( newAnimState, resumeCmd ) =
            WAAPI.resume "my-element" model.animState
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
            | animationState = newAnimState
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

Each event carries the `elementId` of the animated element.

-}
type AnimationEvent
    = Started String
    | Paused String
    | Resumed String
    | Completed String
    | Canceled String
    | Restarted String


{-| Opaque message type for WAAPI updates and subscriptions.

    type Msg
        = WaapiMsg WAAPI.Msg
        | ...

-}
type alias Msg =
    Internal.Msg


{-| Subscribe to WAAPI messages from JavaScript.

    type Msg
        = WaapiMsg WAAPI.Msg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        WAAPI.subscriptions WaapiMsg model.animState

-}
subscriptions : (Msg -> msg) -> AnimState msg -> Sub msg
subscriptions =
    Internal.subscriptions


{-| Handles both property updates and lifecycle events, returning the updated state
and a list of `AnimationEvent`s that you can pattern match on and react to.

    type Msg
        = WaapiMsg WAAPI.Msg
        | ...

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            WaapiMsg waapiMsg ->
                let
                    ( newAnimState, events ) =
                        WAAPI.update waapiMsg model.animState
                in
                handleAnimationEvents events { model | animState = newAnimState }

            ...

    handleAnimationEvents : List WAAPI.AnimationEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvents events model =
        List.foldl handleSingleEvent ( model, Cmd.none ) events

    handleSingleEvent : WAAPI.AnimationEvent -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
    handleSingleEvent event ( model, cmd ) =
        case event of
            WAAPI.Completed "box" ->
                -- The "box" element finished animating
                ( model, Cmd.batch [ cmd, startNextAnimation ] )

            _ ->
                ( model, cmd )

-}
update : Msg -> AnimState msg -> ( AnimState msg, List AnimationEvent )
update msg animState =
    let
        ( newState, rawEvents ) =
            Internal.update msg animState
    in
    ( newState
    , List.map (\( elementId, status ) -> statusStringToEvent elementId status) rawEvents
    )


statusStringToEvent : String -> String -> AnimationEvent
statusStringToEvent elementId status =
    case status of
        "started" ->
            Started elementId

        "paused" ->
            Paused elementId

        "resumed" ->
            Resumed elementId

        "completed" ->
            Completed elementId

        "canceled" ->
            Canceled elementId

        "restarted" ->
            Restarted elementId

        _ ->
            -- Fallback for unknown status (shouldn't happen with valid events)
            Started elementId
