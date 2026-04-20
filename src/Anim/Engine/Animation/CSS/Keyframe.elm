module Anim.Engine.Animation.CSS.Keyframe exposing
    ( AnimState, AnimBuilder, AnimGroupName
    , init
    , animate
    , CurrentTargetId, TargetId, AnimEvent(..)
    , AnimMsg, update
    , attributes
    , styleNode, styleNodeFor, maybeString
    , events, eventsStopPropagation
    , delay
    , duration, speed
    , easing
    , iterations, loopForever, alternate
    , stop, reset, restart, pause, resume
    , discreteEntry, discreteExit
    , transformOrder
    , anyRunning, isRunning, allComplete, isComplete, isCancelled
    , getColorPropertyEnd, getColorPropertyRange, getColorPropertyStart, getPropertyEnd, getPropertyRange, getPropertyStart
    , getBackgroundColorStart, getBackgroundColorEnd, getBackgroundColorRange
    , getFontColorStart, getFontColorEnd, getFontColorRange
    , getOpacityStart, getOpacityEnd, getOpacityRange
    , getRotateStart, getRotateEnd, getRotateRange
    , getScaleStart, getScaleEnd, getScaleRange
    , getSizeStart, getSizeEnd, getSizeRange
    , getTranslateStart, getTranslateEnd, getTranslateRange
    )

