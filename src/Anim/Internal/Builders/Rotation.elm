module Anim.Internal.Builders.Rotation exposing
    ( RotationBuilder
    , build
    , delay
    , duration
    , easing
    , for
    , from
    , speed
    , to
    )

import Anim.Internal.Builder as Builder exposing (AnimBuilder)
import Anim.Internal.Builders.Property as PropertyBuilder
import Anim.Internal.Properties.Rotation as Rotation exposing (Rotation)
import Anim.Internal.Timing.Delay exposing (Delay)
import Anim.Internal.Timing.Easing exposing (Easing)
import Anim.Internal.Timing.TimeSpec exposing (TimeSpec(..))



{- Rotation CONFIGURATION BUILDER -}
{- Usage:

   Anim.init
      |> Rotation.for "my-element"
      |> Rotation.from 0
      |> Rotation.to 360
      |> Rotation.duration 2000
      |> Rotation.easing Easing.easeInOut
      |> Rotation.delay (Delay.millis 500)
      |> Rotation.build
      |> Anim.animate
-}


type RotationBuilder
    = RotationBuilder RotationConfig AnimBuilder


for : String -> AnimBuilder -> RotationBuilder
for elementId builder =
    let
        existingConfig =
            case Builder.getElementConfig elementId builder of
                Just { properties } ->
                    properties
                        |> List.filterMap
                            (\prop ->
                                case prop of
                                    Builder.RotateConfig config ->
                                        Just config

                                    _ ->
                                        Nothing
                            )
                        |> List.head

                _ ->
                    Nothing

        newConfig =
            case existingConfig of
                Just config ->
                    PropertyBuilder.applyGlobalDefaults builder <|
                        { config
                            | startAt = Just config.endAt
                            , easing = Nothing
                            , delay = Nothing
                            , timing = Nothing
                            , duration = 0
                            , speed = 0
                            , distance = 0
                        }

                Nothing ->
                    PropertyBuilder.applyGlobalDefaults builder defaultConfig
    in
    RotationBuilder newConfig (Builder.for elementId builder)


build : RotationBuilder -> AnimBuilder
build (RotationBuilder config builder) =
    let
        newRotationConfig =
            Builder.RotateConfig config
    in
    PropertyBuilder.upsert newRotationConfig builder


type alias RotationConfig =
    { startAt : Maybe Rotation
    , endAt : Rotation
    , duration : Int -- Millis
    , speed : Float -- Pixels per second
    , distance : Float -- Pixels
    , timing : Maybe TimeSpec
    , easing : Maybe Easing
    , delay : Maybe Delay
    }


defaultConfig : RotationConfig
defaultConfig =
    { startAt = Nothing
    , endAt = Rotation.fromFloat 0
    , duration = 0
    , speed = 0
    , distance = 0
    , timing = Nothing
    , easing = Nothing
    , delay = Nothing
    }


from : Rotation -> RotationBuilder -> RotationBuilder
from rotation (RotationBuilder config builder) =
    let
        startPos =
            case config.startAt of
                Just opacity_ ->
                    opacity_

                Nothing ->
                    Rotation.fromFloat 0
    in
    RotationBuilder
        { config
            | endAt = rotation
            , distance = Rotation.distance startPos rotation
            , startAt = Just startPos
        }
        builder


to : Rotation -> RotationBuilder -> RotationBuilder
to rotation (RotationBuilder config builder) =
    RotationBuilder { config | endAt = rotation } builder


speed : Float -> RotationBuilder -> RotationBuilder
speed value (RotationBuilder config builder) =
    RotationBuilder
        { config
            | speed = value
            , timing =
                Just <|
                    Speed value
        }
        builder


duration : Int -> RotationBuilder -> RotationBuilder
duration ms (RotationBuilder config builder) =
    RotationBuilder
        { config
            | duration = ms
            , timing =
                Just <|
                    Duration ms
        }
        builder


easing : Easing -> RotationBuilder -> RotationBuilder
easing easing_ (RotationBuilder config builder) =
    RotationBuilder { config | easing = Just easing_ } builder


delay : Delay -> RotationBuilder -> RotationBuilder
delay delay_ (RotationBuilder config builder) =
    RotationBuilder { config | delay = Just delay_ } builder
