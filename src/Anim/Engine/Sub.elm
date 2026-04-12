module Anim.Engine.Sub exposing
    ( AnimState, AnimBuilder, AnimGroupName
    , init
    , attributes
    , animate
    , AnimMsg, update
    , AnimEvent(..)
    , subscriptions
    , FreezeProperty, translate, rotate, scale
    , freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ
    , unfreezeX, unfreezeY, unfreezeZ, unfreezeXY, unfreezeXZ, unfreezeYZ, unfreezeXYZ
    , transformOrder
    , stop, reset, restart, pause, resume
    , delay
    , duration, speed
    , easing
    , iterations, loopForever, alternate
    , discreteEntry, discreteExit
    , anyRunning, isRunning, allComplete, isComplete
    , getProgress
    , getBackgroundColorStart, getBackgroundColorEnd, getBackgroundColorCurrent
    , getOpacityStart, getOpacityEnd, getOpacityCurrent
    , getRotateStart, getRotateEnd, getRotateCurrent
    , getScaleStart, getScaleEnd, getScaleCurrent
    , getSizeStart, getSizeEnd, getSizeCurrent
    , getTranslateStart, getTranslateEnd, getTranslateCurrent
    )

{-| Subscription-based animation engine with frame-by-frame control.

For detailed guides, examples, and engine comparisons, see the
[full documentation](https://phollyer.github.io/elm-animate/engines/sub/).


# Types

@docs AnimState, AnimBuilder, AnimGroupName


# Initialize

@docs init


# Render

@docs attributes


# Trigger

@docs animate


# Update

@docs AnimMsg, update


# Anim Events

@docs AnimEvent


# Subscriptions

@docs subscriptions


# Freeze

@docs FreezeProperty, translate, rotate, scale

@docs freezeX, freezeY, freezeZ, freezeXY, freezeXZ, freezeYZ, freezeXYZ


# Unfreeze

@docs unfreezeX, unfreezeY, unfreezeZ, unfreezeXY, unfreezeXZ, unfreezeYZ, unfreezeXYZ


# Transform Order

@docs transformOrder


# Animation Control

@docs stop, reset, restart, pause, resume


# Playback Settings

@docs delay

@docs duration, speed

@docs easing

@docs iterations, loopForever, alternate


# Discrete Properties

@docs discreteEntry, discreteExit


# Querying Animation State

@docs anyRunning, isRunning, allComplete, isComplete


# Querying Animation Progress

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
import Anim.Internal.Builder.BackgroundColor as BackgroundColor
import Anim.Internal.Engine.Animation.Sub as InternalSub
import Anim.Internal.Property.Opacity as Opacity
import Anim.Internal.Property.Rotate as Rotate
import Anim.Internal.Property.Scale as Scale
import Anim.Internal.Property.Size as Size
import Anim.Internal.Property.Translate as Translate
import Html


{-| Animation builder type for configuring animations.
-}
type alias AnimBuilder =
    Builder.AnimBuilder



-- TYPES


{-| A type alias for animation group names.

Used to identify which animation group to target in functions like
[attributes](#attributes), [isRunning](#isRunning), [stop](#stop), etc.

-}
type alias AnimGroupName =
    String


{-| The animation state type used to store animation configurations.

Store it in your model.

    type alias Model =
        { animState : Sub.AnimState }

-}
type alias AnimState =
    InternalSub.AnimState



-- INIT


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

    Sub.animate model.animState <|
        Sub.freezeX [ Sub.translate ]
            >> Translate.for "box"
            >> Translate.toY 0
            >> Translate.build

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



-- TRANSFORM ORDER


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
transformOrder : List TransformOrder -> AnimBuilder -> AnimBuilder
transformOrder =
    Builder.transformOrder


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


{-| Set the global delay in milliseconds.

    Sub.animate model.animState <|
        Sub.delay 500
            >> slideIn

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalSub.delay


{-| Set how many times an animation should repeat.

    Sub.animate model.animState <|
        Sub.iterations 3
            >> pulse

-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    Builder.iterations


{-| Make an animation loop infinitely.

    Sub.animate model.animState <|
        Sub.loopForever
            >> pulse

-}
loopForever : AnimBuilder -> AnimBuilder
loopForever =
    Builder.loopForever


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
    Builder.alternate



-- DISCRETE PROPERTIES


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
    Builder.discreteEntry


{-| Add a discrete CSS property for exit animations.

Exit properties hold their `from` value as an inline style throughout the
animation and flip to their `to` value on the final frame. Use this when an
element is disappearing (e.g., going from `display: block` to `display: none`).

    Sub.animate model.animState <|
        Sub.discreteExit "display" "block" "none"
            >> fadeOut

-}
discreteExit : String -> String -> String -> AnimBuilder -> AnimBuilder
discreteExit =
    Builder.discreteExit



-- UPDATE


{-| Opaque message type.

    type Msg
        = SubMsg Sub.AnimMsg
        | ...

-}
type alias AnimMsg =
    InternalSub.AnimMsg


{-| Subscription animation lifecycle events.
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
            Just (Progress key { progress = progressValue })


toControlAnimEvent : InternalSub.ControlEvent -> Maybe AnimEvent
toControlAnimEvent event =
    case event of
        InternalSub.Started key ->
            Just (Started key)

        InternalSub.Cancelled key progressValue ->
            Just (Cancelled key { progress = progressValue })

        InternalSub.Paused key progressValue ->
            Just (Paused key { progress = progressValue })

        InternalSub.Resumed key ->
            Just (Resumed key)

        InternalSub.Restarted key ->
            Just (Restarted key)



-- SUBSCRIPTIONS


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
    InternalSub.isAnimationRunning


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    InternalSub.allComplete


{-| Check if a specific animation group has completed.

Returns `Nothing` if there are no animations for the group.

-}
isComplete : AnimGroupName -> AnimState -> Maybe Bool
isComplete =
    InternalSub.isComplete


{-| Get the current progress of an animation group as a value from 0.0 to 1.0.

Returns `Nothing` if there are no animations for the group.

    Sub.getProgress "myAnimation" model.animState
    -- Just 0.5 (halfway through)

-}
getProgress : AnimGroupName -> AnimState -> Maybe Float
getProgress =
    InternalSub.getProgress


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getBackgroundColorStart : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorStart elementId animState =
    InternalSub.getBackgroundColorRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        BackgroundColor.default

                    Just startColor ->
                        startColor
            )


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorEnd : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorEnd elementId animState =
    InternalSub.getBackgroundColorRange elementId animState
        |> Maybe.map .end


{-| Get the current background color of an element based on its animation state.

Returns `Nothing` if the element has no background color animation.

Returns the start color if the animation has not started yet.

Returns the current interpolated color if the animation is running.

Returns the end color if the animation has completed.

-}
getBackgroundColorCurrent : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorCurrent elementId animState =
    InternalSub.getBackgroundColor elementId animState


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getOpacityStart : AnimGroupName -> AnimState -> Maybe Float
getOpacityStart elementId animState =
    InternalSub.getOpacityRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        1.0

                    Just startOpacity ->
                        Opacity.toFloat startOpacity
            )


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd elementId animState =
    InternalSub.getOpacityRange elementId animState
        |> Maybe.map (.end >> Opacity.toFloat)


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the current interpolated opacity if the animation is running.

Returns the end opacity if the animation has completed.

-}
getOpacityCurrent : AnimGroupName -> AnimState -> Maybe Float
getOpacityCurrent elementId animState =
    InternalSub.getOpacity elementId animState
        |> Maybe.map Opacity.toFloat


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just {x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getTranslateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart elementId animState =
    InternalSub.getTranslateRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 0, y = 0, z = 0 }

                    Just startPos ->
                        Translate.toRecord startPos
            )


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd elementId animState =
    InternalSub.getTranslateRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Translate.toRecord


{-| Get the current translate of an element based on its animation state.

Returns `Nothing` if the element has no translate animation.

Returns the start translate if the animation has not started yet.

Returns the current interpolated translate if the animation is running.

Returns the end translate if the animation has completed.

-}
getTranslateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent elementId animState =
    InternalSub.getTranslate elementId animState
        |> Maybe.map Translate.toRecord


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getRotateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart elementId animState =
    InternalSub.getRotateRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 0, y = 0, z = 0 }

                    Just startRotate ->
                        Rotate.toRecord startRotate
            )


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd elementId animState =
    InternalSub.getRotateRange elementId animState
        |> Maybe.map (.end >> Rotate.toRecord)


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the current interpolated rotation if the animation is running.