{-| Run native CSS Keyframe animations.

For specific Engine guides and examples, see the
[Keyframe Engine Documentation](https://phollyer.github.io/elm-animate/engines/animation/keyframes/).

For Engine comparisons, shared features, examples and code, see the
[Engine Overview](https://phollyer.github.io/elm-animate/engines/animation/overview/) section in the docs.


# Types

@docs AnimState, AnimBuilder, AnimGroupName


# Initialize

@docs init

📖 See [Initialize](https://phollyer.github.io/elm-animate/animation-workflow/init/) in the docs.


# Trigger

@docs animate

📖 See [Triggering Animations](https://phollyer.github.io/elm-animate/animation-workflow/trigger/) in the docs.


# Events

@docs CurrentTargetId, TargetId, AnimEvent

📖 See [Event Reference](https://phollyer.github.io/elm-animate/animation-workflow/react/#event-reference) in the docs.


# Update

@docs AnimMsg, update

📖 See [React](https://phollyer.github.io/elm-animate/animation-workflow/react/) in the docs.


# View

To render a CSS keyframe animation, you need to apply the animation `attributes` to your element
and include a `<style>` node with the generated keyframes.

@docs attributes

@docs styleNode, styleNodeFor, maybeString

📖 See [Render](https://phollyer.github.io/elm-animate/animation-workflow/render/) and
[Keyframe Style Node](https://phollyer.github.io/elm-animate/engines/animation/keyframes/#keyframes-style-node) in the docs.


# Event Listeners

@docs events, eventsStopPropagation

📖 See [Events](https://phollyer.github.io/elm-animate/engines/animation/keyframes/#events) in the docs.


# Playback Settings

@docs delay

@docs duration, speed

@docs easing

@docs iterations, loopForever, alternate

See [Timing](https://phollyer.github.io/elm-animate/getting-started/timing/) and
[Easing](https://phollyer.github.io/elm-animate/getting-started/easing/) in the docs.


# Animation Control

@docs stop, reset, restart, pause, resume

📖 See [Controlling Animations](https://phollyer.github.io/elm-animate/concepts/controlling-animations/) in the docs.


# Discrete Properties

@docs discreteEntry, discreteExit

📖 See [Discrete Properties](https://phollyer.github.io/elm-animate/concepts/discrete-properties/) in the docs.


# Transform Order

@docs transformOrder

📖 See [Transform Ordering](https://phollyer.github.io/elm-animate/concepts/transform-order/) in the docs.


# State Queries

@docs anyRunning, isRunning, allComplete, isComplete, isCancelled

📖 See [State Queries](https://phollyer.github.io/elm-animate/engines/animation/keyframes/#state-queries) in the docs.


# Property Queries

📖 See [Property Queries](https://phollyer.github.io/elm-animate/engines/animation/keyframes/#property-queries) and
[Properties](https://phollyer.github.io/elm-animate/getting-started/properties/) in the docs.


## Custom Properties

@docs getColorPropertyEnd, getColorPropertyRange, getColorPropertyStart, getPropertyEnd, getPropertyRange, getPropertyStart


## Background Color

@docs getBackgroundColorStart, getBackgroundColorEnd, getBackgroundColorRange


## Font Color

@docs getFontColorStart, getFontColorEnd, getFontColorRange


## Opacity

@docs getOpacityStart, getOpacityEnd, getOpacityRange


## Rotate

@docs getRotateStart, getRotateEnd, getRotateRange


## Scale

@docs getScaleStart, getScaleEnd, getScaleRange


## Size

@docs getSizeStart, getSizeEnd, getSizeRange


## Translate

@docs getTranslateStart, getTranslateEnd, getTranslateRange

-}

import Anim.Extra.Color exposing (Color)
import Anim.Extra.Easing exposing (Easing)
import Anim.Extra.TransformOrder exposing (TransformProperty(..))
import Anim.Internal.Engine.Animation.CSS.CSS as CSS
import Anim.Internal.Engine.Animation.CSS.Keyframe as Keyframe
import Anim.Internal.Engine.Animation.CSS.Keyframe.AnimGroup as AnimGroup
import Html



-- ============================================================
-- MODEL
-- ============================================================


{-| The animation state type used to store animation configurations and keyframes.

Store it in your model.

    type alias Model =
        { animState : Keyframe.AnimState }

-}
type alias AnimState =
    Keyframe.AnimState


{-| Animation builder type for configuring animations.
-}
type alias AnimBuilder =
    CSS.AnimBuilder


{-| A type alias for animation group names.

Used to identify which animation group to target in functions like
[attributes](#attributes), [isRunning](#isRunning), [stop](#stop), etc.

-}
type alias AnimGroupName =
    String



-- ============================================================
-- INITIALIZE
-- ============================================================


{-| Initialize animation state with optional property initializers.

    -- Empty state
    Keyframe.init []

    -- With initial properties
    Keyframe.init
        [ Translate.initXY "animGroupName" 100 50
        , Opacity.init "animGroupName" 0.5
        ]

-}
init : List (AnimBuilder -> AnimBuilder) -> AnimState
init =
    Keyframe.init



-- ============================================================
-- TRIGGER
-- ============================================================


{-| Trigger animations.

    { model
        | animState =
            Keyframe.animate model.animState <|
                fadeIn
                    >> slideIn
    }

-}
animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate =
    Keyframe.animate



-- ============================================================
-- EVENTS
-- ============================================================


{-| The ID of the element where the handler is attached.

Returns `Nothing` if the element has no ID attribute.

-}
type alias CurrentTargetId =
    Maybe String


{-| The ID of the element that triggered the event.

Returns `Nothing` if the element has no ID attribute.

This may be different from `CurrentTargetId` if the event bubbled up from a child element.

-}
type alias TargetId =
    Maybe String


{-| CSS keyframe animation lifecycle events.
-}
type AnimEvent
    = Started CurrentTargetId TargetId AnimGroupName
    | Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Iteration CurrentTargetId TargetId AnimGroupName Int
    | Paused AnimGroupName
    | Resumed AnimGroupName
    | Restarted AnimGroupName



-- ============================================================
-- UPDATE
-- ============================================================


{-| Internal message type.

    type Msg
        = KeyframeMsg Keyframe.AnimMsg
        | ...

-}
type alias AnimMsg =
    Keyframe.AnimMsg


{-| Handle animation lifecycle messages.

Returns the updated state and an [AnimEvent](#AnimEvent) for you to pattern match on.

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            KeyframeMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Keyframe.update animMsg model.animState
                in
                handleAnimationEvent event { model | animState = newAnimState }

    handleAnimationEvent : Keyframe.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            ...

-}
update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update msg =
    Keyframe.update msg
        >> Tuple.mapSecond mapEvent


mapEvent : Keyframe.AnimEvent -> AnimEvent
mapEvent event =
    case event of
        Keyframe.Started currentTargetId targetId animGroup ->
            Started currentTargetId targetId animGroup

        Keyframe.Ended currentTargetId targetId animGroup ->
            Ended currentTargetId targetId animGroup

        Keyframe.Cancelled currentTargetId targetId animGroup ->
            Cancelled currentTargetId targetId animGroup

        Keyframe.Iteration currentTargetId targetId animGroup iteration ->
            Iteration currentTargetId targetId animGroup iteration

        Keyframe.Paused animGroup ->
            Paused animGroup

        Keyframe.Resumed animGroup ->
            Resumed animGroup

        Keyframe.Restarted animGroup ->
            Restarted animGroup



-- ============================================================
-- VIEW
-- ============================================================


{-| Apply the animation `attributes` to your element.

    div
        (Keyframe.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes =
    Keyframe.attributes


{-| Get a `<style>` node containing the keyframes for all animations.

    view model =
        div []
            [ Keyframe.styleNode animState
            , ...
            ]

If there are no animations, this returns an empty text node.

-}
styleNode : AnimState -> Html.Html msg
styleNode =
    Keyframe.styleNode


{-| Get a `<style>` node containing keyframes for a specific animation group.

    view model =
        div []
            [ Keyframe.styleNodeFor "animGroupName" animState
            , ...
            ]

If there are no animations, this returns an empty text node.

-}
styleNodeFor : AnimGroupName -> AnimState -> Html.Html msg
styleNodeFor =
    Keyframe.styleNodeFor


{-| Get the raw generated CSS keyframes string for advanced use cases.

You probably want [styleNodeFor](#styleNodeFor) instead,
which handles creating the full `<style>` node for you.

-}
maybeString : AnimGroupName -> AnimState -> Maybe String
maybeString =
    Keyframe.maybeKeyframesString



-- ============================================================
-- EVENT LISTENERS
-- ============================================================


{-| Receive keyframe animation lifecycle events.

Add `events` to your element with a message constructor that wraps `AnimMsg`.

    type Msg
        = KeyframeMsg Keyframe.AnimMsg

    div
        (Keyframe.attributes "animGroupName" animState
            ++ Keyframe.events "animGroupName" KeyframeMsg
        )
        [ text "Animating element" ]

-}
events : (AnimMsg -> msg) -> List (Html.Attribute msg)
events =
    Keyframe.events


{-| The same as [events](#events) but with propagation stopped.

    div
        (Keyframe.attributes "myElement" model.animState
            ++ Keyframe.eventsStopPropagation "myElement" KeyframeMsg
        )
        [ text "Animated element" ]

-}
eventsStopPropagation : (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation =
    Keyframe.eventsStopPropagation



-- ============================================================
-- PLAYBACK SETTINGS
-- ============================================================


{-| Set the global delay in milliseconds.

    Keyframe.animate model.animState <|
        Keyframe.delay 500
            >> slideIn

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    CSS.delay


{-| Set the global duration in milliseconds.

    Keyframe.animate model.animState <|
        Keyframe.duration 500
            >> slideIn

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    CSS.duration


{-| Set the global speed in property units per second.

Consult each property's documentation for details on how speed is interpreted.

    Keyframe.animate model.animState <|
        Keyframe.speed 100
            >> slideIn

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    CSS.speed


{-| Set the global easing function.

    import Anim.Extra.Easing exposing (Easing(..))

    Keyframe.animate model.animState <|
        Keyframe.easing BounceOut
            >> slideIn

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    CSS.easing


{-| Set how many times an animation should repeat.

    Keyframe.animate model.animState <|
        Keyframe.iterations 3
            >> pulse

-}
iterations : Int -> AnimBuilder -> AnimBuilder
iterations =
    CSS.iterations


{-| Make an animation loop infinitely.

    Keyframe.animate model.animState <|
        Keyframe.loopForever
            >> pulse

-}
loopForever : AnimBuilder -> AnimBuilder
loopForever =
    CSS.loopForever


{-| Make an animation alternate direction on each iteration (ping-pong effect).

    Keyframe.animate model.animState <|
        Keyframe.loopForever
            >> Keyframe.alternate
            >> pulse

This creates a smooth ping-pong animation.
The animation plays forward, then backward, then forward, etc.

-}
alternate : AnimBuilder -> AnimBuilder
alternate =
    CSS.alternate



-- ============================================================
-- ANIMATION CONTROL
-- ============================================================


{-| Stop a running animation by instantly jumping to its end state.

    Keyframe.stop "animGroup" model.animState

-}
stop : AnimGroupName -> AnimState -> AnimState
stop =
    Keyframe.stop


{-| Reset an animation by instantly jumping back to its start state.

    Keyframe.reset "animGroup" model.animState

-}
reset : AnimGroupName -> AnimState -> AnimState
reset =
    Keyframe.reset


{-| Restart an animation from the beginning.

    let
        ( newState, cmd ) =
            Keyframe.restart "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
restart : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
restart =
    Keyframe.restart


{-| Pause a running animation.

    let
        ( newState, cmd ) =
            Keyframe.pause "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
pause : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
pause =
    Keyframe.pause


{-| Resume a paused animation.

    let
        ( newState, cmd ) =
            Keyframe.resume "boxAnim" GotAnimMsg model.animState
    in
    ( { model | animState = newState }, cmd )

-}
resume : AnimGroupName -> (AnimMsg -> msg) -> AnimState -> ( AnimState, Cmd msg )
resume =
    Keyframe.resume



-- ============================================================
-- DISCRETE PROPERTIES
-- ============================================================


{-| Add a discrete CSS property for entry animations.

The value is applied at every step of the animation, ensuring the element is
immediately in the target state when the animation starts. The browser already
knows the element's pre-animation state from its own CSS.

    Keyframe.animate model.animState <|
        Keyframe.discreteEntry "display" "block"
            >> Keyframe.discreteEntry "pointer-events" "auto"
            >> fadeIn

-}
discreteEntry : String -> String -> AnimBuilder -> AnimBuilder
discreteEntry =
    CSS.discreteEntry


{-| Add a discrete CSS property for exit animations.

Exit animations need to hold their initial state
until the very end of the animation, at which point they flip to the final state.

Therefore you need to set both the `from` and `to` values for the property.

Use when an element is disappearing (e.g., going from
`display: block` to `display: none`).

    Keyframe.animate model.animState <|
        Keyframe.discreteExit "display" "block" "none"
            >> fadeOut

-}
discreteExit : String -> String -> String -> AnimBuilder -> AnimBuilder
discreteExit =
    CSS.discreteExit



-- ============================================================
-- TRANSFORM ORDER
-- ============================================================


{-| Set the transform order.

The transform order specifies how translate, rotate, and scale transforms
are combined. Start the list with the transform to apply first.

Any missing transforms are automatically appended in the default order
(Translate → Rotate → Scale).

    Keyframe.transformOrder [ Scale, Rotate, Translate ]
        >> rotateLeft
        >> scaleUp
        >> moveRight

-}
transformOrder : List TransformProperty -> AnimBuilder -> AnimBuilder
transformOrder =
    CSS.transformOrder



-- ============================================================
-- STATE QUERIES
-- ============================================================


{-| Check if any animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : AnimState -> Maybe Bool
anyRunning =
    CSS.anyRunning AnimGroup.isRunning


{-| Check if a specific animation group is currently running.

Returns `Nothing` if there are no animations for the group.

-}
isRunning : AnimGroupName -> AnimState -> Maybe Bool
isRunning =
    CSS.isRunning AnimGroup.isRunning


{-| Check if a specific animation group has completed.

Returns `Nothing` if there are no animations for the group.

-}
isComplete : AnimGroupName -> AnimState -> Maybe Bool
isComplete =
    CSS.isComplete AnimGroup.isComplete


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    CSS.allComplete AnimGroup.isComplete


{-| Check if a specific animation group was cancelled.

Returns `Nothing` if there are no animations for the group.

-}
isCancelled : AnimGroupName -> AnimState -> Maybe Bool
isCancelled =
    CSS.isCancelled AnimGroup.isCancelled



-- ============================================================
-- PROPERTY QUERIES
-- ============================================================
--
--
-- ============================
-- BACKGROUND COLOR
-- ============================


{-| Get the start background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getBackgroundColorStart : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorStart =
    CSS.getBackgroundColorStart


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorEnd : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorEnd =
    CSS.getBackgroundColorEnd


{-| Get the background color range (start and end) of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Color, end : Color }
getBackgroundColorRange =
    CSS.getBackgroundColorRange



-- ============================
-- FONT COLOR
-- ============================


{-| Get the start font color of an element being animated.

Returns `Nothing` if the element has no font color animation.

Returns `opaque black (rgba 0 0 0 1)` if no explicit start value was set, which is the default when no start value is set.

-}
getFontColorStart : AnimGroupName -> AnimState -> Maybe Color
getFontColorStart =
    CSS.getFontColorStart


{-| Get the end font color of an element being animated.

Returns `Nothing` if the element has no font color animation.

-}
getFontColorEnd : AnimGroupName -> AnimState -> Maybe Color
getFontColorEnd =
    CSS.getFontColorEnd


{-| Get the font color range (start and end) of an element being animated.

Returns `Nothing` if the element has no font color animation.

-}
getFontColorRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Color, end : Color }
getFontColorRange =
    CSS.getFontColorRange



-- ============================
-- OPACITY
-- ============================


{-| Get the start opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

Returns `Just 1.0` (fully opaque) if no explicit start value was set, which is the default when no start value is set.

-}
getOpacityStart : AnimGroupName -> AnimState -> Maybe Float
getOpacityStart =
    CSS.getOpacityStart


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd =
    CSS.getOpacityEnd


{-| Get the opacity range (start and end) of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityRange : AnimGroupName -> AnimState -> Maybe { start : Maybe Float, end : Float }
getOpacityRange =
    CSS.getOpacityRange



-- ============================
-- ROTATE
-- ============================


{-| Get the start rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getRotateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateStart =
    CSS.getRotateStart


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd =
    CSS.getRotateEnd


{-| Get the rotate range (start and end) of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getRotateRange =
    CSS.getRotateRange



-- ============================
-- SCALE
-- ============================


{-| Get the start scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

Returns `Just { x = 1, y = 1, z = 1 }` if no explicit start value was set, which is the default when no start value is set.

-}
getScaleStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleStart =
    CSS.getScaleStart


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd =
    CSS.getScaleEnd


{-| Get the scale range (start and end) of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getScaleRange =
    CSS.getScaleRange



-- ============================
-- SIZE
-- ============================


{-| Get the start size of an element being animated.

Returns `Nothing` if the element has no size animation.

Returns `Just { width = 0, height = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getSizeStart : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeStart =
    CSS.getSizeStart


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd =
    CSS.getSizeEnd


{-| Get the size range (start and end) of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { width : Float, height : Float }, end : { width : Float, height : Float } }
getSizeRange =
    CSS.getSizeRange



-- ============================
-- TRANSLATE
-- ============================


{-| Get the start translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

Returns `Just { x = 0, y = 0, z = 0 }` if no explicit start value was set, which is the default when no start value is set.

-}
getTranslateStart : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateStart =
    CSS.getTranslateStart


{-| Get the end translate of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd =
    CSS.getTranslateEnd


{-| Get the translate range (start and end) of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateRange : AnimGroupName -> AnimState -> Maybe { start : Maybe { x : Float, y : Float, z : Float }, end : { x : Float, y : Float, z : Float } }
getTranslateRange =
    CSS.getTranslateRange



-- ============================
-- CUSTOM PROPERTY
-- ============================


{-| Get the custom property range (start and end) of an element being animated.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Float, end : Float }
getPropertyRange =
    CSS.getPropertyRange


{-| Get the start value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

Returns `Just 0` if no explicit start value was set, which is the default when no start value is set.

-}
getPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyStart =
    CSS.getPropertyStart


{-| Get the end value of a custom property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom property.

-}
getPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Float
getPropertyEnd =
    CSS.getPropertyEnd



-- ============================
-- CUSTOM COLOR PROPERTY
-- ============================


{-| Get the custom color property range (start and end) of an element being animated.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyRange : AnimGroupName -> String -> AnimState -> Maybe { start : Maybe Color, end : Color }
getColorPropertyRange =
    CSS.getColorPropertyRange


{-| Get the start value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

Returns `transparent white (rgba 255 255 255 0)` if no explicit start value was set, which is the default when no start value is set.

-}
getColorPropertyStart : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyStart =
    CSS.getColorPropertyStart


{-| Get the end value of a custom color property animation.

The second argument is the CSS property name.

Returns `Nothing` if the element has no animation for the given custom color property.

-}
getColorPropertyEnd : AnimGroupName -> String -> AnimState -> Maybe Color
getColorPropertyEnd =
    CSS.getColorPropertyEnd
