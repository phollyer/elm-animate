module Anim.Engine.WAAPI exposing
    ( AnimState, init, AnimBuilder, builder
    , animate, fireAndForget
    , XYZ, PropertyData, AnimationStatus(..), EventType(..), decode
    , stop, reset, restart, pause, resume
    , onResize
    , duration, speed
    , easing
    , delay
    , perspective
    , perspectiveWith
    , anyRunning, isRunning, allComplete, isComplete
    , getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor
    , getStartOpacity, getEndOpacity, getCurrentOpacity
    , getStartPosition, getEndPosition, getCurrentPosition
    , getStartRotate, getEndRotate, getCurrentRotate
    , getStartScale, getEndScale, getCurrentScale
    , getStartSize, getEndSize, getCurrentSize
    , initProperties
    )

{-| Ports-based animation system utilising the Web Animations API with optional state tracking.

This Engine converts [AnimBuilder](#AnimBuilder) configurations to JavaScript Web Animations API calls
via Elm ports for maximum performance and browser compatibility.

**Note:** This module requires the accompanying JavaScript library to handle the Web Animations API.


## Required JavaScript Companion

Install the `elm-animate-waapi` package from npm.

        npm install elm-animate-waapi

Then import and initialize it in your JavaScript code:

```javascript
    import ElmAnimateWAAPI from 'elm-animate-waapi';

    const app = Elm.Main.init({ ... });

    ElmAnimateWAAPI.init(app.ports);
```


## Required Ports

**For fire-and-forget animations** (no state tracking):

Only the outgoing command port is needed to send animation instructions to JavaScript.

        port waapiCommand : Json.Encode.Value -> Cmd msg

**For stateful animations** (with state tracking and real-time updates):

Both outgoing command and incoming event ports are needed.

        port waapiCommand : Json.Encode.Value -> Cmd msg

        port waapiEvent : (Json.Encode.Value -> msg) -> Sub msg

  - **`waapiCommand`**: Outgoing port to send animation commands to JavaScript (always required)
  - **`waapiEvent`**: Incoming port to receive animation updates from JavaScript (only needed for [animate](#animate), not for [fireAndForget](#fireAndForget))

The JavaScript companion automatically connects to these ports when you call `ElmAnimateWAAPI.init(app.ports)` in your JavaScript code.


# Build

@docs AnimState, init, AnimBuilder, builder


# Animation Execution

@docs animate, fireAndForget


# Updates

The JavaScript companion library sends real-time property updates back to Elm during animations.

Updates are throttled to approximately 60 FPS (~16ms intervals) regardless of display refresh rate.
This balances real-time feedback with performance, preventing message flooding on high-refresh-rate
displays (120Hz, 144Hz, etc.) while maintaining smooth visual feedback.

@docs XYZ, PropertyData, AnimationStatus, EventType, decode


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

These settings will be used for all animations unless overridden on a per-animation basis.
So if you want all your animations to have the same duration, easing, etc., you can set them here
rather than repeating them for each property animation.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay


# 3D Animations

For 3D animations you need to set a perspective to give a sense of depth. Without perspective,
3D animations will have no visual effect, and will appear flat.


## Perspective

@docs perspective


## HTML

@docs perspectiveWith


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


## Position

@docs getStartPosition, getEndPosition, getCurrentPosition


## Rotate

@docs getStartRotate, getEndRotate, getCurrentRotate


## Scale

@docs getStartScale, getEndScale, getCurrentScale


## Size

@docs getStartSize, getEndSize, getCurrentSize

-}

import Anim.Color exposing (Color)
import Anim.Easing exposing (Easing)
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position as Position
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.WAAPI as InternalWAAPI
import Html
import Json.Decode as Decode
import Json.Encode as Encode



-- Build


{-| Optional State for managing animations.

This state keeps track of animations and their configurations.

    import Anim.Engine.WAAPI as WAAPI

    { model | animations : WAAPI.AnimState }

**Note:** You do not need this for fire-and-forget animations.

-}
type alias AnimState =
    InternalWAAPI.AnimState


{-| Initialize empty animation state.

    import Anim.Engine.WAAPI as WAAPI

    { model | animations = WAAPI.init }

    -- Or, when you want fire-and-forget animations.

    WAAPI.init
        |> ... -- continue building the animation

-}
init : AnimState
init =
    InternalWAAPI.init


{-| Animation builder type.

This is used internally to configure animations.

-}
type alias AnimBuilder =
    InternalWAAPI.AnimBuilder


{-| Turn the [AnimState](#AnimState) into an [AnimBuilder](#AnimBuilder).

Use this to start building new animations.

        -- Create a new animation based on current state
        model.animations
            |> WAAPI.builder
            |> -- continue building the animation

        -- Create a new fire-and-forget animation
        WAAPI.init
            |> WAAPI.builder
            |> -- continue building the animation

-}
builder : AnimState -> AnimBuilder
builder =
    InternalWAAPI.builder


{-| Set global duration in milliseconds (overrides any previous speed setting).

    model.animations
        |> WAAPI.builder
        |> WAAPI.duration 1000
        |> -- continue building the animation

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalWAAPI.duration


{-| Set global speed in units per second (overrides any previous duration setting).

    model.animations
        |> WAAPI.builder
        |> WAAPI.speed 100
        |> -- continue building the animation

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalWAAPI.speed


{-| Set global easing function.

    model.animations
        |> WAAPI.builder
        |> WAAPI.easing EaseInOutQuad
        |> ... -- continue building the animation

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalWAAPI.easing


{-| Set global delay in milliseconds.

    model.animations
        |> WAAPI.builder
        |> WAAPI.delay 500
        |> -- continue building the animation

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalWAAPI.delay


{-| Set the global perspective value for 3D transforms.

The perspective value determines the distance between the viewer and the `z = 0` plane.
A smaller value creates a more pronounced 3D effect, while a larger value creates
a more subtle effect.

**Important:** The `containerId` must match the `id` attribute of the DOM container element.
The JavaScript will automatically apply perspective CSS to this container.

    div
        [ id "my-container" ]
        [ div
            [ id "animated-element" ]
            [ text "3D content" ]
        ]

    model.animations
        |> WAAPI.builder
        |> WAAPI.perspective "my-container" 1000
        |> -- continue building the animation
        |> WAAPI.animate

You can override this global setting for specific properties using property-specific `perspective` functions.

-}
perspective : String -> Float -> AnimBuilder -> AnimBuilder
perspective =
    InternalWAAPI.perspective


{-| Manually generate HTML attributes with a given perspective value.

Perspective controls the viewer's distance from the 3D scene (not zoom/magnification).
Lower values create more dramatic 3D effects, higher values create more subtle effects.

Can be applied to any ancestor element of 3D-transformed children, not just direct parents.
Set this on the root node for global effect, and override on specific containers as needed.

Common values: 500-2000px.

    -- Adjust 3D depth effect dynamically

    update msg model =
        case msg of
            IncreaseDepth ->
                { model | viewerDistance = model.viewerDistance - 100 }

            DecreaseDepth ->
                { model | viewerDistance = model.viewerDistance + 100 }


    div
        (WAAPI.perspectiveWith model.viewerDistance)
        [ -- Animated content with 3D transforms
        ]

**Elm-side styles take precedence**: When you use this function, the JavaScript will detect
the existing inline style and skip auto-applying perspective, giving you full control.

-}
perspectiveWith : Float -> List (Html.Attribute msg)
perspectiveWith =
    InternalWAAPI.perspectiveWith



-- Execute


{-| Configure an animation.

Returns the updated animation state and command that talks to the JavaScript Web Animations API via ports.

    port waapiCommand : Encode.Value -> Cmd msg

    let
        ( newAnimState, animCmd ) =
            WAAPI.animate waapiCommand model.animations <|
                \builder ->
                    builder
                        |> -- configure animation

    in
    ( { model | animations = newAnimState }, animCmd )

-}
animate : (Encode.Value -> Cmd msg) -> AnimState -> (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )
animate portCmd animState buildAnimation =
    let
        ( newAnimState, animationData ) =
            InternalWAAPI.animate animState buildAnimation
    in
    ( newAnimState, portCmd animationData )


{-| Initialize properties without creating animations.

Use this in your `init` function to set initial property values without animation history.
This keeps AnimState and JavaScript in sync without polluting animation history.

    port waapiCommand : Encode.Value -> Cmd msg

    init : Model -> ( Model, Cmd Msg )
    init model =
        let
            ( initialAnimState, initCmd ) =
                WAAPI.initProperties waapiCommand
                    [ Position.initXY "element-id" 100 50
                    , Opacity.init "element-id" 1.0

                    -- more properties if needed
                    ]
        in
        ( { model | animations = initialAnimState }, initCmd )

-}
initProperties : (Encode.Value -> Cmd msg) -> List (AnimBuilder -> AnimBuilder) -> ( AnimState, Cmd msg )
initProperties portCmd propertyInitializers =
    let
        ( newAnimState, initData ) =
            InternalWAAPI.initProperties propertyInitializers
    in
    ( newAnimState, portCmd initData )


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
    InternalWAAPI.animateStateless



-- Animation Control


{-| Stop an animation by instantly jumping to its end state.

Sends a command to JavaScript to call the native `Animation.finish()` method.

    port waapiCommand : Encode.Value -> Cmd msg

    WAAPI.stop "my-element" waapiCommand

-}
stop : String -> (Encode.Value -> Cmd msg) -> Cmd msg
stop elementId portCmd =
    portCmd (encodeCommand StopCommand elementId Encode.null)


{-| Reset an animation by instantly jumping back to its start state.

Sends a command to JavaScript to cancel and reset the animation.

    port waapiCommand : Encode.Value -> Cmd msg

    let
        ( newAnimState, resetCmd ) =
            WAAPI.reset "my-element" waapiCommand model.animations
    in
    ( { model | animations = newAnimState }, resetCmd )

-}
reset : String -> (Encode.Value -> Cmd msg) -> AnimState -> ( AnimState, Cmd msg )
reset elementId portCmd animState =
    let
        ( newAnimState, resetData ) =
            InternalWAAPI.resetElement elementId animState
    in
    ( newAnimState, portCmd resetData )


{-| Restart an animation from the beginning.

Sends a command to JavaScript to cancel and replay the animation.

    port waapiCommand : Encode.Value -> Cmd msg

    let
        ( newAnimState, restartCmd ) =
            WAAPI.restart "my-element" waapiCommand model.animations
    in
    ( { model | animations = newAnimState }, restartCmd )

-}
restart : String -> (Encode.Value -> Cmd msg) -> AnimState -> ( AnimState, Cmd msg )
restart elementId portCmd animState =
    let
        ( newAnimState, restartData ) =
            InternalWAAPI.restartElement elementId animState
    in
    ( newAnimState, portCmd restartData )


{-| Pause a running animation for a specific element.

    port waapiCommand : Encode.Value -> Cmd msg

    WAAPI.pause "my-element" waapiCommand

-}
pause : String -> (Encode.Value -> Cmd msg) -> Cmd msg
pause elementId portCmd =
    portCmd (encodeCommand PauseCommand elementId Encode.null)


{-| Resume a paused animation for a specific element.

    port waapiCommand : Encode.Value -> Cmd msg

    WAAPI.resume "my-element" waapiCommand

-}
resume : String -> (Encode.Value -> Cmd msg) -> Cmd msg
resume elementId portCmd =
    portCmd (encodeCommand ResumeCommand elementId Encode.null)



-- Responsive Layout


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
                    model.animationState
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
onResize elements portCmd animState =
    let
        updates =
            List.filterMap (calculateResizePosition animState) elements

        ( newAnimState, updateData ) =
            InternalWAAPI.updatePositions updates animState
    in
    ( newAnimState, portCmd updateData )


{-| Calculate new position for an element after container resize.
-}
calculateResizePosition :
    AnimState
    ->
        { elementId : String
        , elementSize : { width : Int, height : Int }
        , oldContainerSize : { width : Int, height : Int }
        , newContainerSize : { width : Int, height : Int }
        }
    -> Maybe { elementId : String, x : Float, y : Float, z : Float }
calculateResizePosition animState { elementId, elementSize, oldContainerSize, newContainerSize } =
    let
        -- Only reposition if dimensions actually changed
        dimensionsChanged =
            oldContainerSize.width /= newContainerSize.width || oldContainerSize.height /= newContainerSize.height
    in
    if not dimensionsChanged then
        Nothing

    else
        let
            -- Calculate center positions
            oldCenterX =
                toFloat oldContainerSize.width / 2 - (toFloat elementSize.width / 2)

            oldCenterY =
                toFloat oldContainerSize.height / 2 - (toFloat elementSize.height / 2)

            newCenterX =
                toFloat newContainerSize.width / 2 - (toFloat elementSize.width / 2)

            newCenterY =
                toFloat newContainerSize.height / 2 - (toFloat elementSize.height / 2)

            -- Get current position or default to old center
            currentPos =
                InternalWAAPI.getCurrentPosition elementId animState
                    |> Maybe.map Position.toRecord
                    |> Maybe.withDefault { x = oldCenterX, y = oldCenterY, z = 0 }

            -- Calculate offset from old center
            offsetX =
                currentPos.x - oldCenterX

            offsetY =
                currentPos.y - oldCenterY

            -- Apply same offset to new center
            newX =
                newCenterX + offsetX

            newY =
                newCenterY + offsetY
        in
        Just
            { elementId = elementId
            , x = newX
            , y = newY
            , z = currentPos.z
            }



-- Query Animation State


{-| Check if any animations are currently running.
-}
anyRunning : AnimState -> Bool
anyRunning =
    InternalWAAPI.anyRunning


{-| Check if a specific element has any animations currently running.
-}
isRunning : String -> AnimState -> Bool
isRunning =
    InternalWAAPI.isElementRunning


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    InternalWAAPI.allComplete


{-| Check if a specific element's animations have completed.

Returns `Nothing` if there are no animations for the element.

-}
isComplete : String -> AnimState -> Maybe Bool
isComplete =
    InternalWAAPI.isElementComplete



-- Query Animated Properties
--
--
-- Background Color


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getStartBackgroundColor : String -> AnimState -> Maybe Color
getStartBackgroundColor =
    InternalWAAPI.getStartBackgroundColor


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getEndBackgroundColor : String -> AnimState -> Maybe Color
getEndBackgroundColor =
    InternalWAAPI.getEndBackgroundColor


{-| Get the current background color of an element based on its animation state.

Returns `Nothing` if the element has no background color animation.

Returns the start color if the animation has not started yet.

Returns the current interpolated color if the animation is running.

Returns the end color if the animation has completed.

-}
getCurrentBackgroundColor : String -> AnimState -> Maybe Color
getCurrentBackgroundColor =
    InternalWAAPI.getCurrentBackgroundColor



-- Opacity


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getStartOpacity : String -> AnimState -> Maybe Float
getStartOpacity elementId animState =
    InternalWAAPI.getStartOpacity elementId animState
        |> Maybe.map Opacity.toFloat


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getEndOpacity : String -> AnimState -> Maybe Float
getEndOpacity elementId animState =
    InternalWAAPI.getEndOpacity elementId animState
        |> Maybe.map Opacity.toFloat


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the current interpolated opacity if the animation is running.

Returns the end opacity if the animation has completed.

-}
getCurrentOpacity : String -> AnimState -> Maybe Float
getCurrentOpacity elementId animState =
    InternalWAAPI.getCurrentOpacity elementId animState
        |> Maybe.map Opacity.toFloat



-- Position


{-| Get the start position of an element being animated.

Returns `Nothing` if the element has no position animation.

Returns `Just {x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getStartPosition : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartPosition elementId animState =
    InternalWAAPI.getStartPosition elementId animState
        |> Maybe.map Position.toRecord


{-| Get the end position of an element being animated.

Returns `Nothing` if the element has no position animation.

-}
getEndPosition : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndPosition elementId animState =
    InternalWAAPI.getEndPosition elementId animState
        |> Maybe.map Position.toRecord


{-| Get the current position of an element based on its animation state.

Returns `Nothing` if the element has no position animation.

Returns the start position if the animation has not started yet.

Returns the current interpolated position if the animation is running.

Returns the end position if the animation has completed.

-}
getCurrentPosition : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentPosition elementId animState =
    InternalWAAPI.getCurrentPosition elementId animState
        |> Maybe.map Position.toRecord



-- Rotate


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartRotate elementId animState =
    InternalWAAPI.getStartRotate elementId animState
        |> Maybe.map Rotate.toRecord


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getEndRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndRotate elementId animState =
    InternalWAAPI.getEndRotate elementId animState
        |> Maybe.map Rotate.toRecord


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the current interpolated rotation if the animation is running.

Returns the end rotation if the animation has completed.

-}
getCurrentRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentRotate elementId animState =
    InternalWAAPI.getCurrentRotate elementId animState
        |> Maybe.map Rotate.toRecord



-- Scale


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartScale elementId animState =
    InternalWAAPI.getStartScale elementId animState
        |> Maybe.map Scale.toRecord


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getEndScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndScale elementId animState =
    InternalWAAPI.getEndScale elementId animState
        |> Maybe.map Scale.toRecord


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the current interpolated scale if the animation is running.

Returns the end scale if the animation has completed.

-}
getCurrentScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentScale elementId animState =
    InternalWAAPI.getCurrentScale elementId animState
        |> Maybe.map Scale.toRecord



-- Size


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartSize : String -> AnimState -> Maybe { width : Float, height : Float }
getStartSize elementId animState =
    InternalWAAPI.getStartSize elementId animState
        |> Maybe.map Size.toRecord


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getEndSize : String -> AnimState -> Maybe { width : Float, height : Float }
getEndSize elementId animState =
    InternalWAAPI.getEndSize elementId animState
        |> Maybe.map Size.toRecord


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the current interpolated size if the animation is running.

Returns the end size if the animation has completed.

-}
getCurrentSize : String -> AnimState -> Maybe { width : Float, height : Float }
getCurrentSize elementId animState =
    InternalWAAPI.getCurrentSize elementId animState
        |> Maybe.map Size.toRecord



-- PORT INTEGRATION


{-| Command types for WAAPI port communication.

These are used internally by the sendCommand function.

-}
type CommandType
    = AnimateCommand
    | StopCommand
    | PauseCommand
    | ResumeCommand
    | ResetCommand
    | RestartCommand


{-| Animation status for lifecycle events.
-}
type AnimationStatus
    = Started
    | Paused
    | Resumed
    | Completed
    | Canceled
    | Restarted


{-| 3D coordinate type.
-}
type alias XYZ =
    { x : Float, y : Float, z : Float }


{-| Property data received from JavaScript during animations.

Each animated property is wrapped in `Maybe` to distinguish between:

  - `Nothing`: Property is not being animated
  - `Just value`: Property is being animated with current value

-}
type alias PropertyData =
    { elementId : String
    , isAnimating : Bool
    , backgroundColor : Maybe Color
    , color : Maybe Color -- Font color
    , opacity : Maybe Float
    , position : Maybe XYZ
    , rotation : Maybe XYZ
    , scale : Maybe XYZ
    , size : Maybe { width : Float, height : Float }
    }


{-| Event types defining the incoming events from JavaScript.
-}
type EventType
    = PropertyUpdate PropertyData
    | AnimationUpdate AnimationStatus


{-| Internal function to encode WAAPI commands for JavaScript.
-}
encodeCommand : CommandType -> String -> Encode.Value -> Encode.Value
encodeCommand commandType elementId payload =
    Encode.object
        [ ( "type", encodeCommandType commandType )
        , ( "elementId", Encode.string elementId )
        , ( "payload", payload )
        ]


{-| Internal function to encode command types.
-}
encodeCommandType : CommandType -> Encode.Value
encodeCommandType commandType =
    case commandType of
        AnimateCommand ->
            Encode.string "animate"

        StopCommand ->
            Encode.string "stop"

        PauseCommand ->
            Encode.string "pause"

        ResumeCommand ->
            Encode.string "resume"

        ResetCommand ->
            Encode.string "reset"

        RestartCommand ->
            Encode.string "restart"


{-| Decode WAAPI events and update animation state.

This function handles JSON decoding and automatically applies property updates to your animation state.
It returns a message with both the event type and updated state.

**Note:** For fire-and-forget animations, you don't need this - animations run entirely in JavaScript.

    port waapiEvent : (Encode.Value -> msg) -> Sub msg

    type Msg
        = GotWaapiUpdate WAAPI.EventType WAAPI.AnimState
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        waapiEvent <|
            WAAPI.decode GotWaapiUpdate model.animationState

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotWaapiUpdate eventType newAnimState ->
                let
                    newModel =
                        { model | animationState = newAnimState }
                in
                case eventType of
                    WAAPI.PropertyUpdate _ ->
                        -- Handle property updates if needed
                        (newModel, Cmd.none )

                    WAAPI.AnimationUpdate _ ->
                        -- Handle animation status changes if needed
                        ( newModel, Cmd.none )

            ...

-}
decode : (EventType -> AnimState -> msg) -> AnimState -> Encode.Value -> msg
decode toMsg currentAnimState eventValue =
    case decodeEvent eventValue of
        Ok eventType ->
            let
                updatedAnimState =
                    case eventType of
                        PropertyUpdate propertyData ->
                            -- Automatically apply property updates
                            InternalWAAPI.update (encodePropertyData propertyData) currentAnimState

                        AnimationUpdate _ ->
                            -- Animation status changes don't modify AnimState
                            currentAnimState
            in
            toMsg eventType updatedAnimState

        Err _ ->
            -- On decode errors, return unchanged state
            toMsg (AnimationUpdate Canceled) currentAnimState


{-| Internal function to decode WAAPI events from JavaScript.
-}
decodeEvent : Encode.Value -> Result String EventType
decodeEvent value =
    case
        Decode.decodeValue
            (Decode.map3 (\eventType targetElementId payload -> ( eventType, targetElementId, payload ))
                (Decode.field "type" Decode.string)
                (Decode.field "elementId" Decode.string)
                (Decode.field "payload" Decode.value)
            )
            value
    of
        Ok ( eventTypeString, _, payload ) ->
            case eventTypeString of
                "propertyUpdate" ->
                    case decodePropertyData payload of
                        Ok propertyData ->
                            Ok (PropertyUpdate propertyData)

                        Err error ->
                            Err ("Property decode error: " ++ error)

                "animationUpdate" ->
                    case decodeAnimationStatus payload of
                        Ok status ->
                            Ok (AnimationUpdate status)

                        Err error ->
                            Err ("Animation status decode error: " ++ error)

                _ ->
                    Err ("Unknown event type: " ++ eventTypeString)

        Err error ->
            Err (Decode.errorToString error)


{-| Decode animation status from JavaScript payload.
-}
decodeAnimationStatus : Encode.Value -> Result String AnimationStatus
decodeAnimationStatus payload =
    case Decode.decodeValue (Decode.field "status" Decode.string) payload of
        Ok "started" ->
            Ok Started

        Ok "paused" ->
            Ok Paused

        Ok "resumed" ->
            Ok Resumed

        Ok "completed" ->
            Ok Completed

        Ok "canceled" ->
            Ok Canceled

        Ok "restarted" ->
            Ok Restarted

        Ok unknown ->
            Err ("Unknown animation status: " ++ unknown)

        Err error ->
            Err (Decode.errorToString error)


xyzDecoder : Decode.Decoder XYZ
xyzDecoder =
    Decode.map3 (\x y z -> { x = x, y = y, z = z })
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)
        (Decode.field "z" Decode.float)


{-| Decode property data from JavaScript payload.
-}
decodePropertyData : Encode.Value -> Result String PropertyData
decodePropertyData payload =
    let
        sizeDecoder =
            Decode.map2 (\w h -> { width = w, height = h })
                (Decode.field "width" Decode.float)
                (Decode.field "height" Decode.float)
    in
    Decode.decodeValue
        (Decode.succeed PropertyData
            |> andMap (Decode.field "elementId" Decode.string)
            |> andMap (Decode.oneOf [ Decode.field "isAnimating" Decode.bool, Decode.succeed True ])
            |> andMap (Decode.maybe (Decode.field "backgroundColor" colorDecoder))
            -- Font color
            |> andMap (Decode.maybe (Decode.field "color" colorDecoder))
            |> andMap (Decode.maybe (Decode.field "opacity" Decode.float))
            |> andMap (Decode.maybe (Decode.field "position" xyzDecoder))
            |> andMap (Decode.maybe (Decode.field "rotation" xyzDecoder))
            |> andMap (Decode.maybe (Decode.field "scale" xyzDecoder))
            |> andMap (Decode.maybe (Decode.field "size" sizeDecoder))
        )
        payload
        |> Result.mapError Decode.errorToString


colorDecoder : Decode.Decoder Color
colorDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case Anim.Color.fromString str of
                    Just color ->
                        Decode.succeed color

                    Nothing ->
                        Decode.fail ("Invalid color string: " ++ str)
            )


colorToCssString : Color -> String
colorToCssString color =
    let
        rgba =
            Anim.Color.toRgba color
    in
    "rgba("
        ++ String.fromInt rgba.r
        ++ ", "
        ++ String.fromInt rgba.g
        ++ ", "
        ++ String.fromInt rgba.b
        ++ ", "
        ++ String.fromFloat rgba.a
        ++ ")"


encodeXYZ : XYZ -> Encode.Value
encodeXYZ { x, y, z } =
    Encode.object
        [ ( "x", Encode.float x )
        , ( "y", Encode.float y )
        , ( "z", Encode.float z )
        ]


{-| Encode PropertyData back to JSON for internal use with decode function.
-}
encodePropertyData : PropertyData -> Encode.Value
encodePropertyData data =
    let
        encodePosition pos =
            [ ( "position", encodeXYZ pos ) ]

        encodeRotation rot =
            [ ( "rotation", encodeXYZ rot ) ]

        encodeScale scl =
            [ ( "scale", encodeXYZ scl ) ]

        encodeSize sz =
            [ ( "size"
              , Encode.object
                    [ ( "width", Encode.float sz.width )
                    , ( "height", Encode.float sz.height )
                    ]
              )
            ]

        optionalFields =
            List.concat
                [ Maybe.map (\c -> [ ( "backgroundColor", Encode.string (colorToCssString c) ) ]) data.backgroundColor |> Maybe.withDefault []
                , Maybe.map (\c -> [ ( "color", Encode.string (colorToCssString c) ) ]) data.color |> Maybe.withDefault []
                , Maybe.map (\o -> [ ( "opacity", Encode.float o ) ]) data.opacity |> Maybe.withDefault []
                , Maybe.map encodePosition data.position |> Maybe.withDefault []
                , Maybe.map encodeRotation data.rotation |> Maybe.withDefault []
                , Maybe.map encodeScale data.scale |> Maybe.withDefault []
                , Maybe.map encodeSize data.size |> Maybe.withDefault []
                ]
    in
    Encode.object
        ([ ( "elementId", Encode.string data.elementId )
         , ( "isAnimating", Encode.bool data.isAnimating )
         ]
            ++ optionalFields
        )


{-| Helper function for applying decoders in sequence.

Simpler than adding [Json.Decode.Extra](https://package.elm-lang.org/packages/elm/json/latest/Json-Decode-Extra)
as a dependency just to get [andMap](https://package.elm-lang.org/packages/elm/json/latest/Json-Decode-Extra#andMap).

-}
andMap : Decode.Decoder a -> Decode.Decoder (a -> b) -> Decode.Decoder b
andMap =
    Decode.map2 (|>)
