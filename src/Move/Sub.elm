module Move.Sub exposing
    ( Model
    , init
    , step
    , subscriptions
    , Position
    , TargetId
    , getPosition
    , getAllPositions
    , setPosition
    , animateTo
    , animateToX
    , animateToY
    , animateToWithConfig
    , animateToXWithConfig
    , animateToYWithConfig
    , stopAnimation
    , isAnimating
    , transform
    , transformElement
    )

{-| This module provides smooth animations using [Browser.Events.onAnimationFrameDelta](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Events#onAnimationFrameDelta)
subscriptions.


## Key Features:

  - Frame-rate independent timing using [onAnimationFrameDelta](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Events#onAnimationFrameDelta)
  - Automatic position preservation when animations stop
  - O(1) element lookup using Dict-based state management
  - Smooth transition interruption (start new animation mid-flight)
  - Support for X-only, Y-only, or both-axis animations


### Perfect for:

  - Drag-and-drop interfaces with smooth snapping
  - Interactive tutorials with guided element movement
  - Real-time collaboration tools (cursor tracking, live editing)
  - Custom animation curves that need frame-by-frame control
  - Synchronized animations of multiple related elements
  - Applications needing precise animation state management


# State Management

@docs Model
@docs init
@docs step
@docs subscriptions


# Position Management

@docs Position
@docs TargetId
@docs getPosition
@docs getAllPositions
@docs setPosition


# Animation Control

@docs animateTo
@docs animateToX
@docs animateToY
@docs animateToWithConfig
@docs animateToXWithConfig
@docs animateToYWithConfig
@docs stopAnimation
@docs isAnimating


# CSS Generation

@docs transform
@docs transformElement

-}

import Browser.Events
import Dict exposing (Dict)
import Move exposing (Config, EasePreset(..), Easing(..), Timing(..))
import Move.Internal exposing (calculateDistance, easingToEaseFunction, timingToPixelsPerSecond)



-- CORE TYPES


{-| Type alias for target element IDs that we want to animate.
-}
type alias TargetId =
    String


{-| Position type for X and Y coordinates in pixels.
-}
type alias Position =
    { x : Float
    , y : Float
    }


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
        Move.Sub.init

-}
init : Model
init =
    Model Dict.empty


{-| Default configuration for animations

    defaultConfig =
        { timing = Speed 400.0
        , easing = EasePreset EaseOutQuart
        }

-}
defaultConfig : Config
defaultConfig =
    { timing = Speed 400.0
    , easing = EasePreset EaseOut
    }


{-| Start animating an element to a target position using default config

If the element is already animating, it will smoothly transition to the new target.
If the element has no current position, it starts from (0, 0).

    import Move.Sub

    newModel =
        Move.Sub.animateTo "my-element" { x = 200, y = 300 } model.moveSubModel

-}
animateTo : TargetId -> Position -> Model -> Model
animateTo elementId position model =
    animateToWithConfig defaultConfig elementId position model


{-| Start animating an element horizontally to a target X position

Only the X coordinate will change - Y position remains at current value.

    newModel =
        Move.Sub.animateToX "my-element" 200 model.moveSubModel

-}
animateToX : TargetId -> Float -> Model -> Model
animateToX elementId targetX model =
    animateToXWithConfig defaultConfig elementId targetX model


{-| Start animating an element vertically to a target Y position

Only the Y coordinate will change - X position remains at current value.

    newModel =
        Move.Sub.animateToY "my-element" 300 model.moveSubModel

-}
animateToY : TargetId -> Float -> Model -> Model
animateToY elementId targetY model =
    animateToYWithConfig defaultConfig elementId targetY model


{-| Start animating an element to a target position with custom configuration

    config =
        { defaultConfig | timing = Speed 600.0, easing = EasePreset EaseOutQuint }

    newModel =
        Move.Sub.animateToWithConfig config "my-element" { x = 100, y = 150 } model.moveSubModel

-}
animateToWithConfig : Config -> TargetId -> Position -> Model -> Model
animateToWithConfig config elementId position (Model elementsDict) =
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
            calculateDistance currentPos position

        -- Duration based on distance and speed (speed = pixels per second)
        duration =
            max 100 (distance * 1000 / timingToPixelsPerSecond config.timing distance)

        animationState =
            { startX = startX
            , startY = startY
            , targetX = position.x
            , targetY = position.y
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
        { defaultConfig | timing = Speed 600.0, easing = EasePreset EaseOutQuint }

    newModel =
        Move.Sub.animateToXWithConfig config "my-element" 200 model.moveSubModel

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
        { defaultConfig | timing = Speed 600.0, easing = EasePreset EaseOutQuint }

    newModel =
        Move.Sub.animateToYWithConfig config "my-element" 300 model.moveSubModel

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


{-| Manually set an element's position without animation

Useful for:

  - Initial positioning

  - Teleporting elements

  - Resetting positions

  - Synchronizing with external events

-}
setPosition : TargetId -> Position -> Model -> Model
setPosition elementId position (Model elementsDict) =
    let
        elementData =
            { lastX = position.x
            , lastY = position.y
            , animation = Nothing
            }

        updatedDict =
            Dict.insert elementId elementData elementsDict
    in
    Model updatedDict


{-| Stop any ongoing animation for an element

The element will remain at its current animated position.

    newModel =
        Move.Sub.stopAnimation "my-element" model.moveSubModel

-}
stopAnimation : TargetId -> Model -> Model
stopAnimation elementId (Model elementsDict) =
    let
        updatedDict =
            Dict.update elementId
                (Maybe.map
                    (\elementData ->
                        case elementData.animation of
                            Just animState ->
                                { elementData
                                    | lastX = animState.currentX
                                    , lastY = animState.currentY
                                    , animation = Nothing
                                }

                            Nothing ->
                                elementData
                    )
                )
                elementsDict
    in
    Model updatedDict


{-| Check if an element is currently animating

    if Move.Sub.isAnimating "my-element" model.moveSubModel then
        -- Element is moving
    else
        -- Element is stationary

-}
isAnimating : TargetId -> Model -> Bool
isAnimating elementId (Model elementsDict) =
    case Dict.get elementId elementsDict of
        Just elementData ->
            case elementData.animation of
                Just _ ->
                    True

                Nothing ->
                    False

        Nothing ->
            False


{-| Get current position of an element

Returns Nothing if element has never been positioned or animated.

    case Move.Sub.getPosition "my-element" model.moveSubModel of
        Just position ->
            -- Use position.x and position.y

        Nothing ->
            -- Element has no position yet

-}
getPosition : TargetId -> Model -> Maybe Position
getPosition elementId (Model elementsDict) =
    Dict.get elementId elementsDict
        |> Maybe.map
            (\elementData ->
                case elementData.animation of
                    Just animState ->
                        { x = animState.currentX, y = animState.currentY }

                    Nothing ->
                        { x = elementData.lastX, y = elementData.lastY }
            )


{-| Get all element positions as a Dict

Useful for debugging or bulk operations.


    allPositions =
        Move.Sub.getAllPositions model.moveSubModel

    -- Dict.fromList [("element-1", {x = 100, y = 200}), ...]

-}
getAllPositions : Model -> Dict TargetId Position
getAllPositions (Model elementsDict) =
    Dict.map
        (\_ elementData ->
            case elementData.animation of
                Just animState ->
                    { x = animState.currentX, y = animState.currentY }

                Nothing ->
                    { x = elementData.lastX, y = elementData.lastY }
        )
        elementsDict


{-| Update animation state based on animation frame delta

Call this from your update function with Tick messages:

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            Tick delta ->
                ( { model | moveSubModel = Move.Sub.step delta model.moveSubModel }, Cmd.none )

-}
step : Float -> Model -> Model
step delta (Model elementsDict) =
    let
        updateElement elementData =
            case elementData.animation of
                Nothing ->
                    elementData

                Just animState ->
                    let
                        newStartedAt =
                            if animState.startedAt == 0 then
                                delta

                            else
                                animState.startedAt

                        elapsed =
                            if animState.startedAt == 0 then
                                0

                            else
                                delta - newStartedAt

                        progress =
                            if animState.duration <= 0 then
                                1.0

                            else
                                min 1.0 (elapsed / animState.duration)

                        easedProgress =
                            easingToEaseFunction animState.config.easing progress

                        newX =
                            animState.startX + (animState.targetX - animState.startX) * easedProgress

                        newY =
                            animState.startY + (animState.targetY - animState.startY) * easedProgress

                        updatedAnimState =
                            { animState
                                | currentX = newX
                                , currentY = newY
                                , startedAt = newStartedAt
                            }
                    in
                    if progress >= 1.0 then
                        -- Animation complete
                        { elementData
                            | lastX = animState.targetX
                            , lastY = animState.targetY
                            , animation = Nothing
                        }

                    else
                        -- Animation continues
                        { elementData | animation = Just updatedAnimState }

        updatedDict =
            Dict.map (\_ elementData -> updateElement elementData) elementsDict
    in
    Model updatedDict


{-| Subscribe to animation frame updates

Add this to your subscriptions function:

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.batch
            [ Move.Sub.subscriptions Tick model.moveSubModel
            , -- your other subscriptions
            ]

-}
subscriptions : (Float -> msg) -> Model -> Sub msg
subscriptions toMsg (Model elementsDict) =
    let
        hasActiveAnimations =
            Dict.values elementsDict
                |> List.any
                    (\elementData ->
                        case elementData.animation of
                            Just _ ->
                                True

                            Nothing ->
                                False
                    )
    in
    if hasActiveAnimations then
        Browser.Events.onAnimationFrameDelta toMsg

    else
        Sub.none


{-| Generate CSS transform string for an element

Apply this to your element's style attribute:

    div
        [ style "transform" (transform "my-element" model.moveSubModel) ]
        [ text "Animated element" ]

-}
transform : TargetId -> Model -> String
transform elementId model =
    case getPosition elementId model of
        Just position ->
            "translate(" ++ String.fromFloat position.x ++ "px, " ++ String.fromFloat position.y ++ "px)"

        Nothing ->
            "translate(0px, 0px)"


{-| Generate CSS transform for a specific element position

Useful when you want to transform based on a known position rather than looking up by ID:

    div
        [ style "transform" (transformElement { x = 100, y = 200 }) ]
        [ text "Animated element" ]

-}
transformElement : Position -> String
transformElement position =
    "translate(" ++ String.fromFloat position.x ++ "px, " ++ String.fromFloat position.y ++ "px)"
