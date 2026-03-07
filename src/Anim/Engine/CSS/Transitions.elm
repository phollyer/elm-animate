module Anim.Engine.CSS.Transitions exposing
    ( AnimGroupName
    , AnimState, init
    , attributes
    , AnimMsg, CurrentTargetId, TargetId, AnimEvent(..), update, events, eventsStopPropagation
    , AnimBuilder, animate, TransformOrder(..), transformOrder
    , duration, speed
    , easing
    , delay
    , allowDiscrete
    , startingStyleNode, startingStyleNodeFor
    , stop, reset
    , anyRunning, isRunning, allComplete, isComplete
    , getBackgroundColorEnd, getOpacityEnd, getRotateEnd, getScaleEnd, getSizeEnd, getTranslateEnd
    )

{-| CSS Transitions engine for smooth A→B animations.

For detailed guides, examples, and engine comparisons, see the
[full documentation](https://phollyer.github.io/elm-animate/engines/transitions/).


# Types

@docs AnimGroupName


# State

@docs AnimState, init


# Apply Transitions

@docs attributes


# Events

@docs AnimMsg, CurrentTargetId, TargetId, AnimEvent, update, events, eventsStopPropagation


# Execute

@docs AnimBuilder, animate, TransformOrder, transformOrder


# Builder Settings

@docs duration, speed

@docs easing

@docs delay


## Discrete Property Transitions

@docs allowDiscrete

@docs startingStyleNode, startingStyleNodeFor


# Animation Control

@docs stop, reset


# Querying Animation State

@docs anyRunning, isRunning, allComplete, isComplete


# Querying Animated Properties

@docs getBackgroundColorEnd, getOpacityEnd, getRotateEnd, getScaleEnd, getSizeEnd, getTranslateEnd

-}

import Anim.Extra.Color exposing (Color)
import Anim.Extra.Easing exposing (Easing)
import Anim.Internal.Builder as Builder
import Anim.Internal.CSS as InternalCSS exposing (ElementState(..))
import Anim.Internal.Properties.Opacity as Opacity
import Anim.Internal.Properties.Rotate as Rotate
import Anim.Internal.Properties.Scale as Scale
import Anim.Internal.Properties.Size as Size
import Anim.Internal.Properties.Translate as Translate
import Html
import Html.Attributes



-- TYPES


{-| A type alias for animation group names.

Used to identify which animation group to target in functions like
[attributes](#attributes), [isRunning](#isRunning), [stop](#stop), etc.

-}
type alias AnimGroupName =
    String


{-| The animation state type used to store animation configurations and transitions.

Both state-tracked and fire-and-forget animations produce an `AnimState`, but only
state-tracked animations require storing it in your model:

    type alias Model =
        { animState : Transitions.AnimState }

-}
type alias AnimState =
    InternalCSS.AnimState


{-| Animation builder type for configuring animations.
-}
type alias AnimBuilder =
    InternalCSS.AnimBuilder


{-| Transform property ordering.

The **default** (recommended) transform order is: Translate → Rotate → Scale.

  - Translate sets the base location
  - Rotation happens around that position
  - Scale happens last to avoid affecting rotation radius

-}
type TransformOrder
    = Translate
    | Rotate
    | Scale


{-| Opaque message type for CSS transition DOM events.

Pass this to your parent Msg type and forward it to [update](#update).

    type Msg
        = TransitionMsg Transitions.AnimMsg
        | ...

-}
type AnimMsg
    = AnimMsg InternalAnimMsg


{-| Internal message variants.
-}
type InternalAnimMsg
    = InternalStarted InternalCSS.SourceEventData
    | InternalEnded InternalCSS.SourceEventData
    | InternalCancelled InternalCSS.SourceEventData
    | InternalRun InternalCSS.SourceEventData


{-| The ID of the element where the handler is attached.

If the element has no ID attribute, this will be an empty string.

-}
type alias CurrentTargetId =
    String


{-| The ID of the element that triggered the event.

If the element has no ID attribute, this will be an empty string.

This may be different from `CurrentTargetId` if the event bubbled up from a child element.

-}
type alias TargetId =
    String


{-| CSS transition lifecycle events.
-}
type AnimEvent
    = Started CurrentTargetId TargetId AnimGroupName
    | Ended CurrentTargetId TargetId AnimGroupName
    | Cancelled CurrentTargetId TargetId AnimGroupName
    | Run CurrentTargetId TargetId AnimGroupName



-- INIT


{-| Initialize animation state with optional property initializers.

    -- Empty state
    Transitions.init []

    -- With initial properties
    Transitions.init
        [ Translate.initXY "animGroupName" 100 50
        , Opacity.init "animGroupName" 0.5
        ]

-}
init : List (AnimBuilder -> AnimBuilder) -> AnimState
init =
    InternalCSS.init



-- EXECUTE


{-| Create a state-tracked animation.

    { model
        | animState =
            Transitions.animate model.animState <|
                (fadeIn >> slideIn)
    }

-}
animate : AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState
animate =
    InternalCSS.animate


{-| Set the transform order for all future animations.

The transform order specifies how translate, rotate, and scale transforms
are combined. Start the list with the transform to apply first.

Any missing transforms are automatically appended in the default order
(Translate → Rotate → Scale).

    model.animState
        |> Transitions.transformOrder [ Scale, Rotate, Translate ]
        |> Transitions.animate
            (rotateLeft >> scaleUp >> moveRight)

-}
transformOrder : List TransformOrder -> AnimBuilder -> AnimBuilder
transformOrder order =
    let
        mapOrder xform =
            case xform of
                Translate ->
                    Builder.Translate

                Rotate ->
                    Builder.Rotate

                Scale ->
                    Builder.Scale
    in
    Builder.transformOrder (List.map mapOrder order)



-- BUILDER SETTINGS


{-| Set the global duration in milliseconds.

    model.animState
        |> Transitions.builder
        |> Transitions.duration 500
        |> ...

-}
duration : Int -> AnimBuilder -> AnimBuilder
duration =
    InternalCSS.duration


{-| Set the global speed in pixels per second.

    model.animState
        |> Transitions.builder
        |> Transitions.speed 100
        |> ...

-}
speed : Float -> AnimBuilder -> AnimBuilder
speed =
    InternalCSS.speed


{-| Set the global easing function.

    model.animState
        |> Transitions.builder
        |> Transitions.easing EaseInOutQuad
        |> ...

-}
easing : Easing -> AnimBuilder -> AnimBuilder
easing =
    InternalCSS.easing


{-| Set the global delay in milliseconds.

    model.animState
        |> Transitions.builder
        |> Transitions.delay 500
        |> ...

-}
delay : Int -> AnimBuilder -> AnimBuilder
delay =
    InternalCSS.delay


{-| Enable transitions for discrete CSS properties using `transition-behavior: allow-discrete`.

    Transitions.animate model.animState <|
        (Transitions.allowDiscrete >> fadeIn >> slideIn)

-}
allowDiscrete : AnimBuilder -> AnimBuilder
allowDiscrete =
    Builder.allowDiscreteTransitions


{-| Generate a `<style>` node containing `@starting-style` rules for all animated elements.

When an element enters the DOM (or changes from `display: none`), the browser needs
to know what values to animate FROM. Without `@starting-style`, the browser skips
the transition.

    view model =
        div []
            [ Transitions.startingStyleNode model.animState
            , div (Transitions.attributes "fadeIn" model.animState)
                [ text "I fade in!" ]
            ]

-}
startingStyleNode : AnimState -> Html.Html msg
startingStyleNode =
    InternalCSS.startingStyleNode


{-| Generate `@starting-style` rules for a specific element.

    view model =
        div []
            [ Transitions.startingStyleNodeFor "fadeIn" model.animState
            , div (Transitions.attributes "fadeIn" model.animState)
                [ text "I fade in!" ]
            ]

-}
startingStyleNodeFor : AnimGroupName -> AnimState -> Html.Html msg
startingStyleNodeFor =
    InternalCSS.startingStyleNodeFor



-- TRANSITION ATTRIBUTES


{-| Get the transition and transform attributes to apply to the target element.

    div
        (Transitions.attributes "animGroupName" animState)
        [ text "Animating element" ]

-}
attributes : AnimGroupName -> AnimState -> List (Html.Attribute msg)
attributes =
    InternalCSS.transitionAttributes



-- TRANSITION EVENTS


{-| The simplest way to receive transition messages.

    type Msg
        = TransitionMsg Transitions.AnimMsg

    div
        (Transitions.attributes "animGroupName" animState
            ++ Transitions.events "animGroupName" TransitionMsg
        )
        [ text "Animating element" ]

-}
events : AnimGroupName -> (AnimMsg -> msg) -> List (Html.Attribute msg)
events animGroup toMsg =
    List.map (Html.Attributes.map toMsg) <|
        [ InternalCSS.onTransitionStartWithSource animGroup (AnimMsg << InternalStarted)
        , InternalCSS.onTransitionEndWithSource animGroup (AnimMsg << InternalEnded)
        , InternalCSS.onTransitionRunWithSource animGroup (AnimMsg << InternalRun)
        , InternalCSS.onTransitionCancelWithSource animGroup (AnimMsg << InternalCancelled)
        ]


{-| Handle CSS transition lifecycle messages.

Returns the updated state and an event for you to pattern match on.

    updateModel msg model =
        case msg of
            TransitionMsg animMsg ->
                let
                    ( newAnimState, event ) =
                        Transitions.update animMsg model.animState
                in
                handleAnimationEvent event { model | animState = newAnimState }

    handleAnimationEvent : Transitions.AnimEvent -> Model -> ( Model, Cmd Msg )
    handleAnimationEvent event model =
        case event of
            Transitions.Ended _ _ animGroup ->
                -- Animation ended
                ( model, Cmd.none )

            _ ->
                ( model, Cmd.none )

-}
update : AnimMsg -> AnimState -> ( AnimState, AnimEvent )
update (AnimMsg animMsg) animState =
    let
        idOrEmpty maybeId =
            Maybe.withDefault "" maybeId
    in
    case animMsg of
        InternalStarted data ->
            ( InternalCSS.handleEvent (InternalCSS.TransitionStarted data.animGroup) animState
            , Started (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )

        InternalEnded data ->
            ( InternalCSS.handleEvent (InternalCSS.TransitionEnded data.animGroup) animState
            , Ended (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )

        InternalRun data ->
            ( InternalCSS.handleEvent (InternalCSS.TransitionRun data.animGroup) animState
            , Run (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )

        InternalCancelled data ->
            ( InternalCSS.handleEvent (InternalCSS.TransitionCancelled data.animGroup) animState
            , Cancelled (idOrEmpty data.currentTargetId) (idOrEmpty data.targetId) data.animGroup
            )


{-| All transition event handlers with propagation stopped.
Use this to prevent events from bubbling up to parent elements with listeners.

    div
        (Transitions.attributes "myElement" model.animState
            ++ Transitions.eventsStopPropagation "myElement" TransitionMsg
        )
        [ text "Animated element" ]

-}
eventsStopPropagation : AnimGroupName -> (AnimMsg -> msg) -> List (Html.Attribute msg)
eventsStopPropagation animGroup toMsg =
    List.map (Html.Attributes.map toMsg) <|
        [ InternalCSS.onTransitionStartWithSourceStopPropagation animGroup (AnimMsg << InternalStarted)
        , InternalCSS.onTransitionEndWithSourceStopPropagation animGroup (AnimMsg << InternalEnded)
        , InternalCSS.onTransitionRunWithSourceStopPropagation animGroup (AnimMsg << InternalRun)
        , InternalCSS.onTransitionCancelWithSourceStopPropagation animGroup (AnimMsg << InternalCancelled)
        ]



-- ANIMATION CONTROL


{-| Stop a running animation by instantly jumping to its end state.

    Transitions.stop "elementId" model.animState

-}
stop : AnimGroupName -> AnimState -> AnimState
stop =
    InternalCSS.stopAnimation


{-| Reset an animation by instantly jumping back to its start state.

    Transitions.reset "elementId" model.animState

-}
reset : AnimGroupName -> AnimState -> AnimState
reset =
    InternalCSS.reset



-- STATE QUERIES


{-| Check if any animations are currently running.

Returns `Nothing` if there are no animations.

-}
anyRunning : AnimState -> Maybe Bool
anyRunning =
    InternalCSS.anyRunning


{-| Check if a specific element has any animations currently running.

Returns `Nothing` if there are no animations for the element.

-}
isRunning : AnimGroupName -> AnimState -> Maybe Bool
isRunning =
    InternalCSS.isRunning


{-| Check if a specific element's animations have completed.

Returns `Nothing` if there are no animations for the element.

-}
isComplete : AnimGroupName -> AnimState -> Maybe Bool
isComplete =
    InternalCSS.isComplete


{-| Check if all animations are complete.

Returns `Nothing` if there are no animations.

-}
allComplete : AnimState -> Maybe Bool
allComplete =
    InternalCSS.allComplete



-- TRANSLATE GETTERS


{-| Get the end translate value of an element being animated.

Returns `Nothing` if the element has no translate animation.

-}
getTranslateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getTranslateEnd elementId animState =
    InternalCSS.getTranslateRange elementId animState
        |> Maybe.map .end
        |> Maybe.map Translate.toRecord



-- SCALE GETTERS


{-| Get the end scale of an element being animated.

Returns `Nothing` if the element has no scale animation.

-}
getScaleEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getScaleEnd elementId animState =
    InternalCSS.getScaleRange elementId animState
        |> Maybe.map (.end >> Scale.toRecord)



-- ROTATE GETTERS


{-| Get the end rotation of an element being animated.

Returns `Nothing` if the element has no rotate animation.

-}
getRotateEnd : AnimGroupName -> AnimState -> Maybe { x : Float, y : Float, z : Float }
getRotateEnd elementId animState =
    InternalCSS.getRotateRange elementId animState
        |> Maybe.map (.end >> Rotate.toRecord)



-- OPACITY GETTERS


{-| Get the end opacity of an element being animated.

Returns `Nothing` if the element has no opacity animation.

-}
getOpacityEnd : AnimGroupName -> AnimState -> Maybe Float
getOpacityEnd elementId animState =
    InternalCSS.getOpacityRange elementId animState
        |> Maybe.map (.end >> Opacity.toFloat)



-- SIZE GETTERS


{-| Get the end size of an element being animated.

Returns `Nothing` if the element has no size animation.

-}
getSizeEnd : AnimGroupName -> AnimState -> Maybe { width : Float, height : Float }
getSizeEnd elementId animState =
    InternalCSS.getSizeRange elementId animState
        |> Maybe.map (.end >> Size.toRecord)



-- BACKGROUND COLOR GETTERS


{-| Get the end background color of an element being animated.

Returns `Nothing` if the element has no background color animation.

-}
getBackgroundColorEnd : AnimGroupName -> AnimState -> Maybe Color
getBackgroundColorEnd elementId animState =
    InternalCSS.getBackgroundColorRange elementId animState
        |> Maybe.map .end
