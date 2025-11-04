module SmoothMoveSub exposing
    ( Config
    , defaultConfig
    , Timing(..)
    , Model
    , init
    , step
    , subscriptions
    , animateTo
    , animateToX
    , animateToY
    , animateToWithConfig
    , animateToXWithConfig
    , animateToYWithConfig
    , setPosition
    , stopAnimation
    , isAnimating
    , getPosition
    , getAllPositions
    , transform
    , transformElement
    )

{-| A subscription-based animation library for smooth element movement.

This module provides a subscription-based approach where animations are managed
automatically through subscriptions to animation frames.


# Configuration

@docs Config
@docs defaultConfig
@docs Timing


# State Management

@docs Model
@docs init
@docs step
@docs subscriptions


# Animation Control

@docs animateTo
@docs animateToX
@docs animateToY
@docs animateToWithConfig
@docs animateToXWithConfig
@docs animateToYWithConfig
@docs setPosition
@docs stopAnimation


# State Queries

@docs isAnimating
@docs getPosition
@docs getAllPositions


# Styling Helper

@docs transform
@docs transformElement

-}

import Browser.Events
import Dict exposing (Dict)
import Ease


{-| Type alias for target element IDs that we want to scroll to.
-}
type alias TargetId =
    String


{-| Animation timing configuration

Choose between speed-based or duration-based timing:

  - Speed: Animation speed in pixels per second (higher = faster)
  - Duration: Animation duration in milliseconds (higher = slower)

-}
type Timing
    = Speed Float
    | Duration Int


{-| Configuration options for subscription-based animations

  - timing: Animation timing (Speed in pixels per second or Duration in milliseconds)
  - easing: Easing function from elm-community/easing-functions

-}
type alias Config =
    { timing : Timing
    , easing : Ease.Easing
    }


{-| Convert timing configuration to pixels per second for internal calculations
-}
timingToPixelsPerSecond : Timing -> Float -> Float
timingToPixelsPerSecond timing distance =
    case timing of
        Speed pixelsPerSecond ->
            pixelsPerSecond

        Duration milliseconds ->
            -- Convert duration to pixels per second: distance / (duration in seconds)
            distance / (toFloat milliseconds / 1000)


type alias AnimationState =
    { startX : Float
    , startY : Float
    , targetX : Float
    , targetY : Float
    , currentX : Float
    , currentY : Float
    , config : Config
    , startedAt : Float
    , duration : Float
    }


{-| Internal model that manages animation state and element positions automatically

This model handles all animation state AND element positions internally, so developers
don't need to track AnimationState, completion logic, or current positions manually.

Uses a Dict for O(1) lookups and better performance with many elements.

-}
type Model
    = Model (Dict String ElementData)


type alias ElementData =
    { lastX : Float
    , lastY : Float
    , animation : Maybe AnimationState
    }


{-| Initialize the model with no active animations

    init =
        SmoothMoveSub.init

-}
init : Model
init =
    Model Dict.empty


{-| Start animating an element to a target position using default config

If the element is already animating, it will smoothly transition to the new target.
If the element has no current position, it starts from (0, 0).

    import SmoothMoveSub

    newModel =
        SmoothMoveSub.animateTo "my-element" 200 300 model.smoothMove

-}
animateTo : TargetId -> Float -> Float -> Model -> Model
animateTo elementId targetX targetY model =
    animateToWithConfig defaultConfig elementId targetX targetY model


{-| Start animating an element horizontally to a target X position

Only the X coordinate will change - Y position remains at current value.

    newModel =
        SmoothMoveSub.animateToX "my-element" 200 model.smoothMove

-}
animateToX : TargetId -> Float -> Model -> Model
animateToX elementId targetX model =
    animateToXWithConfig defaultConfig elementId targetX model


{-| Start animating an element vertically to a target Y position

Only the Y coordinate will change - X position remains at current value.

    newModel =
        SmoothMoveSub.animateToY "my-element" 300 model.smoothMove

-}
animateToY : TargetId -> Float -> Model -> Model
animateToY elementId targetY model =
    animateToYWithConfig defaultConfig elementId targetY model


