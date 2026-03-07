module Anim.Engine.Sub exposing
    ( AnimState, init
    , AnimBuilder, animate, TransformOrder(..), transformOrder
    , AnimMsg, AnimEvent(..), update, subscriptions
    , attributes
    , stop, reset, restart, pause, resume
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

{-| Subscription-based animation system with state tracking.

This Engine converts [AnimBuilder](#AnimBuilder) configurations to frame-based animations using
subscriptions for smooth, controlled animations.


## Design Decisions

**When to use this Engine:**

The Sub Engine is ideal when you need full programmatic control over your animations in pure Elm.

**Use the Sub Engine for:**

  - Complete Elm-side control without JavaScript
  - Real-time access to animated property values
  - Dynamic animation adjustments based on model state
  - Animations that need to react to external events mid-flight
  - Applications where you want to avoid ports/JS interop

**Consider other engines when:**

  - You want fire-and-forget simplicity → use [CSS Engine](Anim-Engine-CSS)
  - You need maximum performance for complex animations → use [WAAPI Engine](Anim-Engine-WAAPI)
  - You only need scroll animations → use [Scroll Engine](Anim-Engine-Scroll)


# State

@docs AnimState, init


# Execute

@docs AnimBuilder, animate, TransformOrder, transformOrder


# Update

@docs AnimMsg, AnimEvent, update, subscriptions


# View

@docs attributes


# Animation Control

Control running animations with stop, reset, restart, pause, and resume functionality.

**Subscription Animation Behavior:**

  - **stop**: Instantly jumps to the animation's end state.
  - **reset**: Instantly jumps back to the animation's start state.
  - **restart**: Restarts the animation from the beginning.
  - **pause**: Pauses an animation.
  - **resume**: Resumes an animation.

@docs stop, reset, restart, pause, resume


# Default Settings

These settings will be used for all animations unless overridden on a per-property basis.


## Timing

@docs duration, speed


## Easing

@docs easing


## Delay

@docs delay


## Iterations

@docs iterations, loopForever, alternate


# Querying Animation State

@docs anyRunning, isRunning, allComplete, isComplete


# Querying Animated Properties

Subscription-based animations provide direct mid-flight access to the current values of animated properties through frame-by-frame updates.
This engine tracks the start, end, and current values of all animated properties, allowing you to query them in real-time
during animation playback.


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
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate as Translate
import Anim.Internal.Sub as InternalSub
import Html


{-| Animation builder type.

This is used internally to configure animations.

-}
type alias AnimBuilder =
    InternalSub.AnimBuilder



-- ANIMATION STATE


{-| State for managing animations.

This state keeps track of animations and their configurations.

    import Anim.Engine.Sub as Sub

    { model | animState : Sub.AnimState }

-}
type alias AnimState =
    InternalSub.AnimState



-- ANIMATION EXECUTION


{-| The ID of the target element being animated.
-}
type alias ElementId =
    String


{-| Initialize animation state with optional property initializers.

Pass an empty list for empty state, or property initializers to set initial values:

    -- Empty state
    Sub.init []

    -- With initial properties
    Sub.init
        [ Translate.initXY "animGroupName" 100 50
        , Opacity.init "animGroupName" 0.5
        ]

Initial values are applied in the view via `htmlAttributes`.
No animations will run until `animate` is called.

-}
init : List (AnimBuilder -> AnimBuilder) -> AnimState
init =
    InternalSub.init


{-| Create animations ready to be applied in the view.

    { model | animState = Sub.animate model.animState Controls.animate }

-}
animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate animState transform =
    InternalSub.animate animState transform


{-| Transform order for custom transform ordering.

The default order is: Translate → Rotate → Scale.

-}
type TransformOrder
    = Translate
    | Rotate
    | Scale


{-| Set the transform order for all future animations.

The transform order specifies how translate, rotate, and scale transforms
are combined. Start the list with the transform to apply first.

Any missing transforms are automatically appended in the default order
(Translate → Rotate → Scale).

    model.animState
        |> Sub.transformOrder [ Scale, Rotate, Translate ]
        |> Sub.animate
            (scaleUp >> rotateLeft >> moveRight)

Transform order affects how combined transforms render. For example, rotating then
translating moves along the rotated axis, while translating then rotating moves
along the original axis.

-}
transformOrder : List TransformOrder -> AnimBuilder -> AnimBuilder
transformOrder order =
    Builder.transformOrder (List.map toInternalOrder order)


toInternalOrder : TransformOrder -> Builder.TransformOrder
toInternalOrder order =
    case order of
        Translate ->
            Builder.Translate

        Rotate ->
            Builder.Rotate

        Scale ->
            Builder.Scale


{-| Set global duration in milliseconds (overrides any previous speed setting).

    Sub.animate model.animState <|
        (Sub.duration 1000
            >> ... -- Continue building the animation
        )

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalSub.duration


{-| Set global speed in units per second (overrides any previous duration setting).

    Sub.animate model.animState <|
        (Sub.speed 100
            >> ... -- Continue building the animation
        )

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalSub.speed


{-| Set global easing function.

    Sub.animate model.animState <|
        (Sub.easing EaseInOutQuad
            >> ... -- Continue building the animation
        )

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalSub.easing


{-| Set global delay in milliseconds.

    Sub.animate model.animState <|
        (Sub.delay 500
            >> ... -- Continue building the animation
        )

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalSub.delay


{-| Set the animation to repeat a specific number of times.

    Sub.animate model.animState <|
        (Sub.iterations 3
            >> ... -- Animation will play 3 times
        )

The `Iteration` event is emitted after each iteration completes (except the final one).

-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    Builder.iterations


{-| Set the animation to loop forever.

    Sub.animate model.animState <|
        (Sub.loopForever
            >> ... -- Animation will loop continuously
        )

The `Iteration` event is emitted after each iteration completes.

-}
loopForever : AnimBuilder -> AnimBuilder
loopForever =
    Builder.loopForever


{-| Make an animation alternate direction on each iteration (ping-pong effect).

    Sub.animate model.animState <|
        (Sub.loopForever >> Sub.alternate
            >> ... -- Animation will ping-pong continuously
        )

This creates a smooth ping-pong animation without needing reverse keyframes.
The animation plays forward, then backward, then forward, etc.

-}
alternate : AnimBuilder -> AnimBuilder
alternate =
    Builder.alternate



-- UPDATE


{-| Messages for animation updates.

    import Anim.Engine.Sub as Sub

    type Msg
        = GotSubAnimMsg Sub.AnimMsg
        | ...

-}
type alias AnimMsg =
    InternalSub.AnimMsg


{-| Animation events.

Emitted by `update` when animation state changes:

  - **Started**: Animation started for an element
  - **Ended**: Animation reached its end naturally
  - **Cancelled**: Animation was stopped or reset
  - **Paused**: Animation was paused
  - **Resumed**: Animation was resumed
  - **Restarted**: Animation was restarted
  - **Iteration**: Animation completed an iteration (includes iteration number)

The `String` is the element ID affected.

-}
type AnimEvent
    = Started String
    | Ended String
    | Cancelled String
    | Paused String
    | Resumed String
    | Restarted String
    | Iteration String Int


{-| Update animation state and check for animation events.

Returns the updated state and a list of events that occurred.
Events include animation starts, completions, pauses, resumes, etc.

    import Anim.Engine.Sub as Sub

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotSubAnimMsg subMsg ->
                let
                    ( newAnimState, events ) =
                        Sub.update subMsg model.animState
                in
                handleAnimationEvents events { model | animState = newAnimState }

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
        InternalSub.Started elementId ->
            Just (Started elementId)

        InternalSub.Ended elementId ->
            Just (Ended elementId)

        InternalSub.Cancelled elementId ->
            Just (Cancelled elementId)

        InternalSub.Paused elementId ->
            Just (Paused elementId)

        InternalSub.Resumed elementId ->
            Just (Resumed elementId)

        InternalSub.Restarted elementId ->
            Just (Restarted elementId)

        InternalSub.Iteration elementId iterationNumber ->
            Just (Iteration elementId iterationNumber)



-- SUBSCRIPTIONS


{-| Subscribe to receive animation updates.

Your animations will not run without this subscription.

    import Anim.Engine.Sub as Sub

    type Msg
        = SubAnimMsg Sub.AnimMsg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.subscriptions SubAnimMsg model.animState

-}
subscriptions : (AnimMsg -> msg) -> AnimState -> Sub msg
subscriptions =
    InternalSub.subscriptions


{-| Check if any animations are currently running.
-}
anyRunning : AnimState -> Bool
anyRunning =
    InternalSub.anyRunning


{-| Check if a specific element has any animations currently running.
-}
isRunning : ElementId -> AnimState -> Bool
isRunning =
    InternalSub.isAnimationRunning


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    InternalSub.allComplete


{-| Check if a specific element's animations have completed.

Returns `Nothing` if there are no animations for the element.

-}
isComplete : String -> AnimState -> Maybe Bool
isComplete =
    InternalSub.isComplete


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getBackgroundColorStart : String -> AnimState -> Maybe Color
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
getBackgroundColorEnd : String -> AnimState -> Maybe Color
getBackgroundColorEnd elementId animState =
    InternalSub.getBackgroundColorRange elementId animState
        |> Maybe.map .end


{-| Get the current background color of an element based on its animation state.

Returns `Nothing` if the element has no background color animation.

Returns the start color if the animation has not started yet.

Returns the current interpolated color if the animation is running.

Returns the end color if the animation has completed.

-}
getBackgroundColorCurrent : String -> AnimState -> Maybe Color
getBackgroundColorCurrent elementId animState =
    InternalSub.getBackgroundColor elementId animState


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getOpacityStart : String -> AnimState -> Maybe Float
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
getOpacityEnd : String -> AnimState -> Maybe Float
getOpacityEnd elementId animState =
    InternalSub.getOpacityRange elementId animState
        |> Maybe.map (.end >> Opacity.toFloat)


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the current interpolated opacity if the animation is running.

Returns the end opacity if the animation has completed.

-}
getOpacityCurrent : String -> AnimState -> Maybe Float
getOpacityCurrent elementId animState =
    InternalSub.getOpacity elementId animState
        |> Maybe.map Opacity.toFloat


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just {x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getTranslateStart : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
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
getTranslateEnd : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
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
getTranslateCurrent : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateCurrent elementId animState =
    InternalSub.getTranslate elementId animState
        |> Maybe.map Translate.toRecord


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getRotateStart : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
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
getRotateEnd : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd elementId animState =
    InternalSub.getRotateRange elementId animState
        |> Maybe.map (.end >> Rotate.toRecord)


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the current interpolated rotation if the animation is running.

Returns the end rotation if the animation has completed.

-}
getRotateCurrent : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateCurrent elementId animState =
    InternalSub.getRotate elementId animState
        |> Maybe.map Rotate.toRecord


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getScaleStart : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
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
getScaleEnd : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd elementId animState =
    InternalSub.getScaleRange elementId animState
        |> Maybe.map (.end >> Scale.toRecord)


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the current interpolated scale if the animation is running.

Returns the end scale if the animation has completed.

-}
getScaleCurrent : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleCurrent elementId animState =
    InternalSub.getScale elementId animState
        |> Maybe.map Scale.toRecord


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSizeStart : String -> AnimState -> Maybe { width : Float, height : Float }
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
getSizeEnd : String -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd elementId animState =
    InternalSub.getSizeRange elementId animState
        |> Maybe.map (.end >> Size.toRecord)


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the current interpolated size if the animation is running.

Returns the end size if the animation has completed.

-}
getSizeCurrent : String -> AnimState -> Maybe { width : Float, height : Float }
getSizeCurrent elementId animState =
    InternalSub.getSize elementId animState
        |> Maybe.map Size.toRecord


{-| Get all the HTML attributes needed for the CSS animations on the target element.

    div
        (Sub.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : ElementId -> AnimState -> List (Html.Attribute msg)
attributes =
    InternalSub.htmlAttributes



-- ANIMATION CONTROL


{-| Stop an animation by instantly jumping to its end state.

    { model | animState = Sub.stop "elementId" model.animState }

-}
stop : String -> AnimState -> AnimState
stop elementId animState =
    InternalSub.stopElement elementId animState


{-| Reset an animation by instantly jumping back to its start state.

    { model | animState = Sub.reset "elementId" model.animState }

-}
reset : String -> AnimState -> AnimState
reset elementId animState =
    InternalSub.resetElement elementId animState


{-| Restart an animation from the beginning.

    { model | animState = Sub.restart "elementId" model.animState }

-}
restart : String -> AnimState -> AnimState
restart elementId animState =
    InternalSub.restartElement elementId animState


{-| Pause a specific element's running animations.

Animation state is preserved and can be resumed later.

    { model | animState = Sub.pause "elementId" model.animState }

-}
pause : String -> AnimState -> AnimState
pause elementId animState =
    InternalSub.pauseElement elementId animState


{-| Resume a specific element's paused animations.

Animations continue from where they were paused.

    { model | animState = Sub.resume "elementId" model.animState }

-}
resume : String -> AnimState -> AnimState
resume elementId animState =
    InternalSub.resumeElement elementId animState
