module Anim.Internal.Engine.Scroll.ScrollTarget exposing
    ( Axis(..)
    , ScrollTarget(..)
    , ScrollTargetType(..)
    , byX
    , byXY
    , byY
    , for
    , getAxis
    , getContainerId
    , getOffset
    , getTargetElement
    , getTargetType
    , getTargetX
    , getTargetY
    , toCoordinates
    , toElement
    , toPercentage
    , toPercentageX
    , toPercentageY
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
    | Percentage Float Float
    | Delta Float Float


{-| Axis configuration for scroll movement
-}
type Axis
    = X
    | Y
    | Both



-- BUILDERS


for : String -> ScrollTarget
for containerId =
    ScrollTarget
        { containerId = containerId
        , target = Coordinates 0 0
        , axis = Both
        , offset = ( 0, 0 )
        }


toXY : Float -> Float -> ScrollTarget -> ScrollTarget
toXY x y (ScrollTarget data) =
    ScrollTarget { data | target = Coordinates x y, axis = Both }


toX : Float -> ScrollTarget -> ScrollTarget
toX x (ScrollTarget data) =
    ScrollTarget { data | target = Coordinates x 0, axis = X }


toY : Float -> ScrollTarget -> ScrollTarget
toY y (ScrollTarget data) =
    ScrollTarget { data | target = Coordinates 0 y, axis = Y }


toElement : String -> ScrollTarget -> ScrollTarget
toElement elementId (ScrollTarget data) =
    ScrollTarget { data | target = Element elementId }


toCoordinates : Float -> Float -> ScrollTarget -> ScrollTarget
toCoordinates x y (ScrollTarget data) =
    ScrollTarget { data | target = Coordinates x y }


toPercentage : Float -> Float -> ScrollTarget -> ScrollTarget
toPercentage xPercent yPercent (ScrollTarget data) =
    ScrollTarget { data | target = Percentage xPercent yPercent }


toPercentageX : Float -> ScrollTarget -> ScrollTarget
toPercentageX xPercent (ScrollTarget data) =
    ScrollTarget { data | target = Percentage xPercent 0, axis = X }


toPercentageY : Float -> ScrollTarget -> ScrollTarget
toPercentageY yPercent (ScrollTarget data) =
    ScrollTarget { data | target = Percentage 0 yPercent, axis = Y }


byXY : Float -> Float -> ScrollTarget -> ScrollTarget
byXY dx dy (ScrollTarget data) =
    ScrollTarget { data | target = Delta dx dy, axis = Both }


byX : Float -> ScrollTarget -> ScrollTarget
byX dx (ScrollTarget data) =
    ScrollTarget { data | target = Delta dx 0, axis = X }


byY : Float -> ScrollTarget -> ScrollTarget
byY dy (ScrollTarget data) =
    ScrollTarget { data | target = Delta 0 dy, axis = Y }


getContainerId : ScrollTarget -> String
getContainerId (ScrollTarget data) =
    data.containerId


getTargetX : ScrollTarget -> Float
getTargetX (ScrollTarget data) =
    case data.target of
        Coordinates x _ ->
            x

        Element _ ->
            0

        Percentage x _ ->
            x

        Delta dx _ ->
            dx


getTargetY : ScrollTarget -> Float
getTargetY (ScrollTarget data) =
    case data.target of
        Coordinates _ y ->
            y

        Element _ ->
            0

        Percentage _ y ->
            y

        Delta _ dy ->
            dy


getAxis : ScrollTarget -> Axis
getAxis (ScrollTarget data) =
    data.axis


getTargetElement : ScrollTarget -> Maybe String
getTargetElement (ScrollTarget data) =
    case data.target of
        Element elementId ->
            Just elementId

        _ ->
            Nothing


getOffset : ScrollTarget -> ( Float, Float )
getOffset (ScrollTarget data) =
    data.offset


getTargetType : ScrollTarget -> ScrollTargetType
getTargetType (ScrollTarget data) =
    data.target