{-| Start animating an element to a target position with custom configuration

    config =
        { defaultConfig | speed = 600.0, easing = Ease.outQuint }

    newModel =
        SmoothMoveSub.animateToWithConfig config "my-element" 100 150 model.smoothMove

-}
animateToWithConfig : Config -> TargetId -> Float -> Float -> Model -> Model
animateToWithConfig config elementId targetX targetY (Model elementsDict) =
    let
        currentPos =
            getPosition elementId (Model elementsDict)
                |> Maybe.withDefault { x = 0, y = 0 }

        startX =
            currentPos.x

        startY =
            currentPos.y

        -- For animateTo (both axes), calculate Euclidean distance
        distance =
            sqrt ((targetX - startX) ^ 2 + (targetY - startY) ^ 2)

        -- Duration based on distance and speed (speed = pixels per second)
        duration =
            max 100 (distance * 1000 / timingToPixelsPerSecond config.timing distance)

        animationState =
            { startX = startX
            , startY = startY
            , targetX = targetX
            , targetY = targetY
            , currentX = startX
            , currentY = startY
            , config = config
            , startedAt = 0
            , duration = duration
            }

        elementData =
            { lastX = startX
            , lastY = startY
            , animation = Just animationState
            }

        updatedDict =
            Dict.insert elementId elementData elementsDict
    in
    Model updatedDict


{-| Start animating an element horizontally to a target X position with custom configuration

Only the X coordinate will change - Y position remains at current value.

    config =
        { defaultConfig | timing = Speed 600.0, easing = Ease.outQuint }

    newModel =
        SmoothMoveSub.animateToXWithConfig config "my-element" 200 model.smoothMove

-}
animateToXWithConfig : Config -> TargetId -> Float -> Model -> Model
animateToXWithConfig config elementId targetX (Model elementsDict) =
    let
        currentPos =
            getPosition elementId (Model elementsDict)
                |> Maybe.withDefault { x = 0, y = 0 }

        startX =
            currentPos.x

        startY =
            currentPos.y

        -- For X-only animation, Y target equals current Y
        targetY =
            startY

        distance =
            abs (targetX - startX)

        -- Duration based on distance and speed (speed = pixels per second)
        duration =
            max 100 (distance * 1000 / timingToPixelsPerSecond config.timing distance)

        animationState =
            { startX = startX
            , startY = startY
            , targetX = targetX
            , targetY = targetY
            , currentX = startX
            , currentY = startY
            , config = config
            , startedAt = 0
            , duration = duration
            }

        elementData =
            { lastX = startX
            , lastY = startY
            , animation = Just animationState
            }

        updatedDict =
            Dict.insert elementId elementData elementsDict
    in
    Model updatedDict


{-| Start animating an element vertically to a target Y position with custom configuration

Only the Y coordinate will change - X position remains at current value.

    config =
        { defaultConfig | timing = Speed 600.0, easing = Ease.outQuint }

    newModel =
        SmoothMoveSub.animateToYWithConfig config "my-element" 300 model.smoothMove

-}
animateToYWithConfig : Config -> TargetId -> Float -> Model -> Model
animateToYWithConfig config elementId targetY (Model elementsDict) =
    let
        currentPos =
            getPosition elementId (Model elementsDict)
                |> Maybe.withDefault { x = 0, y = 0 }

        startX =
            currentPos.x

        startY =
            currentPos.y

        -- For Y-only animation, X target equals current X
        targetX =
            startX

        distance =
            abs (targetY - startY)

        -- Duration based on distance and speed (speed = pixels per second)
        duration =
            max 100 (distance * 1000 / timingToPixelsPerSecond config.timing distance)

        animationState =
            { startX = startX
            , startY = startY
            , targetX = targetX
            , targetY = targetY
            , currentX = startX
            , currentY = startY
            , config = config
            , startedAt = 0
            , duration = duration
            }

        elementData =
            { lastX = startX
            , lastY = startY
            , animation = Just animationState
            }

        updatedDict =
            Dict.insert elementId elementData elementsDict
    in
    Model updatedDict


