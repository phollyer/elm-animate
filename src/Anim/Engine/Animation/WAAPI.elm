module Anim.Engine.Animation.WAAPI exposing
    ( AnimState, AnimBuilder, AnimGroupName
    , init
    , animate, fireAndForget
    , AnimEvent(..)
    , AnimMsg, update
    , subscriptions
    , attributes
    , delay
    , duration, speed
    , easing
    , iterations, loopForever, alternate
    , stop, reset, restart, pause, resume
    , transformOrder
    , discreteEntry, discreteExit
    , FreezeProperty, translate, rotate, scale
    , freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ
    , unfreezeX, unfreezeXY, unfreezeXYZ, unfreezeXZ, unfreezeY, unfreezeYZ, unfreezeZ
    , anyRunning, isRunning, allComplete, isComplete, getProgress
    , getBackgroundColorRange, getBackgroundColorStart, getBackgroundColorEnd, getBackgroundColorCurrent
    , getFontColorRange, getFontColorStart, getFontColorEnd, getFontColorCurrent
    , getOpacityRange, getOpacityStart, getOpacityEnd, getOpacityCurrent
    , getRotateRange, getRotateStart, getRotateEnd, getRotateCurrent
    , getScaleRange, getScaleStart, getScaleEnd, getScaleCurrent
    , getSizeRange, getSizeStart, getSizeEnd, getSizeCurrent
    , getTranslateRange, getTranslateStart, getTranslateEnd, getTranslateCurrent
    --, onResize
    )

