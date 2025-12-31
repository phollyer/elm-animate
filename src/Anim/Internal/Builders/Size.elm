module Anim.Internal.Builders.Size exposing
    ( SizeBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , fromH
    , fromHW
    , fromW
    , speed
    , to
    , toH
    , toHW
    , toW
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Properties.Size as Size exposing (Size)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))



{- SIZE CONFIGURATION BUILDER -}
{- Usage:

   Anim.init
       |> Size.for "my-element"
       |> Size.from (Size.fromTuple (100, 50))
       |> Size.to (Size.fromTuple (200, 100))
       |> Size.duration 2000
       |> Size.easing Easing.easeInOut
       |> Size.delay (Delay.millis 500)
       |> Size.build
       |> Anim.animate
-}


type SizeBuilder
    = SizeBuilder (Builder.AnimationConfig Size) AnimBuilder


for : String -> AnimBuilder -> SizeBuilder
for elementId builder =
    let
        -- First set the current element ID in the builder
        builderWithElement =
            Builder.for elementId builder

        existingConfig =
            Builder.getElementConfig elementId builderWithElement
                |> Maybe.andThen
                    (\{ properties } ->
                        properties
                            |> List.filterMap
                                (\prop ->
                                    case prop of
                                        Builder.SizeConfig config ->
                                            Just config

                                        _ ->
                                            Nothing
                                )
                            |> List.head
                    )

        newConfig =
            case existingConfig of
                Just config ->
                    PropertyBuilder.applyGlobalDefaults builder <|
                        { config
                            | start = Just config.end
                            , easing = Nothing
                            , delay = Nothing
                            , perspective = Nothing
                            , timing = Nothing
                            , duration = 0
                            , speed = 0
                            , distance = 0
                            , isDirty = False
                        }

                Nothing ->
                    PropertyBuilder.applyGlobalDefaults builder defaultConfig
    in
    SizeBuilder newConfig builderWithElement


type alias SizeConfig =
    Builder.AnimationConfig Size


defaultConfig : SizeConfig
defaultConfig =
    { start = Nothing
    , end = Size.fromTuple ( 0, 0 )
    , duration = 0
    , speed = 0
    , distance = 0
    , timing = Nothing
    , easing = Nothing
    , delay = Nothing
    , perspective = Nothing
    , isDirty = False
    }


{-| Set the starting size for the animation.
-}
fromHW : Float -> Float -> SizeBuilder -> SizeBuilder
fromHW height width (SizeBuilder config builder) =
    SizeBuilder
        { config | start = Just (Size.fromTuple ( width, height )) }
        builder


{-| Set the starting height for the animation, keeping the current width.
-}
fromH : Float -> SizeBuilder -> SizeBuilder
fromH height (SizeBuilder config builder) =
    let
        currentSize =
            config.start
                |> Maybe.withDefault (Size.fromTuple ( 0, 0 ))

        ( currentWidth, _ ) =
            Size.toTuple currentSize
    in
    SizeBuilder
        { config | start = Just (Size.fromTuple ( currentWidth, height )) }
        builder


{-| Set the starting width for the animation, keeping the current height.
-}
fromW : Float -> SizeBuilder -> SizeBuilder
fromW width (SizeBuilder config builder) =
    let
        currentSize =
            config.start
                |> Maybe.withDefault (Size.fromTuple ( 0, 0 ))

        ( _, currentHeight ) =
            Size.toTuple currentSize
    in
    SizeBuilder
        { config | start = Just (Size.fromTuple ( width, currentHeight )) }
        builder


{-| Set the target size for the animation.
-}
to : Size -> SizeBuilder -> SizeBuilder
to size (SizeBuilder config builder) =
    SizeBuilder
        { config | end = size }
        builder


{-| Set the target width and height for the animation.
-}
toHW : Float -> Float -> SizeBuilder -> SizeBuilder
toHW height width (SizeBuilder config builder) =
    SizeBuilder
        { config | end = Size.fromTuple ( width, height ) }
        builder


{-| Set the target height for the animation, keeping the current target width.
-}
toH : Float -> SizeBuilder -> SizeBuilder
toH height (SizeBuilder config builder) =
    let
        ( currentTargetWidth, _ ) =
            Size.toTuple config.end
    in
    SizeBuilder
        { config | end = Size.fromTuple ( currentTargetWidth, height ) }
        builder


{-| Set the target width for the animation, keeping the current target height.
-}
toW : Float -> SizeBuilder -> SizeBuilder
toW width (SizeBuilder config builder) =
    let
        ( _, currentTargetHeight ) =
            Size.toTuple config.end
    in
    SizeBuilder
        { config | end = Size.fromTuple ( width, currentTargetHeight ) }
        builder


{-| Set the animation speed in pixels per second.
-}
speed : Float -> SizeBuilder -> SizeBuilder
speed pixelsPerSecond (SizeBuilder config builder) =
    SizeBuilder
        { config | timing = Just (Speed pixelsPerSecond) }
        builder


{-| Set the animation duration in milliseconds.
-}
duration : Int -> SizeBuilder -> SizeBuilder
duration ms (SizeBuilder config builder) =
    SizeBuilder
        { config | timing = Just (Duration ms) }
        builder


{-| Set the easing function for the animation.
-}
easing : Easing -> SizeBuilder -> SizeBuilder
easing easingFunction (SizeBuilder config builder) =
    SizeBuilder
        { config | easing = Just easingFunction }
        builder


{-| Set the delay before starting the animation.
-}
delay : Int -> SizeBuilder -> SizeBuilder
delay ms (SizeBuilder config builder) =
    SizeBuilder
        { config | delay = Just ms }
        builder


{-| Build the size animation and add it to the AnimBuilder.
-}
build : SizeBuilder -> AnimBuilder
build (SizeBuilder config builder) =
    let
        -- Convert our SizeConfig to Builder.AnimationConfig Size
        newSizeConfig =
            { start = config.start
            , end = config.end
            , duration = 0 -- Will be calculated during processing
            , speed = 0 -- Will be calculated during processing
            , distance = 0 -- Will be calculated during processing
            , timing = config.timing
            , easing = config.easing
            , delay = config.delay
            , perspective = Nothing -- Size animations don't use perspective
            , isDirty = False
            }

        builderPropertyConfig =
            Builder.SizeConfig newSizeConfig
    in
    PropertyBuilder.upsert builderPropertyConfig builder
