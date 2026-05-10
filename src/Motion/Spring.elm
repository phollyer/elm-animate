module Motion.Spring exposing
    ( Spring
    , gentle, wobbly, stiff, slow, noWobble
    , custom
    )

{-| Spring-based motion configurations.

Springs describe physical motion — stiffness, damping, mass — rather
than time-and-curve. Their duration is *emergent*: the motion ends
when the value has settled at the target. This makes springs the
right primitive for anything that should "feel physical": bouncy UI
reveals, gesture-handoff momentum, anything where a tween's
fixed-duration ramp would feel artificial.

For ramp-shaped motion (fades, slides with a known duration, classic
ease curves), use `Motion.Easing` instead.


# The Spring type

@docs Spring


# Presets

Curated configurations covering the common feel-points.

@docs gentle, wobbly, stiff, slow, noWobble


# Custom configuration

@docs custom

-}

import Motion.Internal.Spring as Internal


{-| Opaque spring configuration. Construct one via a preset (`gentle`,
`wobbly`, `stiff`, `slow`, `noWobble`) or [`custom`](#custom).

Pass to whichever animation or scroll engine accepts a spring; the
engine will run the motion until the value is settled. There is no
explicit duration — the spring's stiffness, damping, and mass
determine how long it takes to come to rest.

-}
type alias Spring =
    Internal.Spring


{-| A soft, slow settle. Mild overshoot, takes its time.

Good for: hero-element reveals, large modals, anything where a sense
of weight is welcome.

-}
gentle : Spring
gentle =
    Internal.Spring
        { stiffness = 120
        , damping = 14
        , mass = 1
        , initialVelocity = 0
        }


{-| Lively and bouncy. Several visible oscillations before settling.

Good for: playful UI accents, attention-grabbing reveals, cartoony
interactions.

-}
wobbly : Spring
wobbly =
    Internal.Spring
        { stiffness = 180
        , damping = 12
        , mass = 1
        , initialVelocity = 0
        }


{-| Snappy and direct. Small overshoot, settles quickly.

Good for: button presses, tooltip reveals, anything that should feel
crisp and immediate.

-}
stiff : Spring
stiff =
    Internal.Spring
        { stiffness = 300
        , damping = 20
        , mass = 1
        , initialVelocity = 0
        }


{-| Low stiffness with extra damping — a long, mellow approach.

Good for: ambient motion, slow-developing reveals, "drifting into
place" effects.

-}
slow : Spring
slow =
    Internal.Spring
        { stiffness = 60
        , damping = 18
        , mass = 1
        , initialVelocity = 0
        }


{-| Critically damped — the fastest approach to the target with no
overshoot whatsoever.

Good for: when you want spring-like timing but tween-like absence of
overshoot. Useful for scroll handoffs and other places where bounce
would look like a bug.

-}
noWobble : Spring
noWobble =
    Internal.Spring
        { stiffness = 170
        , damping = 26
        , mass = 1
        , initialVelocity = 0
        }


{-| Hand-tune a spring's physics.

  - `stiffness` — Hooke's-law `k`. Higher is snappier. Typical
    `100..400`. Must be `>= 0`.
  - `damping` — viscous friction `c`. Higher is less wobbly. Typical
    `10..40`. Must be `>= 0`.
  - `mass` — oscillator mass. Typical `1.0`. Heavier feels more
    sluggish. Must be `> 0`.

The damping ratio `c / (2·√(k·m))` decides the regime:

  - `< 1` — under-damped: oscillates and decays
  - `= 1` — critically damped: fastest no-overshoot settle
  - `> 1` — over-damped: slow no-overshoot approach

Inputs are clamped: stiffness and damping below 0 become 0, mass
below 1e-6 becomes 1e-6.

    customSpring : Spring
    customSpring =
        Motion.Spring.custom
            { stiffness = 220
            , damping = 16
            , mass = 1
            }

-}
custom :
    { stiffness : Float
    , damping : Float
    , mass : Float
    }
    -> Spring
custom { stiffness, damping, mass } =
    Internal.Spring
        { stiffness = max 0 stiffness
        , damping = max 0 damping
        , mass = max 1.0e-6 mass
        , initialVelocity = 0
        }
