# Easing Functions

Easing functions control the rate of change during an animation, making motion feel natural and polished.

## Standard Easings

These are the standard easing curves calculated using the functions from [elm-community/easing-functions](https://package.elm-lang.org/packages/elm-community/easing-functions/latest/Ease).

### Linear

Constant speed throughout. Rarely what you want for UI animations.

### Ease

The standard CSS easing functions.

| Easing | Feel |
| -------- | ------ |
| `EaseIn` | Starts slow, ends fast |
| `EaseOut` | Starts fast, ends slow |
| `EaseInOut` | Slow at both ends |

### Sine

Gentle, subtle easing based on sine curve.

| Easing | Feel |
| -------- | ------ |
| `SineIn` | Gentle acceleration |
| `SineOut` | Gentle deceleration |
| `SineInOut` | Gentle both ends |

### Quad

Quadratic (power of 2) — slightly more pronounced than sine.

| Easing | Feel |
| -------- | ------ |
| `QuadIn` | Moderate acceleration |
| `QuadOut` | Moderate deceleration |
| `QuadInOut` | Moderate both ends |

### Cubic

Cubic (power of 3) — more noticeable acceleration/deceleration.

| Easing | Feel |
| -------- | ------ |
| `CubicIn` | Noticeable acceleration |
| `CubicOut` | Noticeable deceleration |
| `CubicInOut` | Noticeable both ends |

### Quart

Quartic (power of 4) — dramatic effect.

| Easing | Feel |
| -------- | ------ |
| `QuartIn` | Strong acceleration |
| `QuartOut` | Strong deceleration |
| `QuartInOut` | Strong both ends |

### Quint

Quintic (power of 5) — very dramatic.

| Easing | Feel |
| -------- | ------ |
| `QuintIn` | Very strong acceleration |
| `QuintOut` | Very strong deceleration |
| `QuintInOut` | Very strong both ends |

### Expo

Exponential — extremely dramatic.

| Easing | Feel |
| -------- | ------ |
| `ExpoIn` | Explosive acceleration |
| `ExpoOut` | Explosive deceleration |
| `ExpoInOut` | Explosive both ends |

### Circ

Circular — based on quarter circle.

| Easing | Feel |
| -------- | ------ |
| `CircIn` | Circular acceleration |
| `CircOut` | Circular deceleration |
| `CircInOut` | Circular both ends |

### Back

Overshoots slightly then returns.

| Easing | Feel |
| -------- | ------ |
| `BackIn` | Pulls back then accelerates |
| `BackOut` | Overshoots then settles |
| `BackInOut` | Both effects |

### Elastic

Spring-like bounce effect.

| Easing | Feel |
| -------- | ------ |
| `ElasticIn` | Winds up like a spring |
| `ElasticOut` | Springs and oscillates |
| `ElasticInOut` | Both effects |

### Bounce

Bouncing ball effect.

| Easing | Feel |
| -------- | ------ |
| `BounceIn` | Bounces at start |
| `BounceOut` | Bounces at end |
| `BounceInOut` | Both effects |

### CubicBezier

Custom easing curve defined by two control points — the same format used by CSS `cubic-bezier()`.

??? example "View Source Code"

    ```elm
    >> Property.easing (CubicBezier 0.68 -0.55 0.265 1.55)
    ```

The four parameters (`x1 y1 x2 y2`) define the curve's control points. Use tools like [cubic-bezier.com](https://cubic-bezier.com) to visualize and create custom curves.

## Complex Easings

Back, Bounce, and Elastic are mathematically complex easings. Unlike simple power curves (Quad, Cubic, etc.), these use trigonometric functions, exponentials, and piecewise calculations to create oscillations, bounces, and overshoots.

The following `*Custom` and `*Advanced` variants give you extra control over how these complex curves behave - adjusting bounce count, oscillation intensity, overshoot amount, and decay rates.

!!! note "Duration behavior"
    Custom and Advanced easings are generated such that the transition time (A → B) matches your specified duration/speed. Any oscillations or bounces are calculated based on the provided parameters and then prepended or appended to the transition phase. This provides a smoother, more natural effect - rather than squashing 6 bounces (3 at either end) plus the transition phase into a 2sec animation, you decide on the duration of the transition phase, and then bounces and oscilations are calculated based on velocity and the provided parameters.


## Custom Easings

For Back, Bounce, and Elastic, you can customize their behavior with `*Custom` variants.

=== "Back*Custom"

    Adjust the overshoot amount with a `strength` parameter.

    ??? example "View Source Code"

        ```elm
        >> Property.easing (BackInCustom 2.5)  -- More overshoot
        >> Property.easing (BackOutCustom 0.5)  -- Less overshoot
        >> Property.easing (BackInOutCustom ( 1.0, 2.0 ))  -- Different in/out
        ```

=== "Bounce*Custom"

    Adjust the bounce intensity with a `strength` parameter.

    ??? example "View Source Code"

        ```elm
        >> Property.easing (BounceInCustom 1.5)  -- More intense bounces
        >> Property.easing (BounceOutCustom 0.5)  -- Gentler bounces
        >> Property.easing (BounceInOutCustom ( 0.8, 1.2 ))  -- Different in/out
        ```

=== "Elastic*Custom"

    Adjust the oscillation intensity with a `strength` parameter.

    ??? example "View Source Code"

        ```elm
        >> Property.easing (ElasticInCustom 1.5)  -- More oscillation
        >> Property.easing (ElasticOutCustom 0.5)  -- Less oscillation
        >> Property.easing (ElasticInOutCustom ( 1.0, 0.8 ))  -- Different in/out
        ```

## Advanced Easings

For even more control over Bounce and Elastic, use the `*Advanced` variants with full parameter records.

=== "Bounce*Advanced"

    Control bounces, amplitude, and decay rate.

    | Field | Effect |
    | --------- | ------ |
    | `bounces` | Number of bounces |
    | `amplitude` | Bounce height (higher = larger bounces) |
    | `decay` | How quickly bounces shrink (higher = faster decay) |

    ??? example "View Source Code"

        ```elm
        >> Property.easing
            (BounceOutAdvanced
                { bounces = 3
                , amplitude = 1.2
                , decay = 0.5
                }
            )
        ```

    For `BounceInOutAdvanced`, configure each phase independently:

    ??? example "View Source Code"

        ```elm
        >> Property.easing
            (BounceInOutAdvanced
                { in_ = { bounces = 2, amplitude = 0.8, decay = 0.4 }
                , out = { bounces = 4, amplitude = 1.0, decay = 0.6 }
                }
            )
        ```

=== "Elastic*Advanced"

    Control elasticity, amplitude, and decay rate.

    | Field | Effect |
    | --------- | ------ |
    | `elasticity` | Springiness (higher = more oscillation) |
    | `amplitude` | Oscillation size (higher = larger swings) |
    | `decay` | How quickly oscillations fade (higher = faster decay) |

    ??? example "View Source Code"

        ```elm
        >> Property.easing
            (ElasticOutAdvanced
                { elasticity = 0.8
                , amplitude = 1.5
                , decay = 0.3
                }
            )
        ```

    For `ElasticInOutAdvanced`, configure each phase independently:

    ??? example "View Source Code"

        ```elm
        >> Property.easing
            (ElasticInOutAdvanced
                { in_ = { elasticity = 0.6, amplitude = 1.0, decay = 0.4 }
                , out = { elasticity = 0.9, amplitude = 1.2, decay = 0.5 }
                }
            )
        ```

## Choosing an Easing

!!! tip "General recommendations"

    **For most UI animations:** `QuintOut` or `CubicOut`
    
    These provide a snappy start with a smooth deceleration, which feels responsive.

!!! tip "For entrances:"
    Use `Out` variants — elements should arrive and settle smoothly.

!!! tip "For exits:"
    Use `In` variants — elements should accelerate away.

!!! tip "For state changes:"
    Use `InOut` variants — smooth transitions between states.

## Next Steps

A closer look at the Animation Workflow.

[Animation Workflow →](../animation-workflow/build.md){ .md-button .md-button--primary }