{-| Set the initial position of an element without animation

This is useful for preventing the "jump to (0,0)" behavior on first animation.
Call this during initialization to establish element positions.

    initialModel =
        SmoothMoveSub.init
            |> SmoothMoveSub.setPosition "element-a" 100 150
            |> SmoothMoveSub.setPosition "element-b" 200 250

-}
setPosition : TargetId -> Float -> Float -> Model -> Model
setPosition elementId x y (Model elementsDict) =
    let
        elementData =
            { lastX = x
            , lastY = y
            , animation = Nothing
            }

        updatedDict =
            Dict.insert elementId elementData elementsDict
    in
    Model updatedDict


{-| Step animations forward by the given time delta (in milliseconds)

Call this function on each animation frame with the time delta.
This function handles all active animations simultaneously and updates element positions.

    import SmoothMoveSub

    type Msg
        = AnimationFrame Float
        | StartMove Float Float

    update msg model =
        case msg of
            AnimationFrame deltaMs ->
                let
                    newSmoothMove =
                        SmoothMoveSub.step deltaMs model.smoothMove
                in
                ( { model | smoothMove = newSmoothMove }
                , Cmd.none
                )

-}
step : Float -> Model -> Model
step deltaMs (Model elementsDict) =
    let
        updateElementData _ elementData =
            case elementData.animation of
                -- No animation, keep current state
                Nothing ->
                    elementData

                Just animationState ->
                    let
                        updatedState =
                            updateAnimation deltaMs animationState
                    in
                    if isAnimationComplete updatedState then
                        -- Animation complete, save final position
                        { elementData
                            | animation = Nothing
                            , lastX = updatedState.targetX
                            , lastY = updatedState.targetY
                        }

                    else
                        { elementData | animation = Just updatedState }

        updatedDict =
            Dict.map updateElementData elementsDict
    in
    Model updatedDict


{-| Check if the model is animating

    if SmoothMoveSub.isAnimating model.smoothMove then
        text "Animation running"

    else
        text "No animation"

-}
isAnimating : Model -> Bool
isAnimating (Model elementsDict) =
    Dict.values elementsDict |> List.any (\elementData -> elementData.animation /= Nothing)


{-| Get the current position of a specific element

Returns Nothing if the element has never been animated.

    case SmoothMoveSub.getPosition "my-element" model.smoothMove of
        Just { x, y } ->
            div [ style "transform" (SmoothMoveSub.transform x y) ] [ text "Element" ]

        Nothing ->
            text "Element not found"

-}
getPosition : TargetId -> Model -> Maybe { x : Float, y : Float }
getPosition elementId (Model elementsDict) =
    Dict.get elementId elementsDict
        |> Maybe.map
            (\elementData ->
                case elementData.animation of
                    Just animationState ->
                        { x = animationState.currentX, y = animationState.currentY }

                    Nothing ->
                        { x = elementData.lastX, y = elementData.lastY }
            )


{-| Stop animation for a specific element

The element will remain at its current position.

    newModel =
        SmoothMoveSub.stopAnimation "my-element" currentModel.smoothMove

-}
stopAnimation : TargetId -> Model -> Model
stopAnimation elementId (Model elementsDict) =
    case Dict.get elementId elementsDict of
        Just elementData ->
            let
                currentPos =
                    case elementData.animation of
                        Just animState ->
                            { x = animState.currentX, y = animState.currentY }

                        Nothing ->
                            { x = elementData.lastX, y = elementData.lastY }

                updatedElementData =
                    { elementData
                        | lastX = currentPos.x
                        , lastY = currentPos.y
                        , animation = Nothing
                    }
            in
            Model (Dict.insert elementId updatedElementData elementsDict)

        Nothing ->
            Model elementsDict


