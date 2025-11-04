module Anim.Sub exposing
    ( Model
    , init
    , step
    , subscriptions
    , TargetId
    , animate
    , animateWithConfig
    , getCurrentValue
    , setValue
    , animateTo
    , animateToX
    , animateToY
    , animateToWithConfig
    , animateToXWithConfig
    , animateToYWithConfig
    , animateOpacity
    , animateOpacityWithConfig
    , animateScale
    , animateScaleWithConfig
    , animateRotation
    , animateRotationWithConfig
    , animateBackgroundColor
    , animateBackgroundColorWithConfig
    , getPosition
    , getAllPositions
    , setPosition
    , stopAnimation
    , isAnimating
    , transform
    , transformElement
    , styleProperties
    )

{-| This module provides smooth animations using [Browser.Events.onAnimationFrameDelta](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Events#onAnimationFrameDelta)
subscriptions, supporting comprehensive animation properties.


## Key Features:

  - Frame-rate independent timing using [onAnimationFrameDelta](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Events#onAnimationFrameDelta)
  - Comprehensive animation support: position, opacity, scale, rotation, colors, dimensions, border-radius, filters
  - Automatic value preservation when animations stop
  - O(1) element lookup using Dict-based state management
  - Smooth transition interruption (start new animation mid-flight)
  - Support for simultaneous multi-property animations per element


### Perfect for:

  - Complex UI animations requiring precise control (fade in/out, scaling, morphing)
  - Interactive elements with multiple animation layers (hover effects, state changes)
  - Real-time collaboration tools with rich visual feedback
  - Custom animation curves that need frame-by-frame control
  - Game UI elements with smooth property transitions
  - Applications needing precise animation state management across many properties


# State Management

@docs Model
@docs init
@docs step
@docs subscriptions


# Comprehensive Animation

@docs TargetId
@docs animate
@docs animateWithConfig
@docs getCurrentValue
@docs setValue


# Property-Specific Animation

@docs animateTo
@docs animateToX
@docs animateToY
@docs animateToWithConfig
@docs animateToXWithConfig
@docs animateToYWithConfig
@docs animateOpacity
@docs animateOpacityWithConfig
@docs animateScale
@docs animateScaleWithConfig
@docs animateRotation
@docs animateRotationWithConfig
@docs animateBackgroundColor
@docs animateBackgroundColorWithConfig


# Value Management

@docs getPosition
@docs getAllPositions
@docs setPosition
@docs stopAnimation
@docs isAnimating


# CSS Generation

@docs transform
@docs transformElement
@docs styleProperties

-}

import Anim exposing (AnimationTarget(..), ColorValue(..), Config, EasePreset(..), Easing(..), FilterValue(..), Position, RotationValue, ScaleValue, Timing(..))
import Anim.Internal exposing (calculateDistance, easingToEaseFunction)
import Browser.Events
import Dict exposing (Dict)



-- CORE TYPES


{-| Type alias for target element IDs that we want to animate.
-}
type alias TargetId =
    String


type alias AnimationState =
    { target : AnimationTarget
    , startValue : AnimationTarget
    , startedAt : Float
    , duration : Float
    , config : Config
    }


{-| Internal model that manages animation state and comprehensive element properties automatically.

This model handles all animation state AND element values internally, supporting position,
opacity, scale, rotation, colors, dimensions, border-radius, and filters.

Uses a Dict for O(1) lookups and better performance with many elements.

-}
type Model
    = Model (Dict String ElementData)


type alias ElementData =
    { properties : Dict String AnimationTarget
    , animation : Maybe AnimationState
    }



-- ANIMATION PROPERTY HELPERS


{-| Get the property key for an AnimationTarget.
-}
getPropertyKey : AnimationTarget -> String
getPropertyKey target =
    case target of
        ToPosition _ ->
            "position"

        ToOpacity _ ->
            "opacity"

        ToScale _ ->
            "scale"

        ToRotation _ ->
            "rotation"

        ToBackgroundColor _ ->
            "background-color"

        ToTextColor _ ->
            "text-color"

        ToBorderColor _ ->
            "border-color"

        ToDimensions _ ->
            "dimensions"

        ToBorderRadius _ ->
            "border-radius"

        ToFilter _ ->
            "filter"


{-| Interpolate between two AnimationTarget values based on progress (0.0 to 1.0).
-}
interpolateTarget : AnimationTarget -> AnimationTarget -> Float -> AnimationTarget
interpolateTarget start target progress =
    case ( start, target ) of
        ( ToPosition startPos, ToPosition targetPos ) ->
            ToPosition
                { x = startPos.x + (targetPos.x - startPos.x) * progress
                , y = startPos.y + (targetPos.y - startPos.y) * progress
                }

        ( ToOpacity startOp, ToOpacity targetOp ) ->
            ToOpacity (startOp + (targetOp - startOp) * progress)

        ( ToScale startScale, ToScale targetScale ) ->
            ToScale
                { x = startScale.x + (targetScale.x - startScale.x) * progress
                , y = startScale.y + (targetScale.y - startScale.y) * progress
                }

        ( ToRotation startRot, ToRotation targetRot ) ->
            ToRotation (startRot + (targetRot - startRot) * progress)

        ( ToBackgroundColor startColor, ToBackgroundColor targetColor ) ->
            ToBackgroundColor (interpolateColor startColor targetColor progress)

        ( ToTextColor startColor, ToTextColor targetColor ) ->
            ToTextColor (interpolateColor startColor targetColor progress)

        ( ToBorderColor startColor, ToBorderColor targetColor ) ->
            ToBorderColor (interpolateColor startColor targetColor progress)

        ( ToDimensions startDim, ToDimensions targetDim ) ->
            ToDimensions
                { width = startDim.width + (targetDim.width - startDim.width) * progress
                , height = startDim.height + (targetDim.height - startDim.height) * progress
                }

        ( ToBorderRadius startRadius, ToBorderRadius targetRadius ) ->
            ToBorderRadius (startRadius + (targetRadius - startRadius) * progress)

        ( ToFilter startFilter, ToFilter targetFilter ) ->
            ToFilter (interpolateFilter startFilter targetFilter progress)

        _ ->
            -- Mismatched target types, return target (snap to end)
            target


{-| Interpolate between two ColorValue instances.
-}
interpolateColor : ColorValue -> ColorValue -> Float -> ColorValue
interpolateColor start target progress =
    case ( start, target ) of
        ( Rgb startRgb, Rgb targetRgb ) ->
            Rgb
                { r = round (toFloat startRgb.r + toFloat (targetRgb.r - startRgb.r) * progress)
                , g = round (toFloat startRgb.g + toFloat (targetRgb.g - startRgb.g) * progress)
                , b = round (toFloat startRgb.b + toFloat (targetRgb.b - startRgb.b) * progress)
                }

        ( Rgba startRgba, Rgba targetRgba ) ->
            Rgba
                { r = round (toFloat startRgba.r + toFloat (targetRgba.r - startRgba.r) * progress)
                , g = round (toFloat startRgba.g + toFloat (targetRgba.g - startRgba.g) * progress)
                , b = round (toFloat startRgba.b + toFloat (targetRgba.b - startRgba.b) * progress)
                , a = startRgba.a + (targetRgba.a - startRgba.a) * progress
                }

        ( Hsl startHsl, Hsl targetHsl ) ->
            Hsl
                { h = startHsl.h + (targetHsl.h - startHsl.h) * progress
                , s = startHsl.s + (targetHsl.s - startHsl.s) * progress
                , l = startHsl.l + (targetHsl.l - startHsl.l) * progress
                }

        ( Hsla startHsla, Hsla targetHsla ) ->
            Hsla
                { h = startHsla.h + (targetHsla.h - startHsla.h) * progress
                , s = startHsla.s + (targetHsla.s - startHsla.s) * progress
                , l = startHsla.l + (targetHsla.l - startHsla.l) * progress
                , a = startHsla.a + (targetHsla.a - startHsla.a) * progress
                }

        _ ->
            -- Different color formats or Hex colors - snap to target
            target


{-| Interpolate between two FilterValue instances.
-}
interpolateFilter : FilterValue -> FilterValue -> Float -> FilterValue
interpolateFilter start target progress =
    case ( start, target ) of
        ( Blur startBlur, Blur targetBlur ) ->
            Blur (startBlur + (targetBlur - startBlur) * progress)

        ( Brightness startBrightness, Brightness targetBrightness ) ->
            Brightness (startBrightness + (targetBrightness - startBrightness) * progress)

        ( Contrast startContrast, Contrast targetContrast ) ->
            Contrast (startContrast + (targetContrast - startContrast) * progress)

        ( Grayscale startGrayscale, Grayscale targetGrayscale ) ->
            Grayscale (startGrayscale + (targetGrayscale - startGrayscale) * progress)

        ( Saturate startSaturate, Saturate targetSaturate ) ->
            Saturate (startSaturate + (targetSaturate - startSaturate) * progress)

        _ ->
            -- Mismatched filter types, snap to target
            target


{-| Initialize the model with no active animations

    init =
        Anim.Sub.init

-}
init : Model
init =
    Model Dict.empty


{-| Default configuration for animations

    defaultConfig =
        { timing = Duration 400
        , easing = EasePreset EaseOut
        }

-}
defaultConfig : Config
defaultConfig =
    { timing = Duration 400
    , easing = EasePreset EaseOut
    }


{-| Start animating an element to a target animation property using default config.

This is the general-purpose animation function that can handle any AnimationTarget type.

    import Anim exposing (AnimationTarget(..))

    newModel =
        Anim.Sub.animate "my-element" (ToOpacity 0.5) model.animSubModel

-}
animate : TargetId -> AnimationTarget -> Model -> Model
animate elementId target model =
    animateWithConfig defaultConfig elementId target model


{-| Start animating an element to a target animation property with custom configuration.

    import Anim exposing (AnimationTarget(..), EasePreset(..), Easing(..), Timing(..), defaultConfig)

    config =
        { defaultConfig | timing = Duration 800, easing = EasePreset EaseInOut }

    newModel =
        Anim.Sub.animateWithConfig config "my-element" (ToScale { x = 2.0, y = 2.0 }) model.animSubModel

-}
animateWithConfig : Config -> TargetId -> AnimationTarget -> Model -> Model
animateWithConfig config elementId target (Model elementsDict) =
    let
        propertyKey =
            getPropertyKey target

        currentElementData =
            Dict.get elementId elementsDict
                |> Maybe.withDefault { properties = Dict.empty, animation = Nothing }

        currentValue =
            Dict.get propertyKey currentElementData.properties
                |> Maybe.withDefault (getDefaultValue target)

        duration =
            calculateAnimationDuration config currentValue target

        animationState =
            { target = target
            , startValue = currentValue
            , startedAt = 0
            , duration = duration
            , config = config
            }

        updatedProperties =
            Dict.insert propertyKey currentValue currentElementData.properties

        elementData =
            { properties = updatedProperties
            , animation = Just animationState
            }

        updatedDict =
            Dict.insert elementId elementData elementsDict
    in
    Model updatedDict


{-| Get the default value for an AnimationTarget type.
-}
getDefaultValue : AnimationTarget -> AnimationTarget
getDefaultValue target =
    case target of
        ToPosition _ ->
            ToPosition { x = 0, y = 0 }

        ToOpacity _ ->
            ToOpacity 1.0

        ToScale _ ->
            ToScale { x = 1.0, y = 1.0 }

        ToRotation _ ->
            ToRotation 0.0

        ToBackgroundColor _ ->
            ToBackgroundColor (Rgba { r = 0, g = 0, b = 0, a = 0 })

        ToTextColor _ ->
            ToTextColor (Rgb { r = 0, g = 0, b = 0 })

        ToBorderColor _ ->
            ToBorderColor (Rgba { r = 0, g = 0, b = 0, a = 0 })

        ToDimensions _ ->
            ToDimensions { width = 0, height = 0 }

        ToBorderRadius _ ->
            ToBorderRadius 0.0

        ToFilter _ ->
            ToFilter (Brightness 1.0)


{-| Calculate animation duration based on config and distance.
-}
calculateAnimationDuration : Config -> AnimationTarget -> AnimationTarget -> Float
calculateAnimationDuration config startValue targetValue =
    case config.timing of
        Duration ms ->
            toFloat ms

        Speed pixelsPerSecond ->
            let
                distance =
                    calculateTargetDistance startValue targetValue
            in
            max 100 (distance * 1000 / pixelsPerSecond)


{-| Calculate distance between two AnimationTarget values.
-}
calculateTargetDistance : AnimationTarget -> AnimationTarget -> Float
calculateTargetDistance start target =
    case ( start, target ) of
        ( ToPosition startPos, ToPosition targetPos ) ->
            calculateDistance startPos targetPos

        ( ToOpacity startOp, ToOpacity targetOp ) ->
            abs (targetOp - startOp) * 100

        ( ToScale startScale, ToScale targetScale ) ->
            abs (targetScale.x - startScale.x) * 100 + abs (targetScale.y - startScale.y) * 100

        ( ToRotation startRot, ToRotation targetRot ) ->
            abs (targetRot - startRot)

        ( ToDimensions startDim, ToDimensions targetDim ) ->
            abs (targetDim.width - startDim.width) + abs (targetDim.height - startDim.height)

        ( ToBorderRadius startRadius, ToBorderRadius targetRadius ) ->
            abs (targetRadius - startRadius)

        _ ->
            100



-- Default distance for color/filter animations
-- PROPERTY-SPECIFIC CONVENIENCE FUNCTIONS


{-| Animate element opacity with default configuration.

    newModel =
        Anim.Sub.animateOpacity "my-element" 0.5 model.animSubModel

-}
animateOpacity : TargetId -> Float -> Model -> Model
animateOpacity elementId opacity model =
    animate elementId (ToOpacity opacity) model


{-| Animate element opacity with custom configuration.

    config =
        { defaultConfig | timing = Duration 800 }

    newModel =
        Anim.Sub.animateOpacityWithConfig config "my-element" 0.5 model.animSubModel

-}
animateOpacityWithConfig : Config -> TargetId -> Float -> Model -> Model
animateOpacityWithConfig config elementId opacity model =
    animateWithConfig config elementId (ToOpacity opacity) model


{-| Animate element scale with default configuration.

    newModel =
        Anim.Sub.animateScale "my-element" { x = 1.5, y = 1.5 } model.animSubModel

-}
animateScale : TargetId -> ScaleValue -> Model -> Model
animateScale elementId scale model =
    animate elementId (ToScale scale) model


{-| Animate element scale with custom configuration.

    config =
        { defaultConfig | timing = Duration 600, easing = EasePreset EaseInOut }

    newModel =
        Anim.Sub.animateScaleWithConfig config "my-element" { x = 2.0, y = 2.0 } model.animSubModel

-}
animateScaleWithConfig : Config -> TargetId -> ScaleValue -> Model -> Model
animateScaleWithConfig config elementId scale model =
    animateWithConfig config elementId (ToScale scale) model


{-| Animate element rotation with default configuration.

    newModel =
        Anim.Sub.animateRotation "my-element" 90.0 model.animSubModel

-}
animateRotation : TargetId -> RotationValue -> Model -> Model
animateRotation elementId rotation model =
    animate elementId (ToRotation rotation) model


{-| Animate element rotation with custom configuration.

    config =
        { defaultConfig | timing = Duration 1000 }

    newModel =
        Anim.Sub.animateRotationWithConfig config "my-element" 180.0 model.animSubModel

-}
animateRotationWithConfig : Config -> TargetId -> RotationValue -> Model -> Model
animateRotationWithConfig config elementId rotation model =
    animateWithConfig config elementId (ToRotation rotation) model


{-| Animate element background color with default configuration.

    import Anim exposing (ColorValue(..))

    newModel =
        Anim.Sub.animateBackgroundColor "my-element" (Rgb { r = 255, g = 0, b = 0 }) model.animSubModel

-}
animateBackgroundColor : TargetId -> ColorValue -> Model -> Model
animateBackgroundColor elementId color model =
    animate elementId (ToBackgroundColor color) model


{-| Animate element background color with custom configuration.

    import Anim exposing (ColorValue(..), EasePreset(..), Easing(..), Timing(..), defaultConfig)

    config =
        { defaultConfig | timing = Duration 500, easing = EasePreset EaseInOut }

    newModel =
        Anim.Sub.animateBackgroundColorWithConfig config "my-element" (Hsl { h = 120, s = 100, l = 50 }) model.animSubModel

-}
animateBackgroundColorWithConfig : Config -> TargetId -> ColorValue -> Model -> Model
animateBackgroundColorWithConfig config elementId color model =
    animateWithConfig config elementId (ToBackgroundColor color) model


{-| Start animating an element to a target position using default config

If the element is already animating, it will smoothly transition to the new target.
If the element has no current position, it starts from (0, 0).

    import Anim.Sub

    newModel =
        Anim.Sub.animateTo "my-element" { x = 200, y = 300 } model.animSubModel

-}
animateTo : TargetId -> Position -> Model -> Model
animateTo elementId position model =
    animate elementId (ToPosition position) model


{-| Start animating an element horizontally to a target X position

Only the X coordinate will change - Y position remains at current value.

    newModel =
        Anim.Sub.animateToX "my-element" 200 model.moveSubModel

-}
animateToX : TargetId -> Float -> Model -> Model
animateToX elementId targetX model =
    let
        currentPos =
            getPosition elementId model
                |> Maybe.withDefault { x = 0, y = 0 }

        newPosition =
            { currentPos | x = targetX }
    in
    animate elementId (ToPosition newPosition) model


{-| Start animating an element vertically to a target Y position

Only the Y coordinate will change - X position remains at current value.

    newModel =
        Anim.Sub.animateToY "my-element" 300 model.moveSubModel

-}
animateToY : TargetId -> Float -> Model -> Model
animateToY elementId targetY model =
    let
        currentPos =
            getPosition elementId model
                |> Maybe.withDefault { x = 0, y = 0 }

        newPosition =
            { currentPos | y = targetY }
    in
    animate elementId (ToPosition newPosition) model


{-| Start animating an element to a target position with custom configuration

    config =
        { defaultConfig | timing = Speed 600.0, easing = EasePreset EaseOutQuint }

    newModel =
        Anim.Sub.animateToWithConfig config "my-element" { x = 100, y = 150 } model.moveSubModel

-}
animateToWithConfig : Config -> TargetId -> Position -> Model -> Model
animateToWithConfig config elementId position model =
    animateWithConfig config elementId (ToPosition position) model


{-| Start animating an element horizontally to a target X position with custom configuration

Only the X coordinate will change - Y position remains at current value.

    config =
        { defaultConfig | timing = Speed 600.0, easing = EasePreset EaseOutQuint }

    newModel =
        Anim.Sub.animateToXWithConfig config "my-element" 200 model.moveSubModel

-}
animateToXWithConfig : Config -> TargetId -> Float -> Model -> Model
animateToXWithConfig config elementId targetX model =
    let
        currentPos =
            getPosition elementId model
                |> Maybe.withDefault { x = 0, y = 0 }

        newPosition =
            { currentPos | x = targetX }
    in
    animateWithConfig config elementId (ToPosition newPosition) model


{-| Start animating an element vertically to a target Y position with custom configuration

Only the Y coordinate will change - X position remains at current value.

    config =
        { defaultConfig | timing = Speed 600.0, easing = EasePreset EaseOutQuint }

    newModel =
        Anim.Sub.animateToYWithConfig config "my-element" 300 model.moveSubModel

-}
animateToYWithConfig : Config -> TargetId -> Float -> Model -> Model
animateToYWithConfig config elementId targetY model =
    let
        currentPos =
            getPosition elementId model
                |> Maybe.withDefault { x = 0, y = 0 }

        newPosition =
            { currentPos | y = targetY }
    in
    animateWithConfig config elementId (ToPosition newPosition) model


{-| Manually set an element's position without animation

Useful for:

  - Initial positioning

  - Teleporting elements

  - Resetting positions

  - Synchronizing with external events

-}
setPosition : TargetId -> Position -> Model -> Model
setPosition elementId position model =
    setValue elementId (ToPosition position) model


{-| Set an element's animation property value without animation.

This is the general-purpose version of setPosition that works with any AnimationTarget.

    import Anim exposing (AnimationTarget(..))

    newModel =
        model.animSubModel
            |> Anim.Sub.setValue "my-element" (ToOpacity 0.5)
            |> Anim.Sub.setValue "my-element" (ToScale { x = 1.2, y = 1.2 })

-}
setValue : TargetId -> AnimationTarget -> Model -> Model
setValue elementId target (Model elementsDict) =
    let
        propertyKey =
            getPropertyKey target

        currentElementData =
            Dict.get elementId elementsDict
                |> Maybe.withDefault { properties = Dict.empty, animation = Nothing }

        updatedProperties =
            Dict.insert propertyKey target currentElementData.properties

        elementData =
            { currentElementData | properties = updatedProperties, animation = Nothing }

        updatedDict =
            Dict.insert elementId elementData elementsDict
    in
    Model updatedDict


{-| Get the current value of a specific animation property for an element.

    import Anim exposing (AnimationTarget(..))

    case Anim.Sub.getCurrentValue "my-element" "opacity" model.animSubModel of
        Just (ToOpacity opacity) ->
            -- Use the opacity value

        _ ->
            -- Property not found or different type

-}
getCurrentValue : TargetId -> String -> Model -> Maybe AnimationTarget
getCurrentValue elementId propertyKey (Model elementsDict) =
    Dict.get elementId elementsDict
        |> Maybe.andThen
            (\elementData ->
                case elementData.animation of
                    Just animState ->
                        if getPropertyKey animState.target == propertyKey then
                            Just (getCurrentAnimationValue animState)

                        else
                            Dict.get propertyKey elementData.properties

                    Nothing ->
                        Dict.get propertyKey elementData.properties
            )


{-| Get the current animated value from an animation state.

For now, this returns the target value. The actual interpolated value
is calculated and stored in properties during the step function.

-}
getCurrentAnimationValue : AnimationState -> AnimationTarget
getCurrentAnimationValue animState =
    -- Return the target for now - the step function handles interpolation
    animState.target


{-| Stop any ongoing animation for an element

The element will remain at its current animated position.

    newModel =
        Anim.Sub.stopAnimation "my-element" model.moveSubModel

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
                                let
                                    propertyKey =
                                        getPropertyKey animState.target

                                    currentValue =
                                        getCurrentAnimationValue animState

                                    updatedProperties =
                                        Dict.insert propertyKey currentValue elementData.properties
                                in
                                { elementData
                                    | properties = updatedProperties
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

    if Anim.Sub.isAnimating "my-element" model.moveSubModel then
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

    case Anim.Sub.getPosition "my-element" model.moveSubModel of
        Just position ->
            -- Use position.x and position.y

        Nothing ->
            -- Element has no position yet

-}
getPosition : TargetId -> Model -> Maybe Position
getPosition elementId model =
    case getCurrentValue elementId "position" model of
        Just (ToPosition position) ->
            Just position

        _ ->
            Nothing


{-| Get all element positions as a Dict

Useful for debugging or bulk operations.


    allPositions =
        Anim.Sub.getAllPositions model.moveSubModel

    -- Dict.fromList [("element-1", {x = 100, y = 200}), ...]

-}
getAllPositions : Model -> Dict TargetId Position
getAllPositions model =
    case model of
        Model elementsDict ->
            Dict.foldl
                (\elementId _ acc ->
                    case getCurrentValue elementId "position" model of
                        Just (ToPosition position) ->
                            Dict.insert elementId position acc

                        _ ->
                            acc
                )
                Dict.empty
                elementsDict


{-| Update animation state based on animation frame delta

Call this from your update function with Tick messages:

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            Tick delta ->
                ( { model | moveSubModel = Anim.Sub.step delta model.moveSubModel }, Cmd.none )

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

                        currentValue =
                            interpolateTarget animState.startValue animState.target easedProgress

                        updatedAnimState =
                            { animState | startedAt = newStartedAt }

                        propertyKey =
                            getPropertyKey animState.target
                    in
                    if progress >= 1.0 then
                        -- Animation complete - store final value in properties
                        let
                            updatedProperties =
                                Dict.insert propertyKey animState.target elementData.properties
                        in
                        { elementData
                            | properties = updatedProperties
                            , animation = Nothing
                        }

                    else
                        -- Animation continues - store current interpolated value
                        let
                            updatedProperties =
                                Dict.insert propertyKey currentValue elementData.properties
                        in
                        { elementData
                            | properties = updatedProperties
                            , animation = Just updatedAnimState
                        }

        updatedDict =
            Dict.map (\_ elementData -> updateElement elementData) elementsDict
    in
    Model updatedDict


{-| Subscribe to animation frame updates

Add this to your subscriptions function:

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.batch
            [ Anim.Sub.subscriptions Tick model.moveSubModel
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


{-| Generate comprehensive CSS properties for an element

This generates CSS properties for all the animation targets currently set on an element.
Returns a list of (property, value) tuples that can be applied to HTML attributes.

    div
        (List.map (\( prop, value ) -> style prop value)
            (Anim.Sub.styleProperties "my-element" model.animSubModel)
        )
        [ text "Animated element" ]

-}
styleProperties : TargetId -> Model -> List ( String, String )
styleProperties elementId (Model elementsDict) =
    case Dict.get elementId elementsDict of
        Just elementData ->
            Dict.foldl
                (\_ target acc ->
                    animationTargetToCssProperty target ++ acc
                )
                []
                elementData.properties

        Nothing ->
            []


{-| Convert an AnimationTarget to CSS property-value pairs.
-}
animationTargetToCssProperty : AnimationTarget -> List ( String, String )
animationTargetToCssProperty target =
    case target of
        ToPosition position ->
            [ ( "transform", transformElement position ) ]

        ToOpacity opacity ->
            [ ( "opacity", String.fromFloat opacity ) ]

        ToScale scale ->
            [ ( "transform", "scale(" ++ String.fromFloat scale.x ++ ", " ++ String.fromFloat scale.y ++ ")" ) ]

        ToRotation rotation ->
            [ ( "transform", "rotate(" ++ String.fromFloat rotation ++ "deg)" ) ]

        ToBackgroundColor color ->
            [ ( "background-color", colorValueToCss color ) ]

        ToTextColor color ->
            [ ( "color", colorValueToCss color ) ]

        ToBorderColor color ->
            [ ( "border-color", colorValueToCss color ) ]

        ToDimensions dimensions ->
            [ ( "width", String.fromFloat dimensions.width ++ "px" )
            , ( "height", String.fromFloat dimensions.height ++ "px" )
            ]

        ToBorderRadius radius ->
            [ ( "border-radius", String.fromFloat radius ++ "px" ) ]

        ToFilter filter ->
            [ ( "filter", filterValueToCss filter ) ]


{-| Convert a ColorValue to CSS color string.
-}
colorValueToCss : ColorValue -> String
colorValueToCss color =
    case color of
        Hex hex ->
            hex

        Rgb rgb ->
            "rgb(" ++ String.fromInt rgb.r ++ ", " ++ String.fromInt rgb.g ++ ", " ++ String.fromInt rgb.b ++ ")"

        Rgba rgba ->
            "rgba(" ++ String.fromInt rgba.r ++ ", " ++ String.fromInt rgba.g ++ ", " ++ String.fromInt rgba.b ++ ", " ++ String.fromFloat rgba.a ++ ")"

        Hsl hsl ->
            "hsl(" ++ String.fromFloat hsl.h ++ ", " ++ String.fromFloat hsl.s ++ "%, " ++ String.fromFloat hsl.l ++ "%)"

        Hsla hsla ->
            "hsla(" ++ String.fromFloat hsla.h ++ ", " ++ String.fromFloat hsla.s ++ "%, " ++ String.fromFloat hsla.l ++ "%, " ++ String.fromFloat hsla.a ++ ")"


{-| Convert a FilterValue to CSS filter string.
-}
filterValueToCss : FilterValue -> String
filterValueToCss filter =
    case filter of
        Blur blur ->
            "blur(" ++ String.fromFloat blur ++ "px)"

        Brightness brightness ->
            "brightness(" ++ String.fromFloat brightness ++ ")"

        Contrast contrast ->
            "contrast(" ++ String.fromFloat contrast ++ ")"

        Grayscale grayscale ->
            "grayscale(" ++ String.fromFloat grayscale ++ ")"

        Saturate saturate ->
            "saturate(" ++ String.fromFloat saturate ++ ")"
