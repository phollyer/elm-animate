module Anim.Internal.Properties.ScrollTarget exposing
    ( Axis(..)
    , ScrollTarget(..)
    , ScrollTargetType(..)
    , for
    , getAxis
    , getContainerId
    , getTargetElement
    , getTargetType
    , getTargetX
    , getTargetY
    , toBottom
    , toCenter
    , toCoordinates
    , toElement
    , toPercentage
    , toTop
    , toX
    , toXY
    , toY
    )

{-| Internal scroll target property representation.

This module defines scroll targets that can be animated to specific
positions, elements, or coordinates within containers.

-}


{-| Scroll target configuration
-}
type ScrollTarget
    = ScrollTarget ScrollTargetData


type alias ScrollTargetData =
    { containerId : String
    , target : ScrollTargetType
    , axis : Axis
    , offset : ( Float, Float )
    }


{-| Type of scroll target
-}
type ScrollTargetType
    = Coordinates Float Float
    | Element String
    | Top
    | Bottom
    | Center
    | Percentage Float Float


{-| Axis configuration for scroll movement
-}
type Axis
    = X
    | Y
    | Both



-- BUILDERS


{-| Create scroll target for a specific container.

    ScrollTarget.for "main-content"

-}
for : String -> ScrollTarget
for containerId =
    ScrollTarget
        { containerId = containerId
        , target = Coordinates 0 0
        , axis = Both
        , offset = ( 0, 0 )
        }


{-| Set target position with X and Y coordinates.

    scrollTarget
        |> ScrollTarget.toXY 100 200

-}
toXY : Float -> Float -> ScrollTarget -> ScrollTarget
toXY x y (ScrollTarget data) =
    ScrollTarget { data | target = Coordinates x y, axis = Both }


{-| Set target position with X coordinate only.

    scrollTarget
        |> ScrollTarget.toX 100

-}
toX : Float -> ScrollTarget -> ScrollTarget
toX x (ScrollTarget data) =
    ScrollTarget { data | target = Coordinates x 0, axis = X }


{-| Set target position with Y coordinate only.

    scrollTarget
        |> ScrollTarget.toY 200

-}
toY : Float -> ScrollTarget -> ScrollTarget
toY y (ScrollTarget data) =
    ScrollTarget { data | target = Coordinates 0 y, axis = Y }


{-| Set target to a specific element by ID.

    scrollTarget
        |> ScrollTarget.toElement "section-header"

-}
toElement : String -> ScrollTarget -> ScrollTarget
toElement elementId (ScrollTarget data) =
    ScrollTarget { data | target = Element elementId }


{-| Set target to the top of the container.

    scrollTarget
        |> ScrollTarget.toTop

-}
toTop : ScrollTarget -> ScrollTarget
toTop (ScrollTarget data) =
    ScrollTarget { data | target = Top, axis = Y }


{-| Set target to the bottom of the container.

    scrollTarget
        |> ScrollTarget.toBottom

-}
toBottom : ScrollTarget -> ScrollTarget
toBottom (ScrollTarget data) =
    ScrollTarget { data | target = Bottom, axis = Y }


{-| Set target to the center of the container.

    scrollTarget
        |> ScrollTarget.toCenter

-}
toCenter : ScrollTarget -> ScrollTarget
toCenter (ScrollTarget data) =
    ScrollTarget { data | target = Center }


{-| Set target to specific coordinates.

    scrollTarget
        |> ScrollTarget.toCoordinates 150 300

-}
toCoordinates : Float -> Float -> ScrollTarget -> ScrollTarget
toCoordinates x y (ScrollTarget data) =
    ScrollTarget { data | target = Coordinates x y }


{-| Set target to percentage of container size.

    scrollTarget
        |> ScrollTarget.toPercentage 0.5 0.8  -- 50% width, 80% height

-}
toPercentage : Float -> Float -> ScrollTarget -> ScrollTarget
toPercentage xPercent yPercent (ScrollTarget data) =
    ScrollTarget { data | target = Percentage xPercent yPercent }



-- GETTERS


{-| Get the container ID for this scroll target.
-}
getContainerId : ScrollTarget -> String
getContainerId (ScrollTarget data) =
    data.containerId


{-| Get the target X coordinate (calculated based on target type).
-}
getTargetX : ScrollTarget -> Float
getTargetX (ScrollTarget data) =
    case data.target of
        Coordinates x _ ->
            x

        Element _ ->
            0

        -- Will be calculated based on element position
        Top ->
            0

        Bottom ->
            0

        Center ->
            0

        -- Will be calculated based on container size
        Percentage x _ ->
            x


{-| Get the target Y coordinate (calculated based on target type).
-}
getTargetY : ScrollTarget -> Float
getTargetY (ScrollTarget data) =
    case data.target of
        Coordinates _ y ->
            y

        Element _ ->
            0

        -- Will be calculated based on element position
        Top ->
            0

        Bottom ->
            0

        -- Will be calculated based on container size
        Center ->
            0

        -- Will be calculated based on container size
        Percentage _ y ->
            y


{-| Get the axis configuration.
-}
getAxis : ScrollTarget -> Axis
getAxis (ScrollTarget data) =
    data.axis


{-| Get the target element ID if the target is an element.
-}
getTargetElement : ScrollTarget -> Maybe String
getTargetElement (ScrollTarget data) =
    case data.target of
        Element elementId ->
            Just elementId

        _ ->
            Nothing


{-| Get the scroll target type.
-}
getTargetType : ScrollTarget -> ScrollTargetType
getTargetType (ScrollTarget data) =
    data.target