{-| Get all current element positions

Returns a dictionary mapping element IDs to their current positions.

    positions =
        SmoothMoveSub.getAllPositions model.smoothMove

-}
getAllPositions : Model -> Dict String { x : Float, y : Float }
getAllPositions (Model elementsDict) =
    Dict.map
        (\_ elementData ->
            case elementData.animation of
                Just animationState ->
                    { x = animationState.currentX, y = animationState.currentY }

                Nothing ->
                    { x = elementData.lastX, y = elementData.lastY }
        )
        elementsDict


{-| The default configuration which can be modified import Ease
import SmoothMoveSub exposing (defaultConfig)

    defaultConfig : Config
    defaultConfig =
        { speed = 200
        , easing = Ease.outQuint
        , axis = Both
        }

-}
defaultConfig : Config
defaultConfig =
    { timing = Duration 400
    , easing = Ease.outCubic
    }


{-| Check if animation is complete by comparing current position to target position
-}
isAnimationComplete : AnimationState -> Bool
isAnimationComplete state =
    let
        xComplete =
            abs (state.currentX - state.targetX) < 0.1

        yComplete =
            abs (state.currentY - state.targetY) < 0.1
    in
    xComplete && yComplete


{-| Update animation state with elapsed time and current position
-}
updateAnimation : Float -> AnimationState -> AnimationState
updateAnimation deltaMs state =
    let
        newElapsedTime =
            if state.startedAt == 0 then
                deltaMs

            else
                state.startedAt + deltaMs

        progress =
            min 1.0 (newElapsedTime / state.duration)

        easedProgress =
            state.config.easing progress

        currentX =
            state.startX + (state.targetX - state.startX) * easedProgress

        currentY =
            state.startY + (state.targetY - state.startY) * easedProgress
    in
    { state
        | startedAt = newElapsedTime
        , currentX = currentX
        , currentY = currentY
    }


{-| Create a CSS transform string for positioning

    div [ style "transform" (SmoothMoveSub.transform 100 200) ] [ text "Moving element" ]

-}
transform : Float -> Float -> String
transform x y =
    "translate(" ++ String.fromFloat x ++ "px, " ++ String.fromFloat y ++ "px)"


{-| Create a CSS transform string by looking up the element's current position

This convenience function eliminates the need to manually call getPosition and handle Maybe values.
If the element is not found, it defaults to (0, 0).

    div [ style "transform" (SmoothMoveSub.transformElement "my-element" model) ] [ text "Moving element" ]

-}
transformElement : TargetId -> Model -> String
transformElement elementId model =
    case getPosition elementId model of
        Just position ->
            transform position.x position.y

        Nothing ->
            transform 0 0


{-| Simplified subscription function that handles animation logic internally

This function takes care of all the animation frame updates and state management.
You just need to handle the Position updates in your model. The library will
automatically stop sending updates when the animation is complete.

    import SmoothMoveSub exposing (subscriptions)

    type Msg
        = StartMove Float Float
        | AnimationFrame Float
        | NoOp

    subscriptions : Model -> Sub Msg
    subscriptions model =
        SmoothMoveSub.subscriptions AnimationFrame model.smoothMove

    update msg model =
        case msg of
            StartMove targetX targetY ->
                let
                    newSmoothMove =
                        startAnimationTo "element-id" targetX targetY model.smoothMove
                in
                ( { model | smoothMove = newSmoothMove }, Cmd.none )

            AnimationFrame deltaMs ->
                let
                    newSmoothMove =
                        SmoothMoveSub.update deltaMs model.smoothMove
                in
                ( { model | smoothMove = newSmoothMove }
                , Cmd.none
                )

-}
subscriptions : (Float -> msg) -> Model -> Sub msg
subscriptions toMsg (Model modelData) =
    if not (Dict.values modelData |> List.any (\elementData -> elementData.animation /= Nothing)) then
        Sub.none

    else
        Browser.Events.onAnimationFrameDelta toMsg
