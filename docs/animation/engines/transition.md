# CSS Transition Engine

This page focuses on what makes this Engine different, read [Engines Overview](overview.md) for features that are shared across all Engines.

This Engine uses native browser CSS transitions for simple A→B property animations. The browser handles all rendering, providing excellent performance with minimal setup.

## Example

Simple A→B button hover animations.

??? example "View Example"

    --8<-- "docs/animation/first-animations/button-hovers/transition.md:example"

??? example "View Source Code"

    --8<-- "docs/animation/first-animations/button-hovers/transition.md:code"


### How CSS Transition Work

CSS transitions animate when the browser detects a *change* to a transitioned property. This makes them stable and predictable — they won't re-trigger unexpectedly during browser repaints or reflows.

#### No Starting Values

CSS transitions only use an end value, the start value is *always* computed by the browser from the current state of the element in the DOM. This is native CSS transitions behaviour.

This also applies to subsequent animations. For example, if you animate background color from white to blue, the next animation will always start from blue (the browser's computed value) regardless of any `from` value you set. If you need explicit control over starting values, use the [Keyframe](keyframes.md), [Sub](sub.md) or [WAAPI](waapi.md) engines instead.

As a result of the native behaviour, the Transition Engine **will ignore** starting values in Builder configs.

#### Mid-Flight Interruptions

The native behaviour becomes a feature for mid-flight interruptions to animations - just provide the new end value, and the browser will compute the starting value from the current state of the element.

This means that mid-flight interruptions will **always** transition smoothly from current to end values.

#### OnLoad Animations

Because CSS transitions don't take a start value, running an animation instantly when a page loads requires a workaround. This is because, if the transition runs on first render, the browser has no start value, and so jumps to the end value. The workaround is to use `Process.sleep` to delay the triggering (`opacity = 1`) until after the browser has rendered the initial state - `opacity = 0`. This gives the browser the start value it needs to detect the property change to `opacity = 1`.

If you prefer animations that run immediately on render without this pattern, use the [Keyframe](keyframes.md), [Sub](sub.md) or [WAAPI](waapi.md) Engine instead.

## Easing

Easings are converted to CSS `cubic-bezier` values for the browser to render natively.

Most standard easings (sine, quad, cubic, quart, quint, expo) convert accurately. However, complex curves like **bounce** and **elastic** are approximated and won't match their mathematical definitions exactly.

For accurate complex easing curves, use the [Keyframe Engine](keyframes.md), [Sub Engine](sub.md), or [WAAPI Engine](waapi.md) instead.

## Discrete Properties

The Transition engine uses `discreteEntry` and `discreteExit` — the same API as all other engines.

For this Engine, calling either function enables the browser's native `transition-behavior: allow-discrete` CSS feature.

For entry animations, include `startingStyleNode` in your view. This generates `@starting-style` CSS rules so the browser knows the interpolable property values to animate from when an element first appears. Without it, entry transitions are skipped.

??? example "View Source Code"

    ```elm

    fadeIn : AnimBuilder -> AnimBuilder
    fadeIn =
        Transition.discreteEntry "display" "block"
            >> Opacity.for "box"
            >> Opacity.to 1
            >> Opacity.build

    fadeOut : AnimBuilder -> AnimBuilder
    fadeOut =
        Transition.discreteExit "display" "block" "none"
            >> Opacity.for "box"
            >> Opacity.to 0
            >> Opacity.build

    view : Model -> Html Msg
    view model =
        div []
            [ Transition.startingStyleNode model.animState
            , div
                (Transition.attributes "box" model.animState
                    ++ Transition.events GotAnimMsg
                    ++ [ style "display" "none" ]
                )
                [ text "Hello!" ]
            ]
    ```

!!! info "Browser Support"
    `transition-behavior: allow-discrete` requires modern browsers (Chrome 117+, Firefox 129+, Safari 18+). In older browsers, discrete property transitions won't animate — the property will snap immediately. If you need broader browser support, consider using Keyframe, Sub, or WAAPI instead.

📖 See [Discrete Properties](../concepts/discrete-properties.md) for the full API, live examples, and source code.

## Transform Ordering

Transform Ordering is not supported by this Engine.

### Why Not?

Transform ordering is done by controlling the order of properties defined in the string value of the `transform` property that the Browser reads. However, the `transform` property can only have one transition rule for easing, duration and delay. This means that all the properties defined in a `transform` string will share the same easing, duration and delay - which goes against the grain for this library.

Therefore, this Engine breaks the transform properties `translate` and `scale` out of the `transform` string, and renders them as individual CSS properties. Now `translate`, `scale` and `rotate` can all have their own independent transition rules for easing, duration and delay.

However, without getting all technical about vectors, angles and axes, `rotate` needs to remain inside the `transform` string so that all three axes can be animated independently. At the time of writing, `skew` has no CSS property, and can only be animated/rendered as a `transform`. This means that `rotate` and `skew` both remain inside the `transform` string and therefore they share one transition rule. When both are animated together, `rotate`'s easing, duration, and delay settings always take priority over `skew`'s.

All other properties will animate independently, only `rotate` and `skew` remain linked.

!!! note "Design trade-off: fixed transform order"
    All browsers enforce a fixed application order per the [CSS Transforms Level 2 spec](https://drafts.csswg.org/css-transforms-2/#ctm): **translate → rotate → scale → transform**. Due to `rotate` and `skew` remaining in the `transform` string, the actual application order for this Engine is **translate → scale → transform**, which expands to **translate → scale → rotate → skew**. The difference to the application order is only noticeable for **animations on the same element** with a **non-uniform scale animation** combined with a **non-zero rotation animation**.

    When it does matter you can work around it by placing the rotation on a wrapper element.

    This is a deliberate trade-off — per-property independent timing and easing in exchange for a fixed transform order.

    If you need custom transform ordering, use the [Keyframe](keyframes.md), [Sub](sub.md), or [WAAPI](waapi.md) engine instead.

## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimState` | Tracks animations and their states |
| `AnimBuilder` | Carries all the animations configurations |
| `AnimMsg` | Internal Engine `Msg`s |
| `AnimEvent` | Events received during a transitions lifecycle |
| `AnimGroupName` | `String` type alias representing the animation group name |

### Initialize

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `init` | `List (AnimBuilder -> AnimBuilder) -> AnimState` | Create initial animation state |

### Trigger

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `animate` | `AnimState -> (AnimBuilder -> AnimBuilder) -> AnimState` | Create a state-tracked animation |

### Update

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `update` | `AnimMsg -> AnimState -> (AnimState, AnimEvent)` | Update AnimState after a transition event |

### View

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `AnimGroupName -> AnimState -> List (Html.Attribute msg)` | Get the transition attributes for an element |

### Event Listeners

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `events` | `(AnimMsg -> msg) -> List (Attribute msg)` | Attach all transition event listeners for an animation group |
| `eventsStopPropagation` | `(AnimMsg -> msg) -> List (Attribute msg)` | Attach all listeners, stops propagation |

### Playback Settings

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `duration` | `Int -> AnimBuilder -> AnimBuilder` | Set default duration (ms) |
| `speed` | `Float -> AnimBuilder -> AnimBuilder` | Set default speed (property units/sec) |
| `delay` | `Int -> AnimBuilder -> AnimBuilder` | Set default delay (ms) |

### Easing

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set default easing function |

### Controls

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `stop` | `AnimGroup -> AnimState -> AnimState` | Jump to end state and stop |
| `reset` | `AnimGroup -> AnimState -> AnimState` | Jump to start state and stop |

### Discrete Properties

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `discreteEntry` | `String -> String -> AnimBuilder -> AnimBuilder` | Set a discrete CSS property value for entry animations |
| `discreteExit` | `String -> String -> String -> AnimBuilder -> AnimBuilder` | Set a discrete CSS property value for exit animations (from, to) |
| `startingStyleNode` | `AnimState -> Html msg` | Generate a `<style>` node containing `@starting-style` rules for all animation groups |
| `startingStyleNodeFor` | `AnimGroup -> AnimState -> Html msg` | Generate a `<style>` node containing `@starting-style` rules for a specific animation group |

### State Queries

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `anyRunning` | `AnimState -> Maybe Bool` | Check if any animations are running |
| `isRunning` | `AnimGroup -> AnimState -> Maybe Bool` | Check if a specific element is animating |
| `allComplete` | `AnimState -> Maybe Bool` | Check if all animations are complete |
| `isComplete` | `AnimGroup -> AnimState -> Maybe Bool` | Check if a specific element's animation is complete |

### Property Queries

CSS transitions interpolate from the browser's current computed style, so only end values are tracked. For start values and/or mid-flight values, use either the [Keyframe](keyframes.md), [Sub](sub.md) or [WAAPI](waapi.md) engine.

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `getColorPropertyEnd` | `AnimGroupName -> String -> AnimState -> Maybe Color` | Get end color for a named color property |
| `getOpacityEnd` | `AnimGroup -> AnimState -> Maybe Float` | Get end opacity |
| `getRotateEnd` | `AnimGroup -> AnimState -> Maybe { x, y, z }` | Get end rotate value |
| `get*End` | `AnimGroup -> AnimState -> Maybe *` | Get end * value |

If no animation exists `Nothing` is returned.


For complete API details, see the [Anim.Engine.CSS.Transition](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-CSS-Transition) documentation.

## Next Steps

The Keyframe Engine which provides a few different features to what you get with transitions.

[Keyframe Engine →](keyframes.md){ .md-button .md-button--primary }
