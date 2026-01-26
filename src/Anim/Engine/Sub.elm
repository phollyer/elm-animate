module Anim.Engine.Sub exposing
    ( AnimState, init, AnimBuilder, builder
    , animate
    , AnimationMsg, update, subscriptions
    , htmlAttributes
    , stop, reset, restart, pause, resume
    , perspective
    , perspectiveStyles, perspectiveWith
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

{-| Subscription-based animation system with state tracking.

This Engine converts [AnimBuilder](#AnimBuilder) configurations to frame-based animations using
subscriptions for smooth, controlled animations.


# Build

@docs AnimState, init, AnimBuilder, builder


# Execute

@docs animate


# Update

@docs AnimationMsg, update, subscriptions


# View

@docs htmlAttributes


# Animation Control

Control running animations with stop, reset, restart, pause, and resume functionality.

**Subscription Animation Behavior:**

  - **stop**: Instantly jumps to the animation's end state.
  - **reset**: Instantly jumps back to the animation's start state.
  - **restart**: Restarts the animation from the beginning.
  - **pause**: Pauses a specific element's animations by stopping subscription updates for that element.
    Animation state is preserved at current position.
  - **resume**: Resumes a specific element's paused animations by restarting subscription updates for that element.

@docs stop, reset, restart, pause, resume


# 3D Animations

When using 3D transforms with Position, Rotate, or Scale animations, you need to set a perspective
to give a sense of depth. Without perspective, 3D transformations will have no visual effect, and will appear flat.


## Perspective

@docs perspective


## HTML

@docs perspectiveStyles, perspectiveWith


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

Subscription-based animations provide direct mid-flight access to the current values of animated properties through frame-by-frame updates.
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
import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.BackgroundColor as BackgroundColor
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate as Translate
import Anim.Internal.Sub as InternalSub
import Dict
import Html
import Html.Attributes


{-| Animation builder type.

This is used internally to configure animations.

-}
type alias AnimBuilder =
    InternalSub.AnimBuilder



-- ANIMATION STATE


{-| State for managing animations.

This state keeps track of animations and their configurations.

    import Anim.Engine.Sub as Sub

    { model | animations : Sub.AnimState }

-}
type alias AnimState =
    InternalSub.AnimState



-- ANIMATION EXECUTION


{-| The ID of the target element being animated.
-}
type alias ElementId =
    String


{-| Initialize empty animation state.

    import Anim.Engine.Sub as Sub

    { model | animations = Sub.init }

-}
init : AnimState
init =
    InternalSub.init


{-| Turn the [AnimState](#AnimState) into an [AnimBuilder](#AnimBuilder).

Use this to start building new animations.

    newBuilder =
        model.animations
            |> Sub.builder
            |> ... -- Continue building the animation

-}
builder : AnimState -> AnimBuilder
builder =
    InternalSub.builder


{-| Create animations ready to be applied in the view.

    let
        newAnimations =
            model.animations
                |> Sub.builder
                |> .. -- Build your animations here
                |> Sub.animate
    in
    { model | animations = newAnimations }

-}
animate : AnimBuilder -> AnimState
animate =
    InternalSub.animate


{-| Set global duration in milliseconds (overrides any previous speed setting).

    model.animations
        |> Sub.builder
        |> Sub.duration 1000
        |> ... -- Continue building the animation

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalSub.duration


{-| Set global speed in units per second (overrides any previous duration setting).

    model.animations
        |> Sub.builder
        |> Sub.speed 100
        |> ... -- Continue building the animation

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalSub.speed


{-| Set global easing function.

    model.animations
        |> Sub.builder
        |> Sub.easing EaseInOutQuad
        |> ... -- Continue building the animation

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalSub.easing


{-| Set global delay in milliseconds.

    model.animations
        |> Sub.builder
        |> Sub.delay 500
        |> ... -- Continue building the animation

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalSub.delay


{-| Set the global perspective value for 3D transforms.

The perspective value determines the distance between the viewer and the `z = 0` plane.
A smaller value creates a more pronounced 3D effect, while a larger value creates
a more subtle effect.

    model.animations
        |> Sub.builder
        |> Sub.perspective "container-id" 1000
        |> ... -- Continue building the animation

You can override this global setting for specific properties using property-specific `perspective` functions.

-}
perspective : String -> Float -> AnimBuilder -> AnimBuilder
perspective =
    Builder.perspective


{-| Generate HTML attributes for container elements that need perspective.

This function generates the necessary CSS perspective attributes for container elements
that will contain 3D-transformed children. Specify which container you want attributes for.

    -- Set perspective
    model.animations
        |> Sub.builder
        |> Sub.perspective "main-container" 1000
        |> ... -- Continue building the animation

    -- Apply the perspective styles
    div
        (Sub.perspectiveStyles "main-container" animState)
        [ div
            (Sub.htmlAttributes "animated-element" animState)
            [ text "3D animated content" ]
        ]

-}
perspectiveStyles : String -> AnimState -> List (Html.Attribute msg)
perspectiveStyles containerId animState =
    case Dict.get containerId (Builder.getPerspectiveStylesCache (builder animState)) of
        Just value ->
            [ Html.Attributes.style "perspective" (String.fromFloat value ++ "px")
            , Html.Attributes.style "transform-style" "preserve-3d"
            ]

        Nothing ->
            []


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
        (Sub.perspectiveWith model.viewerDistance)
        [ -- Animated content with 3D transforms
        ]

**Elm-side styles take precedence**: When you use this function, the JavaScript will detect
the existing inline style and skip auto-applying perspective, giving you full control.

-}
perspectiveWith : Float -> List (Html.Attribute msg)
perspectiveWith perspectiveValue =
    [ Html.Attributes.style "perspective" (String.fromFloat perspectiveValue ++ "px")
    , Html.Attributes.style "transform-style" "preserve-3d"
    ]



-- UPDATE


{-| Messages for animation updates.

    import Anim.Engine.Sub as Sub

    type Msg
        = SubAnimationMsg Sub.AnimationMsg
        | ...

-}
type alias AnimationMsg =
    InternalSub.AnimationMsg


{-| Update animation state.

    import Anim.Engine.Sub as Sub

    update : Msg -> Model -> Model
    update msg model =
        case msg of
            SubAnimationMsg subMsg ->
                { model | animations = Sub.update msg model.animations }

            ...

-}
update : AnimationMsg -> AnimState -> AnimState
update =
    InternalSub.update



-- SUBSCRIPTIONS


{-| Subscribe to receive animation updates - this is **required**.

Your animations will not run without this subscription.

    import Anim.Engine.Sub as Sub

    type Msg
        = SubAnimationMsg Sub.AnimationMsg
        | ...

    subscriptions : Model -> Sub AnimationMsg
    subscriptions model =
        Sub.subscriptions SubAnimationMsg model.animations

-}
subscriptions : (AnimationMsg -> msg) -> AnimState -> Sub msg
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
getStartBackgroundColor : String -> AnimState -> Maybe Color
getStartBackgroundColor elementId animState =
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
getEndBackgroundColor : String -> AnimState -> Maybe Color
getEndBackgroundColor elementId animState =
    InternalSub.getBackgroundColorRange elementId animState
        |> Maybe.map .end


{-| Get the current background color of an element based on its animation state.

Returns `Nothing` if the element has no background color animation.

Returns the start color if the animation has not started yet.

Returns the current interpolated color if the animation is running.

Returns the end color if the animation has completed.

-}
getCurrentBackgroundColor : String -> AnimState -> Maybe Color
getCurrentBackgroundColor elementId animState =
    InternalSub.getBackgroundColor elementId animState


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getStartOpacity : String -> AnimState -> Maybe Float
getStartOpacity elementId animState =
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
getEndOpacity : String -> AnimState -> Maybe Float
getEndOpacity elementId animState =
    InternalSub.getOpacityRange elementId animState
        |> Maybe.map (.end >> Opacity.toFloat)


{-| Get the current opacity of an element based on its animation state.

Returns `Nothing` if the element has no opacity animation.

Returns the start opacity if the animation has not started yet.

Returns the current interpolated opacity if the animation is running.

Returns the end opacity if the animation has completed.

-}
getCurrentOpacity : String -> AnimState -> Maybe Float
getCurrentOpacity elementId animState =
    InternalSub.getOpacity elementId animState
        |> Maybe.map Opacity.toFloat


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just {x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getStartTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartTranslate elementId animState =
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
getEndTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndTranslate elementId animState =
    InternalSub.getTranslateRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Translate.toRecord


{-| Get the current translate of an element based on its animation state.

Returns `Nothing` if the element has no translate animation.

Returns the start translate if the animation has not started yet.

Returns the current interpolated translate if the animation is running.

Returns the end translate if the animation has completed.

-}
getCurrentTranslate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentTranslate elementId animState =
    InternalSub.getTranslate elementId animState
        |> Maybe.map Translate.toRecord


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartRotate elementId animState =
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
getEndRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndRotate elementId animState =
    InternalSub.getRotateRange elementId animState
        |> Maybe.map (.end >> Rotate.toRecord)


{-| Get the current rotation of an element based on its animation state.

Returns `Nothing` if the element has no rotate animation.

Returns the start rotation if the animation has not started yet.

Returns the current interpolated rotation if the animation is running.

Returns the end rotation if the animation has completed.

-}
getCurrentRotate : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentRotate elementId animState =
    InternalSub.getRotate elementId animState
        |> Maybe.map Rotate.toRecord


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartScale elementId animState =
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
getEndScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndScale elementId animState =
    InternalSub.getScaleRange elementId animState
        |> Maybe.map (.end >> Scale.toRecord)


{-| Get the current scale of an element based on its animation state.

Returns `Nothing` if the element has no scale animation.

Returns the start scale if the animation has not started yet.

Returns the current interpolated scale if the animation is running.

Returns the end scale if the animation has completed.

-}
getCurrentScale : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentScale elementId animState =
    InternalSub.getScale elementId animState
        |> Maybe.map Scale.toRecord


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getStartSize : String -> AnimState -> Maybe { width : Float, height : Float }
getStartSize elementId animState =
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
getEndSize : String -> AnimState -> Maybe { width : Float, height : Float }
getEndSize elementId animState =
    InternalSub.getSizeRange elementId animState
        |> Maybe.map (.end >> Size.toRecord)


{-| Get the current size of an element based on its animation state.

Returns `Nothing` if the element has no size animation.

Returns the start size if the animation has not started yet.

Returns the current interpolated size if the animation is running.

Returns the end size if the animation has completed.

-}
getCurrentSize : String -> AnimState -> Maybe { width : Float, height : Float }
getCurrentSize elementId animState =
    InternalSub.getSize elementId animState
        |> Maybe.map Size.toRecord


{-| Get all the HTML attributes needed for the CSS animations on the target element.

    div
        (CSS.htmlAttributes "my-element" animationState)
        [ text "Animating element" ]

-}
htmlAttributes : ElementId -> AnimState -> List (Html.Attribute msg)
htmlAttributes =
    InternalSub.htmlAttributes



-- ANIMATION CONTROL


{-| Stop an animation by instantly jumping to its end state.

    stoppedAnimations =
        Sub.stop "my-element" model.animations

-}
stop : String -> AnimState -> AnimState
stop elementId animState =
    InternalSub.stopElement elementId animState


{-| Reset an animation by instantly jumping back to its start state.

    resetAnimations =
        Sub.reset "my-element" model.animations

-}
reset : String -> AnimState -> AnimState
reset elementId animState =
    InternalSub.resetElement elementId animState


{-| Restart an animation from the beginning.

    restartedAnimations =
        Sub.restart "my-element" model.animations

-}
restart : String -> AnimState -> AnimState
restart elementId animState =
    InternalSub.restartElement elementId animState


{-| Pause a specific element's running animations.

Animation state is preserved and can be resumed later.

    pausedAnimations =
        Sub.pause "my-element" model.animations

-}
pause : String -> AnimState -> AnimState
pause elementId animState =
    InternalSub.pauseElement elementId animState


{-| Resume a specific element's paused animations.

Animations continue from where they were paused.

    resumedAnimations =
        Sub.resume "my-element" model.animations

-}
resume : String -> AnimState -> AnimState
resume elementId animState =
    InternalSub.resumeElement elementId animState
