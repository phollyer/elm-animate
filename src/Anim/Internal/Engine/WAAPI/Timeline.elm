module Anim.Internal.Engine.WAAPI.Timeline exposing
    ( Engine(..)
    , isAnimationUpdateFor
    , routeForEngine
    )

import Json.Decode as Decode


type Engine
    = Waapi
    | ScrollTimeline
    | ViewTimeline


isAnimationUpdateFor : Engine -> Decode.Value -> Bool
isAnimationUpdateFor expectedEngine jsonValue =
    case Decode.decodeValue (Decode.field "type" Decode.string) jsonValue of
        Ok "animationUpdate" ->
            let
                decodedEngine =
                    Decode.decodeValue (Decode.field "engine" Decode.string) jsonValue
            in
            case expectedEngine of
                Waapi ->
                    case decodedEngine of
                        Ok "waapi" ->
                            True

                        -- Backwards compatibility for older payloads that omitted engine.
                        Err _ ->
                            True

                        _ ->
                            False

                ScrollTimeline ->
                    decodedEngine == Ok "scrollTimeline"

                ViewTimeline ->
                    decodedEngine == Ok "viewTimeline"

        _ ->
            False


routeForEngine : Engine -> (Decode.Value -> msg) -> msg -> Decode.Value -> msg
routeForEngine expectedEngine onMatch onIgnore jsonValue =
    if isAnimationUpdateFor expectedEngine jsonValue then
        onMatch jsonValue

    else
        onIgnore
