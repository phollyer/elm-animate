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
    , ElementId
    , getPosition, getPositionXY, getPositionX, getPositionY
    , getSize, getSizeHW, getSizeH, getSizeW
    , getCurrentStyles
    , isAnimationRunning, getDuration
    )

{-| Subscription-based animation system with state tracking.

This module converts [AnimBuilder](#AnimBuilder) configurations to frame-based animations using
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


# Animation Querying

@docs ElementId


## Position

@docs getPosition, getPositionXY, getPositionX, getPositionY


## Size

@docs getSize, getSizeHW, getSizeH, getSizeW


## Current Styles

@docs getCurrentStyles


## Animation State

@docs isAnimationRunning, getDuration

-}

import Anim.Internal.Builder as Builder
import Anim.Internal.Properties.Position exposing (Position)
import Anim.Internal.Properties.Size exposing (Size)
import Anim.Internal.Sub as InternalSub
import Anim.Timing.Easing as Easing exposing (Easing)
import Dict
import Html
import Html.Attributes


{-| Animation builder type.

This is used internally to configure animations before executing them.

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


{-| Turn the AnimState into an AnimBuilder.

Use this to start new animations based.

    newBuilder =
        model.animations
            |> Sub.builder
            |> Position.for "element"
            |> Position.to { x = 100, y = 200 }
            |> Position.build
            |> Sub.animate

-}
builder : AnimState -> AnimBuilder
builder =
    InternalSub.builder


{-| Create animations ready to be applied in the view.

    let
        newAnimations =
            model.animations
                |> Sub.builder
                |> Position.for "element"
                |> Position.toXY 100 200
                |> Position.duration 1000
                |> Position.build
                |> Sub.animate
    in
    { model | animations = newAnimations }

-}
animate : AnimBuilder -> AnimState
animate =
    InternalSub.animate


{-| Set global duration in milliseconds (overrides any previous speed setting).

    Sub.init
        |> Sub.duration 1000
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Sub.animate

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalSub.duration


{-| Set global speed in units per second (overrides any previous duration setting).

    Sub.init
        |> Sub.speed 100
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Sub.animate

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalSub.speed


{-| Set global easing function.

    Sub.init
        |> Sub.easing EaseInOutQuad
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Sub.animate

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    Easing.mapInternal InternalSub.easing


{-| Set global delay in milliseconds.

    Sub.init
        |> Sub.delay 500
        |> Position.for "element"
        |> Position.toXY 100 200
        |> Position.build
        |> Sub.animate

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalSub.delay


{-| Set the global perspective value for 3D transforms.

The perspective value determines the distance between the viewer and the `z = 0` plane.
A smaller value creates a more pronounced 3D effect, while a larger value creates
a more subtle effect.

    Sub.init
        |> Sub.perspective "container-id" 1000
        |> Position.for "element"
        |> Position.toXYZ 100 200 50
        |> Position.build
        |> Sub.animate

You can override this global setting for specific properties using property-specific perspective functions.

-}
perspective : String -> Float -> AnimBuilder -> AnimBuilder
perspective =
    Builder.perspective


{-| Generate HTML attributes for container elements that need perspective.

This function generates the necessary CSS perspective attributes for container elements
that will contain 3D-transformed children. Specify which container you want attributes for.

    -- Set perspective with a label
    animBuilder
        |> Sub.perspective "main-container" 1000
        |> ...

    -- Apply it using the same label
    div
        (Sub.perspectiveStyles "main-container" animState)
        [ div
            [ id "animated-element" ]  -- Only the animated elements need id
            [ text "3D animated content" ]
        ]

This looks up perspective settings for the specified container from both global settings
and property-level overrides, with property-level taking precedence.

-}
perspectiveStyles : String -> AnimState -> List (Html.Attribute msg)
perspectiveStyles containerId animState =
    let
        processedData =
            Builder.processAnimationData (builder animState)

        -- Check property-level perspectives first
        propertyPerspective =
            processedData.elements
                |> Dict.values
                |> List.concatMap .properties
                |> List.filterMap extractPerspective
                |> List.filter (\p -> p.containerId == containerId)
                |> List.head
                |> Maybe.map .value

        -- Fall back to global perspective
        globalPerspective =
            processedData.globalPerspective
                |> Maybe.andThen
                    (\p ->
                        if p.containerId == containerId then
                            Just p.value

                        else
                            Nothing
                    )

        perspectiveValue =
            case propertyPerspective of
                Just value ->
                    Just value

                Nothing ->
                    globalPerspective
    in
    case perspectiveValue of
        Just value ->
            perspectiveWith value

        Nothing ->
            []


extractPerspective : Builder.ProcessedPropertyConfig -> Maybe { containerId : String, value : Float }
extractPerspective property =
    case property of
        Builder.ProcessedPositionConfig config ->
            config.perspective

        Builder.ProcessedRotateConfig config ->
            config.perspective

        Builder.ProcessedScaleConfig config ->
            config.perspective

        _ ->
            Nothing


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
        [ -- Animated content
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

    subscriptions : Model -> Sub AnimationMsg
    subscriptions model =
        Sub.subscriptions model.animations
            |> Sub.map SubAnimationMsg

-}
subscriptions : AnimState -> Sub AnimationMsg
subscriptions =
    InternalSub.subscriptions



-- POSITION


{-| Get current position of an element being animated.
-}
getPosition : ElementId -> AnimState -> Maybe Position
getPosition =
    InternalSub.getPosition


{-| Get current X and Y position of an element being animated.
-}
getPositionXY : ElementId -> AnimState -> Maybe ( Float, Float )
getPositionXY =
    InternalSub.getPositionXY


{-| Get current X position of an element being animated.
-}
getPositionX : ElementId -> AnimState -> Maybe Float
getPositionX =
    InternalSub.getPositionX


{-| Get current Y position of an element being animated.
-}
getPositionY : ElementId -> AnimState -> Maybe Float
getPositionY =
    InternalSub.getPositionY



-- SIZE


{-| Get current size of an element being animated.
-}
getSize : ElementId -> AnimState -> Maybe Size
getSize =
    InternalSub.getSize


{-| Get current width and height of an element being animated.
-}
getSizeHW : ElementId -> AnimState -> Maybe ( Float, Float )
getSizeHW =
    InternalSub.getSizeHW


{-| Get current height of an element being animated.
-}
getSizeH : ElementId -> AnimState -> Maybe Float
getSizeH =
    InternalSub.getSizeH


{-| Get current width of an element being animated.
-}
getSizeW : ElementId -> AnimState -> Maybe Float
getSizeW =
    InternalSub.getSizeW


{-| Get duration of the first animation found for an element.
Returns Nothing if the element has no animations.
-}
getDuration : ElementId -> AnimState -> Maybe Int
getDuration =
    InternalSub.getDuration


{-| Check if an animation is currently running for the given element.
Returns True if the element has active animations, False otherwise.
-}
isAnimationRunning : ElementId -> AnimState -> Bool
isAnimationRunning =
    InternalSub.isAnimationRunning



-- CURRENT STYLES


{-| Get current animation values as CSS-compatible styles.
-}
getCurrentStyles : ElementId -> AnimState -> List ( String, String )
getCurrentStyles =
    InternalSub.getCurrentStyles


{-| Get all the HTML attributes needed for the CSS animations on the target element.


### HTML Example

    div
        ([ Html.Attributes.id "my-element"
         , ...
         ]
            ++ CSS.htmlAttributes "my-element" animationState
        )
        [ text "Animating element" ]


### Elm UI Example

For Elm UI, just wrap each attribute with [htmlAttribute](https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/Element#htmlAttribute):

    el
        ([ htmlAttribute (Html.Attributes.id "my-element")
         , ...
         ]
            ++ List.map htmlAttribute <|
                CSS.htmlAttributes "my-element" animationState
        )
        (text "Animating element")

-}
htmlAttributes : ElementId -> AnimState -> List (Html.Attribute msg)
htmlAttributes =
    InternalSub.htmlAttributes
