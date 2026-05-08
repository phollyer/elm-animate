module Anim.Builder exposing
    ( AnimBuilder
    , ForKeyframeEngine, ForSubEngine, ForTransitionEngine, ForWAAPIEngine
    , ForDocumentTimeline, ForScrollTimeline, ForViewTimeline
    )

{-| Builder types for configuring animations with optional type-level restrictions.

Use these types to configure how strict your animation helper signatures should be.
Choose generic modes for broad reuse, or constrained modes when you want stronger
engine and timeline guarantees.

📖 See [Build: Builder Modes](https://phollyer.github.io/elm-animate/animation-workflow/build/#builder-modes)
in the docs for detailed examples and patterns.


# Types

@docs AnimBuilder


## Engine Modes

Use these with `ForDocumentTimeline` when you want to restrict helpers to a specific engine that uses the
browser's Document timeline: Transition, Keyframe, Sub, or WAAPI.

@docs ForKeyframeEngine, ForSubEngine, ForTransitionEngine, ForWAAPIEngine


## Timeline Modes

Use these to restrict helpers to a particular timeline type.

@docs ForDocumentTimeline, ForScrollTimeline, ForViewTimeline

-}

import Anim.Internal.Builder as Internal


{-| The builder type for configuring animations.

The `mode` type parameter is a phantom type that controls where this builder can be used.
Leave it generic for maximum reuse:

    f : AnimBuilder mode -> AnimBuilder mode

Or constrain it to a specific timeline:

    f : AnimBuilder (ForDocumentTimeline engine) -> AnimBuilder (ForDocumentTimeline engine)

Or constrain it to a specific engine.

    f : AnimBuilder (ForDocumentTimeline ForSubEngine) -> AnimBuilder (ForDocumentTimeline ForSubEngine)

Constrained modes make function intent visible from the type signature and can help narrow
which helpers are relevant during debugging.

**Note**: For shorter type signatures, the engine modules expose shorthand aliases targeted to
their specific engine and timeline combinations.

-}
type alias AnimBuilder mode =
    Internal.AnimBuilder mode


{-| Document timeline builder mode, supports Keyframe, Sub, Transition, and WAAPI engines.

Leave the `engine` type parameter generic to allow use with any of these engines,
or constrain it to a specific engine.

Here's a generic Document timeline builder that works with any engine that uses the Document timeline,
but will result in a type error if used with ScrollTimeline or ViewTimeline engines.

    f : AnimBuilder (ForDocumentTimeline engine) -> AnimBuilder (ForDocumentTimeline engine)

Here's an engine-specific Document timeline builder for the Sub Engine.
It will result in a type error if used with any other engine.

    f : AnimBuilder (ForDocumentTimeline ForSubEngine) -> AnimBuilder (ForDocumentTimeline ForSubEngine)

-}
type alias ForDocumentTimeline engine =
    Internal.ForDocumentTimeline engine


{-| Keyframe Engine builder mode.
-}
type alias ForKeyframeEngine =
    Internal.ForKeyframeEngine


{-| Sub Engine builder mode.
-}
type alias ForSubEngine =
    Internal.ForSubEngine


{-| Transition Engine builder mode.
-}
type alias ForTransitionEngine =
    Internal.ForTransitionEngine


{-| WAAPI Engine builder mode.
-}
type alias ForWAAPIEngine =
    Internal.ForWAAPIEngine


{-| ScrollTimeline Engine builder mode.
-}
type alias ForScrollTimeline =
    Internal.ForScrollTimeline


{-| ViewTimeline Engine builder mode.
-}
type alias ForViewTimeline =
    Internal.ForViewTimeline
