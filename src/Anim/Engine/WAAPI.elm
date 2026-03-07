module Anim.Engine.WAAPI exposing
    ( AnimState, AnimBuilder, init
    , animate, fireAndForget
    , TransformOrder(..), transformOrder
    , forElement
    , AnimMsg, AnimEvent(..), update, subscriptions
    , attributes
    , stop, reset, restart, pause, resume
    , onResize
    , duration, speed
    , easing
    , delay
    , iterations, loopForever, alternate
    , anyRunning, isRunning, allComplete, isComplete
    , getBackgroundColorStart, getBackgroundColorEnd, getBackgroundColorCurrent
    , getOpacityStart, getOpacityEnd, getOpacityCurrent
    , getTranslateStart, getTranslateEnd, getTranslateCurrent
    , getRotateStart, getRotateEnd, getRotateCurrent
    , getScaleStart, getScaleEnd, getScaleCurrent
    , getSizeStart, getSizeEnd, getSizeCurrent
    )

{-| Web Animations API engine via ports for maximum performance.

Requires the `elm-animate-waapi` JavaScript companion library.

For detailed guides, setup instructions, and engine comparisons, see the
[full documentation](https://phollyer.github.io/elm-animate/engines/waapi/).


# State

@docs AnimState, AnimBuilder, init


# Execute

@docs animate, fireAndForget

@docs TransformOrder, transformOrder


# Element Targeting

@docs forElement


# Update

@docs AnimMsg, AnimEvent, update, subscriptions


# View

@docs attributes


# Animation Control

@docs stop, reset, restart, pause, resume


# Responsive Layout

@docs onResize


# Builder Settings

@docs duration, speed

@docs easing

@docs delay

@docs iterations, loopForever, alternate


# Querying Animation State

@docs anyRunning, isRunning, allComplete, isComplete


# Querying Animated Properties


## Background Color

@docs getBackgroundColorStart, getBackgroundColorEnd, getBackgroundColorCurrent


## Opacity

@docs getOpacityStart, getOpacityEnd, getOpacityCurrent


## Translate

@docs getTranslateStart, getTranslateEnd, getTranslateCurrent


## Rotate

@docs getRotateStart, getRotateEnd, getRotateCurrent


## Scale

@docs getScaleStart, getScaleEnd, getScaleCurrent


## Size

@docs getSizeStart, getSizeEnd, getSizeCurrent

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


{-| Set how many times an animation should repeat.

    WAAPI.animate waapiCommand model.animState <|
        (WAAPI.iterations 3
            >> ... -- Animation will play 3 times
        )

-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    Builder.iterations


{-| Make an animation loop infinitely.

    WAAPI.animate waapiCommand model.animState <|
        (WAAPI.loopForever
            >> ... -- Animation will loop continuously
        )

The animation will continue until you call `stop`, `reset`, or remove the element.

-}
loopForever : AnimBuilder -> AnimBuilder
loopForever =
    Builder.loopForever


{-| Make an animation alternate direction on each iteration (ping-pong effect).

    WAAPI.animate waapiCommand model.animState <|
        (WAAPI.loopForever >> WAAPI.alternate
            >> ... -- Animation will ping-pong continuously
        )

This creates a smooth ping-pong animation without needing reverse keyframes.
The animation plays forward, then backward, then forward, etc.

-}
alternate : AnimBuilder -> AnimBuilder
alternate =
    Builder.alternate


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
toInternalTransformOrder : TransformOrder -> Builder.TransformOrder
toInternalTransformOrder order =
    case order of
        Translate ->
            Builder.Translate

        Rotate ->
            Builder.Rotate

        Scale ->
            Builder.Scale


{-| Set the transform order for all future animations.

The transform order specifies how translate, rotate, and scale transforms
are combined. Start the list with the transform to apply first.

Any missing transforms are automatically appended in the default order
(Translate → Rotate → Scale), so `[Scale]` becomes `[Scale, Translate, Rotate]`.

    model.animState
        |> WAAPI.animate
            (WAAPI.transformOrder [ Rotate, Translate, Scale ]
                >> rotateLeft
                >> moveRight
                >> scaleUp
            )

-}
transformOrder : List TransformOrder -> AnimBuilder -> AnimBuilder
transformOrder order =
    Builder.transformOrder (List.map toInternalTransformOrder order)


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
getBackgroundColorStart : String -> AnimState msg -> Maybe Color
getBackgroundColorStart =
    Internal.getStartBackgroundColor


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorEnd : String -> AnimState msg -> Maybe Color
getBackgroundColorEnd =
    Internal.getEndBackgroundColor


{-| Get the current background color of an element based on its animation state.

Returns `Nothing` if the element has no background color animation.

Returns the start color if the animation has not started yet.

Returns the current interpolated color if the animation is running.

Returns the end color if the animation has completed.

-}
getBackgroundColorCurrent : String -> AnimState msg -> Maybe Color
getBackgroundColorCurrent =
    Internal.getCurrentBackgroundColor



-- QUERY ANIMATED PROPERTIES: OPACITY


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getOpacityStart : String -> AnimState msg -> Maybe Float
getOpacityStart =
    Internal.getStartOpacity


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : String -> AnimState msg -> Maybe Float
getOpacityEnd =
    Internal.getEndOpacity


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the current interpolated opacity if the animation is running.

Returns the end opacity if the animation has completed.

-}
getOpacityCurrent : String -> AnimState msg -> Maybe Float
getOpacityCurrent =
    Internal.getCurrentOpacity



-- QUERY ANIMATED PROPERTIES: TRANSLATE


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just {x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getTranslateStart : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    Internal.getStartTranslate


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    Internal.getEndTranslate


{-| Get the current translate of an element based on its animation state.

Returns `Nothing` if the element has no translate animation.

Returns the start translate if the animation has not started yet.

Returns the current interpolated translate if the animation is running.

Returns the end translate if the animation has completed.

-}
getTranslateCurrent : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent =
    Internal.getCurrentTranslate



-- QUERY ANIMATED PROPERTIES: ROTATE


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getRotateStart : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    Internal.getStartRotate


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    Internal.getEndRotate


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the current interpolated rotation if the animation is running.

Returns the end rotation if the animation has completed.

-}
getRotateCurrent : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent =
    Internal.getCurrentRotate



-- QUERY ANIMATED PROPERTIES: SCALE


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getScaleStart : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    Internal.getStartScale


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    Internal.getEndScale


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the current interpolated scale if the animation is running.

Returns the end scale if the animation has completed.

-}
getScaleCurrent : String -> AnimState msg -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent =
    Internal.getCurrentScale



-- QUERY ANIMATED PROPERTIES: SIZE


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSizeStart : String -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeStart =
    Internal.getStartSize


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : String -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeEnd =
    Internal.getEndSize


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the current interpolated size if the animation is running.

Returns the end size if the animation has completed.

-}
getSizeCurrent : String -> AnimState msg -> Maybe { width : Float, height : Float }
getSizeCurrent =
    Internal.getCurrentSize


