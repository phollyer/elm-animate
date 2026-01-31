module Anim.Engine.WAAPI exposing
    ( AnimState, init, initProperties, AnimBuilder, builder
    , animate, fireAndForget
    , AnimationEvent(..), decode
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
  - **`waapiEvent`**: Incoming port to receive animation updates from JavaScript (only required for stateful animations)

**For fire-and-forget animations** (no state tracking):

Only the outgoing command port is needed to send animation instructions to JavaScript.

        port waapiCommand : Json.Encode.Value -> Cmd msg

**For stateful animations** (with state tracking and real-time updates):

Both outgoing command and incoming event ports are needed.

        port waapiCommand : Json.Encode.Value -> Cmd msg

        port waapiEvent : (Json.Encode.Value -> msg) -> Sub msg


# Build

@docs AnimState, init, initProperties, AnimBuilder, builder


# Animation Execution

@docs animate, fireAndForget


# Updates

The JavaScript companion library sends real-time property updates back to Elm during animations.

Updates are throttled to approximately 60 FPS (~16ms intervals) regardless of display refresh rate.
This balances real-time feedback with performance, preventing message flooding on high-refresh-rate
displays (120Hz, 144Hz, etc.) while maintaining smooth visual feedback.

@docs AnimationEvent, decode


# Animation Control

Control running animations with stop, reset, restart, pause, and resume functionality.

**WAAPI Animation Behavior:**

  - **stop**: Calls `Animation.finish()` to instantly jump to the animation's end state.
  - **reset**: Calls `Animation.cancel()` to instantly jump back to the animation's start state.
  - **restart**: Calls `Animation.cancel()` followed by `Animation.play()` to restart from the beginning.
  - **pause**: Calls `Animation.pause()` to freeze the animation at its current progress.
  - **resume**: Calls `Animation.play()` to continue a paused animation from where it was paused.

All control methods work with Web Animations API animations and trigger the appropriate animation lifecycle events.

@docs stop, reset, restart, pause, resume


# Responsive Layout

Handle window and container resizes by repositioning elements proportionally without creating animation history.

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
import Json.Encode as Encode



-- BUILD


{-| Optional State for managing animations.

This state keeps track of animations and their configurations.

    import Anim.Engine.WAAPI as WAAPI

    { model | animState : WAAPI.AnimState }

**Note:** You do not need this for fire-and-forget animations.

-}
type alias AnimState =
    Internal.AnimState


{-| Initialize empty animation state.

    import Anim.Engine.WAAPI as WAAPI

    { model | animState = WAAPI.init }

    -- Or, when you want fire-and-forget animations.

    WAAPI.init
        |> ... -- continue building the animation

-}
init : AnimState
init =
    Internal.init


{-| Animation builder type.

This is used internally to configure animations.

-}
type alias AnimBuilder =
    Internal.AnimBuilder


{-| Turn the [AnimState](#AnimState) into an [AnimBuilder](#AnimBuilder).

Use this to start building new animations.

        -- Create a new animation based on current state
        model.animState
            |> WAAPI.builder
            |> -- continue building the animation

        -- Create a new fire-and-forget animation
        WAAPI.init
            |> WAAPI.builder
            |> -- continue building the animation

-}
builder : AnimState -> AnimBuilder
builder =
    Internal.builder


{-| Set global duration in milliseconds (overrides any previous speed setting).

    model.animState
        |> WAAPI.builder
        |> WAAPI.duration 1000
        |> -- continue building the animation

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    Internal.duration


{-| Set global speed in units per second (overrides any previous duration setting).

    model.animState
        |> WAAPI.builder
        |> WAAPI.speed 100
        |> -- continue building the animation

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    Internal.speed


{-| Set global easing function.

    model.animState
        |> WAAPI.builder
        |> WAAPI.easing EaseInOutQuad
        |> ... -- continue building the animation

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Internal.easing


{-| Set global delay in milliseconds.

    model.animState
        |> WAAPI.builder
        |> WAAPI.delay 500
        |> -- continue building the animation

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    Internal.delay



-- EXECUTE


{-| Configure an animation.

Returns the updated animation state and command that talks to the JavaScript Web Animations API via ports.

    port waapiCommand : Encode.Value -> Cmd msg

    let
        ( newAnimState, animCmd ) =
            WAAPI.animate waapiCommand model.animState <|
                \builder ->
                    builder
                        |> -- configure animation

    in
    ( { model | animations = newAnimState }, animCmd )

-}
animate : (Encode.Value -> Cmd msg) -> AnimState -> (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )
animate =
    Internal.animate


{-| Initialize properties without creating animations.

All animations need a starting point to animate from. This function sets
initial property values without creating animation history. They are also used by
the accompanying JavaScript to set the initial state of the animated elements.

**Note:** If you set the same property both here and via inline CSS styles in your
view, the values set here will take precedence (JavaScript applies them after
Elm renders the view). To avoid confusion, pick one approach:

  - Use `initProperties` for initial state (no inline styles needed), or
  - Use inline styles and ensure your `from` values in animations match them

If you try to animate a property that has no initial value set, the engine
will assume sensible start values (e.g., opacity 1.0, translate {0,0,0}, etc.).

    port waapiCommand : Encode.Value -> Cmd msg

    init : Model -> ( Model, Cmd Msg )
    init model =
        let
            ( initialAnimState, initCmd ) =
                WAAPI.initProperties waapiCommand
                    [ Translate.initXY "element-id" 100 50
                    , Opacity.init "element-id" 1.0
                    ... -- more properties if needed
                    ]
        in
        ( { model | animations = initialAnimState }, initCmd )

-}
initProperties : (Encode.Value -> Cmd msg) -> List (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )
initProperties =
    Internal.initProperties


{-| Execute a fire-and-forget animation without state tracking.

Use this when you don't need to track animation state or query animated values.
The animation runs entirely in the browser via the Web Animations API.

    port waapiCommand : Encode.Value -> Cmd msg

    myAnimationCmd : Cmd msg
    myAnimationCmd =
        WAAPI.init
            |> WAAPI.builder
            |> -- configure animation
            |> WAAPI.fireAndForget waapiCommand

For state management and continuity, use `animate` instead.

-}
fireAndForget : (Encode.Value -> Cmd msg) -> AnimBuilder -> Cmd msg
fireAndForget =
    Internal.animateStateless



-- ANIMATION CONTROL


{-| Stop an animation by instantly jumping to its end state.

Sends a command to JavaScript to call the native `Animation.finish()` method.

    port waapiCommand : Encode.Value -> Cmd msg

    WAAPI.stop "my-element" waapiCommand

-}
stop : String -> (Encode.Value -> Cmd msg) -> Cmd msg
stop =
    Internal.stop


{-| Reset an animation by instantly jumping back to its start state.

Sends a command to JavaScript to cancel and reset the animation.

    port waapiCommand : Encode.Value -> Cmd msg

    let
        ( newAnimState, resetCmd ) =
            WAAPI.reset "my-element" waapiCommand model.animState
    in
    ( { model | animations = newAnimState }, resetCmd )

-}
reset : String -> (Encode.Value -> Cmd msg) -> AnimState -> ( AnimState, Cmd msg )
reset =
    Internal.reset


{-| Restart an animation from the beginning.

Sends a command to JavaScript to cancel and replay the animation.

    port waapiCommand : Encode.Value -> Cmd msg

    let
        ( newAnimState, restartCmd ) =
            WAAPI.restart "my-element" waapiCommand model.animState
    in
    ( { model | animations = newAnimState }, restartCmd )

-}
restart : String -> (Encode.Value -> Cmd msg) -> AnimState -> ( AnimState, Cmd msg )
restart =
    Internal.restart


{-| Pause a running animation for a specific element.

    port waapiCommand : Encode.Value -> Cmd msg

    WAAPI.pause "my-element" waapiCommand

-}
pause : String -> (Encode.Value -> Cmd msg) -> Cmd msg
pause =
    Internal.pause


{-| Resume a paused animation for a specific element.

    port waapiCommand : Encode.Value -> Cmd msg

    WAAPI.resume "my-element" waapiCommand

-}
resume : String -> (Encode.Value -> Cmd msg) -> Cmd msg
resume =
    Internal.resume



-- RESPONSIVE LAYOUT


{-| Handle window or container resize by repositioning elements proportionally.

This function scales element positions when their container dimensions change, maintaining their
relative positioning without creating animation history that would interfere with control functions
like reset, restart, or pause/resume.

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
    -> (Encode.Value -> Cmd msg)
    -> AnimState
    -> ( AnimState, Cmd msg )
onResize =
    Internal.onResize



-- QUERY ANIMATION STATE


{-| Check if any animations are currently running.
-}
anyRunning : AnimState -> Bool
anyRunning =
    Internal.anyRunning


{-| Check if a specific element has any animations currently running.
-}
isRunning : String -> AnimState -> Bool
isRunning =
    Internal.isElementRunning


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    Internal.allComplete


{-| Check if a specific element's animations have completed.

Returns `Nothing` if there are no animations for the element.

-}
isComplete : String -> AnimState -> Maybe Bool
isComplete =
    Internal.isElementComplete



-- QUERY ANIMATED PROPERTIES: BACKGROUND COLOR


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getStartBackgroundColor : String -> AnimState -> Maybe Color
getStartBackgroundColor =
    Internal.getStartBackgroundColor


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getEndBackgroundColor : String -> AnimState -> Maybe Color
getEndBackgroundColor =
    Internal.getEndBackgroundColor


{-| Get the current background color of an element based on its animation state.

Returns `Nothing` if the element has no background color animation.

Returns the start color if the animation has not started yet.

Returns the current interpolated color if the animation is running.

Returns the end color if the animation has completed.

-}
getCurrentBackgroundColor : String -> AnimState -> Maybe Color
getCurrentBackgroundColor =
    Internal.getCurrentBackgroundColor



-- QUERY ANIMATED PROPERTIES: OPACITY


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getStartOpacity : String -> AnimState -> Maybe Float
getStartOpacity =
    Internal.getStartOpacity


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getEndOpacity : String -> AnimState -> Maybe Float
getEndOpacity =
    Internal.getEndOpacity


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the current interpolated opacity if the animation is running.

Returns the end opacity if the animation has completed.

-}
getCurrentOpacity : String -> AnimState -> Maybe Float
getCurrentOpacity =
    Internal.getCurrentOpacity



-- QUERY ANIMATED PROPERTIES: TRANSLATE


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just {x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getStartTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartTranslate =
    Internal.getStartTranslate


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getEndTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndTranslate =
    Internal.getEndTranslate


{-| Get the current translate of an element based on its animation state.

Returns `Nothing` if the element has no translate animation.

Returns the start translate if the animation has not started yet.

Returns the current interpolated translate if the animation is running.

Returns the end translate if the animation has completed.

-}
getCurrentTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentTranslate =
    Internal.getCurrentTranslate



-- QUERY ANIMATED PROPERTIES: ROTATE


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartRotate =
    Internal.getStartRotate


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getEndRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndRotate =
    Internal.getEndRotate


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the current interpolated rotation if the animation is running.

Returns the end rotation if the animation has completed.

-}
getCurrentRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentRotate =
    Internal.getCurrentRotate



-- QUERY ANIMATED PROPERTIES: SCALE


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartScale =
    Internal.getStartScale


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getEndScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndScale =
    Internal.getEndScale


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the current interpolated scale if the animation is running.

Returns the end scale if the animation has completed.

-}
getCurrentScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentScale =
    Internal.getCurrentScale



-- QUERY ANIMATED PROPERTIES: SIZE


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartSize : String -> AnimState -> Maybe { width : Float, height : Float }
getStartSize =
    Internal.getStartSize


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getEndSize : String -> AnimState -> Maybe { width : Float, height : Float }
getEndSize =
    Internal.getEndSize


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the current interpolated size if the animation is running.

Returns the end size if the animation has completed.

-}
getCurrentSize : String -> AnimState -> Maybe { width : Float, height : Float }
getCurrentSize =
    Internal.getCurrentSize



-- PORT INTEGRATION: TYPES


{-| Animation lifecycle events from the Web Animations API.

These events notify you when animations change state, allowing you to trigger
side effects like starting the next animation in a sequence or updating the UI.

Each event carries the `elementId` of the animated element:

  - **Started elementId**: Animation has begun playing
  - **Completed elementId**: Animation finished naturally
  - **Paused elementId**: Animation was paused
  - **Resumed elementId**: Animation continued after being paused
  - **Canceled elementId**: Animation was canceled (via reset)
  - **Restarted elementId**: Animation was restarted from the beginning

-}
type AnimationEvent
    = Started String
    | Paused String
    | Resumed String
    | Completed String
    | Canceled String
    | Restarted String



-- PORT INTEGRATION: DECODE


{-| Decode WAAPI events and update animation state.

This function decodes incoming port messages and returns the updated `AnimState`
along with a `Maybe AnimationEvent` for lifecycle changes.

Property updates (translate, opacity, etc.) are automatically applied to `AnimState`.
You can query current values using getter functions by [querying animated properties](#querying-animated-properties).

**Note:** You can receive lifecycle events (Started, Completed, etc.) for fire-and-forget
animations too, but property queries won't work since fire-and-forget doesn't track state.

    port waapiEvent : (Encode.Value -> msg) -> Sub msg

    type Msg
        = GotWaapiUpdate ( WAAPI.AnimState, Maybe WAAPI.AnimationEvent )
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        waapiEvent (GotWaapiUpdate << WAAPI.decode model.animStatetate)

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotWaapiUpdate ( newAnimState, maybeEvent ) ->
                case maybeEvent of
                    Just (WAAPI.Completed "box") ->
                        -- The "box" element finished animating
                        ( { model | animationState = newAnimState }, startNextAnimation )

                    Just (WAAPI.Completed elementId) ->
                        -- Some other element finished
                        ( { model | animationState = newAnimState }, Cmd.none )

                    _ ->
                        -- Just update state (property updates, other events)
                        ( { model | animationState = newAnimState }, Cmd.none )

            ...

-}
decode : AnimState -> Encode.Value -> ( AnimState, Maybe AnimationEvent )
decode currentAnimState eventValue =
    let
        ( updatedState, maybeStatusAndId ) =
            Internal.decodeEvent eventValue currentAnimState
    in
    ( updatedState, Maybe.andThen (\( elementId, status ) -> statusStringToEvent elementId status) maybeStatusAndId )


statusStringToEvent : String -> String -> Maybe AnimationEvent
statusStringToEvent elementId status =
    case status of
        "started" ->
            Just (Started elementId)

        "paused" ->
            Just (Paused elementId)

        "resumed" ->
            Just (Resumed elementId)

        "completed" ->
            Just (Completed elementId)

        "canceled" ->
            Just (Canceled elementId)

        "restarted" ->
            Just (Restarted elementId)

        _ ->
            Nothing
