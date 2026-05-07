module Anim.Builder exposing
    ( AnimBuilder
    , ForDocumentTimeline, ForKeyframeEngine, ForSubEngine, ForTransitionEngine, ForWAAPIEngine
    , ForScrollTimeline, ForViewTimeline
    )

{-| The core animation builder type.

This is the type used by all animation configuration functions across all properties and engines.

This will only be useful to folks building reusable animation functions that are intended to work
with every animation Engine. Generally, you can just use the `AnimBuilder` type alias from the
specific Engine you're using, and the type system will enforce compatibility for you.


# Types

@docs AnimBuilder


## Modes

@docs ForDocumentTimeline, ForKeyframeEngine, ForSubEngine, ForTransitionEngine, ForWAAPIEngine

@docs ForScrollTimeline, ForViewTimeline

The builder mode is important to understand when building reusable animation functions. Setting a specific mode
in animation functions will restrict them to Engines using that timeline.

    import Anim.Builder exposing (AnimBuilder, ForScrollTimeline)
    import Anim.Property.Translate as Translate

    moveRight : AnimBuilder ForScrollTimeline -> AnimBuilder ForScrollTimeline
    moveRight =
        Translate.for "animGroupName"
            ...

This animation can only be used with the `ScrollTimeline` Engine, and will cause a type error if you try to use it
with an Engine that uses a different timeline, like Keyframe or ViewTimeline.

If you want your animations to work with any timeline, don't fix the mode to a specific one:

    import Anim.Builder exposing (AnimBuilder)
    import Anim.Property.Translate as Translate

    moveRight : AnimBuilder mode -> AnimBuilder mode
    moveRight =
        Translate.for "animGroupName"
            ...

This animation can be used by any animation Engine 🎉

-}

import Anim.Internal.Builder as Internal


{-| The builder type for configuring animations.

The `mode` type parameter is a phantom type that enforces timeline compatibility at compile time,
or sooner if you're using an editor with language server support.
This lets the API stay composable while preventing invalid combinations of builders and engines.

-}
type alias AnimBuilder mode =
    Internal.AnimBuilder mode


{-| Type alias for the document timeline builder mode.

Use this when building animations with Engines that use the browser's Document timeline:

  - Keyframe
  - Transition
  - Sub
  - WAAPI

-}
type alias ForDocumentTimeline engine =
    Internal.ForDocumentTimeline engine


{-| Type alias for the Keyframe Engine builder mode.
-}
type alias ForKeyframeEngine =
    Internal.ForKeyframeEngine


{-| Type alias for the Sub Engine builder mode.
-}
type alias ForSubEngine =
    Internal.ForSubEngine


{-| Type alias for the Transition Engine builder mode.
-}
type alias ForTransitionEngine =
    Internal.ForTransitionEngine


{-| Type alias for the WAAPI Engine builder mode.
-}
type alias ForWAAPIEngine =
    Internal.ForWAAPIEngine


{-| Type alias for the scroll timeline builder mode.

Use this when building animations with the ScrollTimeline Engine.

-}
type alias ForScrollTimeline =
    Internal.ForScrollTimeline


{-| Type alias for the view timeline builder mode.

Use this when building animations with the ViewTimeline Engine.

-}
type alias ForViewTimeline =
    Internal.ForViewTimeline