{-| Animation lifecycle events from the Web Animations API.

These events notify you when animations change state, allowing you to trigger
side effects like starting the next animation in a sequence or updating the UI.

Events carry two `String` values: `elementId` and `animGroup`.

  - `elementId`: The HTML `id` attribute of the animated element.
  - `animGroup`: The animation group name.

The `Paused`, `Cancelled`, and `Changed` events include a `{ progress : Float }`
record with the current progress (0.0 to 1.0). `Iteration` includes the iteration count.

    case event of
        WAAPI.Ended "box" "fadeIn" ->
            -- The "box" element finished the "fadeIn" animation
            ...

        WAAPI.Iteration "box" "pulse" iterationNumber ->
            -- Animation completed iteration number (1-based)
            ...

        WAAPI.Paused "box" "fadeIn" { progress } ->
            -- Animation paused, progress is where it stopped
            ...

        WAAPI.Cancelled "box" "fadeIn" { progress } ->
            -- Animation was cancelled, progress shows where it was
            ...

        WAAPI.Changed "box" "fadeIn" { progress } ->
            -- Animation in progress, progress is 0.0 to 1.0
            ...

-}
type AnimEvent
    = Started String String
    | Ended String String
    | Cancelled String String { progress : Float }
    | Restarted String String
    | Paused String String { progress : Float }
    | Resumed String String
    | Iteration String String Int
    | Changed String String { progress : Float }


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
            WaapiMsg subMsg ->
                let
                    ( animState, event ) =
                        WAAPI.update subMsg model.animState
                in
                handleAnimationEvent event { model | animState = animState }

            ...

    handleAnimationEvent : WAAPI.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            WAAPI.Ended "box" "fadeIn" ->
                -- The "box" element finished the "fadeIn" animation
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
    in
    case eventData.status of
        "changed" ->
            Changed elementId animGroup { progress = eventData.progress }

        "started" ->
            Started elementId animGroup

        "paused" ->
            Paused elementId animGroup { progress = eventData.progress }

        "resumed" ->
            Resumed elementId animGroup

        "completed" ->
            Ended elementId animGroup

        "cancelled" ->
            Cancelled elementId animGroup { progress = eventData.progress }

        "stopped" ->
            Ended elementId animGroup

        "reset" ->
            Cancelled elementId animGroup { progress = eventData.progress }

        "restarted" ->
            Restarted elementId animGroup

        "iteration" ->
            -- Extract iteration number from progress (JS encodes it in progress field)
            Iteration elementId animGroup (round eventData.progress)

        _ ->
            -- Fallback for unknown status (includes "unknown" from decode failures)
            Changed elementId animGroup { progress = eventData.progress }
