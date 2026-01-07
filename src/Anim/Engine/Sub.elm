module Anim.Engine.Sub exposing
    ( AnimState, init, AnimBuilder, builder
    , animate
    , AnimationMsg, update, subscriptions
    , htmlAttributes
    , perspective
    , perspectiveStyles, perspectiveWith
    , duration, speed
    , easing
    , delay
    , anyRunning, isRunning, allComplete, isComplete
    , getStartBackgroundColor, getEndBackgroundColor, getCurrentBackgroundColor
    , getStartOpacity, getEndOpacity, getCurrentOpacity
    , getStartPosition, getEndPosition, getCurrentPosition
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


# 3D Animations

When using 3D transforms with Position, Rotate, or Scale animations, you need to set a perspective
to give a sense of depth. Without perspective, 3D transformations will have no visual effect, and will appear flat.


## Perspective

@docs perspective


## HTML

@docs perspectiveStyles, perspectiveWith


# Global Settings

These settings will be used for all animations unless overridden on a per-animation basis.


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


## Position

@docs getStartPosition, getEndPosition, getCurrentPosition


## Rotate

@docs getStartRotate, getEndRotate, getCurrentRotate


## Scale

@docs getStartScale, getEndScale, getCurrentScale


## Size

@docs getStartSize, getEndSize, getCurrentSize

-}

import Anim.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.BackgroundColor as BackgroundColor exposing (Color)
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Position as Position
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
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

You can override this global setting for specific properties using property-specific perspective functions.

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
    case Builder.getPerspectiveStylesCache (builder animState) of
        Just cache ->
            case Dict.get containerId cache of
                Just styles ->
                    List.map (\{ attribute, value } -> Html.Attributes.style attribute value) styles

                Nothing ->
                    []

        Nothing ->
            []


{-| Manually generate HTML attributes with a given perspective value.

Think zoom level for 3D transforms!!

    -- Zoom in/out by changing the perspective value

    update msg model =
        case msg of
            ZoomIn ->
                { model | zoomLevel = model.zoomLevel - 100 }

            ZoomOut ->
                { model | zoomLevel = model.zoomLevel + 100 }


    div
        (Sub.perspectiveWith model.zoomLevel)
        [ --- Animated content
        ]

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
                        BackgroundColor.rgba255 255 255 255 0

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


{-| Get the start position of an element being animated.

Returns `Nothing` if the element has no position animation.

Returns `{x = 0, y = 0, z = 0}` if no explicit start value was set, which is the default when no start value is set.

-}
getStartPosition : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getStartPosition elementId animState =
    InternalSub.getPositionRange elementId animState
        |> Maybe.map
            (\{ start } ->
                case start of
                    Nothing ->
                        { x = 0, y = 0, z = 0 }

                    Just startPos ->
                        Position.toRecord startPos
            )


{-| Get the end position of an element being animated.

Returns `Nothing` if the element has no position animation.

-}
getEndPosition : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getEndPosition elementId animState =
    InternalSub.getPositionRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Position.toRecord


{-| Get the current position of an element based on its animation state.

Returns `Nothing` if the element has no position animation.

Returns the start position if the animation has not started yet.

Returns the current interpolated position if the animation is running.

Returns the end position if the animation has completed.

-}
getCurrentPosition : String -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getCurrentPosition elementId animState =
    InternalSub.getPosition elementId animState
        |> Maybe.map Position.toRecord


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `0.0 degrees` if no explicit start value was set, which is the default when no start value is set.

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

Returns `1.0` if no explicit start value was set, which is the default when no start value is set.

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

Returns `{width = 0, height = 0}` if no explicit start value was set, which is the default when no start value is set.

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


### HTML Example

    div
        (CSS.htmlAttributes "my-element" animationState)
        [ text "Animating element" ]


### Elm UI Example

For Elm UI, just wrap each attribute with [htmlAttribute](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/Element#htmlAttribute):

    el
        (List.map htmlAttribute <|
            CSS.htmlAttributes "my-element" animationState
        )
        (text "Animating element")

-}
htmlAttributes : ElementId -> AnimState -> List (Html.Attribute msg)
htmlAttributes =
    InternalSub.htmlAttributes
