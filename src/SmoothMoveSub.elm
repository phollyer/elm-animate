module SmoothMoveSub exposing
    ( Config
    , defaultConfig
    , Axis(..)
    , Model
    , init
    , step
    , subscriptions
    , animateTo
    , animateToWithConfig
    , setInitialPosition
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
@docs Axis


# State Management

@docs Model
@docs init
@docs step
@docs subscriptions


# Animation Control

@docs animateTo
@docs animateToWithConfig
@docs setInitialPosition
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


{-| Configuration options for subscription-based animations

  - speed: Animation speed in pixels per second (higher = faster movement)
  - easing: Easing function from elm-community/easing-functions
  - axis: Movement axis (X, Y, or Both)

-}
type alias Config =
    { speed : Float
    , easing : Ease.Easing
    , axis : Axis
    }


{-| Axis configuration for movement direction
-}
type Axis
    = X
    | Y
    | Both


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
animateTo : String -> Float -> Float -> Model -> Model
animateTo elementId targetX targetY model =
    animateToWithConfig defaultConfig elementId targetX targetY model


{-| Start animating an element to a target position with custom configuration

    config =
        { defaultConfig | speed = 600.0, easing = Ease.outQuint }

    newModel =
        SmoothMoveSub.animateToWithConfig config "my-element" 100 150 model.smoothMove

-}
animateToWithConfig : Config -> String -> Float -> Float -> Model -> Model
animateToWithConfig config elementId targetX targetY (Model elementsDict) =
    let
        currentPos =
            getPosition elementId (Model elementsDict)
                |> Maybe.withDefault { x = 0, y = 0 }

        startX =
            currentPos.x

        startY =
            currentPos.y

        distance =
            case config.axis of
                X ->
                    abs (targetX - startX)

                Y ->
                    abs (targetY - startY)

                Both ->
                    sqrt ((targetX - startX) ^ 2 + (targetY - startY) ^ 2)

        -- Duration based on distance and speed (speed = pixels per second)
        duration =
            max 100 (distance * 1000 / config.speed)

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
            |> SmoothMoveSub.setInitialPosition "element-a" 100 150
            |> SmoothMoveSub.setInitialPosition "element-b" 200 250

-}
setInitialPosition : String -> Float -> Float -> Model -> Model
setInitialPosition elementId x y (Model elementsDict) =
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
getPosition : String -> Model -> Maybe { x : Float, y : Float }
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
stopAnimation : String -> Model -> Model
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
    { speed = 400.0
    , easing = Ease.outCubic
    , axis = Both
    }


{-| Check if animation is complete by comparing current position to target position
-}
isAnimationComplete : AnimationState -> Bool
isAnimationComplete state =
    let
        xComplete =
            case state.config.axis of
                Y ->
                    True

                -- X axis not animated, so always complete
                _ ->
                    abs (state.currentX - state.targetX) < 0.1

        yComplete =
            case state.config.axis of
                X ->
                    True

                -- Y axis not animated, so always complete
                _ ->
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
            case state.config.axis of
                Y ->
                    state.startX

                _ ->
                    state.startX + (state.targetX - state.startX) * easedProgress

        currentY =
            case state.config.axis of
                X ->
                    state.startY

                _ ->
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
transformElement : String -> Model -> String
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
        SmoothMoveSub.subscriptions model.smoothMove AnimationFrame

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
subscriptions : Model -> (Float -> msg) -> Sub msg
subscriptions (Model modelData) toMsg =
    if not (Dict.values modelData |> List.any (\elementData -> elementData.animation /= Nothing)) then
        Sub.none

    else
        Browser.Events.onAnimationFrameDelta toMsg
