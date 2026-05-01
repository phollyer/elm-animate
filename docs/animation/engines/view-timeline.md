# View Timeline Engine

This page focuses on what makes this Engine different, read [Engines Overview](overview.md) for features that are shared across all Engines.

The View Timeline Engine ties animation progress to an element's position within the viewport. As the element scrolls into (or out of) view, the animation progresses — no `AnimState`, `update`, or `subscriptions` required.

It uses the browser's native `ViewTimeline` API via the same JavaScript companion as the [WAAPI Engine](waapi.md).

!!! info "Browser support"
    `ViewTimeline` is part of the [CSS Scroll-Driven Animations](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_scroll-driven_animations) spec. Check [caniuse.com](https://caniuse.com/css-scroll-driven-animations) for current browser support.


## Setup

Uses the same JavaScript companion as the WAAPI Engine. See [WAAPI Setup](waapi.md#setup) for CDN and NPM install instructions.

Only the outgoing port is needed — there are no events to receive back from JavaScript:

??? example "View Source Code"

    ```elm
    port module Main exposing (main)

    import Json.Encode


    -- Outgoing port (Elm → JS): sends animation commands
    port waapiCommand : Json.Encode.Value -> Cmd msg
    ```


## Trigger

### `animate`

Fire-and-forget. The animated element itself is the `ViewTimeline` subject — no separate target configuration needed. Returns a `Cmd msg` with no state to store.

??? example "View Example"

    <iframe src="../../examples/src/Animation/WAAPI/ViewTimeline/index.html" style="width: 100%; height: 450px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Animation/WAAPI/ViewTimeline/Main.elm"
    ```


## View

Attach the animation group identifier to an element using `attributes`:

??? example "View Source Code"

    ```elm
    div (ViewTimeline.attributes "hero-card") [ ... ]
    ```


## Range

`rangeStart` and `rangeEnd` control exactly when in the element's scroll lifecycle the animation plays. Both are optional — omitting them defaults to `cover 0` through `cover 100`, which spans the full time the element is anywhere in the viewport.

Use the constructor functions to build typed `Range` values:

| Constructor | Valid for | 0% is when… | 100% is when… |
| ----------- | --------- | ----------- | -------------- |
| `cover` | start or end | Element's leading edge first enters the viewport | Element has fully left the viewport |
| `contain` | start or end | Element first becomes fully visible | Element begins to leave the viewport |
| `entry` | start only | Element's leading edge first enters the viewport | Element has fully entered the viewport |
| `exit` | end only | Element's leading edge starts to leave the viewport | Element has fully left the viewport |
| `entryCrossing` | start only | Element's leading edge crosses into the viewport | Element's leading edge reaches the opposite side of the viewport |
| `exitCrossing` | end only | Element's trailing edge begins to cross out of the viewport | Element's trailing edge reaches the opposite side of the viewport |

The compiler enforces which constructors are valid for start vs end — `entry` and `entryCrossing` cannot be passed to `rangeEnd`, and `exit` and `exitCrossing` cannot be passed to `rangeStart`.

Some common combinations:

| `rangeStart` | `rangeEnd` | Effect |
| ------------ | ---------- | ------ |
| `entry 0` | `entry 100` | Animate while the element scrolls into view |
| `entry 0` | `cover 50` | Animate from first appearance until halfway through the viewport |
| `exit 0` | `exit 100` | Animate while the element scrolls out of view |
| `contain 0` | `contain 100` | Animate only while the element is fully inside the viewport |

??? example "View Source Code"

    ```elm
    ViewTimeline.animate waapiCommand <|
        ViewTimeline.rangeStart (ViewTimeline.entry 0)
            >> ViewTimeline.rangeEnd (ViewTimeline.entry 100)
            >> Opacity.for "card"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build
    ```


## Horizontal Axis

Vertical tracking is the default. Call `horizontal` in the pipeline when the element is inside a container that scrolls left and right:

??? example "View Source Code"

    ```elm
    ViewTimeline.animate waapiCommand <|
        ViewTimeline.horizontal
            >> Opacity.for "slide"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build
    ```


## Playback

`iterations` and `alternate` work the same as in other engines, with one difference: for view-driven animations, `alternate` only has an effect when `iterations > 1`. Calling `alternate` without first calling `iterations` will automatically set iterations to `2`.

📖 See [Playback](overview.md) in the Engines Overview for details.


## Easing

📖 See [Easing](../concepts/easing.md) for available easing functions.


## API Quick Reference

### Types

| Type | Description |
| ---- | ----------- |
| `AnimBuilder` | Carries all animation configuration for a view-driven animation |
| `Range a` | A typed range position — use the constructor functions to create values |

### Trigger

| Function | Type | Description |
| -------- | ---- | ----------- |
| `animate` | `(Value -> Cmd msg) -> (AnimBuilder -> AnimBuilder) -> Cmd msg` | Fire-and-forget view-driven animation |

### View

| Function | Type | Description |
| ---------- | ------ | ------------- |
| `attributes` | `String -> List (Html.Attribute msg)` | Attach the animation group identifier to an element |

### Range

| Function | Type | Description |
| -------- | ---- | ----------- |
| `rangeStart` | `Range ForStart -> AnimBuilder -> AnimBuilder` | Set when the animation begins |
| `rangeEnd` | `Range ForEnd -> AnimBuilder -> AnimBuilder` | Set when the animation ends |
| `cover` | `Float -> Range a` | Full element coverage — valid for start or end |
| `contain` | `Float -> Range a` | Full element containment — valid for start or end |
| `entry` | `Float -> Range ForStart` | Element entering the viewport — start only |
| `entryCrossing` | `Float -> Range ForStart` | Leading edge crossing — start only |
| `exit` | `Float -> Range ForEnd` | Element leaving the viewport — end only |
| `exitCrossing` | `Float -> Range ForEnd` | Trailing edge crossing — end only |

### Axis

| Function | Type | Description |
| -------- | ---- | ----------- |
| `horizontal` | `AnimBuilder -> AnimBuilder` | Use horizontal viewport tracking |

### Playback

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `iterations` | `Int -> AnimBuilder -> AnimBuilder` | Set number of iterations |
| `alternate` | `AnimBuilder -> AnimBuilder` | Reverse direction on each iteration |

### Easing

| Function | Type | Description |
| ---------- | ---- | ------------- |
| `easing` | `Easing -> AnimBuilder -> AnimBuilder` | Set the easing function |

For complete API details, see the [Anim.Engine.WAAPI.ViewTimeline](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/Anim-Engine-WAAPI-ViewTimeline) documentation.
