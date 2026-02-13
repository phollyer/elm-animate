module Anim.Engine.CSS.Keyframes exposing
    ( AnimState, init
    , attributes
    , styleNode, styleNodeFor, getElementKeyframes
    , AnimEvent(..), handleEvent
    , events
    , onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel
    , AnimBuilder, animate, fireAndForget, TransformOrder(..), animateOrder, fireAndForgetOrder
    , duration, speed
    , easing
    , delay
    , iterations, loopForever
    , stop, reset, restart, pause, resume
    , anyRunning, isRunning, allComplete, isComplete
    , getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor
    , getStartOpacity, getEndOpacity, getCurrentOpacity
    , getStartRotate, getEndRotate, getCurrentRotate
    , getStartScale, getEndScale, getCurrentScale
    , getStartSize, getEndSize, getCurrentSize
    , getStartTranslate, getEndTranslate, getCurrentTranslate
    )

{-| CSS Keyframe Animations engine for complex, multi-step animations.

CSS Keyframe Animations offer more control than transitions, allowing complex
multi-step animations with precise timing control.

**Use CSS Keyframes for:**

  - Complex, multi-step animations
  - Advanced easing curves (bounce, elastic, back)
  - Pause/resume functionality
  - Loop/iteration control
  - Better debugging visibility in DevTools

**Requirements:**

  - Must add a `<style>` node to the DOM with the generated keyframes
  - Use [keyframesStyleNode](#keyframesStyleNode) or [keyframesStyleNodeFor](#keyframesStyleNodeFor)


# State

@docs AnimState, init


# Apply Keyframe Animations

Keyframe animations require both styles on the element AND a `<style>` node in the DOM:

    import Anim.Engine.CSS.Keyframes as Keyframes

    view model =
        div []
            [ Keyframes.styleNode model.animState
            , div
                (Keyframes.attributes "my-element" model.animState)
                [ text "Animating element" ]
            ]

@docs attributes

@docs styleNode, styleNodeFor, getElementKeyframes


# Keyframe Animation Events

CSS keyframe animations trigger events at various stages of their lifecycle.
Use these events to keep your [AnimState](#AnimState) in sync.

@docs AnimEvent, handleEvent

@docs events

For more granular control over which events to handle:

@docs onAnimationStart, onAnimationEnd, onAnimationIteration, onAnimationCancel


# Execute

@docs AnimBuilder, animate, fireAndForget, TransformOrder, animateOrder, fireAndForgetOrder


# Default Settings


## Timing

@docs duration, speed


## Easing

@docs easing

**Note:** Keyframe animations bake easing into the keyframes themselves, enabling
accurate complex curves like bounce and elastic.


## Delay

@docs delay


## Iteration / Looping

Control how many times an animation repeats.

@docs iterations, loopForever


# Animation Control

@docs stop, reset, restart, pause, resume


# Querying Animation State

@docs anyRunning, isRunning, allComplete, isComplete


# Querying Animated Properties

CSS animations do not provide direct access to mid-flight values.
However, this engine tracks start and end values, allowing you to query them.

For accurate mid-flight values, consider [Sub](Anim.Engine.Sub) or [WAAPI](Anim.Engine.WAAPI) engines.


## Background Color

@docs getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor


## Opacity

@docs getStartOpacity, getEndOpacity, getCurrentOpacity


## Rotate

@docs getStartRotate, getEndRotate, getCurrentRotate


## Scale

@docs getStartScale, getEndScale, getCurrentScale


## Size

@docs getStartSize, getEndSize, getCurrentSize


## Translate

@docs getStartTranslate, getEndTranslate, getCurrentTranslate

-}

import Anim.Extra.Color exposing (Color)
import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.CSS as InternalCSS exposing (ElementState(..))
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate as Translate
import Html
import Html.Attributes



-- TYPES


{-| The animation state type used to store animation configurations and keyframes.

Both state-tracked and fire-and-forget animations produce an `AnimState`, but only
state-tracked animations require storing it in your model:

    type alias Model =
        { animState : Keyframes.AnimState }

-}
type alias AnimState =
    InternalCSS.AnimState


{-| Animation builder type for configuring animations.
-}
type alias AnimBuilder =
    InternalCSS.AnimBuilder


{-| Transform property ordering.

The **default** (recommended) transform order is: Translate → Rotate → Scale.

  - Translate sets the base location
  - Rotation happens around that position
  - Scale happens last to avoid affecting rotation radius

-}
type TransformOrder
    = Translate
    | Rotate
    | Scale


{-| CSS keyframe animation lifecycle events.
-}
type AnimEvent
    = Started String
    | Ended String
    | Cancelled String
    | Iteration String



-- INIT


{-| Initialize animation state with optional property initializers.

    -- Empty state
    Keyframes.init []

    -- With initial properties
    Keyframes.init
        [ Translate.initXY "element-id" 100 50
        , Opacity.init "element-id" 0.5
        ]

-}
init : List (AnimBuilder -> AnimBuilder) -> AnimState
init =
    InternalCSS.init



-- EXECUTE


{-| Create a state-tracked animation.

    { model
        | animState =
            Keyframes.animate model.animState <|
                (fadeIn >> slideIn)
    }

-}
animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate =
    InternalCSS.animate


{-| Apply the animation configuration with custom transform ordering.

    -- Custom transform order: Scale → Rotate → Translate
    Keyframes.animateOrder [ Scale, Rotate, Translate ] model.animState <|
        rotateLeft
            >> scaleUp
            >> moveRight

-}
animateOrder : List TransformOrder -> AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animateOrder order =
    let
        mapOrder xform =
            case xform of
                Translate ->
                    InternalCSS.Translate

                Rotate ->
                    InternalCSS.Rotate

                Scale ->
                    InternalCSS.Scale
    in
    InternalCSS.animateWithOrder (List.map mapOrder order)


{-| Create a fire-and-forget animation without state tracking.

    entranceAnimation : Keyframes.AnimState
    entranceAnimation =
        Keyframes.fireAndForget <|
            (fadeIn >> slideIn)

-}
fireAndForget : (AnimBuilder -> AnimBuilder) -> AnimState
fireAndForget =
    animate (init [])


{-| Create a fire-and-forget animation with custom transform ordering.
-}
fireAndForgetOrder : List TransformOrder -> (AnimBuilder -> AnimBuilder) -> AnimState
fireAndForgetOrder order =
    animateOrder order (init [])



-- GLOBAL SETTINGS


{-| Set the global duration in milliseconds.

    model.animState
        |> Keyframes.builder
        |> Keyframes.duration 500
        |> ...

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalCSS.duration


{-| Set the global speed in pixels per second.

    model.animState
        |> Keyframes.builder
        |> Keyframes.speed 100
        |> ...

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalCSS.speed


{-| Set the global easing function.

    model.animState
        |> Keyframes.builder
        |> Keyframes.easing EaseInOutQuad
        |> ...

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalCSS.easing


{-| Set the global delay in milliseconds.

    model.animState
        |> Keyframes.builder
        |> Keyframes.delay 500
        |> ...

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalCSS.delay


{-| Set how many times an animation should repeat.

    Keyframes.animate model.animState <|
        (iterations 3 >> pulse "my-element")

-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    Builder.iterations


{-| Make an animation loop infinitely.

    Keyframes.animate model.animState <|
        (loopForever >> pulse "my-element")

The animation will continue until you call `stop`, `reset`, or remove the element.

-}
loopForever : AnimBuilder -> AnimBuilder
loopForever =
    Builder.loopForever



-- KEYFRAMES STYLES


{-| Get all attributes for keyframe-based animations.

    div
        (Keyframes.attributes "my-element" animState)
        [ text "Animating element" ]

-}
attributes : String -> AnimState -> List (Html.Attribute msg)
attributes =
    InternalCSS.keyframesStyles


{-| Get a `<style>` node containing keyframes for all animated elements.

    view model =
        div []
            [ Keyframes.styleNode animState
            , ...
            ]

If there are no animations, this returns an empty text node.

-}
styleNode : AnimState -> Html.Html msg
styleNode =
    InternalCSS.keyframesStyleNode


{-| Get a `<style>` node containing keyframes for a specific element.

    view model =
        div []
            [ Keyframes.styleNodeFor "my-element" animState
            , ...
            ]

If the element has no animations, this returns an empty text node.

-}
styleNodeFor : String -> AnimState -> Html.Html msg
styleNodeFor =
    InternalCSS.keyframesStyleNodeFor


{-| Get the raw generated CSS keyframes string for advanced use cases.

You probably want [styleNodeFor](#styleNodeFor) instead,
which handles creating the full `<style>` node for you.

-}
getElementKeyframes : String -> AnimState -> Maybe String
getElementKeyframes =
    InternalCSS.getElementKeyframes



-- KEYFRAME ANIMATION EVENTS


{-| The simplest way to receive keyframe animation event messages.

    type Msg
        = KeyframeMsg Keyframes.AnimEvent

    div
        (Keyframes.attributes "my-element" animState
            ++ Keyframes.events "my-element" KeyframeMsg
        )
        [ text "Animating element" ]

-}
events : String -> (AnimEvent -> msg) -> List (Html.Attribute msg)
events elementId toMsg =
    List.map (Html.Attributes.map toMsg) <|
        [ onAnimationStart (Started elementId)
        , onAnimationEnd (Ended elementId)
        , onAnimationCancel (Cancelled elementId)
        , onAnimationIteration (Iteration elementId)
        ]


{-| Handle CSS keyframe animation lifecycle events.

    update msg model =
        case msg of
            KeyframeMsg event ->
                { model | animState = Keyframes.handleEvent event model.animState }

-}
handleEvent : AnimEvent -> AnimState -> AnimState
handleEvent event animState =
    case event of
        Started elementId ->
            InternalCSS.handleEvent (InternalCSS.AnimationStarted elementId) animState

        Ended elementId ->
            InternalCSS.handleEvent (InternalCSS.AnimationEnded elementId) animState

        Cancelled elementId ->
            InternalCSS.handleEvent (InternalCSS.AnimationCancelled elementId) animState

        Iteration elementId ->
            InternalCSS.handleEvent (InternalCSS.AnimationIteration elementId) animState


{-| Event handler for when a CSS animation starts.
-}
onAnimationStart : msg -> Html.Attribute msg
onAnimationStart =
    InternalCSS.onAnimationStart


{-| Event handler for when a CSS animation ends.
-}
onAnimationEnd : msg -> Html.Attribute msg
onAnimationEnd =
    InternalCSS.onAnimationEnd


{-| Event handler for when a CSS animation iteration completes.
-}
onAnimationIteration : msg -> Html.Attribute msg
onAnimationIteration =
    InternalCSS.onAnimationIteration


{-| Event handler for when a CSS animation is cancelled.
-}
onAnimationCancel : msg -> Html.Attribute msg
onAnimationCancel =
    InternalCSS.onAnimationCancel



-- ANIMATION CONTROL


{-| Stop a running animation by instantly jumping to its end state.

    Keyframes.stop "my-element" model.animState

-}
stop : String -> AnimState -> AnimState
stop =
    InternalCSS.stopAnimation


{-| Reset an animation by instantly jumping back to its start state.

    Keyframes.reset "my-element" model.animState

-}
reset : String -> AnimState -> AnimState
reset =
    InternalCSS.reset


{-| Restart an animation from the beginning.

    Keyframes.restart "my-element" model.animState

-}
restart : String -> AnimState -> AnimState
restart =
    InternalCSS.restartAnimation


{-| Pause a running animation.

    Keyframes.pause "my-element" model.animState

-}
pause : String -> AnimState -> AnimState
pause =
    InternalCSS.pauseAnimation


{-| Resume a paused animation.

    Keyframes.resume "my-element" model.animState

-}
resume : String -> AnimState -> AnimState
resume =
    InternalCSS.resumeAnimation



-- STATE QUERIES


{-| Check if any animations are currently running.
-}
anyRunning : AnimState -> Bool
anyRunning =
    InternalCSS.anyRunning


{-| Check if a specific element has any animations currently running.
-}
isRunning : String -> AnimState -> Bool
isRunning =
    InternalCSS.isRunning


{-| Check if a specific element's animations have completed.

Returns `Nothing` if there are no animations for the element.

-}
isComplete : String -> AnimState -> Maybe Bool
isComplete =
    InternalCSS.isComplete


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    InternalCSS.allComplete



-- PROPERTY GETTERS (HELPER)


getCurrent : String -> a -> AnimState -> { start : Maybe a, end : a } -> Maybe a
getCurrent elementId default animState range =
    InternalCSS.getState elementId animState
        |> Maybe.map
            (\state ->
                case state of
                    NotStarted ->
                        case range.start of
                            Nothing ->
                                default

                            Just startValue ->
                                startValue

                    Running ->
                        range.end

                    Complete ->
                        range.end
            )



-- TRANSLATE GETTERS


{-| Get the start translate value of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getStartTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartTranslate elementId animState =
    InternalCSS.getTranslateRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 0, y = 0, z = 0 }

                    Just startPos ->
                        Translate.toRecord startPos
            )


{-| Get the end translate value of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getEndTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndTranslate elementId animState =
    InternalCSS.getTranslateRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Translate.toRecord


{-| Get the current translate value based on animation state.

Returns `Nothing` if the element has no translate animation.

-}
getCurrentTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentTranslate elementId animState =
    InternalCSS.getTranslateRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId Translate.default animState)
        |> Maybe.map Translate.toRecord



-- SCALE GETTERS


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getStartScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartScale elementId animState =
    InternalCSS.getScaleRange elementId animState
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
getEndScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndScale elementId animState =
    InternalCSS.getScaleRange elementId animState
        |> Maybe.map (.end >> Scale.toRecord)


{-| Get the current scale based on animation state.

Returns `Nothing` if the element has no scale animation.

-}
getCurrentScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentScale elementId animState =
    InternalCSS.getScaleRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId (Scale.fromUniform 1.0) animState)
        |> Maybe.map Scale.toRecord



-- ROTATE GETTERS


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getStartRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartRotate elementId animState =
    InternalCSS.getRotateRange elementId animState
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
getEndRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndRotate elementId animState =
    InternalCSS.getRotateRange elementId animState
        |> Maybe.map (.end >> Rotate.toRecord)


{-| Get the current rotation based on animation state.

Returns `Nothing` if the element has no rotate animation.

-}
getCurrentRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentRotate elementId animState =
    InternalCSS.getRotateRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId Rotate.default animState)
        |> Maybe.map Rotate.toRecord



-- OPACITY GETTERS


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getStartOpacity : String -> AnimState -> Maybe Float
getStartOpacity elementId animState =
    InternalCSS.getOpacityRange elementId animState
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
getEndOpacity : String -> AnimState -> Maybe Float
getEndOpacity elementId animState =
    InternalCSS.getOpacityRange elementId animState
        |> Maybe.map (.end >> Opacity.toFloat)


{-| Get the current opacity based on animation state.

Returns `Nothing` if the element has no opacity animation.

-}
getCurrentOpacity : String -> AnimState -> Maybe Float
getCurrentOpacity elementId animState =
    InternalCSS.getOpacityRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId Opacity.default animState)
        |> Maybe.map Opacity.toFloat



-- SIZE GETTERS


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getStartSize : String -> AnimState -> Maybe { width : Float, height : Float }
getStartSize elementId animState =
    InternalCSS.getSizeRange elementId animState
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
getEndSize : String -> AnimState -> Maybe { width : Float, height : Float }
getEndSize elementId animState =
    InternalCSS.getSizeRange elementId animState
        |> Maybe.map (.end >> Size.toRecord)


{-| Get the current size based on animation state.

Returns `Nothing` if the element has no size animation.

-}
getCurrentSize : String -> AnimState -> Maybe { width : Float, height : Float }
getCurrentSize elementId animState =
    InternalCSS.getSizeRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId Size.default animState)
        |> Maybe.map Size.toRecord



-- BACKGROUND COLOR GETTERS


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getStartBackgroundColor : String -> AnimState -> Maybe Color
getStartBackgroundColor elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Just startColor ->
                        startColor

                    Nothing ->
                        BackgroundColor.default
            )


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getEndBackgroundColor : String -> AnimState -> Maybe Color
getEndBackgroundColor elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.map .end


{-| Get the current background color based on animation state.

Returns `Nothing` if the element has no background color animation.

-}
getCurrentBackgroundColor : String -> AnimState -> Maybe Color
getCurrentBackgroundColor elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.andThen
            (getCurrent elementId BackgroundColor.default animState)
