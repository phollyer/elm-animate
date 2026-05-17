module Anim.Resize exposing
    ( Builder
    , policy, Policy, RangePolicy(..), CurrentPolicy(..), TimingPolicy(..)
    , AxisBounds, Bounds, bounds
    , proportional, clamp, retarget
    , withRange, withCurrent, withTiming
    , current, range, timing
    )

{-| This module provides resize policies and builders to configure how animations
should respond to changes in window size.

The Engines and their animations know nothing about the outside world, or your layout intentions,
so they can't automatically respond to layout changes. Standard CSS media queries or JavaScript
can't help here because the world of the animation is controlled by the Engine. Therefore, this module
provides a way to declare a resize [Policy](#policy) for an animation, and then feed new [Bounds](#bounds)
into the Engine when a resize event occurs.

The Engine applies the declared [Policy](#policy) to the new [Bounds](#bounds) and adjusts the animation
accordingly on the next animation frame after resize.

You can declare different policies for different animation groups, change them at any time, and even query
them to make decisions based on the current policy.

Group policies can be overridden by per-property policies, giving you fine-grained control over how
each animation responds to resize.

Use with the [WAAPI](Anim.Engine.WAAPI) or [Sub](Anim.Engine.Sub) Engines
to make animations responsive to layout changes.

Setup has two very simple steps:

1.  Declare a [Policy](#policy) in your Engine's `init` function.

        Sub.init <|
            [ Resize.policy "box" Resize.proportional
            ... -- other init configs
            ]

2.  After a resize event, pass the new bounds to the engine.

```
    OnResize width height ->
        let
            bounds =
                { x = Just { min = 0, max = toFloat width }
                , y = Just { min = 0, max = toFloat height }
                , z = Nothing
                }
        in
        ({ model | animState =
            Sub.onResize model.animState <|
                Resize.bounds "box" bounds
        }
        , Cmd.none
        )
```

The animation will respect the new bounds and the rules of the declared policy on the next animation frame after resize.


# Builder

@docs Builder


# Policy

The resize policy types and presets provide a way to express your
intentions for how animations should respond to resize.

Set your resize policy in your Engine's `init` function. If you need
to adjust policies dynamically, you can call `Resize.policy` in any
`AnimBuilder` pipeline, and the new policy will apply on the next resize event.

@docs policy, Policy, RangePolicy, CurrentPolicy, TimingPolicy


# Bounds

@docs AxisBounds, Bounds, bounds


## Presets

@docs proportional, clamp, retarget


## Combinators

@docs withRange, withCurrent, withTiming


## Query

@docs current, range, timing

-}

import Anim.Builder as AnimBuilder
import Anim.Internal.Builder as Builder
import Anim.Internal.Resize.Builder as Internal


{-| Opaque builder type consumed by `WAAPI.onResize` or `Sub.onResize`.

This builder stores resize policies so the Engine can apply them when handling a resize event.

-}
type alias Builder =
    Internal.Builder


{-| Inclusive numeric range for one axis.
-}
type alias AxisBounds =
    { min : Float, max : Float }


{-| Per-axis resize bounds. Leave an axis as `Nothing` to ignore it.

    { x = Just { min = 0, max = newWidth - boxSize }
    , y = Nothing
    , z = Nothing
    }

-}
type alias Bounds =
    { x : Maybe AxisBounds
    , y : Maybe AxisBounds
    , z : Maybe AxisBounds
    }


{-| Set group-wide bounds for an animation group when a resize occurs.

    Sub.onResize model.animState <|
        Resize.bounds "box" <|
            { x = Just { min = 0, max = newWidth - boxWidth }
            , y = Nothing
            , z = Nothing
            }

    Sub.onResize model.animState <|
        Resize.bounds "box" newBoxBounds
            >> Resize.bounds "otherGroup" otherBounds

-}
bounds : Internal.AnimGroupName -> Bounds -> Builder -> Builder
bounds =
    Internal.bounds


{-| Set a group-wide resize policy for an animation group.

    Sub.init <|
        [ Resize.policy "box" Resize.proportional
        ... -- other init configs
        ]

This can be orverridden on a per-property basis.

Resolution order:

1.  Per-property policy
2.  Group-wide policy
3.  Library default `Resize.proportional`

-}
policy : Internal.AnimGroupName -> Policy -> AnimBuilder.AnimBuilder mode -> AnimBuilder.AnimBuilder mode
policy =
    Builder.policy toInternalPolicy


toInternalPolicy : Policy -> Internal.Policy
toInternalPolicy (Policy p) =
    { range =
        case p.range of
            Pinned ->
                Internal.Pinned

            Adaptive ->
                Internal.Adaptive
    , current =
        case p.current of
            Fixed ->
                Internal.Fixed

            Relative ->
                Internal.Relative
    , timing =
        case p.timing of
            SolveFromCurrent ->
                Internal.SolveFromCurrent

            PreserveProgress ->
                Internal.PreserveProgress
    }


{-| Determines how an animation's range adjusts to new bounds.

  - `Pinned`: keep configured start/end values, clamped into the new bounds.
  - `Adaptive`: adapt the animation range to match the new bounds.

Quick rule:

  - Reach for `Pinned` when the animation should keep its authored start/end
    positions and resize should only clip them into the new bounds.
  - Reach for `Adaptive` when the range itself should expand or contract with
    the container, so the motion keeps spanning the available space.

-}
type RangePolicy
    = Pinned
    | Adaptive


{-| Controls what happens to the current value after resize.

  - `Fixed` keeps the current value where it is, clamped into bounds.
  - `Relative` keeps the same relative position within the resized
    range.

Quick rule:

  - Reach for `Fixed` when you want the value to stay put during resize
    and only clamp if it falls outside the new bounds.
  - Reach for `Relative` when the current value should move with the
    resized range and keep the same relative spot inside it.

-}
type CurrentPolicy
    = Fixed
    | Relative


{-| Controls how playback time resumes after resize.

  - `SolveFromCurrent`: prioritize visual position now. The engine solves time
    from the resized `current` value.
  - `PreserveProgress`: prioritize motion phase. If the animation was 40%
    through before resize, it stays 40% through after resize.

Quick rule:

  - Reach for `SolveFromCurrent` when the resized animation should continue
    from the current visible position, even if that means changing its point in
    the cycle.
  - Reach for `PreserveProgress` when the animation's phase matters more than
    the exact current position, especially for loops and easing continuity.

-}
type TimingPolicy
    = SolveFromCurrent
    | PreserveProgress


{-| A resize policy combines endpoint, current-value, and timing rules.

Start with one of the presets:

    Resize.proportional

    Resize.clamp

    Resize.retarget

Then tweak it with `withRange`, `withCurrent`, or `withTiming` when needed:

    Resize.retarget
        |> Resize.withTiming Resize.PreserveProgress

-}
type Policy
    = Policy
        { range : RangePolicy
        , current : CurrentPolicy
        , timing : TimingPolicy
        }


{-| Keep the same progress ratio after resize.

Best for looping or ping-pong motion where rhythm should continue smoothly.

    Resize.proportional
    -- { range = TrackBounds
    -- , current = PreserveProportion
    -- , timing = PreserveProgress
    -- }

-}
proportional : Policy
proportional =
    Policy
        { range = Adaptive
        , current = Relative
        , timing = PreserveProgress
        }


{-| Keep configured targets, clamp into bounds, then continue from the current
visual value.

Best when bounds are a safety limit, not the track itself.

    Resize.clamp
    -- { range = Pinned
    -- , current = Fixed
    -- , timing = SolveFromCurrent
    -- }

-}
clamp : Policy
clamp =
    Policy
        { range = Pinned
        , current = Fixed
        , timing = SolveFromCurrent
        }


{-| Use the new bounds as the range, keep the current value in place, then
solve timing from that current value.

Best for motion that should continue toward the resized boundary while
minimizing visual jumps at resize time.

    Resize.retarget
    -- { range = Adaptive
    -- , current = Fixed
    -- , timing = SolveFromCurrent
    -- }

-}
retarget : Policy
retarget =
    Policy
        { range = Adaptive
        , current = Fixed
        , timing = SolveFromCurrent
        }


{-| Override the [`RangePolicy`](#RangePolicy) of an existing policy.

    Resize.retarget
        |> Resize.withRange Resize.Pinned

-}
withRange : RangePolicy -> Policy -> Policy
withRange ep (Policy policy_) =
    Policy { policy_ | range = ep }


{-| Override the [`CurrentPolicy`](#CurrentPolicy) of an existing policy.

    Resize.clamp
        |> Resize.withCurrent Resize.Relative

-}
withCurrent : CurrentPolicy -> Policy -> Policy
withCurrent cp (Policy policy_) =
    Policy { policy_ | current = cp }


{-| Override the [`TimingPolicy`](#TimingPolicy) of an existing policy.

    Resize.retarget
        |> Resize.withTiming Resize.PreserveProgress

-}
withTiming : TimingPolicy -> Policy -> Policy
withTiming tp (Policy policy_) =
    Policy { policy_ | timing = tp }


{-| Query the `CurrentPolicy` of a `Policy`.
-}
current : Policy -> CurrentPolicy
current (Policy p) =
    p.current


{-| Query the `RangePolicy` of a `Policy`.
-}
range : Policy -> RangePolicy
range (Policy p) =
    p.range


{-| Query the `TimingPolicy` of a `Policy`.
-}
timing : Policy -> TimingPolicy
timing (Policy p) =
    p.timing