Returns the end rotation if the animation has completed.

-}
getRotateCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent elementId animState =
    InternalSub.getRotate elementId animState
        |> Maybe.map Rotate.toRecord


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getScaleStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart elementId animState =
    InternalSub.getScaleRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 1, y = 1, z = 1 }

                    Just startScale ->
                        Scale.toRecord startScale
            )


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd elementId animState =
    InternalSub.getScaleRange elementId animState
        |> Maybe.map (.end >> Scale.toRecord)


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the current interpolated scale if the animation is running.

Returns the end scale if the animation has completed.

-}
getScaleCurrent : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent elementId animState =
    InternalSub.getScale elementId animState
        |> Maybe.map Scale.toRecord


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSizeStart : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart elementId animState =
    InternalSub.getSizeRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { width = 0, height = 0 }

                    Just startSize ->
                        Size.toRecord startSize
            )


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd elementId animState =
    InternalSub.getSizeRange elementId animState
        |> Maybe.map (.end >> Size.toRecord)


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the current interpolated size if the animation is running.

Returns the end size if the animation has completed.

-}
getSizeCurrent : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeCurrent elementId animState =
    InternalSub.getSize elementId animState
        |> Maybe.map Size.toRecord


{-| Apply the animation attributes to your element.

    div
        (Sub.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes =
    InternalSub.htmlAttributes



-- ANIMATION CONTROL


{-| Stop a running animation by instantly jumping to its end state.

    Sub.stop "animGroup" model.animState

-}
stop : AnimGroupName -> AnimState -> AnimState
stop elementId animState =
    InternalSub.stop elementId animState


{-| Reset an animation by instantly jumping back to its start state.

    Sub.reset "animGroup" model.animState

-}
reset : AnimGroupName -> AnimState -> AnimState
reset elementId animState =
    InternalSub.reset elementId animState


{-| Restart an animation from the beginning.

    Sub.restart "animGroup" model.animState

-}
restart : AnimGroupName -> AnimState -> AnimState
restart elementId animState =
    InternalSub.restart elementId animState


{-| Pause a running animation.

    Sub.pause "animGroup" model.animState

-}
pause : AnimGroupName -> AnimState -> AnimState
pause elementId animState =
    InternalSub.pause elementId animState


{-| Resume a paused animation.

    Sub.resume "animGroup" model.animState

-}
resume : AnimGroupName -> AnimState -> AnimState
resume elementId animState =
    InternalSub.resume elementId animState