{-| Run animations using the Web Animations API via ports for maximum performance.

Requires the `elm-animate-waapi` JavaScript companion library.

For specific Engine guides, setup instructions, and examples, see the
[WAAPI Engine Documentation](https://phollyer.github.io/elm-animate/engines/animation/waapi/).

For Engine comparisons, shared features, examples and code, see the
[Engine Overview](https://phollyer.github.io/elm-animate/engines/animation/overview/) section in the docs.


# Types

@docs AnimState, AnimBuilder, AnimGroupName


# Initialize

@docs init

📖 See [Initialize](https://phollyer.github.io/elm-animate/animation-workflow/init/) in the docs.


# Trigger

@docs animate, fireAndForget

📖 See [Triggering Animations](https://phollyer.github.io/elm-animate/animation-workflow/trigger/) in the docs.


# Events

@docs AnimEvent

📖 See [Event Reference](https://phollyer.github.io/elm-animate/animation-workflow/react/#event-reference) in the docs.


# Update

@docs AnimMsg, update

📖 See [React](https://phollyer.github.io/elm-animate/animation-workflow/react/) in the docs.


# Subscriptions

@docs subscriptions

📖 See [Subscriptions](https://phollyer.github.io/elm-animate/engines/animation/waapi/#subscriptions) in the docs.


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


# Animation Control

@docs stop, reset, restart, pause, resume

📖 See [Controlling Animations](https://phollyer.github.io/elm-animate/concepts/controlling-animations/) in the docs.


# Transform Order

@docs transformOrder

📖 See [Transform Ordering](https://phollyer.github.io/elm-animate/concepts/transform-order/) in the docs.


# Discrete Properties

@docs discreteEntry, discreteExit

📖 See [Discrete Properties](https://phollyer.github.io/elm-animate/concepts/discrete-properties/) in the docs.


# Freeze

@docs FreezeProperty, translate, rotate, scale

@docs freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ

📖 See [Interrupting Animations](https://phollyer.github.io/elm-animate/concepts/interruptions/) in the docs.


# Unfreeze

@docs unfreezeX, unfreezeXY, unfreezeXYZ, unfreezeXZ, unfreezeY, unfreezeYZ, unfreezeZ

📖 See [Interrupting Animations](https://phollyer.github.io/elm-animate/concepts/interruptions/) in the docs.


# State Queries

@docs anyRunning, isRunning, allComplete, isComplete, getProgress

📖 See [State Queries](https://phollyer.github.io/elm-animate/engines/animation/waapi/#state-queries) in the docs.


# Property Queries

See [Property Queries](https://phollyer.github.io/elm-animate/engines/animation/waapi/#property-queries) and
[Properties](https://phollyer.github.io/elm-animate/getting-started/properties/) in the docs.


## Background Color

@docs getBackgroundColorRange, getBackgroundColorStart, getBackgroundColorEnd, getBackgroundColorCurrent

## Font Color

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
import Anim.Internal.Engine.Animation.WAAPI as Internal
import Html
import Json.Decode as Decode
import Json.Encode as Encode



{- **** MODEL **** -}


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


{-| Apply the animation `attributes` to your element.

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
    Internal.iterations


{-| Make an animation loop infinitely.

    WAAPI.animate model.animState <|
        WAAPI.loopForever
            >> pulse

-}
loopForever : AnimBuilder -> AnimBuilder
loopForever =
    Internal.loopForever


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
    Internal.alternate



-- DISCRETE PROPERTIES


{-| Add a discrete CSS property for entry animations.

The value is applied as an inline style from the first frame and held throughout
the animation. Use this when an element is appearing (e.g., going from
`display: none` to `display: block`).

    WAAPI.animate model.animState <|
        WAAPI.discreteEntry "display" "block"
            >> WAAPI.discreteEntry "visibility" "visible"
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

    WAAPI.animate model.animState <|
        WAAPI.discreteExit "display" "block" "none"
            >> fadeOut

-}
discreteExit : String -> String -> String -> AnimBuilder -> AnimBuilder
discreteExit =
    Internal.discreteExit



-- FREEZE


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



-- UNFREEZE


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
transformOrder : List TransformProperty -> AnimBuilder -> AnimBuilder
transformOrder =
    Internal.transformOrder



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



{- ***** PROPERTY QUERIES ***** -}
--
--
{- *** BACKGROUND COLOR *** -}


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getBackgroundColorStart : AnimGroupName -> AnimState msg -> Maybe Color
getBackgroundColorStart =
    Internal.getBackgroundColorStart


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorEnd : AnimGroupName -> AnimState msg -> Maybe Color
getBackgroundColorEnd =
    Internal.getBackgroundColorEnd


{-| Get the current background color of an element based on its animation state.

Returns `Nothing` if the element has no background color animation.

Returns the start color if the animation has not started yet.

Returns the current interpolated color if the animation is running.

Returns the end color if the animation has completed.

-}
getBackgroundColorCurrent : AnimGroupName -> AnimState msg -> Maybe Color
getBackgroundColorCurrent =
    Internal.getBackgroundColorCurrent


{-| Get the background color range (start and end) of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange =
    Internal.getBackgroundColorRange



{- *** FONT COLOR *** -}


{-| Get the start font color of an element being animated.

Returns `Nothing` if the element has no font color animation.

Returns `opaque black (rgba 0 0 0 1)` if no explicit start value was set, which is the default when no start value is set.

-}
getFontColorStart : AnimGroupName -> AnimState msg -> Maybe Color
getFontColorStart =
    Internal.getFontColorStart


{-| Get the end font color of an element being animated.

Returns `Nothing` if the element has no font color animation.

-}
getFontColorEnd : AnimGroupName -> AnimState msg -> Maybe Color
getFontColorEnd =
    Internal.getFontColorEnd


{-| Get the current font color of an element based on its animation state.

Returns `Nothing` if the element has no font color animation.

-}
getFontColorCurrent : AnimGroupName -> AnimState msg -> Maybe Color
getFontColorCurrent =
    Internal.getFontColorCurrent


{-| Get the font color range (start and end) of an element being animated.

Returns `Nothing` if the element has no font color animation.

-}
getFontColorRange : AnimGroupName -> AnimState msg -> Maybe { start : Maybe Color, end : Color }
getFontColorRange =
    Internal.getFontColorRange



{- *** OPACITY *** -}


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



{- *** TRANSLATE *** -}


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



{- *** ROTATE *** -}


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



{- *** SCALE *** -}


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



{- *** SIZE *** -}


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


{-| Animation lifecycle events from the Web Animations API.
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


{-| Internal message type.

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
        ( newState, internalEvent ) =
            Internal.update msg animState
    in
    ( newState, toAnimEvent internalEvent )


{-| Convert internal AnimEvent to public AnimEvent.
-}
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
